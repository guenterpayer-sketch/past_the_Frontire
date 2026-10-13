extends RefCounted
## W100 im Rolemaster-Stil aus zwei W10 (Zehner + Einer, 00 = 100),
## offen nach oben (96–00: weiter würfeln und addieren) und unten (01–05: würfeln und abziehen).

static var rng := RandomNumberGenerator.new()


## W10 mit den Seiten 0–9
static func d10() -> int:
	return rng.randi_range(0, 9)


## Ein Würfelpaar: t = Zehner, o = Einer, v = Wert 1–100
static func d100_pair() -> Dictionary:
	var t := d10()
	var o := d10()
	var v := t * 10 + o
	if v == 0:
		v = 100
	return {"t": t, "o": o, "v": v}


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
	if first >= 96:
		while true:
			p = d100_pair()
			pairs.append(p)
			rolls.append(p.v)
			total += p.v
			if p.v < 96:
				break
	elif first <= 5:
		while true:
			p = d100_pair()
			pairs.append(p)
			rolls.append(-p.v)
			total -= p.v
			if p.v < 96:
				break
	return {"first": first, "rolls": rolls, "total": total, "fumble": false, "dice": pairs}
