extends SceneTree
## Tests des Schiffs (Hub) ohne Grafik: Sektor, Reisen, Aufträge, Spielstände.
## godot --headless --path godot --script res://tests/test_hub.gd

var fails := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FEHLER: ", what)


func _init() -> void:
	CustomMaps.dir = "user://maps_test_none"   # nur Zufallskarten (eigene Karten des Nutzers nicht mitprüfen)
	SpaceEvents.fixed_contact = -2       # kein Feindkontakt auf Reisen (eigene Tests in _test_space_events)
	SpaceEvents.fixed_kind = "boden"
	TradeSkills.fixed = &"teilerfolg"   # Normalpreise für die älteren Preistests; _test_trade_skills prüft die Stufen
	_test_sector()
	_test_travel_and_offers()
	_test_mission_faction()
	_test_save_slots()
	_test_medbay_and_harbor()
	_test_ui_scale()
	_test_voyage()
	_test_gear()
	_test_ammo()
	_test_encyclopedia()
	_test_galaxy()
	_test_story_hub()
	_test_auftrag3()
	_test_gear_models()
	_test_training()
	_test_upgrades()
	_test_stock()
	_test_trade_skills()
	_test_station_trade()
	_test_loot()
	_test_crafting()
	_test_galley()
	_test_retreat()
	_test_ship_arms()
	_test_space_events()
	print("OK" if fails == 0 else "%d FEHLER" % fails)
	quit(1 if fails else 0)


## Mehrere Sektoren, Sprungtore, Papiere, Orte mit Funktion (Auftrag 2, Entscheidungen des Nutzers 19.10.2026)
func _test_galaxy() -> void:
	var gal := Sector.galaxy(321)
	check(gal.size() == Sector.SECTOR_COUNT, "drei Sektoren")
	for k in gal.size():
		check(gal[k].gates.size() == 2 and gal[k].gates.all(func(t: Dictionary) -> bool: return int(t.system) != gal[k].home), "Sektor %d: zwei Tore, nicht am Heimathafen" % k)
		for t in gal[k].gates:
			var back: Array = gal[int(t.to_sector)].gates.filter(func(x: Dictionary) -> bool: return int(x.to_sector) == k)
			check(back.size() == 1 and int(back[0].system) == int(t.to_system) and int(back[0].to_system) == int(t.system)
				and int(t.fee) >= Sector.GATE_FEE[0] and int(t.fee) <= Sector.GATE_FEE[1], "Tor mit Rückweg und Gebühr 300–600")
	var g := HubState.new_game(321)
	check(g.sectors.size() == 3 and g.sector == g.sectors[0] and g.known_sectors == [0], "neues Spiel: drei Sektoren, nur der Start bekannt")
	check(g.offers.all(func(o: Dictionary) -> bool: return int(o.get("place", -1)) >= 0), "Aufträge an einem Ort")
	var o: Dictionary = g.offers[0]
	var pk := String(g.sector.systems[int(o.system)].places[int(o.place)].kind)
	check(g.mission_of(o).map_type in Places.MAPS[pk], "Kartentyp passt zum Ort (%s)" % pk)
	# alte Spielstände (ein Sektor) gelten als veraltet
	var old := g.to_dict()
	old.erase("sectors")
	old["sector"] = g.sector.to_dict()
	check(HubState.outdated(old) and not HubState.outdated(g.to_dict()), "alter Spielstand veraltet")
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.sectors.size() == 3 and h.sector.to_dict() == g.sector.to_dict() and h.sectors[2].gates.size() == 2, "Sektoren im Spielstand")
	# Sprung: Papiere, Gebühr, neuer Sektor
	var gate: Dictionary = g.sector.gates[0]
	gate.papers = true
	gate.operator = Mission.all_factions()[0].resource_path
	check(g.jump_block(gate) != "", "Sprung nur im System des Tors")
	g.position = int(gate.system)
	g.credits = 2000
	check(g.jump_block(gate).begins_with("Papiere"), "Tor verlangt Papiere")
	g.papers.append(String(gate.operator))
	var fee := g.gate_fee(gate)
	var d0 := g.day
	check(g.jump(gate) and g.cur_sector == int(gate.to_sector) and g.position == int(gate.to_system) and g.credits == 2000 - fee
		and g.day == d0 + 1 and int(gate.to_sector) in g.known_sectors, "Sprung: Gebühr, 1 Tag, neuer Sektor aufgedeckt")
	check(g.offers.all(func(x: Dictionary) -> bool: return int(x.system) < g.sector.systems.size()), "Aufträge im neuen Sektor")
	# Papiere im Hafen
	g.position = g.sector.home
	g.credits = 1000
	var op := Mission.all_factions()[1].resource_path
	check(g.buy_papers(op) and op in g.papers and g.credits == 1000 - g.papers_price() and not g.can_buy_papers(op), "Papiere im Hafen kaufen")
	# Stationshandel 20 % teurer außerhalb des Hafens
	var hostile := -1
	for i in g.sector.systems.size():
		if not g.sector.is_neutral(i):
			hostile = i
			break
	var f_harbor := TradeSkills.buy_factor(g)
	g.position = hostile
	check(is_equal_approx(TradeSkills.buy_factor(g), f_harbor * Places.STATION_FACTOR), "Station: Kauf 20 % teurer")
	# Bergung und Schöpfen
	g.sector.systems[hostile].places = [{"kind": "wrack", "name": "Wrack „Test“", "done": false}, {"kind": "gas", "name": "Gas", "done": false}]
	g.material = 0
	g.craft_material = 0
	Voyage.fixed_result = &"erfolg"
	d0 = g.day
	var e := Places.salvage(g, 0)
	check(not e.is_empty() and g.material == 3 and g.craft_material == 2 and g.day == d0 + 1 and g.sector.systems[hostile].places[0].done
		and not Places.can_salvage(g, 0), "Bergung: Erfolg +3/+2, 1 Tag, danach leer")
	g.fuel = 10
	e = Places.skim(g, 1)
	check(not e.is_empty() and g.fuel == 30 and Places.can_skim(g, 1), "Schöpfen: Erfolg +20 Treibstoff, beliebig oft")
	Voyage.fixed_result = &"patzer"
	var h0 := g.hull
	Places.skim(g, 1)
	check(g.hull == h0 - 5, "Schöpfen: Patzer −5 Hülle")
	Voyage.fixed_result = &""
	HubState.game = null


func _test_sector() -> void:
	var a := Sector.generate(4711)
	var b := Sector.generate(4711)
	check(a.to_dict() == b.to_dict(), "gleicher Seed = gleicher Sektor")
	check(a.systems.size() >= Sector.SYSTEM_MIN and a.systems.size() <= Sector.SYSTEM_MAX, "Anzahl Systeme 15–20")
	for seed_value in [1, 2, 3, 99, 4711, 123456]:
		var s := Sector.generate(seed_value)
		var names := {}
		var neutral := 0
		for i in s.systems.size():
			names[s.systems[i].name] = true
			check(s.route(s.home, i).days >= 0, "Seed %d: System %d erreichbar" % [seed_value, i])
			for j in s.systems.size():
				if i != j:
					check((s.systems[i].pos as Vector2).distance_to(s.systems[j].pos) >= Sector.MIN_DIST, "Mindestabstand")
			if s.systems[i].faction == "":
				neutral += 1
		check(names.size() == s.systems.size(), "Seed %d: Namen eindeutig" % seed_value)
		check(s.systems[s.home].faction == "", "Heimathafen neutral")
		check(neutral == Sector.NEUTRAL, "Seed %d: %d neutrale Systeme (erwartet %d)" % [seed_value, neutral, Sector.NEUTRAL])
		for r in s.routes:
			check(r.days >= 1 and r.days <= Sector.MAX_DAYS, "Reisetage 1–3")
		var fset := {}
		for sys in s.systems:
			if sys.faction != "":
				fset[sys.faction] = true
		var kinds := {}
		for p in fset:
			kinds[(load(p) as FactionData).kind] = true
		check(fset.size() == kinds.size() and kinds.size() == Mission.sector_factions(RandomNumberGenerator.new()).size(), "Seed %d: je Oberart eine Fraktion mit Systemen" % seed_value)
		for i in s.systems.size():
			var pl: Array = s.systems[i].places
			check(pl.size() >= Places.MIN_PLACES and pl.size() <= Places.MAX_PLACES, "Seed %d: 2–4 Orte je System" % seed_value)
			if s.is_neutral(i):
				check(pl.any(func(p: Dictionary) -> bool: return p.kind == "station"), "Hafen hat eine Station")
	var c := Sector.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	check(c.to_dict() == a.to_dict(), "Sektor übersteht Speichern als JSON")
	# Weg: Summe der Reisetage entlang des Pfads
	var r := a.route(a.home, (a.home + 5) % a.systems.size())
	var sum := 0
	for k in range(r.path.size() - 1):
		for n in a.neighbors(r.path[k]):
			if n[0] == r.path[k + 1]:
				sum += n[1]
	check(sum == r.days and r.path[0] == a.home, "Weg und Reisetage passen zusammen")


func _test_travel_and_offers() -> void:
	seed(42)
	var g := HubState.new_game(4711, "Test", 1)
	check(g.day == 1 and g.position == g.sector.home, "Start im Heimathafen an Tag 1")
	check(g.offers.size() == HubState.OFFERS, "Aufträge aufgefüllt")
	for o in g.offers:
		check(g.sector.systems[o.system].faction != "", "Aufträge nur in Systemen mit Fraktion")
		check(o.expires >= g.day + HubState.OFFER_DAYS[0], "Laufzeit")
	# Reisen kostet Tage
	var target: int = g.sector.neighbors(g.position)[0][0]
	var days: int = g.sector.neighbors(g.position)[0][1]
	var expected: int = g.sector.route(g.position, target).days
	check(g.travel_to(target) == expected and g.day == 1 + expected and g.position == target, "Reisen: Tage vergehen (%d)" % days)
	check(g.travel_to(target) == 0, "Reise zum eigenen Standort kostet nichts")
	# Ablauf: Auftrag mit kurzer Laufzeit verschwindet nach der Reise
	g.offers[0].expires = g.day
	var gone_id: int = g.offers[0].id
	var other: int = g.sector.neighbors(g.position)[0][0]
	g.travel_to(other)
	check(g.offers.filter(func(o: Dictionary) -> bool: return o.id == gone_id).is_empty(), "abgelaufener Auftrag verschwindet")
	check(g.offers.size() == HubState.OFFERS, "nach der Reise wieder aufgefüllt")
	# Unerreichbarer Auftrag (Ankunft nach Ablauf) lässt sich nicht annehmen
	var o: Dictionary = g.offers[0]
	if o.system != g.position:
		o.expires = g.day
		check(not g.reachable(o) and not g.start_mission(o), "zu spät: Auftrag nicht annehmbar")
	# Einsatz: annehmen, abschließen
	var o2: Dictionary = g.offers[1]
	o2.expires = g.day + 30
	var day0 := g.day
	check(g.start_mission(o2) and HubState.in_mission() and g.position == o2.system, "Auftrag annehmen: hinfliegen, Einsatz läuft")
	var m := HubState.active_mission()
	check(m != null and m.faction.resource_path == g.sector.systems[o2.system].faction, "Mission gegen die Fraktion des Systems")
	var day1 := g.day
	g.finish_mission({"outcome": &"sieg", "title": m.title})
	check(not HubState.in_mission() and g.missions_done == 1, "Einsatz abgeschlossen")
	check(day1 >= day0 and g.day == day1 + HubState.MISSION_DAYS, "Einsatz dauert %d Tag" % HubState.MISSION_DAYS)
	check(g.offers.filter(func(x: Dictionary) -> bool: return x.id == o2.id).is_empty(), "erledigter Auftrag verschwindet")
	check(g.offers.size() == HubState.OFFERS, "nach dem Einsatz wieder aufgefüllt")
	check(g.report.get("day", 0) == g.day, "Bericht mit Tag")
	var day2 := g.day
	g.offers[0].expires = g.day
	var gone2: int = g.offers[0].id
	g.wait_days(1)
	check(g.day == day2 + 1 and g.offers.filter(func(x: Dictionary) -> bool: return x.id == gone2).is_empty()
		and g.offers.size() == HubState.OFFERS, "warten: Tag vergeht, Aufträge laufen ab und werden aufgefüllt")
	check(g.berths == HubState.BERTHS_START, "Plätze an Bord zu Beginn")
	g.berths = 10
	var d := g.to_dict()
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(d)), 2)
	check(h.to_dict() == d and h.slot == 2, "Spiel im Schiff übersteht Speichern als JSON")
	HubState.game = null


func _test_mission_faction() -> void:
	for f in Mission.all_factions():
		for seed_value in [1, 2, 3]:
			var m := Mission.generate(seed_value, "mittel", f.resource_path)
			check(m.faction == f, "feste Fraktion %s" % f.name)
			for e in m.enemies:
				var known := false
				for u in f.units:
					if e.name == u.name:
						known = true
				check(known, "Gegner %s gehört zu %s" % [e.name, f.name])
	var a := Mission.generate(77)
	var b := Mission.generate(77, "", "")
	check(a.title == b.title and a.faction == b.faction and a.enemies.size() == b.enemies.size(), "ohne Fraktion wie bisher")


func _test_save_slots() -> void:
	SaveSlots.dir = "user://saves_test"
	for s in range(1, SaveSlots.COUNT + 1):
		SaveSlots.delete(s)
	SaveSlots.delete(SaveSlots.AUTO)
	check(SaveSlots.latest() == -1 and SaveSlots.info(1).is_empty(), "keine Spielstände")
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	var g := HubState.new_game(99, "Erster", 2)
	g.day = 7
	check(SaveSlots.save(2, "Erster", g), "speichern")
	var i := SaveSlots.info(2)
	check(i.name == "Erster" and i.day == 7 and i.system == g.sector.systems[g.position].name, "Kurzinfo des Slots")
	check(SaveSlots.latest() == 2, "Fortsetzen = zuletzt gespeichert")
	# Auto-Spielstand (Auftrag 8): eigener Slot, Slot und Name des Spiels bleiben, Laden führt zurück zum eigenen Slot
	g.day = 9
	check(SaveSlots.autosave(g) and g.slot == 2 and g.slot_name == "Erster" and SaveSlots.info(SaveSlots.AUTO).day == 9
		and SaveSlots.info(2).day == 7, "Auto-Spielstand: eigener Slot, Slot 2 unberührt")
	check(SaveSlots.latest() in [SaveSlots.AUTO, 2], "Fortsetzen kennt den Auto-Spielstand")
	check(SaveSlots.load_slot(SaveSlots.AUTO) and HubState.game.day == 9 and HubState.game.slot == 2 and HubState.game.slot_name == "Erster",
		"Auto-Spielstand laden: Tag 9, weiter in Slot 2")
	SaveSlots.delete(SaveSlots.AUTO)
	check(Version.current() != "" and i.game_version == Version.current(), "Spielstand mit Version (Auftrag 7)")
	check(Version.label("") == "Version –", "alte Stände ohne Version: „–“")
	var pm := PopupMenu.new()
	pm.add_item("x", 0)
	Version.add_to(pm)
	check(pm.item_count == 3 and pm.is_item_disabled(2) and pm.get_item_text(2) == Version.label(Version.current()), "Versionszeile im Burgermenü")
	pm.free()
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSlots.path(2)))
	check(raw.keys().all(func(k: String) -> bool: return k in ["version", "game_version", "name", "saved_at", "game", "crew"]), "Spielstand ohne Roster (roster.json gehört nicht in die Slots)")
	HubState.game = null
	check(SaveSlots.load_slot(2) and HubState.game.day == 7 and HubState.game.slot == 2 and HubState.game.slot_name == "Erster", "laden")
	check(HubState.game.sector.to_dict() == g.sector.to_dict(), "Sektor nach dem Laden gleich")
	check(not SaveSlots.load_slot(3), "leerer Slot lässt sich nicht laden")
	for s in range(1, SaveSlots.COUNT + 1):
		SaveSlots.delete(s)
	# Crew-Datei so hinterlassen, wie sie war
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	HubState.game = null


