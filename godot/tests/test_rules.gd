extends SceneTree
## Regeltest ohne Grafik: godot --headless --path godot --script res://tests/test_rules.gd

const Dice := preload("res://scripts/dice.gd")
const Rules := preload("res://scripts/rules.gd")
const Hex := preload("res://scripts/hexgrid.gd")

var fails := 0


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FEHLER: ", what)


func _init() -> void:
	# Gleiche Werte wie tests/sim.js (Projektil gegen Mittel: Schwelle 90, Kritische ab 130)
	check(not Rules.lookup_attack("projektil", 89, 2, 1.0).hit, "89 verfehlt")
	check(Rules.lookup_attack("projektil", 90, 2, 1.0).dmg == 2, "90 = 2 Schaden")
	check(Rules.lookup_attack("projektil", 129, 2, 1.0).severity == "", "129 kein Krit")
	check(Rules.lookup_attack("projektil", 130, 2, 1.0).severity == "A", "130 Krit A")
	check(Rules.lookup_attack("projektil", 145, 2, 1.0).severity == "B", "145 Krit B")
	check(Rules.lookup_attack("projektil", 190, 2, 1.0).severity == "E", "190 Krit E")
	var w: Dictionary = Rules.WEAPONS.sturmgewehr
	check(Rules.range_mod(w, 3.0) == 10, "Kernschussweite")
	check(Rules.range_mod(w, 25.0) == 0, "Stufe 1")
	check(Rules.range_mod(w, 26.0) == -20, "Stufe 2")
	check(Rules.range_mod(w, 101.0) == Rules.OUT_OF_RANGE, "außer Reichweite")
	# Hexraster: Welt <-> Feld und Abstände
	for t in [Vector2i(0, 0), Vector2i(5, 3), Vector2i(21, 15), Vector2i(7, 8)]:
		check(Hex.from_world(Hex.to_world(t)) == t, "Feld %s zurückgerechnet" % t)
		for n in Hex.neighbors(t):
			check(Hex.distance(t, n) == 1, "Nachbar %s von %s" % [n, t])
			check(absf(Hex.to_world(t).distance_to(Hex.to_world(n)) - 1.5) < 0.01, "Nachbarabstand 1,5 m")
	# W100 aus zwei W10: alle Werte 1–100 gleich oft
	Dice.rng.seed = 1
	var cnt := {}
	for i in 100000:
		var v := Dice.d100()
		cnt[v] = cnt.get(v, 0) + 1
	check(not cnt.has(0), "keine 0")
	for v in range(1, 101):
		check(cnt.get(v, 0) > 800 and cnt.get(v, 0) < 1200, "Wert %d: %d" % [v, cnt.get(v, 0)])
	var hi := 0
	var lo := 0
	for i in 100000:
		var r := Dice.open_d100()
		check(r.dice.size() == r.rolls.size(), "Würfelpaare passen zu Würfen")
		if r.total > 100:
			hi += 1
		if r.total < 1:
			lo += 1
	print("Offener W100: >100 in %.2f %%, <1 in %.2f %%" % [hi / 1000.0, lo / 1000.0])
	print("OK" if fails == 0 else "%d Fehler" % fails)
	quit(1 if fails else 0)
