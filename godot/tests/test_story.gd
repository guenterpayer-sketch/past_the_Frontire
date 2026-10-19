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
	_test_templates()
	_test_kapitel1()
	_test_rate_and_backlash()
	_test_items_and_keys()
	_test_events_and_harbor()
	Voyage.fixed_result = &""
	Story.fixed_travel = -1
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
	for id in ["kapitel1", "glaeubiger_rate", "rueck_zins", "rueck_pfaendung", "rueck_gefangen", "rueck_verfolgung", "kapitel1_finale"]:
		check(StoryData.chains().has(id), "Kette %s geladen" % id)
	check(StoryData.templates().size() == 8, "8 Vorlagen geladen (%d)" % StoryData.templates().size())
	for id in StoryData.chains():
		var err := StoryData.validate(StoryData.chain(id))
		check(err.is_empty(), "Kette %s gültig: %s" % [id, err])
	var bad := {"id": "x", "kind": "haupt", "trigger": {"type": "auftrag"}, "start": "a", "scenes": {"a": {"choices": [
		{"text": "?", "next": "fehlt", "check": {"skill": "ueberreden"}, "requires": [{"kampfrang": 5}]}]}}}
	var err2 := StoryData.validate(bad)
	check(err2.size() == 3, "kaputte Kette: Sprung, Fertigkeit, Bedingung gemeldet (%d)" % err2.size())
	var b := StoryData.bausteine()
	check(b.ausgangslage.size() == 4 and b.glaeubiger.size() == 3 and b.konzern.size() == 2 and b.hand.size() == 2, "Bausteine 4 × 3, Konzern, Hand")


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
	s.state.chains.kapitel1 = {"status": "fertig", "scene": "", "place": -1}   # Kapitel 1 (ab Tag 3) hier nicht mitspielen
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
	Story.fixed_travel = 0
	check(s.travel_event() == "" and s.contacts().is_empty(), "keine Reise-/Kontakt-Ketten in den Testdaten")
	Story.fixed_travel = -1
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


## alle Texte einer Kette nach text_of ohne offene Platzhalter
func _no_tokens(s: Story, id: String) -> bool:
	var c := s.chain_of(id)
	var texts: Array = [c.get("title", ""), c.get("contact", "")]
	for sid in c.scenes:
		var sc: Dictionary = c.scenes[sid]
		texts.append(sc.get("title", ""))
		texts.append(sc.get("text", ""))
		for ch in sc.get("choices", []):
			texts.append(ch.get("text", ""))
			for r in ch.get("results", {}).values():
				texts.append(r.get("text", ""))
	for t in texts:
		var out := s.text_of(t)
		if out.contains("{") or out.contains("}"):
			printerr("offener Platzhalter in %s: %s" % [id, out])
			return false
	return true


func _test_templates() -> void:
	var g := HubState.new_game(99, "Test", 0)
	var s := Story.create(null, g)
	s.crew_override = [_crew_member("Mara", 5)]
	for tid in StoryData.templates():
		for i in 12:
			var id := StoryGen.make(s, tid, {"frame": "kapitel1"} if i % 2 == 0 else {})
			var c := s.chain_of(id)
			var err := StoryData.validate(c)
			if not err.is_empty():
				check(false, "erzeugte Kette %s gültig: %s" % [tid, err])
				return
			if not _no_tokens(s, id):
				check(false, "erzeugte Kette %s ohne offene Platzhalter" % tid)
				return
			var e: Dictionary = s.state.chains[id]
			var tt := String(c.trigger.type)
			if tt == "kontakt" and (e.place < 0 or not g.is_harbor(e.place)):
				check(false, "Kontakt liegt in einem Hafen")
				return
			if tt == "ort" and (e.place < 0 or e.place == g.position):
				check(false, "Story-Ort nicht am Standort")
				return
	check(true, "Vorlagen erzeugen gültige Ketten")
	var seen := {}
	for i in 40:
		seen[s.chain_of(StoryGen.make(s, "wrack")).ausgang] = true
	check(seen.size() == 4, "alle vier Ausgänge des Wracks kommen vor")
	var resc := s.chain_of(StoryGen.make(s, "befreien", {"rescue": "Mara", "rescue_name": "Mara"}))
	check(String(resc.title) == "Befreiung: Mara", "Befreiung eines Crewmitglieds: %s" % resc.title)


