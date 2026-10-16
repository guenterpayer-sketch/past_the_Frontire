class_name Voyage
extends RefCounted
## Reise, Schiff, Credits (Regeln docs/Skillsystem.md 9): Reiseproben je Reisetag (Pilot, Navigation, Computer,
## Reparatur), Treibstoff, Hülle, Schiffsmaterial, Credits, Lohn und Beute, Kaufen im Raumhafen, große Reparatur.
## Die Werte liegen im HubState (credits, fuel, hull, material, emergency); hier nur die Regeln.

## Grundwerte ohne Schiffsausbau (mit Ausbau: HubState.tank_max(), hull_max(), fuel_per_day())
const TANK := 100
const HULL_MAX := 100
const START_CREDITS := 300
const START_MATERIAL := 2
## Schwierigkeit der Reiseproben (Rules.DIFFICULTY)
const DIFF := "mittel"
## Treibstoff je Reisetag ohne Ersparnis, Mindestverbrauch
const FUEL_PER_DAY := 10
const FUEL_MIN := 3
## ab hier gilt der Tank als knapp (2 Tage Grundverbrauch)
const FUEL_LOW := 20
## Ersparnis je Probe in Pilot, Navigation, Computer nach Ergebnis
const FUEL_SAVE := {&"teilerfolg": 1, &"erfolg": 2, &"herausragend": 4}
## Hülle je Reparaturprobe auf der Reise
const HULL_TRAVEL := {&"patzer": -10, &"fehlschlag": -5, &"teilerfolg": 0, &"erfolg": 2, &"herausragend": 4}
## große Reparatur durch die Crew (1 Tag, 1 Material)
const HULL_CREW := {&"patzer": -5, &"fehlschlag": 0, &"teilerfolg": 10, &"erfolg": 20, &"herausragend": 40}
## Raumhafen
const FUEL_PRICE := 5
const FUEL_PRICE_EMERGENCY := 10
const MATERIAL_PRICE := 60
const YARD_HULL := 25
const YARD_COST := 40
## Lohn bei Sieg je Schwierigkeit, Faktor je Fraktion (Dateiname der FactionData)
const PAY := {"leicht": 80, "mittel": 140, "schwer": 220}
const PAY_FACTOR := {"rote_sonne": 1.2, "konzern": 1.2}
## Beute (Schiffsmaterial) bei Sieg je Schwierigkeit, Zuschlag je Fraktion
const LOOT := {"leicht": 0, "mittel": 1, "schwer": 2}
const LOOT_BONUS := {"schmuggler": 1}
## Munition (Arten Ammo.TYPES): Startvorrat, Preis je Schuss, Kaufpakete, Beute bei Sieg (eine zufällige Art)
const AMMO_START := {"energie": 200, "projektil": 300, "raketen": 6}
const AMMO_PRICE := {"energie": 2, "projektil": 2, "raketen": 50}
const AMMO_PACKS := {"energie": [30, 100], "projektil": [30, 100], "raketen": [1, 5]}
const AMMO_LOOT := {"energie": [10, 40], "projektil": [10, 40], "raketen": [1, 1]}

## Reiseposten: Fertigkeit, Station (Character.station), Anzeigename
const POSTS := [
	{"skill": &"pilot", "station": "Steuer", "name": "Pilot"},
	{"skill": &"navigation", "station": "Navigation", "name": "Navigation"},
	{"skill": &"computer", "station": "Computer", "name": "Computer"},
	{"skill": &"rsReparatur", "station": "Technik", "name": "Reparatur"},
]

static var _expect := {}


## Wer darf auf Reiseposten: an Bord, nicht gesperrt (verwundet), nicht in der Krankenstation eingeteilt
static func available(g: HubState) -> Array[Character]:
	var out: Array[Character] = []
	for c in Campaign.crew():
		if not c.is_locked() and not String(c.id) in g.medics:
			out.append(c)
	return out


## Einteilung: je Posten {post, ch (oder null), own (eigene Station)}. Zuerst die Station, dann die Besten unter den Übrigen
## (höchste Summe über die freien Posten); jede Person höchstens einen Posten.
static func assign(g: HubState) -> Array[Dictionary]:
	var free := available(g)
	var out: Array[Dictionary] = []
	for p in POSTS:
		out.append({"post": p, "ch": null, "own": false})
	for e in out:
		for c in free:
			if c.station == e.post.station:
				e.ch = c
				e.own = true
				free.erase(c)
				break
	var open: Array[Dictionary] = []
	for e in out:
		if e.ch == null:
			open.append(e)
	var best := _best_fill(open, free, 0, [])
	for i in open.size():
		open[i].ch = best.people[i] if i < best.people.size() else null
	return out


## Freie Posten so besetzen, dass die Summe der Fertigkeitswerte am höchsten ist (wenige Posten, wenig Crew: alle Möglichkeiten)
static func _best_fill(open: Array[Dictionary], free: Array[Character], i: int, used: Array) -> Dictionary:
	if i >= open.size() or used.size() >= free.size():
		return {"sum": 0, "people": []}
	var best := {"sum": -1000000, "people": []}
	for c in free:
		if c in used:
			continue
		var rest := _best_fill(open, free, i + 1, used + [c])
		var sum: int = Rules.skill_total(c, open[i].post.skill) + int(rest.sum)
		if sum > int(best.sum):
			best = {"sum": sum, "people": [c] + rest.people}
	return best