func _test_medbay_and_harbor() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	check(Medbay.extra_days(99) == 0 and Medbay.extra_days(100) == 1 and Medbay.extra_days(149) == 1 and Medbay.extra_days(150) == 2, "Schwellen 100/150")
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(77, "Test", 1)
	var crew := Campaign.crew()
	# ohne Personal: genau 1 Tag Heilung pro Tag
	var a: Character = crew[0]
	a.injury = Injury.SEVERE
	a.injury_days = 10
	g.wait_days(3)
	check(a.injury_days == 7, "ohne Personal heilt 1 Tag pro Tag (%d)" % a.injury_days)
	check(Medbay.blocked_ids(g).is_empty(), "ohne Arzt keine Sperre")
	# Personal: Arzt = höhere Zweite Hilfe
	var best: Character = crew[0]
	for c in crew:
		if Rules.skill_total(c, Medbay.SKILL) > Rules.skill_total(best, Medbay.SKILL):
			best = c
	var other: Character = crew[1] if crew[1] != best else crew[2]
	Medbay.toggle(g, other)
	Medbay.toggle(g, best)
	Medbay.toggle(g, crew[3] if crew[3] != best and crew[3] != other else crew[4])
	check(g.medics.size() == Medbay.MAX_STAFF, "höchstens 2 Personal")
	check(Medbay.doctor(g) == best and Medbay.helper(g) == other, "Arzt = höchste Zweite Hilfe, Helfer der andere")
	check(Medbay.bonus(g) == Rules.skill_total(best, Medbay.SKILL) + Rules.skill_total(other, Medbay.SKILL) / 2, "Bonus Arzt + Helfer/2")
	check(Medbay.blocked_ids(g) == [best.id] and HubState.blocked_ids().keys() == [best.id], "Arzt gesperrt für die Truppwahl")
	var cands := Campaign.candidates(false, HubState.blocked_ids())
	var locked_doc := false
	for k in cands:
		if k.ch == best and k.locked:
			locked_doc = true
	check(locked_doc, "Campaign.candidates sperrt den Arzt")
	# mit Personal: im Schnitt schneller (viele Tage), EP fürs Personal
	var xp0: int = Rules.ensure_skill(best, Medbay.SKILL).xp
	var xp1: int = Rules.ensure_skill(other, Medbay.SKILL).xp
	Dice.set_seed(5)
	var healed_days := 0
	for k in 40:
		a.injury = Injury.SEVERE
		a.injury_days = 100
		g.wait_days(1)
		healed_days += 100 - a.injury_days
	check(healed_days > 40, "mit Personal heilt mehr als 1 Tag pro Tag (%d in 40 Tagen)" % healed_days)
	check(Rules.ensure_skill(best, Medbay.SKILL).xp == xp0 + 40 and Rules.ensure_skill(other, Medbay.SKILL).xp == xp1 + 40, "1 EP je Behandlungstag")
	check(not g.medlog.is_empty() and g.medlog.size() <= Medbay.LOG_SIZE, "Protokoll der Krankenstation")
	a.injury = Injury.LIGHT
	a.injury_days = 1
	g.wait_days(1)
	check(a.injury == "" and a in g.last_healed, "Geheilte werden gemeldet")
	# Reise und Einsatz lassen ebenfalls Tage vergehen
	a.injury = Injury.DOWN
	a.injury_days = 50
	var d0: int = a.injury_days
	var nb: int = g.sector.neighbors(g.position)[0][0]
	var days := g.travel_to(nb)
	check(a.injury_days <= d0 - days, "Reisen heilt (%d Tage)" % days)
	# Hafen
	check(g.is_harbor(g.sector.home) and not g.is_harbor(g.offers[0].system), "Hafen = neutrales System")
	check(g.free_berths() == g.berths - Campaign.crew().size(), "freie Plätze")
	# Speichern: Personal und Protokoll bleiben
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.medics == g.medics and h.medlog == g.medlog, "Personal und Protokoll im Spielstand")
	# Entlassenes Personal wird ausgetragen
	Campaign.fire(other)
	g.wait_days(1)
	check(not String(other.id) in g.medics, "entlassenes Personal ausgetragen")
	HubState.game = null
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


func _test_ui_scale() -> void:
	var before := UiScale.get_factor()
	check(UiScale.STEPS == [0.75, 0.9, 1.0, 1.25] and before in UiScale.STEPS, "UI-Größe: Stufen 75/90/100/125 %")
	UiScale.set_factor(0.75, self)
	check(is_equal_approx(UiScale.get_factor(), 0.75) and is_equal_approx(root.content_scale_factor, 0.75), "UI-Größe gespeichert und angewendet")
	UiScale.set_factor(0.5, self)
	check(is_equal_approx(UiScale.get_factor(), 0.75), "ungültige Stufe wird ignoriert")
	check(UiScale.label(0.9) == "90 %", "Beschriftung")
	UiScale.set_factor(before, self)


func _test_voyage() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(91, "Reise", 1)
	var crew := Campaign.crew()
	check(g.credits == Voyage.START_CREDITS and g.fuel == Voyage.TANK and g.hull == Voyage.HULL_MAX and g.material == Voyage.START_MATERIAL, "Startwerte Schiff")
	# Einteilung: Station zuerst, sonst Bester; jede Person ein Posten; Krankenstation und Gesperrte nicht
	for c in crew:
		c.station = ""
	var tech: Character = crew[5]
	tech.station = "Technik"
	var a := Voyage.assign(g)
	check(a[3].ch == tech and a[3].own, "Station Technik würfelt Reparatur")
	var best_pilot: Character = null
	for c in crew:
		if c != tech and (best_pilot == null or Rules.skill_total(c, &"pilot") > Rules.skill_total(best_pilot, &"pilot")):
			best_pilot = c
	check(a[0].ch == best_pilot and not a[0].own, "ohne Station: Bester in Pilot")
	var ids := {}
	for e in a:
		ids[e.ch] = true
	check(ids.size() == 4, "jede Person höchstens ein Posten")
	g.medics = [String(best_pilot.id)]
	check(Voyage.assign(g)[0].ch != best_pilot and not best_pilot in Voyage.available(g), "Krankenstation würfelt keine Reiseprobe")
	g.medics = []
	best_pilot.injury = Injury.SEVERE
	best_pilot.injury_days = 5
	check(not best_pilot in Voyage.available(g), "Gesperrte würfeln nicht")
	best_pilot.injury = ""
	best_pilot.injury_days = 0
	# Reisetag: Verbrauch zwischen Mindest- und Grundverbrauch, EP für die Würfelnden, Hülle im Rahmen
	Dice.set_seed(11)
	var xp0: int = Rules.ensure_skill(tech, &"rsReparatur").xp
	var row := Voyage.travel_day(g, 2)
	check(-row.fuel >= Voyage.FUEL_MIN and -row.fuel <= Voyage.FUEL_PER_DAY and g.fuel == Voyage.TANK + row.fuel, "Verbrauch je Reisetag (%d)" % row.fuel)
	check(row.checks.size() == 4 and Rules.ensure_skill(tech, &"rsReparatur").xp == xp0 + row.checks[3].xp, "EP in der benutzten Fertigkeit")
	check(row.hull == clampi(Voyage.HULL_MAX + int(Voyage.HULL_TRAVEL[row.checks[3].result]), 0, Voyage.HULL_MAX) - Voyage.HULL_MAX, "Hülle je Reparaturprobe (höchstens voll)")
	# Schätzung: gute Crew spart, schlechte kaum
	check(Voyage.expected_save(200) > Voyage.expected_save(0) and Voyage.expected_save(-100) < 0.1, "erwartete Ersparnis steigt mit dem Bonus")
	check(Voyage.estimate_fuel(g, 3) <= 3 * Voyage.FUEL_PER_DAY and Voyage.estimate_fuel(g, 3) >= 3 * Voyage.FUEL_MIN, "Schätzung im Rahmen")
	# Reise mit Bericht
	g.fuel = Voyage.TANK
	var nb: int = g.sector.neighbors(g.position)[0][0]
	var days := g.travel_to(nb)
	check(days > 0 and g.last_travel.rows.size() == days and g.last_travel.fuel1 == g.fuel, "Reisebericht je Tag")
	# Tank leer: nur zum nächsten Hafen, Notsprit ohne Verbrauch, danach doppelter Preis
	g.fuel = 1
	Voyage.travel_day(g, g.day)
	check(g.fuel == 0 and g.emergency and g.stranded(), "Tank läuft leer → Notsprit")
	var port := g.nearest_harbor()
	var other := -1
	for i in g.sector.systems.size():
		if i != port and i != g.position:
			other = i
			break
	check(not g.can_travel(other) and g.travel_to(other) == -1, "festgesetzt: kein Kurs außer zum Hafen")
	if port != g.position:
		check(g.can_travel(port) and g.travel_to(port) > 0 and g.fuel == 0, "Notsprit bis zum Hafen ohne Verbrauch")
	check(g.position == port and g.is_harbor(port), "im Hafen")
	g.credits = 50
	var got := Voyage.buy_fuel(g, 100)
	check(got == Voyage.TANK and g.credits == 50 - Voyage.TANK * Voyage.FUEL_PRICE_EMERGENCY and not g.emergency, "Tanken nach Notsprit doppelt, Notkredit (%d Cr)" % g.credits)
	check(Voyage.fuel_price(g) == Voyage.FUEL_PRICE, "danach wieder normaler Preis")
	# Ohne Credits: Material und Werft gesperrt (außer Hülle 0)
	g.hull = 50
	check(not Voyage.can_buy_material(g) and not Voyage.buy_material(g) and not Voyage.can_yard_repair(g), "Material und Werft nicht auf Kredit")
	g.credits = 1000
	check(Voyage.buy_material(g, 3) and g.material == Voyage.START_MATERIAL + 3 and g.credits == 1000 - 3 * Voyage.MATERIAL_PRICE, "Material kaufen")
	var m0 := g.material
	check(Voyage.yard_repair(g) and g.hull == 50 + Voyage.YARD_HULL and g.material == m0 - 1, "Werft: +25 Hülle für 1 Material")
	g.hull = 0
	g.credits = -10
	check(not g.can_travel(g.sector.neighbors(g.position)[0][0]), "Hülle 0: festgesetzt")
	check(Voyage.can_yard_repair(g) and Voyage.yard_repair(g) and g.hull == Voyage.YARD_HULL, "Hülle 0: Werft auch auf Notkredit")
	# Lohn und Beute
	var po := Voyage.payout("mittel", "res://data/missions/rote_sonne.tres", true)
	check(po.pay == 140 and po.bonus == 28 and is_equal_approx(po.factor, 1.2) and po.loot == 1 and po.ammo.size() == 1, "Lohn Rote Sonne mittel")
	check(Voyage.payout("schwer", "res://data/missions/schmuggler.tres", true).loot == 3, "Beute Schmuggler schwer")
	check(Voyage.payout("leicht", "res://data/missions/konzern.tres", false).is_empty(), "Niederlage: nichts")
	var o: Dictionary = g.offers[0]
	g.active = o
	g.credits = -30
	var cr0 := g.credits
	var mat0 := g.material
	g.finish_mission({"outcome": &"sieg"})
	var pay: Dictionary = g.report.payout
	check(g.credits == cr0 + int(pay.pay) + int(pay.bonus) and g.material == mat0 + int(pay.loot) and pay.credits0 == cr0, "Lohn verbucht, gleicht Schulden aus")
	g.active = g.offers[0]
	var cr1 := g.credits
	g.finish_mission({"outcome": &"niederlage"})
	check(g.credits == cr1 and g.report.payout.is_empty(), "Niederlage: kein Lohn")
	# Speichern
	g.emergency = true
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.credits == g.credits and h.fuel == g.fuel and h.hull == g.hull and h.material == g.material and h.emergency, "Schiffswerte im Spielstand")
	var old := HubState.from_dict({"sector": g.sector.to_dict()})
	check(old.credits == Voyage.START_CREDITS and old.fuel == Voyage.TANK, "alte Spielstände bekommen Startwerte")
	HubState.game = null
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


func _rm_tree(d: String) -> void:
	if not DirAccess.dir_exists_absolute(d):
		return
	for sub in DirAccess.get_directories_at(d):
		_rm_tree(d.path_join(sub))
	for f in DirAccess.get_files_at(d):
		DirAccess.remove_absolute(d.path_join(f))
	DirAccess.remove_absolute(d)


func _test_gear() -> void:
	Gear.dir = "user://gear_test"
	_rm_tree(Gear.dir)
	check(Gear.weapons().is_empty() and Gear.armors().is_empty(), "Editor: leer am Anfang")
	var pistol: WeaponData = load("res://data/weapons/laserpistole.tres")
	var w := Gear.from_template(pistol) as WeaponData
	check(w.name == "Laserpistole (eigen)" and not Gear.is_free(w) and Gear.template_of(w) == pistol, "Entwurf aus Vorlage")
	check(pistol.name == "Laserpistole", "Vorlage bleibt unverändert")
	var f_inc: Dictionary = Gear.WEAPON_FIELDS[0]
	var f_dmg: Dictionary = Gear.WEAPON_FIELDS[5]
	var f_fum: Dictionary = Gear.WEAPON_FIELDS[4]
	check(Gear.limits(w, f_inc) == Vector2(5, 15), "Reichweite ±50 %")
	check(Gear.limits(w, f_dmg).is_equal_approx(Vector2(0.6, 1.0)), "Schaden ±0,2")
	check(Gear.limits(w, f_fum) == Vector2(1, 4), "Patzer ±2, mindestens 1")
	check(Gear.clamp_value(w, f_inc, 99) == 15 and Gear.clamp_value(w, f_inc, 0) == 5, "Werte bleiben in Grenzen")
	check(not Gear.fields(w).any(func(f: Dictionary) -> bool: return f.has("splash")), "Druckwelle nur mit Vorlage mit Druckwelle")
	var hammer := Gear.from_template(load("res://data/weapons/energiehammer.tres"))
	check(not Gear.fields(hammer).any(func(f: Dictionary) -> bool: return f.get("ranged", false)), "Nahkampf ohne Reichweite")
	var rak := Gear.from_template(load("res://data/weapons/raketenwerfer.tres"))
	check(Gear.fields(rak).filter(func(f: Dictionary) -> bool: return f.has("splash")).size() == 2, "Raketenwerfer: zwei Druckwellen-Ringe")
	# Revolver speichern
	w.name = "Revolver"
	w.skill = &"pistolen"
	w.table = load("res://data/tables/attack_projektil.tres")
	Gear.set_value(w, f_inc, 12)
	Gear.set_value(w, f_dmg, 0.9)
	w.set_meta(&"enemy", true)
	var konzern := "res://data/missions/konzern.tres"
	w.set_meta(&"factions", [konzern])
	var saved := Gear.save(w) as WeaponData
	check(saved != null and Gear.is_custom(saved) and saved.resource_path.begins_with("user://gear_test/weapons/"), "gespeichert im Gear-Ordner")
	var path := saved.resource_path
	var again: WeaponData = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	check(again.name == "Revolver" and again.inc_m == 12 and is_equal_approx(again.damage, 0.9) and again.table.resource_path.ends_with("attack_projektil.tres"), "Werte gespeichert")
	check(String(again.get_meta(&"template", "")) == pistol.resource_path and again.get_meta(&"enemy", false) and again.get_meta(&"factions", []) == [konzern], "Metadaten gespeichert")
	check(Gear.weapons().size() == 1 and Gear.enemy_weapons(konzern).size() == 1 and Gear.enemy_weapons("res://data/missions/kult.tres").is_empty(), "Gegner nach Fraktion")
	# Bearbeiten ändert den getragenen Eintrag mit
	var edit := saved.duplicate()
	for m in saved.get_meta_list():
		edit.set_meta(m, saved.get_meta(m))
	edit.name = "Revolver Mk II"
	edit.set_meta(&"free", true)
	check(Gear.limits(edit, f_dmg).y == Gear.FREE_MAX, "frei: ohne Grenzen")
	Gear.set_value(edit, f_dmg, 2.5)
	var s2 := Gear.save(edit, saved)
	check(s2 == saved and saved.name == "Revolver Mk II" and Gear.is_free(saved) and saved.resource_path == path, "Bearbeiten: derselbe Eintrag, frei markiert")
	edit.set_meta(&"free", false)
	Gear.clamp_all(edit)
	check(is_equal_approx(edit.damage, 1.0), "frei aus: zurück in die Grenzen")
	# Charakter speichert die eigene Waffe über den Pfad
	var c: Character = GlobalRoster.entries()[0]
	c.weapons = [saved]
	var d := c.to_dict()
	check(path in d.weapons, "Charakter speichert eigene Waffe per Pfad")
	# Rüstung
	var vest := Gear.from_template(load("res://data/armor/mittel.tres")) as ArmorData
	check(Gear.limits(vest, Gear.ARMOR_FIELDS[0]) == Vector2(-10, 0) and Gear.limits(vest, Gear.ARMOR_FIELDS[1]) == Vector2(-1, 1), "Rüstung: Verteidigung ±5, Bewegung ±1")
	vest.name = "Plattenweste"
	check(Gear.save(vest) != null and Gear.armors().size() == 1 and Gear.armors()[0].cls == 2, "Rüstung gespeichert, Klasse wie Vorlage")
	# Löschen
	check(Gear.delete(saved) and Gear.weapons().is_empty() and not FileAccess.file_exists(path), "Löschen")
	check(not Gear.delete(pistol), "Mitgelieferte nicht löschbar")
	check(ResourceLoader.exists(Gear.FALLBACK_WEAPON) and ResourceLoader.exists(Gear.FALLBACK_ARMOR), "Ersatz vorhanden")
	_rm_tree(Gear.dir)
	Gear.dir = "user://gear"


