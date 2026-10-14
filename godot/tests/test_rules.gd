extends SceneTree
## Regeltests ohne Grafik (entsprechen tests/sim.js der HTML-Version):
## godot --headless --path godot --script res://tests/test_rules.gd

var fails := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FEHLER: ", what)


func _init() -> void:
	_test_rules()
	_test_dice()
	_test_cover()
	_test_facing()
	_test_wait_and_crouch()
	_test_stopped_move()
	_test_pass_through_ally()
	_test_data()
	_test_missions()
	_test_progress()
	_test_mission_result()
	_test_creation()
	_test_leveling()
	_test_roster()
	_test_deploy()
	print("OK" if fails == 0 else "%d FEHLER" % fails)
	quit(1 if fails else 0)


func _test_rules() -> void:
	check(Rules.rank_bonus(0) == -25 and Rules.rank_bonus(10) == 50 and Rules.rank_bonus(20) == 70 and Rules.rank_bonus(30) == 80, "Rangbonus")
	check(Rules.attr_bonus(50) == 0 and Rules.attr_bonus(100) == 30, "Eigenschaftsbonus")
	var proj: AttackTableData = load("res://data/tables/attack_projektil.tres")
	check(Tables.lookup_attack(proj, 89, 2, 1.0) == {"hit": false, "threshold": 90}, "89 verfehlt (Schwelle 90)")
	check(Tables.lookup_attack(proj, 129, 2, 1.0).severity == "", "129 kein Krit")
	check(Tables.lookup_attack(proj, 130, 2, 1.0).severity == "A", "130 Krit A")
	check(Tables.lookup_attack(proj, 145, 2, 1.0).severity == "B", "145 Krit B")
	check(Tables.lookup_attack(proj, 190, 2, 1.0).severity == "E", "190 Krit E")
	check(Tables.lookup_attack(proj, 90, 2, 1.0).dmg == 2, "90 = 2 Schaden")
	check([20, 50, 60, 70, 100].map(Combat.activity_mod) == [-40, -10, 0, 5, 20], "Aktivitätsmodifikator")


func _test_dice() -> void:
	Dice.set_seed(1)
	var cnt := {}
	for i in 100000:
		var v := Dice.d100()
		cnt[v] = cnt.get(v, 0) + 1
	check(not cnt.has(0), "keine 0")
	for v in range(1, 101):
		check(cnt.get(v, 0) > 800 and cnt.get(v, 0) < 1200, "W100-Wert %d: %d" % [v, cnt.get(v, 0)])
	var hi := 0
	var lo := 0
	for i in 100000:
		var r := Dice.open_d100(5 if i % 2 else 0)
		if r.dice.size() != r.rolls.size():
			check(false, "Würfelpaare passen nicht zu den Würfen")
		for k in r.dice.size():
			var p: Dictionary = r.dice[k]
			check((p.t * 10 + p.o if p.t * 10 + p.o else 100) == p.v and absi(r.rolls[k]) == p.v, "Würfelpaar")
		if i % 2 == 0:
			hi += 1 if r.total > 100 else 0
			lo += 1 if r.total < 1 else 0
	print("Offener W100: >100 in %.2f %%, <1 in %.2f %% (erwartet je ~5 %%)" % [hi / 500.0, lo / 500.0])


func _row_map(n: int) -> BattleMap:
	var m := BattleMap.new(n, 1)
	for q in n:
		m.add_floor(q, 0)
	return m


