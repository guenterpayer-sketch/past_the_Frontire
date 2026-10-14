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
## laufender Einsatz (Auftrag) oder leer
var active := {}
## Bericht des letzten Einsatzes für das Schiff (leer = schon gezeigt)
var report := {}
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


## Reisen: Tage vergehen, abgelaufene Aufträge verschwinden, neue kommen dazu. Liefert die Reisetage.
## Im Schiff warten: Tage vergehen, Aufträge laufen ab, neue kommen dazu
func wait_days(n := 1) -> void:
	day += n
	refill_offers()


func travel_to(target: int) -> int:
	if target == position:
		return 0
	var r := sector.route(position, target)
	if r.days < 0:
		return -1
	day += r.days
	position = target
	refill_offers()
	return r.days


## Ein Auftrag ist noch zu schaffen, wenn das Schiff vor Ablauf dort ist
func reachable(offer: Dictionary) -> bool:
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


## Einsatz abgeschlossen: Auftrag erledigt (auch bei Niederlage), Zeit vergeht, Bericht fürs Schiff
func finish_mission(rep: Dictionary) -> void:
	offers = offers.filter(func(o: Dictionary) -> bool: return o.id != active.get("id", -1))
	active = {}
	missions_done += 1
	day += MISSION_DAYS
	rep.day = day
	report = rep
	refill_offers()


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
		"next_id": next_id, "missions_done": missions_done, "slot_name": slot_name, "berths": berths}


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
	g.slot_name = d.get("slot_name", "")
	g.slot = slot_no
	return g
