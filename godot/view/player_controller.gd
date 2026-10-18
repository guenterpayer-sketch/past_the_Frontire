class_name PlayerController
extends RefCounted
## Spielerseite des Kampfes: gewählte Waffe, Gangart, Angriffsaktivität und Modus (bewegen, Erste Hilfe,
## Psi-Schild, ausrichten). Berechnet Vorschau, Reichweite und Tooltips und führt Klicks als Aktionen aus.

enum Mode { MOVE, AID, PSI, FACE }

var combat: Combat
var mode := Mode.MOVE
var gait: StringName = &"gehen"
var pct := Combat.NORMAL_ATTACK
var show_range := false
var power := ""              # gewählte unterstützende Psi-Kraft (Mode.PSI), PsiCombat-Schlüssel
var psi_tab: StringName = &""  # geöffneter Listen-Reiter im Aktionsblock
var _weapon_sel := {}       # Combatant -> WeaponData
var _reach_key := ""
var _reach: BattleMap.Reach
var _preview_key := ""
var _preview := {}
var _range_key := ""
var _range := {}


func _init(c: Combat) -> void:
	combat = c


func reset_turn() -> void:
	mode = Mode.MOVE
	gait = &"gehen"
	pct = Combat.NORMAL_ATTACK


func weapon_of(u: Combatant) -> WeaponData:
	var usable := combat.usable_weapons(u)
	var w: WeaponData = _weapon_sel.get(u, u.weapon)
	if not usable.has(w):
		w = usable[0] if not usable.is_empty() else u.weapons[0]
	return w


func select_weapon(u: Combatant, w: WeaponData) -> void:
	_weapon_sel[u] = w


## Aktivität für den Angriff: gewählter Wert, begrenzt durch das, was noch übrig ist (inkl. Waffenwechsel)
func max_attack_pct(u: Combatant, w: WeaponData) -> int:
	return mini(100, (u.act - (Combat.COST.swap if w != u.weapon else 0)) / 10 * 10)


func attack_pct(u: Combatant, w: WeaponData) -> int:
	return maxi(Combat.MIN_ATTACK, mini(pct, max_attack_pct(u, w)))


func can_attack_now(u: Combatant) -> bool:
	return combat.can_attack(u) and max_attack_pct(u, weapon_of(u)) >= Combat.MIN_ATTACK


func reach(u: Combatant) -> BattleMap.Reach:
	if mode != Mode.MOVE or not combat.can_move(u, gait):
		return null
	var key := "%s|%s|%d|%d|%.2f|%s" % [u.id, u.pos, u.act, u.free_hex, u.move_spare, gait]
	if key != _reach_key:
		_reach_key = key
		_reach = combat.move_range(u, gait)
	return _reach


## Zustand für die Kartenmarkierungen
func view_state(u: Combatant, hover: Variant, hover_unit: Combatant) -> Dictionary:
	var st := {"hover": hover}
	var r := reach(u)
	if r:
		var tiles: Array = []
		for p in r.dest:
			if p != u.pos:
				tiles.append(p)
		st.reach_tiles = tiles
		if hover != null and hover_unit == null and r.has(hover) and hover != u.pos:
			var path := r.path_to(hover)
			st.path = path
			if path.size() > 1:
				st.preview = preview_for(u, hover, path)
	if show_range:
		st.range = range_for(u, weapon_of(u))
	if mode == Mode.AID:
		st.helpers = combat.first_aid_targets(u)
	elif mode == Mode.PSI:
		st.helpers = combat.power_targets(u, power)
	elif can_attack_now(u):
		var w := weapon_of(u)
		var p := attack_pct(u, w)
		st.targets = combat.opponents(u).filter(func(t: Combatant) -> bool: return combat.attack_info(u, t, w, {"pct": p}).valid)
	return st


## Vorschau für ein Zielfeld: wen kann ich von dort treffen, wer kann mich dort treffen?
func preview_for(u: Combatant, tile_pos: Vector2i, path: Array) -> Dictionary:
	var key := "%s|%s|%d|%d|%.2f|%s|%s|%d" % [u.id, tile_pos, u.act, u.free_hex, u.move_spare, gait, weapon_of(u).id, combat.round_no]
	if key == _preview_key:
		return _preview
	var tile := combat.map.tile(tile_pos)
	var left := u.act - combat.move_pct(u, gait, _reach.cost(tile_pos))
	var facing := Hex.dir_toward(path[-2], path[-1])
	var hit := {}
	var threat := {}
	if not u.has_attacked and not u.stunned_now and gait != &"sprinten":
		var run_mod: int = Combat.GAITS[&"laufen"].attack_mod if gait == &"laufen" and not u.ran else 0
		for w in combat.usable_weapons(u):
			var p := mini(100, (left - (Combat.COST.swap if w != u.weapon else 0)) / 10 * 10)
			if p < Combat.MIN_ATTACK:
				continue
			for t in combat.opponents(u):
				var info := combat.attack_info(u, t, w, {"from": tile, "pct": p})
				if info.valid:
					hit[t] = maxi(hit.get(t, 0), clampi(info.chance + run_mod, 0, 100))
	for e in combat.opponents(u):
		for w in combat.usable_weapons(e):
			var info := combat.attack_info(e, u, w, {"to": tile, "def_facing": facing, "pct": Combat.NORMAL_ATTACK, "preview": true})
			if info.valid:
				threat[e] = maxi(threat.get(e, 0), info.chance)
	_preview_key = key
	_preview = {"hit": hit, "threat": threat, "left": left}
	return _preview


