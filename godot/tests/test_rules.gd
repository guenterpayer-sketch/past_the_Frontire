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
	_test_injury()
	_test_equipment()
	_test_psi_view()
	_test_own_gear()
	_test_armory_stock()
	_test_deploy()
	_test_dying()
	_test_psi()
	_test_ammo()
	_test_custom_gear()
	_test_models_sounds()
	_test_loot_wear()
	_test_char_wear()
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
	# Kistenstapel (Höhe 1) sperren die Sicht nur als Wand: eines auf der Linie nicht, zwei schon
	var k := _row_map(10)
	var K := func(q: int) -> BattleMap.Tile: return k.tile(Vector2i(q, 0))
	K.call(4).terrain = &"kiste"
	K.call(4).h = 1
	check(k.line_of_sight(K.call(9), K.call(1)), "ein Kistenstapel mitten auf der Linie sperrt nicht")
	check(k.cover(K.call(1), K.call(9)).is_empty(), "Kiste 3 Felder vor dem Ziel: keine Deckung")
	K.call(5).terrain = &"kiste"
	K.call(5).h = 1
	k.clear_cache()
	check(not k.line_of_sight(K.call(9), K.call(1)), "zwei Kistenstapel auf der Linie sperren")
	K.call(5).terrain = &"boden"
	K.call(5).h = 0
	K.call(2).terrain = &"kiste"
	K.call(2).h = 1
	k.clear_cache()
	check(k.cover(K.call(1), K.call(9)).get("level", 0) == 1, "Kiste direkt vor dem Ziel: halbe Deckung")


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
	check(Rules.next_rank_cost(ch, &"lWahrnehmung") == 20 and Rules.next_rank_cost(ch, &"psiAngriff") == Rules.rank_cost(Rules.skill_rank(ch, &"psiAngriff")), "erster Rang einer neuen Liste kostet doppelt")
	check(Rules.rank_up_with_pool(ch, &"lWahrnehmung") and ch.free_xp == 80 and ch.new_list == &"lWahrnehmung", "neue Liste begonnen (20 EP)")
	check(Rules.next_rank_cost(ch, &"lWahrnehmung") == 12 and Rules.rank_up_with_pool(ch, &"lWahrnehmung"), "danach normale Kosten")
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
	gone.free_xp = 33
	check(Campaign.harbor().has(gone) and not Campaign.is_aboard(gone.roster_id), "Entlassene warten im Hafen")
	var back := Campaign.hire(GlobalRoster.find(gone.roster_id))
	check(back == gone and back.free_xp == 33 and Campaign.harbor().is_empty(), "aus dem Hafen mit Fortschritt zurück")
	Campaign.fire(back)
	Campaign.set_squad([Campaign.crew()[3]])
	Campaign.reload()
	check(Campaign.crew().size() == 6 and Campaign.crew()[0].free_xp == 50, "Crew gespeichert")
	check(Campaign.harbor().size() == 1 and Campaign.chosen_squad.size() == 1 and Campaign.chosen_squad[0] == Campaign.crew()[3], "Hafen und Trupp gespeichert")
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


## Verwundung: Stufe und Tage aus dem MissionResult, Heilung, Tote, Sperre, Kandidaten
func _test_injury() -> void:
	var r := func(state: String, hp: int, crit := "", dying := false, stab := false) -> Dictionary:
		return {"xp": {}, "free_xp": 0, "status": {"state": state, "hp": hp, "max_hp": 40}, "worst_crit": crit, "dying": dying, "stabilized": stab, "died": false}
	check(Injury.from_result(r.call("ok", 30)).stage == "", "unverletzt")
	check(Injury.from_result(r.call("ok", 15)) == {"stage": Injury.LIGHT, "days": 2}, "angeschlagen: TP unter Hälfte, 2 Tage")
	check(Injury.from_result(r.call("ok", 30, "D")) == {"stage": Injury.LIGHT, "days": 5}, "Kritischer D im Stehen: angeschlagen + 3")
	check(Injury.from_result(r.call("ko", -2, "B")) == {"stage": Injury.DOWN, "days": 6}, "bewusstlos: kampfunfähig 5 + 1")
	check(Injury.from_result(r.call("sterbend", -9, "E", true)) == {"stage": Injury.SEVERE, "days": 14}, "sterbend: schwer verwundet 10 + 4")
	check(Injury.from_result(r.call("sterbend", -9, "", false, true)).stage == Injury.SEVERE, "stabilisiert: schwer verwundet")
	check(Injury.combine(Injury.SEVERE, 3, {"stage": Injury.LIGHT, "days": 2}) == {"stage": Injury.SEVERE, "days": 5}, "erneut: schlimmere Stufe, Tage addiert")
	var files := [GlobalRoster.PATH, Roster.PATH]
	var backup := {}
	for p in files:
		backup[p] = FileAccess.get_file_as_string(p) if FileAccess.file_exists(p) else null
	Campaign.new_game(GlobalRoster.entries())
	var cr := Campaign.crew()
	var res := {"outcome": &"niederlage", "mission": "", "rounds": 3, "reward_xp": 0, "units": {
		cr[0].id: r.call("ok", 15), cr[1].id: r.call("ko", -1), cr[2].id: r.call("sterbend", -9, "C", true),
		cr[3].id: r.call("ok", 40)}}
	res.units[cr[4].id] = r.call("sterbend", -9)
	res.units[cr[4].id].died = true
	var dead := cr[4]
	Campaign.finish_mission(res)
	check(Campaign.crew().size() == 5 and not Campaign.crew().has(dead) and Campaign.last_fallen == [dead] and GlobalRoster.find(dead.roster_id) != null, "Tote verlassen die Crew, Roster-Eintrag bleibt")
	check(cr[0].injury == Injury.LIGHT and cr[1].injury == Injury.DOWN and cr[2].injury == Injury.SEVERE and cr[2].injury_days == 12 and cr[3].injury == "", "Stufen nach dem Einsatz")
	check(Combatant.from_character(cr[0], &"crew").malus == Injury.LIGHT_MALUS, "angeschlagen: Malus im Kampf")
	check(not Campaign.squad().has(cr[1]) and not Campaign.squad().has(cr[2]) and Campaign.squad().has(cr[0]), "Gesperrte nicht im Trupp")
	var cands := Campaign.candidates(false, [cr[3].id])
	var by := {}
	for k in cands:
		by[k.ch] = k
	check(by[cr[1]].locked and by[cr[2]].locked and by[cr[3]].locked and by[cr[3]].reason.begins_with("Arzt") and not by[cr[0]].locked and by[cr[0]].marked, "Kandidaten mit Sperre und Markierung")
	var sug := Campaign.suggested_squad(cands)
	check(sug.size() == 2 and not sug.has(cr[1]), "Vorbelegung ohne Gesperrte")
	check(Campaign.candidates(true).size() == GlobalRoster.entries().size() and not Campaign.candidates(true)[0].locked, "Schnellkampf: Roster-Kopien")
	var healed := Campaign.pass_days(2)
	check(healed.has(cr[0]) and cr[0].injury == "" and cr[1].injury_days == 3, "2 Tage: angeschlagen geheilt, kampfunfähig noch 3")
	Campaign.pass_days(1, 2)
	check(cr[1].injury == "" and cr[2].injury_days == 7 and Campaign.patients() == [cr[2]], "Tag mit Arzt-Bonus +2")
	var q: Array[Character] = [Campaign.candidates(true)[0].ch]
	Campaign.quick_squad = q
	check(Campaign.squad() == q, "Schnellkampf-Trupp")
	Campaign.quick_squad = []
	for p in files:
		if backup[p] != null:
			var f := FileAccess.open(p, FileAccess.WRITE)
			f.store_string(backup[p])
			f.close()
		elif FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	Campaign.reload()


