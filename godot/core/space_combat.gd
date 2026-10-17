class_name SpaceCombat
extends RefCounted
## Regelkern Raumkampf V1 (docs/Raumkampf.md, docs/Planung_Raumkampf.md) ohne Grafik; meldet alles über Signale.
## Ablauf je Runde: Initiative (Navigation) → Phasen Schilde → Bewegen → Schießen → Technik/Computer, in jeder Phase
## die Schiffe nach Initiative. Die Crew gibt je Phase Befehle (set_orders), dann resolve(); Gegner steuert SpaceAI.
## Alle Zahlen sind Platzhalter bis zur Simulation (Entscheidung des Nutzers 16.10.2026).
##
## Befehle der Crew je Phase (alles optional, fehlende Teile = nichts tun bzw. Standard):
##  SHIELDS: {"energy": {"shields", "weapons", "engine", "jump"}, "alloc": [6 Schildwerte]}
##  MOVE:    {"speed": int, "steps": ["L"/"R"/"F", …]}  (F = ein Feld vor; genau `speed` Mal F, L/R = 60° drehen)
##  FIRE:    {"targets": {Geschützstation: Schiffs-ID}}
##  TECH:    {"technik": {"repair": System-ID} oder {"patch": true}, "computer": {"mode": "lock"/"jam", "target": ID},
##            "jump": true}

signal logged(text: String, kind: StringName)
signal rolled(roll: Dictionary, label: String)
signal round_started(number: int)
signal phase_started(phase: int)
signal ship_moved(ship: SpaceShip, path: Array[Vector2i])
signal ship_fired(ship: SpaceShip, target: SpaceShip, slot: String, res: Dictionary)
signal ship_changed(ship: SpaceShip)
signal ship_destroyed(ship: SpaceShip)
signal ended(result: StringName)

enum Phase { SHIELDS, MOVE, FIRE, TECH }
const PHASE_NAMES := ["Schilde", "Bewegen", "Schießen", "Technik / Computer"]

const MAP_W := 20
const MAP_H := 14
const MAX_ROUNDS := 40
const DIFF := "mittel"
## Flucht per Sprung: Vorbereitungsrunden, Energie je Vorbereitung, Treibstoff beim Sprung
const JUMP_ROUNDS := 2
const JUMP_ENERGY := 4
const JUMP_FUEL := 10
## Energie: Schildpunkte je Energiepunkt; Felder ohne Energie, darüber 1 Energie je Feld
const SHIELD_PER_ENERGY := 2
const ENGINE_FREE := 2
## Angriff: Schwelle je Waffenart und Zielklasse (Jäger, leicht, mittel, schwer)
const THRESHOLDS := {"strahl": [50, 40, 35, 35], "ballistik": [55, 40, 30, 25], "rakete": [60, 45, 35, 30],
	"abwehr": [35, 55, 65, 75]}
## Schadensfaktor aller Waffen (Abstimmung per Simulation, tests/sim_space.gd)
const DMG_SCALE := 0.9
const CRIT_GAP := 40
const CRIT_STEP := 15
const FUMBLE := 2
## Abfangen von Raketen durch Abwehrwaffen: Wurf + Bonus muss diesen Wert erreichen
const INTERCEPT_AT := 110
## Malus je Schadensstufe (0 = heil … 5 = E) für Stationen, Waffen, Sensoren
const SYS_MALUS := [0, -5, -10, -20, -30, -50]
## Schildaufladung je Schadensstufe des Systems „schilde“
const SHIELD_FACTOR := [1.0, 1.0, 0.75, 0.5, 0.25, 0.0]
## Energie weniger je Schadensstufe des Reaktors (E = keine Energie)
const REACTOR_LOSS := [0, 1, 2, 4, 6, 999]
## Höchsttempo weniger je Schadensstufe des Antriebs (E = steht)
const ENGINE_LOSS := [0, 0, 0, 1, 2, 99]
const CRIT_HULL := {"A": 0, "B": 2, "C": 4, "D": 6, "E": 10}
const PERSON_DMG := {"A": 3, "B": 6, "C": 10, "D": 15, "E": 25}
## Systemtreffer: W100 + Grad-Modifikator → System
const SYSTEM_TABLE := [[20, "antrieb"], [35, "sensoren"], [50, "slot"], [65, "schilde"], [75, "reaktor"],
	[85, "lebenserhaltung"], [999, "station"]]
const SYSTEM_NAMES := {"antrieb": "Antrieb", "sensoren": "Sensoren", "lebenserhaltung": "Lebenserhaltung",
	"schilde": "Schildgeneratoren", "reaktor": "Reaktor"}
## Entern möglich unter diesem Hüllenanteil (oder Antrieb E)
const BOARD_HULL := 0.25
## Umbesetzen während des Kampfs: nur zu Rundenbeginn (Phase Schilde), −10 an der neuen Station in dieser Runde
const SWITCH_MALUS := -10
const LOCK_BONUS := 15
const JAM_MALUS := -15
## Pilotenprobe → zusätzliche Drehungen und erlaubte Tempoänderung
const PILOT := {&"herausragend": [2, 2], &"erfolg": [1, 1], &"teilerfolg": [0, 1], &"fehlschlag": [0, 0],
	&"patzer": [-99, 0]}
## Schildprobe → Faktor der Aufladung
const SHIELD_ROLL := {&"herausragend": 1.5, &"erfolg": 1.0, &"teilerfolg": 0.75, &"fehlschlag": 0.5, &"patzer": 0.0}

var setup := {}
var rng := RandomNumberGenerator.new()
var cells := {}                    # Vector2i → true (Karte)
var rocks := {}                    # Vector2i → true (Asteroiden: blockieren Bewegung und Sicht)
var ships: Array[SpaceShip] = []
var own: SpaceShip
var crew: Array[Character] = []
var posts := {}                    # Station → Figur-ID oder SpaceSetup.KI
var people := {}                   # Figur-ID → {ch, hp, max_hp, state, worst_crit, malus}
var round_no := 0
var phase := Phase.SHIELDS
var order: Array[SpaceShip] = []
var orders := {}
var result: StringName = &""
var retreated := false
var surrendered := false
var boarding := false
var emergency := false
var jump_progress := 0
var energy_total := 0
var energy := {"shields": 0, "weapons": 0, "engine": 0, "jump": 0}
var ship_ammo := {}
var ammo_used := {}
var fuel_used := 0
var ransom := {}
var loot := {}
var faction_id := ""
var faction := {}
var own_vw := 0                    # VW des eigenen Schiffs in dieser Runde (Grund + halber Pilot-Bonus)
var intercepts := {}
## in dieser Runde umbesetzte Stationen (Malus SWITCH_MALUS bis Rundenende)
var switched := {}
var boarded: SpaceShip = null     # selbst geentertes Gegnerschiff
var board_loot := {}               # Schiffs-ID → Abfangversuche in dieser Runde


