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
## je Auftrag: {id, system, seed, difficulty, expires, retry (nach Rückzug erneut offen)}
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
var last_upgrade: Array[Dictionary] = []
## Handwerk (Crafting): Handwerksmaterial, laufende Arbeiten {Figur-ID: {kind, key, days, material, name}},
## Meldungen fertiger Arbeiten beim letzten Tageswechsel
var craft_material := 0
var jobs := {}
var last_crafts: Array[Dictionary] = []
## Kombüse (Galley): Proviant, Koch (Character-ID, "" = keiner), letzte Kochproben (neueste zuerst),
## Kochproben beim letzten Tageswechsel (für Reise- und Einsatzbericht)
var provisions := Galley.START
var cook := ""
var cooklog: Array = []
var last_cook: Array = []
## laufender Einsatz (Auftrag) oder leer
var active := {}
## Bericht des letzten Einsatzes für das Schiff (leer = schon gezeigt)
var report := {}
## Beute des letzten Einsatzes, noch nicht ausgewählt (Entscheidungen 16.10.2026): {items: [Lagerschlüssel mit Schaden],
## slots: Stücke zum Mitnehmen = Crewmitglieder im Einsatz}; leer = nichts offen. Medikits gehen sofort ins Lager.
var loot_pending := {}
## Schiff und Geld (Regeln: Voyage). Credits dürfen durch Notkredit negativ sein.
var credits := Voyage.START_CREDITS
var fuel := Voyage.TANK
var hull := Voyage.HULL_MAX
var material := Voyage.START_MATERIAL
## Tank war leer (Notsprit): das nächste Tanken kostet das Doppelte
var emergency := false
## Schiffsvorrat Munition {Art: Schuss} (Arten Ammo.TYPES); der Bodenkampf liest ihn (Battle.ammo_stock())
var ammo := Voyage.AMMO_START.duplicate()
## Schiff für den Raumkampf (ShipArms): Waffenslots {Slot-ID: {key, damage}}, Schiffswaffen im Lager {Schlüssel mit
## Schaden: Anzahl}, Schiffsmunition {Art: Anzahl}, Systemschäden {System-ID: "A"–"E"}, Geschützposten {Slot-ID: Figur-ID/"ki"}
var ship_slots := ShipArms.start_slots()
var ship_stock := {}
var ship_ammo := ShipArms.start_ammo()
var ship_damage := {}
var gun_posts := {}
## Selbst geentertes Gegnerschiff aus dem Raumkampf (board_*), bis der Bodenkampf gegen die Besatzung vorbei ist:
## {faction, ship, difficulty, loot: {credits, material, ship_ammo, weapons}}; leer = nichts offen
var board_pending := {}
## Raumkampf im Spiel (SpaceEvents, Teil 2): offener Feindkontakt {faction, difficulty, system, forced, escort},
## unterbrochene Reise {target, days (noch), escort (Auftrags-ID oder −1), won}, laufender Raumkampf
## {kind (reise/eskorte/auftrag/vor_einsatz), offer_id, faction, difficulty, mission}, Auftrag nach der Ankunft
## (ID, −1 = keiner), Bericht des letzten Raumkampfs (leer = schon gezeigt)
var contact := {}
var travel_rest := {}
var space_ctx := {}
var pending_offer := -1
var space_report := {}
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
	if offer.get("board", false) or offer.get("defend", false):
		var bm := Mission.generate(offer.seed, offer.difficulty, board_faction_path(String(offer.get("faction", ""))))
		# Entern: Raumschiff-Inneres (Bodenkampf, 18.10.2026); Abwehr = Gegner kommen durch die Luftschleuse
		bm.set_map_type(MapTypes.SHIP, "defend" if offer.get("defend", false) else "board")
		return bm
	return Mission.generate(offer.seed, offer.difficulty, sector.systems[offer.system].faction)


