extends SceneTree
## Simulation Raumkampf, KI gegen KI (Crew-Seite = Vorschlag der Bord-KI, Startschiff, Startcrew aus dem Roster):
##   godot --headless --path godot --script res://tests/sim_space.gd -- 60          Kämpfe je Schwierigkeit
##   godot --headless --path godot --script res://tests/sim_space.gd -- 40 waffen   Wirkung je Schiffswaffe
##   godot --headless --path godot --script res://tests/sim_space.gd -- 60 fraktionen   Siege je Gegnerseite und Schwierigkeit
##   … -- 60 boss    Boss-Kämpfe (Gruppe fest, Schwierigkeit egal; Ziel etwa 70–75 %)
##   … -- 60 elite   wie oben, aber Elite-Kämpfe (docs/Raumkampf.md 4e; Ziel etwa 70–75 % Siege über alle Stufen)
## Ziele des Nutzers (17.10.2026, docs/Planung_Raumkampf.md 1c): Sieg 90/70/45 %, 8–12 Runden, Flucht < 10 %.

const DIFFS := ["leicht", "mittel", "schwer"]
const GOAL := {"leicht": 90, "mittel": 70, "schwer": 45}
var _elite := false
var _boss := false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 and args[0].is_valid_int() else 60
	Dice.set_seed(20261017)
	_elite = "elite" in args
	_boss = "boss" in args
	if "waffen" in args:
		_weapons(n)
	elif "ep" in args:
		_xp(n)
	elif "fraktionen" in args:
		_by_faction(n)
	else:
		_battles(n)
	quit()


func _factions() -> Array:
	return SpaceTemplates.faction_ids()


func _setup(diff: String, faction: String) -> Dictionary:
	return SpaceBattle.prepare(SpaceSetup.quick(diff, faction, _elite, _boss))


func _battles(n: int) -> void:
	print("Schwierigkeit | Siege (Ziel) | Runden Ø (Siege) | Flucht | Abbruch 40 R. | geentert | Notfall | selbst entert | Hülle Ø danach")
	var factions := _factions()
	for d in DIFFS:
		var st := {"win": 0, "rounds": 0, "win_rounds": 0, "flee": 0, "timeout": 0, "boarded": 0, "emergency": 0,
			"board": 0, "hull": 0}
		for i in n:
			var f: String = factions[i % factions.size()]
			var c := SpaceCombat.new(_setup(d, f), 1000 * DIFFS.find(d) + i)
			c.run_auto()
			st.rounds += mini(c.round_no, SpaceCombat.MAX_ROUNDS)
			st.hull += c.own.hull
			if c.result == &"sieg":
				st.win += 1
				st.win_rounds += c.round_no
				if c.boarded:
					st.board += 1
			elif c.round_no > SpaceCombat.MAX_ROUNDS:
				st.timeout += 1
			elif c.retreated:
				st.flee += 1
			elif c.boarding:
				st.boarded += 1
			elif c.emergency:
				st.emergency += 1
		print("%-13s | %3d %% (%d) | %4.1f (%4.1f) | %3d %% | %3d %% | %3d %% | %3d %% | %3d %% | %3.0f" % [d, _pct(st.win, n),
			GOAL[d], float(st.rounds) / n, float(st.win_rounds) / maxi(1, st.win), _pct(st.flee, n), _pct(st.timeout, n),
			_pct(st.boarded, n), _pct(st.emergency, n), _pct(st.board, maxi(1, st.win)), float(st.hull) / n])


## Je Waffe: statt der Startwaffe im Bug (Abwehrwaffen im Turm), reichlich Munition, Kämpfe „mittel“;
## Schaden je Schuss/Runde und Siegquote (Grundlage der Preise in ShipWeapons)
func _weapons(n: int) -> void:
	print("Waffe | Slot | Preis | Treffer % | Schaden/Schuss | Schaden/Runde je Waffe | Siege (mittel)")
	var factions := _factions()
	for key in ShipWeapons.keys():
		var st := {"shots": 0, "hits": 0, "dmg": 0, "rounds": 0, "win": 0}
		var turret: bool = ShipWeapons.data(key).slot == "turm"
		for i in n:
			var s := _setup("mittel", factions[i % factions.size()])
			s.ship.slots["turm" if turret else "bug"] = {"key": key, "damage": 0}
			s.ship_ammo = {"schiffsraketen": 20, "geschosse": 100}   # Munition kauft man getrennt: Waffe selbst bewerten
			var c := SpaceCombat.new(s, 5000 + i)
			c.ship_fired.connect(func(sh: SpaceShip, _t: SpaceShip, slot: String, r: Dictionary) -> void:
				if sh == c.own and slot == ("turm" if turret else "bug"):
					st.shots += 1
					if r.hit:
						st.hits += 1
					st.dmg += int(r.dmg))
			c.run_auto()
			st.rounds += mini(c.round_no, SpaceCombat.MAX_ROUNDS)
			if c.result == &"sieg":
				st.win += 1
		var count := 1
		print("%-18s | %s | %5d | %3d %% | %4.1f | %4.2f | %3d %%" % [ShipWeapons.name(key), "Turm" if turret else "normal",
			ShipWeapons.price(key), _pct(st.hits, st.shots), float(st.dmg) / maxi(1, st.shots),
			float(st.dmg) / maxi(1, st.rounds) / count, _pct(st.win, n)])