func _init(s: Dictionary, seed_value := -1) -> void:
	setup = s
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	faction_id = String(s.get("enemy", {}).get("faction", "piraten"))
	faction = SpaceTemplates.faction(faction_id)
	ship_ammo = s.get("ship_ammo", {}).duplicate()
	for ch in s.get("crew", []):
		crew.append(ch)
		ch.xp_log = {}
		var mh := Rules.max_hp(ch)
		people[String(ch.id)] = {"ch": ch, "hp": mh, "max_hp": mh, "state": "ok", "worst_crit": "", "malus": 0}
	_build_map()
	_build_own()
	posts = s.get("posts", {}).duplicate()
	for st in SpaceSetup.stations_for(own.slots):
		if not posts.has(st) or (posts[st] != SpaceSetup.KI and not people.has(String(posts[st]))):
			posts[st] = SpaceSetup.KI
	_build_enemies(String(s.get("enemy", {}).get("difficulty", "mittel")))


# ---------------------------------------------------------------- Aufbau

func _build_map() -> void:
	for row in MAP_H:
		for col in MAP_W:
			cells[Hex.from_offset(col, row)] = true
	for i in rng.randi_range(3, 5):
		var c := Hex.from_offset(rng.randi_range(7, MAP_W - 6), rng.randi_range(1, MAP_H - 2))
		rocks[c] = true
		for j in rng.randi_range(1, 3):
			var n: Vector2i = c + Hex.DIRS[rng.randi_range(0, 5)]
			if cells.has(n):
				rocks[n] = true


func _build_own() -> void:
	var sh: Dictionary = setup.get("ship", {})
	var lv: Dictionary = sh.get("levels", {})
	own = SpaceShip.new()
	own.id = "eigen"
	own.name = "Frontire"
	own.side = &"crew"
	own.cls = SpaceSetup.OWN_CLASS
	own.hull_max = int(sh.get("hull_max", 100))
	own.hull = clampi(int(sh.get("hull", own.hull_max)), 1, own.hull_max)
	own.shield_max = SpaceSetup.SHIELD_PER_SIDE[clampi(int(lv.get("shields", 0)), 0, 3)]
	own.armor = SpaceSetup.ARMOR_PER_HIT[clampi(int(lv.get("armor", 0)), 0, 3)]
	own.vw = SpaceSetup.OWN_VW
	own.max_speed = SpaceSetup.OWN_MAX_SPEED
	own.turns = SpaceSetup.OWN_TURNS
	own.speed = 2
	own.slots = sh.get("slots", SpaceSetup.start_slots()).duplicate(true)
	own.damage = sh.get("damage", {}).duplicate()
	var f: float = SHIELD_FACTOR[own.dmg_level("schilde")]
	for i in 6:
		own.shields[i] = roundi(own.shield_max * f)
	own.pos = _free_cell(Hex.from_offset(4, MAP_H / 2))
	own.facing = 0
	ships.append(own)


func _build_enemies(difficulty: String) -> void:
	var group := SpaceTemplates.pick_group(faction_id, difficulty, rng)
	var count := {}
	for t in group:
		count[t] = int(count.get(t, 0)) + 1
	var seen := {}
	for i in group.size():
		var t: String = group[i]
		seen[t] = int(seen.get(t, 0)) + 1
		var s := SpaceTemplates.make(t, int(seen[t]) if int(count[t]) > 1 else 0)
		s.id = "g%d" % i
		var row := MAP_H / 2 + (((i + 1) / 2) * (1 if i % 2 == 0 else -1)) * 2
		s.pos = _free_cell(Hex.from_offset(MAP_W - 3 - (i % 2), clampi(row, 1, MAP_H - 2)))
		s.facing = 3
		ships.append(s)


func _free_cell(want: Vector2i) -> Vector2i:
	if cells.has(want) and not rocks.has(want) and ship_at(want) == null:
		return want
	for r in range(1, 6):
		for c in cells:
			if Hex.distance(c, want) == r and not rocks.has(c) and ship_at(c) == null:
				return c
	return want


# ---------------------------------------------------------------- Abfragen

func log_text(text: String, kind: StringName = &"") -> void:
	logged.emit(text, kind)


func enemies() -> Array[SpaceShip]:
	var out: Array[SpaceShip] = []
	out.assign(ships.filter(func(s: SpaceShip) -> bool: return s.side == &"enemy"))
	return out


func active_enemies() -> Array[SpaceShip]:
	var out: Array[SpaceShip] = []
	out.assign(ships.filter(func(s: SpaceShip) -> bool: return s.side == &"enemy" and s.is_active()))
	return out


func ship_by_id(sid: String) -> SpaceShip:
	for s in ships:
		if s.id == sid:
			return s
	return null


func ship_at(p: Vector2i) -> SpaceShip:
	for s in ships:
		if s.is_active() and s.pos == p:
			return s
	return null


func is_free(p: Vector2i, except: SpaceShip = null) -> bool:
	if not cells.has(p) or rocks.has(p):
		return false
	var s := ship_at(p)
	return s == null or s == except


func stations() -> Array[String]:
	return SpaceSetup.stations_for(own.slots)


## Figur an der Station (null = Bord-KI oder nicht einsatzfähig → Bord-KI übernimmt)
func station_who(st: String) -> Character:
	var pid := String(posts.get(st, SpaceSetup.KI))
	if pid == SpaceSetup.KI or not people.has(pid):
		return null
	if people[pid].state != "ok":
		return null
	return people[pid].ch


func station_usable(st: String) -> bool:
	if own.is_out("station_" + st):
		return false
	if st.begins_with("geschuetz_"):
		var slot := st.trim_prefix("geschuetz_")
		return own.slots.has(slot) and String(own.slots[slot].get("key", "")) != "" and not own.is_out("slot_" + slot)
	return true


