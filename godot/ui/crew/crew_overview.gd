class_name CrewOverview
extends Modal
## Charakter-Modul: Übersicht der Crew zum Durchblättern (Reiter, Pfeiltasten) und Aufleveln. Je Figur:
## 3D-Vorschau, Name/Kürzel/Farbe/Station/Aussehen ändern, Eigenschaften und Ränge mit freien EP steigern
## (fehlende EP aus dem freien Pool, keine Ranggrenze), neue Psi-Liste: erster Rang doppelt, eine pro Levelphase.
## Nach einem Einsatz zeigt sie dessen Ergebnis (Campaign.last_result); die EP sind dann schon verbucht.

signal next_battle
signal reset_crew
## veraltet: im Spiel wird nicht mehr erschaffen, sondern aus dem Roster angeheuert (Signal bleibt für alte Verbindungen)
signal create_member
## Crew geändert (angeheuert oder entlassen; schon gespeichert)
signal crew_changed
signal open_sheet(crew: Array[Character], u: Character)

var _crew: Array[Character] = []
var _result := {}
var _idx := 0
var _snap := {}          # Character -> Stand beim Öffnen (für "zurücknehmen")
var _show_all := false
var _page: VBoxContainer
var _preview: FigurePreview
var _visuals: Array[CharacterVisual] = []
## Plätze an Bord (der Hub kann mehr erlauben)
var seats := Campaign.START_SEATS
var _hire: Modal


func show_crew(crew: Array[Character], result := {}) -> void:
	if _preview and _preview.get_parent():
		_preview.get_parent().remove_child(_preview)
	closable = false
	_crew = crew
	_result = result
	_idx = clampi(_idx, 0, maxi(0, crew.size() - 1))
	_snap.clear()
	for u in _crew:
		_snap[u] = {"skills": u.skills.duplicate(true), "attrs": u.attrs.duplicate(), "free_xp": u.free_xp, "new_list": u.new_list}
	if _visuals.is_empty():
		_visuals = FigurePreview.visual_choices()
	var intro: Label
	if result.is_empty():
		open("Crew")
		intro = UiTheme.label("Freie EP füllen fehlende EP beim Rangkauf auf oder steigern Eigenschaften; nicht ausgegebene freie EP bleiben gespart.", 13, UiTheme.MUTED)
	else:
		var win: bool = result.outcome == &"sieg"
		open("%s%s" % ["Sieg!" if win else "Niederlage", (" – " + result.mission) if result.mission != "" else ""])
		var reward := ""
		if result.mission != "":
			reward = " Missionsbelohnung: +%d freie EP%s." % [result.reward_xp, "" if win else " (nur bei Sieg)"]
		intro = UiTheme.label("Runde %d. Fertigkeits-EP gab es nur für benutzte Fertigkeiten. Jede Figur bekommt %d freie EP pro Einsatz.%s Freie EP füllen fehlende EP beim Rangkauf auf oder steigern Eigenschaften; nicht ausgegebene freie EP bleiben gespart." % [result.rounds, MissionResult.FREE_XP, reward], 13, UiTheme.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	if not result.is_empty():
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
	var aboard := UiTheme.label("An Bord %d / %d" % [crew.size(), seats], 13, UiTheme.MUTED)
	aboard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aboard.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(aboard)
	var fire := UiTheme.button("Entlassen", "Gewählte Figur entlassen (Fortschritt in diesem Spiel geht verloren, der Roster-Eintrag bleibt)")
	fire.add_theme_color_override("font_color", UiTheme.BAD)
	fire.disabled = crew.size() <= 1
	fire.pressed.connect(func() -> void: _confirm_fire(current()))
	footer.add_child(fire)
	var hire := UiTheme.button("Anheuern", "Figur aus dem Roster an Bord holen" if crew.size() < seats else "Kein Platz an Bord")
	hire.disabled = crew.size() >= seats
	hire.pressed.connect(_show_hire)
	footer.add_child(hire)
	var next := UiTheme.button("Speichern & nächste Mission")
	next.add_theme_color_override("font_color", UiTheme.ACCENT)
	next.pressed.connect(func() -> void: next_battle.emit())
	footer.add_child(next)
	_render()


## Ergebnis des letzten Einsatzes für eine Figur (leer ohne Einsatz)
func _unit_result(u: Character) -> Dictionary:
	return _result.get("units", {}).get(u.id, {})


func current() -> Character:
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
	# Vorschau behalten (nicht mit dem Inhalt freigeben), damit das Modell nicht bei jedem Klick neu lädt
	if _preview and _preview.get_parent():
		_preview.get_parent().remove_child(_preview)
	UiTheme.clear(_page)
	var u := current()
	if u == null:
		return
	# Reiter je Figur mit freien EP
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 6)
	for i in _crew.size():
		var o := _crew[i]
		var b := UiTheme.button("%s %s%s" % [o.letter, o.name.split(" ")[0], (" · %d" % o.free_xp) if o.free_xp else ""], "%s: %d freie EP (Pfeiltasten blättern)" % [o.name, o.free_xp], true)
		b.button_pressed = i == _idx
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			_idx = i
			_render())
		nav.add_child(b)
	_page.add_child(nav)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 12))
	_page.add_child(card)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	card.add_child(cols)
	cols.add_child(_left_column(u))
	cols.add_child(_skills(u))


