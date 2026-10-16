class_name SpaceUI
extends Control
## Oberfläche des Raumkampfs (Mockup bestätigt 16.10.2026): Phasenleiste oben, Schiffskasten links oben
## (Schema/Zahlen), Initiative und Log unten links, einklappbare Seitenleiste rechts mit allen Stationen.
## In jeder Phase bedient man die Stationen dieser Phase; vorbelegt ist ein Vorschlag (SpaceAI), „Phase ausführen“
## gibt die Befehle an den Regelkern.

const SIDE_W := 340.0
const ALLOC_PRESETS := ["Zum Gegner", "Gleichmäßig", "Bug", "Heck", "Backbord", "Steuerbord"]
## Gewichte je Schildseite (0 Bug, 1 Bug links, 2 Heck links, 3 Heck, 4 Heck rechts, 5 Bug rechts)
const ALLOC_WEIGHTS := {"Gleichmäßig": [1, 1, 1, 1, 1, 1], "Bug": [4, 2, 1, 1, 1, 2], "Heck": [1, 1, 2, 4, 2, 1],
	"Backbord": [1, 3, 3, 1, 1, 1], "Steuerbord": [1, 1, 1, 1, 3, 3]}

var view: SpaceView
var combat: SpaceCombat
var ship_box: SpaceShipBox
var briefing: SpaceBriefing
var result_modal: Modal
var combat_log: CombatLog
var _phase_labels: Array[Label] = []
var _round: Label
var _init_bar: HBoxContainer
var _side: PanelContainer
var _side_list: VBoxContainer
var _collapse: Button
var _exec: Button
var _auto: Button
var _surrender: Button
var _defaults := {}
var _w := {}                      # Bedienelemente der laufenden Phase
var _targets := {}                # Geschützstation → Schiffs-ID
var _selected_gun := ""
var _confirm_surrender := false


func setup(v: SpaceView) -> void:
	view = v
	combat = v.combat
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top()
	ship_box = SpaceShipBox.new()
	ship_box.combat = combat
	ship_box.position = Vector2(12, 52)
	add_child(ship_box)
	_build_side()
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bottom.offset_left = 12
	bottom.offset_bottom = -12
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bottom)
	_init_bar = HBoxContainer.new()
	_init_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(_init_bar)
	combat_log = CombatLog.new()
	bottom.add_child(combat_log)
	briefing = SpaceBriefing.new()
	add_child(briefing)
	briefing.confirmed.connect(func(p: Dictionary) -> void: view.begin(p))
	result_modal = Modal.new()
	add_child(result_modal)
	result_modal.closable = false
	result_modal.max_size = Vector2(900, 720)
	refresh_ships()


func _build_top() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(12, 10)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	for i in SpaceCombat.PHASE_NAMES.size():
		var l := UiTheme.label("%d %s" % [i + 1, SpaceCombat.PHASE_NAMES[i]], 13, UiTheme.MUTED)
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.88), UiTheme.LINE, 4, 6))
		p.add_child(l)
		bar.add_child(p)
		_phase_labels.append(l)
	_round = UiTheme.label("", 13, UiTheme.MUTED)
	var rp := PanelContainer.new()
	rp.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.88), UiTheme.LINE, 4, 6))
	rp.add_child(_round)
	bar.add_child(rp)