## Modifikatoren einer Station (ohne Fertigkeit): Doppelbesetzung, Verwundung, Stationsschaden, Lebenserhaltung
func station_mods(st: String) -> Array:
	var mods: Array = []
	var ch := station_who(st)
	if ch and switched.has(st):
		mods.append({"label": "Wechsel", "val": SWITCH_MALUS})
	if ch:
		var pid := String(ch.id)
		var n := 0
		for k in posts:
			if String(posts[k]) == pid:
				n += 1
		if n > 1:
			mods.append({"label": "Doppelbesetzung", "val": SpaceSetup.DOUBLE_MALUS})
		if ch.injury == Injury.LIGHT:
			mods.append({"label": "angeschlagen", "val": Injury.LIGHT_MALUS})
		if int(people[pid].malus) != 0:
			mods.append({"label": "verletzt", "val": int(people[pid].malus)})
	var d := own.dmg_level("station_" + st)
	if d > 0:
		mods.append({"label": "Station beschädigt", "val": SYS_MALUS[d]})
	var ls := own.dmg_level("lebenserhaltung")
	if ls > 0:
		mods.append({"label": "Lebenserhaltung", "val": SYS_MALUS[ls] / 2})
	return mods


static func _sum(mods: Array) -> int:
	var t := 0
	for m in mods:
		t += int(m.val)
	return t


## Gesamtbonus einer Station mit dieser Fertigkeit (Bord-KI: fester Bonus)
func station_bonus(st: String, skill: StringName) -> int:
	var ch := station_who(st)
	var base := Rules.skill_total(ch, skill) if ch else SpaceSetup.KI_BONUS
	return base + _sum(station_mods(st))


## Probe an einer Station (mit Figur über Rules.maneuver inkl. EP, sonst Bord-KI)
func check(st: String, skill: StringName, diff: String, extra: Array = []) -> Dictionary:
	var mods := station_mods(st)
	mods.append_array(extra)
	var ch := station_who(st)
	var r: Dictionary
	if ch:
		r = Rules.maneuver(ch, skill, diff, mods)
	else:
		var d: Dictionary = Rules.DIFFICULTY[diff]
		var roll := Dice.open_d100()
		var all: Array = [{"label": "Bord-KI", "val": SpaceSetup.KI_BONUS}, {"label": d.name, "val": d.mod}]
		all.append_array(mods)
		var total: int = roll.total + _sum(all)
		r = {"roll": roll, "mods": all, "total": total, "result": Rules.maneuver_result(total), "xp": 0}
	rolled.emit(r.roll, "%s: %s" % [SpaceSetup.station_name(st), Rules.skill_name(skill)])
	return r


func who_name(st: String) -> String:
	var ch := station_who(st)
	return ch.name if ch else "Bord-KI"


func reactor_energy() -> int:
	var lv: Dictionary = setup.get("ship", {}).get("levels", {})
	var e: int = SpaceSetup.REACTOR_ENERGY[clampi(int(lv.get("reactor", 0)), 0, 3)]
	return maxi(0, e - REACTOR_LOSS[own.dmg_level("reaktor")])


func max_speed_of(s: SpaceShip) -> int:
	return maxi(0, s.max_speed - ENGINE_LOSS[s.dmg_level("antrieb")])


func vw_of(s: SpaceShip) -> int:
	return own_vw if s == own else s.vw + s.crew_skill / 2


func can_surrender() -> bool:
	var r := int(faction.get("ransom", 0))
	return result == &"" and r > 0 and int(setup.get("credits", 0)) >= r


func can_jump() -> bool:
	return int(setup.get("fuel", 0)) >= JUMP_FUEL and station_usable("navigation")


# ---------------------------------------------------------------- Ablauf

func start() -> void:
	log_text("Kontakt: %s." % SpaceTemplates.faction_name(faction_id), &"round")
	_start_round()


func _start_round() -> void:
	round_no += 1
	switched = {}
	if round_no > MAX_ROUNDS:
		log_text("Die Gegner drehen ab – der Kampf endet ohne Entscheidung.", &"round")
		retreated = true
		_finish(&"niederlage")
		return
	energy_total = reactor_energy()
	energy = {"shields": 0, "weapons": 0, "engine": 0, "jump": 0}
	intercepts = {}
	own_vw = maxi(0, own.vw + station_bonus("steuer", &"pilot") / 2) if station_usable("steuer") else own.vw
	for s in ships:
		if not s.is_active():
			continue
		var init_b := s.init_bonus + s.crew_skill / 10
		if s == own:
			init_b = station_bonus("navigation", &"navigation") / 5 if station_usable("navigation") else 0
		s.initiative = Dice.d(10) + Dice.d(10) + init_b
	order.assign(ships.filter(func(s: SpaceShip) -> bool: return s.is_active()))
	order.sort_custom(func(a: SpaceShip, b: SpaceShip) -> bool: return a.initiative > b.initiative)
	round_started.emit(round_no)
	log_text("Runde %d" % round_no, &"round")
	_begin_phase(Phase.SHIELDS)


func _begin_phase(p: int) -> void:
	phase = p
	orders = {}
	phase_started.emit(p)


## Befehle der Crew für die laufende Phase (werden zusammengeführt)
func set_orders(o: Dictionary) -> void:
	orders.merge(o, true)


## Laufende Phase für alle Schiffe ausführen und zur nächsten Phase weitergehen
func resolve() -> void:
	if result != &"":
		return
	for s in order:
		if not s.is_active() or result != &"":
			continue
		var o: Dictionary = orders if s == own else SpaceAI.enemy_orders(self, s, phase)
		match phase:
			Phase.SHIELDS:
				_do_shields(s, o)
			Phase.MOVE:
				_do_move(s, o)
			Phase.FIRE:
				_do_fire(s, o)
			Phase.TECH:
				_do_tech(s, o)
		_check_end()
	if result != &"":
		return
	if phase == Phase.TECH:
		_end_round()
	else:
		_begin_phase(phase + 1)


## Crew und Gegner spielen selbst, bis der Kampf endet (Test, Simulation)
func run_auto() -> void:
	if round_no == 0:
		start()
	var guard := 0
	while result == &"" and guard < (MAX_ROUNDS + 2) * 4:
		guard += 1
		if boardable():
			board(boardable())
			break
		set_orders(SpaceAI.crew_orders(self, phase))
		resolve()