## Bodenfraktion zur Raumkampf-Fraktion: Missionsfraktion (data/missions/<id>.tres) oder "" = zufällig
## (Piraten, Militär, Drohnen haben noch keine eigene; Entscheidung des Nutzers 16.10.2026)
static func board_faction_path(faction_id: String) -> String:
	var p := "res://data/missions/%s.tres" % faction_id
	return p if faction_id != "" and ResourceLoader.exists(p) else ""


## Ergebnis des Raumkampfs: selbst geentert (board_enemy) → Entern vormerken; difficulty = Schwierigkeit des
## Raumkampfs (gilt auch für den Bodenkampf). true = der Hub startet danach den Bodenkampf (start_boarding).
func book_board(result: Dictionary, difficulty: String) -> bool:
	if not bool(result.get("board_enemy", false)):
		return false
	board_pending = {"faction": String(result.get("board_faction", "")), "ship": String(result.get("board_ship", "")),
		"difficulty": difficulty, "loot": result.get("board_loot", {}).duplicate(true)}
	return true


## Bodenkampf gegen die Besatzung des geenterten Schiffs vorbereiten (Lagerhalle); danach in den Bodenkampf wechseln
func start_boarding() -> bool:
	if board_pending.is_empty():
		return false
	active = {"id": -1, "system": position, "seed": randi() % 1000000, "difficulty": String(board_pending.difficulty),
		"expires": day, "retry": false, "board": true, "faction": String(board_pending.faction)}
	return true


## Beute des geenterten Schiffs verbuchen (nur nach gewonnenem Bodenkampf): Credits, Schiffsmaterial,
## Schiffsmunition, Schiffswaffen ins Schiffslager (mit Schaden)
func _book_board_loot(loot: Dictionary) -> Dictionary:
	credits += int(loot.get("credits", 0))
	material += int(loot.get("material", 0))
	var am: Dictionary = loot.get("ship_ammo", {})
	for t in am:
		ship_ammo[String(t)] = int(ship_ammo.get(String(t), 0)) + int(am[t])
	for w in loot.get("weapons", []):
		ShipArms.stock_add(self, Stock.damaged_key(String(w.key), int(w.get("damage", 0))))
	return loot.duplicate(true)


## Tage vergehen (Reisen, Einsatz, Warten): Kombüse (Galley: Kochprobe und Proviant, nicht im Hafen; traveling =
## Reisetage, nie im Hafen), Krankenstation und Heilung (Medbay), Training (mit Kochbonus), abgelaufene und neue Aufträge
func advance_days(n: int, traveling := false) -> void:
	if n <= 0:
		return
	last_training = 0
	last_upgrade = []
	last_crafts = []
	last_cook = []
	for i in n:
		var msg := ShipUpgrades.work_day(self)
		if not msg.is_empty():
			last_upgrade.append(msg)
		last_crafts.append_array(Crafting.work_day(self))
		var d := day + i + 1
		var e := Galley.pass_day(self, d, not traveling and is_harbor(position))
		if not e.is_empty():
			last_cook.append(e)
		if d % TRAINING_DAYS == 0 and training_xp() > 0:
			last_training += training_xp() + Galley.training_bonus(self, d)
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


## Darf das Schiff dorthin? Festgesetzt nur zum nächsten Hafen (aus einem Hafen heraus gar nicht); Antrieb ausgefallen: nirgends
func can_travel(target: int) -> bool:
	if target == position or ShipArms.engine_down(self):
		return false
	if not stranded():
		return true
	return target == nearest_harbor()


## Reisen: je Reisetag Reiseproben (Voyage.travel_day: Treibstoff, Hülle, EP), dann vergehen die Tage
## (siehe advance_days). Feindkontakt nach Gebiet (SpaceEvents) unterbricht die Reise: das Schiff steht dann im System
## des Kontakts, contact und travel_rest sind gesetzt. Eskorte (escort = Auftrags-ID): sicher ein Kontakt, kein Ausweichen.
## Liefert die gereisten Tage; den Bericht in last_travel.
func travel_to(target: int, escort := -1) -> int:
	if target == position:
		return 0
	var r := sector.route(position, target)
	if r.days < 0 or not can_travel(target):
		return -1
	return _travel(target, r.days, r.path, escort, true)