func _build_side() -> void:
	_side = PanelContainer.new()
	_side.clip_contents = true
	_side.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_side.offset_left = -SIDE_W
	_side.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.96), UiTheme.LINE, 0, 10))
	add_child(_side)
	var v := VBoxContainer.new()
	_side.add_child(v)
	var head := HBoxContainer.new()
	v.add_child(head)
	var t := UiTheme.label("STATIONEN · MUTTERSCHIFF", 13, UiTheme.MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_side_list = VBoxContainer.new()
	_side_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side_list.custom_minimum_size.x = SIDE_W - 30
	scroll.add_child(_side_list)
	var foot := HBoxContainer.new()
	v.add_child(foot)
	_exec = UiTheme.button("Phase ausführen ▶", "Befehle dieser Phase ausführen (Leertaste)")
	_exec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exec.pressed.connect(func() -> void: view.execute(collect_orders()))
	foot.add_child(_exec)
	_auto = UiTheme.button("Vorschlag", "Diese Phase mit dem Vorschlag der Bord-KI ausführen")
	_auto.pressed.connect(func() -> void: view.execute(SpaceAI.crew_orders(combat, combat.phase)))
	foot.add_child(_auto)
	_surrender = UiTheme.button("Kapitulieren")
	_surrender.pressed.connect(_on_surrender)
	v.add_child(_surrender)
	_collapse = UiTheme.button("›", "Seitenleiste ein-/ausklappen")
	_collapse.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_collapse.offset_left = -SIDE_W - 34
	_collapse.offset_right = -SIDE_W - 6
	_collapse.offset_top = 10
	_collapse.pressed.connect(_toggle_side)
	add_child(_collapse)
	view.rig.right_inset = SIDE_W


func _toggle_side() -> void:
	_side.visible = not _side.visible
	var w := SIDE_W if _side.visible else 0.0
	_collapse.text = "›" if _side.visible else "‹"
	_collapse.offset_left = -w - 34
	_collapse.offset_right = -w - 6
	view.rig.right_inset = w


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_SPACE and not _exec.disabled \
			and _exec.is_visible_in_tree():
		_exec.pressed.emit()


func open_briefing() -> void:
	briefing.open_for(view)


func log_line(t: String, kind: StringName) -> void:
	combat_log.add(t, kind)


func set_busy(b: bool) -> void:
	_exec.disabled = b
	_auto.disabled = b
	_surrender.disabled = b or not combat.can_surrender()


func refresh_ships() -> void:
	ship_box.refresh()
	UiTheme.clear(_init_bar)
	for s in combat.order:
		if not s.is_active():
			continue
		var p := PanelContainer.new()
		var col := UiTheme.CREW if s.side == &"crew" else UiTheme.ENEMY
		p.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), col, 4, 5))
		p.add_child(UiTheme.label("%s %d" % [s.name, s.initiative], 12, col))
		_init_bar.add_child(p)


# ---------------------------------------------------------------- Phase und Stationen

func refresh() -> void:
	for i in _phase_labels.size():
		var on := i == combat.phase
		_phase_labels[i].add_theme_color_override("font_color", UiTheme.ACCENT if on else UiTheme.MUTED)
	_round.text = "Runde %d" % combat.round_no
	_defaults = SpaceAI.crew_orders(combat, combat.phase)
	_targets = _defaults.get("targets", {}).duplicate() if combat.phase == SpaceCombat.Phase.FIRE else {}
	_w = {}
	_confirm_surrender = false
	_surrender.text = "Kapitulieren (%d Credits)" % int(combat.faction.get("ransom", 0)) if combat.can_surrender() \
		else "Kapitulieren (nicht möglich)"
	_surrender.disabled = not combat.can_surrender()
	refresh_ships()
	_build_cards()


func _active_stations() -> Array:
	match combat.phase:
		SpaceCombat.Phase.SHIELDS:
			return ["schilde"]
		SpaceCombat.Phase.MOVE:
			return ["steuer"]
		SpaceCombat.Phase.FIRE:
			return combat.stations().filter(func(s: String) -> bool: return s.begins_with("geschuetz_"))
		SpaceCombat.Phase.TECH:
			return ["technik", "computer", "navigation"]
	return []