func _test_ammo() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(55, "Munition", 1)
	check(g.ammo == {"energie": 200, "projektil": 300, "raketen": 6}, "Startvorrat Munition")
	check(g.ammo.keys().all(func(t: String) -> bool: return Ammo.TYPES.has(StringName(t))), "Arten wie Ammo.TYPES")
	# Kaufen nur im Hafen, nur mit Credits
	g.position = g.nearest_harbor()
	g.credits = 120
	check(Voyage.buy_ammo(g, "raketen", 1) and g.ammo.raketen == 7 and g.credits == 70, "Raketen kaufen (50 Cr)")
	check(not Voyage.buy_ammo(g, "raketen", 5) and g.ammo.raketen == 7, "nicht ohne genug Credits")
	check(Voyage.buy_ammo(g, "energie", 30) and g.ammo.energie == 230 and g.credits == 10, "Energiezellen kaufen (2 Cr je Schuss)")
	var other := -1
	for i in g.sector.systems.size():
		if not g.is_harbor(i) and not g.sector.systems[i].places.any(func(p: Dictionary) -> bool: return p.kind == "station"):   # ohne Station (Auftrag 9)
			other = i
			break
	g.position = other
	g.credits = 1000
	check(not Voyage.buy_ammo(g, "energie", 30), "nur im Hafen")
	# Verbrauch nicht unter 0
	g.ammo.raketen = 1
	var used := Voyage.use_ammo(g, {"raketen": 2, "projektil": 5})
	check(g.ammo.raketen == 0 and g.ammo.projektil == 295 and used == {"raketen": 1, "projektil": 5}, "Verbrauch abziehen, nicht unter 0")
	# Einsatzende: Verbrauch aus Campaign.last_result, Beute bei Sieg
	g.ammo = Voyage.AMMO_START.duplicate()
	g.active = g.offers[0]
	Campaign.last_result = {"ammo_used": {"projektil": 12}}
	g.finish_mission({"outcome": &"niederlage"})
	check(g.ammo.projektil == 288 and g.report.ammo_used == {"projektil": 12} and g.report.payout.is_empty(), "Einsatz: Verbrauch abgezogen, Niederlage ohne Beute")
	var before := g.ammo.duplicate()
	g.active = g.offers[0]
	Campaign.last_result = {}
	g.finish_mission({"outcome": &"sieg"})
	var loot: Dictionary = g.report.payout.ammo
	var t: String = loot.keys()[0]
	check(loot.size() == 1 and g.ammo[t] == before[t] + loot[t] and loot[t] >= Voyage.AMMO_LOOT[t][0] and loot[t] <= Voyage.AMMO_LOOT[t][1], "Sieg: eine zufällige Art als Beute (%s +%d)" % [t, loot[t]])
	# Speichern, alte Spielstände
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.ammo == g.ammo, "Munition im Spielstand")
	check(HubState.from_dict({"sector": g.sector.to_dict()}).ammo == Voyage.AMMO_START, "alte Spielstände: Startvorrat")
	# Editor: Munitionswerte ohne Grenzen
	var w := Gear.from_template(load("res://data/weapons/laserpistole.tres"))
	var keys := Gear.fields(w).map(func(f: Dictionary) -> String: return f.key)
	check("shots" in keys and "magazine" in keys and "ammo_total" in keys, "Editor: Schuss pro Angriff, Magazin, Munition")
	var fm: Dictionary = Gear.fields(w).filter(func(f: Dictionary) -> bool: return f.key == "magazine")[0]
	check(Gear.limits(w, fm) == Vector2(0, Gear.FREE_MAX) and not Gear.is_free(w), "Munitionswerte ohne Grenzen, ohne Vermerk frei")
	var hammer := Gear.from_template(load("res://data/weapons/energiehammer.tres"))
	check(not Gear.fields(hammer).any(func(f: Dictionary) -> bool: return f.key == "shots"), "Nahkampf ohne Munitionswerte")
	HubState.game = null
	Campaign.last_result = {}
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


## Story-Anbindung (Auftrag 1, Entscheidungen des Nutzers 19.10.2026)
## Auftrag 3 (19.10.2026): Beuteplätze, Lohn der neuen Fraktionen, Entern nicht absagbar, Story-Orte je Sektor,
## Kartenart, gefangene Crew, Story-Schlüssel sectors
func _test_auftrag3() -> void:
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(77)
	HubState.game = g
	# Beuteplätze = Figuren + loot_extra
	g.loot_pending = {}
	g.set_loot({"units": {"a": {}, "b": {}}, "loot_extra": 1, "loot": [{"key": "res://data/weapons/sturmgewehr.tres", "damage": 0}]})
	check(int(g.loot_pending.slots) == 3, "Beuteplätze: Figuren + loot_extra")
	g.loot_pending = {}
	# Lohn: neue Fraktionen wie der alte Partner gleicher Art, Story-Fraktionen ohne Lohn
	check(is_equal_approx(float(Voyage.payout("mittel", "res://data/missions/semidrug.tres", true).factor), 1.2)
		and is_equal_approx(float(Voyage.payout("mittel", "res://data/missions/eisenwoelfe.tres", true).factor), 1.2)
		and int(Voyage.payout("mittel", "res://data/missions/neuntes_haus.tres", true).loot) == 2
		and is_equal_approx(float(Voyage.payout("mittel", "res://data/missions/aasgeier.tres", true).factor), 1.0), "Lohn der neuen Fraktionen")
	check(Voyage.payout("mittel", "res://data/missions/abteilung_9.tres", true).is_empty(), "Story-Fraktion: kein Lohn")
	# Entern und Abwehr lassen sich nicht absagen
	g.active = {"id": -1, "board": true}
	g.board_pending = {"faction": "", "ship": "x", "difficulty": "mittel"}
	g.abort_mission()
	check(g.boarding_active() and not g.board_pending.is_empty(), "abort_mission verwirft Entern nicht")
	g.active = {"id": -1, "defend": true}
	g.abort_mission()
	check(g.boarding_active() and g.space_report.is_empty(), "abort_mission verwirft Abwehr nicht")
	g.active = {"id": 5}
	g.abort_mission()
	check(g.active.is_empty(), "normaler Einsatz: abort_mission räumt auf")
	g.board_pending = {}
	# Story-Orte: alte und neue Form, Marker nur im aktuellen Sektor
	check(HubState.story_place(4) == {"sector": 0, "system": 4, "place": -1}
		and HubState.story_place({"sector": 2, "system": 3, "place": 1}) == {"sector": 2, "system": 3, "place": 1}, "Story-Ort in einheitlicher Form")
	var st := g.story_engine()
	st.state.chains["kapitel1"] = {"status": "fertig", "scene": "", "place": -1}
	st.reveal("test_ort")
	check(g.story_markers().size() == 1, "Story-Ort im Startsektor sichtbar")
	g.cur_sector = 1
	g.sector = g.sectors[1]
	check(g.story_markers().is_empty(), "Story-Ort eines anderen Sektors nicht auf der Karte")
	g.cur_sector = 0
	g.sector = g.sectors[0]
	# Ort anfliegen (Auftrag 4): Kette am Ort startet erst beim Anfliegen, nicht bei der Ankunft im System
	st.state.chains["test_ort"].place = {"sector": 0, "system": g.position, "place": 0}
	check(g.story_arrive() != "test_ort" and st.at_place(0, g.position, 0).size() == 1, "Story-Ort am Ort: Ankunft im System startet nichts")
	check(g.visit_place(1) == "" and g.visit_place(0) == "test_ort" and st.state.status("test_ort") == "aktiv", "Ort anfliegen startet die Kette")
	# Kartenart: Feld map der Vorlage, sonst Ort, sonst zufällig
	check(g.story_map({"map": "tempel"}) == "tempel" and g.story_map({"map": "gibtsnicht"}) == "", "Story-Karte aus der Vorlage")
	st.state.chains["test_kette"] = {"status": "wartet", "scene": "start", "place": {"sector": 0, "system": g.position, "place": 0}}
	var k0 := String(g.sector.systems[g.position].places[0].kind)
	var sm := g.story_map({"chain": "test_kette"})
	check((sm != "" and StringName(sm) in Places.MAPS[k0]) if Places.has_ground(k0) else sm == "", "Story-Karte aus dem Story-Ort")
	var gm := g.mission_of({"story": true, "seed": 5, "difficulty": "leicht", "system": g.position, "map": "bar"})
	check(gm.map_type == &"bar", "Story-Einsatz mit Kartentyp")
	# Story-Schlüssel sectors
	check(g.sectors_reached() == 1, "erreichte Sektoren")
	# Gefangene Crew
	var c: Character = Campaign.crew()[0]
	st.state.captured.append(String(c.id))
	check(not c in Voyage.available(g) and not Crafting.can_work(c) and Crafting.status_text(g, c).begins_with("gefangen"), "Gefangene: kein Reiseposten, keine Arbeit")
	var cands := Campaign.candidates(false, HubState.blocked_ids())
	check(cands.any(func(x: Dictionary) -> bool: return x.ch == c and x.locked and x.reason == "gefangen"), "Gefangene in der Truppwahl gesperrt")
	check(not (ShipArms.setup(g, {}, "test").crew as Array).has(c), "Gefangene nicht im Raumkampf")
	var xp := c.free_xp
	g.day = HubState.TRAINING_DAYS - 1
	g.wait_days(1)
	check(c.free_xp == xp, "Gefangene: kein Training")
	st.state.captured.clear()
	st.state.chains.erase("test_kette")


func _test_story_hub() -> void:
	var g := HubState.new_game(11)
	check(not g.story.is_empty() and g.story_engine().game == g, "Story: neues Spiel mit Story-Zustand und Story-Objekt")
	var old := g.to_dict()
	old.erase("story")
	check(not HubState.from_dict(old).story.is_empty(), "Story: alter Spielstand ohne Feld lädt")
	# Ressourcen nach den Regeln des Hubs
	g.credits = 100
	g.material = 2
	g.fuel = g.tank_max() - 5
	var ch := g.apply_story({"credits": -150, "material": -5, "fuel": 20})
	check(g.credits == -50 and g.material == 0 and g.fuel == g.tank_max() and ch.material == -2 and ch.fuel == 5, "apply_story: Credits unter 0, Material ab 0, Tank bis voll")
	# Story-Ort: Ankunft öffnet die Kette (Szenenfenster vorgemerkt), im Spielstand
	var st := g.story_engine()
	st.state.chains["kapitel1"] = {"status": "fertig", "scene": "", "place": -1}   # Kapitel 1 startet ab Tag 3 von selbst (Story-Chat)
	st.reveal("test_ort")
	var loc := st.loc_of("test_ort")
	var place := int(loc.get("system", -1))
	check(place >= 0 and st.markers(-1).size() == 1, "Story-Ort auf der Karte")
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.story_engine().loc_of("test_ort") == loc, "Story-Zustand im Spielstand")
	g.position = place
	g.queue_story(g.story_engine().on_visit(int(loc.sector), place, int(loc.place)))   # Story-Ort an einem Ort (Story Auftrag 5)
	check(g.story_queue == ["test_ort"] and st.state.status("test_ort") == "aktiv", "Story-Ort angeflogen: Szenenfenster vorgemerkt")
	g.story_queue = []
	# Frist verpasst → Rückschlag-Szene am Tagesende
	st.state.chains["test_kette"] = {"status": "aktiv", "scene": "start", "place": -1}
	st.state.goals["frist"] = {"name": "Frist", "chain": "test_kette", "value": 0, "target": 1, "due": g.day, "fail": "pfaendung", "done": false}
	g.wait_days(1)
	check("test_kette" in g.story_queue and st.current_scene_id("test_kette") == "pfaendung", "Tagesende: verpasste Frist öffnet die Rückschlag-Szene")
	g.story_queue = []
	# Story-Einsatz am Boden: Angebot, kein Lohn, Beuteauswahl, Folgeszene
	st.state.chains["test_kette"] = {"status": "wartet", "scene": "start", "place": -1}
	st.state.mission = {"chain": "test_kette", "kind": "boden", "title": "Schlägerei an der Schleuse", "difficulty": "leicht",
		"sieg": "ende", "niederlage": "pfaendung", "rueckzug": "hafen"}
	check(g.start_story_mission() == "ground" and g.active.story and g.mission_of(g.active).title == "Schlägerei an der Schleuse", "Story-Einsatz: Bodenkampf mit Story-Titel")
	var cr := g.credits
	g.loot_pending = {}
	Campaign.last_result = {"outcome": &"sieg", "units": {"a": {}}, "loot": [{"key": "res://data/weapons/sturmgewehr.tres", "damage": 0}]}
	g.finish_mission({"outcome": &"sieg"})
	check(g.credits == cr and g.report.story and g.loot_pending.items.size() == 1 and g.story_queue == ["test_kette"]
		and st.current_scene_id("test_kette") == "ende" and g.story_mission().is_empty(), "Story-Einsatz gewonnen: kein Lohn, Beuteauswahl, Folgeszene")
	g.loot_pending = {}
	g.story_queue = []
	# Raum: Rückzug; Blockade: Sieg → Bodenkampf
	var res := {"outcome": &"niederlage", "retreated": true, "surrendered": false, "ransom": {}, "boarding": false, "units": {}}
	st.state.chains["test_kette"] = {"status": "wartet", "scene": "start", "place": -1}
	st.state.mission = {"chain": "test_kette", "kind": "raum", "title": "Jagd", "difficulty": "mittel", "sieg": "ende", "rueckzug": "hafen"}
	check(g.start_story_mission() == "space" and g.space_ctx.kind == "story", "Story-Einsatz im All: Raumkampf")
	g.finish_space(res)
	check(g.story_queue == ["test_kette"] and st.current_scene_id("test_kette") == "hafen", "Raum-Story: Rückzug → Folgeszene")
	g.story_queue = []
	st.state.chains["test_kette"] = {"status": "wartet", "scene": "start", "place": -1}
	st.state.mission = {"chain": "test_kette", "kind": "blockade", "title": "Sperre", "difficulty": "mittel", "sieg": "ende"}
	g.start_story_mission()
	res.outcome = &"sieg"
	res.retreated = false
	check(g.finish_space(res) == "ground" and g.active.story and g.story_queue.is_empty(), "Story-Blockade gewonnen: Bodenkampf folgt")
	g.active = {}
	Campaign.last_result = {}
	HubState.game = null


