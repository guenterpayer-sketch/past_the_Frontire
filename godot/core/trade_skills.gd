class_name TradeSkills
extends RefCounted
## Handelsfertigkeiten im Raumhafen (Entscheidungen des Nutzers 16.10.2026): je Fertigkeit eine Probe pro Tag im Hafen,
## die gewählte Figur würfelt (Mittel, EP wie Reiseproben). Das Ergebnis gilt an diesem Tag in diesem Hafen.
## Ohne Probe gilt es wie ein Fehlschlag (5 % schlechter).
##   Handeln: Kauf- und Verkaufspreise von Waffen, Rüstungen, Munition, Medikits
##   Verhandeln: Preise für das Schiff (Treibstoff, Werft-Reparatur, Schiffsmaterial, Werft-Ausbau)
##   Gassenwissen: Anteil des Sortiments
## Die Würfe liegen in HubState.trade_rolls {Fertigkeit: {day, system, result, total, name}}.

const SKILLS := [&"handeln", &"verhandeln", &"gassenwissen"]
const NONE := &"fehlschlag"
## Kauf (Handeln) bzw. Schiffspreise (Verhandeln) als Faktor
const BUY := {&"patzer": 1.2, &"fehlschlag": 1.05, &"teilerfolg": 1.0, &"erfolg": 0.9, &"herausragend": 0.8}
## Verkauf als Anteil des Kaufpreises (Handeln)
const SELL := {&"patzer": 0.3, &"fehlschlag": 0.45, &"teilerfolg": 0.5, &"erfolg": 0.6, &"herausragend": 0.7}
## Anteil des Sortiments (Gassenwissen)
const SHARE := {&"patzer": 0.3, &"fehlschlag": 0.5, &"teilerfolg": 0.6, &"erfolg": 0.75, &"herausragend": 0.9}


## Für Tests: feste Ergebnisstufe für alle Handelsfertigkeiten (leer = normal würfeln/Fehlschlag)
static var fixed: StringName = &""


## Heutiger Wurf dieser Fertigkeit hier ({} = noch nicht gewürfelt)
static func roll_of(g: HubState, skill: StringName) -> Dictionary:
	var r: Dictionary = g.trade_rolls.get(String(skill), {})
	if r.is_empty() or int(r.day) != g.day or int(r.system) != g.position:
		return {}
	return r


## Ergebnisstufe (ohne Wurf wie Fehlschlag)
static func result(g: HubState, skill: StringName) -> StringName:
	if g == null:
		return &"teilerfolg"
	if fixed != &"":
		return fixed
	var r := roll_of(g, skill)
	return StringName(r.result) if not r.is_empty() else NONE


static func can_roll(g: HubState, skill: StringName) -> bool:
	return g.is_harbor(g.position) and roll_of(g, skill).is_empty()


## Probe würfeln (Figur gewählt im Handelsdialog); EP in der Fertigkeit
static func roll(g: HubState, skill: StringName, c: Character) -> Dictionary:
	if c == null or not can_roll(g, skill):
		return {}
	var r := Voyage.check(c, skill, Galley.malus(g))
	var out := {"day": g.day, "system": g.position, "result": String(r.result), "total": r.total, "name": c.name,
		"result_name": r.result_name, "xp": r.xp}
	g.trade_rolls[String(skill)] = out
	return out


static func buy_factor(g: HubState) -> float:
	return BUY[result(g, &"handeln")]


static func sell_factor(g: HubState) -> float:
	return SELL[result(g, &"handeln")]


static func ship_factor(g: HubState) -> float:
	return BUY[result(g, &"verhandeln")]


static func shop_share(g: HubState) -> float:
	return SHARE[result(g, &"gassenwissen")]


static func adj(base: float, f: float) -> int:
	return maxi(0, roundi(base * f))


## Kurztext der Wirkung je Fertigkeit und Ergebnis
static func effect_text(skill: StringName, res: StringName) -> String:
	match skill:
		&"handeln":
			return "Kauf %s, Verkauf %d %%" % [_pct(BUY[res]), roundi(SELL[res] * 100)]
		&"verhandeln":
			return "Schiffspreise %s" % _pct(BUY[res])
		_:
			return "Sortiment %d %%" % roundi(SHARE[res] * 100)


static func _pct(f: float) -> String:
	var p := roundi((f - 1.0) * 100)
	return "normal" if p == 0 else ("%+d %%" % p).replace("-", "−")