func _build_cards() -> void:
	UiTheme.clear(_side_list)
	var active := _active_stations()
	for st in combat.stations():
		var on: bool = st in active
		var card := PanelContainer.new()
		var border := UiTheme.ACCENT if on else UiTheme.LINE
		if st == _selected_gun and on:
			border = UiTheme.CREW
		card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2 if on else Color(UiTheme.PANEL2, 0.5),
			border, 4, 8))
		card.modulate.a = 1.0 if on else 0.6
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 3)
		card.add_child(v)
		var top := HBoxContainer.new()
		v.add_child(top)
		var name_l := UiTheme.label(SpaceSetup.station_name(st), 14, UiTheme.TEXT)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_l)
		top.add_child(_tag(st, on))
		var skill := _skill_of(st)
		var who := combat.who_name(st)
		v.add_child(UiTheme.label("%s · %s %+d" % [who, Rules.skill_name(skill), combat.station_bonus(st, skill)], 12,
			UiTheme.MUTED))
		if st.begins_with("geschuetz_"):
			var slot := st.trim_prefix("geschuetz_")
			v.add_child(UiTheme.label(ShipWeapons.describe(String(combat.own.slots[slot].key)), 11, UiTheme.MUTED))
		if on and combat.station_usable(st):
			_controls(st, v)
			if st.begins_with("geschuetz_"):
				card.gui_input.connect(func(e: InputEvent) -> void:
					if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
						_selected_gun = "" if _selected_gun == st else st
						_build_cards())
		_fit_card(v)
		_side_list.add_child(card)


## Inhalte einer Karte auf die Breite der Seitenleiste bringen (Text umbrechen, lange Listen kürzen)
func _fit_card(n: Node) -> void:
	for c in n.get_children():
		if c is Label and not c.get_parent() is HBoxContainer:
			(c as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			(c as Label).custom_minimum_size.x = 0
		elif c is OptionButton:
			(c as OptionButton).clip_text = true
			(c as OptionButton).fit_to_longest_item = false
			(c as OptionButton).custom_minimum_size.x = 0
			(c as OptionButton).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		elif c is Button:
			(c as Button).clip_text = true
			(c as Button).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_fit_card(c)


func _tag(st: String, on: bool) -> Label:
	var txt := ""
	var col := UiTheme.MUTED
	var pid := String(combat.posts.get(st, SpaceSetup.KI))
	if not combat.station_usable(st):
		txt = "ausgefallen"
		col = UiTheme.BAD
	elif combat.station_who(st) == null:
		txt = "Bord-KI +%d" % SpaceSetup.KI_BONUS
		col = UiTheme.CREW
	elif combat.posts.values().count(pid) > 1:
		txt = "doppelt −30"
		col = UiTheme.ACCENT
	elif combat.own.dmg_level("station_" + st) > 0 or int(combat.people[pid].malus) != 0:
		txt = "verletzt/beschädigt"
		col = UiTheme.BAD
	elif on:
		txt = "am Zug"
		col = UiTheme.ACCENT
	return UiTheme.label(txt, 11, col)


func _skill_of(st: String) -> StringName:
	if st.begins_with("geschuetz_"):
		return ShipWeapons.skill(String(combat.own.slots[st.trim_prefix("geschuetz_")].key))
	return SpaceSetup.STATION_SKILL[st]


func _controls(st: String, v: VBoxContainer) -> void:
	match combat.phase:
		SpaceCombat.Phase.SHIELDS:
			_shield_controls(v)
		SpaceCombat.Phase.MOVE:
			_move_controls(v)
		SpaceCombat.Phase.FIRE:
			_fire_controls(st, v)
		SpaceCombat.Phase.TECH:
			_tech_controls(st, v)


func _spin(v: VBoxContainer, text: String, value: int, max_v: int) -> SpinBox:
	var row := HBoxContainer.new()
	var l := UiTheme.label(text, 12)
	l.custom_minimum_size.x = 120
	row.add_child(l)
	var sb := SpinBox.new()
	sb.min_value = 0
	sb.max_value = max_v
	sb.value = value
	sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(sb)
	v.add_child(row)
	return sb


func _shield_controls(v: VBoxContainer) -> void:
	var e: Dictionary = _defaults.get("energy", {})
	var total := combat.energy_total
	v.add_child(UiTheme.label("Energie diese Runde: %d (Rest geht in die Waffen)" % total, 12, UiTheme.ACCENT))
	_w.e_shields = _spin(v, "Schilde (×%d)" % SpaceCombat.SHIELD_PER_ENERGY, int(e.get("shields", 0)), total)
	_w.e_engine = _spin(v, "Antrieb", int(e.get("engine", 0)), total)
	_w.e_jump = _spin(v, "Sprung (%d nötig)" % SpaceCombat.JUMP_ENERGY, int(e.get("jump", 0)), total)
	var row := HBoxContainer.new()
	row.add_child(UiTheme.label("Verteilung", 12))
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	for p in ALLOC_PRESETS:
		ob.add_item(p)
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ob)
	v.add_child(row)
	_w.alloc = ob