## Kapitel 1 ganz durchspielen: Start ab Tag 3, Schritte erzeugen, Spuren, Finale
func _test_kapitel1() -> void:
	Voyage.fixed_result = &"erfolg"
	var s := _story(0)
	s.day = 2
	check(s.on_day().is_empty(), "Kapitel 1 nicht vor Tag 3")
	s.day = 3
	check(s.on_day() == ["kapitel1"], "Kapitel 1 beginnt an Tag 3")
	check(s.state.goals.schulden.target == 5000 and s.state.goals.schulden.due == 13 and s.state.goals.schulden.rate == 500, "Schulden 5000, Rate 500 an Tag 13")
	var need: int = s.state.goals.spuren.target
	check(need >= 3 and need <= 4, "Spuren 3–4 (%d)" % need)
	check(_no_tokens(s, "kapitel1"), "Kapitel 1 ohne offene Platzhalter")
	s.choose("kapitel1", 0)
	check(s.state.status("kapitel1") == "fertig" and s.state.generated.size() == 1, "Anfang erzeugt den ersten Schritt")
	var guard := 0
	while not s.state.goals.spuren.done and guard < 20:
		guard += 1
		var id := _open_step(s)
		if id == "":
			check(false, "kein offener Schritt")
			return
		s.start(id)
		_play_step(s, id, guard % 3 != 0)
	check(s.state.goals.spuren.done and s.state.flags.has("kapitel1_spuren"), "Spuren voll (%d Schritte)" % guard)
	check(s.state.status("kapitel1_finale") == "bekannt" and s.offers().is_empty(), "Finale bekannt, aber noch gesperrt")
	check(s.open_chains().any(func(c: Dictionary) -> bool: return c.chain == "kapitel1_finale" and c.reason.contains("Schiffsausbau 2")), "Logbuch zeigt, was fehlt")
	s.res.ship_level = 2
	check(s.offers().size() == 1 and s.offers()[0].chain == "kapitel1_finale", "Finale in der Auftragsliste")
	s.start("kapitel1_finale")
	var r := s.choose("kapitel1_finale", 0)
	check(r.mission.difficulty == "schwer", "Finale frontal: schwer")
	s.mission_done("niederlage")
	check(s.current_scene_id("kapitel1_finale") == "zurueck", "Niederlage: zurückgeschlagen")
	s.choose("kapitel1_finale", 0)
	r = s.choose("kapitel1_finale", 1)
	check(s.current_scene_id("kapitel1_finale") == "drin", "Wartungsschächte bei Erfolg")
	r = s.choose("kapitel1_finale", 0)
	check(r.mission.difficulty == "mittel", "eingeschlichen: mittel")
	s.mission_done("sieg")
	var c0: int = s.res.credits
	s.choose("kapitel1_finale", 1)
	check(s.state.flags.has("k2_hirten") and s.res.credits == c0 + 600 and s.state.status("kapitel1_finale") == "fertig", "Lio zu den Hirten")
	Voyage.fixed_result = &""


func _open_step(s: Story) -> String:
	for id in s.state.generated:
		if s.state.status(id) == "bekannt" and s.chain_of(id).has("frame"):
			return id
	return ""


## Schritt spielen: Kampf (Sieg/Niederlage) oder Gespräch (Probe nach Voyage.fixed_result)
func _play_step(s: Story, id: String, win: bool) -> void:
	Voyage.fixed_result = &"erfolg" if win else &"fehlschlag"
	var r := s.choose(id, 0)
	if not r.mission.is_empty():
		s.mission_done("sieg" if win else "niederlage")
	s.choose(id, 0)
	Voyage.fixed_result = &"erfolg"