## Waffenkammer: Waffen ändern, Waffe 2 leer, keine doppelt, Schild nur mit einhändiger Waffe 1, keine Psi-Waffen
func _test_equipment() -> void:
	var ch := Roster.start_crew()[0]
	var by := {}
	for w in GameData.weapons():
		by[w.id] = w
	check(not Equipment.weapons().any(func(w: WeaponData) -> bool: return w.psi), "Psi-Waffen nicht wählbar")
	check(Equipment.set_weapon(ch, 0, by[&"psi_stoss"]) != "", "Psi-Stoß nicht in einen Platz")
	check(Equipment.set_weapon(ch, 0, by[&"laserpistole"]) == "" and ch.weapons[0] == by[&"laserpistole"], "Waffe 1 wechseln")
	check(Equipment.set_weapon(ch, 1, by[&"laserpistole"]) != "", "keine Waffe doppelt")
	check(Equipment.set_weapon(ch, 1, null) == "" and ch.weapons.size() == 1 and Equipment.weapon(ch, 1) == null, "Waffe 2 leer")
	check(Equipment.set_weapon(ch, 0, null) != "", "Waffe 1 ist Pflicht")
	check(Equipment.set_weapon(ch, 1, by[&"vibroklinge"]) == "" and ch.weapons.size() == 2, "Waffe 2 wieder belegen")
	check(not by[&"vibroklinge"].two_handed and by[&"laserkarabiner"].skill == &"gewehre", "Vibroklinge einhändig, Laserkarabiner = Gewehre")
	check(Equipment.set_shield(ch, true) == "" and ch.shield, "Schild mit zwei Einhandwaffen (Pistole + Vibroklinge)")
	check(Equipment.set_weapon(ch, 1, by[&"sturmgewehr"]) == "" and not ch.shield, "zweihändige Waffe 2 legt Schild ab")
	check(Equipment.set_shield(ch, true) != "" and not ch.shield, "kein Schild mit zweihändiger Waffe")
	Equipment.set_weapon(ch, 1, by[&"vibroklinge"])
	Equipment.set_shield(ch, true)
	check(Equipment.set_weapon(ch, 0, by[&"sturmgewehr"]) == "" and not ch.shield, "zweihändige Waffe 1 legt Schild ab")
	Equipment.set_weapon(ch, 0, by[&"laserpistole"])
	Equipment.set_weapon(ch, 1, by[&"faeuste"])
	check(Equipment.set_shield(ch, true) == "", "Schild mit Fäusten als Waffe 2")
	Equipment.set_weapon(ch, 1, by[&"vibroklinge"])
	Equipment.set_weapon(ch, 0, by[&"sturmgewehr"])
	check(Equipment.shield_bonus(ch) == 10 + maxi(0, Rules.rank_bonus(Rules.skill_rank(ch, &"schild")) / 2), "Schildbonus wie im Kampf")
	var d := Character.from_dict(ch.to_dict())
	check(d.weapons.size() == 2 and d.weapons[0] == by[&"sturmgewehr"] and not d.shield, "Ausrüstung gespeichert")
	var u := Combatant.from_character(Character.from_dict({"id": "x", "attrs": ch.attrs, "weapons": [by[&"laserpistole"].resource_path], "armor": ch.armor.resource_path}), &"crew")
	check(u.weapons.size() >= 1 and u.weapon == by[&"laserpistole"], "Kampf mit nur einer Waffe")


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