# ---------------------------------------------------------------- links: Person, Eigenschaften, Psi

func _left_column(u: Character) -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 400
	v.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	if _preview == null:
		_preview = FigurePreview.new()
	top.add_child(_preview)
	_preview.show_character(u)

	var person := VBoxContainer.new()
	person.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(person)
	var name_edit := LineEdit.new()
	name_edit.text = u.name
	name_edit.add_theme_font_size_override("font_size", 18)
	name_edit.add_theme_color_override("font_color", UiTheme.CREW)
	name_edit.text_submitted.connect(func(_t: String) -> void: _render())
	name_edit.text_changed.connect(func(t: String) -> void:
		if t.strip_edges() != "":
			u.name = t.strip_edges())
	name_edit.focus_exited.connect(_render.call_deferred)
	person.add_child(name_edit)
	var ur := _unit_result(u)
	var sub := u.role
	if not ur.is_empty():
		sub += " · %s · %d Gegner ausgeschaltet" % [{"ok": "kampffähig", "ko": "bewusstlos", "tot": "tot"}.get(ur.status.state, ""), ur.kills]
	var sl := UiTheme.label(sub, 12, UiTheme.MUTED)
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	person.add_child(sl)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 8)
	person.add_child(g)
	g.add_child(UiTheme.label("Kürzel, Farbe", 12, UiTheme.MUTED))
	var hb := HBoxContainer.new()
	var letter := LineEdit.new()
	letter.text = u.letter
	letter.max_length = 1
	letter.custom_minimum_size.x = 36
	letter.text_changed.connect(func(t: String) -> void:
		if t != "":
			u.letter = t.to_upper())
	letter.focus_exited.connect(_render.call_deferred)
	hb.add_child(letter)
	var col := ColorPickerButton.new()
	col.color = u.color
	col.edit_alpha = false
	col.custom_minimum_size = Vector2(50, 26)
	col.popup_closed.connect(func() -> void:
		u.color = col.color
		_render())
	hb.add_child(col)
	g.add_child(hb)
	g.add_child(UiTheme.label("Station", 12, UiTheme.MUTED))
	var st := OptionButton.new()
	for i in Creation.STATIONS.size():
		var s: String = Creation.STATIONS[i]
		st.add_item(s if s != "" else "keine", i)
		st.set_item_disabled(i, not Creation.station_free(_crew, s, u))
	st.select(maxi(0, Creation.STATIONS.find(u.station)))
	st.tooltip_text = "Jede Station nur einmal, Jäger mehrfach (docs/Raumkampf.md)"
	st.item_selected.connect(func(i: int) -> void:
		u.station = Creation.STATIONS[i]
		_render())
	g.add_child(st)
	g.add_child(UiTheme.label("Aussehen", 12, UiTheme.MUTED))
	var vis := OptionButton.new()
	for i in _visuals.size():
		vis.add_item(FigurePreview.visual_name(_visuals[i]), i)
	vis.select(maxi(0, _visuals.find(u.visual)))
	vis.item_selected.connect(func(i: int) -> void:
		u.visual = _visuals[i]
		_render())
	g.add_child(vis)

	# freie EP, zurücknehmen, Bogen
	var pool_row := HBoxContainer.new()
	pool_row.add_theme_constant_override("separation", 10)
	var pool := UiTheme.label("Freie EP: %d" % u.free_xp, 20, UiTheme.ACCENT)
	pool.tooltip_text = "Davon aus diesem Einsatz: %d" % ur.get("free_xp", 0)
	pool.mouse_filter = Control.MOUSE_FILTER_PASS
	pool.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pool_row.add_child(pool)
	var undo := UiTheme.button("zurücknehmen", "Alle Steigerungen dieser Figur seit dem Öffnen der Übersicht zurücknehmen")
	undo.disabled = not _changed(u)
	undo.pressed.connect(func() -> void:
		var s: Dictionary = _snap[u]
		u.skills = s.skills.duplicate(true)
		u.attrs = s.attrs.duplicate()
		u.free_xp = s.free_xp
		u.new_list = s.new_list
		_render())
	pool_row.add_child(undo)
	var sheet := UiTheme.button("Charakterbogen", "Vollständigen Bogen mit den aktuellen Werten öffnen")
	sheet.pressed.connect(func() -> void: open_sheet.emit(_crew, u))
	pool_row.add_child(sheet)
	v.add_child(pool_row)
	v.add_child(_attributes(u))
	v.add_child(UiTheme.label("Trefferpunkte %d · Psi-Punkte %s" % [Rules.max_hp(u), str(Rules.max_pp(u)) if Rules.has_psi(u) else "–"], 13, UiTheme.MUTED))
	v.add_child(_psi_powers(u))
	return v