## Reichweitenstufen der gewählten Waffe auf alle sichtbaren Felder
func range_for(u: Combatant, w: WeaponData) -> Dictionary:
	var key := "%s|%s|%s" % [u.id, u.pos, w.id]
	if key == _range_key:
		return _range
	_range_key = key
	_range = {}
	if w.melee:
		return _range
	var from := combat.tile_of(u)
	for t in combat.map.list:
		if not combat.map.walkable(t) or t == from:
			continue
		var m := Hex.distance(from.pos, t.pos) * BattleMap.HEX_M
		var stage := maxi(1, ceili(m / w.inc_m))
		if stage > w.stages or (w.min_range_m and m < w.min_range_m):
			continue
		if combat.map.line_of_sight(from, t):
			_range[t.pos] = stage
	return _range


## Klick oder zweites Antippen: Aktion ausführen
func click(u: Combatant, tile_pos: Variant, target: Combatant) -> void:
	var w := weapon_of(u)
	# im Bewegungsmodus fangen eigene Figuren keinen Klick ab, nicht angreifbare Gegner auch nicht
	if target and mode == Mode.MOVE:
		if target.team == u.team or not can_attack_now(u) or not combat.attack_info(u, target, w, {"pct": attack_pct(u, w)}).valid:
			target = null
	match mode:
		Mode.FACE:
			if tile_pos != null and tile_pos != u.pos:
				combat.do_face(u, Hex.dir_toward(u.pos, tile_pos))
			mode = Mode.MOVE
		Mode.AID:
			if target and combat.do_first_aid(u, target):
				mode = Mode.MOVE
		Mode.PSI:
			if target and combat.do_power(u, power, target):
				mode = Mode.MOVE
		_:
			if target:
				combat.do_attack(u, target, w, attack_pct(u, w))
			elif tile_pos != null:
				combat.do_move(u, tile_pos, gait)


func face_toward(u: Combatant, tile_pos: Vector2i) -> void:
	if tile_pos != u.pos:
		combat.do_face(u, Hex.dir_toward(u.pos, tile_pos))


func toggle_mode(m: Mode) -> void:
	mode = Mode.MOVE if mode == m else m


## unterstützende Kraft gewählt: ohne Zielwahl (selbst, Fläche) sofort wirken, sonst Ziel anklicken lassen
func choose_power(u: Combatant, k: String) -> void:
	if mode == Mode.PSI and power == k:
		mode = Mode.MOVE
		return
	var t: String = PsiCombat.SUPPORT[k].target
	if t in ["self", "area", "foes"]:
		combat.do_power(u, k, u)
		mode = Mode.MOVE
		return
	power = k
	mode = Mode.PSI


## Kontextmenü (Rechtsklick auf eine Figur): Psi-Kräfte, die auf diese Figur passen.
## Einträge {k, text, enabled}; leer = keine Kraft passt (dann dreht der Rechtsklick wie bisher)
func context_powers(u: Combatant, target: Combatant) -> Array:
	var out: Array = []
	if target == null:
		return out
	for w in u.weapons:
		if w.power == "" or target.team == u.team:
			continue
		var p := attack_pct(u, w)
		var info := combat.attack_info(u, target, w, {"pct": p})
		var ok: bool = info.valid and can_attack_now(u) and combat.attack_cost(u, w, p) <= u.act
		out.append({"k": w.power, "attack": w, "enabled": ok,
			"text": "%s · %d PP · %s" % [w.name, w.pp_cost, ("%d %% Treffer" % info.chance) if info.valid else info.reason]})
	for k in u.powers:
		var spec: Dictionary = PsiCombat.SUPPORT[k]
		var self_kind: bool = spec.target in ["self", "area", "foes"]
		if self_kind and target != u:
			continue
		if not self_kind and not _could_target(u, k, target):
			continue
		var ok := combat.can_power(u, k) and combat.power_targets(u, k).has(target)
		out.append({"k": k, "enabled": ok, "text": "%s · %d PP · %s" % [spec.name, PsiCombat.level_of(k), spec.hint]})
	return out


## passt die Zielart der Kraft grundsätzlich zur Figur (Freund/Feind), auch wenn sie gerade nicht erreichbar ist?
func _could_target(u: Combatant, k: String, target: Combatant) -> bool:
	var t: String = PsiCombat.SUPPORT[k].target
	return (t == "enemy") == (target.team != u.team)