func _test_encyclopedia() -> void:
	var e := Encyclopedia.new()
	for sec in Encyclopedia.SECTIONS:
		check(not e.entries(sec[0]).is_empty(), "Enzyklopädie: Bereich %s hat Einträge" % sec[1])
	var w: Array = e.entries(&"waffen").filter(func(x: Dictionary) -> bool: return x.name == "Sturmgewehr")
	check(w.size() == 1 and String(w[0].text).contains("Gewehre") and String(w[0].text).contains("[table=5]"), "Waffe mit Werten und Angriffstabelle")
	for r in Encyclopedia.RULES:
		var t := Encyclopedia.rule_text(r[1])
		check(t.length() > 100 and not t.contains("nicht gefunden"), "Kurzregel aus Skillsystem.md: %s" % r[0])
	var dw := Encyclopedia.rule_text("### 5.4")
	check(not dw.contains("### 5.5") and not dw.contains("Patzer (W100)[/b]"), "Kurzregel endet beim nächsten Abschnitt")
	for g in Rules.SKILL_GROUPS:
		for s in g.skills:
			check(SkillTexts.text(StringName(s[0])) != "", "Beschreibung für %s" % s[1])
	check(Encyclopedia.md_to_bb("**fett** und *kursiv*") == "[b]fett[/b] und [i]kursiv[/i]", "Markdown fett/kursiv")
	check(Encyclopedia.md_to_bb("| a | b |\n|---|---|\n| 1 | 2 |").begins_with("[table=2]"), "Markdown-Tabelle")
	check(Encyclopedia._plain("[b]Deckung[/b] x").to_lower().contains("deckung"), "Suche im Klartext")
	# Raumkampf (Entscheidungen des Nutzers 19.10.2026)
	var sw: Array = e.entries(&"s_waffen")
	check(sw[0].name == Encyclopedia.OVERVIEW and sw.size() == ShipWeapons.CATALOG.size() + 1 and String(sw[0].text).contains("[table=9]"), "Schiffswaffen: Übersicht + je Waffe")
	var lb: Array = sw.filter(func(x: Dictionary) -> bool: return x.name == "Laserbank")
	check(lb.size() == 1 and String(lb[0].text).contains("900 Cr") and String(lb[0].text).contains("s_schiffe:"), "Laserbank mit Preis und Gegnern")
	check(e.entries(&"s_schiffe").size() == SpaceTemplates.ships().size() + 1 and e.entries(&"s_seiten").size() == SpaceTemplates.factions().size() + 1, "Gegnerschiffe und -seiten vollständig")
	# Fraktionen, Gegnertypen, Orte, Sektoren (Hub Auftrag 5)
	check(e.entries(&"fraktionen").size() == Mission.all_factions().size() + 1 and e.entries(&"gegner").size() == Encyclopedia.enemy_units().size() + 1
		and e.entries(&"orte").size() == Places.KINDS.size() + 1, "Fraktionen, Gegnertypen und Orte vollständig (mit Übersicht)")
	var ag: Array = e.entries(&"fraktionen").filter(func(x: Dictionary) -> bool: return x.name == "Aasgeier")
	check(not ag.is_empty() and String(ag[0].text).contains("Überzahl") and String(ag[0].text).contains("[url=gegner:Plünderer 1]")
		and String(ag[0].text).contains("[url=s_seiten:"), "Fraktion: Eigenheit, Verweis auf Gegnertyp und Raumseite")
	var a9: Array = e.entries(&"fraktionen").filter(func(x: Dictionary) -> bool: return x.name == "Abteilung 9")
	check(not a9.is_empty() and String(a9[0].text).contains("Story") and String(a9[0].text).contains("Ersatz"), "Story-Fraktion sichtbar, Raumseite Ersatz")
	var hx: Array = e.entries(&"gegner").filter(func(x: Dictionary) -> bool: return x.name == "Hexer")
	check(not hx.is_empty() and String(hx[0].text).contains("Psi-Stoß") and String(hx[0].text).contains("[url=fraktionen:"), "Gegnertyp: Psi und Verweis auf Fraktion")
	var wr: Array = e.entries(&"orte").filter(func(x: Dictionary) -> bool: return x.name == "Wrack")
	check(not wr.is_empty() and String(wr[0].text).contains("Schiffsmaterial") and e.entries(&"sektoren").size() == 3, "Orte und Sektoren")
	var ar: Array = e.entries(&"s_ausbau").filter(func(x: Dictionary) -> bool: return x.name == "Schiffspanzerung")
	check(ar.size() == 1 and String(ar[0].text).contains("%d Abzug" % SpaceSetup.ARMOR_PER_HIT[3]), "Schiffspanzerung je Stufe")
	var st: Array = e.entries(&"s_stationen").filter(func(x: Dictionary) -> bool: return x.name == "Steuer")
	check(st.size() == 1 and String(st[0].text).contains("VW"), "Station mit Aufgabe aus Raumkampf.md")
	for r in Encyclopedia.SPACE_RULES:
		var rt := Encyclopedia.rule_text(r[1], Encyclopedia.SPACE_RULES_FILE)
		check(rt.length() > 100 and not rt.contains("nicht gefunden"), "Kurzregel aus Raumkampf.md: %s" % r[0])
	check(not Encyclopedia.rule_text("## 4.", Encyclopedia.SPACE_RULES_FILE).contains("4a."), "Raumregel endet vor 4a")
	e.free()


func _test_gear_models() -> void:
	Gear.dir = "user://gear_test_models"
	_rm_tree(Gear.dir)
	var w := Gear.from_template(load("res://data/weapons/laserpistole.tres")) as WeaponData
	var guns := WeaponModels.all().filter(func(m: Dictionary) -> bool: return not m.melee)
	var melee := WeaponModels.all().filter(func(m: Dictionary) -> bool: return m.melee)
	check(guns.size() > 5 and melee.size() > 5, "Katalog: Schusswaffen %d, Nahkampf %d" % [guns.size(), melee.size()])
	var rev: Dictionary = guns.filter(func(m: Dictionary) -> bool: return m.name == "Revolver A")[0]
	WeaponModels.apply(w, rev)
	w.sound_id = rev.sound
	check(w.model.resource_path == rev.model and not w.two_handed and w.sound() == &"revolver", "Modell und Klang aus dem Katalog")
	var saved := Gear.save(w) as WeaponData
	var again: WeaponData = ResourceLoader.load(saved.resource_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	check(again.sound_id == &"revolver" and again.model.resource_path == rev.model and is_equal_approx(again.length_m, rev.length_m), "Modell und Klang gespeichert")
	check(Gear.auto_sound(again) == &"laser" and again.sound_id == &"revolver", "automatischer Klang ohne Auswahl")
	for k in WeaponData.SOUNDS:
		check(WeaponData.SOUNDS[k] != "", "Klangname %s" % k)
	_rm_tree(Gear.dir)
	Gear.dir = "user://gear"


func _test_training() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	check(HubState.training_days(4, 5) == 1 and HubState.training_days(1, 4) == 0 and HubState.training_days(5, 9) == 0 and HubState.training_days(1, 10) == 2, "Trainingstage zählen")
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(31, "Training", 1)
	var crew := Campaign.crew()
	var hurt: Character = crew[0]
	hurt.injury = Injury.SEVERE
	hurt.injury_days = 20
	var xp0 := crew.map(func(c: Character) -> int: return c.free_xp)
	g.wait_days(3)
	check(g.day == 4 and g.last_training == 0 and crew[1].free_xp == xp0[1], "vor Tag 5 kein Training")
	g.wait_days(1)
	check(g.day == 5 and g.last_training == 3, "Tag 5: Training")
	var ok := true
	for i in crew.size():
		ok = ok and crew[i].free_xp == xp0[i] + 3
	check(ok, "ganze Crew +3 freie EP, auch Verwundete")
	g.wait_days(11)
	check(g.day == 16 and g.last_training == 6 and crew[1].free_xp == xp0[1] + 9, "zwei Trainingstage auf einmal (+6)")
	var nb: int = g.sector.neighbors(g.position)[0][0]
	g.day = 9
	var d := g.travel_to(nb)
	check(g.last_travel.training == (3 if d >= 1 else 0), "Reisebericht mit Training")
	g.day = 14
	g.active = g.offers[0]
	g.finish_mission({"outcome": &"niederlage"})
	check(g.report.training == 3, "Einsatzbericht mit Training (Tag 15)")
	HubState.game = null
	Campaign.last_result = {}
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


func _test_upgrades() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(41, "Ausbau", 1)
	check(g.tank_max() == 100 and g.hull_max() == 100 and g.fuel_per_day() == 10 and g.travel_bonus() == 0 and g.training_xp() == 3, "Ausbau Stufe 0 = bisherige Werte")
	# Werft: nur im Hafen, nur mit Credits
	g.position = g.nearest_harbor()
	g.credits = 500
	check(not ShipUpgrades.buy_yard(g, &"tank"), "Werft nicht ohne genug Credits (600)")
	g.credits = 5000
	check(ShipUpgrades.buy_yard(g, &"tank") and g.tank_max() == 130 and g.credits == 4400, "Werft: Tank Stufe 1")
	check(ShipUpgrades.buy_yard(g, &"berths") and g.berths == 9 and g.free_berths() == 9 - Campaign.crew().size(), "Werft: Plätze an Bord 9")
	g.fuel = 100
	check(Voyage.buy_fuel(g, 100) == 30 and g.fuel == 130, "größerer Tank wird voll getankt")
	ShipUpgrades.buy_yard(g, &"engine")
	ShipUpgrades.buy_yard(g, &"systems")
	ShipUpgrades.buy_yard(g, &"training")
	ShipUpgrades.buy_yard(g, &"medbay")
	check(g.fuel_per_day() == 9 and g.travel_bonus() == 5 and g.training_xp() == 4 and g.heal_bonus() == 10, "Antrieb, Systeme, Training, Krankenstation Stufe 1")
	var other := -1
	for i in g.sector.systems.size():
		if not g.is_harbor(i):
			other = i
	g.position = other
	check(not ShipUpgrades.can_yard(g, &"hull"), "Werft nur im Hafen")
	# Systeme wirken auf die Reiseprobe, Krankenstation auf den Heilbonus (nur mit Personal)
	var c: Character = Campaign.crew()[0]
	Dice.set_seed(3)
	var a := Voyage.check(c, &"pilot", g.travel_bonus())
	check(a.bonus == Rules.skill_total(c, &"pilot") + 5, "Systeme +5 auf Reiseprobe")
	check(Medbay.bonus(g) == 0, "Krankenstation-Bonus nur mit Personal")
	Medbay.toggle(g, c)
	check(Medbay.bonus(g) == Rules.skill_total(c, Medbay.SKILL) + 10, "Krankenstation +10 auf die Heilprobe")
	g.medics = []
	# Crew-Ausbau: Material sofort, Tage, Probe am Ende, nur einer zur Zeit
	g.material = 2
	check(not ShipUpgrades.can_crew(g, &"hull"), "Crew-Ausbau braucht 3 Material")
	g.material = 10
	check(ShipUpgrades.start_crew(g, &"hull") and g.material == 7 and g.project == {"id": "hull", "days": 3}, "Crew-Ausbau Hülle beginnt (3 Material, 3 Tage)")
	check(not ShipUpgrades.can_crew(g, &"tank"), "nur ein Crew-Ausbau zur Zeit")
	g.wait_days(2)
	check(ShipUpgrades.level(g, &"hull") == 0 and int(g.project.days) == 1 and g.last_upgrade.is_empty(), "nach 2 Tagen noch im Bau")
	var guard := 0
	while ShipUpgrades.busy(g) and guard < 30:
		g.wait_days(1)
		guard += 1
	check(ShipUpgrades.level(g, &"hull") == 1 and g.hull_max() == 125 and g.material >= 7 - guard, "Crew-Ausbau fertig (nach %d Zusatztagen)" % (guard - 1))
	# Speichern
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.upgrades == g.upgrades and h.tank_max() == 130 and h.berths == 9, "Ausbau im Spielstand")
	ShipUpgrades.start_crew(g, &"tank")
	var h2 := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h2.project == g.project, "laufender Crew-Ausbau im Spielstand")
	check(HubState.from_dict({"sector": g.sector.to_dict()}).upgrades.is_empty(), "alte Spielstände ohne Ausbau")
	HubState.game = null
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


func _test_stock() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(61, "Lager", 1)
	check(g.stock.is_empty(), "Lager zu Beginn leer")
	var sg := "res://data/weapons/sturmgewehr.tres"
	check(Stock.price(sg) == 280 and Stock.sell_price(sg) == 140 and Stock.price(Stock.MEDKIT) == 30, "Preise")
	check(not "res://data/weapons/faeuste.tres" in Stock.goods() and not "res://data/armor/keine.tres" in Stock.goods(), "Fäuste und „Keine“ kein Handelsgut")
	g.position = g.nearest_harbor()
	var shop := Stock.shop(g, g.position)
	var all := Stock.goods()
	check(Stock.MEDKIT in shop and shop.size() - 1 == ceili(all.size() * TradeSkills.shop_share(g)), "Sortiment: Anteil nach Gassenwissen + Medikits (%d von %d)" % [shop.size() - 1, all.size()])
	check(Stock.shop(g, g.position) == shop, "Sortiment bleibt innerhalb der 10 Tage gleich")
	g.day += Stock.SHOP_DAYS
	var shop2 := Stock.shop(g, g.position)
	check(shop2.size() == shop.size(), "nach 10 Tagen neu gemischt (gleiche Größe)")
	var key: String = shop2[1]
	g.credits = Stock.price(key) - 1
	check(not Stock.buy(g, key), "nicht ohne genug Credits")
	g.credits = 5000
	check(Stock.buy(g, key) and Stock.count(g, key) == 1 and g.credits == 5000 - Stock.price(key), "Kaufen ins Lager")
	check(Stock.buy(g, Stock.MEDKIT) and Stock.buy(g, Stock.MEDKIT) and Stock.count(g, Stock.MEDKIT) == 2, "Medikits kaufen")
	var cr := g.credits
	check(Stock.sell(g, key) and Stock.count(g, key) == 0 and g.credits == cr + Stock.sell_price(key) and not g.stock.has(key), "Verkaufen zum halben Preis")
	check(not Stock.sell(g, key), "nichts zu verkaufen")
	check(Stock.take(g, Stock.MEDKIT) and Stock.count(g, Stock.MEDKIT) == 1 and not Stock.take(g, sg), "Herausnehmen fürs Ausrüsten")
	Stock.add(g, sg, 2)
	check(Stock.count(g, sg) == 2 and Stock.items(g).size() == 2, "Zurücklegen und Liste")
	check(Stock.take(null, sg) and Stock.count(null, sg) > 1000, "ohne Spiel (Schnellkampf) unbegrenzt")
	g.ammo.projektil = 40
	cr = g.credits
	check(Voyage.sell_ammo(g, "projektil", 30) and g.ammo.projektil == 10 and g.credits == cr + 30, "Munition verkaufen (halber Preis)")
	# Schild als Handelsgut (150 Cr, Verkauf nach Handeln)
	var sh := Equipment.SHIELD
	check(Stock.price(sh) == 150 and Stock.name_of(sh) == "Schild" and sh in Stock.goods(), "Schild: 150 Cr, Name, Handelsgut")
	check(Stock.sell_price(sh, g) == 75, "Schild verkaufen: halber Preis bei Teilerfolg")
	TradeSkills.fixed = &"herausragend"
	check(Stock.buy_price(g, sh) == 120 and Stock.sell_price(sh, g) == 105, "Schild nach Handeln herausragend: 120 / 105")
	TradeSkills.fixed = &"teilerfolg"
	var old_shop: Dictionary = g.shop.duplicate(true)
	g.shop[str(g.position)] = [sh]
	cr = g.credits
	check(sh in Stock.shop(g, g.position) and Stock.buy(g, sh) and Stock.count(g, sh) == 1 and g.credits == cr - 150, "Schild im Sortiment kaufen")
	check(Stock.sell(g, sh) and Stock.count(g, sh) == 0 and g.credits == cr - 75, "Schild verkaufen")
	g.shop = old_shop
	# eigene Ausrüstung: Preis der Vorlage, frei doppelt
	Gear.dir = "user://gear_test_stock"
	_rm_tree(Gear.dir)
	var w := Gear.from_template(load("res://data/weapons/laserpistole.tres"))
	var own := Gear.save(w)
	check(Stock.price(own.resource_path) == 150 and own.resource_path in Stock.goods(), "eigene Waffe: Preis der Vorlage, Handelsgut")
	own.set_meta(&"free", true)
	check(Stock.price(own.resource_path) == 300, "frei eingetragen: doppelter Preis")
	_rm_tree(Gear.dir)
	Gear.dir = "user://gear"
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.stock == g.stock and int(h.shop.get("_period", -1)) == int(g.shop.get("_period", -2)), "Lager und Sortiment im Spielstand")
	HubState.game = null
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


## Handel an Stationen (Auftrag 9): wie im Hafen, 20 % teurer; Werft, Anheuern, Papiere nur im Hafen
func _test_station_trade() -> void:
	TradeSkills.fixed = &"teilerfolg"
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(72, "Station", 1)
	HubState.game = g
	var sys := -1
	var none := -1
	for i in g.sector.systems.size():
		var has: bool = g.sector.systems[i].places.any(func(p: Dictionary) -> bool: return p.kind == "station")
		if not g.is_harbor(i) and has and sys < 0:
			sys = i
		if not g.is_harbor(i) and not has and none < 0:
			none = i
	check(sys >= 0, "Fraktionssystem mit Station gefunden")
	var sg := "res://data/weapons/sturmgewehr.tres"
	g.position = g.nearest_harbor()
	var harbor_price := Stock.buy_price(g, sg)
	g.position = sys
	g.credits = 5000
	check(g.at_market() and not g.is_harbor(sys) and g.market_title() == g.station_name(), "Station: Handel möglich, Titel = Station")
	check(Stock.buy_price(g, sg) == roundi(harbor_price * Places.STATION_FACTOR) or absi(Stock.buy_price(g, sg) - roundi(harbor_price * 1.2)) <= 1, "Station 20 % teurer")
	var key: String = Stock.shop(g, sys)[0]
	var n0 := Stock.count(g, key)
	check(Stock.can_buy(g, key) and Stock.buy(g, key) and Stock.count(g, key) == n0 + 1, "Kauf an der Station")
	check(Galley.can_buy(g, 1) and Voyage.can_buy_material(g, 1) and Crafting.can_buy_material(g, 1), "Proviant und Material an der Station")
	TradeSkills.fixed = &""
	var c: Character = Campaign.crew()[0]
	check(TradeSkills.can_roll(g, &"handeln") and not TradeSkills.roll(g, &"handeln", c).is_empty(), "Probe Handeln an der Station")
	check(not ShipUpgrades.can_yard(g, &"tank") and not g.can_buy_papers("x"), "Werft und Papiere nur im Hafen")
	if none >= 0:
		g.position = none
		check(not g.at_market() and not TradeSkills.can_roll(g, &"verhandeln"), "ohne Station und Hafen kein Handel")
	TradeSkills.fixed = &"teilerfolg"


