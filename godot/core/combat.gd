class_name Combat
extends RefCounted
## Rundenbasierter Bodenkampf im RMSS-Stil: 10-Sekunden-Runden, 100 % Aktivität pro Figur und Runde,
## Reihenfolge nach Initiative, Feuerbereitschaft, Blickrichtung. Reine Spiellogik ohne Grafik;
## alles Sichtbare wird über Signale gemeldet.

signal logged(text: String, kind: StringName)
signal rolled(roll: Dictionary, label: String)
signal floated(unit: Combatant, text: String, kind: StringName)
signal stepped(unit: Combatant, from: Vector2i, to: Vector2i, gait: StringName)
signal faced(unit: Combatant)
signal attacked(unit: Combatant, target: Combatant, weapon: WeaponData)
signal unit_changed(unit: Combatant)
signal died(unit: Combatant)
signal crouched(unit: Combatant)
signal reloaded(unit: Combatant)
## sichtbare Handlung ohne Angriff: &"aid" (Erste Hilfe), &"psi" (Psi wirken)
signal acted(unit: Combatant, action: StringName)
signal overwatch_fired(unit: Combatant)
signal round_started(number: int)
signal turn_started(unit: Combatant)
signal order_changed
signal ended(result: StringName)

## Gangarten: Hexfelder pro 10 % Aktivität
const GAITS := {
	&"gehen": {"name": "Gehen", "pace": 1, "attack_mod": 0},
	&"laufen": {"name": "Laufen", "pace": 2, "attack_mod": -20},
	&"sprinten": {"name": "Sprinten", "pace": 3, "attack_mod": 0, "no_attack": true},
}
const COST := {"aid": 50, "psi": 40, "reload": 30, "stand": 30, "swap": 10, "crouch": 10, "wait": 10}
const CROUCH_DB := 15        # geduckt: +15 VW gegen Fernkampf
const CROUCH_OB := 10        # +10 AW im Fernkampf
const CROUCH_MELEE_OB := 10  # Nahkämpfer gegen Geduckte +10
const MEDKIT_BONUS := 20
const MIN_ATTACK := 20
const NORMAL_ATTACK := 60
const MIN_OVERWATCH := 30
const REACTION_MOD := -10
const FACING_MOD := {&"flanke": 15, &"ruecken": 30}
const PSI_SHIELD_BONUS := 20
const PSI_SHIELD_PP := 2

var map: BattleMap
var units: Array[Combatant] = []
var round_no := 0
var order: Array[Combatant] = []
var turn_idx := -1
var result: StringName = &""   # &"sieg" oder &"niederlage"
var jump_queue: Array[Combatant] = []
var fumbles: FumbleTableData
var deploying := true          # Runde 0: Crew im Eingangsbereich aufstellen, bis start() aufgerufen wird
var retreated := false         # Crew hat sich zurückgezogen (zählt als Niederlage)


## Modifikator für die in einen Angriff gesteckte Aktivität: 60 % = ±0, darunter −10 je 10 %, darüber +5 je 10 %
static func activity_mod(pct: int) -> int:
	return pct - NORMAL_ATTACK if pct < NORMAL_ATTACK else (pct - NORMAL_ATTACK) / 2


static func _sum(mods: Array) -> int:
	var s := 0
	for m in mods:
		s += m.val
	return s


func _init(battle_map: BattleMap, crew: Array[Combatant], enemies: Array[Combatant]) -> void:
	map = battle_map
	fumbles = GameData.fumble_table()
	units.append_array(crew)
	units.append_array(enemies)
	for i in crew.size():
		crew[i].pos = map.crew_start[i].pos
	for i in enemies.size():
		enemies[i].pos = map.enemy_start[i].pos


func log_text(text: String, kind: StringName = &"") -> void:
	logged.emit(text, kind)


var current: Combatant:
	get:
		return order[turn_idx] if turn_idx >= 0 and turn_idx < order.size() else null


func crew() -> Array[Combatant]:
	return units.filter(func(u: Combatant) -> bool: return u.is_crew)


func enemies() -> Array[Combatant]:
	return units.filter(func(u: Combatant) -> bool: return not u.is_crew)


func opponents(u: Combatant) -> Array[Combatant]:
	return units.filter(func(o: Combatant) -> bool: return o.team != u.team and o.is_ok())


func unit_at(p: Vector2i) -> Combatant:
	for u in units:
		if not u.is_dead() and u.pos == p:
			return u
	return null


func tile_of(u: Combatant) -> BattleMap.Tile:
	return map.tile(u.pos)


# ---------------------------------------------------------------- Runden und Züge

func start() -> void:
	deploying = false
	_start_round()


# ---------------------------------------------------------------- Runde 0: Aufstellung

func deploy_tiles() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for t in map.crew_start:
		out.append(t.pos)
	return out


func can_deploy(u: Combatant, p: Vector2i) -> bool:
	if not deploying or u == null or not u.is_crew or not deploy_tiles().has(p):
		return false
	var o := unit_at(p)
	return o == null or o.is_crew


