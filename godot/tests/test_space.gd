extends SceneTree
## Regeltests Raumkampf ohne Grafik:
## godot --headless --path godot --script res://tests/test_space.gd

var fails := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FEHLER: ", what)


func _init() -> void:
	Dice.set_seed(4711)
	_test_catalog()
	_test_setup()
	_test_build()
	_test_arcs()
	_test_hit()
	_test_systems()
	_test_stations()
	_test_shields()
	_test_move()
	_test_end_states()
	_test_result()
	_test_tech()
	_test_board()
	_test_preview()
	_test_auto()
	print("OK" if fails == 0 else "%d FEHLER" % fails)
	quit(1 if fails > 0 else 0)


func _combat(seed_value := 1, faction := "piraten", diff := "mittel") -> SpaceCombat:
	var c := SpaceCombat.new(SpaceBattle.prepare(SpaceSetup.quick(diff, faction)), seed_value)
	c.start()
	return c


func _test_catalog() -> void:
	check(ShipWeapons.keys().size() == 8, "8 handelbare Schiffswaffen")
	check(not ShipWeapons.keys().has("jaegerkanone"), "Jägerkanone nicht im Handel")
	check(ShipWeapons.fits("abwehrgeschuetz", "turm") and ShipWeapons.fits("abwehrlaser", "turm2"), "Abwehr in Turm")
	check(not ShipWeapons.fits("laserbank", "turm"), "keine normale Waffe im Turm")
	check(not ShipWeapons.fits("abwehrgeschuetz", "bug"), "Abwehr nicht im Bug")
	check(ShipWeapons.fits("raketenwerfer", "heck"), "jede Waffe in normale Slots")
	check(ShipWeapons.ammo("laserbank") == "" and ShipWeapons.ammo("raketenwerfer") == "schiffsraketen", "Munition")
	for k in ShipWeapons.CATALOG:
		check(ShipWeapons.ART_SKILL.has(ShipWeapons.CATALOG[k].art), "Fertigkeit für %s" % k)
		var a := String(ShipWeapons.CATALOG[k].ammo)
		check(a == "" or ShipWeapons.AMMO_TYPES.has(a), "Munitionsart %s" % k)


func _test_setup() -> void:
	check(SpaceSetup.slots_for(0) == ["bug", "backbord", "steuerbord", "turm"], "Startslots")
	check(SpaceSetup.slots_for(1).has("heck") and SpaceSetup.slots_for(3).has("steuerbord2"), "Slots Stufe 1–3")
	check(SpaceSetup.slots_for(5).size() == 9 and SpaceSetup.slots_for(5).has("turm2"), "Slots Stufe 5")
	check(SpaceSetup.slots_for(9).size() == 9, "höchstens Stufe 5")
	for s in SpaceSetup.START_SLOTS:
		check(ShipWeapons.fits(SpaceSetup.START_SLOTS[s], s), "Startwaffe passt in %s" % s)
	var q := SpaceSetup.quick()
	for k in ["crew", "posts", "ship", "ship_ammo", "fuel", "credits", "enemy", "source", "mission", "return_scene"]:
		check(q.has(k), "setup hat %s" % k)
	check(q.crew.size() > 0, "Schnellkampf hat Crew")
	var sts := SpaceSetup.stations_for(q.ship.slots)
	check(sts.size() == 11, "5 Stationen + 4 Geschützstationen + 2 weitere Techniker")
	for st in sts:
		check(q.posts.has(st), "Posten für %s" % st)
	var p := SpaceBattle.prepare(q)
	check(p.crew[0] != q.crew[0] and p.crew[0].id == q.crew[0].id, "prepare macht Kopien")


func _test_build() -> void:
	for f in SpaceTemplates.FACTIONS:
		for d in ["leicht", "mittel", "schwer"]:
			var c := _combat(7, f, d)
			check(c.active_enemies().size() > 0, "Gegner für %s/%s" % [f, d])
			for s in c.ships:
				check(c.cells.has(s.pos) and not c.rocks.has(s.pos), "Startfeld frei (%s)" % s.name)
			var seen := {}
			for s in c.ships:
				check(not seen.has(s.pos), "kein Feld doppelt")
				seen[s.pos] = true
	for t in SpaceTemplates.SHIPS:
		for w in SpaceTemplates.SHIPS[t].weapons:
			check(ShipWeapons.has(w), "Waffe %s der Vorlage %s" % [w, t])