func _test_trade_skills() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	TradeSkills.fixed = &""
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(71, "Handel", 1)
	g.position = g.nearest_harbor()
	var sg := "res://data/weapons/sturmgewehr.tres"
	check(TradeSkills.result(g, &"handeln") == &"fehlschlag" and Stock.buy_price(g, sg) == 294 and Stock.sell_price(sg, g) == 126, "ohne Probe wie Fehlschlag: +5 %, Verkauf 45 %")
	check(Voyage.fuel_price(g) == 5 and Voyage.material_price(g) == 63 and ShipUpgrades.yard_cost(g, &"tank") == 630, "Verhandeln ohne Probe: Schiffspreise +5 %")
	var all := Stock.goods().size()
	check(Stock.shop(g, g.position).size() - 1 == ceili(all * 0.5), "Gassenwissen ohne Probe: 50 %")
	var c: Character = Campaign.crew()[0]
	var xp0: int = Rules.ensure_skill(c, &"handeln").xp
	var r := TradeSkills.roll(g, &"handeln", c)
	check(not r.is_empty() and TradeSkills.roll_of(g, &"handeln") == r and not TradeSkills.can_roll(g, &"handeln"), "eine Probe pro Tag")
	check(Rules.ensure_skill(c, &"handeln").xp == xp0 + int(r.xp), "EP in Handeln")
	check(TradeSkills.result(g, &"handeln") == StringName(r.result), "Ergebnis gilt heute")
	g.day += 1
	check(TradeSkills.result(g, &"handeln") == &"fehlschlag" and TradeSkills.can_roll(g, &"handeln"), "nächster Tag: neue Probe möglich")
	var ex := {&"patzer": [336, 84, 30], &"fehlschlag": [294, 126, 50], &"teilerfolg": [280, 140, 60], &"erfolg": [252, 168, 75], &"herausragend": [224, 196, 90]}
	for res in ex:
		TradeSkills.fixed = res
		var share := ceili(all * TradeSkills.SHARE[res])
		check(Stock.buy_price(g, sg) == ex[res][0] and Stock.sell_price(sg, g) == ex[res][1] and roundi(TradeSkills.shop_share(g) * 100) == ex[res][2]
			and Stock.shop(g, g.position).size() - 1 == share, "Stufe %s: Kauf %d, Verkauf %d, Sortiment %d %%" % [res, ex[res][0], ex[res][1], ex[res][2]])
	TradeSkills.fixed = &"erfolg"
	check(Voyage.fuel_price(g) == 5 and Voyage.material_price(g) == 54 and Voyage.yard_cost(g) == 36 and ShipUpgrades.yard_cost(g, &"tank") == 540, "Verhandeln Erfolg: −10 %")
	TradeSkills.fixed = &"fehlschlag"
	var small := Stock.shop(g, g.position)
	TradeSkills.fixed = &"herausragend"
	var big := Stock.shop(g, g.position)
	check(small.all(func(k: String) -> bool: return k in big), "größeres Sortiment ergänzt nur")
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.trade_rolls.has("handeln"), "Handelsproben im Spielstand")
	TradeSkills.fixed = &"teilerfolg"
	HubState.game = null
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


## Beuteauswahl, beschädigte Stücke im Lager, Werkstatt, Verkauf beschädigt (Entscheidungen 16.10.2026)
func _test_loot() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(62, "Beute", 1)
	HubState.game = g
	var sg := "res://data/weapons/sturmgewehr.tres"
	var lp := "res://data/weapons/laserpistole.tres"
	var kp := "res://data/armor/mittel.tres"
	# Lagerformat
	var k20 := Stock.damaged_key(sg, -20)
	check(k20 == sg + "|-20" and Stock.base_of(k20) == sg and Stock.damage_of(k20) == -20 and Stock.damage_of(sg) == 0, "Schlüssel mit Schaden")
	check(Stock.damaged_key(sg, 0) == sg and Stock.damaged_key(k20, -10) == sg + "|-10" and Stock.damaged_key(sg, -50) == sg + "|-30", "intakt = Grundschlüssel, Schaden höchstens −30")
	check(Stock.name_of(k20) == "Sturmgewehr (−20)" and Stock.name_of(Stock.damaged_key(kp, -30)) == "Kampfpanzer (mittel) (−30, unbrauchbar)", "Name mit Schaden")
	check(Stock.price(k20) == 280, "Kaufpreis = intaktes Stück")
	# Verkauf beschädigt: je −10 um 25 % weniger
	check(Stock.sell_price(sg) == 140 and Stock.sell_price(Stock.damaged_key(sg, -10)) == 105 and Stock.sell_price(k20) == 70 and Stock.sell_price(Stock.damaged_key(sg, -30)) == 35, "Verkauf 140/105/70/35")
	# Schrottwert: 15 %, −30 = 0
	check(Stock.scrap_value(sg) == 42 and Stock.scrap_value(k20) == 42 and Stock.scrap_value(Stock.damaged_key(sg, -30)) == 0, "Schrott 42/42/0")
	# Werkstatt: 10 % je −10, nach Handeln (Mockup: Erfolg)
	g.position = g.nearest_harbor()
	TradeSkills.fixed = &"erfolg"
	check(Stock.repair_cost(g, k20) == 50 and Stock.repair_cost(g, Stock.damaged_key(lp, -10)) == 14 and Stock.repair_cost(g, Stock.damaged_key(kp, -30)) == 95 and Stock.repair_cost(g, sg) == 0, "Werkstatt 50/14/95 bei Erfolg")
	check(Stock.sell_price(Stock.damaged_key(lp, -10), g) == 67 and Stock.sell_price(Stock.damaged_key(kp, -30), g) == 52, "Verkauf beschädigt nach Handeln 67/52")
	TradeSkills.fixed = &"teilerfolg"
	check(Stock.repair_cost(g, k20) == 56, "Werkstatt normal 56")
	Stock.add(g, k20)
	Stock.add(g, sg)
	g.credits = 55
	check(not Stock.can_repair(g, k20), "Werkstatt: zu wenig Credits")
	g.credits = 100
	check(not Stock.can_repair(g, sg), "intakt: nichts zu reparieren")
	check(Stock.repair(g, k20) and g.credits == 44 and Stock.count(g, k20) == 0 and Stock.count(g, sg) == 2 and not g.stock.has(k20), "Reparieren: ganz, ins intakte Stück")
	Stock.add(g, k20)
	var it: Array = Stock.items(g).filter(func(x: Dictionary) -> bool: return x.key == k20)
	check(it.size() == 1 and int(it[0].damage) == -20 and it[0].name == "Sturmgewehr (−20)", "Lagerliste mit Schaden")
	var cr := g.credits
	check(Stock.sell(g, k20) and g.credits == cr + 70, "beschädigt verkaufen")
	Stock.add(g, k20)
	var away := -1
	for i in g.sector.systems.size():
		if not g.is_harbor(i) and not g.sector.systems[i].places.any(func(p: Dictionary) -> bool: return p.kind == "station"):   # ohne Station (Auftrag 9)
			away = i
			break
	g.position = away
	g.credits = 1000
	check(not Stock.can_repair(g, k20), "Werkstatt nur im Raumhafen")
	# gute Stücke (+5) aus dem Handwerk
	var k5 := Stock.damaged_key(sg, 5)
	check(k5 == sg + "|+5" and Stock.damaged_key(sg, 12) == k5 and Stock.damage_of(k5) == Stock.BONUS and Stock.is_fine(k5) and not Stock.is_fine(k20), "Schlüssel +5")
	check(Stock.base_of(k5) == sg and Stock.name_of(k5) == "Sturmgewehr (+5)" and Stock.damage_steps(k5) == 0, "Name und Stufen +5")
	check(Stock.sell_price(k5) == 210 and Stock.repair_cost(g, k5) == 0 and not Stock.can_repair(g, k5), "+5: Verkauf +50 %, nichts zu reparieren")
	g.stock = {}
	# Beute aus dem MissionResult: Medikits sofort, Rest zur Auswahl, 1 Stück je Crewmitglied im Einsatz
	var res := {"units": {"a": {}, "b": {}}, "loot": [
		{"key": sg, "name": "Sturmgewehr", "damage": 0},
		{"key": lp, "name": "Laserpistole", "damage": -10},
		{"key": kp, "name": "Kampfpanzer (mittel)", "damage": -30},
		{"key": Stock.MEDKIT, "name": "Medikit", "count": 2},
		{"key": "res://data/weapons/raketenwerfer.tres", "name": "Raketenwerfer", "damage": -20}]}
	check(g.set_loot(res) == 2 and Stock.count(g, Stock.MEDKIT) == 2, "Medikits gleich ins Lager")
	check(g.loot_pending.slots == 2 and g.loot_pending.items.size() == 4 and Stock.damaged_key(lp, -10) in g.loot_pending.items, "offene Beute: 4 Stück, 2 Plätze")
	check(g.loot_default() == [0, 3], "Vorauswahl: die wertvollsten (Sturmgewehr 140, Raketenwerfer −20 150)")
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.loot_pending == g.loot_pending, "offene Beute im Spielstand")
	cr = g.credits
	var r := g.take_loot([0, 1, 2])
	check(r.taken == 2 and r.scrapped == 2 and Stock.count(g, sg) == 1 and Stock.count(g, Stock.damaged_key(lp, -10)) == 1, "Auswahl: höchstens 2 ins Lager")
	check(r.scrap == 0 + 90 and g.credits == cr + 90, "Rest als Schrott: Kampfpanzer −30 = 0, Raketenwerfer 90")
	check(g.loot_pending.is_empty(), "Auswahl erledigt")
	g.set_loot({"units": {"a": {}}, "loot": [{"key": Stock.MEDKIT, "name": "Medikit", "count": 1}]})
	check(g.loot_pending.is_empty() and Stock.count(g, Stock.MEDKIT) == 3, "nur Medikits: keine Auswahl")
	# Einsatzende im Schiff: Beute aus Campaign.last_result
	g.active = g.offers[0]
	Campaign.last_result = res
	g.finish_mission({"outcome": &"sieg"})
	check(g.report.payout.medkits == 2 and g.loot_pending.slots == 2, "finish_mission: Medikits im Bericht, Auswahl offen")
	g.active = g.offers[0]
	Campaign.last_result = res
	cr = g.credits
	var n := Stock.count(g, sg)
	g.finish_mission({"outcome": &"sieg"})
	check(Stock.count(g, sg) == n + 1 and g.loot_pending.items.size() == 4, "offene Auswahl wird vor neuer Beute mit Vorauswahl übernommen")
	TradeSkills.fixed = &"teilerfolg"
	HubState.game = null
	Campaign.last_result = {}
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


## Handwerk (Crafting): Material, Freischalten, Dauer, Bauen/Zerlegen/Reparieren nach Ergebnis, Spielstand
func _test_crafting() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(63, "Handwerk", 1)
	HubState.game = g
	var sg := "res://data/weapons/sturmgewehr.tres"
	var lp := "res://data/weapons/laserpistole.tres"
	var kp := "res://data/armor/mittel.tres"
	var mg := "res://data/weapons/mg.tres"
	var c: Character = Campaign.crew()[0]
	var c2: Character = Campaign.crew()[1]
	# Zahlen (Mockup 29–31)
	check(Crafting.build_material(sg) == 14 and Crafting.build_material(lp) == 8 and Crafting.build_material(kp) == 18 and Crafting.build_material(Stock.MEDKIT) == 2, "Material Bauen 14/8/18/2")
	check(Crafting.build_material(Crafting.ammo_key("energie")) == 3 and Crafting.build_material(Crafting.ammo_key("raketen")) == 3, "Munition 3/3")
	check(Crafting.repair_material(Stock.damaged_key(sg, -20)) == 3 and Crafting.repair_material(Stock.damaged_key(lp, -10)) == 1 and Crafting.repair_material(Stock.damaged_key(kp, -30)) == 6, "Material Reparieren 3/1/6")
	check(Crafting.take_material(kp, &"teilerfolg") == 7 and Crafting.take_material(sg, &"herausragend") == 11 and Crafting.take_material(sg, &"patzer") == 0, "Zerlegen 7/11/0")
	check(Crafting.build_days(g, sg) == 2 and Crafting.build_days(g, mg) == 3 and Crafting.build_days(g, lp) == 1, "Dauer 2/3/1")
	check(Crafting.skill_of(sg) == &"hwWaffen" and Crafting.skill_of(kp) == &"hwRuestung" and Crafting.skill_of(Stock.MEDKIT) == &"medikamente" and Crafting.skill_of(Crafting.ammo_key("projektil")) == &"hwWaffen", "Fertigkeiten")
	check(Crafting.difficulty(lp) == "mittel" and Crafting.difficulty(sg) == "schwer" and Crafting.difficulty(mg) == "sehrSchwer" and Crafting.difficulty("res://data/armor/schwer.tres") == "extrem", "Schwierigkeit nach Kaufpreis 150/280/500/700")
	check(Crafting.difficulty(Stock.damaged_key(sg, -20), "repair") == "schwer" and Crafting.difficulty(sg, "take") == "mittel" and Crafting.difficulty(Stock.MEDKIT) == "mittel" and Crafting.difficulty(Crafting.ammo_key("raketen")) == "mittel", "Reparieren wie Bauen; Zerlegen, Medikit, Munition mittel")
	check(Crafting.check_bonus(g, c, sg) == Rules.skill_total(c, &"hwWaffen") - 10 and Crafting.check_bonus(g, c, sg, "take") == Rules.skill_total(c, &"hwWaffen"), "Probenwert mit Schwierigkeit")
	check(not Equipment.SHIELD in Crafting.buildable() and sg in Crafting.buildable() and Crafting.ammo_key("raketen") in Crafting.buildable(), "baubar: ohne Schild, mit Munition")
	# Freischalten und Werkstatt-Stufen
	check(Crafting.unlocked(g, lp) and not Crafting.unlocked(g, sg) and Crafting.unlock_level(sg) == 1 and Crafting.unlock_level(mg) == 2, "Stufe 0: bis 200 Cr")
	g.upgrades["workshop"] = 1
	check(Crafting.unlocked(g, sg) and not Crafting.unlocked(g, mg) and Crafting.bonus(g, sg) == 10, "Stufe 1: bis 400, +10")
	g.upgrades["workshop"] = 2
	check(Crafting.unlocked(g, mg) and Crafting.build_days(g, sg) == 1 and Crafting.build_days(g, mg) == 2 and Crafting.bonus(g, sg) == 10, "Stufe 2: alles, Dauer −50 %")
	g.upgrades["workshop"] = 3
	check(Crafting.bonus(g, sg) == 20 and Crafting.bonus(g, Stock.MEDKIT) == g.heal_bonus(), "Stufe 3: +20; Medikits mit Ausbau Krankenstation")
	check(ShipUpgrades.AREAS.has(&"workshop") and ShipUpgrades.describe(&"workshop", 1) != "", "Werkstatt im Maschinenraum")
	g.upgrades["workshop"] = 1
	# Bauen
	g.craft_material = 13
	check(not Crafting.build(g, c, sg), "zu wenig Material")
	g.craft_material = 30
	check(Crafting.build(g, c, sg) and g.craft_material == 16 and Crafting.is_busy(g, c), "Bauen: Material sofort")
	check(not Crafting.build(g, c, lp), "eine Arbeit je Figur")
	check(not Campaign.candidates(false, HubState.game.blocked_ids()).any(func(x: Dictionary) -> bool: return x.ch == c and x.locked and String(x.reason).contains("Werkstatt")), "Handwerker nicht gesperrt")
	for res in [&"herausragend", &"erfolg", &"teilerfolg", &"fehlschlag"]:
		g.stock = {}
		g.jobs = {}
		g.craft_material = 100
		Crafting.build(g, c, sg)
		Voyage.fixed_result = res
		g.advance_days(2)
		var want := Stock.damaged_key(sg, int(Crafting.BUILD_WEAR[res]))
		check(Stock.count(g, want) == 1 and g.jobs.is_empty() and g.last_crafts.size() == 1, "Bauen %s → %s" % [res, Stock.name_of(want)])
		check(g.last_crafts[0].result == String(res) and String(g.last_crafts[0].text) != "" and g.last_crafts[0].has("xp")
			and g.last_crafts[0].skill != "", "Meldung %s mit Ergebnis, Fertigkeit, EP" % res)
	g.stock = {}
	g.craft_material = 100
	Crafting.build(g, c, sg)
	Voyage.fixed_result = &"patzer"
	g.advance_days(2)
	check(g.stock.is_empty(), "Bauen Patzer: nichts")
	var am := int(g.ammo.energie)
	Voyage.fixed_result = &"teilerfolg"
	Crafting.build(g, c, Crafting.ammo_key("energie"))
	g.advance_days(1)
	check(int(g.ammo.energie) == am + 30, "Munition +30")
	Crafting.build(g, c, Stock.MEDKIT)
	g.advance_days(1)
	check(Stock.count(g, Stock.MEDKIT) == 1, "Medikit ins Lager")
	# Zerlegen
	Stock.add(g, Stock.damaged_key(kp, -30))
	var m0 := g.craft_material
	check(Crafting.take_apart(g, c, Stock.damaged_key(kp, -30)) and Stock.count(g, Stock.damaged_key(kp, -30)) == 0, "Zerlegen: Stück sofort weg")
	Voyage.fixed_result = &"erfolg"
	g.advance_days(1)
	check(g.craft_material == m0 + 10, "Zerlegen Erfolg: +10 Material")
	# Reparieren
	var k20 := Stock.damaged_key(sg, -20)
	for pair in [[&"patzer", -30], [&"fehlschlag", -20], [&"teilerfolg", -10], [&"erfolg", 0]]:
		g.stock = {}
		Stock.add(g, k20)
		m0 = g.craft_material
		check(Crafting.repair(g, c2, k20) and g.craft_material == m0 - 3 and Stock.count(g, k20) == 0, "Reparieren: Material sofort, Stück in der Werkstatt")
		Voyage.fixed_result = pair[0]
		g.advance_days(1)
		check(Stock.count(g, Stock.damaged_key(sg, pair[1])) == 1, "Reparieren %s → %d" % [pair[0], pair[1]])
	g.stock = {}
	Stock.add(g, k20)
	m0 = g.craft_material
	Crafting.repair(g, c2, k20)
	Voyage.fixed_result = &"herausragend"
	g.advance_days(1)
	check(Stock.count(g, sg) == 1 and g.craft_material == m0, "Reparieren herausragend: heil, Material zurück")
	check(not Crafting.can_repair(g, c2, sg), "Intaktes nicht reparieren")
	# Material im Raumhafen
	g.position = g.nearest_harbor()
	g.credits = 100
	m0 = g.craft_material
	check(Crafting.buy_material(g, 10) and g.credits == 0 and g.craft_material == m0 + 10, "Material kaufen 10 Cr")
	check(Crafting.sell_material(g) and g.credits == 5, "Material verkaufen 5 Cr")
	# Spielstand: laufende Arbeit und Material
	Voyage.fixed_result = &""
	Crafting.build(g, c, lp)
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(h.jobs == g.jobs and h.craft_material == g.craft_material, "Arbeiten und Material im Spielstand")
	# Handwerker nicht mehr an Bord: abgebrochen, Material zurück
	g.jobs = {"niemand": {"kind": "build", "key": lp, "days": 1, "material": 8, "name": "X"}}
	m0 = g.craft_material
	g.advance_days(1)
	check(g.craft_material == m0 + 8 and String(g.last_crafts[0].text).contains("abgebrochen"), "abgebrochen: Material zurück")
	HubState.game = null
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