## Rest einer unterbrochenen Reise fliegen (ohne weiteren Kontakt), am Ziel Eskorte abrechnen. 0 = nichts offen.
func resume_travel() -> int:
	if travel_rest.is_empty() or not contact.is_empty() or stranded():
		return 0
	var t := travel_rest
	travel_rest = {}
	var days := int(t.days)
	if days <= 0:
		position = int(t.target)
		last_travel = {"from": sector.systems[position].name, "to": sector.systems[position].name, "days": 0, "day0": day,
			"fuel0": fuel, "fuel1": fuel, "hull0": hull, "hull1": hull, "rows": [], "emergency": false, "per_day": fuel_per_day()}
		_arrive(t)
		return 0
	var done := _travel(int(t.target), days, [position, int(t.target)], -1, false)
	_arrive(t)
	return done


func _travel(target: int, days: int, path: Array, escort: int, events: bool) -> int:
	var rep := {"from": sector.systems[position].name, "to": sector.systems[target].name, "days": days,
		"day0": day, "fuel0": fuel, "hull0": hull, "rows": [], "emergency": fuel <= 0, "per_day": fuel_per_day(), "contact": {}}
	var forced := -1
	if escort >= 0:
		forced = mini(SpaceEvents.fixed_contact, days - 1) if SpaceEvents.fixed_contact >= 0 else randi_range(0, days - 1)
	var done := days
	var stop := -1
	for i in days:
		rep.rows.append(Voyage.travel_day(self, day + i + 1))
		var sys: int = path[mini(path.size() - 1, ceili(float(i + 1) / days * (path.size() - 1)))]
		var hit := i == forced if escort >= 0 else (events and SpaceEvents.roll_contact(self, sys, i))
		if hit:
			done = i + 1
			stop = sys
			var o := offer_by_id(escort)
			contact = {"faction": SpaceEvents.faction_id(self, sys), "system": sys, "forced": escort >= 0, "escort": escort,
				"difficulty": String(o.difficulty) if not o.is_empty() else SpaceEvents.roll_difficulty()}
			travel_rest = {"target": target, "days": days - done, "escort": escort, "won": false}
			break
	rep.days = done
	rep.fuel1 = fuel
	rep.hull1 = hull
	rep.contact = contact.duplicate()
	if not contact.is_empty():
		rep.to = sector.systems[stop].name
	last_travel = rep
	position = target if contact.is_empty() else stop
	rep.prov0 = provisions
	advance_days(done, true)
	rep.prov1 = provisions
	rep.cook = last_cook.duplicate(true)
	rep.training = last_training
	rep.upgrade = last_upgrade.duplicate()
	rep.crafts = last_crafts.duplicate()
	return done


## Ankunft nach unterbrochener Reise: Eskorte abrechnen (Lohn bei gewonnenem Kampf, sonst bleibt der Auftrag offen)
func _arrive(t: Dictionary) -> void:
	var o := offer_by_id(int(t.get("escort", -1)))
	if o.is_empty():
		return
	if bool(t.get("won", false)):
		var pay := SpaceEvents.offer_pay(self, o)
		credits += pay
		missions_done += 1
		offers = offers.filter(func(x: Dictionary) -> bool: return x.id != o.id)
		last_travel.escort = {"pay": pay, "title": offer_title(o)}
	else:
		o.retry = true
		last_travel.escort = {"pay": 0, "title": offer_title(o)}


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


## Zum Auftrag fliegen. Bodenauftrag ohne Blockade und ohne Feindkontakt: der Einsatz beginnt sofort (active, danach in
## den Bodenkampf). Sonst bleibt er vorgemerkt (pending_offer) und beginnt nach der Reise über begin_offer().
func start_mission(offer: Dictionary) -> bool:
	if not reachable(offer):
		return false
	pending_offer = int(offer.id)
	if offer.system != position:
		travel_to(offer.system)
	if contact.is_empty() and travel_rest.is_empty() and offer_kind(offer) == "boden" and not offer.get("blockade", false):
		return begin_offer() == "ground"
	return true


