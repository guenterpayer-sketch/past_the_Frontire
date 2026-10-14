class_name BriefingDialog
extends Modal
## Einsatzbesprechung vor Runde 0, zwei Spalten: links Auftrag, Gegnergruppe, Schwierigkeit, Halle, Belohnung;
## rechts die Truppwahl als Kacheln (bis Campaign.MAX_SQUAD; Gesperrte ausgegraut, Angeschlagene markiert,
## Warnung bei weniger als MAX_SQUAD). "Neu würfeln" erzeugt eine andere Mission (wahlweise mit fester Schwierigkeit).

signal reroll(difficulty: String)
## beim Schließen: gewählter Trupp in Listenreihenfolge (leer = nichts gewählt, bisheriger Trupp bleibt)
signal accepted(squad: Array[Character])

const DIFF_CHOICES := [["", "zufällig"], ["leicht", "leicht"], ["mittel", "mittel"], ["schwer", "schwer"]]
const SEL_BG := Color("3a3215")
const HURT := Color("ff8a3d")
const SUB := Color("a9b4c9")

var _diff := 0
## aus dem Schiff gestartet: kein Neu-Würfeln, stattdessen zurück ins Schiff
var hub_mode := false
## Schnellkampf aus dem Startmenü: Figuren aus dem globalen Roster
var quick := false
var _cands: Array[Dictionary] = []
var _sel: Array[Character] = []
var _tiles := {}          # Character -> Button
var _count: Label
var _warn: PanelContainer
var _warn_text: Label
var _go: Button


func _init() -> void:
	max_size = Vector2(1520, 860)


## cands = Kandidaten (Campaign.candidates: {ch, locked, reason, marked, note}), selected = vorbelegter Trupp
func show_mission(m: Mission, cands: Array[Dictionary], selected: Array[Character]) -> void:
	open("Einsatz: %s" % m.title)
	_cands = cands
	_sel = selected.duplicate()
	_tiles.clear()
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 22)
	content.add_child(cols)
	cols.add_child(_mission_column(m))
	cols.add_child(VSeparator.new())
	cols.add_child(_squad_column())
	_refresh()

	var hint := UiTheme.label("Vorbelegt: die 6 Startfiguren · Figuren aus dem Roster, es wird nichts verbucht" if quick
		else "Vorbelegt: Trupp des letzten Einsatzes, Gesperrte entfernt, freie Plätze aufgefüllt", 12, UiTheme.MUTED)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(hint)
	if hub_mode:
		var back := UiTheme.button("Zurück ins Schiff", "Auftrag nicht jetzt erledigen; er bleibt auf der Sternenkarte offen")
		back.pressed.connect(func() -> void:
			hide()
			reroll.emit(""))
		footer.add_child(back)
	var ob := OptionButton.new()
	for c in DIFF_CHOICES:
		ob.add_item("Schwierigkeit: %s" % c[1])
	ob.select(_diff)
	ob.visible = not hub_mode
	ob.item_selected.connect(func(i: int) -> void: _diff = i)
	footer.add_child(ob)
	var again := UiTheme.button("Andere Mission")
	again.pressed.connect(func() -> void:
		hide()
		reroll.emit(DIFF_CHOICES[_diff][0]))
	again.visible = not hub_mode
	footer.add_child(again)
	_go = UiTheme.button("Zur Aufstellung")
	_go.add_theme_color_override("font_color", UiTheme.ACCENT)
	_go.pressed.connect(close)
	footer.add_child(_go)
	_refresh()


func close() -> void:
	super.close()
	accepted.emit(_sel.duplicate())


## gewählter Trupp (für Tests)
func selection() -> Array[Character]:
	return _sel.duplicate()


## Kachel an- oder abwählen (Gesperrte und ein volles Team ignorieren den Klick)
func toggle(ch: Character) -> void:
	var c := _cand(ch)
	if c.is_empty() or c.locked:
		return
	if ch in _sel:
		_sel.erase(ch)
	elif _sel.size() < Campaign.MAX_SQUAD:
		_sel.append(ch)
	var sorted: Array[Character] = []
	for o in _cands:
		if o.ch in _sel:
			sorted.append(o.ch)
	_sel = sorted
	_refresh()


func _cand(ch: Character) -> Dictionary:
	for c in _cands:
		if c.ch == ch:
			return c
	return {}


func _mission_column(m: Mission) -> VBoxContainer:
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 470
	left.add_theme_constant_override("separation", 10)
	var t := UiTheme.label(m.text, 15)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(t)
	var f := UiTheme.label("%s – %s" % [m.faction.name, m.faction.description], 13, UiTheme.MUTED)
	f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(f)
	var sz: Dictionary = {}
	for s in BattleMap.SIZES:
		if s.id == m.size_id:
			sz = s
	var s := "[b]Ziel:[/b] alle Gegner ausschalten\n"
	s += "[b]Schwierigkeit:[/b] %s · [b]Halle:[/b] %s\n[b]Belohnung bei Sieg:[/b] +%d freie EP je Figur (zusätzlich zu den %d freien EP pro Einsatz)\n\n" % [
		m.difficulty_name(), sz.get("name", m.size_id), m.reward_xp, MissionResult.FREE_XP]
	s += "[color=#8291ad]GEGNER (%d)[/color]\n[table=4]" % m.enemies.size()
	for h in ["", "Typ", "Rolle", "Ausrüstung"]:
		s += "[cell][color=#8291ad]%s[/color][/cell]" % h
	for d in m.enemies:
		var gear := ", ".join(d.weapons.map(func(w: WeaponData) -> String: return w.name))
		if d.armor:
			gear += " · " + d.armor.name
		s += "[cell][b]%s[/b][/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [d.letter, d.name, d.role, gear]
	s += "[/table]"
	left.add_child(Modal.rich(s))
	return left


