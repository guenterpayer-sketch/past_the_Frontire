extends SceneTree
## Tests der Story-Engine ohne Grafik: Daten, Szenen, Proben, Bedingungen, Folgen, Ziele, Einhängepunkte, Speichern.
## godot --headless --path godot --script res://tests/test_story.gd

var fails := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FEHLER: ", what)


func _init() -> void:
	_test_data()
	_test_start_and_texts()
	_test_conditions()
	_test_checks()
	_test_goals_and_backlash()
	_test_mission()
	_test_places_and_hooks()
	_test_save()
	Voyage.fixed_result = &""
	print("OK" if fails == 0 else "%d FEHLER" % fails)
	quit(1 if fails else 0)


func _crew_member(n: String, verhandeln: int, psi := false) -> Character:
	var ch := Character.new()
	ch.id = StringName(n)
	ch.name = n
	for a in Rules.ATTRIBUTES:
		ch.attrs[a.id] = 50
	ch.skills[&"verhandeln"] = {"rank": verhandeln, "xp": 0}
	if psi:
		ch.skills[&"lWahrnehmung"] = {"rank": 1, "xp": 0}
	return ch


func _story(credits := 3000) -> Story:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := Story.create(StoryState.create(rng))
	s.res.credits = credits
	s.crew_override = [_crew_member("Mara", 8), _crew_member("Jax", 2)]
	return s


func _test_data() -> void:
	StoryData.reload()
	check(StoryData.chains().has("test_kette") and StoryData.chains().has("test_ort"), "Test-Ketten geladen")
	for id in StoryData.chains():
		var err := StoryData.validate(StoryData.chain(id))
		check(err.is_empty(), "Kette %s gültig: %s" % [id, err])
	var bad := {"id": "x", "kind": "haupt", "trigger": {"type": "auftrag"}, "start": "a", "scenes": {"a": {"choices": [
		{"text": "?", "next": "fehlt", "check": {"skill": "ueberreden"}, "requires": [{"kampfrang": 5}]}]}}}
	var err2 := StoryData.validate(bad)
	check(err2.size() == 3, "kaputte Kette: Sprung, Fertigkeit, Bedingung gemeldet (%d)" % err2.size())
	var b := StoryData.bausteine()
	check(b.ausgangslage.size() == 4 and b.glaeubiger.size() == 3, "Bausteine 4 × 3")


func _test_start_and_texts() -> void:
	var s := _story()
	check(s.state.vars.has("ausgangslage") and s.state.vars.has("glaeubiger"), "Start würfelt Ausgangslage und Gläubiger")
	var seen := {}
	for i in 60:
		var rng := RandomNumberGenerator.new()
		rng.seed = i
		seen[StoryState.create(rng).vars.ausgangslage] = true
	check(seen.size() == 4, "alle vier Ausgangslagen kommen vor")
	check(s.offers().is_empty(), "Test-Ketten werden nicht als Auftrag angeboten")
	check(s.start("test_kette") and not s.start("test_kette"), "Kette startet einmal")
	var v := s.view("test_kette")
	var gl: String = StoryData.bausteine().glaeubiger[s.state.vars.glaeubiger].name
	check(v.text.contains("(%s)" % gl), "Baustein im Text ersetzt: %s" % v.text)
	s.state.vars.ausgangslage = "pump"
	check(s.view("test_kette").text.contains("erst, wenn es bezahlt ist"), "Textvariante je Ausgangslage")
	s.state.vars.ausgangslage = "fracht"
	check(s.view("test_kette").text.contains("warum ich hier bin"), "Textvariante „*“ als Ersatz")
	check(s.state.goals.schulden.due == s.today() + 5, "Ziel mit Frist angelegt")


func _test_conditions() -> void:
	var s := _story(1000)
	s.start("test_kette")
	var c: Array = s.view("test_kette").choices
	check(c.size() == 5, "fünf Wahlen sichtbar")
	check(not c[0].enabled and c[0].reason.contains("2000 Credits"), "Rate zahlen gesperrt ohne Credits: %s" % c[0].reason)
	check(not c[3].enabled and c[3].reason == "braucht: Liste Wahrnehmung", "Psi-Wahl gesperrt ohne Psi-Liste")
	check(c[1].check.skill_name == "Verhandeln" and c[1].check.diff_name == "Mittel", "Probe angezeigt")
	check(not s.choose("test_kette", 0).ok, "gesperrte Wahl geht nicht")
	s.crew_override.append(_crew_member("Ivo", 0, true))
	s.res.credits = 2500
	c = s.view("test_kette").choices
	check(c[0].enabled and c[3].enabled, "Wahlen frei mit Credits und Psi")
	var r := s.choose("test_kette", 0)
	check(r.ok and s.res.credits == 500 and s.state.goals.schulden.value == 2000, "Rate bezahlt: Credits und Ziel")
	check(s.current_scene_id("test_kette") == "ende", "weiter zur Szene „ende“")
	r = s.choose("test_kette", 0)
	check(r.ended == "fertig" and s.state.status("test_kette") == "fertig", "Kette beendet")
	check(s.blocked_reason([{"skill": "verhandeln", "rank": 9}]) == "braucht: Verhandeln Rang 9", "Rangbedingung")
	check(s.blocked_reason([{"skill": "verhandeln", "rank": 8}]) == "", "Rangbedingung erfüllt")
	s.state.flags.x = true
	check(s.blocked_reason([{"flag": "x"}, {"not_flag": "y"}]) == "" and s.blocked_reason([{"not_flag": "x"}]) != "", "Flags")