func _test_cover() -> void:
	var m := _row_map(10)
	var T := func(q: int) -> BattleMap.Tile: return m.tile(Vector2i(q, 0))
	T.call(3).terrain = &"barriere"
	check(m.cover(T.call(2), T.call(8)).get("level", 0) == 1, "Barriere = halbe Deckung")
	check(m.cover(T.call(2), T.call(8)).get("bonus", 0) == 40, "halbe Deckung +40")
	T.call(3).terrain = &"boden"
	T.call(4).terrain = &"barriere"
	check(m.cover(T.call(2), T.call(8)).get("level", 0) == 1, "Barriere 2 Felder vor dem Ziel zählt auch")
	check(m.cover(T.call(2), T.call(5)).is_empty(), "bei 3 Feldern Abstand zählt nur das Nachbarfeld")
	T.call(4).terrain = &"boden"
	T.call(3).terrain = &"barriere"
	check(m.line_of_sight(T.call(8), T.call(2)), "über halbe Deckung hinweg schießen")
	T.call(3).terrain = &"container"
	T.call(3).h = 2
	check(m.cover(T.call(2), T.call(8)).get("level", 0) == 2, "Container = volle Deckung")
	m.clear_cache()
	check(not m.line_of_sight(T.call(8), T.call(2)), "in einer Reihe kein Herausschauen")
	T.call(8).h = 3
	check(m.cover(T.call(2), T.call(8)).get("level", 0) == 2, "1 Stufe über dem Container: volle Deckung bleibt")
	T.call(8).h = 4
	check(m.cover(T.call(2), T.call(8)).get("level", 0) == 1, "2 Stufen über dem Container: halbe Deckung")


func _test_facing() -> void:
	var o := Vector2i.ZERO
	check(Hex.sector(o, 0, Vector2i(3, 0)) == &"vorne", "vorne")
	check(Hex.sector(o, 0, Vector2i(0, 3)) == &"vorne", "Südost liegt 60° neben Osten")
	check(Hex.sector(o, 0, Vector2i(-3, 3)) == &"flanke", "Südwest = Flanke")
	check(Hex.sector(o, 0, Vector2i(-3, 0)) == &"ruecken", "Westen = Rücken")
	for d in 6:
		check(Hex.dir_toward(o, Hex.DIRS[d]) == d, "dir_toward %d" % d)
	for p in [Vector2i(0, 0), Vector2i(5, 3), Vector2i(-4, 9)]:
		check(Hex.from_world(Hex.to_world(p)) == p, "Welt-Umrechnung %s" % p)


func _combat(m: BattleMap, n_crew := 6, n_enemy := 6) -> Combat:
	var crew := Roster.build_team(GameData.crew(), &"crew").slice(0, n_crew)
	var enemies := Roster.build_team(GameData.enemies(), &"enemy").slice(0, n_enemy)
	return Combat.new(m, crew, enemies)


func _test_wait_and_crouch() -> void:
	Dice.set_seed(7)
	var c := _combat(MapGenerator.generate(4711, "mittel"))
	c.start()
	var first := c.current
	var second := c.order[c.turn_idx + 1]
	check(c.do_wait(first), "Abwarten möglich")
	check(c.current == second, "nach dem Abwarten ist der Nächste dran")
	check(c.order[-1] == first, "Wartender steht am Ende")
	check(c.request_jump(first), "Einspringen anmelden")
	c.end_turn()
	check(c.current == first, "Einsprung direkt nach dem laufenden Zug")
	check(first.act == 90, "Abwarten kostet 10 %")
	check(not c.can_wait(first), "nur einmal pro Runde")
	var budget := c.move_budget(first, &"gehen")
	check(c.do_crouch(first) and first.crouched and first.act == 80, "Ducken kostet 10 %")
	check(c.move_budget(first, &"gehen") == floorf(8 * 0.5), "geduckt: 1 Hex je 20 %")
	check(not c.can_move(first, &"laufen"), "geduckt nicht laufen")
	check(budget > c.move_budget(first, &"gehen"), "geduckt langsamer")


func _start_maps(m: BattleMap, crew_q: Array, enemy_q: Array) -> void:
	for q in crew_q:
		m.crew_start.append(m.tile(Vector2i(q, 0)))
	for q in enemy_q:
		m.enemy_start.append(m.tile(Vector2i(q, 0)))