func _squad_column() -> VBoxContainer:
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	var head := HBoxContainer.new()
	var title := UiTheme.label("EINSATZTRUPP · bis %d aus %s · Kachel anklicken: dazu / heraus" % [
		Campaign.MAX_SQUAD, "dem Roster" if quick else "Crew und Reserve"], 12, UiTheme.MUTED)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_count = UiTheme.label("", 20, UiTheme.ACCENT)
	head.add_child(_count)
	right.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	# Gesperrte ans Ende
	for locked in [false, true]:
		for c in _cands:
			if c.locked == locked:
				var b := _tile(c)
				grid.add_child(b)
				_tiles[c.ch] = b
	right.add_child(grid)
	_warn = PanelContainer.new()
	_warn.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BG, HURT, 8, 10))
	_warn_text = UiTheme.label("", 14, Color("ffcf9e"))
	_warn_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_warn.add_child(_warn_text)
	right.add_child(_warn)
	return right


## Kachel einer Figur: Name, Rolle, TP/PP, Waffen, Rüstung, Zustand
func _tile(c: Dictionary) -> Button:
	var ch: Character = c.ch
	var one: Array[Character] = [ch]
	var u: Combatant = Roster.build_crew(one)[0]
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 150)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = c.locked
	b.pressed.connect(toggle.bind(ch))
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12
	v.offset_right = -12
	v.offset_top = 10
	v.offset_bottom = -10
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UiTheme.badge(ch.letter, ch.color, 28))
	var nm := UiTheme.label(ch.name, 16)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(nm)
	var mark := UiTheme.label("", 18, UiTheme.ACCENT)
	mark.name = "Mark"
	row.add_child(mark)
	v.add_child(row)
	v.add_child(_line("%s · TP %d · PP %s" % [ch.role, u.max_hp, str(u.max_pp) if u.max_pp > 0 else "–"], 12, UiTheme.MUTED))
	var weapons := ", ".join(u.weapons.filter(func(w: WeaponData) -> bool: return w.power == "").map(func(w: WeaponData) -> String: return w.name))
	var psi: Array[String] = []
	for list in PsiLists.LISTS:
		var r := Rules.skill_rank(ch, list)
		if r > 0:
			psi.append("%s %d" % [PsiLists.LISTS[list].name, r])
	if not psi.is_empty():
		weapons += " · Psi: " + ", ".join(psi)
	v.add_child(_line(weapons, 13, UiTheme.TEXT))
	var armor := u.armor.name if u.armor else "keine Rüstung"
	if u.shield:
		armor += " · Schild"
	v.add_child(_line(armor, 12, SUB))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	var state := "einsatzbereit"
	var col := UiTheme.MUTED
	if c.locked:
		state = "gesperrt: " + c.reason
		col = UiTheme.BAD
	elif c.marked:
		state = "%s · %d im Einsatz" % [c.note, Injury.LIGHT_MALUS]
		col = HURT
	v.add_child(_line(state, 12, col))
	b.tooltip_text = "%s (%s)\n%s\n%s\n%s" % [ch.name, ch.role, weapons, armor, state]
	return b


func _line(text: String, size: int, color: Color) -> Label:
	var l := UiTheme.label(text, size, color)
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Kacheln, Zähler, Warnung und Startknopf an die Auswahl anpassen
func _refresh() -> void:
	for ch in _tiles:
		var b: Button = _tiles[ch]
		var on: bool = ch in _sel
		var full := not on and _sel.size() >= Campaign.MAX_SQUAD
		var sb: StyleBoxFlat
		if b.disabled:
			sb = UiTheme.box(Color(UiTheme.PANEL2, 0.45), Color(UiTheme.LINE, 0.9), 10, 0, 2)
			b.modulate = Color(1, 1, 1, 0.55)
		elif on:
			sb = UiTheme.box(SEL_BG, UiTheme.ACCENT, 10, 0, 2)
			b.modulate = Color.WHITE
		else:
			sb = UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 10, 0, 2)
			b.modulate = Color(1, 1, 1, 0.75) if full else Color.WHITE
		var hover := sb.duplicate() as StyleBoxFlat
		if not b.disabled and not on:
			hover.border_color = UiTheme.ACCENT.darkened(0.3)
		for s in ["normal", "pressed", "disabled", "focus"]:
			b.add_theme_stylebox_override(s, sb)
		b.add_theme_stylebox_override("hover", hover)
		(b.find_child("Mark", true, false) as Label).text = "✓" if on else ""
	if _count == null:
		return
	var n := _sel.size()
	_count.text = "%d / %d" % [n, Campaign.MAX_SQUAD]
	_count.add_theme_color_override("font_color", UiTheme.ACCENT if n == Campaign.MAX_SQUAD else HURT)
	_warn.visible = n < Campaign.MAX_SQUAD
	if n == 0:
		_warn_text.text = "Niemand gewählt. Mindestens eine Figur muss in den Einsatz."
	else:
		_warn_text.text = "Nur %d von %d Plätzen besetzt. Der Einsatz ist möglich, aber mit weniger Figuren schwerer." % [n, Campaign.MAX_SQUAD]
	if _go:
		_go.disabled = n == 0
		_go.text = "Zur Aufstellung" if n == Campaign.MAX_SQUAD else "Mit %d zur Aufstellung" % n