## EP je Station und Kampf (nur von Crew besetzte Stationen), zwei Aufstellungen der Startcrew:
## A = Posten nach Fähigkeit (SpaceSetup.quick), B = Technik-Team (Steuer, Navigation, Schilde, Technik 1–3, Computer
## mit Crew, Geschütze Bord-KI), damit auch die weiteren Techniker gemessen werden, C = alle Geschütze mit Crew
func _xp(n: int) -> void:
	print("Station | besetzt in Kämpfen | EP Ø je Kampf | EP höchstens | Ø je Runde")
	var factions := _factions()
	var sum := {}
	var per_char := {"sum": 0, "max": 0, "n": 0}
	for variant in ["A", "B", "C"]:
		for d in DIFFS:
			for i in n:
				var s := _setup(d, factions[i % factions.size()])
				if variant == "B":
					var crew: Array = s.crew
					var order := ["steuer", "navigation", "schilde", "technik", "technik_2", "technik_3"]
					var posts: Dictionary = s.posts
					for st in posts:
						posts[st] = SpaceSetup.KI
					for k in order.size():
						posts[order[k]] = String(crew[k % crew.size()].id)
					posts["computer"] = String(crew[0].id)   # Doppelbesetzung (Steuer + Computer)
				if variant == "C":
					var crew: Array = s.crew
					var posts: Dictionary = s.posts
					for st in posts:
						posts[st] = SpaceSetup.KI
					var k := 0
					for st in ["geschuetz_bug", "geschuetz_backbord", "geschuetz_steuerbord", "geschuetz_turm", "steuer", "schilde"]:
						posts[st] = String(crew[k % crew.size()].id)
						k += 1
				var c := SpaceCombat.new(s, 7000 + i + 1000 * DIFFS.find(d))
				c.run_auto()
				var rounds := mini(c.round_no, SpaceCombat.MAX_ROUNDS)
				for st in c.posts:
					if String(c.posts[st]) == SpaceSetup.KI:
						continue
					var key := String(st)
					if not sum.has(key):
						sum[key] = {"n": 0, "xp": 0, "max": 0, "rounds": 0}
					var x := int(c.station_xp.get(st, 0))
					sum[key].n += 1
					sum[key].xp += x
					sum[key].max = maxi(sum[key].max, x)
					sum[key].rounds += rounds
				for ch in c.crew:
					var t := 0
					for k in ch.xp_log:
						t += int(ch.xp_log[k])
					per_char.sum += t
					per_char.max = maxi(per_char.max, t)
					per_char.n += 1
	for key in ["steuer", "navigation", "schilde", "technik", "technik_2", "technik_3", "computer", "geschuetz_bug",
			"geschuetz_backbord", "geschuetz_steuerbord", "geschuetz_turm"]:
		if not sum.has(key):
			continue
		var r: Dictionary = sum[key]
		print("%-20s | %4d | %5.1f | %3d | %4.2f" % [key, r.n, float(r.xp) / r.n, r.max, float(r.xp) / maxi(1, r.rounds)])
	print("je Figur (alle Stationen zusammen): Ø %.1f EP, höchstens %d" % [float(per_char.sum) / per_char.n, per_char.max])


## Siege je Gegnerseite (n Kämpfe je Seite und Schwierigkeit), Ziel wie GOAL
func _by_faction(n: int) -> void:
	print("Seite | leicht | mittel | schwer | Runden Ø")
	var only := Array(OS.get_cmdline_user_args()).filter(func(a): return a in _factions())
	for f in (only if not only.is_empty() else _factions()):
		var line := "%-16s" % f
		var rounds := 0
		for d in DIFFS:
			var win := 0
			for i in n:
				var c := SpaceCombat.new(_setup(d, f), 1000 * DIFFS.find(d) + i)
				c.run_auto()
				rounds += mini(c.round_no, SpaceCombat.MAX_ROUNDS)
				if c.result == &"sieg":
					win += 1
			line += " | %3d %%" % _pct(win, n)
		print("%s | %4.1f" % [line, float(rounds) / (3 * n)])


func _pct(a: int, b: int) -> int:
	return roundi(100.0 * a / maxi(1, b))