## Gestoppte Bewegung kostet nur den gelaufenen Teil
func _test_stopped_move() -> void:
	var m := _row_map(12)
	_start_maps(m, [0, 1, 2, 3, 4, 5], [11, 10, 9, 8, 7, 6])
	var c := _combat(m, 1, 1)
	c.start()
	var a := c.crew()[0]
	var e := c.enemies()[0]
	e.pos = Vector2i(11, 0)
	a.pos = Vector2i(0, 0)
	c.order.assign([a, e])
	c.turn_idx = 0
	c._begin_turn(a)
	a.free_hex = 0
	e.overwatch = {"weapon": e.weapon, "pct": 100}
	e.facing = 3
	# der Reaktionsschuss legt die Figur garantiert um
	c.rolled.connect(func(_r, _l) -> void: pass)
	c.attacked.connect(func(_u, t: Combatant, _w) -> void:
		t.hp = -100
		c._check_state(t))
	c.do_move(a, Vector2i(6, 0), &"gehen")
	check(a.pos.x == 1, "nach dem ersten Feld gestoppt (%d)" % a.pos.x)
	check(a.act == 90, "nur 1 Feld bezahlt (%d)" % a.act)


## Weg durch eine eigene Figur: Ziel direkt dahinter muss erreicht werden
func _test_pass_through_ally() -> void:
	var m := _row_map(8)
	_start_maps(m, [0, 1, 2, 3, 4, 5], [7, 6, 5, 4, 3, 2])
	var c := _combat(m, 2, 1)
	c.start()
	var a := c.crew()[0]
	var b := c.crew()[1]
	var e := c.enemies()[0]
	a.pos = Vector2i(0, 0)
	b.pos = Vector2i(1, 0)
	e.pos = Vector2i(7, 0)
	c.order.assign([a, b, e])
	c.turn_idx = 0
	c._begin_turn(a)
	var reach := c.move_range(a, &"gehen")
	check(not reach.has(Vector2i(1, 0)), "Feld der eigenen Figur ist kein Ziel")
	check(reach.has(Vector2i(2, 0)), "Feld dahinter ist erreichbar")
	check(reach.path_to(Vector2i(2, 0)) == [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], "Weg führt durch die eigene Figur")
	check(c.do_move(a, Vector2i(2, 0), &"gehen") and a.pos.x == 2, "Figur ist angekommen")


func _test_data() -> void:
	check(GameData.crew().units.size() == 6 and GameData.enemies().units.size() == 6, "6 gegen 6")
	check(GameData.weapons().size() == 9, "9 Waffen (%d)" % GameData.weapons().size())
	for t in GameData.crit_tables():
		check(t.rows.size() == 7, "Kritische Tabelle %s mit 7 Zeilen" % t.name)


## Missionsgenerator: Budget, Anzahl, eindeutige Kennungen, Abwechslung
func _test_missions() -> void:
	var kinds := {}
	var counts := {}
	for i in 60:
		var m := Mission.generate(1000 + i)
		var n := m.enemies.size()
		check(n >= Mission.MIN_ENEMIES and n <= Mission.MAX_ENEMIES, "Gegneranzahl %d" % n)
		var ids := {}
		var budget := 0
		for d in m.enemies:
			ids[d.id] = true
			budget += d.threat
		check(ids.size() == n, "eindeutige Kennungen")
		check(budget <= Mission.DIFFICULTIES[m.difficulty].budget, "Budget eingehalten (%d)" % budget)
		kinds[m.enemy_summary()] = true
		counts[n] = true
		var map := MapGenerator.generate(m.map_seed, m.size_id)
		var c := Combat.new(map, Roster.build_team(GameData.crew(), &"crew"), Roster.build_units(m.enemies, &"enemy"))
		var pos := {}
		for u in c.units:
			pos[u.pos] = true
		check(pos.size() == c.units.size(), "alle Figuren auf eigenen Feldern")
	check(kinds.size() >= 20, "verschiedene Gegnergruppen (%d)" % kinds.size())
	check(counts.size() >= 3, "verschiedene Gruppengrößen (%d)" % counts.size())
	var a := Mission.generate(77)
	var b := Mission.generate(77)
	check(a.enemy_summary() == b.enemy_summary() and a.title == b.title, "gleicher Seed = gleiche Mission")