func _end_round() -> void:
	if jump_progress >= JUMP_ROUNDS:
		fuel_used += JUMP_FUEL
		log_text("Sprung! Die Frontire entkommt.", &"round")
		retreated = true
		_finish(&"niederlage")
		return
	_start_round()


func _check_end() -> void:
	if result != &"":
		return
	if own.hull <= 0:
		own.hull = 0
		if String(faction.get("on_win", "abziehen")) == "entern":
			boarding = true
			log_text("Die Frontire ist manövrierunfähig – %s gehen längsseits und entern!" % faction.name, &"bad")
		else:
			emergency = true
			log_text("Die Frontire ist manövrierunfähig. Die Gegner ziehen ab.", &"bad")
		_finish(&"niederlage")
	elif active_enemies().is_empty():
		_finish(&"sieg")


## Umbesetzen geht nur zu Rundenbeginn (vor der Schildphase)
func can_repost() -> bool:
	return result == &"" and round_no > 0 and phase == Phase.SHIELDS


## Fehler einer Postenliste ("" = gültig): höchstens zwei Stationen je Person, weitere Techniker nur mit Crew
static func posts_problem(p: Dictionary) -> String:
	var count := {}
	for st in p:
		var pid := String(p[st])
		if pid != SpaceSetup.KI:
			count[pid] = int(count.get(pid, 0)) + 1
			if count[pid] > 2:
				return "Eine Person kann höchstens zwei Stationen bedienen."
	return ""


## Posten zu Rundenbeginn neu besetzen; wer an eine Station neu kommt, hat dort in dieser Runde −10
func repost(p: Dictionary) -> bool:
	if not can_repost() or posts_problem(p) != "":
		return false
	for st in stations():
		var old := String(posts.get(st, SpaceSetup.KI))
		var neu := String(p.get(st, SpaceSetup.KI))
		if neu != SpaceSetup.KI and not people.has(neu):
			neu = SpaceSetup.KI
		if neu != old:
			if neu != SpaceSetup.KI:
				switched[st] = true
			log_text("Umbesetzt: %s → %s." % [SpaceSetup.station_name(st),
				people[neu].ch.name if neu != SpaceSetup.KI else "Bord-KI"])
		posts[st] = neu
	return true


## Kapitulation: Lösegeld zahlen, Kampf endet
func surrender() -> bool:
	if not can_surrender():
		return false
	surrendered = true
	ransom = {"credits": int(faction.ransom), "ship_ammo": {}}
	log_text("Kapitulation: %d Credits Lösegeld an %s." % [faction.ransom, faction.name], &"bad")
	_finish(&"niederlage")
	return true


func _finish(res: StringName) -> void:
	result = res
	for pid in people:
		var p: Dictionary = people[pid]
		if p.state == "sterbend":
			log_text("%s wird im Sanitätsraum stabilisiert." % p.ch.name)
	if res == &"sieg":
		_roll_loot()
		log_text("Sieg!", &"round")
	ended.emit(res)


# ---------------------------------------------------------------- Phase 1: Schilde und Energie

func _do_shields(s: SpaceShip, o: Dictionary) -> void:
	if s != own:
		_add_shields(s, s.shield_recharge * 6, [])
		return
	var e: Dictionary = o.get("energy", {})
	var left := energy_total
	for k in ["jump", "shields", "weapons", "engine"]:
		var v := clampi(int(e.get(k, 0)), 0, left)
		energy[k] = v
		left -= v
	energy.weapons += left   # Rest in die Waffen
	if not station_usable("schilde"):
		log_text("Schildstation ausgefallen – keine Aufladung.", &"bad")
		return
	var r := check("schilde", &"schutzschild", DIFF)
	var pts := roundi(energy.shields * SHIELD_PER_ENERGY * float(SHIELD_ROLL[r.result.id])
		* SHIELD_FACTOR[own.dmg_level("schilde")])
	var alloc: Array = o.get("alloc", []) if r.result.id in [&"herausragend", &"erfolg", &"teilerfolg"] else []
	_add_shields(own, pts, alloc)
	log_text("%s (%s): Schilde +%d (%s) · Energie %d: Schilde %d, Waffen %d, Antrieb %d, Sprung %d" % [
		who_name("schilde"), r.result.name, pts, _shield_text(own), energy_total, energy.shields, energy.weapons,
		energy.engine, energy.jump])
	ship_changed.emit(own)


## Schildpunkte dazugeben; alloc = gewünschte Verteilung (6 Werte) oder leer = auf die schwächsten Seiten
func _add_shields(s: SpaceShip, pts: int, alloc: Array) -> void:
	if s.shield_max <= 0 or s.is_out("schilde"):
		return
	var pool := mini(s.shield_total() + pts, s.shield_max * 6)
	if alloc.size() == 6:
		var want: Array[int] = []
		var sum := 0
		for v in alloc:
			var x := clampi(int(v), 0, s.shield_max)
			want.append(x)
			sum += x
		if sum > pool and sum > 0:
			var scale := float(pool) / sum
			for i in 6:
				want[i] = floori(want[i] * scale)
		for i in 6:
			s.shields[i] = want[i]
		# nicht verteilte Punkte gehen auf die schwächsten Seiten
		_fill_weakest(s, pool - s.shield_total())
		return
	_fill_weakest(s, pool - s.shield_total())


func _fill_weakest(s: SpaceShip, add: int) -> void:
	while add > 0:
		var low := 0
		for i in 6:
			if s.shields[i] < s.shields[low]:
				low = i
		if s.shields[low] >= s.shield_max:
			break
		s.shields[low] += 1
		add -= 1


func _shield_text(s: SpaceShip) -> String:
	var parts := PackedStringArray()
	for v in s.shields:
		parts.append(str(v))
	return "/".join(parts)


# ---------------------------------------------------------------- Phase 2: Bewegen

## Vorschau eines Bewegungsplans ohne Änderung: {path (Felder nacheinander), facing, blocked}
func plan_path(s: SpaceShip, steps: Array) -> Dictionary:
	var p := s.pos
	var f := s.facing
	var path: Array[Vector2i] = []
	var blocked := false
	for st in steps:
		match String(st):
			"L":
				f = posmod(f + 1, 6)
			"R":
				f = posmod(f - 1, 6)
			"F":
				var n: Vector2i = p + Hex.DIRS[f]
				if not is_free(n, s):
					blocked = true
					break
				p = n
				path.append(p)
	return {"path": path, "facing": f, "end": p, "blocked": blocked}


