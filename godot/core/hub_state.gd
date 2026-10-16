class_name HubState
extends RefCounted
## Laufendes Spiel im Schiff (Hub): Tag, Sektor, Position, offene Aufträge, laufender Einsatz,
## Bericht des letzten Einsatzes. Liegt statisch in HubState.game und übersteht so den Szenenwechsel
## Schiff ⇄ Bodenkampf. Die Crew selbst liegt weiter in user://crew.json (Roster).

const START_SCENE := "res://start.tscn"
const HUB_SCENE := "res://hub.tscn"
const BATTLE_SCENE := "res://main.tscn"

## so viele Aufträge sind auf der Sternenkarte offen
const OFFERS := 4
## Tage, die ein Einsatz dauert
const MISSION_DAYS := 1
## Laufzeit neuer Aufträge in Tagen (von, bis)
const OFFER_DAYS := [4, 10]
## Plätze an Bord zu Beginn (6 im Einsatz + 2 Reserve)
const BERTHS_START := 8
## Training: alle TRAINING_DAYS Spieltage (Tag 5, 10, 15 …) bekommt die ganze Crew an Bord TRAINING_XP freie EP
const TRAINING_DAYS := 5
const TRAINING_XP := 3
const DIFFICULTY_ROLL := ["leicht", "mittel", "mittel", "mittel", "schwer"]

static var game: HubState = null
## Schnellkampf aus dem Startmenü: mit der aktuellen Crew, aber ohne Verbuchung, danach zurück ins Startmenü
static var quick_battle := false

var day := 1
var sector: Sector
var position := 0
## je Auftrag: {id, system, seed, difficulty, expires}
var offers: Array[Dictionary] = []
var next_id := 1
var missions_done := 0
## Plätze an Bord (Einsatztrupp 6 + Reserve), später über das Schiff ausbaubar
var berths := BERTHS_START
## Personal der Krankenstation (Character-IDs, höchstens Medbay.MAX_STAFF)
var medics: Array = []
## letzte Einträge der Krankenstation (Proben, Geheilte), neueste zuerst
var medlog: Array = []
## beim letzten Tageswechsel wieder einsatzbereit geworden (für die Anzeige im Schiff)
var last_healed: Array[Character] = []
## beim letzten Tageswechsel vergebene freie EP je Figur durch Training (0 = kein Trainingstag dabei)
var last_training := 0
## Schiffsausbau: Stufen {Bereich: Stufe} und laufender Crew-Ausbau {id, days} (ShipUpgrades)
var upgrades := {}
## Lager {Schlüssel: Anzahl} und Sortiment der Häfen {System: [Schlüssel], "_period": n} (Stock)
var stock := {}
## Handelsproben im Hafen {Fertigkeit: {day, system, result, …}} (TradeSkills)
var trade_rolls := {}
var shop := {}
var project := {}
## Meldungen des Crew-Ausbaus beim letzten Tageswechsel
var last_upgrade: Array[String] = []
## laufender Einsatz (Auftrag) oder leer
var active := {}
## Bericht des letzten Einsatzes für das Schiff (leer = schon gezeigt)
var report := {}
## Schiff und Geld (Regeln: Voyage). Credits dürfen durch Notkredit negativ sein.
var credits := Voyage.START_CREDITS
var fuel := Voyage.TANK
var hull := Voyage.HULL_MAX
var material := Voyage.START_MATERIAL
## Tank war leer (Notsprit): das nächste Tanken kostet das Doppelte
var emergency := false
## Schiffsvorrat Munition {Art: Schuss} (Arten Ammo.TYPES); der Bodenkampf liest ihn (Battle.ammo_stock())
var ammo := Voyage.AMMO_START.duplicate()
## Bericht der letzten Reise (für die Anzeige im Schiff; leer = schon gezeigt)
var last_travel := {}
## Spielstand-Slot (1 … SaveSlots.COUNT) und Name
var slot := 0
var slot_name := ""


## Neues Spiel: frischer Sektor, Start im Heimathafen, Crew auf Anfang
static func new_game(seed_value: int, name := "", slot_no := 0) -> HubState:
	var g := HubState.new()
	g.sector = Sector.generate(seed_value)
	g.position = g.sector.home
	g.slot = slot_no
	g.slot_name = name
	g.refill_offers()
	game = g
	return g


## Bodenkampf über den Hub gestartet?
static func in_mission() -> bool:
	return game != null and not game.active.is_empty()


## Mission des laufenden Einsatzes (für den Bodenkampf) oder null
static func active_mission() -> Mission:
	return game.mission_of(game.active) if in_mission() else null


func mission_of(offer: Dictionary) -> Mission:
	return Mission.generate(offer.seed, offer.difficulty, sector.systems[offer.system].faction)