func _test_rate_and_backlash() -> void:
	var s := _story(2000)
	s.day = 3
	s.on_day()
	s.choose("kapitel1", 0)
	check(s.contacts().any(func(c: Dictionary) -> bool: return c.chain == "glaeubiger_rate"), "Rate zahlen als Kontakt")
	s.start("glaeubiger_rate")
	s.choose("glaeubiger_rate", 0)
	check(s.res.credits == 1500 and s.state.goals.schulden.value == 500 and s.state.goals.schulden.paid == 500, "Rate gezahlt")
	check(s.state.status("glaeubiger_rate") == "" and s.contacts().any(func(c: Dictionary) -> bool: return c.chain == "glaeubiger_rate"), "Rate wiederholbar")
	s.day = 14
	check(s.on_day().is_empty() and s.state.goals.schulden.due == 23 and s.state.goals.schulden.paid == 0, "Rate pünktlich: kein Rückschlag, nächste Frist Tag 23")
	s.day = 24
	var hit := s.on_day()
	check(hit.size() == 1 and String(hit[0]).begins_with("rueck_"), "Rate verpasst: Rückschlag %s" % [hit])
	# Rückschläge einzeln
	s.state.chains.erase("rueck_zins")
	s.start("rueck_zins")
	var t0: int = s.state.goals.schulden.target
	s.choose("rueck_zins", 0)
	check(s.state.goals.schulden.target == t0 + roundi((t0 - 500) * 0.1), "Strafzins +10 % der Restschuld")
	s.res.credits = 1000
	s.res.material = 5
	s.res.stock = {"medkit": 1}
	s.state.chains.erase("rueck_pfaendung")
	s.start("rueck_pfaendung")
	s.choose("rueck_pfaendung", 0)
	check(s.res.credits == 750 and s.res.material == 3 and s.item_count("medkit") == 0, "Pfändung: −25 % Credits, −2 Material, ein Stück aus dem Lager")
	s.state.chains.erase("rueck_gefangen")
	s.start("rueck_gefangen")
	s.choose("rueck_gefangen", 0)
	check(s.state.captured.size() == 1 and s.crew().size() == 1, "Crew gefangen und gesperrt")
	var rid := ""
	for id in s.state.generated:
		if s.state.generated[id].has("rescue"):
			rid = id
	check(rid != "", "Befreiung erzeugt")
	s.start(rid)
	_play_step(s, rid, true)
	check(s.state.captured.is_empty() and s.crew().size() == 2, "befreit und wieder an Bord")
	s.state.chains.erase("rueck_verfolgung")
	s.start("rueck_verfolgung")
	s.choose("rueck_verfolgung", 0)
	check(s.state.flags.has("kopfgeld"), "Kopfgeld ausgesetzt")
	# Schuld ganz bezahlt: Gefangene frei
	s.state.captured.append("Jax")
	s._goal_effect({"goal": "schulden", "add": 99999}, {"effects": []})
	check(s.state.goals.schulden.done and s.state.captured.is_empty(), "Schulden getilgt: Gefangene frei")


func _test_items_and_keys() -> void:
	var s := _story()
	check(s.blocked_reason([{"item": "medkit"}]) == "braucht: 1 × Medikit im Lager", "Lager-Bedingung")
	s._apply("x", [{"item": "res://data/weapons/sturmgewehr.tres", "add": 1}, {"item": "medkit", "add": 2}], {"effects": []})
	check(s.item_count("medkit") == 2 and s.blocked_reason([{"item": "medkit", "count": 2}]) == "", "Gegenstände ins Lager")
	s._apply("x", [{"item": "medkit", "take": 5}], {"effects": []})
	check(s.item_count("medkit") == 0 and s.item_count("res://data/weapons/sturmgewehr.tres") == 1, "nehmen höchstens, was da ist")
	check(s.blocked_reason([{"crew_ranks": 10}]) == "" and s.blocked_reason([{"crew_ranks": 11}]) != "", "Crew-Ränge (Summe 10)")
	check(s.blocked_reason([{"day": 1}]) == "" and s.blocked_reason([{"day": 2}]) == "ab Tag 2", "Tag-Bedingung")
	var g := HubState.new_game(5, "Test", 0)
	var gs := Story.create(null, g)
	g.upgrades = {"a": 2, "b": 1}
	check(gs.ship_level() == 3, "Schiffsausbau = Summe der Stufen")
	gs.item_add("medkit", 1)
	check(Stock.count(g, "medkit") == 1 and gs.item_count("medkit") == 1, "Lager im Spiel über Stock")


func _test_events_and_harbor() -> void:
	var g := HubState.new_game(77, "Test", 0)
	var s := Story.create(null, g)
	s.crew_override = [_crew_member("Mara", 5), _crew_member("Jax", 2)]
	Story.fixed_travel = 1
	var id := s.travel_event()
	check(id != "" and s.state.status(id) == "aktiv" and s.chain_of(id).template in Story.TRAVEL_EVENTS, "Reise: Ereigniskette erzeugt und gestartet")
	check(s.travel_event() == "", "höchstens eine Reise-Ereigniskette offen")
	Story.fixed_travel = 0
	check(s.travel_event() == "", "fixed_travel 0: nichts")
	Story.fixed_travel = -1
	s.state.flags.kopfgeld = true
	var hid := s.on_arrive(g.sector.home)
	check(hid != "" and s.chain_of(hid).template == "hinterhalt" and s.state.status(hid) == "aktiv" and not s.state.flags.has("kopfgeld"), "Kopfgeldjäger im Hafen")
	var tries := 0
	while not s._event_open(Story.HARBOR_EVENTS) and tries < 60:
		tries += 1
		s.on_arrive(g.sector.home)
	check(s._event_open(Story.HARBOR_EVENTS), "Schmuggel-Kontakt im Hafen")
	check(s.contacts().any(func(c: Dictionary) -> bool: return s.chain_of(c.chain).get("template", "") == "schmuggel"), "Schmuggel unter den Kontakten")