## Vorgemerkten Auftrag nach der Ankunft beginnen: "ground" (Bodenkampf, active gesetzt), "space" (Raumkampf, space_ctx
## gesetzt), "escort" (Eskorte losgeflogen, Kontakt unterwegs), "" = nichts
func begin_offer() -> String:
	var o := offer_by_id(pending_offer)
	pending_offer = -1
	if o.is_empty() or int(o.system) != position or int(o.expires) < day:
		return ""
	match offer_kind(o):
		"abfangen":
			space_ctx = {"kind": "auftrag", "offer_id": o.id, "faction": SpaceEvents.faction_id(self, o.system),
				"difficulty": String(o.difficulty), "mission": offer_title(o)}
			return "space"
		"eskorte":
			travel_to(int(o.target), int(o.id))
			return "escort"
	if o.get("blockade", false) and not o.get("blockade_done", false):
		space_ctx = {"kind": "vor_einsatz", "offer_id": o.id, "faction": SpaceEvents.faction_id(self, o.system),
			"difficulty": String(o.difficulty), "mission": "Blockade: " + offer_title(o)}
		return "space"
	active = o
	return "ground"


func offer_by_id(id: int) -> Dictionary:
	for o in offers:
		if int(o.id) == id:
			return o
	return {}


static func offer_kind(o: Dictionary) -> String:
	return String(o.get("kind", "boden"))


## Titel eines Auftrags für Listen und Berichte
func offer_title(o: Dictionary) -> String:
	match offer_kind(o):
		"abfangen":
			return "Abfangen: %s" % SpaceTemplates.faction_name(SpaceEvents.faction_id(self, o.system))
		"eskorte":
			return "Eskorte nach %s" % sector.systems[int(o.target)].name
	return mission_of(o).title


# ---------------------------------------------------------------- Raumkampf im Spiel

## Feindkontakt annehmen: Raumkampf vorbereiten (space_ctx)
func fight_contact() -> void:
	if contact.is_empty():
		return
	var esc := int(contact.get("escort", -1))
	space_ctx = {"kind": "eskorte" if esc >= 0 else "reise", "offer_id": esc, "faction": String(contact.faction),
		"difficulty": String(contact.difficulty), "mission": offer_title(offer_by_id(esc)) if esc >= 0 else
		"Feindkontakt: %s" % SpaceTemplates.faction_name(String(contact.faction))}
	contact = {}


## Ausweichen versuchen (nur ohne Eskorte): Probe Navigation; gelingt sie, ist der Kontakt vorbei, sonst Raumkampf
func dodge_contact() -> Dictionary:
	if contact.is_empty() or contact.get("forced", false):
		return {}
	var r := SpaceEvents.dodge(self)
	if r.dodged:
		contact = {}
	else:
		fight_contact()
	return r


## Eingang für SpaceBattle.start() aus space_ctx
func space_setup(return_scene := HUB_SCENE) -> Dictionary:
	var src := {"reise": "reise", "eskorte": "auftrag", "auftrag": "auftrag", "vor_einsatz": "vor_einsatz"}
	return ShipArms.setup(self, {"faction": String(space_ctx.faction), "difficulty": String(space_ctx.difficulty)},
		String(src.get(String(space_ctx.kind), "reise")), String(space_ctx.get("mission", "")), return_scene)