func _test_arcs() -> void:
	var c := _combat()
	var o := c.own
	o.pos = Vector2i(5, 5)
	o.facing = 0
	var ahead: Vector2i = o.pos + Hex.DIRS[0] * 3
	var behind: Vector2i = o.pos + Hex.DIRS[3] * 3
	var right: Vector2i = o.pos + Hex.DIRS[5] * 2 + Hex.DIRS[4] * 1   # Süden (Steuerbord bei Bug nach Osten)
	var left: Vector2i = o.pos + Hex.DIRS[1] * 2 + Hex.DIRS[2] * 1
	check(c.in_arc(o, "bug", ahead) and not c.in_arc(o, "bug", behind), "Bugbogen")
	check(c.in_arc(o, "heck", behind) and not c.in_arc(o, "heck", ahead), "Heckbogen")
	check(c.in_arc(o, "steuerbord", right) and not c.in_arc(o, "steuerbord", left), "Steuerbord rechts")
	check(c.in_arc(o, "backbord", left) and not c.in_arc(o, "backbord", right), "Backbord links")
	check(c.in_arc(o, "turm", behind) and c.in_arc(o, "turm", ahead), "Turm rundum")
	check(o.side_toward(ahead) == 0 and o.side_toward(behind) == 3, "Schildseite Bug/Heck")
	check(o.side_toward(left) in [1, 2] and o.side_toward(right) in [4, 5], "Schildseite links/rechts")


func _test_hit() -> void:
	var c := _combat()
	var o := c.own
	var e: SpaceShip = c.active_enemies()[0]
	o.pos = Vector2i(5, 5)
	o.facing = 0
	e.pos = o.pos + Hex.DIRS[0] * 2
	o.shields = [5, 5, 5, 5, 5, 5]
	o.armor = 1
	var hull := o.hull
	c._apply_hit(e, o, {"dmg": 8, "severity": ""})
	check(o.shields[0] == 0, "Bugschild fängt zuerst ab")
	check(o.hull == hull - 2, "Rest minus Panzerung auf die Hülle (8−5−1)")
	hull = o.hull
	c._apply_hit(e, o, {"dmg": 1, "severity": ""})
	check(o.hull == hull, "Panzerung schluckt kleinen Rest")
	e.hull = 3
	e.shields = [0, 0, 0, 0, 0, 0]
	e.armor = 0
	c._apply_hit(o, e, {"dmg": 5, "severity": ""})
	check(e.destroyed and not e.is_active(), "Gegner zerstört")


func _test_systems() -> void:
	var c := _combat()
	var o := c.own
	c._damage_system(o, "sensoren", "B")
	check(o.damage.sensoren == "B", "Systemschaden B")
	c._damage_system(o, "sensoren", "A")
	check(o.damage.sensoren == "B", "leichterer Treffer ändert nichts")
	c._damage_system(o, "sensoren", "B")
	check(o.damage.sensoren == "C", "gleiche Stufe verschlimmert")
	c._damage_system(o, "slot_bug", "C")
	check(int(o.slots.bug.damage) == -10, "Waffe im Slot beschädigt")
	c._damage_system(o, "slot_bug", "E")
	check(c.fire_problem(o, "bug", c.active_enemies()[0]) == "Waffe ausgefallen", "Slot E = ausgefallen")
	c._damage_system(o, "reaktor", "C")
	check(c.reactor_energy() == SpaceSetup.REACTOR_ENERGY[0] - SpaceCombat.REACTOR_LOSS[3], "Reaktorschaden kostet Energie")
	c._damage_system(o, "schilde", "E")
	check(o.shield_total() == 0, "Schilde E = alle Schilde weg")
	c._damage_system(o, "antrieb", "E")
	check(c.max_speed_of(o) == 0, "Antrieb E = steht")


func _test_stations() -> void:
	var c := _combat()
	var ch: Character = c.crew[0]
	c.posts["steuer"] = String(ch.id)
	c.posts["navigation"] = String(ch.id)
	var mods := c.station_mods("steuer")
	check(mods.any(func(m: Dictionary) -> bool: return m.val == SpaceSetup.DOUBLE_MALUS), "Doppelbesetzung −30")
	c.posts["navigation"] = SpaceSetup.KI
	check(c.station_bonus("navigation", &"navigation") == SpaceSetup.KI_BONUS, "Bord-KI +20")
	c.people[String(ch.id)].state = "ko"
	check(c.station_who("steuer") == null, "Ausgefallene: Bord-KI übernimmt")
	c.people[String(ch.id)].state = "ok"
	c._damage_system(c.own, "station_steuer", "C")
	check(c.station_mods("steuer").any(func(m: Dictionary) -> bool: return m.label == "Station beschädigt"),
		"Stationsschaden als Malus")
	ch.xp_log = {}
	var before: int = ch.xp_log.size()
	c.check("steuer", &"pilot", "mittel")
	check(ch.xp_log.size() >= before, "Probe läuft über Rules.maneuver")
	var r: Dictionary = c.check("computer", &"computer", "mittel")
	check(r.has("result") and r.has("total"), "Bord-KI-Probe")
	c._hurt(ch, "E")
	check(c.people[String(ch.id)].worst_crit == "E", "Verletzung an der Station")