# ---------------------------------------------------------------- Tooltip (BBCode)

func tooltip(u: Combatant, player_turn: bool, tile_pos: Variant, o: Combatant) -> String:
	if tile_pos == null:
		return ""
	var t := combat.map.tile(tile_pos)
	if t == null:
		return ""
	var h := ""
	if o:
		var st := "" if o.is_ok() else " – " + o.state_name()
		h += "[b]%s[/b] [color=#8291ad]%s%s[/color]\nTP %d/%d%s · %s" % [o.name, o.role, st, o.hp, o.max_hp,
			(" · PP %d/%d" % [o.pp, o.max_pp]) if o.max_pp else "", o.armor.name]
		if o != u and o.is_ok():
			h += "\n[color=#8291ad]Ausweichreserve %d %%[/color]" % o.reserve
		var s := o.status_list()
		if s:
			h += "\n[color=#8291ad]%s[/color]" % " · ".join(s)
		if player_turn and u and o.team != u.team:
			var w := weapon_of(u)
			var info := combat.attack_info(u, o, w, {"pct": attack_pct(u, w)})
			if not info.valid:
				h += "\n[color=#ff8a8a]Kein Angriff: %s[/color]" % info.reason
			elif not combat.can_attack(u):
				h += "\n[color=#ff8a8a]Kein Angriff mehr in dieser Runde%s[/color]" % (" (gesprintet)" if u.sprinted else "")
			elif max_attack_pct(u, w) < Combat.MIN_ATTACK:
				h += "\n[color=#ff8a8a]Zu wenig Aktivität für einen Angriff (mind. %d %%)[/color]" % Combat.MIN_ATTACK
			else:
				h += "\n" + attack_breakdown(info)
		h += "\n"
	var info_t := t.info()
	var line := "%s · Höhe %d (%s m) · %s" % [combat.map.terrain_name(t), t.h, Combat._m(t.h * BattleMap.LEVEL_M),
		("Kosten %d" % info_t.cost) if info_t.walk else "nicht begehbar"]
	if u and not o and player_turn:
		line += " · %s m entfernt" % Combat._m(Hex.distance(u.pos, tile_pos) * BattleMap.HEX_M)
		var r := reach(u)
		if r and r.has(tile_pos) and tile_pos != u.pos:
			var cost := r.cost(tile_pos)
			var p := combat.move_pct(u, gait, cost)
			line += "\n[b]%s:[/b] %d Hex-Kosten = [b]%d %%[/b] Aktivität (bleiben %d %%)" % [Combat.GAITS[gait].name, int(cost), p, u.act - p]
			var path := r.path_to(tile_pos)
			if path.size() > 1:
				var pv := preview_for(u, tile_pos, path)
				line += "\n[color=#7be38b]Von hier treffbar: %s[/color]" % _list(pv.hit, "niemand")
				line += "\n[color=#ff8a7a]Gefahr dort: %s[/color]" % _list(pv.threat, "niemand sieht das Feld")
	return h + "[color=#aab4c8]" + line + "[/color]"


func _list(m: Dictionary, empty: String) -> String:
	if m.is_empty():
		return "[i]%s[/i]" % empty
	var keys := m.keys()
	keys.sort_custom(func(a, b) -> bool: return m[a] > m[b])
	return ", ".join(keys.map(func(o: Combatant) -> String: return "%s %d %%" % [o.name, m[o]]))


static func attack_breakdown(info: Dictionary) -> String:
	var chance: int = info.chance
	var col := "#7be38b" if chance >= 60 else ("#ffd34d" if chance >= 35 else "#ff8a7a")
	var w: WeaponData = info.weapon
	var s := "[color=%s][b]Trefferchance ≈ %d %%[/b][/color] [color=#8291ad](%d %% Aktivität)[/color]" % [col, chance, info.pct]
	if info.surprised and not w.psi:
		s += "\n[color=#ffd34d]Überraschung (%s): Ziel weicht nicht aus, kein Schild. Eine gelungene Kampfsinn-Probe des Ziels halbiert das Ausweichen.[/color]" % ("Flanke" if info.sector == &"flanke" else "Rücken")
	s += "\n[color=#8291ad]W100 offen %s ≥ %d (%s) · Patzer 01–%02d[/color]" % [Dice.fmt(info.net), info.thr, w.table.name, w.fumble]
	s += "\n[b]Angriff %s[/b]" % _num(Combat._sum(info.ob))
	for m in info.ob:
		s += "\n  %s %s" % [m.label, Dice.fmt(m.val)]
	s += "\n[b]Verteidigung %s[/b]" % _num(Combat._sum(info.db))
	for m in info.db:
		s += "\n  %s %s" % [m.label, Dice.fmt(m.val)]
	return s


static func _num(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)