## Plan auf das Erlaubte kürzen: Tempo (±delta, Höchsttempo), Drehungen, Energie
func _trim_plan(s: SpaceShip, want_speed: int, steps: Array, max_turns: int, delta: int, engine: int) -> Array:
	var spd := clampi(want_speed, maxi(0, s.speed - delta), mini(max_speed_of(s), s.speed + delta))
	if s == own:
		spd = mini(spd, ENGINE_FREE + engine)
	var out: Array = []
	var fwd := 0
	var turns := 0
	for st in steps:
		if st == "F" and fwd < spd:
			out.append("F")
			fwd += 1
		elif (st == "L" or st == "R") and turns < max_turns:
			out.append(st)
			turns += 1
	while fwd < spd:
		out.append("F")
		fwd += 1
	return out


func _do_move(s: SpaceShip, o: Dictionary) -> void:
	var extra := 0
	var delta := 1
	if s == own:
		if not station_usable("steuer"):
			extra = -99
			delta = 0
			log_text("Steuer ausgefallen – das Schiff treibt weiter.", &"bad")
		else:
			var r := check("steuer", &"pilot", DIFF)
			extra = PILOT[r.result.id][0]
			delta = PILOT[r.result.id][1]
			log_text("%s steuert (%s)." % [who_name("steuer"), r.result.name])
	elif s.crew_skill >= 40:
		extra = 1
	var max_turns := maxi(0, s.turns + extra) if not s.is_out("antrieb") else 0
	var steps: Array = o.get("steps", [])
	var want := int(o.get("speed", s.speed))
	var plan := _trim_plan(s, want, steps, max_turns, delta, energy.engine if s == own else 99)
	var spd := plan.count("F")
	var pv := plan_path(s, plan)
	var path: Array[Vector2i] = pv.path
	s.pos = pv.end
	s.facing = pv.facing
	s.speed = spd
	if pv.blocked:
		s.speed = path.size()
		log_text("%s muss ausweichen und bremst ab." % s.name)
	if s == own:
		energy.engine = maxi(0, energy.engine - maxi(0, path.size() - ENGINE_FREE))
	ship_moved.emit(s, path)


# ---------------------------------------------------------------- Phase 3: Schießen

## Feuerbogen eines Slots (Peilung relativ zum Bug, positiv = Steuerbord)
func in_arc(s: SpaceShip, slot: String, to: Vector2i) -> bool:
	var b := s.bearing(to)
	if slot.begins_with("turm"):
		return true
	if s != own:
		return absf(b) <= (60.0 if s.is_fighter() else 120.0) + 0.1
	match slot.trim_suffix("2"):
		"bug":
			return absf(b) <= 60.1
		"steuerbord":
			return b >= 29.9 and b <= 150.1
		"backbord":
			return b <= -29.9 and b >= -150.1
		"heck":
			return absf(b) >= 119.9
	return false


## Schätzung, wohin die Gegner in dieser Runde ziehen (KI-Plan vom jetzigen Stand aus): {ID: {pos, facing}}
func predict_enemies() -> Dictionary:
	var out := {}
	for e in active_enemies():
		var pv := plan_path(e, SpaceAI.enemy_orders(self, e, Phase.MOVE).get("steps", []))
		out[e.id] = {"pos": pv.end, "facing": pv.facing}
	return out


## Ziel-Check für einen Bewegungsplan: je Waffen-Slot die Gegner mit Grund ("" = feuerbereit) und Abstand,
## eigene Lage nach dem Plan, Gegner an den geschätzten Positionen (predict)
func preview_fire(pos: Vector2i, facing: int, predict: Dictionary) -> Dictionary:
	var keep_pos := own.pos
	var keep_f := own.facing
	var keep := {}
	own.pos = pos
	own.facing = facing
	for e in active_enemies():
		keep[e.id] = e.pos
		if predict.has(e.id):
			e.pos = predict[e.id].pos
	var out := {}
	for slot in own.weapon_slots():
		var rows: Array = []
		for e in active_enemies():
			rows.append({"ship": e, "why": fire_problem(own, slot, e), "dist": Hex.distance(own.pos, e.pos)})
		out[slot] = rows
	own.pos = keep_pos
	own.facing = keep_f
	for e in active_enemies():
		e.pos = keep[e.id]
	return out


## Sichtlinie: Asteroiden zwischen den Schiffen sperren
func has_los(a: Vector2i, b: Vector2i) -> bool:
	for p in Hex.line(a, b):
		if p != a and p != b and rocks.has(p):
			return false
	return true


## Kann dieser Slot dieses Ziel beschießen? "" = ja, sonst der Grund
func fire_problem(s: SpaceShip, slot: String, t: SpaceShip) -> String:
	if t == null or not t.is_active() or t.side == s.side:
		return "kein Ziel"
	var key := String(s.slots.get(slot, {}).get("key", ""))
	if key == "":
		return "keine Waffe"
	if s.is_out("slot_" + slot):
		return "Waffe ausgefallen"
	var w := ShipWeapons.data(key)
	if not in_arc(s, slot, t.pos):
		return "außerhalb des Feuerbogens"
	if Hex.distance(s.pos, t.pos) > int(w.range) * 2:
		return "außer Reichweite"
	if not has_los(s.pos, t.pos):
		return "keine Sicht (Asteroiden)"
	if s == own:
		if not station_usable(SpaceSetup.gun_station(slot)):
			return "Station ausgefallen"
		if w.ammo != "" and int(ship_ammo.get(w.ammo, 0)) <= 0:
			return "keine Munition"
		if w.ammo == "" and int(energy.weapons) < int(w.energy):
			return "zu wenig Energie"
	return ""