func _test_shields() -> void:
	var c := _combat()
	var o := c.own
	o.shields = [0, 0, 0, 0, 0, 0]
	c._add_shields(o, 12, [])
	check(o.shield_total() == 12 and o.shields.max() - o.shields.min() <= 1, "Aufladung auf die schwächsten Seiten")
	c._add_shields(o, 6, [10, 4, 0, 0, 0, 4])
	check(o.shields == [10, 4, 0, 0, 0, 4], "Verteilung nach Wunsch")
	c._add_shields(o, 0, [10, 10, 10, 10, 10, 10])
	check(o.shield_total() <= 18, "Verteilung nicht über den Vorrat")
	c.set_orders({"energy": {"shields": 99}})
	c.resolve()
	check(c.energy.shields <= c.energy_total and c.phase == SpaceCombat.Phase.MOVE, "Energie gedeckelt, weiter zu Bewegen")


func _test_move() -> void:
	var c := _combat()
	var o := c.own
	c.rocks = {}
	for e in c.enemies():
		e.pos = Vector2i(40, 40)
	o.pos = Hex.from_offset(5, 6)
	o.facing = 0
	o.speed = 2
	var pv := c.plan_path(o, ["F", "L", "F"])
	check(pv.path.size() == 2 and pv.facing == 1, "Plan: vor, links, vor")
	var trimmed := c._trim_plan(o, 6, ["L", "L", "L", "F"], 1, 1, 0)
	check(trimmed.count("F") == 2 and trimmed.count("L") == 1, "Plan gekürzt: Tempo ±1, Energie, Drehungen")
	c.rocks[o.pos + Hex.DIRS[0]] = true
	pv = c.plan_path(o, ["F", "F"])
	check(pv.blocked and pv.path.is_empty(), "Asteroid blockiert")


func _test_end_states() -> void:
	var c := _combat(3, "piraten")
	c.setup.credits = 10000
	check(c.can_surrender(), "Piraten nehmen Lösegeld")
	check(c.surrender() and c.result == &"niederlage" and c.surrendered, "Kapitulation")
	check(int(c.to_result().ransom.credits) == 400, "Lösegeld im Ergebnis")
	c = _combat(3, "militaer")
	c.setup.credits = 10000
	check(not c.can_surrender(), "Militär nimmt kein Lösegeld")
	c.own.hull = 0
	c._check_end()
	check(c.result == &"niederlage" and c.emergency and not c.boarding, "Militär: Notfall")
	c = _combat(3, "piraten")
	c.own.hull = 0
	c._check_end()
	check(c.boarding and c.to_result().boarding_faction == "piraten", "Piraten: Entern")
	c = _combat(3)
	c.jump_progress = SpaceCombat.JUMP_ROUNDS
	c._end_round()
	check(c.retreated and c.result == &"niederlage" and c.fuel_used == SpaceCombat.JUMP_FUEL, "Flucht per Sprung")
	c = _combat(3)
	for e in c.enemies():
		e.destroyed = true
	c._check_end()
	check(c.result == &"sieg" and c.to_result().ship_loot.has("credits"), "Sieg mit Beute")


func _test_result() -> void:
	var c := _combat(5)
	c.run_auto()
	var r := c.to_result()
	for k in ["outcome", "retreated", "mission", "rounds", "units", "space", "surrendered", "ransom", "boarding",
			"emergency", "ship", "ship_ammo_used", "fuel_used", "ship_loot"]:
		check(r.has(k), "Ergebnis hat %s" % k)
	check(r.units.size() == c.crew.size(), "Einheiten für jede Figur")
	for id in r.units:
		var u: Dictionary = r.units[id]
		var inj := Injury.from_result(u)
		check(inj.has("stage"), "Verwundung lesbar")
	var ch: Character = c.crew[0].duplicate_character()
	ch.apply_result(r.units[c.crew[0].id])
	check(ch.free_xp >= MissionResult.FREE_XP, "apply_result verbucht freie EP")
	var js := JSON.stringify(r.ship)
	check(JSON.parse_string(js) is Dictionary, "Schiffsteil als JSON speicherbar")