## Ergebnis des Raumkampfs auswerten (SpaceBattle.take_result; EP und Verwundung hat der Raumkampf schon gebucht).
## Bucht Schiff, Lösegeld, Beute, Lohn; Notfall (Plünderung + Treiben). Bericht in space_report. Rückgabe, was danach
## kommt: "board" (selbst entern → Bodenkampf), "defend" (Gegner entern → Bodenkampf an Bord), "ground" (Blockade
## gewonnen → Bodeneinsatz), "" (zurück ins Schiff; eine unterbrochene Reise geht danach weiter).
func finish_space(result: Dictionary) -> String:
	var ctx := space_ctx
	space_ctx = {}
	var rep := SpaceEvents.book(self, result)
	var kind := String(ctx.get("kind", "reise"))
	var o := offer_by_id(int(ctx.get("offer_id", -1)))
	var outcome := StringName(result.get("outcome", &"niederlage"))
	rep.merge({"kind": kind, "title": String(ctx.get("mission", "")), "faction": SpaceTemplates.faction_name(String(ctx.get("faction", ""))),
		"outcome": outcome, "retreated": bool(result.get("retreated", false)), "surrendered": bool(result.get("surrendered", false)),
		"rounds": int(result.get("rounds", 0)), "units": _space_units(result), "pay": 0, "plunder": {}, "next": ""}, true)
	var next := ""
	if outcome == &"sieg":
		match kind:
			"auftrag":
				rep.pay = SpaceEvents.offer_pay(self, o) if not o.is_empty() else 0
				credits += int(rep.pay)
				_drop_offer(o, true)
			"vor_einsatz":
				if not o.is_empty():
					active = o
					next = "ground"
			"eskorte":
				if not travel_rest.is_empty():
					travel_rest.won = true
		if next == "" and book_board(result, String(ctx.get("difficulty", "mittel"))):
			next = "board"
	elif rep.retreated:
		if not o.is_empty():
			o.retry = true
	elif rep.surrendered:
		if kind != "eskorte":
			_drop_offer(o, false)
	elif bool(result.get("boarding", false)):
		# Auftrag erst nach der Abwehr abrechnen (gewonnen = wie ein gewonnener Raumkampf, verloren = Notfall)
		active = {"id": -2, "system": position, "seed": randi() % 1000000, "difficulty": String(ctx.get("difficulty", "mittel")),
			"expires": day, "retry": false, "defend": true, "faction": String(result.get("boarding_faction", ctx.get("faction", ""))),
			"space_kind": kind, "offer_id": int(ctx.get("offer_id", -1)), "ship": String(result.get("board_ship", "")),
			"loot": result.get("board_loot", {}).duplicate(true)}
		next = "defend"
	else:
		_drop_offer(o, false)
		rep.plunder = SpaceEvents.plunder(self)
		travel_rest = {}
	if kind == "auftrag" and next == "":
		advance_days(MISSION_DAYS)
	rep.next = next
	rep.day = day
	space_report = rep
	return next


func _drop_offer(o: Dictionary, done: bool) -> void:
	if o.is_empty():
		return
	offers = offers.filter(func(x: Dictionary) -> bool: return x.id != o.id)
	if done:
		missions_done += 1


## Figuren im Raumkampf für den Bericht: [{letter, name, state, xp}]
func _space_units(result: Dictionary) -> Array:
	var out := []
	var states := {"ok": "kampffähig", "ko": "bewusstlos", "sterbend": "sterbend", "tot": "tot"}
	var units: Dictionary = result.get("units", {})
	for ch in Campaign.crew():
		var r: Dictionary = units.get(ch.id, units.get(String(ch.id), {}))
		if r.is_empty():
			continue
		var xp: Dictionary = r.get("xp", {})
		var st := String(r.get("status", {}).get("state", "ok"))
		out.append({"letter": ch.letter, "name": ch.name, "state": states.get(st, st) + (" · " + ch.injury_text() if ch.injury != "" else ""),
			"xp": ", ".join(xp.keys().map(func(k) -> String: return "%s +%d" % [Rules.skill_name(k), xp[k]]))})
	return out