## Angriffsbonus ohne Wurf: {base, mods, threshold}
func attack_info(s: SpaceShip, slot: String, t: SpaceShip) -> Dictionary:
	var key := String(s.slots[slot].key)
	var w := ShipWeapons.data(key)
	var mods: Array = []
	if s == own:
		var st := SpaceSetup.gun_station(slot)
		var ch := station_who(st)
		mods.append({"label": ch.name if ch else "Bord-KI",
			"val": Rules.skill_total(ch, ShipWeapons.skill(key)) if ch else SpaceSetup.KI_BONUS})
		mods.append_array(station_mods(st))
	else:
		mods.append({"label": "Besatzung", "val": s.crew_skill})
	mods.append({"label": w.name, "val": int(w.mod)})
	var wd := int(s.slots[slot].get("damage", 0))
	if wd != 0:
		mods.append({"label": "Waffe beschädigt", "val": wd})
	var sd := s.dmg_level("slot_" + slot)
	if sd > 0:
		mods.append({"label": "Slot beschädigt", "val": SYS_MALUS[sd]})
	var sens := s.dmg_level("sensoren")
	if sens > 0:
		mods.append({"label": "Sensoren", "val": SYS_MALUS[sens]})
	var over := Hex.distance(s.pos, t.pos) - int(w.range)
	if over > 0:
		mods.append({"label": "Entfernung", "val": -10 * over})
	if s.lock.has(t.id):
		mods.append({"label": "Zielerfassung", "val": int(s.lock[t.id])})
	if s.jammed != 0:
		mods.append({"label": "Störsender", "val": s.jammed})
	mods.append({"label": "VW %s" % t.name, "val": -vw_of(t)})
	return {"mods": mods, "threshold": int(THRESHOLDS[w.art][t.cls]), "weapon": w, "key": key}


func _do_fire(s: SpaceShip, o: Dictionary) -> void:
	var targets: Dictionary = o.get("targets", {})
	for slot in s.weapon_slots():
		var tid := String(targets.get(SpaceSetup.gun_station(slot), "") if s == own else targets.get(slot, ""))
		if tid == "":
			continue
		var t := ship_by_id(tid)
		var w := ShipWeapons.data(String(s.slots[slot].key))
		for shot in int(w.shots):
			if result != &"" or t == null or not t.is_active():
				break
			var why := fire_problem(s, slot, t)
			if why != "":
				if shot == 0 and s == own:
					log_text("%s: %s." % [SpaceSetup.station_name(SpaceSetup.gun_station(slot)), why])
				break
			fire(s, slot, t)


## Ein Schuss: Wurf, Abfangen (Raketen), Schild, Panzerung, Hülle, Systemtreffer
func fire(s: SpaceShip, slot: String, t: SpaceShip) -> Dictionary:
	var info := attack_info(s, slot, t)
	var w: Dictionary = info.weapon
	if s == own:
		if w.ammo != "":
			ship_ammo[w.ammo] = int(ship_ammo.get(w.ammo, 0)) - 1
			ammo_used[w.ammo] = int(ammo_used.get(w.ammo, 0)) + 1
		else:
			energy.weapons -= int(w.energy)
	var roll := Dice.open_d100(FUMBLE)
	var total: int = roll.total + _sum(info.mods)
	var res := {"roll": roll, "total": total, "threshold": info.threshold, "hit": false, "dmg": 0, "severity": "",
		"intercepted": false, "fumble": roll.fumble}
	rolled.emit(roll, "%s → %s" % [w.name, t.name])
	var gunner: Character = station_who(SpaceSetup.gun_station(slot)) if s == own else null
	if roll.fumble:
		log_text("%s: Patzer mit %s!" % [s.name, w.name], &"bad")
		_damage_system(s, "slot_" + slot, "A")
	elif total >= info.threshold:
		res.hit = true
		if w.art == "rakete" and _intercept(t, s):
			res.intercepted = true
		else:
			res.dmg = maxi(1, roundi((3.0 + (total - info.threshold) / 5.0) * float(w.dmg) * DMG_SCALE))
			if total >= info.threshold + CRIT_GAP:
				res.severity = Tables.SEVERITIES[mini(4, (total - info.threshold - CRIT_GAP) / CRIT_STEP)]
			_apply_hit(s, t, res)
	if gunner:
		Rules.award_xp(gunner, ShipWeapons.skill(info.key), 2 if res.hit else 1)
	if not res.hit and not roll.fumble:
		log_text("%s → %s: %s verfehlt (%d gegen %d)." % [s.name, t.name, w.name, total, info.threshold])
	ship_fired.emit(s, t, slot, res)
	return res


## Abwehrwaffen des Ziels versuchen, eine Rakete abzufangen
func _intercept(t: SpaceShip, from: SpaceShip) -> bool:
	for slot in t.weapon_slots():
		var key := String(t.slots[slot].key)
		var w := ShipWeapons.data(key)
		if w.art != "abwehr" or t.is_out("slot_" + slot):
			continue
		var used := int(intercepts.get(t.id + slot, 0))
		if used >= int(w.shots):
			continue
		var bonus := t.crew_skill
		var gunner: Character = null
		if t == own:
			var st := SpaceSetup.gun_station(slot)
			if not station_usable(st):
				continue
			gunner = station_who(st)
			bonus = station_bonus(st, ShipWeapons.skill(key))
		intercepts[t.id + slot] = used + 1
		var roll := Dice.open_d100()
		var total: int = roll.total + bonus + int(w.mod) + int(t.slots[slot].get("damage", 0))
		rolled.emit(roll, "%s fängt ab" % w.name)
		if gunner:
			Rules.award_xp(gunner, ShipWeapons.skill(key), 1)
		if total >= INTERCEPT_AT:
			log_text("%s: %s fängt die Rakete von %s ab." % [t.name, w.name, from.name])
			return true
	return false


func _apply_hit(s: SpaceShip, t: SpaceShip, res: Dictionary) -> void:
	var side := t.side_toward(s.pos)
	var absorbed := mini(t.shields[side], int(res.dmg))
	t.shields[side] -= absorbed
	var rest: int = res.dmg - absorbed
	var hull_dmg := maxi(0, rest - t.armor) if rest > 0 else 0
	t.hull -= hull_dmg
	var txt := "%s trifft %s (%s): %d Schaden" % [s.name, t.name, SpaceShip.SIDE_NAMES[side], res.dmg]
	if absorbed > 0:
		txt += ", Schild %d" % absorbed
	txt += ", Hülle %d" % hull_dmg
	log_text(txt + ".", &"hit")
	if res.severity != "" and rest > 0:
		_system_hit(t, String(res.severity))
	if t.hull <= 0 and t != own:
		t.hull = 0
		t.destroyed = true
		log_text("%s ist zerstört!" % t.name, &"kill")
		ship_destroyed.emit(t)
	ship_changed.emit(t)