## Tage vergehen (Reisen, Einsatz, Warten): Krankenstation und Heilung (Medbay), abgelaufene Aufträge, neue Aufträge
func advance_days(n: int) -> void:
	if n <= 0:
		return
	last_training = training_xp() * training_days(day, day + n)
	last_upgrade = []
	for i in n:
		var msg := ShipUpgrades.work_day(self)
		if msg != "":
			last_upgrade.append(msg)
	day += n
	last_healed = Medbay.pass_days(self, n)
	if last_training > 0:
		for c in Campaign.crew():
			c.free_xp += last_training
	refill_offers()


## Werte mit Schiffsausbau
func tank_max() -> int:
	return ShipUpgrades.value(self, &"tank")


func hull_max() -> int:
	return ShipUpgrades.value(self, &"hull")


func fuel_per_day() -> int:
	return ShipUpgrades.value(self, &"engine")


func travel_bonus() -> int:
	return ShipUpgrades.value(self, &"systems")


func heal_bonus() -> int:
	return ShipUpgrades.value(self, &"medbay")


func training_xp() -> int:
	return ShipUpgrades.value(self, &"training")


## Anzahl der Trainingstage (Vielfache von TRAINING_DAYS) nach Tag von bis einschließlich Tag bis
static func training_days(from: int, to: int) -> int:
	return to / TRAINING_DAYS - from / TRAINING_DAYS


## Im Schiff warten
func wait_days(n := 1) -> void:
	advance_days(n)


## Ist das System ein Hafen (neutral)? Dort kann man anheuern.
func is_harbor(system: int) -> bool:
	return sector.systems[system].faction == ""


## Freie Plätze an Bord
func free_berths() -> int:
	return berths - Campaign.crew().size()


## IDs, die in der Truppwahl gesperrt sind (der Arzt der Krankenstation bleibt an Bord); für Campaign.candidates()
static func blocked_ids() -> Array:
	return Medbay.blocked_ids(game) if game and not quick_battle else []


## Schiff festgesetzt: Tank leer oder Hülle 0 → nur noch Kurs zum nächsten Hafen
func stranded() -> bool:
	return fuel <= 0 or hull <= 0


## Nächster Hafen (wenigste Reisetage; der eigene, wenn das Schiff in einem liegt)
func nearest_harbor() -> int:
	var best := -1
	var best_days := 1 << 30
	for i in sector.systems.size():
		if not is_harbor(i):
			continue
		var d: int = 0 if i == position else sector.route(position, i).days
		if d >= 0 and d < best_days:
			best_days = d
			best = i
	return best


## Darf das Schiff dorthin? Festgesetzt nur zum nächsten Hafen (aus einem Hafen heraus gar nicht)
func can_travel(target: int) -> bool:
	if target == position:
		return false
	if not stranded():
		return true
	return target == nearest_harbor()


## Reisen: je Reisetag Reiseproben (Voyage.travel_day: Treibstoff, Hülle, EP), dann vergehen die Tage
## (siehe advance_days). Liefert die Reisetage; den Bericht in last_travel.
func travel_to(target: int) -> int:
	if target == position:
		return 0
	var r := sector.route(position, target)
	if r.days < 0 or not can_travel(target):
		return -1
	var rep := {"from": sector.systems[position].name, "to": sector.systems[target].name, "days": r.days,
		"day0": day, "fuel0": fuel, "hull0": hull, "rows": [], "emergency": fuel <= 0, "per_day": fuel_per_day()}
	for i in r.days:
		rep.rows.append(Voyage.travel_day(self, day + i + 1))
	rep.fuel1 = fuel
	rep.hull1 = hull
	last_travel = rep
	position = target
	advance_days(r.days)
	rep.training = last_training
	rep.upgrade = last_upgrade.duplicate()
	return r.days


## Große Reparatur durch die Crew: 1 Tag, 1 Material, Reparaturprobe (Voyage.crew_repair). Leer = nicht möglich.
func crew_repair() -> Dictionary:
	var r := Voyage.crew_repair(self)
	if not r.is_empty():
		advance_days(1)
	return r


## Ein Auftrag ist noch zu schaffen, wenn das Schiff vor Ablauf dort ist
func reachable(offer: Dictionary) -> bool:
	if offer.system != position and not can_travel(offer.system):
		return false
	return arrival_day(offer.system) <= int(offer.expires)


func arrival_day(system: int) -> int:
	var r := sector.route(position, system)
	return day + r.days if r.days >= 0 else 1 << 30


## Zum Auftrag fliegen und den Einsatz beginnen (danach in den Bodenkampf wechseln)
func start_mission(offer: Dictionary) -> bool:
	if not reachable(offer):
		return false
	travel_to(offer.system)
	for o in offers:
		if o.id == offer.id:
			active = o
			return true
	return false


## Einsatz abbrechen (zurück ins Schiff ohne Ergebnis, der Auftrag bleibt offen)
func abort_mission() -> void:
	active = {}