## Einsatz abbrechen (zurück ins Schiff ohne Ergebnis, der Auftrag bleibt offen)
func abort_mission() -> void:
	if active.get("board", false):
		board_pending = {}
	elif active.get("defend", false):
		# Abwehr nicht angetreten: wie verloren (Notfall)
		_drop_offer(offer_by_id(int(active.get("offer_id", -1))), false)
		space_report = {"kind": "abwehr", "title": "Entern abgewehrt?", "outcome": &"niederlage", "plunder": SpaceEvents.plunder(self),
			"units": [], "day": day, "next": ""}
		travel_rest = {}
	active = {}


## Einsatz abgeschlossen: Auftrag erledigt (auch bei Niederlage), Lohn und Beute bei Sieg, Zeit vergeht, Bericht fürs Schiff.
## Rückzug (MissionResult.retreated, Entscheidung des Nutzers 16.10.2026): eigener Ausgang, kein Lohn, keine Beute,
## der Auftrag bleibt offen (Vermerk retry) bis zum Ablaufdatum; zählt nicht als erledigter Einsatz.
func finish_mission(rep: Dictionary) -> void:
	var retreated := bool(rep.get("retreated", Campaign.last_result.get("retreated", false)))
	rep.retreated = retreated
	if retreated:
		rep.outcome = &"rueckzug"
		rep.expires = int(active.get("expires", day))
	var won: bool = rep.get("outcome", &"") == &"sieg"
	var go_ground := false
	if active.get("defend", false):
		# Gegner entern: Sieg = Raumkampf gewonnen (Beute des Enterschiffs, Beuteauswahl, Auftrag geht weiter);
		# Niederlage = Notfall (Plünderung + Treiben), der Auftrag ist verloren
		rep.ammo_used = Voyage.use_ammo(self, Campaign.last_result.get("ammo_used", {}))
		rep.defend = true
		rep.payout = {}
		var o := offer_by_id(int(active.get("offer_id", -1)))
		if won:
			rep.board = String(active.get("ship", ""))
			rep.board_loot = _book_board_loot(active.get("loot", {}))
			rep.medkits = set_loot(Campaign.last_result)
			go_ground = _defend_won(o, rep)
		else:
			_drop_offer(o, false)
			rep.plunder = SpaceEvents.plunder(self)
			travel_rest = {}
	elif active.get("board", false):
		# Entern: kein Lohn; Beute des Schiffs und Beuteauswahl nur bei Sieg, sonst verloren
		rep.ammo_used = Voyage.use_ammo(self, Campaign.last_result.get("ammo_used", {}))
		rep.board = String(board_pending.get("ship", ""))
		rep.board_loot = _book_board_loot(board_pending.get("loot", {})) if won else {}
		if won:
			rep.medkits = set_loot(Campaign.last_result)
		rep.payout = {}
		board_pending = {}
	elif not active.is_empty():
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
			pay.medkits = set_loot(Campaign.last_result)
		rep.payout = pay
	if active.get("board", false) or active.get("defend", false):
		pass
	elif retreated:
		for o in offers:
			if o.id == active.get("id", -1):
				o.retry = true
	else:
		offers = offers.filter(func(o: Dictionary) -> bool: return o.id != active.get("id", -1))
		missions_done += 1
	active = {}
	rep.prov0 = provisions
	if not go_ground:
		advance_days(MISSION_DAYS)
	rep.prov1 = provisions
	rep.cook = last_cook.duplicate(true)
	rep.training = last_training
	rep.upgrade = last_upgrade.duplicate()
	rep.crafts = last_crafts.duplicate()
	rep.day = day
	report = rep


## Abwehr gewonnen: den Auftrag wie nach einem gewonnenen Raumkampf weiterführen (Abfangen: Lohn; Eskorte: Lohn bei
## Ankunft; Blockade: der Bodeneinsatz folgt gleich, Truppwahl in der Einsatzbesprechung). true = Bodeneinsatz folgt
## (dann vergeht keine Zeit, damit der Auftrag nicht abläuft).
func _defend_won(o: Dictionary, rep: Dictionary) -> bool:
	match String(active.get("space_kind", "reise")):
		"auftrag":
			if not o.is_empty():
				rep.pay = SpaceEvents.offer_pay(self, o)
				credits += int(rep.pay)
				_drop_offer(o, true)
		"vor_einsatz":
			if not o.is_empty():
				o.blockade_done = true
				pending_offer = int(o.id)
				rep.next = "ground"
				return true
		"eskorte":
			if not travel_rest.is_empty():
				travel_rest.won = true
	return false