## Verwundung statt Tod: sterbend statt tot, Stabilisieren, Todeswurf nur wenn die ganze Crew fällt
func _test_dying() -> void:
	var m := _row_map(8)
	_start_maps(m, [0, 1, 2, 3, 4, 5], [7, 6, 5, 4, 3, 2])
	var c := _combat(m, 2, 1)
	c.start()
	var a := c.crew()[0]
	var b := c.crew()[1]
	var e := c.enemies()[0]
	a.hp = Rules.death_at(a) - 3
	c._check_state(a)
	check(a.state == Combatant.State.DYING and not a.is_dead() and a.is_down(), "unter der Todesgrenze: sterbend, nicht tot")
	a.hp = -1000
	c._check_state(a)
	check(a.hp == -a.max_hp and a.state == Combatant.State.DYING, "TP-Untergrenze −max_hp, bleibt sterbend")
	e.hp = Rules.death_at(e) - 1
	c._check_state(e)
	check(e.state == Combatant.State.DYING, "Gegner werden ebenfalls sterbend")
	check(c.first_aid_targets(b).has(a) or Hex.distance(a.pos, b.pos) > 1, "Sterbende sind Ziel für Erste Hilfe")
	check(c._stabilize(a) != "" and a.stabilized and a.state == Combatant.State.DYING, "Stabilisieren: bleibt kampfunfähig")
	c._heal(a, 500)
	check(a.state == Combatant.State.DYING, "Heilen weckt Sterbende nicht auf")
	var crit := {"row": CritRowData.new(), "table": "test", "roll": 50, "total": 50}
	c._apply_crit(b, crit, "C")
	c._apply_crit(b, crit, "A")
	check(b.worst_crit == "C", "schwerster Kritischer wird gemerkt (%s)" % b.worst_crit)
	var r := MissionResult.from_combat(c)
	check(r.units[a.id].stabilized and not r.units[a.id].dying and r.units[a.id].status.state == "sterbend", "MissionResult: stabilisiert")
	check(r.units[b.id].worst_crit == "C" and not r.units[b.id].died, "MissionResult: worst_crit")
	# ganze Crew fällt: nur unversorgte Sterbende würfeln (10 %); über viele Würfe ungefähr 10 % Tote
	var deaths := 0
	var stab_deaths := 0
	for i in 400:
		var x := Combatant.create(GameData.crew().units[0], &"crew")
		var y := Combatant.create(GameData.crew().units[1], &"crew")
		var en := Combatant.create(GameData.enemies().units[0], &"enemy")
		var mm := _row_map(8)
		mm.crew_start.append(mm.tile(Vector2i(0, 0)))
		mm.crew_start.append(mm.tile(Vector2i(1, 0)))
		mm.enemy_start.append(mm.tile(Vector2i(7, 0)))
		var cr: Array[Combatant] = [x, y]
		var ce: Array[Combatant] = [en]
		var cx := Combat.new(mm, cr, ce)
		cx.deploying = false
		x.state = Combatant.State.DYING
		y.state = Combatant.State.DYING
		y.stabilized = true
		cx.check_end()
		if x.is_dead():
			deaths += 1
		if y.is_dead():
			stab_deaths += 1
	check(cx_ok(deaths), "Todeswurf ≈ 10 %% (%d von 400)" % deaths)
	check(stab_deaths == 0, "Stabilisierte sterben nicht")


func cx_ok(n: int) -> bool:
	return n >= 20 and n <= 65


## Psi im Kampf: Kräfte aus den Listen, Angriffskräfte als Waffen, unterstützende Kräfte und ihre Wirkungen
func _test_psi() -> void:
	var m := _row_map(10)
	_start_maps(m, [0, 1, 2, 3, 4, 5], [9, 8, 7, 6, 5, 4])
	var crew := Roster.build_team(GameData.crew(), &"crew")
	var nyx: Combatant = crew.filter(func(u: Combatant) -> bool: return u.id == &"nyx")[0]
	var hexer := Combatant.create(load("res://data/units/enemies/hexer.tres"), &"enemy")
	check(not nyx.weapons.any(func(w: WeaponData) -> bool: return w.id == &"psi_stoss"), "alte Psi-Stoß-Waffe fällt weg")
	var names := nyx.weapons.filter(func(w: WeaponData) -> bool: return w.power != "").map(func(w: WeaponData) -> String: return w.name)
	check(names == ["Psi-Nadel", "Psi-Stoß", "Lähmen"], "Nyx: Angriffskräfte aus Angriff 4 (%s)" % [names])
	check(Array(nyx.powers) == ["lSchutz/1", "lSchutz/2", "lSchutz/4"], "Nyx: Schutz 4 (%s)" % [nyx.powers])
	check(Array(hexer.powers) == ["lSchutz/1", "lSchutz/2"] and hexer.weapons[0].name == "Laserpistole", "Hexer: Schutz 2, Pistole zuerst")
	var a: Array[Combatant] = [nyx, crew[0]]
	var e: Array[Combatant] = [hexer]
	var c := Combat.new(m, a, e)
	c.start()
	nyx.pos = Vector2i(2, 0)
	crew[0].pos = Vector2i(3, 0)
	hexer.pos = Vector2i(5, 0)
	c.order.assign([nyx, crew[0], hexer])
	c.turn_idx = 0
	c._begin_turn(nyx)
	check(c.power_targets(nyx, "lSchutz/2").has(crew[0]), "Psi-Schild: Verbündeter in Sicht ist Ziel")
	check(c.can_power(nyx, "lSchutz/2"), "Psi-Schild wirkbar")
	var pp := nyx.pp
	check(c.do_power(nyx, "lSchutz/2", crew[0]) and nyx.pp == pp - 2 and nyx.act == 60, "Kraft kostet Stufe PP und 40 %")
	# Wirkungen direkt (ohne Würfelglück)
	c._power_effect(nyx, "lSchutz/4", crew[0], 2)
	check(crew[0].buffs.has("ablenkfeld"), "Ablenkfeld gesetzt")
	var pistol := crew[0].weapons[0]
	var info := c.attack_info(hexer, crew[0], hexer.weapons[0])
	check(info.ob.any(func(x: Dictionary) -> bool: return x.label == "Ablenkfeld" and x.val == -20), "Ablenkfeld −20 auf Fernangriffe")
	c._power_effect(nyx, "lSchutz/9", crew[0], 2)
	var res := {"hit": true, "dmg": 0, "severity": "A", "crit": load("res://data/tables/crit_durchschlag.tres")}
	c._apply_power_hit(hexer, crew[0], pistol, res)
	check(not crew[0].buffs.has("barriere") and crew[0].worst_crit == "", "Letzte Barriere wehrt Kritischen A ab")
	var lahm := PsiCombat.weapon("lAngriff/4")
	c._apply_power_hit(nyx, hexer, lahm, {"hit": true, "dmg": 9, "severity": "", "crit": null})
	check(hexer.stun == 1 and hexer.hp == hexer.max_hp, "Lähmen: betäubt, kein Schaden")
	var push := PsiCombat.weapon("lTelekinese/3")
	c._apply_power_hit(nyx, hexer, push, {"hit": true, "dmg": 9, "severity": "B", "crit": null})
	check(hexer.pos == Vector2i(6, 0) and hexer.prone, "Stoßen: 1 Hex zurück, niedergeworfen")
	c._apply_power_hit(nyx, hexer, PsiCombat.weapon("lTelekinese/5"), {"hit": true, "dmg": 0, "severity": "", "crit": null})
	check(hexer.disarmed, "Entwaffnen gesetzt")
	c._begin_turn(hexer)
	check(not c.can_attack(hexer) and not hexer.disarmed, "entwaffnet: kein Angriff im nächsten Zug")
	crew[0].state = Combatant.State.DYING
	crew[0].powers = []
	nyx.powers.append("lHeilung/10")
	check(c.power_targets(nyx, "lHeilung/10").has(crew[0]), "Am Leben halten: sterbende Nachbarin ist Ziel")
	check(c._power_effect(nyx, "lHeilung/10", crew[0], 2) != "" and crew[0].stabilized, "Am Leben halten stabilisiert")
	# Kontextmenü
	var pc := PlayerController.new(c)
	c.turn_idx = 0
	c._begin_turn(nyx)
	var entries := pc.context_powers(nyx, hexer)
	check(entries.any(func(x: Dictionary) -> bool: return x.has("attack")), "Kontextmenü: Angriffskräfte gegen Gegner")
	check(not pc.context_powers(nyx, crew[0]).any(func(x: Dictionary) -> bool: return x.has("attack")), "Kontextmenü: keine Angriffe gegen Verbündete")



