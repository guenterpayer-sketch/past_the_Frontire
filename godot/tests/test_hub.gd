extends SceneTree
## Tests des Schiffs (Hub) ohne Grafik: Sektor, Reisen, Aufträge, Spielstände.
## godot --headless --path godot --script res://tests/test_hub.gd

var fails := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FEHLER: ", what)


func _init() -> void:
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
	_test_gear_models()
	_test_training()
	_test_upgrades()
	_test_stock()
	_test_trade_skills()
	_test_loot()
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
	# große Reparatur durch die Crew: 1 Tag, 1 Material
	g.hull = 40
	g.material = 1
	var d0 := g.day
	var r := g.crew_repair()
	check(not r.is_empty() and g.day == d0 + 1 and g.material == 0 and g.hull == clampi(40 + int(Voyage.HULL_CREW[r.result]), 0, 100), "Crew-Reparatur (%s)" % r.get("result_name", ""))
	check(g.crew_repair().is_empty(), "ohne Material keine Crew-Reparatur")
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
		if not g.is_harbor(i):
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
		if not g.is_harbor(i):
			away = i
			break
	g.position = away
	g.credits = 1000
	check(not Stock.can_repair(g, k20), "Werkstatt nur im Raumhafen")
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