## Beute aus dem MissionResult übernehmen: Medikits ins Lager (Anzahl zurück), Waffen/Rüstungen als offene Auswahl
func set_loot(result: Dictionary) -> int:
	if not loot_pending.is_empty():
		take_loot(loot_default())
	var items: Array = []
	var medkits := 0
	for l in result.get("loot", []):
		if String(l.key) == Stock.MEDKIT:
			medkits += int(l.get("count", 1))
		elif String(l.key) != "" and String(l.key) != Equipment.SHIELD:
			items.append(Stock.damaged_key(String(l.key), int(l.get("damage", 0))))
	Stock.add(self, Stock.MEDKIT, medkits)
	loot_pending = {} if items.is_empty() else {"items": items, "slots": result.get("units", {}).size()}
	return medkits


## Vorauswahl der Beute: die wertvollsten Stücke (Verkaufswert mit Schaden), höchstens slots
func loot_default() -> Array[int]:
	var items: Array = loot_pending.get("items", [])
	var idx: Array[int] = []
	for i in items.size():
		idx.append(i)
	idx.sort_custom(func(a: int, b: int) -> bool:
		var va := Stock.sell_price(items[a])
		var vb := Stock.sell_price(items[b])
		return va > vb or (va == vb and a < b))
	idx = idx.slice(0, int(loot_pending.get("slots", 0)))
	idx.sort()
	return idx


## Beuteauswahl abschließen: gewählte Stücke (Indizes, höchstens slots) ins Lager, den Rest als Schrott verkaufen.
## Rückgabe {taken, scrapped, scrap (Credits)}
func take_loot(picks: Array) -> Dictionary:
	var items: Array = loot_pending.get("items", [])
	var slots := int(loot_pending.get("slots", 0))
	var out := {"taken": 0, "scrapped": 0, "scrap": 0}
	for i in items.size():
		if i in picks and out.taken < slots:
			Stock.add(self, items[i])
			out.taken += 1
		else:
			out.scrapped += 1
			out.scrap += Stock.scrap_value(items[i])
	credits += int(out.scrap)
	loot_pending = {}
	return out


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
		var k := SpaceEvents.roll_kind()
		var o := {"id": next_id, "system": sys, "seed": randi() % 1000000,
			"difficulty": DIFFICULTY_ROLL[randi() % DIFFICULTY_ROLL.size()],
			"expires": day + randi_range(OFFER_DAYS[0], OFFER_DAYS[1]), "retry": false, "kind": k.kind, "blockade": k.blockade}
		if k.kind == "eskorte":
			o.target = SpaceEvents.escort_target(self, sys)
			if int(o.target) < 0:
				o.kind = "boden"
				o.erase("target")
		offers.append(o)
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
		"loot_pending": loot_pending.duplicate(true), "craft_material": craft_material, "jobs": jobs.duplicate(true),
		"trade_rolls": trade_rolls.duplicate(true), "provisions": provisions, "cook": cook, "cooklog": cooklog.duplicate(true),
		"ship_slots": ship_slots.duplicate(true), "ship_stock": ship_stock.duplicate(), "ship_ammo": ship_ammo.duplicate(),
		"ship_damage": ship_damage.duplicate(), "gun_posts": gun_posts.duplicate(), "board_pending": board_pending.duplicate(true),
		"contact": contact.duplicate(), "travel_rest": travel_rest.duplicate(), "pending_offer": pending_offer}