func _test_psi_view() -> void:
	check(PsiLists.kind(&"lAngriff", 2) == PsiLists.ATTACK and PsiLists.kind(&"lHeilung", 3) == PsiLists.SUPPORT
		and PsiLists.kind(&"lTelekinese", 1) == PsiLists.OFF, "Psi: Art der Kraft wie im Bodenkampf")
	check(PsiLists.target(&"lAngriff", 2) == "Gegner, bis %d m" % PsiCombat.weapon("lAngriff/2").max_range_m(), "Psi: Reichweite aus dem Bodenkampf")
	check(PsiLists.target(&"lSchutz", 6) == "Verbündete in 2 Hex" and PsiLists.target(&"lTelekinese", 8) == "selbst", "Psi: Ziele")
	# jede Kraft hat eine Art und ein Ziel
	for id in PsiLists.LISTS:
		for p in PsiLists.LISTS[id].powers:
			check(PsiLists.target(id, p[0]) != "", "Psi: Ziel für %s" % p[1])
	var ch := Character.new()
	ch.attrs = {"KON": 50, "GEW": 50, "STÄ": 50, "INT": 50, "MEN": 50, "EMP": 50, "WAH": 50}
	ch.skills = {&"lAngriff": {"rank": 4, "xp": 0}, &"lSchutz": {"rank": 1, "xp": 0}}
	check(PsiLists.next_power(ch, &"lAngriff")[1] == "Psi-Lanze", "Psi: nächste Kraft")
	check(PsiListView.next_hint(ch, &"lAngriff").begins_with("Rang 5: keine neue Kraft · Rang 6: Psi-Lanze"), "Psi: Hinweis nächster Rang ohne Kraft")
	check(PsiListView.next_hint(ch, &"lSchutz").begins_with("Rang 2: Psi-Schild"), "Psi: Hinweis nächster Rang mit Kraft")
	check(PsiListView.next_hint(ch, &"lTelekinese") == "Rang 1: Heranziehen (nicht im Kampf)", "Psi: Kraft außerhalb des Kampfs")
	check(PsiListView.preview_hint(ch, &"lHeilung") == "Rang 1: Blutung stillen · Rang 3: Wunden schließen · Rang 5: Schmerz dämpfen …", "Psi: Vorschau ungelernte Liste")
	check(PsiListView.preview_hint(ch, &"lAngriff") == "verfügbar: Psi-Nadel, Psi-Stoß, Lähmen · Rang 6: Psi-Lanze", "Psi: Vorschau gelernte Liste")
	ch.skills[&"lAngriff"].rank = 8
	check(PsiListView.next_hint(ch, &"lAngriff") == "alle Kräfte verfügbar", "Psi: alles verfügbar")