## Figur auf ein Feld im Eingangsbereich stellen; steht dort schon jemand von der Crew, tauschen beide
func deploy(u: Combatant, p: Vector2i) -> Combatant:
	if not can_deploy(u, p):
		return null
	var o := unit_at(p)
	if o and o != u:
		o.pos = u.pos
	u.pos = p
	return o if o != u else null


func deploy_face(u: Combatant, dir: int) -> void:
	if deploying and u and u.is_crew:
		u.facing = dir


func _start_round() -> void:
	round_no += 1
	jump_queue.clear()
	log_text("— Runde %d (%d–%d s) —" % [round_no, (round_no - 1) * 10, round_no * 10], &"round")
	round_started.emit(round_no)
	for u in units:
		if u.is_dead():
			continue
		if round_no > 1 and u.is_ok():
			Rules.award_xp(u, &"kampfsinn", 1)
		if u.psi_shield > 0:
			u.psi_shield -= 1
		if u.bleed > 0:
			u.hp -= u.bleed
			log_text("%s blutet (−%d TP)." % [u.name, u.bleed], &"dmg")
			floated.emit(u, "−%d" % u.bleed, &"bleed")
			_check_state(u)
	if check_end():
		return
	var ready := units.filter(func(u: Combatant) -> bool: return u.is_ok())
	for u in ready:
		var a := Dice.d(10)
		var b := Dice.d(10)
		var bonus := Rules.initiative_bonus(u)
		u.init = a + b + bonus
		u.init_roll = "%d+%d%s" % [a, b, Dice.fmt(bonus)]
	ready.sort_custom(func(x: Combatant, y: Combatant) -> bool:
		return x.init > y.init if x.init != y.init else (x.is_crew and not y.is_crew))
	order.assign(ready)
	turn_idx = -1
	order_changed.emit()
	_next_turn()


func _next_turn() -> void:
	if check_end():
		return
	# wartende Figur, die einspringen will, kommt direkt als Nächste
	while not jump_queue.is_empty():
		var j: Combatant = jump_queue.pop_front()
		var idx := order.find(j)
		if j.waiting and j.is_ok() and idx > turn_idx:
			order.remove_at(idx)
			order.insert(turn_idx + 1, j)
			order_changed.emit()
			break
	turn_idx += 1
	while turn_idx < order.size() and not order[turn_idx].is_ok():
		turn_idx += 1
	if turn_idx >= order.size():
		_start_round()
		return
	_begin_turn(current)


func _begin_turn(u: Combatant) -> void:
	if u.waiting:
		# Einsprung nach dem Abwarten: Zustand vom Zugbeginn bleibt, Abwarten kostet 10 %
		u.waiting = false
		u.act = u.wait_act - COST.wait
		log_text("%s springt ein (−%d %% fürs Abwarten)." % [u.name, COST.wait])
		turn_started.emit(u)
		return
	u.acted = false
	u.act = 100
	u.has_attacked = false
	u.ran = false
	u.sprinted = false
	u.move_spare = 0.0
	u.free_hex = Rules.free_hexes(u)
	u.overwatch = {}  # Feuerbereitschaft endet mit dem eigenen nächsten Zug
	u.stunned_now = u.stun > 0
	if u.prone:
		u.act -= COST.stand
		u.prone = false
		log_text("%s rappelt sich auf (−%d %%)." % [u.name, COST.stand])
	if u.stunned_now:
		u.act = mini(u.act, 50)
		log_text("%s ist betäubt: höchstens 50 %% Aktivität, kein Angriff." % u.name)
	turn_started.emit(u)


## darf die Figur gerade handeln? (am Zug und kampffähig)
func is_active(u: Combatant) -> bool:
	return current == u and result == &"" and u.is_ok()


func can_do(u: Combatant, cost: int) -> bool:
	return is_active(u) and u.act >= cost


## Abwarten: Zug nach hinten schieben, solange die Figur in dieser Runde noch nichts getan hat
func can_wait(u: Combatant) -> bool:
	return is_active(u) and not u.acted and not u.waiting and u.wait_round != round_no and u.act >= COST.wait


func do_wait(u: Combatant) -> bool:
	if not can_wait(u):
		return false
	u.waiting = true
	u.wait_round = round_no
	u.wait_act = u.act
	u.reserve = u.act - COST.wait  # wachsam: freie Aktivität zählt als Ausweichreserve
	order.remove_at(turn_idx)
	order.append(u)
	turn_idx -= 1
	log_text("%s wartet ab." % u.name)
	order_changed.emit()
	_next_turn()
	return true


## wartende Figur springt nach dem laufenden Zug ein
func request_jump(u: Combatant) -> bool:
	if not u.waiting or not u.is_ok() or result != &"" or jump_queue.has(u):
		return false
	jump_queue.append(u)
	log_text("%s springt nach diesem Zug ein." % u.name)
	order_changed.emit()
	return true


