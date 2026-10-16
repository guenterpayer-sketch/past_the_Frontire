class_name ResultBanner
extends PanelContainer
## Kampfende über der Karte: Sieg, Niederlage oder Rückzug mit kurzer Bilanz. Die Szene wechselt erst auf „Weiter“.

signal continued

var _box: VBoxContainer
var _next: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.96), UiTheme.ACCENT, 12, 22, 2))
	custom_minimum_size.x = 460
	mouse_filter = Control.MOUSE_FILTER_STOP
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)
	hide()


## c: beendeter Kampf, result: MissionResult; next_text: Beschriftung des Knopfs (z. B. „Zurück ins Schiff“);
## from_ship: Einsatz aus dem Schiff (beim Rückzug bleibt der Auftrag dann offen)
func show_result(c: Combat, result: Dictionary, next_text: String, from_ship := false) -> void:
	UiTheme.clear(_box)
	var win := c.result == &"sieg"
	var retreated := bool(result.get("retreated", c.retreated))
	var title := "Sieg!" if win else ("Rückzug" if retreated else "Niederlage")
	var t := UiTheme.label(title, 34, UiTheme.GOOD if win else (UiTheme.RETREAT if retreated else UiTheme.BAD))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	if result.get("mission", "") != "":
		var m := UiTheme.label(result.mission, 15, UiTheme.MUTED)
		m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(m)
	var down := c.enemies().filter(func(u: Combatant) -> bool: return not u.is_ok()).size()
	var ko := 0
	var dying := 0
	var dead := 0
	for u in c.crew():
		if u.is_dead():
			dead += 1
		elif u.state == Combatant.State.DYING and not u.stabilized:
			dying += 1
		elif not u.is_ok():
			ko += 1
	var lines := PackedStringArray()
	lines.append("Runden: %d" % c.round_no)
	lines.append("Gegner ausgeschaltet: %d von %d" % [down, c.enemies().size()])
	lines.append("Crew: %d kampffähig%s%s%s" % [c.crew().size() - ko - dying - dead, (", %d kampfunfähig" % ko) if ko else "",
		(", %d schwer verwundet" % dying) if dying else "", (", %d tot" % dead) if dead else ""])
	lines.append("Jede Figur: +%d freie EP%s" % [MissionResult.FREE_XP + int(result.get("reward_xp", 0)),
		(" (davon +%d Belohnung)" % result.reward_xp) if int(result.get("reward_xp", 0)) > 0 else ""])
	if retreated:
		lines.append("Rückzug: kein Lohn, keine Beute%s. Die EP aus dem Kampf bleiben." % ("; der Auftrag bleibt bis zum Ablaufdatum offen" if from_ship else ""))
	var l := UiTheme.label("\n".join(lines), 15)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(l)
	_next = UiTheme.button(next_text + "  ⏎")
	_next.custom_minimum_size = Vector2(240, 48)
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_next.add_theme_font_size_override("font_size", 16)
	_next.add_theme_color_override("font_color", UiTheme.ACCENT)
	_next.pressed.connect(confirm)
	_box.add_child(_next)
	show()
	reset_size()


func confirm() -> void:
	if visible:
		hide()
		continued.emit()
