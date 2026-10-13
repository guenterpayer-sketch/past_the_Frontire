class_name EndDialog
extends Modal
## Kampfende: Erfahrung je benutzter Fertigkeit, Ränge steigern, freier Pool (3 EP), speichern, nächster Kampf.

signal next_battle
signal reset_crew

const FREE_XP := 3

var _combat: Combat
var _free := {}


func show_end(c: Combat) -> void:
	_combat = c
	for u in c.crew():
		if not _free.has(u):
			_free[u] = FREE_XP
	var win := c.result == &"sieg"
	open("Sieg!" if win else "Niederlage")
	var intro := UiTheme.label("Runde %d. Erfahrung gab es nur für Fertigkeiten, die benutzt wurden. Ränge kosten 10 + 2 × aktueller Rang." % c.round_no, 14)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	var note := UiTheme.label("Prototyp: Tote und Bewusstlose stehen im nächsten Kampf wieder voll bereit (Regeln für Heilung, Tod und Ersatz sind noch offen).", 12, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	var grid := GridContainer.new()
	grid.columns = 2 if size.x > 900 else 1
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for u in c.crew():
		grid.add_child(_card(u))
	content.add_child(grid)
	var reset := UiTheme.button("Crew zurücksetzen")
	reset.add_theme_color_override("font_color", UiTheme.BAD)
	reset.pressed.connect(_confirm_reset)
	footer.add_child(reset)
	var next := UiTheme.button("Fortschritt speichern & nächster Kampf")
	next.add_theme_color_override("font_color", UiTheme.ACCENT)
	next.pressed.connect(func() -> void:
		_free.clear()
		hide()
		next_battle.emit())
	footer.add_child(next)


func _card(u: Combatant) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 10))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	card.add_child(v)
	var head := HBoxContainer.new()
	head.add_child(UiTheme.badge(u.letter, u.color, 24))
	head.add_child(UiTheme.label(u.name, 15, UiTheme.CREW))
	head.add_child(UiTheme.label("%s · %s · %d Gegner ausgeschaltet" % [u.role, u.state_name(), u.kills], 12, UiTheme.MUTED))
	v.add_child(head)
	var g := GridContainer.new()
	g.columns = 5
	for h in ["Fertigkeit", "+EP", "EP / Kosten", "Rang", ""]:
		g.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	var gains := u.xp_log.keys()
	gains.sort_custom(func(a, b) -> bool: return u.xp_log[a] > u.xp_log[b])
	for sid in gains:
		var s := Rules.ensure_skill(u, sid)
		var cost := Rules.rank_cost(s.rank)
		g.add_child(UiTheme.label(Rules.skill_name(sid), 13))
		g.add_child(UiTheme.label("+%d" % u.xp_log[sid], 13, UiTheme.GOOD))
		g.add_child(UiTheme.label("%d / %d" % [s.xp, cost], 13))
		g.add_child(UiTheme.label(str(s.rank), 13))
		if s.xp >= cost:
			var b := UiTheme.button("Rang %d" % (s.rank + 1))
			b.add_theme_color_override("font_color", UiTheme.ACCENT)
			b.pressed.connect(func() -> void:
				Rules.rank_up(u, sid)
				show_end(_combat))
			g.add_child(b)
		else:
			g.add_child(Control.new())
	if gains.is_empty():
		v.add_child(UiTheme.label("keine Fertigkeit benutzt", 12, UiTheme.MUTED))
	else:
		v.add_child(g)
	var free := HBoxContainer.new()
	free.add_child(UiTheme.label("Freier Pool: %d EP" % _free[u], 13))
	var ob := OptionButton.new()
	var ids: Array[StringName] = []
	for grp in Rules.SKILL_GROUPS:
		for sk in grp.skills:
			ob.add_item("%s: %s" % [grp.name, sk[1]])
			ids.append(StringName(sk[0]))
	ob.disabled = _free[u] == 0
	ob.fit_to_longest_item = false
	ob.custom_minimum_size.x = 220
	free.add_child(ob)
	var give := UiTheme.button("vergeben")
	give.disabled = _free[u] == 0
	give.pressed.connect(func() -> void:
		var sid := ids[ob.selected]
		Rules.ensure_skill(u, sid).xp += _free[u]
		u.xp_log[sid] = u.xp_log.get(sid, 0) + _free[u]
		_free[u] = 0
		show_end(_combat))
	free.add_child(give)
	v.add_child(free)
	return card


func _confirm_reset() -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = "Alle Fortschritte der Crew verwerfen?"
	d.ok_button_text = "Zurücksetzen"
	d.cancel_button_text = "Abbrechen"
	add_child(d)
	d.confirmed.connect(func() -> void:
		_free.clear()
		hide()
		reset_crew.emit())
	d.popup_centered()