func end_turn() -> void:
	var u := current
	if u == null:
		return
	# nicht verbrauchte Aktivität bleibt bis zum nächsten eigenen Zug als Ausweichreserve
	u.reserve = u.overwatch.pct if u.has_overwatch() else maxi(0, u.act)
	if u.stun > 0:
		u.stun -= 1
	u.act = 0
	unit_changed.emit(u)
	_next_turn()


func _check_state(u: Combatant) -> void:
	if u.is_dead():
		return
	if u.hp <= Rules.death_at(u):
		u.state = Combatant.State.DEAD
		u.overwatch = {}
		log_text("%s ist tot." % u.name, &"death")
		died.emit(u)
	elif u.hp <= 0 and u.is_ok():
		u.state = Combatant.State.KO
		u.overwatch = {}
		log_text("%s bricht bewusstlos zusammen." % u.name, &"death")
		unit_changed.emit(u)


## Rückzug der Crew (ab Runde 1): Kampf endet als Niederlage, die bis dahin gesammelten EP bleiben
func retreat() -> bool:
	if result != &"" or deploying:
		return false
	retreated = true
	result = &"niederlage"
	log_text("Die Crew zieht sich zurück.", &"round")
	ended.emit(result)
	return true


func check_end() -> bool:
	if result != &"":
		return true
	if enemies().all(func(u: Combatant) -> bool: return not u.is_ok()):
		result = &"sieg"
	elif crew().all(func(u: Combatant) -> bool: return not u.is_ok()):
		result = &"niederlage"
	if result != &"":
		ended.emit(result)
		return true
	return false


# ---------------------------------------------------------------- Bewegung

## Hexfelder je 10 %; geduckt nur Gehen mit halber Geschwindigkeit
func pace(u: Combatant, gait: StringName) -> float:
	if u.crouched:
		return 0.5 if gait == &"gehen" else 0.0
	return GAITS[gait].pace


func free_of(u: Combatant) -> int:
	return 0 if u.crouched else u.free_hex


## verfügbare Hexfelder bei dieser Gangart; act_limit begrenzt die dafür verwendbare Aktivität (KI)
func move_budget(u: Combatant, gait: StringName, act_limit := -1) -> float:
	var a := u.act if act_limit < 0 else act_limit
	return free_of(u) + u.move_spare + floorf(floorf(maxi(0, a) / 10.0) * pace(u, gait))


## Aktivität in %, die eine Strecke mit diesen Wegkosten kostet
func move_pct(u: Combatant, gait: StringName, cost: float) -> int:
	var rest := maxf(0.0, cost - free_of(u) - u.move_spare)
	return ceili(rest / pace(u, gait)) * 10


func can_move(u: Combatant, gait: StringName) -> bool:
	if not is_active(u):
		return false
	if gait == &"sprinten" and u.has_attacked:
		return false
	if pace(u, gait) == 0.0:
		return false
	return move_budget(u, gait) > 0


func move_range(u: Combatant, gait: StringName = &"gehen", act_limit := -1) -> BattleMap.Reach:
	return map.reachable(u.pos, move_budget(u, gait, act_limit),
		func(t: BattleMap.Tile) -> bool:
			var o := unit_at(t.pos)
			return o != null and o != u and o.team != u.team,
		func(t: BattleMap.Tile) -> bool:
			var o := unit_at(t.pos)
			return o != null and o != u)


func _pay_move(u: Combatant, gait: StringName, cost: float) -> void:
	var pct := move_pct(u, gait, cost)
	var need := cost
	var free := minf(free_of(u), need)
	u.free_hex -= int(free)
	need -= free
	var spare := minf(u.move_spare, need)
	u.move_spare -= spare
	need -= spare
	u.act -= pct
	u.move_spare += (pct / 10.0) * pace(u, gait) - need


func do_move(u: Combatant, target: Vector2i, gait: StringName = &"gehen") -> bool:
	if not can_move(u, gait):
		return false
	var reach := move_range(u, gait)
	if not reach.has(target) or target == u.pos:
		return false
	var path := reach.path_to(target)
	var before := [u.free_hex, u.move_spare, u.act]
	_pay_move(u, gait, reach.cost(target))
	u.acted = true
	if gait == &"laufen":
		u.ran = true
	if gait == &"sprinten":
		u.sprinted = true
	# Schritt für Schritt: Gegner in Feuerbereitschaft können unterwegs schießen
	var walked := 1
	for i in range(1, path.size()):
		var from := u.pos
		u.facing = Hex.dir_toward(path[i - 1], path[i])
		u.pos = path[i]
		walked += 1
		stepped.emit(u, from, u.pos, gait)
		_check_overwatch(u)
		if not u.is_ok() or result != &"":
			break
	if walked < path.size():
		# gestoppt: nur den gelaufenen Teil bezahlen
		u.free_hex = before[0]
		u.move_spare = before[1]
		u.act = before[2]
		_pay_move(u, gait, reach.cost(u.pos))
		log_text("%s wird mitten in der Bewegung gestoppt (bezahlt wird nur der gelaufene Weg)." % u.name)
	unit_changed.emit(u)
	return true


