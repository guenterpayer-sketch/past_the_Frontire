class_name EndDialog
extends Modal
## Nach dem Kampf: Charakterübersicht zum Durchblättern (◀ ▶, Pfeiltasten). Je Figur:
## Ränge steigern (Fertigkeits-EP, fehlende EP aus dem freien Pool), Eigenschaften mit freien EP steigern.
## Freie EP: FREE_XP pro Einsatz + Missionsbelohnung bei Sieg; was nicht ausgegeben wird, bleibt gespart.

signal next_battle
signal reset_crew

const FREE_XP := 3

var _combat: Combat
var _mission: Mission
var _crew: Array[Combatant] = []
var _idx := 0
var _snap := {}          # Combatant -> Stand beim Öffnen (für "zurücknehmen")
var _gain := {}          # Combatant -> freie EP aus diesem Einsatz
var _show_all := false
var _page: VBoxContainer


func show_end(c: Combat, mission: Mission = null) -> void:
	if c != _combat:
		_combat = c
		_mission = mission
		_crew = c.crew()
		_idx = 0
		_snap.clear()
		_gain.clear()
		var win := c.result == &"sieg"
		for u in _crew:
			var g := FREE_XP + (mission.reward_xp if mission and win else 0)
			u.free_xp += g
			_gain[u] = g
			_snap[u] = {"skills": u.skills.duplicate(true), "attrs": u.attrs.duplicate(), "free_xp": u.free_xp}
	var win := c.result == &"sieg"
	open("%s%s" % ["Sieg!" if win else "Niederlage", (" – " + _mission.title) if _mission else ""])
	var reward := ""
	if _mission:
		reward = " Missionsbelohnung: +%d freie EP%s." % [_mission.reward_xp if win else 0, "" if win else " (nur bei Sieg)"]
	var intro := UiTheme.label("Runde %d. Fertigkeits-EP gab es nur für benutzte Fertigkeiten. Jede Figur bekommt %d freie EP pro Einsatz.%s Freie EP füllen fehlende EP beim Rangkauf auf oder steigern Eigenschaften; nicht ausgegebene freie EP bleiben gespart." % [c.round_no, FREE_XP, reward], 13, UiTheme.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	var note := UiTheme.label("Prototyp: Tote und Bewusstlose stehen im nächsten Kampf wieder voll bereit (Regeln für Heilung, Tod und Ersatz sind noch offen).", 12, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	_page = VBoxContainer.new()
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_page)
	var reset := UiTheme.button("Crew zurücksetzen", "Allen gespeicherten Fortschritt der Crew verwerfen")
	reset.add_theme_color_override("font_color", UiTheme.BAD)
	reset.pressed.connect(_confirm_reset)
	footer.add_child(reset)
	var next := UiTheme.button("Speichern & nächste Mission")
	next.add_theme_color_override("font_color", UiTheme.ACCENT)
	next.pressed.connect(func() -> void:
		hide()
		next_battle.emit())
	footer.add_child(next)
	_render()


func current() -> Combatant:
	return _crew[_idx] if not _crew.is_empty() else null


func page(delta: int) -> void:
	if _crew.is_empty():
		return
	_idx = posmod(_idx + delta, _crew.size())
	_render()


func _unhandled_input(e: InputEvent) -> void:
	if not visible or not (e is InputEventKey) or not e.pressed:
		return
	if e.keycode == KEY_LEFT:
		page(-1)
		get_viewport().set_input_as_handled()
	elif e.keycode == KEY_RIGHT:
		page(1)
		get_viewport().set_input_as_handled()


func _render() -> void:
	UiTheme.clear(_page)
	var u := current()
	if u == null:
		return
	# Blättern: ◀ Reiter je Figur ▶
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	var prev := UiTheme.button("◀", "vorige Figur (Pfeil links)")
	prev.pressed.connect(page.bind(-1))
	nav.add_child(prev)
	for i in _crew.size():
		var o := _crew[i]
		var b := UiTheme.button("%s %s%s" % [o.letter, o.name.split(" ")[0], (" · %d" % o.free_xp) if o.free_xp else ""], "%s: %d freie EP" % [o.name, o.free_xp], true)
		b.button_pressed = i == _idx
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			_idx = i
			_render())
		nav.add_child(b)
	var nxt := UiTheme.button("▶", "nächste Figur (Pfeil rechts)")
	nxt.pressed.connect(page.bind(1))
	nav.add_child(nxt)
	_page.add_child(nav)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 12))
	_page.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(UiTheme.badge(u.letter, u.color, 34))
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UiTheme.label("%s  (%d / %d)" % [u.name, _idx + 1, _crew.size()], 18, UiTheme.CREW))
	hv.add_child(UiTheme.label("%s · %s · %d Gegner ausgeschaltet" % [u.role, u.state_name(), u.kills], 12, UiTheme.MUTED))
	head.add_child(hv)
	var pool := UiTheme.label("Freie EP: %d" % u.free_xp, 20, UiTheme.ACCENT)
	pool.tooltip_text = "Davon aus diesem Einsatz: %d" % _gain.get(u, 0)
	pool.mouse_filter = Control.MOUSE_FILTER_PASS
	head.add_child(pool)
	var undo := UiTheme.button("zurücknehmen", "Alle Steigerungen dieser Figur seit Kampfende zurücknehmen")
	undo.disabled = not _changed(u)
	undo.pressed.connect(func() -> void:
		var s: Dictionary = _snap[u]
		u.skills = s.skills.duplicate(true)
		u.attrs = s.attrs.duplicate()
		u.free_xp = s.free_xp
		_render())
	head.add_child(undo)
	v.add_child(head)
	if not u.xp_log.is_empty():
		var keys := u.xp_log.keys()
		keys.sort_custom(func(a, b) -> bool: return u.xp_log[a] > u.xp_log[b])
		var gl := UiTheme.label("In diesem Kampf: " + ", ".join(keys.map(func(k) -> String: return "%s +%d" % [Rules.skill_name(k), u.xp_log[k]])), 13, UiTheme.GOOD)
		gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(gl)
	else:
		v.add_child(UiTheme.label("In diesem Kampf keine Fertigkeit benutzt.", 13, UiTheme.MUTED))

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	v.add_child(cols)
	var left := _attributes(u)
	cols.add_child(left)
	cols.add_child(_skills(u))