## Freie EP, Eigenschaften steigern, Rangkauf mit Pool, Speichern und Laden
func _test_progress() -> void:
	var u := Roster.start_crew()[0]
	u.free_xp = 10
	var kon: int = u.attrs.KON
	var cost := Rules.attr_cost(kon)
	check(Rules.raise_attr(u, "KON") and u.attrs.KON == kon + 1 and u.free_xp == 10 - cost, "Eigenschaft +1 kostet %d" % cost)
	u.free_xp = 0
	check(not Rules.raise_attr(u, "KON"), "ohne freie EP keine Steigerung")
	var s := Rules.ensure_skill(u, &"kochen")
	s.xp = 6
	u.free_xp = 3
	check(not Rules.rank_up_with_pool(u, &"kochen"), "6 + 3 EP reichen nicht für 10")
	u.free_xp = 5
	check(Rules.rank_up_with_pool(u, &"kochen") and s.rank == 1 and s.xp == 0 and u.free_xp == 1, "fehlende 4 EP aus dem Pool")
	u.free_xp = 3
	check(Rules.deposit_xp(u, &"navigation", 5) == 3 and u.free_xp == 0 and u.skills[&"navigation"].xp == 3, "Einzahlen höchstens so viel wie da")
	check(Rules.deposit_xp(u, &"navigation", 1) == 0, "ohne freie EP kein Einzahlen")
	u.free_xp = 1
	check(Rules.next_bonus_step(70) == 71 and Rules.next_bonus_step(50) == 71, "nächste Bonusstufe")
	var backup := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	u.name = "Testname"
	Roster.save_crew([u])
	var loaded := Roster.load_crew()
	var w := loaded[0]
	check(loaded.size() == 1 and w.name == "Testname" and w.attrs.KON == kon + 1 and w.free_xp == 1 and w.skills[&"kochen"].rank == 1, "Charakter gespeichert und geladen")
	check(w.weapons.size() == u.weapons.size() and w.armor == u.armor and w.visual == u.visual and w.color.is_equal_approx(u.color), "Ausrüstung und Aussehen gespeichert")
	var v := Combatant.from_character(w, &"crew")
	check(v.max_hp == Rules.max_hp(w) and v.max_hp == 15 + (kon + 1) / 3, "TP aus gesteigerter KON")
	# alte Formate (Version 1: nur Fertigkeiten, Version 2: Fortschritt) werden auf die Startcrew gelegt
	var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({String(u.id): {"gewehre": {"rank": 9, "xp": 4}}}))
	f.close()
	loaded = Roster.load_crew()
	check(loaded.size() == 6 and loaded[0].skills[&"gewehre"].rank == 9 and loaded[0].free_xp == 0, "Speicherformat 1")
	f = FileAccess.open(Roster.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 2, "crew": {String(u.id): {"skills": {}, "attrs": {"KON": 77}, "free_xp": 4}}}))
	f.close()
	loaded = Roster.load_crew()
	check(loaded[0].attrs.KON == 77 and loaded[0].free_xp == 4, "Speicherformat 2")
	if backup != "":
		f = FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	else:
		Roster.reset()