func do_face(u: Combatant, dir: int) -> bool:
	if not is_active(u):
		return false
	u.facing = posmod(dir, 6)
	faced.emit(u)
	return true


# ---------------------------------------------------------------- Angriff

func usable_weapons(u: Combatant) -> Array[WeaponData]:
	return u.weapons.filter(func(w: WeaponData) -> bool:
		if w.magazine > 0 and u.loaded.get(w.id, 0) <= 0:
			return false
		return not (w.pp_cost > 0 and u.pp < w.pp_cost))


## Ausweichen hängt an der zurückgehaltenen Aktivität: ½ immer, die andere ½ anteilig zur Reserve
func reserve_of(u: Combatant) -> int:
	return maxi(0, u.act) if current == u else u.reserve


## Verteidigungswert gegen einen Angriff (wie im Panel angezeigt)
func dodge_value(u: Combatant) -> int:
	var dodge := maxi(0, Rules.skill_total(u, &"ausweichen"))
	return dodge / 2 + int(dodge / 2.0 * maxi(0, u.act) / 100.0) + u.armor.db


func _defense_mods(def: Combatant, w: WeaponData, from: BattleMap.Tile, to: BattleMap.Tile, sense: bool, facing: int) -> Array:
	var mods: Array = []
	if w.psi:
		mods.append({"label": "Psi-Verteidigung", "val": maxi(0, Rules.skill_total(def, &"psiVerteidigung"))})
		if def.psi_shield > 0:
			mods.append({"label": "Psi-Schild", "val": PSI_SHIELD_BONUS})
		return mods
	var dodge := maxi(0, Rules.skill_total(def, &"ausweichen"))
	var reserve := reserve_of(def)
	var normal := dodge / 2 + int(dodge / 2.0 * reserve / 100.0)
	var surprised := Hex.sector(to.pos, facing, from.pos) != &"vorne"
	if def.stun > 0:
		mods.append({"label": "Ausweichen (betäubt)", "val": 0})
	elif surprised and sense:
		mods.append({"label": "Ausweichen (überrascht, Kampfsinn gelungen: ½)", "val": normal / 2})
	elif surprised:
		mods.append({"label": "Ausweichen (überrascht)", "val": 0})
	else:
		mods.append({"label": "Ausweichen (½ + Reserve %d %%)" % reserve, "val": normal})
	if def.armor.db:
		mods.append({"label": def.armor.name, "val": def.armor.db})
	if def.shield and not surprised:
		mods.append({"label": "Schild", "val": 10 + maxi(0, Rules.rank_bonus(Rules.skill_rank(def, &"schild")) / 2)})
	if not w.melee:
		var cov := map.cover(to, from)
		if not cov.is_empty() and cov.level == 1 and def.crouched:
			mods.append({"label": "Volle Deckung (geduckt hinter %s)" % cov.label, "val": BattleMap.COVER_BONUS[2], "full_cover": true})
		elif not cov.is_empty():
			mods.append({"label": "%s Deckung (%s)" % ["Volle" if cov.level == 2 else "Halbe", cov.label], "val": cov.bonus, "full_cover": cov.level == 2})
		if def.crouched:
			mods.append({"label": "geduckt", "val": CROUCH_DB})
	if def.psi_shield > 0:
		mods.append({"label": "Psi-Schild", "val": PSI_SHIELD_BONUS})
	return mods