func _changed(u: Character) -> bool:
	var s: Dictionary = _snap.get(u, {})
	return not s.is_empty() and (s.free_xp != u.free_xp or s.attrs != u.attrs or s.skills != u.skills)


func _attributes(u: Character) -> Control:
	var v := VBoxContainer.new()
	v.add_child(UiTheme.label("Eigenschaften (+1 kostet 2 + Wert/10 freie EP)", 13, UiTheme.MUTED))
	var g := GridContainer.new()
	g.columns = 5
	g.add_theme_constant_override("h_separation", 10)
	for h in ["Eigenschaft", "Wert", "Bonus", "nächste Stufe", ""]:
		g.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	for a in Rules.ATTRIBUTES:
		var val: int = u.attrs[a.id]
		var base: int = _snap[u].attrs[a.id] if _snap.has(u) else val
		var an := UiTheme.label(a.name, 13)
		an.tooltip_text = "%s zählt für: %s" % [a.name, ", ".join(Rules.skills_using(a.id))]
		an.mouse_filter = Control.MOUSE_FILTER_PASS
		g.add_child(an)
		g.add_child(UiTheme.label(str(val) + ((" (+%d)" % (val - base)) if val > base else ""), 13, UiTheme.GOOD if val > base else UiTheme.TEXT))
		g.add_child(UiTheme.label(Dice.fmt(Rules.attr_bonus(val)), 13))
		var nb := Rules.next_bonus_step(val)
		g.add_child(UiTheme.label(("ab %d: %s" % [nb, Dice.fmt(Rules.attr_bonus(nb))]) if nb > 0 else "–", 12, UiTheme.MUTED))
		var b := UiTheme.button("+1 (%d)" % Rules.attr_cost(val), "+1 für %d freie EP" % Rules.attr_cost(val))
		b.disabled = not Rules.can_raise_attr(u, a.id)
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func() -> void:
			Rules.raise_attr(u, a.id)
			_render())
		g.add_child(b)
	v.add_child(g)
	return v


func _psi_powers(u: Character) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(UiTheme.label("Psi-Kräfte", 13, UiTheme.MUTED))
	var learned := PsiLists.learned(u)
	if learned.is_empty():
		v.add_child(UiTheme.label("keine Psi-Liste gelernt", 12, UiTheme.MUTED))
	for id in learned:
		var l: Dictionary = PsiLists.LISTS[id]
		var r := Rules.skill_rank(u, id)
		v.add_child(UiTheme.label("%s – Rang %d · %s" % [l.name, r, l.probe], 13, Color("b07ae8")))
		for p in l.powers:
			var on: bool = p[0] <= r
			var pl := UiTheme.label("  %d  %s (%d PP)" % [p[0], p[1], p[0]], 12, UiTheme.TEXT if on else UiTheme.MUTED)
			pl.tooltip_text = p[2]
			pl.mouse_filter = Control.MOUSE_FILTER_PASS
			if not on:
				pl.modulate.a = 0.6
			v.add_child(pl)
	return v