## Munition: Mitnahme aus dem Schiffsvorrat, Feuerstoß, Verbrauch je Art, KI mit leeren Waffen
func _test_ammo() -> void:
	var by_id := {}
	for w in GameData.weapons():
		by_id[w.id] = w
	check(Ammo.carry(by_id[&"raketenwerfer"]) == 2, "Raketenwerfer: 3 Magazine, höchstens Munition gesamt (2)")
	check(Ammo.carry(by_id[&"mg"]) == 180 and Ammo.carry(by_id[&"laserpistole"], 1) == 12 and by_id[&"mg"].shots == 3 and by_id[&"mg"].ob_bonus == 0, "MG: Magazin 60 (3 Magazine), Feuerstoß 3 statt festem Bonus; Pistole als Zweitwaffe 1 Magazin")
	check(by_id[&"laserkarabiner"].ammo_type == &"energie" and by_id[&"sturmgewehr"].ammo_type == &"projektil" and by_id[&"raketenwerfer"].ammo_type == &"raketen", "Munitionsarten zugeordnet")
	check(Ammo.burst_bonus(1) == 0 and Ammo.burst_bonus(2) == 10 and Ammo.burst_bonus(3) == 15, "Feuerstoß +5 je Kugel ab 2")
	var w := WeaponData.new()
	w.id = &"test_mg"
	w.name = "Test-MG"
	w.magazine = 30
	w.shots = 3
	w.ammo_type = &"projektil"
	check(Ammo.carry(w) == 90 and Ammo.shots_next(w, 30) == 3 and Ammo.shots_next(w, 2) == 2, "3 Magazine; Rest-Feuerstoß")
	check(Ammo.carry(w, 1) == 30 and Ammo.plan([[by_id[&"faeuste"], w]], null).give[0][&"test_mg"] == 30, "Zweitwaffe: 1 Magazin")
	var p := Ammo.plan([[w], [w]], {&"projektil": 50})
	check(p.give[0][&"test_mg"] == 50 and p.give[1][&"test_mg"] == 0 and p.take[&"projektil"] == 50, "Vorrat reicht nur für die erste Figur")
	check(p.short[0].size() == 1 and "nur 50" in p.short[0][0] and "keine Munition" in p.short[1][0], "Hinweise bei knapper Munition")
	check(Ammo.plan([[w]], null).give[0][&"test_mg"] == 90, "ohne Vorrat (Schnellkampf): voll")
	# Verbrauch und Rückmeldung
	var c := Combat.new(MapGenerator.generate(4711, "klein"), Roster.build_crew(Roster.start_crew()), Roster.build_units(Mission.generate(4711).enemies, &"enemy"))
	var u := c.crew()[0]
	u.weapons.insert(0, w)   # als Waffe 1 (3 Magazine)
	Ammo.apply(c.crew(), {&"projektil": 40, &"raketen": 1})
	check(u.loaded[&"test_mg"] == 30 and u.ammo[&"test_mg"] == 10, "Magazin voll, Rest als Reserve")
	u.loaded[&"test_mg"] -= Ammo.shots_next(w, u.loaded[&"test_mg"])
	check(u.loaded[&"test_mg"] == 27, "ein Feuerstoß verbraucht 3 Schuss")
	var used := Ammo.used(c.crew())
	check(used.get("projektil", 0) == 3, "Verbrauch je Munitionsart")
	for e in c.enemies():
		e.state = Combatant.State.DEAD
	c.check_end()
	check(MissionResult.from_combat(c).ammo_used.get("projektil", 0) == 3, "MissionResult meldet ammo_used")
	# KI: Crew nur mit leeren Waffen darf den Kampf nicht aufhalten
	Dice.set_seed(11)
	var c2 := Combat.new(MapGenerator.generate(4712, "klein"), Roster.build_crew(Roster.start_crew()), Roster.build_units(Mission.generate(4712).enemies, &"enemy"))
	for cu in c2.crew():
		var ew := w.duplicate()
		ew.id = StringName("leer_%s" % cu.id)
		cu.weapons.assign([ew])
		cu.weapon = ew
	Ammo.apply(c2.crew(), {})
	check(c2.usable_weapons(c2.crew()[0]).is_empty(), "leere Waffe nicht nutzbar")
	var ai := CombatAI.new()
	c2.start()
	var steps := 0
	while c2.result == &"" and steps < 5000 and c2.round_no <= 60:
		ai.act(c2)
		steps += 1
	check(c2.result != &"" or c2.round_no > 60, "KI mit leeren Waffen hängt nicht (Ergebnis %s, Runde %d)" % [c2.result, c2.round_no])


## eigene Ausrüstung (Gear) in der Waffenkammer; gelöscht → Fäuste / keine Rüstung
func _test_own_gear() -> void:
	var old_dir := Gear.dir
	Gear.dir = "user://gear_test_charakter"
	var pistol: WeaponData = load("res://data/weapons/laserpistole.tres")
	var w := Gear.save(Gear.from_template(pistol)) as WeaponData
	var t: ArmorData = Equipment.armors()[1]
	var draft := Gear.from_template(t)
	draft.set_meta(&"free", true)
	var a := Gear.save(draft) as ArmorData
	check(w in Equipment.weapons() and a in Equipment.armors(), "eigene Ausrüstung wählbar")
	check(Equipment.weapons().count(w) == 1, "eigene Waffe nur einmal (auch wenn GameData sie liefert)")
	check(Equipment.label(a).ends_with("(frei)") and Equipment.label(pistol) == "Laserpistole", "Vermerk frei")
	var ch := Roster.start_crew()[0]
	ch.weapons = [w, pistol] as Array[WeaponData]
	ch.armor = a
	var d := ch.to_dict()
	Gear.delete(w)
	Gear.delete(a)
	var c := Character.from_dict(d)
	check(c.weapons.size() == 2 and c.weapons[0].resource_path == Gear.FALLBACK_WEAPON and c.weapons[1] == pistol, "gelöschte Waffe 1 → Fäuste")
	check(c.armor.resource_path == Gear.FALLBACK_ARMOR, "gelöschte Rüstung → keine")
	d.weapons = [pistol.resource_path, w.resource_path]
	c = Character.from_dict(d)
	check(c.weapons.size() == 1 and c.weapons[0] == pistol, "gelöschte Waffe 2 → leer")
	DirAccess.remove_absolute(Gear.dir.path_join("weapons"))
	DirAccess.remove_absolute(Gear.dir.path_join("armor"))
	DirAccess.remove_absolute(Gear.dir)
	Gear.dir = old_dir
	# Munition: Feuerstoß aus shots, Mitnahme 3 Magazine, höchstens „Munition gesamt“
	var mg: WeaponData = load("res://data/weapons/mg.tres")
	check(mg.shots == 3 and Ammo.burst_bonus(mg.shots) == 15 and mg.ob_bonus == 0, "MG: Feuerstoß über shots")
	var rw: WeaponData = load("res://data/weapons/raketenwerfer.tres")
	check(Ammo.carry(rw) == (mini(rw.magazine * Ammo.MAGS, rw.ammo_total) if rw.ammo_total > 0 else rw.magazine * Ammo.MAGS), "Mitnahme mit Obergrenze")


