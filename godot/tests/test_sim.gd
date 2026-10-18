extends SceneTree
## KI gegen KI: godot --headless --path godot --script res://tests/test_sim.gd -- [Anzahl Kämpfe] [missionen]
## Mit "missionen": Gegner aus dem Missionsgenerator (Schwierigkeit reihum leicht/mittel/schwer), Siege je Schwierigkeit.


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var fights := int(args[0]) if args.size() > 0 else 30
	var stats := {&"sieg": 0, &"niederlage": 0, "stuck": 0, "rounds": 0, "dead": 0, "ko": 0}
	var missions := args.size() > 1 and args[1] == "missionen"
	var by_diff := {}
	var t0 := Time.get_ticks_msec()
	for i in fights:
		Dice.set_seed(1000 + i)
		var c: Combat
		var diff := ""
		if missions:
			diff = ["leicht", "mittel", "schwer"][i % 3]
			var mi := Mission.generate(5000 + i, diff)
			c = Combat.new(MapGenerator.for_mission(mi.map_seed, mi), Roster.build_team(GameData.crew(), &"crew"), Roster.build_units(mi.enemies, &"enemy"))
		else:
			# alle Kartentypen reihum, abwechselnd quadratisch, Startlagen reihum
			var types: Array = MapTypes.GROUND + [MapTypes.SHIP]
			var ty: StringName = types[i % types.size()]
			var lagen: Array = Mission.LAGEN.keys()
			var m := MapGenerator.generate(5000 + i, BattleMap.SIZES[i % 3].id, ty, i % 2 == 1, lagen[(i / 2) % lagen.size()])
			c = Combat.new(m, Roster.build_team(GameData.crew(), &"crew"), Roster.build_team(GameData.enemies(), &"enemy"))
		var ai := CombatAI.new()
		c.start()
		var steps := 0
		while c.result == &"" and steps < 5000 and c.round_no <= 60:
			var t := Time.get_ticks_usec()
			ai.act(c)
			var dt := Time.get_ticks_usec() - t
			stats.max_step = maxi(stats.get("max_step", 0), dt)
			stats.steps_total = stats.get("steps_total", 0) + 1
			stats.time_total = stats.get("time_total", 0) + dt
			steps += 1
		if c.result == &"":
			stats.stuck += 1
			continue
		stats[c.result] += 1
		if missions:
			var d: Array = by_diff.get(diff, [0, 0])
			d[0] += 1 if c.result == &"sieg" else 0
			d[1] += 1
			by_diff[diff] = d
		stats.rounds += c.round_no
		for u in c.crew():
			if u.is_dead():
				stats.dead += 1
			elif u.is_down():
				stats.ko += 1
		if i == 0:
			for u in c.crew():
				print("  %s: %s" % [u.name, u.xp_log])
	print("Kämpfe: %d | Crew-Siege: %d | Niederlagen: %d | hängengeblieben: %d" % [fights, stats[&"sieg"], stats[&"niederlage"], stats.stuck])
	print("Laufzeit: %d ms pro Kampf, KI-Schritt Ø %.1f ms, max. %.0f ms" % [(Time.get_ticks_msec() - t0) / fights,
		stats.time_total / 1000.0 / maxi(1, stats.steps_total), stats.max_step / 1000.0])
	print("Ø Runden: %.1f | Ø tote Crew: %.2f | Ø kampfunfähige Crew (bewusstlos/sterbend): %.2f" % [float(stats.rounds) / maxi(1, fights - stats.stuck), float(stats.dead) / fights, float(stats.ko) / fights])
	for d in by_diff:
		print("  %s: %d von %d gewonnen" % [d, by_diff[d][0], by_diff[d][1]])
	print("OK" if stats.stuck == 0 else "FEHLER: Kämpfe ohne Ende")
	quit(0 if stats.stuck == 0 else 1)
