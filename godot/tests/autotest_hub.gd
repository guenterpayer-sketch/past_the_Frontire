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
	print("Musik Startmenü: Anlass %s, Stücke %d, Busse Musik/Effekte %d/%d, Sfx auf Effekt-Bus %s" % [Music.theme, Music.tracks(Music.START).size(),
		AudioServer.get_bus_index(Music.BUS_MUSIC), AudioServer.get_bus_index(Music.BUS_SFX),
		Sfx.get_children().all(func(c: Node) -> bool: return not c is AudioStreamPlayer or (c as AudioStreamPlayer).bus == Music.BUS_SFX)])
	await _shot("h0_start")
	# Enzyklopädie über das Burgermenü im Startmenü
	var st0 := get_tree().current_scene as StartScreen
	var burger: MenuButton = st0.find_children("*", "MenuButton", true, false)[0]
	burger.get_popup().id_pressed.emit(0)
	await _frames(10)
	var enc := st0.find_children(Encyclopedia.NAME, "Encyclopedia", true, false)[0] as Encyclopedia
	print("Enzyklopädie offen: %s, Bereich %s, Eintrag %s" % [enc.visible, enc.section, enc.entry])
	await _click_button(enc, "Sturmgewehr")
	await _frames(5)
	await _shot("h0e1_enz_waffe")
	await _click_button(enc, "Psi-Listen")
	await _click_button(enc, "Angriff")
	await _frames(5)
	await _shot("h0e2_enz_psi")
	await _click_button(enc, "Kurzregeln")
	await _click_button(enc, "Reichweite und Deckung")
	await _frames(5)
	await _shot("h0e3_enz_regel")
	enc._search.text = "deckung"
	enc._search.text_changed.emit("deckung")
	await _frames(5)
	print("Enzyklopädie Suche „deckung“: %d Treffer" % enc._list.get_child_count())
	await _shot("h0e4_enz_suche")
	enc.close()
	# Ausrüstungs-Editor (Testordner): Revolver aus der Laserpistole, speichern, frei, löschen
	Gear.dir = "user://gear_autotest"
	var st := get_tree().current_scene as StartScreen
	await _click_button(st, "Ausrüstung")
	var ge := st.gear
	await _click_button(ge, "+ Neu")
	await _click_button(ge, "Laserpistole")
	ge.draft.name = "Revolver"
	var rv: Dictionary = WeaponModels.all().filter(func(m: Dictionary) -> bool: return m.name == "Revolver A")[0]
	WeaponModels.apply(ge.draft, rv)
	ge.draft.sound_id = rv.sound
	ge.refresh()
	ge.picking = false
	for i in 2:
		Gear.set_value(ge.draft, Gear.WEAPON_FIELDS[0], Gear.clamp_value(ge.draft, Gear.WEAPON_FIELDS[0], ge.draft.inc_m + 1))
	ge.refresh()
	await _frames(5)
	await _shot("h0a_editor_waffe")
	await _click_button(ge, "Speichern")
	print("Editor: gespeichert %d Waffen, Revolver Reichweite %d (Vorlage 10)" % [Gear.weapons().size(), Gear.weapons()[0].inc_m if not Gear.weapons().is_empty() else -1])
	await _click_button(ge, "Werte frei")
	await _frames(5)
	await _shot("h0a2_editor_frei")
	await _click_button(ge, "Löschen")
	await _frames(5)
	await _shot("h0a3_editor_loeschen")
	await _click_button(ge._confirm, "Löschen")
	print("Editor: nach Löschen %d Waffen" % Gear.weapons().size())
	await _click_button(ge, "Rüstungen")
	await _click_button(ge, "+ Neu")
	await _click_button(ge, "Kampfpanzer")
	await _frames(5)
	await _shot("h0a4_editor_ruestung")
	ge.close()
	Gear.dir = "user://gear"
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
	print("Musik Schiff: Anlass %s" % Music.theme)
	hub._on_action(&"encyclopedia", null)
	await _frames(5)
	var enc2 := hub.ui.get_node_or_null(Encyclopedia.NAME)
	print("Enzyklopädie im Schiff offen: %s, Dialog erkannt %s" % [enc2 != null and enc2.visible, hub.ui.any_dialog_open()])
	enc2.close()
	print("Schiff: Tag %d, %s, %d Aufträge" % [g.day, g.sector.systems[g.position].name, g.offers.size()])
	await _shot("h1_schiff")
	# Hafen (Start im Heimathafen): eine Figur entlassen und auf der Brücke wieder anheuern
	var gone: Character = Campaign.crew()[Campaign.crew().size() - 1]
	Campaign.fire(gone)
	hub.open_room(&"bridge")
	hub.ui.star_map.select(g.position)
	await _frames(10)
	# Raumhafen: Tank halb leer, Volltanken, Material kaufen
	g.fuel = 70
	g.hull = 70
	hub.ui.star_map.refresh()
	await _frames(5)
	await _shot("h1a_raumhafen")
	var cr0 := g.credits
	await _click_button(hub.ui, "Volltanken")
	await _click_button(hub.ui, "1 kaufen")
	await _click_button(hub.ui, "1× reparieren")
	print("Raumhafen: Credits %d -> %d, Tank %d, Material %d, Hülle %d" % [cr0, g.credits, g.fuel, g.material, g.hull])
	# Handel: kaufen und verkaufen
	g.credits += 1000
	await _click_button(hub.ui, "Handel")
	await _frames(5)
	await _click_button(hub.ui.trade, "Würfeln")
	print("Handelsprobe: %s" % g.trade_rolls)
	await _click_button(hub.ui.trade, "Kaufen")
	await _frames(5)
	print("Handel: offen %s, Lager %s, Credits %d" % [hub.ui.trade.visible, g.stock, g.credits])
	await _shot("h1a2_handel")
	await _click_button(hub.ui.trade, "Verkaufen")
	print("Handel: nach Verkauf Lager %s, Credits %d" % [g.stock, g.credits])
	hub.ui.trade.hide()
	g.credits -= 1000
	await _click_button(hub.ui, "Crew anheuern")
	await _frames(5)
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
	# Maschinenraum (früher Hangar): Schiffsausbau
	g.credits = 3000
	g.material = 8
	hub.open_room(&"hangar")
	await _frames(5)
	await _click_button(hub.ui.engine, "Werft ")
	await _click_button(hub.ui.engine, "Crew: 3 Material")
	await _frames(5)
	print("Maschinenraum: offen %s, Stufen %s, Projekt %s, Credits %d, Material %d" % [hub.ui.engine.visible, g.upgrades, g.project, g.credits, g.material])
	await _shot("h1f_maschinenraum")
	hub.ui.engine.hide()
	# Waffenkammer: Raum öffnet den Ausrüstungsdialog des Charakter-Moduls (erste Figur mit beschädigter Ausrüstung)
	Campaign.crew()[0].wear = {"w0": -10, "armor": -30}
	hub.open_room(&"armory")
	await _frames(10)
	print("Waffenkammer: Dialog offen ", hub.ui.armory.visible)
	await _shot("h1d_waffenkammer")
	# UI-Größe über das Menü im Schiff: 75 % und zurück
	var f0 := UiScale.get_factor()
	hub.ui.show_ui_scale()
	await _click_button(hub.ui, "75 %")
	await _frames(5)
	var v0 := Music.get_volume(Music.BUS_MUSIC)
	Music.set_volume(Music.BUS_MUSIC, 30)
	var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index(Music.BUS_MUSIC))
	Music.set_volume(Music.BUS_MUSIC, 0)
	var muted := AudioServer.is_bus_mute(AudioServer.get_bus_index(Music.BUS_MUSIC))
	Music.set_volume(Music.BUS_MUSIC, v0)
	print("Lautstärke Musik: %d %% -> 30 %% = %.1f dB, 0 %% stumm %s, zurück %d %%" % [v0, db, muted, Music.get_volume(Music.BUS_MUSIC)])
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
	sm.refresh()
	await _frames(5)
	await _shot("h4b_kurs_reiseposten")
	await _click_button(hub.ui, "Kurs setzen")
	print("Reise: Tag %d -> %d, Position %s, Reisebericht offen %s, Treibstoff %d -> %d, Hülle %d -> %d" % [day0, g.day,
		g.sector.systems[g.position].name, hub.ui.travel_report.visible, g.last_travel.get("fuel0", -1), g.fuel,
		g.last_travel.get("hull0", -1), g.hull])
	await _shot("h5_reisebericht")
	await _click_button(hub.ui, "Weiter")
	print("Reisebericht geschlossen: ", not hub.ui.travel_report.visible)
	# große Reparatur durch die Crew (1 Tag, 1 Material)
	g.hull = 60
	sm.refresh()
	var d1 := g.day
	await _click_button(hub.ui, "Große Reparatur")
	print("Crew-Reparatur: Tag %d -> %d, Hülle 60 -> %d, Material %d" % [d1, g.day, g.hull, g.material])
	await _shot("h5b_crew_reparatur")
	hub.ui.notice.hide()
	await _shot("h5c_status_schiff")
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
	await _frames(10)
	if hub.ui.travel_report.visible:
		print("Reisebericht vor dem Einsatz offen")
		await _click_button(hub.ui, "Weiter")
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
	print("vor dem Ergebnis: Credits %d, Material %d" % [g.credits, g.material])
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
	print("nach dem Einsatz: Credits %d, Material %d" % [g.credits, g.material])
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