func _move_controls(v: VBoxContainer) -> void:
	var o := combat.own
	var spd: int = view.plan.count("F")
	v.add_child(UiTheme.label("Tempo jetzt %d → geplant %d (höchstens %d, ±1 je Runde)" % [o.speed, spd,
		combat.max_speed_of(o)], 12, UiTheme.ACCENT))
	v.add_child(UiTheme.label("Plan: %s" % (" ".join(PackedStringArray(view.plan.map(_step_name))) if not view.plan.is_empty()
		else "stehen bleiben"), 12))
	var row := HBoxContainer.new()
	for b in [["⟲ Links", "L"], ["▲ Vor", "F"], ["⟳ Rechts", "R"]]:
		var btn := UiTheme.button(b[0])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var step: String = b[1]
		btn.pressed.connect(func() -> void:
			view.plan.append(step)
			view.update_plan_preview()
			_build_cards())
		row.add_child(btn)
	v.add_child(row)
	var row2 := HBoxContainer.new()
	var back := UiTheme.button("↶ Zurück")
	back.pressed.connect(func() -> void:
		if not view.plan.is_empty():
			view.plan.pop_back()
		view.update_plan_preview()
		_build_cards())
	row2.add_child(back)
	var sug := UiTheme.button("Vorschlag")
	sug.pressed.connect(func() -> void:
		view.plan = _defaults.get("steps", []).duplicate()
		view.update_plan_preview()
		_build_cards())
	row2.add_child(sug)
	v.add_child(row2)
	v.add_child(UiTheme.label("Die Pilotenprobe entscheidet über Drehungen (Grundwert %d) und Tempoänderung. "
		% o.turns + "Antrieb: %d Felder frei, jedes weitere kostet 1 Energie." % SpaceCombat.ENGINE_FREE, 11,
		UiTheme.MUTED))
	for l in v.get_children():
		if l is Label:
			(l as Label).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _step_name(s: Variant) -> String:
	return {"F": "vor", "L": "links", "R": "rechts"}.get(String(s), String(s))


func _fire_controls(st: String, v: VBoxContainer) -> void:
	var slot := st.trim_prefix("geschuetz_")
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.add_item("— nicht feuern")
	ob.set_item_metadata(0, "")
	var sel := 0
	for e in combat.active_enemies():
		var why := combat.fire_problem(combat.own, slot, e)
		var d := Hex.distance(combat.own.pos, e.pos)
		ob.add_item("%s · %d Felder%s" % [e.name, d, "" if why == "" else " (%s)" % why])
		ob.set_item_metadata(ob.item_count - 1, e.id)
		ob.set_item_disabled(ob.item_count - 1, why != "")
		if String(_targets.get(st, "")) == e.id and why == "":
			sel = ob.item_count - 1
	ob.select(sel)
	ob.item_selected.connect(func(i: int) -> void: _targets[st] = ob.get_item_metadata(i))
	v.add_child(ob)
	if sel > 0:
		var t := combat.ship_by_id(String(_targets[st]))
		var info := combat.attack_info(combat.own, slot, t)
		v.add_child(UiTheme.label("Angriff %+d gegen Schwelle %d" % [SpaceCombat._sum(info.mods), info.threshold], 11,
			UiTheme.MUTED))


