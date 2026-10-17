extends SceneTree
## Simulation Raumkampf, KI gegen KI (Crew-Seite = Vorschlag der Bord-KI, Startschiff, Startcrew aus dem Roster):
##   godot --headless --path godot --script res://tests/sim_space.gd -- 60          Kämpfe je Schwierigkeit
##   godot --headless --path godot --script res://tests/sim_space.gd -- 40 waffen   Wirkung je Schiffswaffe
## Ziele des Nutzers (17.10.2026, docs/Planung_Raumkampf.md 1c): Sieg 90/70/45 %, 8–12 Runden, Flucht < 10 %.

const DIFFS := ["leicht", "mittel", "schwer"]
const GOAL := {"leicht": 90, "mittel": 70, "schwer": 45}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 and args[0].is_valid_int() else 60
	Dice.set_seed(20261017)
	if "waffen" in args:
		_weapons(n)
	else:
		_battles(n)
	quit()


func _factions() -> Array:
	return SpaceTemplates.faction_ids()


func _setup(diff: String, faction: String) -> Dictionary:
	return SpaceBattle.prepare(SpaceSetup.quick(diff, faction))


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


func _pct(a: int, b: int) -> int:
	return roundi(100.0 * a / maxi(1, b))