# ---------------------------------------------------------------- rechts: Fertigkeiten

func _skills(u: Character) -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gained: Dictionary = _unit_result(u).get("xp", {})
	if not gained.is_empty():
		var keys := gained.keys()
		keys.sort_custom(func(a, b) -> bool: return gained[a] > gained[b])
		var gl := UiTheme.label("In diesem Einsatz: " + ", ".join(keys.map(func(k) -> String: return "%s +%d" % [Rules.skill_name(k), gained[k]])), 13, UiTheme.GOOD)
		gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(gl)
	elif not _unit_result(u).is_empty():
		v.add_child(UiTheme.label("In diesem Einsatz keine Fertigkeit benutzt.", 13, UiTheme.MUTED))
	var top := HBoxContainer.new()
	var t := UiTheme.label("Fertigkeiten: Rang kostet 10 + 2 × Rang, fehlende EP aus den freien EP, keine Ranggrenze.\nNeue Psi-Liste: erster Rang doppelt, höchstens eine neue Liste pro Levelphase.", 12, UiTheme.MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(t)
	var all := UiTheme.button("alle zeigen", "Auch Fertigkeiten ohne Rang und EP zeigen (z. B. um sie mit freien EP zu lernen)", true)
	all.button_pressed = _show_all
	all.toggled.connect(func(on: bool) -> void:
		_show_all = on
		_render())
	top.add_child(all)
	v.add_child(top)
	var shown := 0
	for grp in Rules.SKILL_GROUPS:
		var g := GridContainer.new()
		g.columns = 7
		g.add_theme_constant_override("h_separation", 10)
		var rows := 0
		for sk in grp.skills:
			var id := StringName(sk[0])
			var s: Dictionary = u.skills.get(id, {"rank": 0, "xp": 0})
			var used: bool = gained.has(id)
			if not _show_all and s.rank == 0 and s.xp == 0 and not used and grp.id != "psiListen":
				continue
			if rows == 0:
				for h in ["Fertigkeit", "Eig.", "Rang", "Gesamt", "EP / Kosten", "einzahlen", ""]:
					g.add_child(UiTheme.label(h, 11, UiTheme.MUTED))
			rows += 1
			shown += 1
			var base_rank: int = _snap[u].skills.get(id, {}).get("rank", 0) if _snap.has(u) else s.rank
			var new_list: bool = Rules.is_psi_list(id) and s.rank == 0
			var nl := UiTheme.label(sk[1] + ("  (neu: %d EP)" % Rules.next_rank_cost(u, id) if new_list else ""), 13,
				UiTheme.GOOD if used else (UiTheme.TEXT if s.rank > 0 else UiTheme.MUTED))
			nl.custom_minimum_size.x = 200
			g.add_child(nl)
			g.add_child(UiTheme.label("%s+%s" % [Rules.attr_short(sk[2]), Rules.attr_short(sk[3])], 12, UiTheme.MUTED))
			g.add_child(UiTheme.label(str(s.rank) + ((" (+%d)" % (s.rank - base_rank)) if s.rank > base_rank else ""), 13, UiTheme.GOOD if s.rank > base_rank else UiTheme.TEXT))
			g.add_child(UiTheme.label(_effect(u, id, s.rank), 13))
			var cost := Rules.next_rank_cost(u, id)
			g.add_child(UiTheme.label("%d / %d" % [s.xp, cost], 13))
			var dep := HBoxContainer.new()
			dep.add_theme_constant_override("separation", 4)
			for n in [1, 5]:
				var db := UiTheme.button("+%d" % n, "%d freie EP auf %s einzahlen" % [n, sk[1]])
				db.add_theme_font_size_override("font_size", 12)
				db.custom_minimum_size.x = 36
				db.disabled = u.free_xp <= 0
				db.pressed.connect(func() -> void:
					Rules.deposit_xp(u, id, n)
					_render())
				dep.add_child(db)
			g.add_child(dep)
			var missing := maxi(0, cost - s.xp)
			var block := Rules.rank_block(u, id)
			var b: Button
			if missing == 0:
				b = UiTheme.button("Rang %d" % (s.rank + 1), block)
				b.add_theme_color_override("font_color", UiTheme.ACCENT)
			else:
				b = UiTheme.button("Rang %d (%d frei)" % [s.rank + 1, missing], block if block != "" else "Fehlende %d EP aus den freien EP nehmen" % missing)
			b.disabled = missing > u.free_xp or block != ""
			b.add_theme_font_size_override("font_size", 12)
			b.pressed.connect(func() -> void:
				Rules.rank_up_with_pool(u, id)
				_render())
			g.add_child(b)
		if rows > 0:
			v.add_child(UiTheme.label(grp.name, 13, UiTheme.ACCENT))
			v.add_child(g)
	if shown == 0:
		v.add_child(UiTheme.label("noch keine Fertigkeit gelernt – „alle zeigen“ einschalten", 12, UiTheme.MUTED))
	return v


## Was die Ränge bringen: Gesamtbonus, bei Entwicklung TP/PP, bei Listen die Zahl der Kräfte
func _effect(u: Character, id: StringName, r: int) -> String:
	if id == &"koerper":
		return "+%d TP" % (r * Rules.HP_PER_RANK)
	if id == &"psiPunkte":
		return "+%d PP" % (r * Rules.PP_PER_RANK)
	if PsiLists.is_list(id):
		return "%d Kräfte" % PsiLists.powers(u, id).size()
	return Dice.fmt(Rules.skill_total(u, id))


## Anheuern: Roster-Figuren, die noch nicht an Bord sind (Kopie mit dem Stand des Roster-Eintrags)
func _show_hire() -> void:
	if _hire == null:
		_hire = Modal.new()
		add_child(_hire)
		_hire.max_size = Vector2(760, 620)
	_hire.open("Anheuern aus dem Roster")
	var free := GlobalRoster.entries().filter(func(c: Character) -> bool: return not Campaign.is_aboard(c.roster_id))
	_hire.content.add_child(UiTheme.label("Figuren, die noch nicht an Bord sind. Platz: %d frei. Angeheuert wird eine Kopie mit dem Stand des Roster-Eintrags." % (seats - _crew.size()), 13, UiTheme.MUTED))
	if free.is_empty():
		_hire.content.add_child(UiTheme.label("Alle Roster-Figuren sind schon an Bord. Neue Figuren entstehen im Roster (Startmenü).", 13, UiTheme.MUTED))
	for c in free:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row.add_child(UiTheme.badge(c.letter, c.color, 30))
		var l := UiTheme.label("%s – %s" % [c.name, c.role], 14)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var b := UiTheme.button("anheuern")
		b.add_theme_color_override("font_color", UiTheme.ACCENT)
		b.disabled = _crew.size() >= seats
		b.pressed.connect(func() -> void:
			var h := Campaign.hire(c)
			_hire.close()
			if h:
				_crew = Campaign.crew()
				_idx = _crew.find(h)
			_reopen())
		row.add_child(b)
		_hire.content.add_child(row)
	_hire.add_close()
	_hire.move_to_front()


func _confirm_fire(u: Character) -> void:
	if u == null or _crew.size() <= 1:
		return
	var d := ConfirmationDialog.new()
	d.dialog_text = "%s entlassen?\nDer Fortschritt in diesem Spiel geht verloren; der Roster-Eintrag bleibt und kann später neu angeheuert werden." % u.name
	d.ok_button_text = "Entlassen"
	d.cancel_button_text = "Abbrechen"
	add_child(d)
	d.confirmed.connect(func() -> void:
		Campaign.fire(u)
		_crew = Campaign.crew()
		_idx = clampi(_idx, 0, _crew.size() - 1)
		_reopen())
	d.popup_centered()


## Übersicht mit der geänderten Crew neu aufbauen (Knopftexte des Aufrufers gehen dabei verloren → crew_changed)
func _reopen() -> void:
	var title_keep := _idx
	show_crew(_crew, _result)
	_idx = title_keep
	_render()
	crew_changed.emit()


func _exit_tree() -> void:
	if _preview and not _preview.is_inside_tree():
		_preview.free()


func _confirm_reset() -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = "Alle Fortschritte der Crew verwerfen?"
	d.ok_button_text = "Zurücksetzen"
	d.cancel_button_text = "Abbrechen"
	add_child(d)
	d.confirmed.connect(func() -> void: reset_crew.emit())
	d.popup_centered()