func _tech_controls(st: String, v: VBoxContainer) -> void:
	match st:
		"technik":
			var ob := OptionButton.new()
			ob.focus_mode = Control.FOCUS_NONE
			ob.add_item("nichts tun")
			ob.set_item_metadata(0, {})
			ob.add_item("Hülle flicken (Panzerung)")
			ob.set_item_metadata(1, {"patch": true})
			for sys in combat.own.damage:
				ob.add_item("Reparieren: %s (%s)" % [combat.system_name(String(sys)), combat.own.damage[sys]])
				ob.set_item_metadata(ob.item_count - 1, {"repair": String(sys)})
			var d: Dictionary = _defaults.get("technik", {})
			for i in ob.item_count:
				if ob.get_item_metadata(i) == d:
					ob.select(i)
			v.add_child(ob)
			_w.technik = ob
		"computer":
			var mode := OptionButton.new()
			mode.focus_mode = Control.FOCUS_NONE
			mode.add_item("Zielerfassung (+%d)" % SpaceCombat.LOCK_BONUS)
			mode.add_item("Störsender (%d)" % SpaceCombat.JAM_MALUS)
			v.add_child(mode)
			var tgt := OptionButton.new()
			tgt.focus_mode = Control.FOCUS_NONE
			tgt.add_item("— nichts")
			tgt.set_item_metadata(0, "")
			for e in combat.active_enemies():
				tgt.add_item(e.name)
				tgt.set_item_metadata(tgt.item_count - 1, e.id)
				if e.id == String(_defaults.get("computer", {}).get("target", "")):
					tgt.select(tgt.item_count - 1)
			v.add_child(tgt)
			_w.comp_mode = mode
			_w.comp_target = tgt
		"navigation":
			var cb := CheckBox.new()
			cb.text = "Sprung vorbereiten (%d/%d)" % [combat.jump_progress, SpaceCombat.JUMP_ROUNDS]
			cb.disabled = not combat.can_jump()
			cb.button_pressed = bool(_defaults.get("jump", false))
			v.add_child(cb)
			var hint := UiTheme.label("Braucht %d Energie „Sprung“ (Schildphase) und %d Treibstoff." % [
				SpaceCombat.JUMP_ENERGY, SpaceCombat.JUMP_FUEL], 11, UiTheme.MUTED)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(hint)
			_w.jump = cb


## Befehle der laufenden Phase aus den Bedienelementen
func collect_orders() -> Dictionary:
	match combat.phase:
		SpaceCombat.Phase.SHIELDS:
			if not _w.has("e_shields"):
				return _defaults
			var sh := int(_w.e_shields.value)
			var eng := int(_w.e_engine.value)
			var jump := int(_w.e_jump.value)
			var preset: String = ALLOC_PRESETS[_w.alloc.selected]
			var alloc: Array = _defaults.get("alloc", [])
			if preset != "Zum Gegner":
				var weights: Array = ALLOC_WEIGHTS[preset]
				var pool := mini(combat.own.shield_total() + sh * SpaceCombat.SHIELD_PER_ENERGY, combat.own.shield_max * 6)
				alloc = []
				for i in 6:
					alloc.append(mini(combat.own.shield_max, pool * int(weights[i]) / 10 if preset != "Gleichmäßig"
						else pool / 6))
			return {"energy": {"jump": jump, "shields": sh, "engine": eng, "weapons": combat.energy_total}, "alloc": alloc}
		SpaceCombat.Phase.MOVE:
			return {"speed": view.plan.count("F"), "steps": view.plan.duplicate()}
		SpaceCombat.Phase.FIRE:
			return {"targets": _targets.duplicate()}
		SpaceCombat.Phase.TECH:
			var o := {}
			if _w.has("technik"):
				o["technik"] = _w.technik.get_item_metadata(_w.technik.selected)
			if _w.has("comp_target"):
				o["computer"] = {"mode": "lock" if _w.comp_mode.selected == 0 else "jam",
					"target": _w.comp_target.get_item_metadata(_w.comp_target.selected)}
			if _w.has("jump"):
				o["jump"] = _w.jump.button_pressed
			return o
	return {}