## Schnittstelle Kampf ⇄ Charakter-Modul: Kampf arbeitet auf Kopien, Ergebnis wird verbucht
func _test_mission_result() -> void:
	var crew := Roster.start_crew()
	var ch := crew[0]
	var xp_before: int = Rules.ensure_skill(ch, &"kampfsinn").xp
	var c := Combat.new(MapGenerator.generate(4711, "klein"), Roster.build_crew(crew), Roster.build_units(Mission.generate(4711).enemies, &"enemy"))
	var u := c.crew()[0]
	Rules.award_xp(u, &"kampfsinn", 3)
	u.medkit -= 1
	u.hp = 2
	check(ch.skills[&"kampfsinn"].xp == xp_before, "Kampf ändert den Charakter nicht")
	for e in c.enemies():
		e.state = Combatant.State.DEAD
	c.check_end()
	var m := Mission.generate(4711)
	var r := MissionResult.from_combat(c, m)
	var ur: Dictionary = r.units[ch.id]
	check(r.outcome == &"sieg" and ur.xp[&"kampfsinn"] >= 3 and ur.free_xp == MissionResult.FREE_XP + m.reward_xp, "Ergebnis: EP und freie EP")
	check(ur.status.state == "ok" and ur.status.hp == 2 and ur.used.medkits == 1, "Ergebnis: Zustand und Verbrauch")
	var free_before := ch.free_xp
	ch.apply_result(ur)
	check(ch.skills[&"kampfsinn"].xp == xp_before + ur.xp[&"kampfsinn"] and ch.free_xp == free_before + ur.free_xp, "Ergebnis verbucht")
	check(ch.status.hp == 2 and ch.used.medkits == 1, "Zustand und Verbrauch gemerkt")
	var again := Combatant.from_character(ch, &"crew")
	check(again.hp == again.max_hp and again.medkit == ch.medkits, "nächster Kampf: volle TP und Ausrüstung (Heilung/Nachschub noch nicht gebaut)")


## Charaktererschaffung: Würfe, Punkte, Ranggrenzen, Psi-Listen, TP/PP
func _test_creation() -> void:
	for n in 200:
		var pool := Creation.roll_pool()
		if pool.size() != 7 or not pool.has(Creation.LOWEST_TO) or pool.min() < 20 or pool.max() > 100:
			check(false, "Würfe 20–100 mit einer 90: %s" % [pool])
			return
	check(true, "Würfe 20–100, niedrigster wird 90")
	var ch := Character.new()
	for a in Rules.ATTRIBUTES:
		ch.attrs[a.id] = 80
	check(Creation.budget(ch) == 672 and Creation.points_left(ch) == 672, "Punkte = Summe × 1,2 (560 → 672)")
	check(Creation.ranks_cost(5) == 70 and Creation.ranks_cost(8) == 136, "Rangkosten 5 → 70, 8 → 136")
	for i in 5:
		Creation.raise(ch, &"gewehre")
	check(Creation.raise_block(ch, &"gewehre") == "" , "über Rang 5 als erste Ausnahme")
	for i in 3:
		Creation.raise(ch, &"gewehre")
	check(Rules.skill_rank(ch, &"gewehre") == 8 and not Creation.raise(ch, &"gewehre"), "höchstens Rang 8")
	for i in 6:
		Creation.raise(ch, &"pistolen")
	for i in 6:
		Creation.raise(ch, &"ausweichen")
	check(Rules.skill_rank(ch, &"pistolen") == 6 and Rules.skill_rank(ch, &"ausweichen") == 5, "nur zwei Fertigkeiten über Rang 5")
	check(Creation.spent(ch) == 136 + 90 + 70, "verbaute Punkte")
	check(Creation.raise(ch, &"lSchutz") and Creation.raise(ch, &"lHeilung") and not Creation.raise(ch, &"lAngriff"), "höchstens zwei Psi-Listen")
	Creation.raise(ch, &"lSchutz")
	check(PsiLists.powers(ch, &"lSchutz").size() == 2, "Liste Schutz Rang 2: zwei Kräfte")
	check(Creation.lower(ch, &"lHeilung") and not ch.skills.has(&"lHeilung") and Creation.raise(ch, &"lAngriff"), "Liste abwählen, andere lernen")
	ch.attrs.MEN = 98
	var pp := 9 + Rules.attr_bonus(98) / 2
	check(Rules.has_psi(ch) and Rules.max_pp(ch) == pp, "PP = MEN/10 + MEN-Bonus/2 (%d)" % pp)
	Creation.raise(ch, &"psiPunkte")
	Creation.raise(ch, &"koerper")
	check(Rules.max_pp(ch) == pp + 2 and Rules.max_hp(ch) == 15 + 80 / 3 + 5, "Entwicklung: +2 PP, +5 TP je Rang")
	var crew := Roster.start_crew()
	crew[0].station = "Steuer"
	# Campaign.reload: Crew nach Austausch der Datei neu lesen
	var backup := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Campaign.reset()
	var other := Roster.start_crew()
	other[0].name = "Geladen"
	Roster.save_crew(other)
	check(Campaign.crew()[0].name != "Geladen", "Campaign hält die Crew im Speicher")
	Campaign.reload()
	check(Campaign.crew()[0].name == "Geladen" and Campaign.last_result.is_empty(), "Campaign.reload liest den Spielstand neu")
	if backup != "":
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	else:
		Roster.reset()
	Campaign.reload()
	check(not Creation.station_free(crew, "Steuer") and Creation.station_free(crew, "Steuer", crew[0]) and Creation.station_free(crew, "Jäger"), "Station nur einmal, Jäger mehrfach")