## Vorschau oder Grundlage eines Angriffs. opts:
##   from (Tile, hypothetische Position), to / def_facing (hypothetische Lage des Ziels),
##   pct (eingesetzte Aktivität), reaction (Feuerbereitschaft), sense (Kampfsinn gelungen), preview
func attack_info(att: Combatant, def: Combatant, w: WeaponData, opts := {}) -> Dictionary:
	var from: BattleMap.Tile = opts.get("from", tile_of(att))
	var to: BattleMap.Tile = opts.get("to", tile_of(def))
	var pct: int = opts.get("pct", NORMAL_ATTACK)
	var def_facing: int = opts.get("def_facing", def.facing)
	var reaction: bool = opts.get("reaction", false)
	var dist := Hex.distance(from.pos, to.pos)
	var meters := dist * BattleMap.HEX_M
	if not def.is_ok():
		return _bad("Ziel ist kampfunfähig", w)
	if w.magazine > 0 and att.loaded.get(w.id, 0) <= 0:
		return _bad("nicht geladen", w)
	if w.pp_cost > 0 and att.pp < w.pp_cost:
		return _bad("zu wenig Psi-Punkte (%d nötig)" % w.pp_cost, w)
	var ob: Array = [{"label": Rules.skill_name(w.skill), "val": Rules.skill_total(att, w.skill)}]
	var dh := from.h - to.h
	if w.melee:
		if dist != 1:
			return _bad("nicht benachbart", w)
		if absi(dh) > 1:
			return _bad("Höhenunterschied zu groß", w)
		if dh:
			ob.append({"label": "höher stehend" if dh > 0 else "tiefer stehend", "val": 10 if dh > 0 else -10})
	else:
		var stage := maxi(1, ceili(meters / w.inc_m))
		if stage > w.stages:
			return _bad("außer Reichweite (%s m, max. %d m)" % [_m(meters), w.max_range_m()], w)
		if w.min_range_m and meters < w.min_range_m:
			return _bad("zu nah (mind. %d m)" % w.min_range_m, w)
		if not map.line_of_sight(from, to):
			return _bad("keine Sichtlinie", w)
		if dh:
			ob.append({"label": ("%d Stufe(n) höher" % dh) if dh > 0 else ("%d Stufe(n) tiefer" % -dh), "val": clampi(dh * 5, -15, 15)})
		if meters <= Tables.POINT_BLANK_M:
			ob.append({"label": "Kernschussweite (%s m)" % _m(meters), "val": 10})
		elif stage > 1:
			ob.append({"label": "Reichweitenstufe %d (%s m)" % [stage, _m(meters)], "val": Tables.RANGE_STEP * (stage - 1)})
	var a_mod := activity_mod(pct)
	if a_mod:
		ob.append({"label": "Aktivität %d %%" % pct, "val": a_mod})
	if reaction:
		ob.append({"label": "Reaktion (Feuerbereitschaft)", "val": REACTION_MOD})
	if att.ran and not reaction and not opts.get("preview", false):
		ob.append({"label": "gelaufen", "val": GAITS[&"laufen"].attack_mod})
	var sector := Hex.sector(to.pos, def_facing, from.pos)
	if FACING_MOD.has(sector):
		ob.append({"label": "Flanke" if sector == &"flanke" else "Rücken", "val": FACING_MOD[sector]})
	if att.crouched and not w.melee:
		ob.append({"label": "geduckt (ruhiger Anschlag)", "val": CROUCH_OB})
	if def.crouched and w.melee:
		ob.append({"label": "Ziel geduckt", "val": CROUCH_MELEE_OB})
	if w.ob_bonus:
		ob.append({"label": "Feuerstoß", "val": w.ob_bonus})
	if att.next_attack_malus:
		ob.append({"label": "Waffe klemmt", "val": att.next_attack_malus})
	if att.malus:
		ob.append({"label": "Wunden", "val": att.malus})
	var db := _defense_mods(def, w, from, to, opts.get("sense", false), def_facing)
	# Ziel in voller Deckung: nur gezielte Schüsse (mind. 60 % Aktivität), keine Reaktionsschüsse
	if not w.melee and not w.psi and db.any(func(m: Dictionary) -> bool: return m.get("full_cover", false)):
		if reaction:
			return _bad("Ziel in voller Deckung – kein Reaktionsschuss", w)
		if pct < NORMAL_ATTACK:
			return _bad("Ziel in voller Deckung – nur gezielter Schuss (mind. %d %% Aktivität)" % NORMAL_ATTACK, w)
	var net := _sum(ob) - _sum(db)
	var thr: int = w.table.thresholds[def.armor.cls]
	# Trefferchance: W100 (ohne Patzerbereich) + net >= thr; der offene Wurf nach oben wird vernachlässigt
	var need := maxi(thr - net, w.fumble + 1)
	return {"valid": true, "weapon": w, "ob": ob, "db": db, "net": net, "thr": thr,
		"chance": clampi(101 - need, 0, 100), "dist": dist, "meters": meters, "from": from, "to": to,
		"pct": pct, "sector": sector, "surprised": sector != &"vorne"}


func _bad(reason: String, w: WeaponData) -> Dictionary:
	return {"valid": false, "reason": reason, "weapon": w}


static func _m(meters: float) -> String:
	return String.num(meters, 1).replace(".", ",").trim_suffix(",0")


## Kosten eines Angriffs inkl. Waffenwechsel
func attack_cost(u: Combatant, w: WeaponData, pct: int) -> int:
	return pct + (COST.swap if w != u.weapon else 0)


func can_attack(u: Combatant) -> bool:
	return is_active(u) and not u.has_attacked and not u.stunned_now and not u.sprinted and u.act >= MIN_ATTACK