## Klick auf ein Schiff: in der Schussphase Ziel setzen, sonst Zustand ins Log
func ship_clicked(s: SpaceShip) -> void:
	if combat.phase == SpaceCombat.Phase.FIRE and s.side == &"enemy":
		var set_any := false
		for st in _active_stations():
			if _selected_gun != "" and st != _selected_gun:
				continue
			if combat.fire_problem(combat.own, st.trim_prefix("geschuetz_"), s) == "":
				_targets[st] = s.id
				set_any = true
		if set_any:
			Sfx.play(&"klick")
			_build_cards()
			return
	var dmg := PackedStringArray()
	for sys in s.damage:
		dmg.append("%s %s" % [combat.system_name(String(sys)), s.damage[sys]])
	log_line("%s (%s): Hülle %d/%d, Schilde %s, Tempo %d%s" % [s.name, SpaceShip.CLASSES[s.cls], s.hull, s.hull_max,
		combat._shield_text(s), s.speed, "" if dmg.is_empty() else ", Schäden: " + ", ".join(dmg)], &"")


func _on_surrender() -> void:
	if not _confirm_surrender:
		_confirm_surrender = true
		_surrender.text = "Wirklich kapitulieren? Nochmals klicken"
		return
	view.surrender()


# ---------------------------------------------------------------- Ergebnis

func show_result(r: Dictionary) -> void:
	var title := "Sieg" if r.outcome == &"sieg" else ("Gesprungen" if r.retreated else "Niederlage")
	if r.surrendered:
		title = "Kapitulation"
	result_modal.open(title)
	var t := ""
	if r.boarding:
		t += "[color=#ffd34d]Die Gegner entern die Frontire – es folgt ein Bodenkampf.[/color]\n"
	elif r.emergency:
		t += "[color=#ff6b6b]Die Frontire ist manövrierunfähig (Notfall).[/color]\n"
	if r.surrendered:
		t += "Lösegeld: %d Credits\n" % int(r.ransom.get("credits", 0))
	t += "[b]Schiff:[/b] Hülle %d/%d nach %d Runden\n" % [int(r.ship.hull), combat.own.hull_max, int(r.rounds)]
	var dmg := PackedStringArray()
	for sys in r.ship.damage:
		dmg.append("%s (%s)" % [combat.system_name(String(sys)), r.ship.damage[sys]])
	t += "Systemschäden (bleiben bis zur Reparatur): %s\n" % (", ".join(dmg) if not dmg.is_empty() else "keine")
	var used := PackedStringArray()
	for k in r.ship_ammo_used:
		used.append("%d %s" % [int(r.ship_ammo_used[k]), ShipWeapons.AMMO_TYPES.get(k, k)])
	t += "Verbrauch: %s%s\n" % [", ".join(used) if not used.is_empty() else "keine Munition",
		", %d Treibstoff" % int(r.fuel_used) if int(r.fuel_used) > 0 else ""]
	t += "\n[b]Crew[/b]\n"
	for c in combat.crew:
		var u: Dictionary = r.units[c.id]
		var xp := PackedStringArray()
		for k in u.xp:
			xp.append("%s +%d" % [Rules.skill_name(StringName(k)), int(u.xp[k])])
		var hurt := ""
		if String(u.worst_crit) != "":
			hurt = " · [color=#ff6b6b]verletzt (%s)[/color]" % u.worst_crit
		t += "%s: %s%s\n" % [c.name, ", ".join(xp) if not xp.is_empty() else "keine EP", hurt]
	if not r.ship_loot.is_empty():
		var l: Dictionary = r.ship_loot
		t += "\n[b]Beute[/b]\n%d Credits, %d Schiffsmaterial" % [int(l.credits), int(l.material)]
		for k in l.ship_ammo:
			t += ", %d %s" % [int(l.ship_ammo[k]), ShipWeapons.AMMO_TYPES.get(k, k)]
		for w in l.weapons:
			t += "\n%s (%d)" % [w.name, int(w.damage)]
	if SpaceBattle.is_quick():
		t += "\n\n[color=#8291ad]Schnellkampf – nichts wird verbucht.[/color]"
	result_modal.content.add_child(Modal.rich(t))
	var b := UiTheme.button("Weiter")
	b.pressed.connect(func() -> void: view.leave(r))
	result_modal.footer.add_child(b)
