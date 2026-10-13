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
	var u := Roster.build_team(GameData.crew(), &"crew")[0]
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
	check(Rules.next_bonus_step(70) == 71 and Rules.next_bonus_step(50) == 71, "nächste Bonusstufe")
	var crew: Array[Combatant] = [u]
	var backup := FileAccess.get_file_as_string(Roster.PATH) if FileAccess.file_exists(Roster.PATH) else ""
	Roster.save_progress(crew)
	var p := Roster.load_progress()
	var v := Combatant.create(u.data, &"crew", p.get(u.id, {}))
	check(v.attrs.KON == kon + 1 and v.free_xp == 1 and v.skills[&"kochen"].rank == 1, "Fortschritt gespeichert und geladen")
	check(v.max_hp == Rules.max_hp(v), "TP aus gesteigerter KON")
	# altes Format (nur Fertigkeiten) wird weiter gelesen
	var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({String(u.id): {"gewehre": {"rank": 9, "xp": 4}}}))
	f.close()
	p = Roster.load_progress()
	check(p[u.id].skills[&"gewehre"].rank == 9 and p[u.id].free_xp == 0, "altes Speicherformat")
	if backup != "":
		f = FileAccess.open(Roster.PATH, FileAccess.WRITE)
		f.store_string(backup)
		f.close()
	else:
		Roster.reset()


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
	c.start()
	check(not c.can_deploy(a, free_tile), "nach Kampfbeginn keine Aufstellung mehr")