## Eigene Waffen/Rüstungen (Gear): in GameData.weapons(); Gegner bekommen freigegebene mit gleicher Fertigkeit/Klasse
func _test_custom_gear() -> void:
	var old_dir := Gear.dir
	Gear.dir = "user://gear_test_rules"
	for sub in ["weapons", "armor"]:
		var d := Gear.dir.path_join(sub)
		if DirAccess.dir_exists_absolute(d):
			for f in DirAccess.get_files_at(d):
				DirAccess.remove_absolute(d.path_join(f))
	var m0 := Mission.generate(4711)
	var plain: Array = m0.enemies.map(func(d: UnitData) -> String: return d.weapons[0].name if not d.weapons.is_empty() else "")
	var by_skill := {}
	var classes := {}
	for d in m0.enemies:
		if not d.weapons.is_empty():
			by_skill[d.weapons[0].skill] = d.weapons[0]
		if d.armor:
			classes[d.armor.cls] = d.armor
	for sk in by_skill:
		var w := Gear.from_template(by_skill[sk]) as WeaponData
		w.name = "Eigen-%s" % sk
		w.set_meta(&"enemy", true)
		Gear.save(w)
	for cl in classes:
		var a := Gear.from_template(classes[cl]) as ArmorData
		a.name = "Eigen-Rüstung %d" % cl
		a.set_meta(&"enemy", true)
		Gear.save(a)
	check(GameData.weapons().any(func(w: WeaponData) -> bool: return w.name.begins_with("Eigen-")), "eigene Waffen in GameData.weapons()")
	var swapped := 0
	var ok := true
	for seed_v in range(4711, 4741):
		var m := Mission.generate(seed_v)
		var base := Mission.generate(seed_v)
		for i in m.enemies.size():
			var d: UnitData = m.enemies[i]
			if d.weapons.is_empty():
				continue
			if d.weapons[0].name.begins_with("Eigen-"):
				swapped += 1
				ok = ok and d.weapons[0].skill == base.faction.units.filter(func(u: UnitData) -> bool: return u.name == d.name)[0].weapons[0].skill
			if d.armor and d.armor.name.begins_with("Eigen-") and d.armor.cls != base.faction.units.filter(func(u: UnitData) -> bool: return u.name == d.name)[0].armor.cls:
				ok = false
	check(swapped > 0 and ok, "Gegner bekommen eigene Ausrüstung (gleiche Fertigkeit/Klasse), %d Mal in 30 Missionen" % swapped)
	check(Mission.generate(4711).title == m0.title and Mission.generate(4711).enemies.size() == m0.enemies.size(), "Mission sonst unverändert")
	for f in Mission.all_factions():
		for u in f.units:
			check(not (not u.weapons.is_empty() and u.weapons[0].name.begins_with("Eigen-")), "Vorlagen der Fraktion bleiben unverändert")
	Gear.dir = old_dir


## Modell-Katalog (alle laden, lange Achse x) und Klänge (Dateien vorhanden, MG wieder mit MG-Klang)
func _test_models_sounds() -> void:
	var all := WeaponModels.all()
	check(all.size() == WeaponModels.LIST.size() and all.size() >= 68, "Modell-Katalog: alle %d Modelle laden" % all.size())
	var along_x := true
	for e in all:
		var n: Node3D = (e.scene as PackedScene).instantiate()
		var acc := [null]
		_aabb(n, Transform3D.IDENTITY, acc)
		var a: AABB = acc[0]
		if a.size.x < a.size.y or a.size.x < a.size.z:
			along_x = false
			print("  nicht entlang x: ", e.model, " ", a.size)
		n.free()
	check(along_x, "Modelle liegen entlang x (wie die Figur sie erwartet)")
	var w := WeaponData.new()
	WeaponModels.apply(w, WeaponModels.find("res://assets/weapons/melee/sword.tscn"))
	check(w.model != null and is_equal_approx(w.length_m, 0.95) and not w.two_handed, "Katalog-Eintrag auf Waffe übertragen")
	for k in [&"pistole", &"revolver", &"mp", &"sturmgewehr", &"minigun", &"schrotflinte", &"gewehr_schwer"]:
		check(ResourceLoader.exists("res://audio/sfx/%s.ogg" % k) and WeaponData.SOUNDS.has(k), "Klangdatei %s" % k)
	var mg: WeaponData = load("res://data/weapons/mg.tres").duplicate()
	check(mg.sound() == &"minigun", "MG: Klang Minigun (Entscheidung des Nutzers)")
	mg.sound_id = &""
	check(mg.sound() == &"mg", "ohne eigenen Klang: Feuerstoß-Waffe spielt den MG-Klang")
	var std := {&"laserpistole": "blaster-b", &"laserkarabiner": "blaster-d", &"sturmgewehr": "assault_rifle_2", &"energiehammer": "hammer_double"}
	for wid in std:
		var sw: WeaponData = load("res://data/weapons/%s.tres" % wid)
		check(sw.model != null and std[wid] in sw.model.resource_path and sw.sound_id != &"", "Standardwaffe %s: neues Modell und Klang" % wid)
	var lp: WeaponData = load("res://data/weapons/laserpistole.tres").duplicate()
	lp.sound_id = &"revolver"
	check(lp.sound() == &"revolver", "Klang je Waffe wählbar")


func _aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf * (n as Node3D).transform if n is Node3D else xf
	if n is MeshInstance3D:
		var a: AABB = t * (n as MeshInstance3D).get_aabb()
		acc[0] = a if acc[0] == null else (acc[0] as AABB).merge(a)
	for c in n.get_children():
		_aabb(c, t, acc)


