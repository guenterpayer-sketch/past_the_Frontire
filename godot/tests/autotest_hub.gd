extends Node
## Selbsttest des Schiffs (Hub) mit Screenshots (Zielordner PTF_OUT), hängt an der Wurzel und übersteht
## die Szenenwechsel Startmenü → Schiff → Bodenkampf → Schiff:
##   godot --path godot -- --autotest-hub
## Spielstände landen in user://saves_test (die echten Slots bleiben unberührt).

var out := ""


func _ready() -> void:
	out = OS.get_environment("PTF_OUT")
	if out == "":
		out = "user://"
	SaveSlots.dir = "user://saves_test"
	for s in range(1, SaveSlots.COUNT + 1):
		SaveSlots.delete(s)
	_run.call_deferred()


func _run() -> void:
	await _frames(30)
	await _shot("h0_start")
	# Roster aus dem Startmenü und zurück
	await _click_button(get_tree().current_scene, "Roster")
	await _frames(20)
	print("Roster offen: ", get_tree().current_scene.scene_file_path == Campaign.ROSTER_SCENE)
	await _shot("h0b_roster")
	get_tree().change_scene_to_file(HubState.START_SCENE)
	await _frames(30)
	# Neues Spiel im Slot 1: Slot und Name, dann Crew aus dem Roster (CrewPicker)
	var start := get_tree().current_scene as StartScreen
	start._new_game(1, "Autotest")
	await _frames(10)
	print("CrewPicker offen: ", start.picker.visible)
	await _shot("h0c_crew_waehlen")
	seed(4711)
	var picked: Array[Character] = GlobalRoster.entries().slice(0, 7)
	start.start_new_game(1, "Autotest", picked)
	await _frames(40)
	var g := HubState.game
	print("Neues Spiel: %d an Bord (gewählt %d), Plätze %d, Slot 1 gespeichert %s" % [Campaign.crew().size(), picked.size(), g.berths,
		not SaveSlots.info(1).is_empty()])
	var hub := get_tree().current_scene as Hub
	print("Schiff: Tag %d, %s, %d Aufträge" % [g.day, g.sector.systems[g.position].name, g.offers.size()])
	await _shot("h1_schiff")
	# Hafen (Start im Heimathafen): eine Figur entlassen und auf der Brücke wieder anheuern
	var gone: Character = Campaign.crew()[Campaign.crew().size() - 1]
	Campaign.fire(gone)
	hub.open_room(&"bridge")
	hub.ui.star_map.select(g.position)
	await _frames(10)
	await _shot("h1b_hafen")
	await _click_button(hub.ui, "Anheuern")
	print("Hafen: %s im Hafen, nach Anheuern an Bord %s, Crew %d / %d" % [gone.name, Campaign.crew().has(gone), Campaign.crew().size(), g.berths])
	hub.ui.star_map.close()
	# Krankenstation: Verwundeten anlegen, Arzt zuweisen, einen Tag warten
	var pat: Character = Campaign.crew()[0]
	pat.injury = Injury.DOWN
	pat.injury_days = 5
	for c in Campaign.crew():
		if c != pat and g.medics.size() < Medbay.MAX_STAFF and Rules.skill_total(c, Medbay.SKILL) > -10:
			Medbay.toggle(g, c)
	hub.open_room(&"medbay")
	await _frames(5)
	await _click_button(hub.ui, "1 Tag warten")
	await _frames(5)
	print("Krankenstation: Arzt %s, %s noch %d Tage, Protokoll: %s" % [Medbay.doctor(g).name if Medbay.doctor(g) else "-", pat.name,
		pat.injury_days, g.medlog[0] if not g.medlog.is_empty() else "-"])
	await _shot("h1c_krankenstation")
	hub.ui.medbay.hide()
	# Waffenkammer: Raum öffnet den Ausrüstungsdialog des Charakter-Moduls
	hub.open_room(&"armory")
	await _frames(10)
	print("Waffenkammer: Dialog offen ", hub.ui.armory.visible)
	await _shot("h1d_waffenkammer")
	# UI-Größe über das Menü im Schiff: 75 % und zurück
	var f0 := UiScale.get_factor()
	hub.ui.show_ui_scale()
	await _click_button(hub.ui, "75 %")
	await _frames(5)
	print("UI-Größe: %s -> %s, Fenster %.2f" % [UiScale.label(f0), UiScale.label(UiScale.get_factor()), get_tree().root.content_scale_factor])
	await _shot("h1e_ui_75")
	UiScale.set_factor(f0, get_tree())
	hub.ui.notice.hide()
	await _click_button(hub.ui, "Fertig")
	print("Waffenkammer: nach „Fertig“ geschlossen ", not hub.ui.armory.visible)
	pat.injury = ""
	pat.injury_days = 0
	# Maus über die Brücke: Hervorhebung und Infokasten
	_mouse_move(hub.rig.camera.unproject_position(ShipView.room_center(&"bridge")))
	await _frames(10)
	print("Hover: ", hub._hover, " · Info: ", hub.ui.info.text().replace("\n", " | ").left(160))
	await _shot("h2_hover_bruecke")
	hub.rig.rotate_by(90)
	await get_tree().create_timer(0.6).timeout
	await _shot("h3_gedreht")
	hub.rig.rotate_by(-90)
	await get_tree().create_timer(0.6).timeout
	# Brücke anklicken (echter Mausklick auf das Deck)
	_mouse_click(hub.rig.camera.unproject_position(ShipView.room_center(&"bridge")))
	await _frames(10)
	print("Sternenkarte offen: ", hub.ui.star_map.visible)
	var sm := hub.ui.star_map
	var offer: Dictionary = g.offers[0]
	for o in g.offers:
		if o.system != g.position and g.reachable(o):
			offer = o
			break
	_mouse_click(sm.system_screen_pos(offer.system))
	await _frames(10)
	print("gewählt: %s (Auftrag im System: %s)" % [g.sector.systems[sm.selected].name, sm.selected_offer])
	await _shot("h4_sternenkarte")
	# Kurs setzen zu einem Nachbarsystem
	var day0 := g.day
	var nb: int = g.sector.neighbors(g.position)[0][0]
	sm.select(nb)
	await _click_button(hub.ui, "Kurs setzen")
	print("Reise: Tag %d -> %d, Position %s" % [day0, g.day, g.sector.systems[g.position].name])
	await _shot("h5_nach_reise")
	await _click_button(hub.ui, "Zurück ins Schiff")
	# Crewquartiere
	hub.open_room(&"quarters")
	await _frames(10)
	print("Crewquartiere offen: ", hub.ui.crew.visible, ", ", Campaign.crew().size(), " Figuren")
	await _shot("h6_crewquartiere")
	await _click_button(hub.ui, "Speichern & zurück")
	# Speichern-Dialog
	hub.ui.slots.show_slots(&"save", true)
	await _frames(5)
	await _shot("h7_speichern")
	await _click_button(hub.ui, "Überschreiben")
	hub.ui.slots.hide()
	for c in hub.ui.slots.get_children():
		if c is ConfirmationDialog:
			c.hide()
	# Auftrag annehmen -> Bodenkampf
	hub.ui.star_map.open(g)
	var o2: Dictionary = {}
	for o in g.offers:
		if g.reachable(o):
			o2 = o
			break
	hub.ui.star_map.select(o2.system, o2.id)
	await _frames(5)
	await _click_button(hub.ui, "Briefing")
	await _frames(60)
	var b := get_tree().current_scene as Battle
	print("Bodenkampf: %s gegen %s (erwartet %s), Briefing offen %s" % [b.mission.title, b.mission.faction.name,
		g.sector.faction_of(o2.system).name, b.ui.briefing.visible])
	var doc := Medbay.doctor(g)
	var doc_c: Array = b.candidates.filter(func(k: Dictionary) -> bool: return k.ch == doc)
	print("Truppwahl im Schiff: Arzt %s gesperrt %s (%s), nicht im Trupp %s, Trupp %d, Crew im Kampf %d" % [doc.name if doc else "-",
		doc_c[0].locked if not doc_c.is_empty() else false, doc_c[0].reason if not doc_c.is_empty() else "-",
		not doc in b.squad, b.squad.size(), b.combat.crew().size()])
	await _shot("h8_briefing_aus_schiff")
	b.ui.briefing.close()
	b.begin_combat()
	b.auto_crew = true
	var t0 := Time.get_ticks_msec()
	while b.combat.result == &"" and Time.get_ticks_msec() - t0 < 15000:
		await get_tree().create_timer(0.5).timeout
	if b.combat.result == &"":
		for e in b.combat.enemies():
			e.state = Combatant.State.DEAD
		b.combat.check_end()
	var done0 := g.missions_done
	var t0_banner := Time.get_ticks_msec()
	while not b.ui.result_banner.visible and Time.get_ticks_msec() - t0_banner < 10000:
		await get_tree().process_frame
	print("Ergebnis-Banner: ", b.ui.result_banner.visible)
	await _shot("h8b_ergebnis")
	b.ui.result_banner.confirm()
	await get_tree().create_timer(2.0).timeout
	hub = get_tree().current_scene as Hub
	print("zurück im Schiff: %s, Einsätze %d -> %d, Tag %d, Bericht offen %s" % [hub != null, done0, g.missions_done, g.day,
		hub.ui.report.visible if hub else false])
	await _frames(10)
	await _shot("h9_bericht")
	var saved := Roster.load_crew()
	print("freie EP: im Speicher %d, gespeichert %d (erwartet je Figur %d)" % [Campaign.crew()[0].free_xp, saved[0].free_xp,
		MissionResult.FREE_XP + int(Campaign.last_result.get("reward_xp", 0))])
	# Crewquartiere nach dem Einsatz: Übersicht mit dem Ergebnis
	hub.ui.report.hide()
	hub.open_room(&"quarters")
	await _frames(10)
	await _shot("h9b_crewquartiere_nach_einsatz")
	var reset_visible := false
	for fb in hub.ui.crew.footer.get_children():
		if fb is Button and fb.visible and (fb.text.begins_with("Crew zurücksetzen") or fb.text == "Anheuern"):
			reset_visible = true
	print("Crew zurücksetzen/Anheuern im Schiff sichtbar: ", reset_visible)
	await _click_button(hub.ui, "Speichern & zurück")
	print("Crewquartiere geschlossen: ", not hub.ui.crew.visible)
	# Laden: Slot 1 (vor dem Einsatz gespeichert)
	SaveSlots.load_slot(1)
	print("geladen: Tag %d, Einsätze %d, freie EP %d (Campaign neu geladen)" % [HubState.game.day, HubState.game.missions_done,
		Campaign.crew()[0].free_xp])
	get_tree().change_scene_to_file(HubState.START_SCENE)
	await _frames(30)
	await _shot("h10_start_mit_spielstand")
	# Schnellkampf: nichts verbuchen, zurück ins Startmenü
	var slot_day: int = SaveSlots.info(1).day
	(get_tree().current_scene as StartScreen).start_quick_battle()
	var fx0: int = Campaign.crew()[0].free_xp
	print("Schnellkampf-Crew aus dem Roster: %d Figuren (Roster %d)" % [Campaign.crew().size(), GlobalRoster.entries().size()])
	await _frames(60)
	var qb := get_tree().current_scene as Battle
	var start_ids := Roster.start_crew().map(func(c: Character) -> StringName: return c.id)
	print("Schnellkampf-Truppwahl: %d Kandidaten aus dem Roster (Roster %d), vorbelegt %d, alle Startfiguren %s, Crew im Kampf %d" % [
		qb.candidates.size(), GlobalRoster.entries().size(), qb.squad.size(),
		qb.squad.all(func(c: Character) -> bool: return c.id in start_ids), qb.combat.crew().size()])
	await _shot("h11_schnellkampf_truppwahl")
	var chosen0 := Campaign.chosen_squad.size()
	qb.ui.briefing.close()
	print("Schnellkampf: gewählter Trupp im Spielstand unverändert %s" % (Campaign.chosen_squad.size() == chosen0))
	qb.begin_combat()
	for e in qb.combat.enemies():
		e.state = Combatant.State.DEAD
	qb.combat.check_end()
	await get_tree().create_timer(5.0).timeout
	print("Schnellkampf: zurück im Startmenü %s, freie EP %d -> %d (gespeichert %d)" % [get_tree().current_scene is StartScreen,
		fx0, Campaign.crew()[0].free_xp, Roster.load_crew()[0].free_xp])
	print("Spielstand nach Schnellkampf unverändert: ", SaveSlots.info(1).day == slot_day)
	for s in range(1, SaveSlots.COUNT + 1):
		SaveSlots.delete(s)
	print("AUTOTEST FERTIG")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _to_window(p: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * p


func _mouse_move(p: Vector2) -> void:
	p = _to_window(p)
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	Input.parse_input_event(e)


func _mouse_click(p: Vector2) -> void:
	_mouse_move(p)
	p = _to_window(p)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = p
		e.global_position = p
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		Input.parse_input_event(e)


## Sichtbaren Button mit passendem Text suchen und mit der Maus anklicken
func _click_button(root: Node, text: String) -> void:
	await _frames(2)
	var found: Button = null
	for n in root.find_children("*", "Button", true, false):
		var btn := n as Button
		if btn.is_visible_in_tree() and not btn.disabled and btn.text.contains(text):
			found = btn
	if found == null:
		print("Button nicht gefunden: ", text)
		return
	_mouse_click(found.get_global_rect().get_center())
	await get_tree().create_timer(0.3).timeout
