class_name Dice
extends RefCounted
## Würfel: W100 im Rolemaster-Stil aus zwei W10 (Zehner + Einer, 00 = 100),
## offen nach oben (96–00: weiter würfeln und addieren) und unten (01–05: würfeln und abziehen).

static var rng := RandomNumberGenerator.new()


static func set_seed(s: int) -> void:
	rng.seed = s


static func randomize() -> void:
	rng.randomize()


## Wn mit den Seiten 1..n
static func d(n: int) -> int:
	return rng.randi_range(1, n)


## W10 mit den Seiten 0–9
static func d10() -> int:
	return rng.randi_range(0, 9)


## Ein Würfelpaar: t = Zehner, o = Einer, v = Wert 1–100
static func d100_pair() -> Dictionary:
	var t := d10()
	var o := d10()
	var v := t * 10 + o
	return {"t": t, "o": o, "v": 100 if v == 0 else v}


static func d100() -> int:
	return d100_pair().v


## Offener Wurf. fumble > 0: unmodifizierter Wurf <= fumble ist ein Patzer.
## Ergebnis: first, rolls (Nachwürfe nach unten negativ), total, fumble, dice (alle Würfelpaare)
static func open_d100(fumble := 0) -> Dictionary:
	var pairs: Array = []
	var p := d100_pair()
	pairs.append(p)
	var first: int = p.v
	var rolls: Array = [first]
	var total := first
	if fumble > 0 and first <= fumble:
		return {"first": first, "rolls": rolls, "total": total, "fumble": true, "dice": pairs}
	var sign := 0
	if first >= 96:
		sign = 1
	elif first <= 5:
		sign = -1
	while sign != 0:
		p = d100_pair()
		pairs.append(p)
		rolls.append(sign * p.v)
		total += sign * p.v
		if p.v < 96:
			break
	return {"first": first, "rolls": rolls, "total": total, "fumble": false, "dice": pairs}


## "47" oder "(98+27=125)"
static func format_roll(roll: Dictionary) -> String:
	var rolls: Array = roll.rolls
	if rolls.size() == 1:
		return str(roll.first)
	var s := str(rolls[0])
	for i in range(1, rolls.size()):
		var r: int = rolls[i]
		s += ("−%d" % -r) if r < 0 else ("+%d" % r)
	return "(%s=%d, offen)" % [s, roll.total]


static func fmt(v: int) -> String:
	return ("+%d" % v) if v >= 0 else ("−%d" % -v)
