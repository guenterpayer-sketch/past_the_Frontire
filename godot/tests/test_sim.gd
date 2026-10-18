extends SceneTree
## KI gegen KI: godot --headless --path godot --script res://tests/test_sim.gd -- [Anzahl Kämpfe] [missionen] [leicht|mittel|schwer] [trupp=N] [ab=K] [budget=N]
## Mit "missionen": Gegner aus dem Missionsgenerator (Schwierigkeit reihum leicht/mittel/schwer, oder nur die genannte),
## Siege je Schwierigkeit. Truppgröße wie im Spiel (Campaign.max_squad: schwer 8, sonst 6) oder fest mit trupp=N;
## mehr als 6 Figuren: Kopien der Startcrew der Reihe nach (Vela, Ikko, …).


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var fights := int(args[0]) if args.size() > 0 else 30
	var stats := {&"sieg": 0, &"niederlage": 0, "stuck": 0, "rounds": 0, "dead": 0, "ko": 0}
	var missions := args.size() > 1 and args[1] == "missionen"
	var only := ""
	var squad_n := 0
	var offset := 0   # ab=K: andere Kämpfe (Würfel und Missionen ab K), z. B. für parallele Läufe
	for a in args.slice(2):
		if a in ["leicht", "mittel", "schwer"]:
			only = a
		elif a.begins_with("trupp="):
			squad_n = int(a.substr(6))
		elif a.begins_with("ab="):
			offset = int(a.substr(3))
		elif a.begins_with("budget="):
			Mission.budget_override[only if only != "" else "schwer"] = int(a.substr(7))
	var by_diff := {}
	var t0 := Time.get_ticks_msec()
	for k in fights:
		var i := k + offset
		Dice.set_seed(1000 + i)
		var c: Combat
		var diff := ""
		var lage_name := ""
		if missions:
			diff = only if only != "" else ["leicht", "mittel", "schwer"][i % 3]
			var mi := Mission.generate(5000 + i, diff)
			lage_name = String(mi.lage)
			var n := squad_n if squad_n > 0 else Campaign.max_squad(diff)
			c = Combat.new(MapGenerator.for_mission(mi.map_seed, mi), _crew(n), Roster.build_units(mi.enemies, &"enemy"))
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
		while c.result == &"" and steps < 10000 and c.round_no <= 100:
			var t := Time.get_ticks_usec()
			ai.act(c)
			var dt := Time.get_ticks_usec() - t
			stats.max_step = maxi(stats.get("max_step", 0), dt)
			stats.steps_total = stats.get("steps_total", 0) + 1
			stats.time_total = stats.get("time_total", 0) + dt
			steps += 1
		if c.result == &"":
			stats.stuck += 1
			var alive := func(t: StringName) -> int: return c.units.filter(func(u: Combatant) -> bool: return u.team == t and u.is_ok()).size()
			print("  hängengeblieben: Kampf %d, %s/%s %s, Runde %d, Schritte %d, Crew %d, Gegner %d" % [i, c.map.map_type, c.map.size_info.get("id", ""), lage_name,
				c.round_no, steps, alive.call(&"crew"), alive.call(&"enemy")])
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
	if missions:
		print("  Gegnerbudget: %s" % ", ".join(Mission.DIFFICULTIES.keys().map(func(k: String) -> String: return "%s %d" % [k, int(Mission.budget_override.get(k, Mission.DIFFICULTIES[k].budget))])))
	print("OK" if stats.stuck == 0 else "FEHLER: Kämpfe ohne Ende")
	quit(0 if stats.stuck == 0 else 1)


## n Crew-Figuren: die Startcrew, darüber hinaus Kopien der Reihe nach (eigene IDs)
func _crew(n: int) -> Array[Combatant]:
	var units: Array[UnitData] = GameData.crew().units
	var out: Array[Combatant] = []
	for i in n:
		var u := Combatant.create(units[i % units.size()], &"crew")
		if i >= units.size():
			u.id = "%s_%d" % [u.id, i / units.size() + 1]
		out.append(u)
	return out