## Kritischer Systemtreffer der Stufe sev
func _system_hit(t: SpaceShip, sev: String) -> void:
	t.hull -= int(CRIT_HULL[sev])
	if t.is_fighter():
		t.hull -= int(CRIT_HULL[sev])
		log_text("Kritischer Treffer %s bei %s." % [sev, t.name], &"crit")
		return
	var roll := Dice.d100() + int(Tables.SEVERITY_MOD[sev])
	var sys := "station"
	for row in SYSTEM_TABLE:
		if roll <= int(row[0]):
			sys = String(row[1])
			break
	if sys == "slot":
		var ws := t.weapon_slots()
		sys = "slot_" + ws[rng.randi_range(0, ws.size() - 1)] if not ws.is_empty() else "antrieb"
	elif sys == "station":
		if t != own:
			sys = "lebenserhaltung"
		else:
			var sts := stations()
			sys = "station_" + sts[rng.randi_range(0, sts.size() - 1)]
	_damage_system(t, sys, sev)
	if sys.begins_with("station_") and t == own:
		var st := sys.trim_prefix("station_")
		var ch := station_who(st)
		if ch:
			_hurt(ch, sev)


## Systemschaden setzen: die schwerere Stufe; dieselbe Stufe noch einmal = eine Stufe schlimmer
func _damage_system(t: SpaceShip, sys: String, sev: String) -> void:
	var old := t.dmg_level(sys)
	var lv := Tables.SEVERITIES.find(sev) + 1
	var new_lv := mini(5, old + 1) if lv == old else maxi(old, lv)
	t.damage[sys] = Tables.SEVERITIES[new_lv - 1]
	if sys.begins_with("slot_"):
		var slot := sys.trim_prefix("slot_")
		if new_lv >= 2 and t.slots.has(slot):
			t.slots[slot].damage = maxi(-30, int(t.slots[slot].get("damage", 0)) - 10)
	if sys == "schilde" and new_lv == 5:
		for i in 6:
			t.shields[i] = 0
	log_text("Systemtreffer %s bei %s: %s." % [t.damage[sys], t.name, system_name(sys)], &"crit")
	ship_changed.emit(t)


func system_name(sys: String) -> String:
	if sys.begins_with("slot_"):
		var slot := sys.trim_prefix("slot_")
		return "Waffe %s" % SpaceSetup.SLOT_NAMES.get(slot, slot)
	if sys.begins_with("station_"):
		return "Station %s" % SpaceSetup.station_name(sys.trim_prefix("station_"))
	return String(SYSTEM_NAMES.get(sys, sys))


func _hurt(ch: Character, sev: String) -> void:
	var p: Dictionary = people[String(ch.id)]
	p.hp -= int(PERSON_DMG[sev])
	if p.worst_crit == "" or Tables.SEVERITIES.find(sev) > Tables.SEVERITIES.find(p.worst_crit):
		p.worst_crit = sev
	p.malus = mini(int(p.malus), -5 * (Tables.SEVERITIES.find(sev) + 1))
	var txt := "%s wird an der Station verletzt (Kritischer %s, Explosion)" % [ch.name, sev]
	if p.hp <= Rules.death_at(ch):
		p.state = "sterbend"
		txt += " und ist schwer verwundet. Die Bord-KI übernimmt"
	elif p.hp <= 0:
		p.state = "ko"
		txt += " und fällt aus. Die Bord-KI übernimmt"
	log_text(txt + ".", &"bad")


# ---------------------------------------------------------------- Phase 4: Technik, Computer, Sprung

func _do_tech(s: SpaceShip, o: Dictionary) -> void:
	if s != own:
		var flee := float(faction.get("flee_at", 0.0))
		if flee > 0.0 and not s.is_fighter() and not s.is_out("antrieb") and s.hull < s.hull_max * flee:
			s.fled = true
			log_text("%s dreht ab und flieht." % s.name, &"round")
			ship_changed.emit(s)
		return
	# Zielerfassung und Störsender gelten bis zur nächsten Technikphase
	own.lock = {}
	for e in enemies():
		e.jammed = 0
	for st in tech_tasks(o):
		var tasks: Array = tech_tasks(o)[st]
		for n in mini(2, tasks.size()):
			_tech_task(st, tasks[n], [{"label": "2. Baustelle", "val": SpaceSetup.SECOND_TASK_MALUS}] if n == 1 else [])
	var comp: Dictionary = o.get("computer", {})
	var target := ship_by_id(String(comp.get("target", "")))
	if target and target.is_active() and station_usable("computer"):
		var sens := own.dmg_level("sensoren")
		var r := check("computer", &"computer", DIFF, [{"label": "Sensoren", "val": SYS_MALUS[sens]}] if sens > 0 else [])
		if Rules.is_success(r.result):
			if String(comp.get("mode", "lock")) == "jam":
				target.jammed = JAM_MALUS
				log_text("%s stört %s." % [who_name("computer"), target.name])
			else:
				own.lock[target.id] = LOCK_BONUS
				log_text("%s erfasst %s." % [who_name("computer"), target.name])
		else:
			log_text("%s: Computer ohne Erfolg (%s)." % [who_name("computer"), r.result.name])
	if o.get("jump", false):
		_prepare_jump()
	ship_changed.emit(own)


## Technik-Befehle als {Station: [Aufgabe, …]}; Aufgabe {"repair": System} oder {"patch": true}.
## Altes Format {"technik": {"repair"/"patch"}} gilt als eine Aufgabe der Station „technik“.
func tech_tasks(o: Dictionary) -> Dictionary:
	var t: Dictionary = o.get("technik", {})
	if t.has("repair") or t.has("patch"):
		t = {"technik": [t]}
	var out := {}
	for st in t:
		if SpaceSetup.is_tech(String(st)) and tech_active(String(st)):
			out[String(st)] = t[st] if t[st] is Array else [t[st]]
	return out


## Technikstation arbeitet: die Hauptstation auch mit der Bord-KI, weitere Techniker nur mit Crew
func tech_active(st: String) -> bool:
	if not station_usable(st):
		return false
	return st == "technik" or station_who(st) != null