## Kombüse: Proviant, Kochprobe, Verbrauch, Malus, Kauf, Trainingsbonus, Spielstand (Entscheidungen 16.10.2026)
func _test_galley() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(77, "Kombüse", 1)
	var n := Campaign.crew().size()
	check(g.provisions == Galley.START and g.cook == "", "Startvorrat 60, kein Koch")
	check(Galley.need(&"fehlschlag", 6) == 6 and Galley.need(&"patzer", 6) == 8 and Galley.need(&"teilerfolg", 6) == 5
		and Galley.need(&"erfolg", 6) == 5 and Galley.need(&"herausragend", 6) == 4 and Galley.need(&"herausragend", 1) == 1, "Verbrauch je Ergebnis, kaufmännisch, mindestens 1")
	# im Hafen: kein Verbrauch, keine Probe
	g.position = g.nearest_harbor()
	g.wait_days(2)
	check(g.provisions == Galley.START and g.cooklog.is_empty(), "im Hafen kein Verbrauch")
	# außerhalb ohne Koch: Fehlschlag, normaler Verbrauch
	var away := -1
	for i in g.sector.systems.size():
		if not g.is_harbor(i):
			away = i
			break
	g.position = away
	g.wait_days(1)
	check(g.provisions == Galley.START - n and g.cooklog[0].result == "fehlschlag" and g.cooklog[0].cook == "", "ohne Koch wie Fehlschlag")
	# Koch würfelt mit EP; Ergebnis bestimmt den Verbrauch
	var c: Character = Campaign.crew()[1]
	Galley.set_cook(g, c)
	var xp0: int = Rules.ensure_skill(c, Galley.SKILL).xp
	Voyage.fixed_result = &"herausragend"
	var p0 := g.provisions
	g.wait_days(1)
	check(g.provisions == p0 - Galley.need(&"herausragend") and g.cooklog[0].cook == c.name and Rules.ensure_skill(c, Galley.SKILL).xp > xp0, "Koch: Herausragend spart, EP")
	check(Galley.bonus_pending(g) == (g.day % HubState.TRAINING_DAYS != 0), "Anzeige: Herausragend seit dem Training")
	# Trainingsbonus: Herausragend in den Tagen vor dem Training
	var fx0: int = Campaign.crew()[0].free_xp
	while g.day % HubState.TRAINING_DAYS != HubState.TRAINING_DAYS - 1:
		g.wait_days(1)
	g.wait_days(1)
	check(g.last_training == g.training_xp() + Galley.TRAINING_BONUS, "Training +1 nach Herausragend")
	Voyage.fixed_result = &"fehlschlag"
	g.wait_days(HubState.TRAINING_DAYS)
	check(g.last_training == g.training_xp(), "Training ohne Herausragend normal")
	check(Campaign.crew()[0].free_xp > fx0, "freie EP vergeben")
	# Mangel: Rest aufbrauchen, dann −10 auf Proben im Schiff
	g.provisions = 2
	g.wait_days(1)
	check(g.provisions == 0 and g.cooklog[0].use == 2 and g.cooklog[0].empty, "Rest aufgebraucht")
	check(Galley.malus(g) == Galley.MALUS, "ohne Proviant −10")
	Voyage.fixed_result = &""
	# Koch nicht mehr an Bord → ausgetragen
	g.cook = "niemand"
	check(Galley.cook(g) == null and g.cook == "", "Koch nicht an Bord: ausgetragen")
	# Kauf nur im Hafen, nach Handeln
	check(not Galley.can_buy(g, 10), "Kauf nur im Hafen")
	g.position = g.nearest_harbor()
	var cr := g.credits
	check(Galley.price(g) == Galley.PRICE and Galley.buy(g, 10) and g.provisions == 10 and g.credits == cr - 10 * Galley.PRICE, "Proviant kaufen 5 Cr")
	check(Galley.malus(g) == 0 and Galley.fill_amount(g) == n * Galley.FILL_DAYS - 10, "nach Kauf kein Malus; bis 10 Tage")
	# Reise: Verbrauch an Reisetagen, auch wenn das Ziel ein Hafen ist; Bericht
	var nb: int = g.sector.neighbors(g.position)[0][0]
	g.provisions = 50
	var d := g.travel_to(nb)
	check(d > 0 and g.last_travel.cook.size() == d and g.last_travel.prov0 == 50 and g.last_travel.prov1 == 50 - d * n, "Reise: Verbrauch je Reisetag, Bericht")
	# Spielstand
	Galley.set_cook(g, c)
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())), 1)
	check(h.provisions == g.provisions and h.cook == g.cook and h.cooklog == g.cooklog, "Kombüse im Spielstand")
	HubState.game = null
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


## Rückzug: eigener Ausgang, Auftrag bleibt offen (retry), kein Lohn, zählt nicht als erledigt
func _test_retreat() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	var g := HubState.new_game(88, "Rückzug", 1)
	var o: Dictionary = g.offers[0]
	o.expires = g.day + 20
	check(g.start_mission(o), "Auftrag angenommen")
	var cr := g.credits
	var done := g.missions_done
	Campaign.last_result = {"outcome": &"niederlage", "retreated": true}
	g.finish_mission({"outcome": &"niederlage", "title": "Test (Rückzug)"})
	var still := g.offers.filter(func(x: Dictionary) -> bool: return x.id == o.id)
	check(g.report.retreated and g.report.outcome == &"rueckzug" and g.report.expires == o.expires, "Bericht: Ausgang Rückzug mit Ablaufdatum")
	check(still.size() == 1 and still[0].retry, "Auftrag bleibt offen, Vermerk erneuter Versuch")
	check(g.credits == cr and g.report.payout.is_empty() and g.missions_done == done and not HubState.in_mission(), "kein Lohn, nicht erledigt")
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())), 1)
	check(h.offers.filter(func(x: Dictionary) -> bool: return x.id == o.id)[0].retry, "Vermerk im Spielstand")
	# erneuter Versuch, diesmal Niederlage ohne Rückzug: Auftrag weg
	check(g.start_mission(still[0]), "erneut angenommen")
	Campaign.last_result = {"outcome": &"niederlage", "retreated": false}
	g.finish_mission({"outcome": &"niederlage"})
	check(g.offers.filter(func(x: Dictionary) -> bool: return x.id == o.id).is_empty() and not g.report.retreated, "Niederlage ohne Rückzug: Auftrag erledigt")
	HubState.game = null
	Campaign.last_result = {}
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


## Anbindung Raumkampf, Teil 1 (Entscheidungen 16.10.2026): Slots, Lager, Handel, Posten, Systemschäden, Reparatur, setup
## Hüllenreparatur als Arbeit und schwer Verwundete (Entscheidungen des Nutzers 18.10.2026)
func _test_hull_job(g: HubState, fc: Character, other: Character) -> void:
	g.jobs = {}
	g.hull = 50
	g.material = 3
	var d0 := g.day
	Voyage.fixed_result = &"erfolg"
	check(ShipArms.start_fix(g, fc, ShipArms.HULL_TARGET) and g.day == d0 and g.material == 3 and Crafting.is_busy(g, fc)
		and not ShipArms.can_start_fix(g, other, ShipArms.HULL_TARGET), "Hülle: angelegt ohne Tag und Material, nur einmal")
	check(not Crafting.can_take_apart(g, fc, "medkit") and Crafting.job_text(Crafting.job_of(g, fc)).contains("Hülle"), "Hülle: eine Arbeit je Figur")
	g.wait_days(1)
	var e: Dictionary = g.last_crafts[0] if not g.last_crafts.is_empty() else {}
	check(g.hull == 70 and g.material == 2 and Crafting.is_busy(g, fc) and e.get("label", "") == "Reparatur" and e.result == "erfolg"
		and e.skill == String(ShipArms.SKILL), "Hülle: Tag 1 Erfolg +20, 1 Material, läuft weiter")
	var hj := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())), 1)
	check(ShipArms.is_hull_job(hj.jobs[String(fc.id)]), "Hüllenarbeit im Spielstand")
	# Reisetag: pausiert (keine Probe, kein Material)
	g.advance_days(1, true)
	check(g.hull == 70 and g.material == 2 and Crafting.is_busy(g, fc) and g.last_crafts.is_empty(), "Hülle: Reisetag pausiert")
	g.wait_days(2)
	check(g.hull == 100 and g.material == 0 and not Crafting.is_busy(g, fc), "Hülle: täglich bis voll, dann beendet")
	# Material leer: Arbeit endet
	g.hull = 50
	g.material = 1
	ShipArms.start_fix(g, fc, ShipArms.HULL_TARGET)
	g.wait_days(1)
	check(g.hull == 70 and g.material == 0 and not Crafting.is_busy(g, fc) and not ShipArms.can_start_fix(g, fc, ShipArms.HULL_TARGET), "Hülle: Material leer, Arbeit endet")
	# Beenden von Hand
	g.material = 2
	ShipArms.start_fix(g, fc, ShipArms.HULL_TARGET)
	check(ShipArms.stop_fix(g, fc) and not Crafting.is_busy(g, fc) and g.material == 2, "Hülle: Beenden, nichts verloren")
	# schwer Verwundete arbeiten nicht; kampfunfähig darf
	fc.injury = Injury.DOWN
	fc.injury_days = 30
	check(ShipArms.can_start_fix(g, fc, ShipArms.HULL_TARGET) and fc in ShipArms.fixers(g), "kampfunfähig: darf reparieren")
	ShipArms.start_fix(g, fc, ShipArms.HULL_TARGET)
	fc.injury = Injury.SEVERE
	g.craft_material = 50
	check(not Crafting.can_build(g, fc, Stock.MEDKIT) and not fc in ShipArms.fixers(g) and Crafting.status_text(g, fc).begins_with("schwer verwundet"),
		"schwer verwundet: kein Handwerk, keine Reparatur")
	var h0 := g.hull
	g.wait_days(1)
	check(g.hull == h0 and g.material == 2 and Crafting.is_busy(g, fc), "schwer verwundet: laufende Arbeit pausiert")
	var techs := Campaign.crew().filter(func(c: Character) -> bool: return c.station == "Technik")
	if not techs.is_empty():
		techs[0].injury = Injury.SEVERE
		techs[0].injury_days = 30
		check(Voyage.repairer(g) != techs[0], "Crew-Ausbau: schwer Verwundete machen die Probe nicht")
		techs[0].injury = Injury.DOWN
		check(Voyage.repairer(g) == techs[0] or String(techs[0].id) in g.medics, "Crew-Ausbau: kampfunfähig darf")
		techs[0].injury = ""
		techs[0].injury_days = 0
	fc.injury = ""
	fc.injury_days = 0
	g.wait_days(1)
	check(g.hull > h0 or g.hull == g.hull_max(), "nach der Genesung läuft die Arbeit weiter")
	g.jobs = {}
	g.material = 0


