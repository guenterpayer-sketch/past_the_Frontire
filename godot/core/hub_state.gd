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
	if offer.get("board", false):
		return Mission.generate(offer.seed, offer.difficulty, board_faction_path(String(offer.get("faction", ""))))
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
	rep.prov0 = provisions
	advance_days(r.days, true)
	rep.prov1 = provisions
	rep.cook = last_cook.duplicate(true)
	rep.training = last_training
	rep.upgrade = last_upgrade.duplicate()
	rep.crafts = last_crafts.duplicate()
	return r.days


## Große Reparatur durch die Crew: 1 Tag, 1 Material, Reparaturprobe (Voyage.crew_repair). Leer = nicht möglich.
func crew_repair() -> Dictionary:
	var r := Voyage.crew_repair(self)
	if not r.is_empty():
		advance_days(1)
	return r


## Reparatur durch die Crew am Schiff (ShipArms): System-ID, "slot:<Slot-ID>" oder Lagerschlüssel einer Schiffswaffe.
## 1 Tag, 1 Material, Probe. Leer = nicht möglich.
func ship_fix(target: String) -> Dictionary:
	var r := ShipArms.crew_fix_system(self, target) if ShipArms.SYSTEMS.has(target) or ship_damage.has(target) else ShipArms.crew_fix_weapon(self, target)
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


## Einsatz abgeschlossen: Auftrag erledigt (auch bei Niederlage), Lohn und Beute bei Sieg, Zeit vergeht, Bericht fürs Schiff.
## Rückzug (MissionResult.retreated, Entscheidung des Nutzers 16.10.2026): eigener Ausgang, kein Lohn, keine Beute,
## der Auftrag bleibt offen (Vermerk retry) bis zum Ablaufdatum; zählt nicht als erledigter Einsatz.
func finish_mission(rep: Dictionary) -> void:
	var retreated := bool(rep.get("retreated", Campaign.last_result.get("retreated", false)))
	rep.retreated = retreated
	if retreated:
		rep.outcome = &"rueckzug"
		rep.expires = int(active.get("expires", day))
	if active.get("board", false):
		# Entern: kein Lohn; Beute des Schiffs nur bei Sieg, sonst verloren
		rep.ammo_used = Voyage.use_ammo(self, Campaign.last_result.get("ammo_used", {}))
		rep.board = String(board_pending.get("ship", ""))
		rep.board_loot = _book_board_loot(board_pending.get("loot", {})) if rep.get("outcome", &"") == &"sieg" else {}
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
	if active.get("board", false):
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
	advance_days(MISSION_DAYS)
	rep.prov1 = provisions
	rep.cook = last_cook.duplicate(true)
	rep.training = last_training
	rep.upgrade = last_upgrade.duplicate()
	rep.crafts = last_crafts.duplicate()
	rep.day = day
	report = rep


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
		offers.append({"id": next_id, "system": sys, "seed": randi() % 1000000,
			"difficulty": DIFFICULTY_ROLL[randi() % DIFFICULTY_ROLL.size()],
			"expires": day + randi_range(OFFER_DAYS[0], OFFER_DAYS[1]), "retry": false})
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
		"ship_damage": ship_damage.duplicate(), "gun_posts": gun_posts.duplicate(), "board_pending": board_pending.duplicate(true)}


static func from_dict(d: Dictionary, slot_no := 0) -> HubState:
	var g := HubState.new()
	g.day = int(d.get("day", 1))
	g.sector = Sector.from_dict(d.get("sector", {}))
	g.position = int(d.get("position", g.sector.home))
	for o in d.get("offers", []):
		g.offers.append({"id": int(o.id), "system": int(o.system), "seed": int(o.seed), "difficulty": String(o.difficulty),
			"expires": int(o.expires), "retry": bool(o.get("retry", false))})
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
	g.slot_name = d.get("slot_name", "")
	g.slot = slot_no
	return g