## Beute, Beschädigung und Verlust (Entscheidungen des Nutzers 16.10.2026)
func _test_loot_wear() -> void:
	Dice.set_seed(21)
	var c := Combat.new(MapGenerator.generate(4711, "klein"), Roster.build_crew(Roster.start_crew()), Roster.build_units(Mission.generate(4711).enemies, &"enemy"))
	var u := c.crew()[0]
	var w := u.weapons[0]
	check(u.slot_of(w) == "w0" and u.weapon_wear(w) == 0, "Platz der Waffe 1")
	u.add_wear("w0")
	var foe := c.enemies()[0]
	for n in Hex.neighbors(u.pos):
		var t := c.map.tile(n)
		if t and c.map.walkable(t) and c.unit_at(n) == null:
			foe.pos = n
			break
	var info := c.attack_info(u, foe, w, {"pct": 60})
	check(info.get("ob", []).any(func(m: Dictionary) -> bool: return m.label == "Waffe beschädigt" and m.val == -10), "beschädigte Waffe: −10 auf den Angriff")
	u.add_wear("w0")
	u.add_wear("w0")
	u.add_wear("w0")
	check(u.weapon_wear(w) == -30 and u.weapon_broken(w) and not c.usable_weapons(u).has(w), "ab −30 unbrauchbar (nicht tiefer)")
	var a := c.crew().filter(func(o: Combatant) -> bool: return o.armor and o.armor.cls > 0)[0] as Combatant
	var cls := a.armor.cls
	for i in 3:
		a.add_wear("armor")
	check(a.armor_cls() == 0 and a.armor_db() == 0 and cls > 0, "Rüstung ab −30 wie keine")
	var b := c.crew().filter(func(o: Combatant) -> bool: return o.armor and o.armor.cls > 0 and o != a)[0] as Combatant
	c._apply_crit(b, Tables.roll_crit(GameData.crit_tables()[0], "D"), "D")
	check(int(b.wear.get("armor", 0)) == -10, "Kritischer D beschädigt die Rüstung")
	# Sieg: Beute aus der Ausrüstung der Gegner
	for e in c.enemies():
		e.state = Combatant.State.DEAD
	c.check_end()
	var keys := c.loot.map(func(l: Dictionary) -> String: return l.key)
	var e_weapons := 0
	for e in c.enemies():
		e_weapons += e.weapons.filter(func(x: WeaponData) -> bool: return x.power == "" and not Stock.EXCLUDE.has(x.resource_path)).size()
	check(c.loot.size() >= e_weapons and keys.all(func(k: String) -> bool: return k != ""), "Beute: alle Waffen der Gegner (%d Einträge)" % c.loot.size())
	check(c.loot.all(func(l: Dictionary) -> bool: return l.has("count") or (int(l.damage) <= 0 and int(l.damage) >= -30)), "Beute-Schaden 0 bis −30")
	var r := MissionResult.from_combat(c)
	check(r.loot.size() == c.loot.size() and r.units[u.id].wear.w0 == -30, "MissionResult: loot und wear")
	# Niederlage ohne Rückzug: Verlust; mit Rückzug: keiner
	var lost_n := 0
	var parts := 0
	for seed_v in 8:
		Dice.set_seed(100 + seed_v)
		var c2 := Combat.new(MapGenerator.generate(4711, "klein"), Roster.build_crew(Roster.start_crew()), Roster.build_units(Mission.generate(4711).enemies, &"enemy"))
		for o in c2.crew():
			o.state = Combatant.State.KO
		c2.check_end()
		for o in c2.crew():
			lost_n += o.lost.size()
			for slot in ["w0", "w1", "armor"]:
				var g := o.gear_at(slot)
				if g and not Stock.EXCLUDE.has(g.resource_path):
					parts += 1
	check(c2_ok(lost_n, parts), "Niederlage: rund die Hälfte verloren (%d von %d)" % [lost_n, parts])
	Dice.set_seed(7)
	var c3 := Combat.new(MapGenerator.generate(4711, "klein"), Roster.build_crew(Roster.start_crew()), Roster.build_units(Mission.generate(4711).enemies, &"enemy"))
	for o in c3.crew():
		o.state = Combatant.State.KO
	c3.deploying = false
	check(c3.retreat(), "Rückzug möglich")
	var worn := 0
	for o in c3.crew():
		worn += o.wear.size()
	check(c3.crew().all(func(o: Combatant) -> bool: return o.lost.is_empty()) and worn > 0 and c3.loot.is_empty(), "Rückzug: kein Verlust, Kampfunfähige teils beschädigt (%d)" % worn)


## Charakter-Modul: Beschädigung und Verlust aus dem MissionResult übernehmen
func _test_char_wear() -> void:
	var g := HubState.new()
	var by := {}
	for w in GameData.weapons():
		by[w.id] = w
	var ch := Roster.start_crew()[0]
	var sg: WeaponData = by[&"sturmgewehr"]
	var lp: WeaponData = by[&"laserpistole"]
	ch.weapons.assign([sg, lp])
	var arm := ch.armor
	ch.apply_result({"wear": {"w0": -10, "armor": -30, "w1": 0}})
	check(ch.wear == {"w0": -10, "armor": -30}, "wear übernommen (nur Abzüge)")
	check(Equipment.wear_text(ch, "w0") == "beschädigt " + Dice.fmt(-10) and Equipment.wear_text(ch, "armor") == "unbrauchbar" and Equipment.wear_text(ch, "w1") == "", "Text der Beschädigung")
	var ch2 := Character.from_dict(ch.to_dict())
	check(ch2.wear == ch.wear, "wear gespeichert und geladen")
	var u := Combatant.from_character(ch2, &"crew")
	check(u.weapon_wear(sg) == -10 and u.armor_broken(), "Kampf liest Character.wear")
	# Verlust: Plätze leeren, nichts ins Lager
	ch.apply_result({"wear": {"w0": -10, "armor": -30}, "lost": ["w1", "armor"]})
	check(ch.weapons == [sg] and ch.armor.resource_path == Gear.FALLBACK_ARMOR and ch.wear == {"w0": -10}, "Waffe 2 und Rüstung verloren")
	ch.apply_result({"lost": ["w0"]})
	check(ch.weapons[0].resource_path == Gear.FALLBACK_WEAPON and ch.wear.is_empty(), "Waffe 1 verloren → Fäuste")
	check(Stock.count(g, Stock.key_of(lp)) == 0 and Stock.count(g, Stock.key_of(arm)) == 0, "Verlorenes nicht im Lager")
	# Waffenkammer am Lager mit beschädigten Stücken (Lagerformat des Hubs: "Grundschlüssel|Schaden")
	ch.weapons.assign([sg])
	ch.armor = arm
	ch.wear = {"w0": -20, "armor": -10}
	var snap := Equipment.snapshot(ch)
	Stock.add(g, Stock.key_of(lp))
	check(Equipment.set_weapon(ch, 0, lp, g) == "" and not ch.wear.has("w0") and ch.wear.armor == -10, "Wechsel auf intaktes Stück: Platz heil")
	check(Stock.count(g, Stock.damaged_key(Stock.key_of(sg), -20)) == 1 and Stock.count(g, Stock.key_of(sg)) == 0, "Ablegen: mit Schaden ins Lager")
	check(Equipment.stock_damages(g, sg) == [-20] and Equipment.listed(g, sg, false), "beschädigtes Stück wählbar")
	check(Equipment.weapon_block(ch, 0, sg, g) == "nicht im Lager" and Equipment.weapon_block(ch, 0, sg, g, -20) == "", "nur die Schadensstufe im Lager")
	check(Equipment.set_weapon(ch, 0, sg, g, -20) == "" and ch.wear.w0 == -20 and Stock.count(g, Stock.key_of(lp)) == 1 and Stock.count(g, Stock.damaged_key(Stock.key_of(sg), -20)) == 0, "Anlegen: Schaden geht in den Platz")
	check(Equipment.set_weapon(ch, 0, lp, g) == "" and Equipment.restore(ch, snap, g) == "" and ch.wear == {"w0": -20, "armor": -10} and Stock.count(g, Stock.key_of(lp)) == 1 and Stock.count(g, Stock.damaged_key(Stock.key_of(sg), -20)) == 0, "zurücknehmen: Schaden und Lager wie vorher")
	Stock.add(g, Stock.key_of(arm))
	check(Equipment.set_armor(ch, arm, g) == "" and not ch.wear.has("armor") and Stock.count(g, Stock.damaged_key(Stock.key_of(arm), -10)) == 1, "Rüstung tauschen: beschädigte zurück ins Lager, intakte im Platz")
	check(Equipment.set_armor(ch, arm, g, -10) == "" and ch.wear.armor == -10 and Stock.count(g, Stock.key_of(arm)) == 1, "beschädigte Rüstung anlegen")
	check(Equipment.stock_damages(null, sg) == [0], "ohne Spiel nur intakt")
	# gute Stücke (+5) aus dem Handwerk: Schlüssel "…|+5", Character.wear = 5
	Stock.add(g, Stock.damaged_key(Stock.key_of(sg), 5))
	check(Equipment.stock_damages(g, sg)[0] == Stock.BONUS, "gutes Stück wählbar (zuerst)")
	check(Equipment.set_weapon(ch, 0, sg, g, Stock.BONUS) == "" and ch.wear.w0 == Stock.BONUS and Stock.count(g, Stock.damaged_key(Stock.key_of(sg), -20)) == 1, "+5 anlegen, altes mit Schaden zurück")
	check(Equipment.wear_text(ch, "w0") == "+5" and Equipment.wear_summary(ch, true).contains("+5") and not Equipment.wear_summary(ch).contains("+5"), "+5 in Text und Übersicht")
	check(Character.from_dict(ch.to_dict()).wear.w0 == Stock.BONUS, "+5 gespeichert")
	ch.apply_result({"wear": {"w0": 5, "armor": -10}})
	check(ch.wear.w0 == Stock.BONUS, "+5 aus dem Einsatz übernommen")
	check(Equipment.set_weapon(ch, 0, lp, g) == "" and Stock.count(g, Stock.damaged_key(Stock.key_of(sg), 5)) == 1 and not ch.wear.has("w0"), "+5 ablegen: zurück ins Lager als „|+5“")
	check(Equipment.stock_damages(null, sg) == [0], "ohne Spiel kein +5")