func _tech_task(st: String, task: Dictionary, extra: Array) -> void:
	if task.has("repair") and own.damage.has(String(task.repair)):
		var sys := String(task.repair)
		var r := check(st, &"notReparatur", "schwer", extra)
		var steps := 2 if r.result.id == &"herausragend" else (1 if r.result.id == &"erfolg" else 0)
		if steps > 0:
			var lv := own.dmg_level(sys) - steps
			if lv <= 0:
				own.damage.erase(sys)
			else:
				own.damage[sys] = Tables.SEVERITIES[lv - 1]
		log_text("%s repariert %s (%s)%s." % [who_name(st), system_name(sys), r.result.name,
			"" if steps == 0 else (": jetzt " + String(own.damage.get(sys, "heil")))])
	elif task.get("patch", false):
		var r := check(st, &"panzerung", DIFF, extra)
		var plus := 0
		if Rules.is_success(r.result):
			plus = mini(own.hull_max - own.hull, Dice.d(6) + Dice.d(6) + (5 if r.result.id == &"herausragend" else 0))
			own.hull += plus
		log_text("%s flickt die Hülle (%s): +%d." % [who_name(st), r.result.name, plus])


# ---------------------------------------------------------------- Selbst entern

## Enterbar: Schiff mit Besatzung (kein Jäger), direkt benachbart, Antrieb ausgefallen oder Hülle unter 25 %,
## und es kämpft kein anderer Gegner mehr (Entscheidungen des Nutzers 16.10.2026)
func can_board(t: SpaceShip) -> bool:
	if result != &"" or t == null or not t.is_active() or t.side != &"enemy" or t.is_fighter():
		return false
	if Hex.distance(own.pos, t.pos) != 1:
		return false
	if not (t.is_out("antrieb") or t.hull < t.hull_max * BOARD_HULL):
		return false
	return active_enemies().size() == 1


func boardable() -> SpaceShip:
	for e in active_enemies():
		if can_board(e):
			return e
	return null


## Entern: der Raumkampf endet, der Hub startet den Bodenkampf gegen die Besatzung
func board(t: SpaceShip) -> bool:
	if not can_board(t):
		return false
	boarded = t
	log_text("Die Frontire geht längsseits und entert %s!" % t.name, &"round")
	_finish(&"sieg")
	return true


func _prepare_jump() -> void:
	if not can_jump():
		log_text("Sprung nicht möglich (Treibstoff oder Navigation).", &"bad")
		return
	if int(energy.jump) < JUMP_ENERGY:
		log_text("Zu wenig Energie für die Sprungvorbereitung (%d nötig)." % JUMP_ENERGY, &"bad")
		return
	var r := check("navigation", &"navigation", DIFF)
	if r.result.id == &"patzer":
		jump_progress = 0
	elif Rules.is_success(r.result):
		jump_progress += 1
	log_text("%s bereitet den Sprung vor (%s): %d/%d." % [who_name("navigation"), r.result.name, jump_progress,
		JUMP_ROUNDS])


# ---------------------------------------------------------------- Ende und Ergebnis

func _roll_loot() -> void:
	var credits := 0
	var material := 0
	var am := {}
	var weapons: Array = []
	for e in enemies():
		if not e.destroyed:
			continue
		var t: Dictionary = SpaceTemplates.ship(e.template)
		credits += roundi(int(t.credits) * rng.randf_range(0.6, 1.0))
		material += int(t.material)
		if e.is_fighter():
			continue
		am["schiffsraketen"] = int(am.get("schiffsraketen", 0)) + rng.randi_range(0, 2)
		am["geschosse"] = int(am.get("geschosse", 0)) + rng.randi_range(0, 10)
		if rng.randf() < 0.35:
			var tradable: Array[String] = []
			for sl in e.weapon_slots():
				if ShipWeapons.data(String(e.slots[sl].key)).trade:
					tradable.append(sl)
			if not tradable.is_empty():
				var key := String(e.slots[tradable[rng.randi_range(0, tradable.size() - 1)]].key)
				weapons.append({"key": key, "name": ShipWeapons.name(key), "damage": [-10, -20, -30][rng.randi_range(0, 2)]})
	loot = {"credits": credits, "material": material, "ship_ammo": am, "weapons": weapons}
	if boarded:
		# Beute des geenterten Schiffs: gilt erst, wenn die Crew den Bodenkampf gewinnt (bucht der Hub)
		var t: Dictionary = SpaceTemplates.ship(boarded.template)
		var bw: Array = []
		for sl in boarded.weapon_slots():
			var key := String(boarded.slots[sl].key)
			if ShipWeapons.data(key).trade:
				bw.append({"key": key, "name": ShipWeapons.name(key), "damage": maxi(-30, int(boarded.slots[sl].damage))})
		board_loot = {"credits": roundi(int(t.credits) * 1.5), "material": int(t.material) * 2,
			"ship_ammo": {"schiffsraketen": rng.randi_range(2, 4), "geschosse": rng.randi_range(10, 20)}, "weapons": bw}


## Ergebnis im Format MissionResult plus Schiffsteil (Schnittstelle docs/module/raumkampf.md)
func to_result() -> Dictionary:
	var units := {}
	for pid in people:
		var p: Dictionary = people[pid]
		var ch: Character = p.ch
		units[ch.id] = {
			"xp": ch.xp_log.duplicate(),
			"free_xp": MissionResult.FREE_XP,
			"kills": 0,
			"status": {"state": p.state, "hp": p.hp, "max_hp": p.max_hp, "bleed": 0, "malus": p.malus},
			"worst_crit": p.worst_crit,
			"dying": false,
			"stabilized": p.state == "sterbend",
			"died": false,
			"used": {"medkits": 0, "ammo": {}},
		}
	var slots := own.slots.duplicate(true)
	return {"outcome": result, "retreated": retreated, "mission": String(setup.get("mission", "")),
		"rounds": round_no, "reward_xp": 0, "units": units, "ammo_used": {}, "loot": [],
		"space": true, "surrendered": surrendered, "ransom": ransom.duplicate(true),
		"boarding": boarding, "boarding_faction": faction_id if boarding else "", "emergency": emergency,
		"ship": {"hull": own.hull, "damage": own.damage.duplicate(), "slots": slots},
		"ship_ammo_used": ammo_used.duplicate(), "fuel_used": fuel_used,
		"ship_loot": loot.duplicate(true) if result == &"sieg" else {},
		"board_enemy": boarded != null, "board_faction": faction_id if boarded else "",
		"board_ship": boarded.name if boarded else "", "board_loot": board_loot.duplicate(true)}