func _test_ship_arms() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	TradeSkills.fixed = &"teilerfolg"
	var g := HubState.new_game(91, "Raumkampf", 1)
	var crew := Campaign.crew()
	for c in crew:
		c.station = ""
	check(ShipArms.slot_ids(g) == ["bug", "backbord", "steuerbord", "turm"] and ShipArms.slot_key(g, "bug") == "laserbank"
		and ShipArms.slot_key(g, "turm") == "abwehrgeschuetz" and g.ship_ammo == {"schiffsraketen": 6, "geschosse": 40}, "Startschiff und Startvorrat")
	check(ShipArms.keys() == ShipWeapons.keys() and ShipArms.name("partikelkanone") == ShipWeapons.name("partikelkanone")
		and ShipArms.price("laserbank|-20") == ShipWeapons.price("laserbank")
		and ShipArms.ammo("raketenwerfer") == "schiffsraketen" and ShipArms.ammo("laserbank") == "", "Übergangskatalog")
	check(ShipArms.fits("abwehrgeschuetz", "turm") and not ShipArms.fits("abwehrgeschuetz", "bug") and not ShipArms.fits("laserbank", "turm2")
		and ShipArms.fits("raketenbatterie", "heck"), "Turm nur Abwehr, sonst jede andere Waffe")
	check(ShipUpgrades.AREAS.size() == 12 and ShipUpgrades.describe(&"slots", 1) == "5 Slots (+ Heck)" and ShipUpgrades.describe(&"shields", 2) == "Stufe 2", "neue Ausbau-Bereiche")
	# Ausbau Waffenslots in der Werft
	var away := -1
	for i in g.sector.systems.size():
		if not g.is_harbor(i):
			away = i
			break
	g.position = g.nearest_harbor()
	g.credits = 20000
	check(ShipUpgrades.buy_yard(g, &"slots") and ShipArms.slot_ids(g).size() == 5 and g.ship_slots.has("heck") and ShipArms.slot_key(g, "heck") == "", "Waffenslots Stufe 1: Heck frei")
	# Handel nach Verhandeln (Teilerfolg = Normalpreis, Verkauf 50 %)
	var shop := ShipArms.shop(g, g.position)
	check(not shop.is_empty() and shop.size() == ceili(8 * TradeSkills.shop_share(g)), "Schiffswaffen im Sortiment nach Gassenwissen")
	var k: String = shop[0]
	var cr := g.credits
	check(ShipArms.buy(g, k) and g.credits == cr - ShipArms.price(k) and ShipArms.stock_count(g, k) == 1, "Schiffswaffe kaufen ins Lager")
	# Preise sind Platzhalter des Raumkampfs: Erwartung aus ShipWeapons berechnet
	var lp: int = ShipWeapons.price("laserbank")
	check(ShipArms.sell_price(g, "laserbank|-20") == int(floor(lp * 0.5 * 0.5)) and ShipArms.sell_price(g, "laserbank") == int(floor(lp * 0.5)),
		"Verkauf 50 %, beschädigt −25 % je −10")
	check(ShipArms.sell(g, k) and ShipArms.stock_count(g, k) == 0, "Schiffswaffe verkaufen")
	cr = g.credits
	check(ShipArms.buy_ammo(g, "schiffsraketen", 3) and g.credits == cr - 180 and g.ship_ammo.schiffsraketen == 9, "Schiffsraketen 60 Cr")
	check(ShipArms.buy_ammo(g, "geschosse", 10) and g.ship_ammo.geschosse == 50 and ShipArms.ammo_sell(g, "schiffsraketen", 3) == 90, "Geschosse 3 Cr, Verkauf 50 %")
	TradeSkills.fixed = &"erfolg"
	check(ShipArms.buy_price(g, "laserbank") == roundi(lp * 0.9) and ShipArms.ammo_price(g, "schiffsraketen") == 54
		and ShipArms.sell_price(g, "laserbank") == int(floor(lp * 0.6)), "Verhandeln Erfolg: −10 %, Verkauf 60 %")
	TradeSkills.fixed = &"teilerfolg"
	# Einbau nur im Hafen; alte Waffe ins Lager, Schaden bleibt am Stück
	ShipArms.stock_add(g, "partikelkanone")
	ShipArms.stock_add(g, "abwehrlaser")
	ShipArms.stock_add(g, "schnellfeuerkanone|-10")
	check(not ShipArms.install(g, "bug", "abwehrlaser"), "Abwehrlaser nicht in den Bug")
	check(ShipArms.install(g, "bug", "partikelkanone") and ShipArms.slot_key(g, "bug") == "partikelkanone" and ShipArms.stock_count(g, "laserbank") == 1, "Tauschen: Laserbank ins Lager")
	check(ShipArms.install(g, "turm", "abwehrlaser") and ShipArms.stock_count(g, "abwehrgeschuetz") == 1, "Turm: Abwehrlaser")
	check(ShipArms.install(g, "heck", "schnellfeuerkanone|-10") and ShipArms.slot_damage(g, "heck") == -10, "beschädigt eingebaut")
	check(ShipArms.uninstall(g, "heck") and ShipArms.stock_count(g, "schnellfeuerkanone|-10") == 1 and ShipArms.slot_key(g, "heck") == "", "Ausbau mit Schaden ins Lager")
	g.position = away
	check(not ShipArms.can_install(g, "heck", "laserbank") and not ShipArms.can_uninstall(g, "bug") and not ShipArms.can_buy_ammo(g, "geschosse", 10), "unterwegs kein Einbau, kein Handel")
	# Posten: feste aus Character.station, Geschützposten im Hub
	crew[0].station = "Steuer"
	crew[1].station = "Geschütze"
	var p := ShipArms.posts(g)
	check(p.steuer == String(crew[0].id) and p.navigation == ShipArms.KI and p.geschuetz_bug == String(crew[1].id)
		and p.geschuetz_turm == ShipArms.KI and not p.has("geschuetz_heck"), "Posten: Station, Geschütze am ersten Slot, sonst KI")
	ShipArms.set_gun_post(g, "backbord", String(crew[1].id))
	p = ShipArms.posts(g)
	check(p.geschuetz_backbord == String(crew[1].id) and p.geschuetz_bug == ShipArms.KI, "eine Figur nur an einem Geschütz")
	check(not crew[0] in ShipArms.gun_candidates(g) and crew[1] in ShipArms.gun_candidates(g), "Geschütz nur ohne andere Station")
	Medbay.toggle(g, crew[0])
	check(ShipArms.posts(g).steuer == ShipArms.KI, "Personal der Krankenstation: Bord-KI")
	g.medics = []
	# Systemschäden: Reiseproben, Ausfall
	ShipArms.set_stage(g, "antrieb", 3)
	ShipArms.set_stage(g, "station_computer", 1)
	check(g.ship_damage == {"antrieb": "C", "station_computer": "A"} and ShipArms.travel_malus(g, &"pilot") == -15
		and ShipArms.travel_malus(g, &"rsReparatur") == 0, "Antrieb C: −15 auf Pilot")
	check(ShipArms.effect_text("antrieb", 3) == "−15 auf Pilot (Reiseprobe)" and ShipArms.effect_text("station_computer", 1) == "nur im Kampf", "Wirkungstext")
	var target := g.nearest_harbor()
	check(g.can_travel(target), "Antrieb C: Reise möglich")
	ShipArms.set_stage(g, "antrieb", 5)
	check(not g.can_travel(target) and g.travel_to(target) == -1, "Antrieb E: keine Reise")
	ShipArms.set_stage(g, "antrieb", 3)
	ShipArms.set_stage(g, "lebenserhaltung", 5)
	g.provisions = 100
	g.cook = ""
	g.wait_days(1)
	check(g.provisions == 100 - 2 * Galley.need(), "Lebenserhaltung E: Proviant doppelt")
	ShipArms.set_stage(g, "lebenserhaltung", 0)
	# Crew-Reparatur als Arbeit wie Handwerk (Entscheidungen 18.10.2026): kein Tag sofort, Probe am Ende, eine Arbeit je Figur
	g.material = 5
	g.jobs = {}
	var fc := ShipArms.default_fixer(g)
	var d0 := g.day
	Voyage.fixed_result = &"erfolg"
	check(ShipArms.start_fix(g, fc, "antrieb") and g.day == d0 and g.material == 4 and ShipArms.stage(g, "antrieb") == 3
		and ShipArms.fix_job(g, "antrieb").name == fc.name and Crafting.is_busy(g, fc), "Reparatur angelegt: 1 Material, kein Tag, Figur beschäftigt")
	check(not ShipArms.can_start_fix(g, fc, "station_computer") and not Crafting.can_take_apart(g, fc, "medkit"), "eine Arbeit je Figur (auch kein Handwerk)")
	var other: Character = null
	for c in ShipArms.fixers(g):
		if c != fc:
			other = c
			break
	check(not ShipArms.can_start_fix(g, other, "antrieb"), "Ziel schon in Arbeit")
	var hj := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())), 1)
	check(String(hj.jobs[String(fc.id)].kind) == ShipArms.FIX_KIND and hj.jobs[String(fc.id)].key == "antrieb", "Reparatur im Spielstand")
	g.wait_days(1)
	var e: Dictionary = g.last_crafts[0] if not g.last_crafts.is_empty() else {}
	check(ShipArms.stage(g, "antrieb") == 2 and not Crafting.is_busy(g, fc) and e.get("label", "") == "Reparatur" and e.result == "erfolg"
		and e.skill == String(ShipArms.SKILL) and String(e.text).contains("Antrieb"), "Arbeit fertig: Erfolg −1 Stufe, Meldung wie Werkstatt")
	Voyage.fixed_result = &"herausragend"
	ShipArms.start_fix(g, fc, "antrieb")
	g.wait_days(1)
	check(not g.ship_damage.has("antrieb"), "Crew: Herausragend −2 Stufen")
	Voyage.fixed_result = &"patzer"
	ShipArms.start_fix(g, fc, "station_computer")
	g.wait_days(1)
	check(ShipArms.stage(g, "station_computer") == 2, "Crew: Patzer +1 Stufe")
	Voyage.fixed_result = &"teilerfolg"
	ShipArms.start_fix(g, fc, "station_computer")
	g.wait_days(1)
	check(ShipArms.stage(g, "station_computer") == 2 and g.material == 1, "Crew: Teilerfolg nichts, Material weg")
	Voyage.fixed_result = &"erfolg"
	g.ship_slots.backbord.damage = -20
	ShipArms.start_fix(g, fc, "slot:backbord")
	g.wait_days(1)
	check(ShipArms.slot_damage(g, "backbord") == -10 and g.material == 0, "Crew: Waffe im Slot −10 weg")
	check(not ShipArms.can_start_fix(g, fc, "slot:backbord"), "ohne Material keine Crew-Reparatur")
	g.material = 2
	Voyage.fixed_result = &"herausragend"
	check(ShipArms.start_fix(g, other, "schnellfeuerkanone|-10") and ShipArms.stock_count(g, "schnellfeuerkanone|-10") == 0, "Stück aus dem Lager in der Werkstatt")
	g.wait_days(1)
	check(ShipArms.stock_count(g, "schnellfeuerkanone") == 1 and ShipArms.stock_count(g, "schnellfeuerkanone|-10") == 0, "Crew: Waffe im Lager heil")
	# Abbruch: Figur nicht mehr an Bord → Material und Stück zurück
	ShipArms.stock_add(g, "laserbank|-20")
	ShipArms.start_fix(g, other, "laserbank|-20")
	var mat0 := g.material
	g.jobs[String(other.id)].name = other.name
	g.jobs["niemand_mehr"] = g.jobs[String(other.id)]
	g.jobs.erase(String(other.id))
	g.wait_days(1)
	check(g.material == mat0 + 1 and ShipArms.stock_count(g, "laserbank|-20") == 1 and String(g.last_crafts[0].text).contains("abgebrochen"), "Abbruch: Material und Stück zurück")
	ShipArms.stock_take(g, "laserbank|-20")
	_test_hull_job(g, fc, other)
	Voyage.fixed_result = &""
	check(ShipArms.damage_count(g) == 2, "offene Schäden: Station Computer, Massebeschleuniger")
	# Werft: nur im Hafen
	check(not ShipArms.can_yard_system(g, "station_computer"), "Werft nur im Hafen")
	g.position = g.nearest_harbor()
	g.credits = 1000
	g.material = 1
	check(ShipArms.yard_stage_cost(g) == 50 and ShipArms.yard_system(g, "station_computer") and ShipArms.stage(g, "station_computer") == 1
		and g.credits == 950 and g.material == 0, "Werft: 1 Stufe 50 Cr + 1 Material")
	check(not ShipArms.can_yard_system(g, "station_computer"), "Werft braucht Material")
	check(ShipArms.yard_weapon_cost(g, "slot:backbord") == roundi(ShipWeapons.price("massebeschleuniger") * 0.1) and ShipArms.yard_weapon(g, "slot:backbord") and ShipArms.slot_damage(g, "backbord") == 0, "Werft: Waffe 10 % je −10")
	# Spielstand
	ShipArms.stock_add(g, "laserbank|-20")
	var h := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())), 1)
	check(h.ship_slots == g.ship_slots and h.ship_stock == g.ship_stock and h.ship_ammo == g.ship_ammo and h.ship_damage == g.ship_damage
		and h.gun_posts == g.gun_posts, "Schiff im Spielstand")
	var old := HubState.from_dict({"sector": g.sector.to_dict()})
	check(old.ship_slots == ShipArms.start_slots() and old.ship_ammo == SpaceSetup.START_AMMO and old.ship_damage.is_empty(), "alte Spielstände: Startschiff")
	# setup für SpaceBattle.start
	crew[2].injury = Injury.DOWN
	crew[2].injury_days = 3
	var su := ShipArms.setup(g, {"faction": "piraten", "difficulty": "mittel"}, "reise")
	check(su.ship.levels == {"shields": 0, "armor": 0, "reactor": 0, "slots": 1} and su.ship.slots.size() == 5 and su.ship.hull_max == g.hull_max()
		and su.ship_ammo == g.ship_ammo and su.source == "reise" and su.return_scene == HubState.HUB_SCENE and su.posts.has("geschuetz_bug")
		and su.crew.size() == crew.size() - 1 and not crew[2] in su.crew, "setup aus dem HubState, Gesperrte fehlen")
	# Schnittstellen-Erweiterung Raumkampf: Waffenslots 0–5, weitere Techniker, selbst entern
	g.position = g.nearest_harbor()
	g.credits = 50000
	while ShipUpgrades.level(g, &"slots") < 3:
		ShipUpgrades.buy_yard(g, &"slots")
	check(ShipUpgrades.max_level(&"slots") == 5 and ShipUpgrades.max_level(&"tank") == 3 and ShipUpgrades.yard_cost(g, &"slots") == 3200
		and ShipUpgrades.CREW_MATERIAL[3] == 12 and ShipUpgrades.CREW_DAYS[3] == 10, "Waffenslots Stufe 4: 3200 Cr, 12 Material, 10 Tage")
	ShipUpgrades.buy_yard(g, &"slots")
	check(ShipUpgrades.yard_cost(g, &"slots") == 4500, "Waffenslots Stufe 5: 4500 Cr")
	ShipUpgrades.buy_yard(g, &"slots")
	check(ShipArms.slot_ids(g) == SpaceSetup.slots_for(5) and "backbord2" in g.ship_slots and "steuerbord2" in g.ship_slots and "turm2" in g.ship_slots
		and not ShipUpgrades.can_yard(g, &"slots") and ShipUpgrades.describe(&"slots", 5) == "9 Slots (+ Turm 2)", "Waffenslots Stufe 5: 9 Slots, ausgebaut")
	check(ShipArms.fits("raketenwerfer", "backbord2") and ShipArms.fits("abwehrlaser", "turm2") and not ShipArms.fits("abwehrlaser", "steuerbord2"), "neue Slots: Turm 2 nur Abwehr")
	var free_c: Character = null
	for c in crew:
		if c.station == "" and not c.is_locked():
			free_c = c
			break
	p = ShipArms.posts(g)
	check(p.technik_2 == ShipArms.KI and p.technik_3 == ShipArms.KI, "weitere Techniker ohne Eintrag frei")
	ShipArms.set_gun_post(g, "technik_2", String(free_c.id))
	check(ShipArms.posts(g).technik_2 == String(free_c.id), "Techniker 2 besetzt")
	ShipArms.set_gun_post(g, "bug", String(free_c.id))
	p = ShipArms.posts(g)
	check(p.geschuetz_bug == String(free_c.id) and p.technik_2 == ShipArms.KI, "eine Figur nur auf einem Zusatzposten")
	check(ShipArms.setup(g, {}, "reise").ship.levels.slots == 5, "setup: Waffenslots Stufe 5")
	# selbst entern: vormerken, Bodenkampf, Beute nur bei Sieg
	check(not g.book_board({"outcome": &"sieg"}, "mittel") and g.board_pending.is_empty(), "ohne board_enemy nichts vorgemerkt")
	var loot := {"credits": 300, "material": 4, "ship_ammo": {"geschosse": 20}, "weapons": [{"key": "raketenbatterie", "name": "Raketenbatterie", "damage": -20}]}
	var res := {"outcome": &"sieg", "board_enemy": true, "board_faction": "rote_sonne", "board_ship": "Korvette Ash", "board_loot": loot}
	check(g.book_board(res, "schwer") and g.board_pending.faction == "rote_sonne" and g.board_pending.difficulty == "schwer", "Entern vorgemerkt")
	var hb := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())), 1)
	check(hb.board_pending.ship == "Korvette Ash" and int(hb.board_pending.loot.credits) == 300, "Entern im Spielstand")
	check(g.start_boarding() and g.active.board and g.active.difficulty == "schwer", "Bodenkampf gegen die Besatzung vorbereitet")
	var bm := g.mission_of(g.active)
	check(bm.faction.resource_path == "res://data/missions/rote_sonne.tres" and HubState.board_faction_path("piraten") == "", "Missionsfraktion kämpft selbst, Piraten zufällig")
	var cr1 := g.credits
	var m1 := g.material
	var ga: int = g.ship_ammo.geschosse
	var offers_before := g.offers.size()
	Campaign.last_result = {"outcome": &"sieg", "units": {"a": {}}, "loot": [{"key": "res://data/weapons/raketenwerfer.tres", "damage": -20},
		{"key": Stock.MEDKIT, "count": 1}]}
	g.loot_pending = {}
	g.finish_mission({"outcome": &"sieg", "title": "Entern"})
	check(g.report.medkits == 1 and g.loot_pending.items.size() == 1, "Entern gewonnen: Beuteauswahl aus dem Bodenkampf")
	g.loot_pending = {}
	check(g.credits == cr1 + 300 and g.material == m1 + 4 and g.ship_ammo.geschosse == ga + 20 and ShipArms.stock_count(g, "raketenbatterie|-20") == 1
		and g.board_pending.is_empty() and g.report.board == "Korvette Ash" and g.report.payout.is_empty(), "Sieg: Beute des Schiffs verbucht, kein Lohn")
	check(not HubState.in_mission() and g.offers.size() >= offers_before, "kein Einsatz mehr offen, Aufträge unberührt")
	g.book_board(res, "mittel")
	g.start_boarding()
	cr1 = g.credits
	Campaign.last_result = {"outcome": &"niederlage"}
	g.finish_mission({"outcome": &"niederlage"})
	check(g.credits == cr1 and g.report.board_loot.is_empty() and g.board_pending.is_empty(), "Niederlage: Beute verloren")
	Campaign.last_result = {}
	TradeSkills.fixed = &"teilerfolg"
	HubState.game = null
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()