func do_attack(u: Combatant, target: Combatant, w: WeaponData, pct := NORMAL_ATTACK) -> bool:
	pct = roundi(pct / 10.0) * 10
	if not can_attack(u) or pct < MIN_ATTACK or pct > 100:
		return false
	if attack_cost(u, w, pct) > u.act:
		return false
	if not attack_info(u, target, w, {"pct": pct}).valid:
		return false
	# wer einen Gegner in Feuerbereitschaft vor sich hat, wird beim Ansetzen beschossen
	_check_overwatch(u)
	if not u.is_ok() or result != &"":
		return true
	var cost := attack_cost(u, w, pct)
	if w != u.weapon:
		u.weapon = w
		log_text("%s wechselt zu %s (−%d %%)." % [u.name, w.name, COST.swap])
	u.act -= cost
	u.has_attacked = true
	u.acted = true
	u.facing = Hex.dir_toward(u.pos, target.pos)
	faced.emit(u)
	var info := attack_info(u, target, w, {"pct": pct, "sense": _sense_check(u, target)})
	if info.valid:
		_resolve_attack(u, target, info)
	unit_changed.emit(u)
	return true


## Überraschung: Ziel, das den Angreifer nicht im Sichtfeld hat, darf Kampfsinn (Mittel) würfeln
func _sense_check(att: Combatant, def: Combatant) -> bool:
	if Hex.sector(def.pos, def.facing, att.pos) == &"vorne" or def.stun > 0:
		return false
	var m := _maneuver(def, &"kampfsinn", "mittel", _wound_mods(def), "%s: Kampfsinn (überrascht)" % def.name)
	var ok := Rules.is_success(m.result)
	log_text("%s wird von %s überrascht – Kampfsinn: Wurf %s → %d = %s%s." % [def.name, att.name,
		Dice.format_roll(m.roll), m.total, m.result.name, " (Ausweichen zählt halb)" if ok else ""], &"heal" if ok else &"miss")
	return ok


func _wound_mods(u: Combatant) -> Array:
	return [{"label": "Wunden", "val": u.malus}] if u.malus else []


func _maneuver(u: Combatant, skill_id: StringName, diff: String, mods: Array, label: String) -> Dictionary:
	var m := Rules.maneuver(u, skill_id, diff, mods)
	rolled.emit(m.roll, label)
	return m


func _resolve_attack(u: Combatant, target: Combatant, info: Dictionary, tag := "") -> void:
	var w: WeaponData = info.weapon
	if w.pp_cost:
		u.pp -= w.pp_cost
	if w.magazine:
		u.loaded[w.id] -= 1
	var roll := Dice.open_d100(w.fumble)
	rolled.emit(roll, "%s%s → %s (%s)" % ["Feuerbereitschaft: " if tag else "", u.name, target.name, w.name])
	Rules.award_xp(u, w.skill, 1)
	u.next_attack_malus = 0
	attacked.emit(u, target, w)
	if roll.fumble:
		_resolve_fumble(u, roll, w)
		return
	var raw: int = roll.total + info.net
	var total := mini(raw, w.max_result)
	var res := Tables.lookup_attack(w.table, total, target.armor.cls, w.damage)
	var head := "%s%s → %s (%s, %d %%): Wurf %s %s AW − %d VW = %d%s" % [tag, u.name, target.name, w.name, info.pct,
		Dice.format_roll(roll), Dice.fmt(_sum(info.ob)), _sum(info.db), total, " (max. %d)" % w.max_result if raw > w.max_result else ""]
	if not res.hit:
		log_text("%s → daneben (Schwelle %d)." % [head, res.threshold], &"miss")
		floated.emit(target, "daneben", &"miss")
		_defense_xp(target, w)
	else:
		log_text("%s → Treffer: %d TP%s." % [head, res.dmg, (", Kritischer %s" % res.severity) if res.severity else ""], &"hit")
		Rules.award_xp(u, w.skill, 1)
		if _sum(info.ob.slice(1)) - _sum(info.db) <= -20:
			Rules.award_xp(u, w.skill, 2)
		_apply_hit(u, target, res)
		if res.severity:
			Rules.award_xp(u, w.skill, 1)
	if not w.splash.is_empty():
		_resolve_splash(u, target, roll, info, w)
	check_end()


# ---------------------------------------------------------------- Feuerbereitschaft

func can_overwatch(u: Combatant, w: WeaponData) -> bool:
	return can_attack(u) and u.act >= MIN_OVERWATCH and attack_cost(u, w, MIN_OVERWATCH) <= u.act and usable_weapons(u).has(w)


func do_overwatch(u: Combatant, w: WeaponData) -> bool:
	if not can_overwatch(u, w):
		return false
	if w != u.weapon:
		u.act -= COST.swap
		u.weapon = w
	u.overwatch = {"weapon": w, "pct": mini(100, u.act / 10 * 10)}
	u.acted = true
	log_text("%s hält %d %% in Feuerbereitschaft (%s)." % [u.name, u.overwatch.pct, w.name])
	u.act = 0
	unit_changed.emit(u)
	return true