static func from_dict(d: Dictionary, slot_no := 0) -> HubState:
	var g := HubState.new()
	g.day = int(d.get("day", 1))
	g.sector = Sector.from_dict(d.get("sector", {}))
	g.position = int(d.get("position", g.sector.home))
	for o in d.get("offers", []):
		var no := {"id": int(o.id), "system": int(o.system), "seed": int(o.seed), "difficulty": String(o.difficulty),
			"expires": int(o.expires), "retry": bool(o.get("retry", false)), "kind": String(o.get("kind", "boden")),
			"blockade": bool(o.get("blockade", false))}
		if o.get("blockade_done", false):
			no.blockade_done = true
		if o.has("target"):
			no.target = int(o.target)
		g.offers.append(no)
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
	g.craft_material = int(d.get("craft_material", 0))
	var jb: Dictionary = d.get("jobs", {})
	for k in jb:
		var j: Dictionary = jb[k]
		g.jobs[String(k)] = {"kind": String(j.kind), "key": String(j.key), "days": int(j.days), "material": int(j.get("material", 0)),
			"name": String(j.get("name", ""))}
	var lp: Dictionary = d.get("loot_pending", {})
	if not lp.is_empty():
		g.loot_pending = {"items": lp.get("items", []).map(func(x) -> String: return String(x)), "slots": int(lp.get("slots", 0))}
	g.trade_rolls = d.get("trade_rolls", {}).duplicate(true)
	var pr: Dictionary = d.get("project", {})
	if not pr.is_empty():
		g.project = {"id": String(pr.id), "days": int(pr.days)}
	var am: Dictionary = d.get("ammo", Voyage.AMMO_START)
	g.ammo = {}
	for t in Voyage.AMMO_START:
		g.ammo[t] = int(am.get(t, Voyage.AMMO_START[t]))
	g.provisions = int(d.get("provisions", Galley.START))
	g.cook = String(d.get("cook", ""))
	for e in d.get("cooklog", []):
		g.cooklog.append({"day": int(e.day), "cook": String(e.cook), "result": String(e.result), "result_name": String(e.result_name),
			"total": int(e.total), "xp": int(e.xp), "use": int(e.use), "p0": int(e.p0), "p1": int(e.p1), "empty": bool(e.empty)})
	# Schiff für den Raumkampf; alte Spielstände bekommen Startschiff und Startvorrat
	if d.has("ship_slots"):
		g.ship_slots = {}
		for k in d.ship_slots:
			g.ship_slots[String(k)] = {"key": String(d.ship_slots[k].get("key", "")), "damage": int(d.ship_slots[k].get("damage", 0))}
	for s in ShipArms.slot_ids(g):
		if not g.ship_slots.has(s):
			g.ship_slots[s] = {"key": "", "damage": 0}
	for k in d.get("ship_stock", {}):
		g.ship_stock[String(k)] = int(d.ship_stock[k])
	var sa: Dictionary = d.get("ship_ammo", ShipArms.start_ammo())
	for t in ShipArms.AMMO_NAMES:
		g.ship_ammo[t] = int(sa.get(t, 0))
	for k in d.get("ship_damage", {}):
		g.ship_damage[String(k)] = String(d.ship_damage[k])
	for k in d.get("gun_posts", {}):
		g.gun_posts[String(k)] = String(d.gun_posts[k])
	g.board_pending = d.get("board_pending", {}).duplicate(true)
	var ct: Dictionary = d.get("contact", {})
	if not ct.is_empty():
		g.contact = {"faction": String(ct.faction), "difficulty": String(ct.difficulty), "system": int(ct.system),
			"forced": bool(ct.get("forced", false)), "escort": int(ct.get("escort", -1))}
	var tr: Dictionary = d.get("travel_rest", {})
	if not tr.is_empty():
		g.travel_rest = {"target": int(tr.target), "days": int(tr.days), "escort": int(tr.get("escort", -1)), "won": bool(tr.get("won", false))}
	g.pending_offer = int(d.get("pending_offer", -1))
	g.slot_name = d.get("slot_name", "")
	g.slot = slot_no
	return g