func c2_ok(lost_n: int, parts: int) -> bool:
	return parts > 0 and lost_n > parts * 0.3 and lost_n < parts * 0.7


## Waffenkammer am Lager (Schritt 3): Ausrüsten nimmt heraus, Ablegen legt zurück, Schild und Medikits im Lager
func _test_armory_stock() -> void:
	var g := HubState.new()
	var by := {}
	for w in GameData.weapons():
		by[w.id] = w
	var ch := Roster.start_crew()[0]
	ch.weapons.assign([by[&"laserpistole"]])
	ch.shield = false
	ch.medkits = 3
	var sg: WeaponData = by[&"sturmgewehr"]
	check(Equipment.weapon_block(ch, 0, sg, g) == "nicht im Lager" and not Equipment.listed(g, sg, false), "leeres Lager: Waffe nicht wählbar, ausgeblendet")
	check(Equipment.set_weapon(ch, 1, by[&"faeuste"], g) == "", "Fäuste immer verfügbar")
	Stock.add(g, Stock.key_of(sg))
	var before := g.stock.duplicate()
	var snap := {"weapons": ch.weapons.duplicate(), "armor": ch.armor, "shield": ch.shield, "medkits": ch.medkits}
	check(Equipment.set_weapon(ch, 0, sg, g) == "" and Stock.count(g, Stock.key_of(sg)) == 0
		and Stock.count(g, Stock.key_of(by[&"laserpistole"])) == 1, "Ausrüsten nimmt heraus, Ablegen legt zurück")
	var old_armor := ch.armor
	var none: ArmorData = load(Gear.FALLBACK_ARMOR)
	check(Equipment.set_armor(ch, none, g) == "" and Stock.count(g, Stock.key_of(old_armor)) == 1, "Rüstung ablegen → Lager")
	check(Equipment.set_shield(ch, true, g) != "", "Schild nur aus dem Lager")
	Equipment.set_weapon(ch, 0, by[&"laserpistole"], g)
	Stock.add(g, Equipment.SHIELD)
	check(Equipment.set_shield(ch, true, g) == "" and ch.shield and Stock.count(g, Equipment.SHIELD) == 0, "Schild aus dem Lager")
	Stock.add(g, Stock.key_of(by[&"energiehammer"]))
	Equipment.set_weapon(ch, 0, by[&"energiehammer"], g)
	check(not ch.shield and Stock.count(g, Equipment.SHIELD) == 1, "zweihändige Waffe legt den Schild ins Lager")
	check(Equipment.set_medkits(ch, 1, g) == 1 and Stock.count(g, Stock.MEDKIT) == 2, "Medikits zurücklegen")
	check(Equipment.set_medkits(ch, 9, g) == 3 and Stock.count(g, Stock.MEDKIT) == 0, "Medikits höchstens 3, aus dem Lager")
	Stock.take(g, Equipment.SHIELD)
	Stock.add(g, Equipment.SHIELD)
	check(Equipment.restore(ch, snap, g) == "" and ch.weapons == snap.weapons and ch.armor == snap.armor and ch.medkits == 3, "zurücknehmen")
	var same := true
	for k in before.keys() + g.stock.keys():
		var want := int(before.get(k, 0)) + (1 if k == Equipment.SHIELD else 0) + (1 if k == Stock.key_of(by[&"energiehammer"]) else 0)
		if Stock.count(g, k) != want:
			same = false
	check(same, "zurücknehmen stellt das Lager wieder her")
	# ohne Spiel unbegrenzt
	check(Equipment.set_weapon(ch, 0, by[&"mg"]) == "" and Equipment.set_medkits(ch, 3) == 3, "ohne Spielstand unbegrenzt")
	# Verbrauch im Einsatz
	ch.medkits = 3
	ch.apply_result({"used": {"medkits": 2}})
	check(ch.medkits == 1, "verbrauchte Medikits werden abgezogen")