## Gegner in Feuerbereitschaft, die den Handelnden im Sichtfeld und in Reichweite haben, schießen (einmal je Runde)
func _check_overwatch(mover: Combatant) -> void:
	for w in opponents(mover):
		if not w.has_overwatch() or not mover.is_ok() or result != &"":
			continue
		if Hex.sector(w.pos, w.facing, mover.pos) != &"vorne":
			continue
		var weapon: WeaponData = w.overwatch.weapon
		var pct: int = w.overwatch.pct
		if not attack_info(w, mover, weapon, {"pct": pct, "reaction": true}).valid:
			continue
		w.overwatch = {}
		w.reserve = 0
		overwatch_fired.emit(w)
		w.facing = Hex.dir_toward(w.pos, mover.pos)
		faced.emit(w)
		var info := attack_info(w, mover, weapon, {"pct": pct, "reaction": true, "sense": _sense_check(w, mover)})
		if info.valid:
			_resolve_attack(w, mover, info, "Feuerbereitschaft! ")


# ---------------------------------------------------------------- Treffer, Kritische, Patzer

func _apply_hit(att: Combatant, target: Combatant, res: Dictionary) -> void:
	target.hp -= res.dmg
	floated.emit(target, "−%d" % res.dmg, &"hit")
	if res.severity:
		_apply_crit(target, Tables.roll_crit(res.crit, res.severity), res.severity)
	var was_ok := target.is_ok()
	_check_state(target)
	if was_ok and not target.is_ok():
		att.kills += 1
	unit_changed.emit(target)


func _apply_crit(u: Combatant, crit: Dictionary, sev: String) -> void:
	var r: CritRowData = crit.row
	if r.kill:
		u.hp = mini(u.hp, Rules.death_at(u))
	u.hp -= r.dmg
	u.bleed += r.bleed
	u.stun += r.stun
	u.malus += r.malus
	if r.prone:
		u.prone = true
	if r.ko and u.is_ok():
		u.state = Combatant.State.KO
		u.overwatch = {}
	if r.stun or r.prone:
		u.overwatch = {}
	var fx := r.effects()
	log_text("  Kritisch %s (%s), Wurf %d%s = %d: %s %s" % [sev, crit.table, crit.roll, Dice.fmt(Tables.SEVERITY_MOD[sev]),
		crit.total, r.text, ("[" + ", ".join(fx) + "]") if fx else ""], &"crit")
	floated.emit(u, "Krit %s" % sev, &"crit")


func _defense_xp(def: Combatant, w: WeaponData) -> void:
	if def.stun > 0:
		return
	Rules.award_xp(def, &"psiVerteidigung" if w.psi else &"ausweichen", 1)
	if def.shield and not w.psi:
		Rules.award_xp(def, &"schild", 1)


## Druckwelle: Ring 1 (1,5 m) und Ring 2 (3 m) mit eigenem Abzug, gleicher Wurf
func _resolve_splash(att: Combatant, target: Combatant, roll: Dictionary, info: Dictionary, w: WeaponData) -> void:
	for v in units:
		if v == target or not v.is_ok():
			continue
		var d := Hex.distance(v.pos, target.pos)
		if d < 1 or d > w.splash.size():
			continue
		var total := mini(roll.total + _sum(info.ob) + w.splash[d - 1], w.max_result)
		var res := Tables.lookup_attack(w.table, total, v.armor.cls, w.damage)
		if not res.hit:
			log_text("  Druckwelle verfehlt %s (%d)." % [v.name, total], &"miss")
			continue
		log_text("  Druckwelle trifft %s (%d): %d TP%s." % [v.name, total, res.dmg, (", Kritischer %s" % res.severity) if res.severity else ""], &"hit")
		_apply_hit(att, v, res)


func _resolve_fumble(u: Combatant, roll: Dictionary, w: WeaponData) -> void:
	var f := Tables.roll_fumble(fumbles)
	var row: FumbleRowData = f.row
	log_text("%s (%s): Wurf %d – PATZER! Patzerwurf %d: %s" % [u.name, w.name, roll.first, f.roll, row.text], &"fumble")
	floated.emit(u, "Patzer", &"fumble")
	if row.lose_turn and current == u:
		u.act = 0
		u.free_hex = 0
		u.move_spare = 0.0
	if row.next_malus:
		u.next_attack_malus = row.next_malus
	if row.prone:
		u.prone = true
	if row.self_damage:
		var d := Dice.d(10)
		u.hp -= d
		log_text("  %s erleidet %d TP." % [u.name, d], &"dmg")
		floated.emit(u, "−%d" % d, &"hit")
		_check_state(u)
	unit_changed.emit(u)
	check_end()


# ---------------------------------------------------------------- Ducken, Nachladen, Erste Hilfe, Psi

func can_crouch(u: Combatant) -> bool:
	return can_do(u, COST.crouch)


func do_crouch(u: Combatant) -> bool:
	if not can_crouch(u):
		return false
	u.act -= COST.crouch
	u.crouched = not u.crouched
	u.acted = true
	log_text("%s %s (−%d %%)." % [u.name, "duckt sich" if u.crouched else "steht auf", COST.crouch])
	crouched.emit(u)
	return true