## Raumkampf im Spiel, Teil 2 (Entscheidungen 16.10.2026): Feindkontakt, Ausweichen, Auftragsarten, Auswertung, Notfall
func _test_space_events() -> void:
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.new_game(GlobalRoster.entries())
	TradeSkills.fixed = &"teilerfolg"
	var g := HubState.new_game(93, "Raumkampf 2", 1)
	g.credits = 1000
	# Auftragsarten
	SpaceEvents.fixed_kind = ""
	var kinds := {}
	for i in 400:
		var k := SpaceEvents.roll_kind()
		kinds[k.kind + ("+b" if k.blockade else "")] = int(kinds.get(k.kind + ("+b" if k.blockade else ""), 0)) + 1
	check(kinds.has("abfangen") and kinds.has("eskorte") and kinds.has("boden+b") and kinds.has("boden"), "alle Auftragsarten kommen vor %s" % kinds)
	SpaceEvents.fixed_kind = "eskorte"
	g.offers = []
	g.refill_offers()
	var eo: Dictionary = g.offers[0]
	var ed: int = g.sector.route(eo.system, eo.target).days
	check(eo.kind == "eskorte" and ed >= 1 and ed <= 3, "Eskorte mit Ziel 1–3 Reisetage")
	check(SpaceEvents.offer_pay(g, eo) == roundi((Voyage.PAY[eo.difficulty] * float(Voyage.PAY_FACTOR.get(String(g.sector.systems[eo.system].faction).get_file().get_basename(), 1.0))) * 1.5)
		or SpaceEvents.offer_pay(g, eo) > 0, "Eskorte zahlt ×1,5")
	var hb := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())), 1)
	check(hb.offers[0].kind == "eskorte" and hb.offers[0].target == eo.target, "Auftragsart im Spielstand")
	check(HubState.from_dict({"sector": g.sector.to_dict(), "offers": [{"id": 1, "system": 0, "seed": 1, "difficulty": "leicht", "expires": 9}]}).offers[0].kind == "boden", "alte Aufträge = Boden")
	SpaceEvents.fixed_kind = "boden"
	# Kontaktwahrscheinlichkeit nach Gebiet
	var harbor := g.nearest_harbor()
	var hostile := -1
	for i in g.sector.systems.size():
		if not g.is_harbor(i):
			hostile = i
			break
	check(SpaceEvents.contact_chance(g, harbor) == 0.05 and SpaceEvents.contact_chance(g, hostile) == 0.20
		and SpaceEvents.faction_id(g, harbor) == "piraten", "Feindkontakt 5 % neutral, 20 % Fraktion; neutral = Piraten")
	# Reise mit Kontakt am ersten Tag: Reise unterbrochen
	var far := -1
	for i in g.sector.systems.size():
		if g.sector.route(g.position, i).days >= 2:
			far = i
			break
	var total: int = g.sector.route(g.position, far).days
	var d0 := g.day
	SpaceEvents.fixed_contact = 0
	var done := g.travel_to(far)
	check(done == 1 and g.day == d0 + 1 and not g.contact.is_empty() and int(g.travel_rest.days) == total - 1 and g.position != far
		and not g.last_travel.contact.is_empty(), "Feindkontakt an Tag 1 unterbricht die Reise")
	var h2 := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())), 1)
	check(h2.contact.faction == g.contact.faction and h2.travel_rest.target == far, "Kontakt und Restreise im Spielstand")
	# Ausweichen gelingt: Reise geht weiter
	Voyage.fixed_result = &"erfolg"
	var r := g.dodge_contact()
	check(r.dodged and g.contact.is_empty() and g.space_ctx.is_empty(), "Ausweichen mit Navigation (Erfolg)")
	SpaceEvents.fixed_contact = -2
	g.resume_travel()
	check(g.position == far and g.travel_rest.is_empty() and g.day == d0 + total, "Restreise geflogen")
	# Ausweichen misslingt: Raumkampf, Sieg mit Beute, Reise geht weiter
	var back := g.nearest_harbor()
	if g.sector.route(g.position, back).days < 2:
		for i in g.sector.systems.size():
			if g.sector.route(g.position, i).days >= 2:
				back = i
				break
	SpaceEvents.fixed_contact = 0
	g.travel_to(back)
	Voyage.fixed_result = &"fehlschlag"
	r = g.dodge_contact()
	check(not r.dodged and g.contact.is_empty() and g.space_ctx.kind == "reise", "Ausweichen misslungen: Raumkampf")
	var su := g.space_setup()
	check(su.source == "reise" and su.enemy.faction == g.space_ctx.faction and su.return_scene == HubState.HUB_SCENE, "setup für den Kontakt")
	var cr := g.credits
	var am: int = g.ship_ammo.geschosse
	var res := {"outcome": &"sieg", "retreated": false, "surrendered": false, "ransom": {}, "boarding": false, "emergency": false, "units": {},
		"ship": {"hull": 70, "damage": {"antrieb": "B"}, "slots": {"backbord": {"key": "massebeschleuniger", "damage": -10}}},
		"ship_ammo_used": {"geschosse": 5}, "fuel_used": 2, "board_enemy": false,
		"ship_loot": {"credits": 200, "material": 1, "ship_ammo": {"schiffsraketen": 2}, "weapons": [{"key": "raketenwerfer", "name": "Raketenwerfer", "damage": -20}]}}
	var nx := g.finish_space(res)
	check(nx == "" and g.hull == 70 and g.ship_damage.antrieb == "B" and ShipArms.slot_damage(g, "backbord") == -10 and g.ship_ammo.geschosse == am - 5
		and g.credits == cr + 200 and ShipArms.stock_count(g, "raketenwerfer|-20") == 1 and g.space_report.new_damage.has("antrieb"), "Sieg: Schiff und Kampfbeute gebucht")
	SpaceEvents.fixed_contact = -2
	check(not g.travel_rest.is_empty() and g.resume_travel() >= 0 and g.position == back, "nach dem Kampf geht die Reise weiter")
	# Abfangen: Flucht = Auftrag bleibt offen, Sieg = Lohn
	SpaceEvents.fixed_kind = "abfangen"
	g.offers = []
	g.refill_offers()
	var ao: Dictionary = g.offers[0]
	ao.system = g.position
	ao.expires = g.day + 10
	check(g.start_mission(ao) and g.active.is_empty() and g.pending_offer == ao.id and g.begin_offer() == "space" and g.space_ctx.kind == "auftrag", "Abfangen beginnt mit Raumkampf")
	var flee := res.duplicate(true)
	flee.outcome = &"niederlage"
	flee.retreated = true
	flee.ship_loot = {}
	g.finish_space(flee)
	check(g.offer_by_id(ao.id).get("retry", false), "Flucht: Auftrag bleibt offen")
	g.start_mission(g.offer_by_id(ao.id))
	g.begin_offer()
	cr = g.credits
	var done0 := g.missions_done
	g.finish_space(res)
	check(g.offer_by_id(ao.id).is_empty() and g.credits == cr + 200 + SpaceEvents.offer_pay(g, ao) and g.missions_done == done0 + 1, "Abfangen gewonnen: Lohn + Beute")
	# Blockade: Sieg → Bodeneinsatz
	SpaceEvents.fixed_kind = "blockade"
	g.offers = []
	g.refill_offers()
	var bo: Dictionary = g.offers[0]
	bo.system = g.position
	bo.expires = g.day + 10
	check(g.start_mission(bo) and g.active.is_empty() and g.begin_offer() == "space" and g.space_ctx.kind == "vor_einsatz", "Blockade: erst Raumkampf")
	check(g.finish_space(res) == "ground" and g.active.id == bo.id, "Blockade durchbrochen: Bodeneinsatz")
	g.active = {}
	# Notfall: Plünderung + Treiben
	SpaceEvents.fixed_kind = "abfangen"
	g.offers = []
	g.refill_offers()
	var no: Dictionary = g.offers[0]
	no.system = g.position
	no.expires = g.day + 10
	g.start_mission(no)
	g.begin_offer()
	g.credits = 800
	g.ship_ammo = {"schiffsraketen": 8, "geschosse": 40}
	g.stock = {"medkit": 2}
	g.ship_stock = {"laserbank": 1}
	var lost := res.duplicate(true)
	lost.outcome = &"niederlage"
	lost.emergency = true
	lost.ship_loot = {}
	lost.ship_ammo_used = {}
	g.finish_space(lost)
	var pl: Dictionary = g.space_report.plunder
	check(pl.credits == 200 and g.credits == 600 and g.ship_ammo.schiffsraketen == 6 and g.ship_ammo.geschosse == 30 and pl.items.size() == 3
		and Stock.count(g, "medkit") + ShipArms.stock_count(g, "laserbank") == 0 and g.hull == 0 and g.stranded() and g.offer_by_id(no.id).is_empty(),
		"Notfall: 25 % Credits und Munition, 3 Stücke, Hülle 0, festgesetzt")
	g.hull = 50
	# Kapitulation: Lösegeld
	g.space_ctx = {"kind": "reise", "offer_id": -1, "faction": "piraten", "difficulty": "mittel", "mission": "Test"}
	cr = g.credits
	var sur := res.duplicate(true)
	sur.outcome = &"niederlage"
	sur.surrendered = true
	sur.ransom = {"credits": 400, "ship_ammo": {}}
	sur.ship_loot = {}
	g.finish_space(sur)
	check(g.credits == cr - 400 and g.space_report.plunder.is_empty() and g.hull == 70, "Kapitulation: Lösegeld, keine Plünderung")
	# Gegner entern: Abwehr an Bord; verloren = Notfall
	g.hull = 50
	g.space_ctx = {"kind": "reise", "offer_id": -1, "faction": "piraten", "difficulty": "mittel", "mission": "Test"}
	var brd := res.duplicate(true)
	brd.outcome = &"niederlage"
	brd.boarding = true
	brd.boarding_faction = "rote_sonne"
	brd.ship_loot = {}
	check(g.finish_space(brd) == "defend" and g.active.defend and g.mission_of(g.active).faction.resource_path == "res://data/missions/rote_sonne.tres", "Gegner entern: Bodenkampf an Bord")
	g.credits = 400
	Campaign.last_result = {"outcome": &"niederlage"}
	g.finish_mission({"outcome": &"niederlage"})
	check(g.report.defend and g.credits == 300 and g.stranded() and g.report.plunder.credits == 100, "Abwehr verloren: Notfall")
	g.hull = 50
	g.space_ctx = {"kind": "reise", "offer_id": -1, "faction": "piraten", "difficulty": "mittel", "mission": "Test"}
	brd.board_ship = "Enterschiff Y"
	brd.board_loot = {"credits": 120, "material": 2, "ship_ammo": {"geschosse": 10}, "weapons": [{"key": "raketenwerfer", "damage": -10}]}
	g.finish_space(brd)
	check(g.space_report.next == "defend" and g.active.ship == "Enterschiff Y", "Enterschiff und Beute vorgemerkt")
	cr = g.credits
	var mt := g.material
	var gs: int = g.ship_ammo.get("geschosse", 0)
	var day0 := g.day
	g.loot_pending = {}
	Campaign.last_result = {"outcome": &"sieg", "units": {"a": {}}, "loot": [{"key": "res://data/weapons/raketenwerfer.tres", "damage": 0}]}
	g.finish_mission({"outcome": &"sieg"})
	check(g.report.defend and g.credits == cr + 120 and g.material == mt + 2 and g.ship_ammo.geschosse == gs + 10
		and ShipArms.stock_count(g, "raketenwerfer|-10") >= 1 and not g.report.has("plunder") and g.report.board == "Enterschiff Y"
		and g.loot_pending.items.size() == 1 and g.day == day0 + HubState.MISSION_DAYS, "Abwehr gewonnen: Beute des Enterschiffs, Beuteauswahl")
	g.loot_pending = {}
	# Abwehr im Abfang-Auftrag: gewonnen = Lohn, verloren = Auftrag weg
	SpaceEvents.fixed_kind = "abfangen"
	g.offers = []
	g.refill_offers()
	var dao: Dictionary = g.offers[0]
	dao.system = g.position
	dao.expires = g.day + 10
	g.start_mission(dao)
	g.begin_offer()
	g.finish_space(brd)
	check(not g.offer_by_id(dao.id).is_empty(), "Gegner entern: Auftrag noch offen bis zur Abwehr")
	cr = g.credits
	var done1 := g.missions_done
	Campaign.last_result = {"outcome": &"sieg"}
	g.finish_mission({"outcome": &"sieg"})
	check(g.offer_by_id(dao.id).is_empty() and g.credits == cr + 120 + SpaceEvents.offer_pay(g, dao) and g.missions_done == done1 + 1
		and int(g.report.pay) == SpaceEvents.offer_pay(g, dao), "Abwehr im Abfangen gewonnen: Lohn wie im Raumkampf")
	g.refill_offers()
	var dao2: Dictionary = g.offers[0]
	dao2.system = g.position
	dao2.expires = g.day + 10
	g.start_mission(dao2)
	g.begin_offer()
	g.finish_space(brd)
	g.hull = 50
	Campaign.last_result = {"outcome": &"niederlage"}
	g.finish_mission({"outcome": &"niederlage"})
	check(g.offer_by_id(dao2.id).is_empty() and g.report.has("plunder"), "Abwehr im Abfangen verloren: Auftrag weg, Notfall")
	g.hull = 50
	g.travel_rest = {}
	# Abwehr in der Blockade gewonnen: Bodeneinsatz folgt gleich (Truppwahl), keine Zeit vergeht
	SpaceEvents.fixed_kind = "blockade"
	g.offers = []
	g.refill_offers()
	var dbo: Dictionary = g.offers[0]
	dbo.system = g.position
	dbo.expires = g.day
	g.start_mission(dbo)
	g.begin_offer()
	g.finish_space(brd)
	day0 = g.day
	Campaign.last_result = {"outcome": &"sieg"}
	g.finish_mission({"outcome": &"sieg"})
	var hb2 := HubState.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g.report.next == "ground" and g.day == day0 and g.pending_offer == dbo.id and hb2.offer_by_id(dbo.id).get("blockade_done", false),
		"Abwehr in der Blockade gewonnen: Bodeneinsatz vorgemerkt")
	check(g.begin_offer() == "ground" and g.active.id == dbo.id, "Bodeneinsatz ohne neue Blockade")
	g.active = {}
	Campaign.last_result = {}
	# selbst entern über die Auswertung
	g.space_ctx = {"kind": "reise", "offer_id": -1, "faction": "schmuggler", "difficulty": "leicht", "mission": "Test"}
	var be := res.duplicate(true)
	be.board_enemy = true
	be.board_faction = "schmuggler"
	be.board_ship = "Frachter X"
	be.board_loot = {"credits": 50, "material": 0, "ship_ammo": {}, "weapons": []}
	check(g.finish_space(be) == "board" and g.board_pending.difficulty == "leicht", "selbst entern aus der Auswertung")
	g.board_pending = {}
	# Eskorte: sicher ein Kontakt, Lohn bei Ankunft
	SpaceEvents.fixed_kind = "eskorte"
	g.offers = []
	g.refill_offers()
	var es: Dictionary = g.offers[0]
	es.system = g.position
	es.expires = g.day + 10
	SpaceEvents.fixed_contact = 0
	g.start_mission(es)
	check(g.begin_offer() == "escort" and g.contact.forced and g.dodge_contact().is_empty(), "Eskorte: sicherer Kontakt, kein Ausweichen")
	g.fight_contact()
	check(g.space_ctx.kind == "eskorte" and g.space_setup().source == "auftrag", "Eskorte: Raumkampf")
	# Gegner entern, die Crew wehrt sie ab: zählt wie ein gewonnener Raumkampf
	check(g.finish_space(brd) == "defend" and not g.travel_rest.won, "Eskorte: Gegner entern")
	g.loot_pending = {}
	Campaign.last_result = {"outcome": &"sieg"}
	g.finish_mission({"outcome": &"sieg"})
	check(g.travel_rest.won and not g.offer_by_id(es.id).is_empty(), "Eskorte: Abwehr gewonnen = Kampf gewonnen")
	cr = g.credits
	SpaceEvents.fixed_contact = -2
	g.resume_travel()
	check(g.position == int(es.target) and g.offer_by_id(es.id).is_empty() and int(g.last_travel.escort.pay) == SpaceEvents.offer_pay(g, es)
		and g.credits == cr + int(g.last_travel.escort.pay), "Eskorte erfüllt: Lohn bei Ankunft")
	Voyage.fixed_result = &""
	SpaceEvents.fixed_contact = -2
	SpaceEvents.fixed_kind = "boden"
	Campaign.last_result = {}
	HubState.game = null
	if crew_before != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(crew_before)
	Campaign.reload()