## Aufleveln: keine Ranggrenze, neue Psi-Liste doppelt, höchstens eine neue Liste pro Levelphase
func _test_leveling() -> void:
	var ch := Roster.start_crew()[4]
	ch.free_xp = 100
	check(Rules.next_rank_cost(ch, &"lSchutz") == 20 and Rules.next_rank_cost(ch, &"psiAngriff") == Rules.rank_cost(Rules.skill_rank(ch, &"psiAngriff")), "erster Rang einer neuen Liste kostet doppelt")
	check(Rules.rank_up_with_pool(ch, &"lSchutz") and ch.free_xp == 80 and ch.new_list == &"lSchutz", "neue Liste begonnen (20 EP)")
	check(Rules.next_rank_cost(ch, &"lSchutz") == 12 and Rules.rank_up_with_pool(ch, &"lSchutz"), "danach normale Kosten")
	check(Rules.deposit_xp(ch, &"lHeilung", 5) == 5 and not Rules.rank_up_with_pool(ch, &"lHeilung") and Rules.rank_block(ch, &"lHeilung") != "", "zweite neue Liste: Einzahlen ja, Rang 1 nicht")
	ch.apply_result({"xp": {}, "free_xp": 0})
	check(ch.new_list == &"" and Rules.rank_up_with_pool(ch, &"lHeilung"), "nach dem Einsatz: neue Phase, nächste Liste")
	var r := Rules.skill_rank(ch, &"psiAngriff")
	ch.free_xp = 1000
	for i in 6:
		Rules.rank_up_with_pool(ch, &"psiAngriff")
	check(Rules.skill_rank(ch, &"psiAngriff") == r + 6, "keine Ranggrenze beim Aufleveln")
	var d := Character.from_dict(ch.to_dict())
	check(d.new_list == ch.new_list and d.station == ch.station, "new_list und Station gespeichert")


