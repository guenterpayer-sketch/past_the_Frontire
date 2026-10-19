class_name Galley
extends RefCounted
## Kombüse: Proviant und Kochen (docs/archiv/Planung_Rueckzug_Proviant_Kochen.md, Entscheidungen des Nutzers 16.10.2026).
## - Proviant (HubState.provisions): Startvorrat START, Kauf beim Schiffshändler PRICE Cr je Einheit nach Verhandeln (Entscheidung 16.10.2026).
## - Verbrauch je Tag außerhalb des Hafens: Crew an Bord × Faktor der Kochprobe (FACTOR), kaufmännisch gerundet,
##   mindestens 1. Im Raumhafen kein Verbrauch und keine Kochprobe. Reicht der Vorrat nicht, wird der Rest verbraucht.
## - Koch (HubState.cook = Character-ID, "" = keiner) würfelt jeden Tag automatisch (Voyage.check, EP für Kochen);
##   ohne Koch (oder Koch gesperrt verwundet) gilt Fehlschlag. Der Koch darf zugleich Arzt, Helfer oder Handwerker sein.
## - Ohne Proviant (Vorrat 0): MALUS auf alle Proben im Schiff (Reise, Handel, Heilung, Handwerk, Ausbau, Kochen),
##   nicht im Bodenkampf; gilt bis zum nächsten Kauf.
## - Training: war unter den Kochproben seit dem letzten Training ein Herausragend, gibt es TRAINING_BONUS freie EP mehr.

const SKILL := &"kochen"
const START := 60
const PRICE := 5
const MALUS := -10
const TRAINING_BONUS := 1
## Knopf „bis 10 Tage“ im Handel: auffüllen auf Crew an Bord × FILL_DAYS
const FILL_DAYS := 10
## Warnung „knapp“, wenn der Vorrat weniger als LOW_DAYS Tage reicht
const LOW_DAYS := 3
const LOG_SIZE := 20
## Verbrauch nach Ergebnis der Kochprobe (ohne Koch: Fehlschlag)
const FACTOR := {&"patzer": 1.25, &"fehlschlag": 1.0, &"teilerfolg": 0.9, &"erfolg": 0.8, &"herausragend": 0.7}
const NONE := &"fehlschlag"


## eingestellter Koch an Bord oder null (nicht mehr an Bord → ausgetragen)
static func cook(g: HubState) -> Character:
	if g == null or g.cook == "":
		return null
	for c in Campaign.crew():
		if String(c.id) == g.cook:
			return c
	g.cook = ""
	return null


static func set_cook(g: HubState, c: Character) -> void:
	g.cook = String(c.id) if c else ""


## Verbrauch eines Tages bei diesem Ergebnis (0, wenn niemand an Bord ist)
static func need(result: StringName = NONE, crew := -1) -> int:
	var n := Campaign.crew().size() if crew < 0 else crew
	if n <= 0:
		return 0
	return maxi(1, roundi(n * float(FACTOR.get(result, 1.0))))


## −10 auf Proben im Schiff, solange kein Proviant da ist
static func malus(g: HubState) -> int:
	return MALUS if g != null and g.provisions <= 0 else 0


## reicht noch für … Tage (bei normalem Verbrauch)
static func days_left(g: HubState) -> int:
	var n := need()
	return g.provisions / n if n > 0 else 1 << 20


## Kaufpreis je Einheit nach Verhandeln
static func price(g: HubState) -> int:
	return TradeSkills.adj(PRICE, TradeSkills.ship_factor(g))


static func can_buy(g: HubState, n: int) -> bool:
	return n > 0 and g.is_harbor(g.position) and g.credits >= n * price(g)


static func buy(g: HubState, n: int) -> bool:
	if not can_buy(g, n):
		return false
	g.credits -= n * price(g)
	g.provisions += n
	return true


## Menge für „bis 10 Tage“ (0 = schon genug)
static func fill_amount(g: HubState) -> int:
	return maxi(0, Campaign.crew().size() * FILL_DAYS - g.provisions)


## Ein Tag vergeht (aus HubState.advance_days): im Hafen nichts; sonst Kochprobe und Verbrauch (Lebenserhaltung
## ausgefallen: doppelt, ShipArms.provision_factor).
## Gibt den Eintrag zurück ({} im Hafen): {day, cook, result, result_name, total, xp, use, p0, p1, empty}
static func pass_day(g: HubState, day_no: int, harbor: bool) -> Dictionary:
	if harbor:
		return {}
	var c := cook(g)
	var e := {"day": day_no, "cook": "", "result": String(NONE), "result_name": "ohne Koch", "total": 0, "xp": 0}
	if c and not c.is_locked() and not g.is_captured(c):
		var r := Voyage.check(c, SKILL, malus(g))
		e.cook = c.name
		e.result = String(r.result)
		e.result_name = r.result_name
		e.total = r.total
		e.xp = r.xp
	elif c:
		e.result_name = "Koch gefangen" if g.is_captured(c) else "Koch verwundet"
	e.p0 = g.provisions
	e.use = mini(g.provisions, need(StringName(e.result)) * ShipArms.provision_factor(g))
	g.provisions -= e.use
	e.p1 = g.provisions
	e.empty = e.p1 <= 0 and Campaign.crew().size() > 0
	g.cooklog.push_front(e)
	if g.cooklog.size() > LOG_SIZE:
		g.cooklog.resize(LOG_SIZE)
	return e


## Herausragend unter den Kochproben seit dem letzten Training vor Tag training_day (Tage dazwischen)?
static func training_bonus(g: HubState, training_day: int) -> int:
	for e in g.cooklog:
		var d := int(e.day)
		if d <= training_day and d > training_day - HubState.TRAINING_DAYS and StringName(e.result) == &"herausragend":
			return TRAINING_BONUS
	return 0


## Herausragend seit dem letzten Training (für die Anzeige in der Kombüse)
static func bonus_pending(g: HubState) -> bool:
	var last := g.day / HubState.TRAINING_DAYS * HubState.TRAINING_DAYS
	for e in g.cooklog:
		if int(e.day) > last and StringName(e.result) == &"herausragend":
			return true
	return false