func _test_checks() -> void:
	var s := _story()
	s.start("test_kette")
	var opts := s.roller_options(&"verhandeln")
	check(opts[0].ch.name == "Mara" and opts[0].total > opts[1].total, "Bester zuerst")
	Voyage.fixed_result = &"herausragend"
	var due0: int = s.state.goals.schulden.due
	var jax: Character = s.crew_override[1]
	var r := s.choose("test_kette", 1, jax)
	check(r.check.name == "Jax" and r.check.result == &"herausragend", "gewählter Würfler")
	check(s.state.flags.has("aufschub") and s.state.goals.schulden.due == due0 + 5, "Herausragend nutzt Zweig „erfolg“")
	check(Rules.skill_rank(jax, &"verhandeln") == 2 and int(jax.skills[&"verhandeln"].xp) == 2, "EP auf die benutzte Fertigkeit")
	var s2 := _story()
	s2.start("test_kette")
	Voyage.fixed_result = &"teilerfolg"
	r = s2.choose("test_kette", 1)
	check(r.check.name == "Mara" and s2.state.goals.schulden.target == 7000, "ohne Wahl würfelt der Beste; Teilerfolg → Zweig „fehlschlag“")
	Voyage.fixed_result = &"erfolg"
	var s3 := _story()
	s3.start("test_kette")
	r = s3.choose("test_kette", 2)
	check(s3.current_scene_id("test_kette") == "hafen" and s3.state.entries("hinweis").size() == 1, "Hinweis ins Logbuch, zurück zur Szene")
	check(s3.state.entries("verlauf").size() == 2, "Verlauf: Beginn und Wahl")
	Voyage.fixed_result = &""


func _test_goals_and_backlash() -> void:
	var s := _story()
	s.res.material = 5
	s.start("test_kette")
	s.day += 5
	check(s.on_day().is_empty(), "Frist noch nicht abgelaufen")
	s.day += 1
	check(s.on_day() == ["test_kette"], "Frist verpasst: Rückschlag")
	check(s.current_scene_id("test_kette") == "pfaendung", "Szene Pfändung")
	s.choose("test_kette", 0)
	check(s.res.credits == 2500 and s.res.material == 3, "Pfändung nimmt Credits und Material")
	check(s.state.goals.schulden.due == s.today() + 5, "neue Frist")
	s.res.credits = 0
	s.add_resource("credits", -10)
	check(s.res.credits == 0, "Ressourcen nicht unter 0")


func _test_mission() -> void:
	var s := _story()
	s.start("test_kette")
	var r := s.choose("test_kette", 4)
	check(r.mission.get("kind", "") == "boden" and s.state.status("test_kette") == "wartet", "Story-Einsatz wartet")
	check(s.pending_mission().chain == "test_kette", "Einsatz für den Hub abrufbar")
	check(not s.choose("test_kette", 0).ok, "keine Wahl während des Einsatzes")
	check(s.mission_done("rueckzug") == "test_kette" and s.current_scene_id("test_kette") == "hafen", "Rückzug → Szene hafen")
	check(s.pending_mission().is_empty() and s.state.status("test_kette") == "aktiv", "Einsatz abgeschlossen")


func _test_places_and_hooks() -> void:
	var s := _story()
	s.reveal("test_ort")
	check(s.state.status("test_ort") == "bekannt", "Kette bekannt")
	check(s.open_chains().size() == 1, "bekannte Kette im Logbuch")
	s.state.chains.test_ort.place = 3
	check(s.markers().size() == 1 and s.markers()[0].system == 3, "Story-Ort auf der Karte")
	check(s.on_arrive(2) == "" and s.on_arrive(3) == "test_ort", "Ankunft am Story-Ort startet die Kette")
	check(s.state.status("test_ort") == "aktiv" and s.markers().is_empty(), "Marker weg, Kette aktiv")
	check(s.travel_event() == "" and s.contacts().is_empty(), "keine Reise-/Kontakt-Ketten in den Testdaten")
	var g := HubState.new_game(4711, "Test", 0)
	var gs := Story.create(null, g)
	gs.crew_override = [_crew_member("Mara", 8)]
	var c0 := g.credits
	gs.add_resource("credits", 100)
	check(g.credits == c0 + 100 and gs.today() == g.day, "mit Spielstand: Credits und Tag aus dem Hub")
	check(gs.add_resource("credits", -(c0 + 300)) == -(c0 + 300) and g.credits == -200, "Credits dürfen unter 0 (HubState.apply_story)")
	g.material = 1
	check(gs.add_resource("material", -3) == -1 and g.material == 0, "Material nicht unter 0, tatsächliche Änderung zurück")
	g.fuel = 0
	check(gs.add_resource("fuel", 10000) == g.tank_max() and g.fuel == g.tank_max(), "Treibstoff höchstens Tankgröße")
	gs.reveal("test_ort")
	var p := int(gs.state.chains.test_ort.place)
	check(p >= 0 and p < g.sector.systems.size() and p != g.position, "Story-Ort im Sektor, nicht am Standort")
	check(g.story_engine() == g.story_engine() and g.story_engine().game == g, "HubState.story_engine() hält ein Story-Objekt je Spiel")


func _test_save() -> void:
	var s := _story()
	s.start("test_kette")
	Voyage.fixed_result = &"erfolg"
	s.choose("test_kette", 2)
	s.reveal("test_ort")
	var d := JSON.parse_string(JSON.stringify(s.state.to_dict())) as Dictionary
	var st := StoryState.from_dict(d)
	check(st.to_dict() == s.state.to_dict(), "Speichern/Laden über JSON gleich")
	check(st.goals.schulden.due is int and st.logbook[0].day is int, "Zahlen nach dem Laden ganzzahlig")
	Voyage.fixed_result = &""