func reloadable(u: Combatant) -> Array[WeaponData]:
	return u.weapons.filter(func(w: WeaponData) -> bool:
		return w.magazine > 0 and u.loaded.get(w.id, 0) < w.magazine and u.ammo.get(w.id, 0) > 0)


func do_reload(u: Combatant, w: WeaponData) -> bool:
	if not can_do(u, COST.reload) or not reloadable(u).has(w):
		return false
	u.act -= COST.reload
	u.acted = true
	var n := mini(w.magazine - u.loaded[w.id], u.ammo[w.id])
	u.loaded[w.id] += n
	u.ammo[w.id] -= n
	log_text("%s lädt %s nach (−%d %%, Reserve %d)." % [u.name, w.name, COST.reload, u.ammo[w.id]])
	reloaded.emit(u)
	return true


func first_aid_targets(u: Combatant) -> Array[Combatant]:
	return units.filter(func(o: Combatant) -> bool:
		return o.team == u.team and not o.is_dead() and Hex.distance(o.pos, u.pos) <= 1 \
			and (o.bleed > 0 or o.state == Combatant.State.KO or o.hp < o.max_hp))


func do_first_aid(u: Combatant, target: Combatant) -> bool:
	if not can_do(u, COST.aid) or not first_aid_targets(u).has(target):
		return false
	u.act -= COST.aid
	u.acted = true
	var mods := _wound_mods(u)
	if u.medkit > 0:
		mods.append({"label": "Medikit", "val": MEDKIT_BONUS})
		u.medkit -= 1
	u.facing = Hex.dir_toward(u.pos, target.pos) if target != u else u.facing
	faced.emit(u)
	acted.emit(u, &"aid")
	var m := _maneuver(u, &"ersteHilfe", "leicht", mods, "%s: Erste Hilfe bei %s" % [u.name, target.name])
	var fx: String
	match m.result.id:
		&"herausragend":
			var h := Dice.d(10) + Dice.d(10)
			target.bleed = 0
			target.stun = 0
			_heal(target, h)
			fx = "Blutung gestoppt, +%d TP, Betäubung aufgehoben" % h
		&"erfolg":
			var h := Dice.d(10)
			target.bleed = 0
			_heal(target, h)
			fx = "Blutung gestoppt, +%d TP" % h
		&"teilerfolg":
			var h := Dice.d(5)
			target.bleed /= 2
			_heal(target, h)
			fx = "Blutung halbiert, +%d TP" % h
		&"fehlschlag":
			fx = "keine Wirkung"
		_:
			var d := Dice.d(5)
			target.hp -= d
			_check_state(target)
			fx = "verschlimmert die Wunde (−%d TP)" % d
	log_text("%s leistet Erste Hilfe bei %s (−%d %%): Wurf %s → %d = %s: %s." % [u.name, target.name, COST.aid,
		Dice.format_roll(m.roll), m.total, m.result.name, fx], &"heal")
	unit_changed.emit(target)
	unit_changed.emit(u)
	return true


func _heal(u: Combatant, amount: int) -> void:
	u.hp = mini(u.max_hp, u.hp + amount)
	floated.emit(u, "+%d" % amount, &"heal")
	if u.state == Combatant.State.KO and u.hp > 0:
		u.state = Combatant.State.OK
		u.reserve = 0
		log_text("%s kommt wieder zu sich." % u.name, &"heal")


func psi_shield_targets(u: Combatant) -> Array[Combatant]:
	if Rules.skill_rank(u, &"psiWirken") < 1 or u.pp < PSI_SHIELD_PP:
		return []
	return units.filter(func(o: Combatant) -> bool: return o.team == u.team and o.is_ok() and Hex.distance(o.pos, u.pos) <= 4)


func do_psi_shield(u: Combatant, target: Combatant) -> bool:
	if not can_do(u, COST.psi) or not psi_shield_targets(u).has(target):
		return false
	u.act -= COST.psi
	u.pp -= PSI_SHIELD_PP
	u.acted = true
	acted.emit(u, &"psi")
	var m := _maneuver(u, &"psiWirken", "mittel", _wound_mods(u), "%s: Psi-Schild auf %s" % [u.name, target.name])
	var rounds: int = {&"herausragend": 3, &"erfolg": 2, &"teilerfolg": 1}.get(m.result.id, 0)
	if rounds:
		target.psi_shield = maxi(target.psi_shield, rounds)
	if m.result.id == &"patzer":
		u.stun += 1
	var fx := ("Psi-Schild auf %s für %d Runde(n)" % [target.name, rounds]) if rounds else ("Rückkopplung, betäubt 1" if m.result.id == &"patzer" else "keine Wirkung")
	log_text("%s wirkt Psi-Schild (−%d %%): Wurf %s → %d = %s: %s." % [u.name, COST.psi, Dice.format_roll(m.roll), m.total, m.result.name, fx], &"heal")
	unit_changed.emit(target)
	unit_changed.emit(u)
	return true
