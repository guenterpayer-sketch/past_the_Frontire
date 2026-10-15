extends SceneTree
## Tests des Schiffs (Hub) ohne Grafik: Sektor, Reisen, Aufträge, Spielstände.
## godot --headless --path godot --script res://tests/test_hub.gd

var fails := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FEHLER: ", what)


func _init() -> void:
	_test_sector()
	_test_travel_and_offers()
	_test_mission_faction()
	_test_save_slots()
	_test_medbay_and_harbor()
	_test_ui_scale()
	print("OK" if fails == 0 else "%d FEHLER" % fails)
	quit(1 if fails else 0)


func _test_sector() -> void:
	var a := Sector.generate(4711)
	var b := Sector.generate(4711)
	check(a.to_dict() == b.to_dict(), "gleicher Seed = gleicher Sektor")
	check(a.systems.size() == Sector.SYSTEM_COUNT, "Anzahl Systeme")
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
		check(fset.size() == Mission.all_factions().size(), "Seed %d: jede Fraktion hat Systeme" % seed_value)
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
	check(SaveSlots.latest() == 0 and SaveSlots.info(1).is_empty(), "keine Spielstände")
	var crew_before := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	var g := HubState.new_game(99, "Erster", 2)
	g.day = 7
	check(SaveSlots.save(2, "Erster", g), "speichern")
	var i := SaveSlots.info(2)
	check(i.name == "Erster" and i.day == 7 and i.system == g.sector.systems[g.position].name, "Kurzinfo des Slots")
	check(SaveSlots.latest() == 2, "Fortsetzen = zuletzt gespeichert")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSlots.path(2)))
	check(raw.keys().all(func(k: String) -> bool: return k in ["version", "name", "saved_at", "game", "crew"]), "Spielstand ohne Roster (roster.json gehört nicht in die Slots)")
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
	check(Medbay.blocked_ids(g) == [best.id] and HubState.blocked_ids() == [best.id], "Arzt gesperrt für die Truppwahl")
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