## Einsatz abgeschlossen: Auftrag erledigt (auch bei Niederlage), Lohn und Beute bei Sieg, Zeit vergeht, Bericht fürs Schiff
func finish_mission(rep: Dictionary) -> void:
	if not active.is_empty():
		# Munitionsverbrauch aus dem Einsatz abziehen (Campaign.finish_mission() lief vorher mit dem MissionResult)
		rep.ammo_used = Voyage.use_ammo(self, Campaign.last_result.get("ammo_used", {}))
		var pay := Voyage.payout(String(active.difficulty), String(sector.systems[active.system].faction), rep.get("outcome", &"") == &"sieg")
		if not pay.is_empty():
			pay.credits0 = credits
			credits += int(pay.pay) + int(pay.bonus)
			material += int(pay.loot)
			for t in pay.ammo:
				ammo[t] = int(ammo.get(t, 0)) + int(pay.ammo[t])
			pay.credits1 = credits
			pay.difficulty = String(active.difficulty)
		rep.payout = pay
	offers = offers.filter(func(o: Dictionary) -> bool: return o.id != active.get("id", -1))
	active = {}
	missions_done += 1
	advance_days(MISSION_DAYS)
	rep.training = last_training
	rep.upgrade = last_upgrade.duplicate()
	rep.day = day
	report = rep


## Abgelaufene Aufträge streichen und auf OFFERS auffüllen (nur in Systemen mit Fraktion)
func refill_offers() -> void:
	offers = offers.filter(func(o: Dictionary) -> bool: return int(o.expires) >= day)
	var hostile := []
	for i in sector.systems.size():
		if sector.systems[i].faction != "":
			hostile.append(i)
	if hostile.is_empty():
		return
	var tries := 0
	while offers.size() < OFFERS and tries < 50:
		tries += 1
		var sys: int = hostile[randi() % hostile.size()]
		if offers.filter(func(o: Dictionary) -> bool: return o.system == sys).size() >= 2:
			continue
		offers.append({"id": next_id, "system": sys, "seed": randi() % 1000000,
			"difficulty": DIFFICULTY_ROLL[randi() % DIFFICULTY_ROLL.size()],
			"expires": day + randi_range(OFFER_DAYS[0], OFFER_DAYS[1])})
		next_id += 1


func offers_at(system: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for o in offers:
		if o.system == system:
			out.append(o)
	return out


func to_dict() -> Dictionary:
	return {"day": day, "sector": sector.to_dict(), "position": position, "offers": offers.duplicate(true),
		"next_id": next_id, "missions_done": missions_done, "slot_name": slot_name, "berths": berths,
		"medics": medics.duplicate(), "medlog": medlog.duplicate(),
		"credits": credits, "fuel": fuel, "hull": hull, "material": material, "emergency": emergency, "ammo": ammo.duplicate(),
		"upgrades": upgrades.duplicate(), "project": project.duplicate(), "stock": stock.duplicate(), "shop": shop.duplicate(true),
		"trade_rolls": trade_rolls.duplicate(true)}


static func from_dict(d: Dictionary, slot_no := 0) -> HubState:
	var g := HubState.new()
	g.day = int(d.get("day", 1))
	g.sector = Sector.from_dict(d.get("sector", {}))
	g.position = int(d.get("position", g.sector.home))
	for o in d.get("offers", []):
		g.offers.append({"id": int(o.id), "system": int(o.system), "seed": int(o.seed), "difficulty": String(o.difficulty),
			"expires": int(o.expires)})
	g.next_id = int(d.get("next_id", 1))
	g.missions_done = int(d.get("missions_done", 0))
	g.berths = int(d.get("berths", BERTHS_START))
	g.medics = d.get("medics", []).map(func(x) -> String: return String(x))
	g.medlog = d.get("medlog", []).duplicate()
	g.credits = int(d.get("credits", Voyage.START_CREDITS))
	g.fuel = int(d.get("fuel", Voyage.TANK))
	g.hull = int(d.get("hull", Voyage.HULL_MAX))
	g.material = int(d.get("material", Voyage.START_MATERIAL))
	g.emergency = bool(d.get("emergency", false))
	for k in d.get("upgrades", {}):
		g.upgrades[String(k)] = int(d.upgrades[k])
	for k in d.get("stock", {}):
		g.stock[String(k)] = int(d.stock[k])
	g.shop = d.get("shop", {}).duplicate(true)
	g.trade_rolls = d.get("trade_rolls", {}).duplicate(true)
	var pr: Dictionary = d.get("project", {})
	if not pr.is_empty():
		g.project = {"id": String(pr.id), "days": int(pr.days)}
	var am: Dictionary = d.get("ammo", Voyage.AMMO_START)
	g.ammo = {}
	for t in Voyage.AMMO_START:
		g.ammo[t] = int(am.get(t, Voyage.AMMO_START[t]))
	g.slot_name = d.get("slot_name", "")
	g.slot = slot_no
	return g
