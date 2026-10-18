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
	# kein zufälliger Feindkontakt, nur Bodenaufträge (eigene Schritte unten)
	SpaceEvents.fixed_contact = -2
	SpaceEvents.fixed_kind = "boden"
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
	await _click_button(get_tree().current_scene, "Charakterbogen")
	await _frames(5)
	print("Roster: Charakterbogen offen ", (get_tree().current_scene as RosterScreen).sheet.visible)
	await _shot("h0b2_roster_bogen")
	(get_tree().current_scene as RosterScreen).sheet.close()
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
	# Raumkampf-Bereiche: Übersicht Gegnerschiffe und eine Schiffswaffe
	enc2.show_at(&"s_schiffe", Encyclopedia.OVERVIEW)
	await _frames(5)
	await _shot("h0e_enzyklopaedie_schiffe")
	enc2.show_at(&"s_waffen", "Laserbank")
	await _frames(5)
	await _shot("h0f_enzyklopaedie_schiffswaffe")
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
	# Schiffshändler: Volltanken, Material kaufen
	await _click_button(hub.ui.star_map, "Schiffshändler")
	await _frames(5)
	await _click_button(hub.ui.port, "Volltanken")
	await _click_button(hub.ui.port, "1 kaufen")
	await _shot("h1a1_schiffshaendler")
	hub.ui.port.hide()
	# Werft: große Reparatur
	await _click_button(hub.ui.star_map, "Werft")
	await _frames(5)
	await _click_button(hub.ui.ship_arms, "1× reparieren")
	print("Raumhafen: Credits %d -> %d, Tank %d, Material %d, Hülle %d" % [cr0, g.credits, g.fuel, g.material, g.hull])
	hub.ui.ship_arms.hide()
	# Händler: kaufen und verkaufen
	g.credits += 1000
	await _click_button(hub.ui.star_map, "Händler")
	await _frames(5)
	await _click_button(hub.ui.trade, "Würfeln")
	print("Handelsprobe: %s" % g.trade_rolls)
	await _click_button(hub.ui.trade, "Kaufen")
	await _frames(5)
	print("Handel: offen %s, Lager %s, Credits %d" % [hub.ui.trade.visible, g.stock, g.credits])
	await _shot("h1a2_handel")
	await _click_button(hub.ui.trade, "Verkaufen")
	print("Handel: nach Verkauf Lager %s, Credits %d" % [g.stock, g.credits])
	# Werkstatt: beschädigtes Stück im Lager reparieren
	Stock.add(g, Stock.damaged_key("res://data/weapons/sturmgewehr.tres", -20))
	Stock.add(g, Stock.damaged_key("res://data/armor/mittel.tres", -30))
	# lange Lagerliste (Bildlaufleiste): nichts darf rechts überlaufen
	var long_stock := g.stock.duplicate()
	for f in ResourceLoader.list_directory("res://data/weapons").slice(0, 12):
		if f.ends_with(".tres"):
			Stock.add(g, Stock.damaged_key("res://data/weapons/" + f, -10))
	hub.ui.trade.show_trade(g)
	await _frames(5)
	await _shot("h1a4_handel_lang")
	g.stock = long_stock
	hub.ui.trade.show_trade(g)
	await _frames(5)
	await _shot("h1a3_werkstatt")
	await _click_button(hub.ui.trade, "Reparieren")
	print("Werkstatt: Lager %s, Credits %d" % [g.stock, g.credits])
	hub.ui.trade.hide()
	g.credits -= 1000
	await _click_button(hub.ui.star_map, "Crew anheuern")
	await _frames(5)
	await _shot("h1b_hafen")
	await _click_button(hub.ui.port, "Anheuern")
	hub.ui.port.hide()
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
	await _shot("h1f0_maschinenraum_auswahl")
	await _click_button(hub.ui.notice, "Schiffsausbau")
	await _frames(5)
	await _click_button(hub.ui.engine, "Crew: 3 Material")
	await _frames(5)
	print("Maschinenraum: offen %s, Stufen %s, Projekt %s, Credits %d, Material %d" % [hub.ui.engine.visible, g.upgrades, g.project, g.credits, g.material])
	await _shot("h1f_maschinenraum")
	hub.ui.engine.hide()
	# Raumkampf, Teil 1: Waffenslots und Posten, Systemschäden, Handel „Schiff“
	ShipArms.stock_add(g, "partikelkanone")
	ShipArms.stock_add(g, "schnellfeuerkanone|-10")
	g.ship_slots.backbord.damage = -20
	ShipArms.set_stage(g, "antrieb", 3)
	ShipArms.set_stage(g, "lebenserhaltung", 5)
	ShipArms.set_stage(g, "station_computer", 1)
	hub.open_room(&"hangar")
	await _frames(5)
	await _click_button(hub.ui.notice, "Waffenslots und Posten")
	await _frames(5)
	await _shot("h1f1_waffenslots")
	hub.ui.ship_arms.hide()
	g.material = 8
	g.hull = mini(g.hull, 60)
	hub.open_room(&"hangar")
	await _frames(5)
	await _click_button(hub.ui.notice, "Systemschäden")
	await _frames(5)
	await _click_button(hub.ui.ship_arms, "Reparieren")
	await _frames(5)
	print("Systemschäden: offen %s, Schäden %s, Material %d, Tag %d" % [hub.ui.ship_arms.visible, g.ship_damage, g.material, g.day])
	await _shot("h1f2_systemschaeden")
	hub.ui.ship_arms.hide()
	# Werft im Hafen: Systemschäden, Ausbau, Waffe einbauen
	hub.ui.ship_arms.show_yard(g)
	await _frames(5)
	await _shot("h1f3_werft")
	await _click_button(hub.ui.ship_arms, "Ausbau")
	await _frames(5)
	await _shot("h1f4_werft_ausbau")
	await _click_button(hub.ui.ship_arms, "Waffenslots")
	await _frames(5)
	await _click_button(hub.ui.ship_arms, "Tauschen …")
	await _frames(5)
	await _shot("h1f5_werft_waffenslots")
	await _click_button(hub.ui.ship_arms, "Einbauen")
	print("Werft: offen %s, Slots %s, Lager %s" % [hub.ui.ship_arms.visible, g.ship_slots, g.ship_stock])
	hub.ui.ship_arms.hide()
	g.ship_damage = {}
	# Raumkampf im Spiel (Teil 2): Feindkontakt, Bericht nach dem Raumkampf, Notfall (ohne Szenenwechsel)
	g.contact = {"faction": "rote_sonne", "difficulty": "mittel", "system": g.position, "forced": false, "escort": -1}
	hub.ui.show_contact(g)
	await _frames(5)
	await _shot("h1i_feindkontakt")
	hub.ui.contact.hide()
	g.contact = {}
	g.space_ctx = {"kind": "reise", "offer_id": -1, "faction": "rote_sonne", "difficulty": "mittel", "mission": "Feindkontakt: Söldner"}
	var sres := {"outcome": &"sieg", "retreated": false, "surrendered": false, "ransom": {}, "boarding": false, "emergency": false, "units": {},
		"rounds": 14, "ship": {"hull": 64, "damage": {"antrieb": "B"}, "slots": {}}, "ship_ammo_used": {"geschosse": 22, "schiffsraketen": 3},
		"fuel_used": 6, "board_enemy": false, "ship_loot": {"credits": 210, "material": 2, "ship_ammo": {"geschosse": 8},
		"weapons": [{"key": "schnellfeuerkanone", "name": "Schnellfeuerkanone", "damage": -20}]}}
	g.finish_space(sres)
	hub.ui.show_space_report(g.space_report)
	await _frames(5)
	await _shot("h1j_raumkampf_bericht")
	hub.ui.space_report.hide()
	g.space_ctx = {"kind": "reise", "offer_id": -1, "faction": "konzern", "difficulty": "mittel", "mission": "Feindkontakt: Konzern"}
	var lost := sres.duplicate(true)
	lost.outcome = &"niederlage"
	lost.emergency = true
	lost.ship_loot = {}
	g.finish_space(lost)
	hub.ui.show_space_report(g.space_report)
	await _frames(5)
	await _shot("h1k_notfall")
	hub.ui.space_report.hide()
	print("Raumkampf-Berichte: Plünderung %s, Hülle %d" % [g.space_report.plunder, g.hull])
	g.hull = g.hull_max()
	g.ship_damage = {}
	g.space_report = {}
	# Kombüse: Koch einstellen, ein Tag außerhalb des Hafens mit Kochprobe
	Galley.set_cook(g, Campaign.crew()[1])
	var pos0 := g.position
	for i in g.sector.systems.size():
		if not g.is_harbor(i):
			g.position = i
			break
	g.wait_days(1)
	g.position = pos0
	hub.open_room(&"galley")
	await _frames(10)
	print("Kombüse offen %s, Koch %s, Proviant %d, Proben %d" % [hub.ui.galley.visible, g.cook, g.provisions, g.cooklog.size()])
	await _shot("h1h_kombuese")
	hub.ui.galley.hide()
	# Waffenkammer: Raum öffnet den Ausrüstungsdialog des Charakter-Moduls (erste Figur mit beschädigter Ausrüstung)
	Campaign.crew()[0].wear = {"w0": -10, "armor": -30}
	Stock.add(HubState.game, Stock.damaged_key(Stock.key_of(Campaign.crew()[0].weapons[0]), -20))
	Stock.add(HubState.game, Stock.damaged_key("res://data/weapons/laserpistole.tres", -30))
	hub.open_room(&"armory")
	await _frames(5)
	await _shot("h1d0_waffenkammer_auswahl")
	await _click_button(hub.ui.notice, "Ausrüstung")
	await _frames(10)
	print("Waffenkammer: Dialog offen ", hub.ui.armory.visible)
	await _shot("h1d_waffenkammer")
	# Reiter „Lager“: ganzes Schiffslager, direkt anlegen
	Stock.add(HubState.game, Equipment.SHIELD)
	Stock.add(HubState.game, Stock.MEDKIT, 2)
	Stock.add(HubState.game, "res://data/armor/leicht.tres")
	Stock.add(HubState.game, "res://data/weapons/sturmgewehr.tres|+5")
	Stock.add(HubState.game, "res://data/armor/leicht.tres|+5")
	hub.ui.armory._mode = "stock"
	hub.ui.armory._render()
	await _frames(5)
	await _shot("h1d2_waffenkammer_lager")
	var before := Stock.count(HubState.game, "res://data/weapons/laserpistole.tres|-30")
	Equipment.set_weapon(Campaign.crew()[0], 1, load("res://data/weapons/laserpistole.tres"), HubState.game, -30)
	hub.ui.armory._render()
	print("Lager-Reiter: Laserpistole (−30) als Waffe 2 angelegt ", Stock.count(HubState.game, "res://data/weapons/laserpistole.tres|-30") == before - 1, ", Platz ", Campaign.crew()[0].wear_of("w1"))
	await _frames(5)
	await _shot("h1d3_waffenkammer_lager_angelegt")
	Equipment.set_weapon(Campaign.crew()[0], 0, load("res://data/weapons/sturmgewehr.tres"), HubState.game, Stock.BONUS)
	print("Gutes Stück: Sturmgewehr (+5) als Waffe 1 ", Campaign.crew()[0].wear_of("w0"))
	hub.ui.armory._mode = "equip"
	hub.ui.armory._slot = "w0"
	hub.ui.armory._render()
	await _frames(5)
	await _shot("h1d4_waffenkammer_gut")
	hub.ui.armory._mode = "equip"
	hub.ui.armory.hide()
	# Werkstatt: über die Auswahl beim Raum, Material auffüllen, Bauen beginnen
	HubState.game.craft_material = 40
	hub.open_room(&"armory")
	await _frames(5)
	await _click_button(hub.ui.notice, "Werkstatt")
	await _frames(10)
	print("Werkstatt offen ", hub.ui.craft.visible)
	await _shot("h1g_werkstatt_bauen")
	await _click_button(hub.ui.craft, "Bauen")
	print("Werkstatt: Arbeiten %s, Material %d" % [HubState.game.jobs, HubState.game.craft_material])
	await _click_button(hub.ui.craft, "Reparieren")
	await _frames(5)
	await _shot("h1g2_werkstatt_reparieren")
	hub.ui.craft.hide()
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
	# Auftragsarten (Mockup Bildschirm 41): vorübergehend drei Aufträge anderer Art im gewählten System
	var extra := []
	var esc_t := SpaceEvents.escort_target(g, sm.selected)
	for k in [{"kind": "boden", "blockade": true}, {"kind": "abfangen", "blockade": false}, {"kind": "eskorte", "blockade": false}]:
		if k.kind == "eskorte" and esc_t < 0:
			continue
		var xo := {"id": 900 + extra.size(), "system": sm.selected, "seed": 4242 + extra.size(), "difficulty": "mittel",
			"expires": g.day + 8, "retry": false, "kind": k.kind, "blockade": k.blockade}
		if k.kind == "eskorte":
			xo.target = esc_t
		extra.append(xo)
	g.offers.append_array(extra)
	sm.refresh()
	await _frames(5)
	await _shot("h4a_auftragsarten")
	g.offers = g.offers.filter(func(o: Dictionary) -> bool: return int(o.id) < 900)
	sm.refresh()
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
	# Status nach der Reise (die Hülle repariert die Crew jetzt als Arbeit im Maschinenraum)
	g.hull = 60
	sm.refresh()
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
	# warten, bis die Kampfszene geladen ist (höchstens 600 Frames)
	var waited := 0
	while not get_tree().current_scene is Battle and waited < 600:
		await _frames(10)
		waited += 10
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
	print("Beute offen: %s" % g.loot_pending)
	var sc := hub.ui.report.content.get_parent() as ScrollContainer
	sc.scroll_vertical = 100000
	await _frames(5)
	await _shot("h9a_beuteauswahl")
	var saved := Roster.load_crew()
	print("freie EP: im Speicher %d, gespeichert %d (erwartet je Figur %d)" % [Campaign.crew()[0].free_xp, saved[0].free_xp,
		MissionResult.FREE_XP + int(Campaign.last_result.get("reward_xp", 0))])
	# Crewquartiere nach dem Einsatz: Übersicht mit dem Ergebnis
	var stock0 := g.stock.duplicate()
	hub.ui.report.hide()
	# Einsatzbericht mit Ausgang Rückzug (Beispiel)
	hub.ui.show_report({"outcome": &"rueckzug", "retreated": true, "title": "Lagerhalle säubern (Rückzug)", "system": "Kessra IV",
		"faction": "Schrottbarone", "rounds": 4, "reward_xp": 0, "free_xp": MissionResult.FREE_XP, "units": [], "day": g.day,
		"expires": g.day + 6, "prov0": 30, "prov1": 24, "cook": g.cooklog.slice(0, 1)})
	await _frames(5)
	await _shot("h9c_bericht_rueckzug")
	hub.ui.report.hide()
	# Einsatzbericht: Entern abgewehrt in einer Blockade (Beispiel)
	hub.ui.show_report({"outcome": &"sieg", "defend": true, "title": "Abwehr an Bord", "system": "Kessra IV", "faction": "Rote Sonne",
		"rounds": 6, "reward_xp": 0, "free_xp": MissionResult.FREE_XP, "units": [], "day": g.day, "payout": {}, "medkits": 1, "next": "ground",
		"board": "Korvette Ash", "board_loot": {"credits": 120, "material": 2, "ship_ammo": {"geschosse": 10}, "weapons": [{"key": "raketenwerfer", "damage": -10}]}})
	await _frames(5)
	await _shot("h9d_bericht_abwehr")
	hub.ui.report.hide()
	await _frames(2)
	print("Beute übernommen: offen %s, Lager %s -> %s" % [g.loot_pending, stock0, g.stock])
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