## Globaler Roster und Crew im Spiel (Kopien, Anheuern, Entlassen, Trupp)
func _test_roster() -> void:
	var files := [GlobalRoster.PATH, Roster.PATH]
	var backup := {}
	for p in files:
		backup[p] = FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else null
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	check(GlobalRoster.entries().size() == 6 and GlobalRoster.own().is_empty(), "Roster: 6 Startcharaktere")
	var vela := GlobalRoster.entries()[0]
	check(GlobalRoster.is_protected(vela) and not GlobalRoster.update(vela), "Startcharaktere schreibgeschützt")
	var cp := GlobalRoster.copy(vela, "Vela (Kopie)")
	check(GlobalRoster.own().size() == 1 and cp.id != vela.id and not GlobalRoster.is_protected(cp) and cp.attrs == vela.attrs, "Kopie als eigene Figur")
	cp.name = "Velina"
	cp.attrs.STA = 1
	check(GlobalRoster.update(cp) and GlobalRoster.find(cp.id).name == "Velina" and GlobalRoster.find(cp.id).attrs.STA == vela.attrs.STA, "Bearbeiten: nur Name/Aussehen, Werte fest")
	var picked: Array[Character] = [vela, GlobalRoster.find(cp.id)]
	Campaign.new_game(picked)
	check(Campaign.crew().size() == 2 and Campaign.crew()[1].roster_id == cp.id and Campaign.is_aboard(vela.roster_id), "neues Spiel mit 2 Figuren")
	Campaign.crew()[0].free_xp = 50
	check(GlobalRoster.find(vela.id).free_xp == 0, "Fortschritt im Spiel fließt nicht in den Roster")
	check(Campaign.hire(vela) == null, "Roster-Figur höchstens einmal an Bord")
	for c in GlobalRoster.entries().slice(1, 6):
		Campaign.hire(c)
	check(Campaign.crew().size() == 7 and Campaign.squad().size() == 6, "7 an Bord, Trupp höchstens 6")
	var chosen: Array[Character] = [Campaign.crew()[6], Campaign.crew()[2]]
	Campaign.chosen_squad = chosen
	check(Campaign.squad().size() == 2 and Campaign.squad()[0] == Campaign.crew()[6], "gewählter Trupp")
	var gone := Campaign.crew()[6]
	Campaign.fire(gone)
	check(Campaign.crew().size() == 6 and not Campaign.squad().has(gone) and GlobalRoster.find(cp.id) != null, "Entlassen: Roster-Eintrag bleibt")
	Campaign.reload()
	check(Campaign.crew().size() == 6 and Campaign.crew()[0].free_xp == 50, "Crew gespeichert")
	check(GlobalRoster.remove(cp.id) and GlobalRoster.own().is_empty() and not GlobalRoster.remove(vela.id), "eigene löschen, Startcharakter nicht")
	Campaign.chosen_squad = []
	for p in files:
		if backup[p] != null:
			var f := FileAccess.open(p, FileAccess.WRITE)
			f.store_string(backup[p])
			f.close()
		elif FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	Campaign.reload()


## Runde 0: Aufstellung nur im Eingangsbereich, Tauschen, danach gesperrt
func _test_deploy() -> void:
	var c := _combat(MapGenerator.generate(4711, "mittel"))
	var zone := c.deploy_tiles()
	check(zone.size() >= 6, "Eingangsbereich groß genug (%d)" % zone.size())
	var a := c.crew()[0]
	var b := c.crew()[1]
	var free_tile: Variant = null
	for p in zone:
		if c.unit_at(p) == null:
			free_tile = p
			break
	check(free_tile != null and c.deploy(a, free_tile) == null and a.pos == free_tile, "auf freies Feld stellen")
	var bp := b.pos
	check(c.deploy(a, bp) == b and a.pos == bp and b.pos == free_tile, "mit Crewmitglied tauschen")
	check(not c.can_deploy(a, c.enemies()[0].pos), "nicht auf Gegnerfeld")
	var outside := Vector2i(999, 999)
	for t in c.map.list:
		if c.map.walkable(t) and not zone.has(t.pos) and c.unit_at(t.pos) == null:
			outside = t.pos
			break
	check(not c.can_deploy(a, outside), "nicht außerhalb des Eingangsbereichs")
	c.deploy_face(a, 4)
	check(a.facing == 4, "Blickrichtung in Runde 0")
	check(not c.retreat(), "kein Rückzug in Runde 0")
	c.start()
	check(not c.can_deploy(a, free_tile), "nach Kampfbeginn keine Aufstellung mehr")
	check(c.retreat() and c.result == &"niederlage" and c.retreated, "Rückzug = Niederlage")
	check(not c.retreat(), "Rückzug nur einmal")