## Für Tests: fester Ausgang aller Proben (Ergebnis-ID, leer = normal würfeln)
static var fixed_result: StringName = &""
const _FIXED_TOTAL := {&"patzer": -50, &"fehlschlag": 50, &"teilerfolg": 90, &"erfolg": 150, &"herausragend": 200}


## Probe ohne Kampf-Protokoll: offener W100 + Fertigkeit + Schwierigkeit (Standard „mittel“); EP wie Rules.maneuver (Erfolg voll, sonst halb, Patzer 0)
static func check(c: Character, skill: StringName, extra := 0, diff_id := DIFF) -> Dictionary:
	var diff: Dictionary = Rules.DIFFICULTY[diff_id]
	var roll := Dice.open_d100()
	var bonus := Rules.skill_total(c, skill) + int(diff.mod) + extra
	var total: int = roll.total + bonus
	if fixed_result != &"":
		total = int(_FIXED_TOTAL[fixed_result])
	var res := Rules.maneuver_result(total)
	var xp := 0
	if Rules.is_success(res):
		xp = diff.xp
	elif res.id != &"patzer":
		xp = int(diff.xp) / 2
	if xp > 0:
		Rules.ensure_skill(c, skill).xp += xp
	return {"name": c.name, "skill": skill, "roll": roll, "bonus": bonus, "total": total, "result": res.id, "result_name": res.name, "xp": xp}


## Ein Reisetag: Proben, Treibstoff, Hülle. Gibt die Zeile für den Reisebericht zurück.
static func travel_day(g: HubState, day_no: int) -> Dictionary:
	var row := {"day": day_no, "checks": [], "fuel": 0, "hull": 0}
	var save := 0
	for e in assign(g):
		if e.ch == null:
			row.checks.append({})
			continue
		var r := check(e.ch, e.post.skill, g.travel_bonus() + Galley.malus(g) + ShipArms.travel_malus(g, e.post.skill))
		row.checks.append(r)
		if e.post.skill == &"rsReparatur":
			row.hull = HULL_TRAVEL[r.result]
		else:
			save += FUEL_SAVE.get(r.result, 0)
	var use := maxi(FUEL_MIN, g.fuel_per_day() - save)
	if g.fuel <= 0:
		use = 0          # Notsprit
	elif use >= g.fuel:
		use = g.fuel
		g.emergency = true
	row.fuel = -use
	g.fuel -= use
	var h0 := g.hull
	g.hull = clampi(g.hull + int(row.hull), 0, g.hull_max())
	row.hull = g.hull - h0
	return row


## Erwartete Ersparnis einer Probe mit diesem Bonus (offener W100, zweiter Wurf berücksichtigt)
static func expected_save(bonus: int) -> float:
	if _expect.has(bonus):
		return _expect[bonus]
	var sum := 0.0
	for f in range(1, 101):
		if f >= 96 or f <= 5:
			var s := 1 if f >= 96 else -1
			for x in range(1, 101):
				sum += FUEL_SAVE.get(Rules.maneuver_result(f + s * x + bonus).id, 0) / 100.0
		else:
			sum += FUEL_SAVE.get(Rules.maneuver_result(f + bonus).id, 0)
	_expect[bonus] = sum / 100.0
	return _expect[bonus]


## Geschätzter Verbrauch für n Reisetage mit der aktuellen Einteilung (ganzzahlig gerundet)
static func estimate_fuel(g: HubState, days: int) -> int:
	var save := 0.0
	for e in assign(g):
		if e.ch != null and e.post.skill != &"rsReparatur":
			save += expected_save(Rules.skill_total(e.ch, e.post.skill) + int(Rules.DIFFICULTY[DIFF].mod) + g.travel_bonus()
				+ ShipArms.travel_malus(g, e.post.skill))
	return roundi(maxf(FUEL_MIN, g.fuel_per_day() - save) * days)


## Treibstoffpreis je Einheit (nach Notsprit doppelt)
static func fuel_price(g: HubState) -> int:
	return TradeSkills.adj(FUEL_PRICE_EMERGENCY if g.emergency else FUEL_PRICE, TradeSkills.ship_factor(g))


## Schiffsmaterial je Einheit und Werftlohn der großen Reparatur (nach Verhandeln)
static func material_price(g: HubState) -> int:
	return TradeSkills.adj(MATERIAL_PRICE, TradeSkills.ship_factor(g))


static func yard_cost(g: HubState) -> int:
	return TradeSkills.adj(YARD_COST, TradeSkills.ship_factor(g))


## Munition je Schuss: Kauf nach Handeln, Verkauf nach Handeln (Anteil)
static func ammo_price(g: HubState, type: String) -> int:
	return maxi(1, TradeSkills.adj(int(AMMO_PRICE[type]), TradeSkills.buy_factor(g)))