func _test_tech() -> void:
	var c := _combat(11)
	var a: Character = c.crew[0]
	var b: Character = c.crew[1]
	c.posts["technik"] = String(a.id)
	c.posts["technik_2"] = String(b.id)
	c.posts["technik_3"] = SpaceSetup.KI
	check(c.tech_active("technik") and c.tech_active("technik_2") and not c.tech_active("technik_3"),
		"weitere Techniker nur mit Crew")
	c.own.damage = {"sensoren": "C", "antrieb": "B", "reaktor": "A"}
	var t := c.tech_tasks({"technik": {"technik": [{"repair": "sensoren"}, {"repair": "reaktor"}],
		"technik_2": [{"repair": "antrieb"}], "technik_3": [{"patch": true}]}})
	check(t.size() == 2 and t.technik.size() == 2, "Aufgaben je Techniker, freie Station ohne Aufgabe")
	check(c.tech_tasks({"technik": {"repair": "sensoren"}}).has("technik"), "altes Format geht weiter")
	var rolls := []
	c.rolled.connect(func(r: Dictionary, label: String) -> void: rolls.append(label))
	c.phase = SpaceCombat.Phase.TECH
	c._do_tech(c.own, {"technik": {"technik": [{"repair": "sensoren"}, {"repair": "reaktor"}],
		"technik_2": [{"repair": "antrieb"}]}})
	check(rolls.filter(func(l: String) -> bool: return l.contains("Technik")).size() == 3, "drei Reparaturproben")


func _test_board() -> void:
	var c := _combat(12, "piraten", "leicht")
	var e: SpaceShip = null
	for s in c.enemies():
		if not s.is_fighter() and e == null:
			e = s
		elif s != e:
			s.destroyed = true
	if e == null:
		e = SpaceTemplates.make("korvette", 0)
		e.id = "gx"
		c.ships.append(e)
		for s in c.enemies():
			if s != e:
				s.destroyed = true
	e.pos = c.own.pos + Hex.DIRS[0]
	check(not c.can_board(e), "heile Schiffe nicht enterbar")
	e.hull = e.hull_max / 5
	check(c.can_board(e), "Hülle unter 25 % und benachbart: enterbar")
	e.pos = c.own.pos + Hex.DIRS[0] * 3
	check(not c.can_board(e), "nicht benachbart")
	e.pos = c.own.pos + Hex.DIRS[0]
	e.hull = e.hull_max
	e.damage["antrieb"] = "E"
	check(c.can_board(e), "Antrieb E: enterbar")
	var j := SpaceTemplates.make("jaeger", 1)
	j.id = "gj"
	j.pos = c.own.pos + Hex.DIRS[2] * 4
	c.ships.append(j)
	check(not c.can_board(e), "nur wenn kein anderer Gegner mehr kämpft")
	check(not c.can_board(j), "Jäger nicht enterbar")
	j.destroyed = true
	check(c.board(e) and c.result == &"sieg", "Entern beendet den Raumkampf")
	var r := c.to_result()
	check(r.board_enemy and r.board_faction == "piraten" and r.board_loot.has("credits"), "Entern im Ergebnis")


func _test_preview() -> void:
	var c := _combat(13)
	var pred := c.predict_enemies()
	check(pred.size() == c.active_enemies().size(), "Schätzung für jeden Gegner")
	var pos := c.own.pos
	var pf := c.preview_fire(pos + Hex.DIRS[0], 0, pred)
	check(c.own.pos == pos and pf.size() == c.own.weapon_slots().size(), "Ziel-Check ändert nichts")
	for d in ["leicht", "mittel", "schwer"]:
		for i in 6:
			var g := SpaceTemplates.pick_group("piraten", d, RandomNumberGenerator.new())
			if d == "mittel":
				check(g[0] == "korvette" and g.count("jaeger") in [1, 2], "mittel: Korvette mit 1 oder 2 Jägern")


func _test_auto() -> void:
	var wins := 0
	var n := 0
	for f in ["piraten", "militaer", "drohnen", "rote_sonne"]:
		for d in ["leicht", "mittel", "schwer"]:
			for i in 3:
				var c := _combat(100 + n, f, d)
				c.run_auto()
				n += 1
				check(c.result != &"", "Kampf endet (%s/%s)" % [f, d])
				if c.result == &"sieg":
					wins += 1
	print("Selbstlauf: %d von %d Kämpfen gewonnen" % [wins, n])
