class_name CrewWidgets
extends RefCounted
## Bausteine für Roster, Crew-Auswahl und Anheuern: Figurenkarte und Kurzwerte einer Figur.

const WEAPON_SKILLS: Array[StringName] = [&"waffenlos", &"einhand", &"zweihand", &"pistolen", &"gewehre",
	&"schnellfeuer", &"raketenwerfer", &"geschuetze", &"psiAngriff"]


## Knopf mit Kürzel, Name und Untertitel (toggle = ankreuzbar)
static func card(ch: Character, sub: String, toggle := false) -> Button:
	var b := Button.new()
	b.toggle_mode = toggle
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(210, 52)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 8
	h.offset_right = -8
	h.add_theme_constant_override("separation", 10)
	b.add_child(h)
	var badge := UiTheme.badge(ch.letter, ch.color, 32)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(badge)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(v)
	var n := UiTheme.label(ch.name, 14)
	n.clip_text = true
	n.custom_minimum_size.x = 140
	v.add_child(n)
	var s := UiTheme.label(sub, 11, UiTheme.MUTED)
	s.clip_text = true
	s.custom_minimum_size.x = 140
	v.add_child(s)
	return b


## höchster Gesamtbonus unter den Waffenfertigkeiten: [Name, Bonus]
static func best_weapon(ch: Character) -> Array:
	var best: StringName = WEAPON_SKILLS[0]
	for id in WEAPON_SKILLS:
		if Rules.skill_total(ch, id) > Rules.skill_total(ch, best):
			best = id
	return [Rules.skill_name(best), Rules.skill_total(ch, best)]


## Eigenschaften als Zeile kleiner Kästchen und darunter Kurzwerte
static func summary(ch: Character) -> Control:
	var v := VBoxContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for a in Rules.ATTRIBUTES:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.PANEL2, 5, 4))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 0)
		var val: int = ch.attrs[a.id]
		var l1 := UiTheme.label(str(val), 15)
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(l1)
		var l2 := UiTheme.label("%s %s" % [a.short, Dice.fmt(Rules.attr_bonus(val))], 10, UiTheme.MUTED)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(l2)
		p.add_child(c)
		row.add_child(p)
	v.add_child(row)
	var bw := best_weapon(ch)
	var lists := PsiLists.learned(ch).map(func(id: StringName) -> String: return "%s %d" % [PsiLists.LISTS[id].name, Rules.skill_rank(ch, id)])
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	for kv in [["Eigenschaften", str(Creation.attr_sum(ch))], ["Beste Waffe", "%s %s" % [bw[0], Dice.fmt(bw[1])]],
			["TP / PP", "%d / %s" % [Rules.max_hp(ch), str(Rules.max_pp(ch)) if Rules.has_psi(ch) else "–"]],
			["Psi-Listen", ", ".join(lists) if not lists.is_empty() else "–"],
			["Ausrüstung", "%s · %s" % [", ".join(ch.weapons.map(func(w: WeaponData) -> String: return w.name)), ch.armor.name if ch.armor else "–"]],
			["Gute Stücke", Equipment.wear_summary(ch, true) if Equipment.wear_summary(ch, true) != "" else "–"],
			["Beschädigt", Equipment.wear_summary(ch) if Equipment.wear_summary(ch) != "" else "–"]]:
		g.add_child(UiTheme.label(kv[0], 13, UiTheme.MUTED))
		var l := UiTheme.label(kv[1], 13)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 220
		g.add_child(l)
	v.add_child(g)
	return v


## Burgermenü (☰) für die Titelzeile eines Dialogs: Enzyklopädie (öffnet sie über host)
static func burger(host: Control) -> MenuButton:
	var b := MenuButton.new()
	b.text = "☰"
	b.tooltip_text = "Menü"
	b.flat = false
	b.add_theme_font_size_override("font_size", 20)
	b.custom_minimum_size = Vector2(44, 36)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pop := b.get_popup()
	pop.add_item("Enzyklopädie", 0)
	Version.add_to(pop)   # Versionszeile (Hub Auftrag 7)
	pop.id_pressed.connect(func(id: int) -> void:
		if id == 0:
			Encyclopedia.show_on(host).move_to_front())
	return b


## Enzyklopädie unter host schließen, falls offen (Esc); true = war offen
static func close_encyclopedia(host: Node) -> bool:
	var e := host.get_node_or_null(Encyclopedia.NAME) as Encyclopedia
	if e and e.visible:
		e.close()
		return true
	return false