static func ammo_sell(g: HubState, type: String, n: int) -> int:
	return int(floor(n * int(AMMO_PRICE[type]) * TradeSkills.sell_factor(g)))


## Tanken (nur im Hafen); geht auch ohne genug Credits (Notkredit). Gibt die getankte Menge zurück.
static func buy_fuel(g: HubState, amount: int) -> int:
	if not g.is_harbor(g.position):
		return 0
	amount = mini(amount, g.tank_max() - g.fuel)
	if amount <= 0:
		return 0
	g.credits -= amount * fuel_price(g)
	g.fuel += amount
	g.emergency = false
	return amount


## Notlage Hülle 0: Werft und Material gehen dann auch auf Notkredit
static func hull_emergency(g: HubState) -> bool:
	return g.hull <= 0


static func can_buy_material(g: HubState, n := 1) -> bool:
	return g.is_harbor(g.position) and (g.credits >= n * material_price(g) or hull_emergency(g))


static func buy_material(g: HubState, n := 1) -> bool:
	if not can_buy_material(g, n):
		return false
	g.credits -= n * material_price(g)
	g.material += n
	return true


static func can_yard_repair(g: HubState) -> bool:
	return g.is_harbor(g.position) and g.hull < g.hull_max() and g.material >= 1 and (g.credits >= yard_cost(g) or hull_emergency(g))


## Werft: große Reparatur (+25 Hülle für 1 Material + 40 Cr)
static func yard_repair(g: HubState) -> bool:
	if not can_yard_repair(g):
		return false
	g.material -= 1
	g.credits -= yard_cost(g)
	g.hull = mini(g.hull_max(), g.hull + YARD_HULL)
	return true


## Wer die große Reparatur durch die Crew macht: Station Technik, sonst der Beste in Reparatur
static func repairer(g: HubState) -> Character:
	var free := available(g)
	for c in free:
		if c.station == "Technik":
			return c
	var best: Character = null
	for c in free:
		if best == null or Rules.skill_total(c, &"rsReparatur") > Rules.skill_total(best, &"rsReparatur"):
			best = c
	return best


static func can_crew_repair(g: HubState) -> bool:
	return g.hull < g.hull_max() and g.material >= 1 and repairer(g) != null


## Große Reparatur durch die Crew (überall): 1 Material, Reparaturprobe; der Tag vergeht im HubState (crew_repair)
static func crew_repair(g: HubState) -> Dictionary:
	if not can_crew_repair(g):
		return {}
	var r := check(repairer(g), &"rsReparatur", Galley.malus(g))
	g.material -= 1
	var h0 := g.hull
	g.hull = clampi(g.hull + int(HULL_CREW[r.result]), 0, g.hull_max())
	r.hull = g.hull - h0
	return r


## Munition kaufen (nur im Hafen, nur mit genug Credits)
static func can_buy_ammo(g: HubState, type: String, n: int) -> bool:
	return g.is_harbor(g.position) and n > 0 and g.credits >= n * ammo_price(g, type)


static func buy_ammo(g: HubState, type: String, n: int) -> bool:
	if not can_buy_ammo(g, type, n):
		return false
	g.credits -= n * ammo_price(g, type)
	g.ammo[type] = int(g.ammo.get(type, 0)) + n
	return true


## Munition verkaufen (nur im Hafen, halber Preis)
static func can_sell_ammo(g: HubState, type: String, n: int) -> bool:
	return g.is_harbor(g.position) and n > 0 and int(g.ammo.get(type, 0)) >= n


static func sell_ammo(g: HubState, type: String, n: int) -> bool:
	if not can_sell_ammo(g, type, n):
		return false
	g.ammo[type] = int(g.ammo[type]) - n
	g.credits += ammo_sell(g, type, n)
	return true


## Verbrauch aus dem Einsatz abziehen (MissionResult.ammo_used), nicht unter 0. Gibt den tatsächlichen Abzug zurück.
static func use_ammo(g: HubState, used: Dictionary) -> Dictionary:
	var out := {}
	for t in used:
		var have := int(g.ammo.get(String(t), 0))
		var n := mini(have, int(used[t]))
		g.ammo[String(t)] = have - n
		if n > 0:
			out[String(t)] = n
	return out


## Munitions-Beute bei Sieg: eine zufällige Art, Menge aus AMMO_LOOT
static func ammo_loot() -> Dictionary:
	var types := AMMO_LOOT.keys()
	var t: String = types[randi() % types.size()]
	return {t: randi_range(AMMO_LOOT[t][0], AMMO_LOOT[t][1])}


## Lohn und Beute für einen Auftrag; leer bei Niederlage/Rückzug
static func payout(difficulty: String, faction_path: String, win: bool) -> Dictionary:
	if not win:
		return {}
	var key := faction_path.get_file().get_basename()
	var base: int = PAY.get(difficulty, 0)
	var total := roundi(base * float(PAY_FACTOR.get(key, 1.0)))
	return {"pay": base, "bonus": total - base, "factor": float(PAY_FACTOR.get(key, 1.0)),
		"loot": int(LOOT.get(difficulty, 0)) + int(LOOT_BONUS.get(key, 0)), "ammo": ammo_loot()}