func _changed(u: Combatant) -> bool:
	var s: Dictionary = _snap.get(u, {})
	return not s.is_empty() and (s.free_xp != u.free_xp or s.attrs != u.attrs or s.skills != u.skills)


func _attributes(u: Combatant) -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 380
	v.add_child(UiTheme.label("Eigenschaften (+1 kostet 2 + Wert/10 freie EP)", 13, UiTheme.MUTED))
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 10)
	for h in ["Eigenschaft", "Wert", "Bonus", "nächste Stufe", ""]:
		g.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	for a in Rules.ATTRIBUTES:
		var val: int = u.attrs[a.id]
		var base: int = _snap[u].attrs[a.id] if _snap.has(u) else val
		g.add_child(UiTheme.label(a.name, 13))
		g.add_child(UiTheme.label(str(val) + ((" (+%d)" % (val - base)) if val > base else ""), 13, UiTheme.GOOD if val > base else UiTheme.TEXT))
		g.add_child(UiTheme.label(Dice.fmt(Rules.attr_bonus(val)), 13))
		var nb := Rules.next_bonus_step(val)
		g.add_child(UiTheme.label(("ab %d: %s" % [nb, Dice.fmt(Rules.attr_bonus(nb))]) if nb > 0 else "–", 12, UiTheme.MUTED))
		var cost := Rules.attr_cost(val)
		var b := UiTheme.button("+1 (%d EP)" % cost)
		b.disabled = not Rules.can_raise_attr(u, a.id)
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func() -> void:
			Rules.raise_attr(u, a.id)
			_render())
		g.add_child(b)
	v.add_child(g)
	v.add_child(UiTheme.label("Trefferpunkte im nächsten Kampf: %d · Psi-Punkte: %d" % [Rules.max_hp(u), Rules.max_pp(u)], 12, UiTheme.MUTED))
	return v


func _skills(u: Combatant) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var top := HBoxContainer.new()
	var t := UiTheme.label("Fertigkeiten (Rang kostet 10 + 2 × Rang EP)", 13, UiTheme.MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var all := UiTheme.button("alle zeigen", "Auch Fertigkeiten ohne Rang und EP zeigen (z. B. um sie mit freien EP zu lernen)", true)
	all.button_pressed = _show_all
	all.toggled.connect(func(on: bool) -> void:
		_show_all = on
		_render())
	top.add_child(all)
	v.add_child(top)
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 10)
	for h in ["Fertigkeit", "Rang", "Gesamt", "EP / Kosten", ""]:
		g.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	var shown := 0
	for grp in Rules.SKILL_GROUPS:
		for sk in grp.skills:
			var id := StringName(sk[0])
			var s: Dictionary = u.skills.get(id, {"rank": 0, "xp": 0})
			if not _show_all and s.rank == 0 and s.xp == 0 and not u.xp_log.has(id):
				continue
			shown += 1
			var base_rank: int = _snap[u].skills.get(id, {}).get("rank", 0) if _snap.has(u) else s.rank
			g.add_child(UiTheme.label(sk[1], 13, UiTheme.GOOD if u.xp_log.has(id) else UiTheme.TEXT))
			g.add_child(UiTheme.label(str(s.rank) + ((" (+%d)" % (s.rank - base_rank)) if s.rank > base_rank else ""), 13, UiTheme.GOOD if s.rank > base_rank else UiTheme.TEXT))
			g.add_child(UiTheme.label(Dice.fmt(Rules.skill_total(u, id)), 13))
			var cost := Rules.rank_cost(s.rank)
			g.add_child(UiTheme.label("%d / %d" % [s.xp, cost], 13))
			var missing := maxi(0, cost - s.xp)
			var b: Button
			if missing == 0:
				b = UiTheme.button("Rang %d" % (s.rank + 1))
				b.add_theme_color_override("font_color", UiTheme.ACCENT)
			else:
				b = UiTheme.button("Rang %d (%d frei)" % [s.rank + 1, missing], "Fehlende %d EP aus den freien EP nehmen" % missing)
				b.disabled = missing > u.free_xp
			b.add_theme_font_size_override("font_size", 12)
			b.pressed.connect(func() -> void:
				Rules.rank_up_with_pool(u, id)
				_render())
			g.add_child(b)
	if shown == 0:
		v.add_child(UiTheme.label("noch keine Fertigkeit gelernt – „alle zeigen“ einschalten", 12, UiTheme.MUTED))
	v.add_child(g)
	return v


func _confirm_reset() -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = "Alle Fortschritte der Crew verwerfen?"
	d.ok_button_text = "Zurücksetzen"
	d.cancel_button_text = "Abbrechen"
	add_child(d)
	d.confirmed.connect(func() -> void:
		hide()
		reset_crew.emit())
	d.popup_centered()
