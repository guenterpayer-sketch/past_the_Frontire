class_name UnitCard
extends PanelContainer
## Karte einer Figur (kompakt, oben in der Seitenleiste): Name, Rolle, TP/PP/Aktivität, AW/VW/INI, Blickrichtung, Zustände.
## Für die eigene Figur am Zug bzw. in Runde 0 die gewählte, sonst für die Figur, die die KI gerade steuert.

signal action(name: StringName, arg: Variant)

var _box: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	mouse_filter = Control.MOUSE_FILTER_STOP
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)


## note: Zusatzzeile (z. B. "Gegner ist am Zug …"), leer = keine
## w: Waffe für den AW-Wert (die im Aktionsblock gewählte), null = geführte Waffe
func refresh(c: Combat, u: Combatant, note := "", w: WeaponData = null) -> void:
	UiTheme.clear(_box)
	if u == null:
		hide()
		return
	show()
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(UiTheme.badge(u.letter, u.color, 30))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nm := UiTheme.label(u.name, 15, UiTheme.CREW if u.is_crew else UiTheme.ENEMY)
	nm.clip_text = true
	col.add_child(nm)
	var sub := UiTheme.label("%s · %s" % [u.role, "Crew" if u.is_crew else "Gegner"], 11, UiTheme.MUTED)
	sub.clip_text = true
	col.add_child(sub)
	head.add_child(col)
	if u.is_crew:
		var b := UiTheme.button("Bogen", "Charakterbogen")
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(action.emit.bind(&"sheet", u))
		head.add_child(b)
	_box.add_child(head)
	_box.add_child(bar("TP %d/%d" % [maxi(u.hp, 0), u.max_hp], u.hp, u.max_hp, UiTheme.GOOD if u.hp > u.max_hp / 3 else UiTheme.BAD))
	if u.max_pp:
		_box.add_child(bar("PP %d/%d" % [u.pp, u.max_pp], u.pp, u.max_pp, Color("b07ae8")))
	if not c.deploying:
		var free := u.free_hex + int(u.move_spare)
		_box.add_child(bar("Aktivität %d %%%s" % [maxi(u.act, 0), (" + %d Hex frei" % free) if free > 0 else ""], maxi(u.act, 0), 100, Color("c9a227")))
	var stats := HBoxContainer.new()
	if w == null:
		w = u.weapon
	stats.add_child(_stat("AW", Rules.skill_total(u, w.skill), "Gesamtbonus der Waffenfertigkeit (%s)" % w.name))
	stats.add_child(_stat("VW", c.dodge_value(u), "Ausweichen ½ + ½ × übrige Aktivität, + Rüstung (ohne Deckung/Schild)"))
	if not c.deploying:
		stats.add_child(_stat("INI", u.init, "Initiative diese Runde"))
	var facing := UiTheme.label("Blick %s" % Hex.DIR_NAMES[u.facing], 12, UiTheme.MUTED)
	facing.tooltip_text = "Blickrichtung (Rechtsklick dreht)"
	facing.mouse_filter = Control.MOUSE_FILTER_PASS
	stats.add_child(facing)
	_box.add_child(stats)
	var status := u.status_list()
	if status:
		var st := UiTheme.label(" · ".join(status), 11, UiTheme.ACCENT)
		st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_box.add_child(st)
	if note != "":
		_box.add_child(UiTheme.label(note, 13, UiTheme.ENEMY if not u.is_crew else UiTheme.CREW))


static func bar(text: String, v: int, max_v: int, color: Color) -> Control:
	var pb := ProgressBar.new()
	pb.max_value = maxi(max_v, 1)
	pb.value = clampi(v, 0, max_v)
	pb.show_percentage = false
	pb.custom_minimum_size.y = 17
	pb.add_theme_stylebox_override("fill", UiTheme.box(Color(color, 0.75), color, 4, 0, 0))
	var l := UiTheme.label(text, 11, Color.WHITE)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.offset_left = 8
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pb.add_child(l)
	return pb


func _stat(name: String, v: int, tip: String) -> Label:
	var l := UiTheme.label("%s %d" % [name, v], 12)
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l
