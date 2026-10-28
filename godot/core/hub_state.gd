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
## Schon erbeutete Elite-/Boss-Stücke (Grundschlüssel); bleiben nach Verkauf in der Enzyklopädie sichtbar (Hub Auftrag 13)
var elite_seen: Array[String] = []
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
## Sektoren (Auftrag 2, 19.10.2026): alle Sektoren des Spiels, der aktuelle (sector = sectors[cur_sector]), bekannte
## Sektoren (aufgedeckt beim ersten Sprung) und Papiere für Sprungtore (Pfade der FactionData der Betreiber)
var sectors: Array[Sector] = []
var cur_sector := 0
var known_sectors: Array[int] = [0]
var papers: Array[String] = []
## Story (Auftrag 1, 19.10.2026): Zustand StoryState.to_dict() im Spielstand; das Story-Objekt hält story_engine()
var story := {}
## Ketten, deren Szenenfenster noch offen ist (Reise, Ankunft, Frist, Einsatzende); der Hub zeigt sie nacheinander
var story_queue: Array[String] = []
var _story: Story
## Spielstand-Slot (1 … SaveSlots.COUNT) und Name
var slot := 0
var slot_name := ""
## Schwierigkeitsgrad (Elite.LEVELS: leicht/normal/schwer), im Spielstand; wirkt auf Boden und Raum (Hub Auftrag 10)
var difficulty_level := "normal"


## Neues Spiel: frischer Sektor, Start im Heimathafen, Crew auf Anfang
static func new_game(seed_value: int, name := "", slot_no := 0) -> HubState:
	var g := HubState.new()
	g.sectors = Sector.galaxy(seed_value)
	g.sector = g.sectors[0]
	g.position = g.sector.home
	g.slot = slot_no
	g.slot_name = name
	g.story = StoryState.create().to_dict()
	g.refill_offers()
	game = g
	return g


## Bodenkampf über den Hub gestartet?
static func in_mission() -> bool:
	return game != null and not game.active.is_empty()


## Mission des laufenden Einsatzes (für den Bodenkampf) oder null
static func active_mission() -> Mission:
	return game.mission_of(game.active) if in_mission() else null


## Elite-Stufe ("" | "elite" | "boss") und Schwierigkeitsgrad gehen an den Bodenkampf (Elite.apply/generate, Hub Auftrag 10)
func mission_of(offer: Dictionary) -> Mission:
	var f := difficulty_factor()
	var m: Mission
	if offer.get("story", false):
		m = Elite.generate(offer.seed, offer.difficulty, board_faction_path(String(offer.get("faction", ""))) if String(offer.get("faction", "")) != ""
			else sector.systems[offer.system].faction, f)
		m.title = String(offer.get("title", m.title))
		if String(offer.get("map", "")) != "":
			m.set_map_type(StringName(offer.map))
	elif offer.get("board", false) or offer.get("defend", false):
		m = Elite.generate(offer.seed, offer.difficulty, board_faction_path(String(offer.get("faction", ""))), f)
		# Entern: Raumschiff-Inneres (Bodenkampf, 18.10.2026); Abwehr = Gegner kommen durch die Luftschleuse
		m.set_map_type(MapTypes.SHIP, "defend" if offer.get("defend", false) else "board")
	else:
		m = Elite.generate(offer.seed, offer.difficulty, sector.systems[offer.system].faction, f)
		var pl: Array = sector.systems[int(offer.system)].get("places", [])
		var pi := int(offer.get("place", -1))
		if pi >= 0 and pi < pl.size() and Places.has_ground(String(pl[pi].kind)):
			m.set_map_type(Places.map_for(String(pl[pi].kind), int(offer.seed)))
		if offer.has("bounty"):
			m.title = "Kopfgeld: %s beseitigen" % String(offer.bounty)
	Elite.apply(m, String(offer.get("elite", "")))
	return m


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


## Elite-Stufe des laufenden Raumkampfs an das Entern weitergeben (Besatzung eines Elite-Schiffs ist Elite)
func _board_elite(level: String) -> void:
	if not board_pending.is_empty():
		board_pending.elite = level


## Bodenkampf gegen die Besatzung des geenterten Schiffs vorbereiten (Lagerhalle); danach in den Bodenkampf wechseln
func start_boarding() -> bool:
	if board_pending.is_empty():
		return false
	active = {"id": -1, "system": position, "seed": randi() % 1000000, "difficulty": String(board_pending.difficulty),
		"expires": day, "retry": false, "board": true, "faction": String(board_pending.faction),
		"elite": String(board_pending.get("elite", ""))}
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
		last_crafts.append_array(Crafting.work_day(self, traveling))
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
			if not is_captured(c):
				c.free_xp += last_training
	refill_offers()
	# Story: verpasste Fristen → Rückschlag-Szene
	for c in story_engine().on_day():
		queue_story(c)


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


## Handel möglich (Hub Auftrag 9, Entscheidung des Nutzers 20.10.2026): im Hafen oder an einer Station im System des
## Schiffs. Dort geht alles wie im Hafen (kaufen, verkaufen, reparieren, Proben würfeln), an Stationen außerhalb eines
## Hafens 20 % teurer (TradeSkills.station_factor). Werft, Crew anheuern und Papiere nur im Hafen.
func at_market() -> bool:
	return is_harbor(position) or station_name() != ""


## Name der Station im System des Schiffs ("" = keine)
func station_name() -> String:
	for p in sector.systems[position].get("places", []):
		if String(p.kind) == "station":
			return String(p.name)
	return ""


## Fenstertitel für Händler/Schiffshändler: „Raumhafen X“ im Hafen, sonst der Name der Station
func market_title() -> String:
	return "Raumhafen %s" % sector.systems[position].name if is_harbor(position) else station_name()


## Freie Plätze an Bord
func free_berths() -> int:
	return berths - Campaign.crew().size()


## In der Truppwahl gesperrt {ID: Grund}: der Arzt der Krankenstation bleibt an Bord, Gefangene fehlen; für Campaign.candidates()
static func blocked_ids() -> Dictionary:
	var out := {}
	if game == null or quick_battle:
		return out
	for id in Medbay.blocked_ids(game):
		out[id] = "Arzt in der Krankenstation"
	for id in game.captured_ids():
		out[id] = "gefangen"
	return out


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
		queue_story(story_arrive())
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
	var story_hit := false
	for i in days:
		rep.rows.append(Voyage.travel_day(self, day + i + 1))
		var sys: int = path[mini(path.size() - 1, ceili(float(i + 1) / days * (path.size() - 1)))]
		var hit := i == forced if escort >= 0 else (events and SpaceEvents.roll_contact(self, sys, i))
		if hit:
			done = i + 1
			stop = sys
			var o := offer_by_id(escort)
			contact = {"faction": SpaceEvents.faction_id(self, sys), "system": sys, "forced": escort >= 0, "escort": escort,
				"difficulty": String(o.difficulty) if not o.is_empty() else SpaceEvents.roll_difficulty(),
				"elite": String(o.get("elite", "")) if not o.is_empty() else (Elite.ELITE if Elite.roll(randi()) else "")}
			travel_rest = {"target": target, "days": days - done, "escort": escort, "won": false}
			break
		# Story: höchstens ein Reise-Ereignis je Reise (neben dem Feindkontakt); das Szenenfenster folgt nach der Reise
		if not story_hit:
			var sc := story_engine().travel_event()
			if sc != "":
				story_hit = true
				queue_story(sc)
	rep.days = done
	rep.fuel1 = fuel
	rep.hull1 = hull
	rep.contact = contact.duplicate()
	if not contact.is_empty():
		rep.to = sector.systems[stop].name
	last_travel = rep
	position = target if contact.is_empty() else stop
	if contact.is_empty():
		queue_story(story_arrive())
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
				"difficulty": String(o.difficulty), "mission": offer_title(o), "elite": String(o.get("elite", ""))}
			return "space"
		"eskorte":
			travel_to(int(o.target), int(o.id))
			return "escort"
	if o.get("blockade", false) and not o.get("blockade_done", false):
		space_ctx = {"kind": "vor_einsatz", "offer_id": o.id, "faction": SpaceEvents.faction_id(self, o.system),
			"difficulty": String(o.difficulty), "mission": "Blockade: " + offer_title(o), "elite": String(o.get("elite", ""))}
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
		"Feindkontakt: %s" % SpaceTemplates.faction_name(String(contact.faction)), "elite": String(contact.get("elite", ""))}
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
	var lv := String(space_ctx.get("elite", ""))
	var s := ShipArms.setup(self, {"faction": String(space_ctx.faction), "difficulty": String(space_ctx.difficulty),
		"elite": lv != "", "boss": lv == Elite.BOSS, "boss_name": String(space_ctx.get("boss_name", ""))},
		String(src.get(String(space_ctx.kind), "reise")), String(space_ctx.get("mission", "")), return_scene)
	s.difficulty_factor = difficulty_factor()
	return s


## Faktor des Schwierigkeitsgrads (leicht 0,8 / normal 1,0 / schwer 1,25)
func difficulty_factor() -> float:
	return Elite.factor(difficulty_level)


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
			"story":
				if bool(ctx.get("then_ground", false)) and not story_mission().is_empty():
					active = _story_ground(story_mission())
					next = "ground"
				else:
					_story_done("sieg")
		if next == "" and book_board(result, String(ctx.get("difficulty", "mittel"))):
			_board_elite(String(ctx.get("elite", "")))
			next = "board"
	elif rep.retreated:
		if not o.is_empty():
			o.retry = true
		if kind == "story":
			_story_done("rueckzug")
	elif rep.surrendered:
		if kind != "eskorte":
			_drop_offer(o, false)
		if kind == "story":
			_story_done("niederlage")
	elif bool(result.get("boarding", false)):
		# Auftrag erst nach der Abwehr abrechnen (gewonnen = wie ein gewonnener Raumkampf, verloren = Notfall)
		active = {"id": -2, "system": position, "seed": randi() % 1000000, "difficulty": String(ctx.get("difficulty", "mittel")),
			"expires": day, "retry": false, "defend": true, "faction": String(result.get("boarding_faction", ctx.get("faction", ""))),
			"space_kind": kind, "offer_id": int(ctx.get("offer_id", -1)), "ship": String(result.get("board_ship", "")),
			"loot": result.get("board_loot", {}).duplicate(true), "elite": String(ctx.get("elite", ""))}
		next = "defend"
	else:
		_drop_offer(o, false)
		rep.plunder = SpaceEvents.plunder(self)
		travel_rest = {}
		if kind == "story":
			_story_done("niederlage")
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
	if boarding_active():
		return
	active = {}


## Läuft ein Entern oder eine Abwehr? Beides lässt sich nicht absagen (Entscheidung des Nutzers 19.10.2026):
## abort_mission() verwirft es nicht, der Hub schickt zurück in den Bodenkampf.
func boarding_active() -> bool:
	return active.get("board", false) or active.get("defend", false)


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
			if String(active.get("space_kind", "")) == "story":
				_story_done("niederlage")
	elif active.get("story", false):
		# Story-Einsatz: kein Lohn (die Folgeszene vergibt Belohnungen), Beuteauswahl bei Sieg; Folgeszene vormerken
		rep.ammo_used = Voyage.use_ammo(self, Campaign.last_result.get("ammo_used", {}))
		rep.story = true
		rep.payout = {}
		if won:
			rep.medkits = set_loot(Campaign.last_result)
		_story_done("rueckzug" if retreated else ("sieg" if won else "niederlage"))
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
	if active.get("board", false) or active.get("defend", false) or active.get("story", false):
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
		"story":
			_story_done("sieg")
	return false


## Beute aus dem MissionResult übernehmen: Medikits ins Lager (Anzahl zurück), Waffen/Rüstungen als offene Auswahl
func set_loot(result: Dictionary) -> int:
	if not loot_pending.is_empty():
		take_loot(loot_default())
	var items: Array = []
	var elite: Array = []
	var medkits := 0
	for l in result.get("loot", []):
		if String(l.key) == Stock.MEDKIT:
			medkits += int(l.get("count", 1))
		elif String(l.key) == Equipment.SHIELD:
			# Schild als Beute (Hub Auftrag 11): direkt ins Lager wie Medikits, nie beschädigt
			Stock.add(self, Equipment.SHIELD, int(l.get("count", 1)))
		elif String(l.key) != "":
			# Elite-Beute (MissionResult.loot mit elite: true, Hub Auftrag 10): wie andere Beute, im Lager verkaufbar,
			# nie im Sortiment (Stock.goods); hier nur für die Anzeige „★“ vermerkt
			if bool(l.get("elite", false)):
				elite.append(items.size())
			items.append(Stock.damaged_key(String(l.key), int(l.get("damage", 0))))
	Stock.add(self, Stock.MEDKIT, medkits)
	# Beuteplätze = Figuren + Eigenheit der Fraktion (MissionResult.loot_extra, z. B. Aasgeier +1)
	loot_pending = {} if items.is_empty() else {"items": items, "slots": result.get("units", {}).size() + int(result.get("loot_extra", 0))}
	if not elite.is_empty() and not loot_pending.is_empty():
		loot_pending.elite = elite
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
		# Elite-Wurf (≈ 13 %); Bodenaufträge ohne Blockade selten mit Person als Ziel = Boss-Kampf („Kopfgeld“)
		o.elite = Elite.ELITE if Elite.roll(int(o.seed)) else ""
		if k.kind == "boden" and not k.blockade and randf() < Elite.BOUNTY_CHANCE:
			o.elite = Elite.BOSS
			o.bounty = Elite.boss_name(int(o.seed))
		var grounds := []
		var pl: Array = sector.systems[sys].get("places", [])
		for pi in pl.size():
			if Places.has_ground(String(pl[pi].kind)):
				grounds.append(pi)
		o.place = grounds[randi() % grounds.size()] if not grounds.is_empty() else -1
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
	return {"day": day, "sectors": sectors.map(func(x: Sector) -> Dictionary: return x.to_dict()), "cur_sector": cur_sector,
		"known_sectors": known_sectors.duplicate(), "papers": papers.duplicate(), "position": position, "offers": offers.duplicate(true),
		"next_id": next_id, "missions_done": missions_done, "slot_name": slot_name, "difficulty_level": difficulty_level, "berths": berths,
		"medics": medics.duplicate(), "medlog": medlog.duplicate(),
		"credits": credits, "fuel": fuel, "hull": hull, "material": material, "emergency": emergency, "ammo": ammo.duplicate(),
		"upgrades": upgrades.duplicate(), "project": project.duplicate(), "stock": stock.duplicate(), "elite_seen": elite_seen.duplicate(), "shop": shop.duplicate(true),
		"loot_pending": loot_pending.duplicate(true), "craft_material": craft_material, "jobs": jobs.duplicate(true),
		"trade_rolls": trade_rolls.duplicate(true), "provisions": provisions, "cook": cook, "cooklog": cooklog.duplicate(true),
		"ship_slots": ship_slots.duplicate(true), "ship_stock": ship_stock.duplicate(), "ship_ammo": ship_ammo.duplicate(),
		"ship_damage": ship_damage.duplicate(), "gun_posts": gun_posts.duplicate(), "board_pending": board_pending.duplicate(true),
		"contact": contact.duplicate(), "travel_rest": travel_rest.duplicate(), "pending_offer": pending_offer,
		"story": story_engine().state.to_dict(), "story_queue": story_queue.duplicate()}


static func from_dict(d: Dictionary, slot_no := 0) -> HubState:
	var g := HubState.new()
	g.day = int(d.get("day", 1))
	for sd in d.get("sectors", []):
		g.sectors.append(Sector.from_dict(sd))
	if g.sectors.is_empty():
		g.sectors.append(Sector.from_dict(d.get("sector", {})))
	g.cur_sector = clampi(int(d.get("cur_sector", 0)), 0, g.sectors.size() - 1)
	g.sector = g.sectors[g.cur_sector]
	g.known_sectors.assign(d.get("known_sectors", [0]).map(func(x) -> int: return int(x)))
	g.papers.assign(d.get("papers", []).map(func(x) -> String: return String(x)))
	g.position = int(d.get("position", g.sector.home))
	# alte Spielstände ohne Story: frischer Story-Zustand
	g.story = d.get("story", {}).duplicate(true) if not d.get("story", {}).is_empty() else StoryState.create().to_dict()
	for c in d.get("story_queue", []):
		g.story_queue.append(String(c))
	for o in d.get("offers", []):
		var no := {"id": int(o.id), "system": int(o.system), "seed": int(o.seed), "difficulty": String(o.difficulty),
			"expires": int(o.expires), "retry": bool(o.get("retry", false)), "kind": String(o.get("kind", "boden")),
			"blockade": bool(o.get("blockade", false))}
		if o.get("blockade_done", false):
			no.blockade_done = true
		if o.has("place"):
			no.place = int(o.place)
		if o.has("target"):
			no.target = int(o.target)
		no.elite = String(o.get("elite", ""))
		if o.has("bounty"):
			no.bounty = String(o.bounty)
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
	if d.has("elite_seen"):
		g.elite_seen.assign(d.elite_seen.map(func(x) -> String: return String(x)))
	else:
		# alte Spielstände: was im Lager liegt oder getragen wird, gilt als erbeutet
		for k in g.stock:
			Stock.note_elite(g, k)
		for ch in Campaign.crew():
			for w in ch.weapons:
				Stock.note_elite(g, Stock.key_of(w))
			Stock.note_elite(g, Stock.key_of(ch.armor))
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
		if lp.has("elite"):
			g.loot_pending.elite = lp.elite.map(func(x) -> int: return int(x))
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
			"forced": bool(ct.get("forced", false)), "escort": int(ct.get("escort", -1)), "elite": String(ct.get("elite", ""))}
	var tr: Dictionary = d.get("travel_rest", {})
	if not tr.is_empty():
		g.travel_rest = {"target": int(tr.target), "days": int(tr.days), "escort": int(tr.get("escort", -1)), "won": bool(tr.get("won", false))}
	g.pending_offer = int(d.get("pending_offer", -1))
	g.slot_name = d.get("slot_name", "")
	g.difficulty_level = String(d.get("difficulty_level", "normal")) if Elite.LEVELS.has(String(d.get("difficulty_level", ""))) else "normal"
	g.slot = slot_no
	return g


# ---------------------------------------------------------------- Story (Auftrag 1, Entscheidungen des Nutzers 19.10.2026)

## Das Story-Objekt dieses Spiels (einmal je Spielstand; der Zustand geht beim Speichern nach story)
func story_engine() -> Story:
	if _story == null:
		_story = Story.create(StoryState.from_dict(story) if not story.is_empty() else StoryState.create(), self)
	return _story


## Story-Folgen auf Ressourcen mit den Regeln des Hubs: {credits, material, provisions, fuel: Änderung}. Credits dürfen
## wie beim Notkredit unter 0, Material und Proviant nicht, der Tank bleibt zwischen 0 und dem Maximum. Gibt die
## tatsächlichen Änderungen zurück.
func apply_story(effects: Dictionary) -> Dictionary:
	var out := {}
	for k in effects:
		var n := int(effects[k])
		match String(k):
			"credits":
				credits += n
				out[k] = n
			"material", "provisions":
				var v0 := int(get(k))
				set(k, maxi(0, v0 + n))
				out[k] = int(get(k)) - v0
			"fuel":
				var f0 := fuel
				fuel = clampi(fuel + n, 0, tank_max())
				out[k] = fuel - f0
	return out


## Szenenfenster vormerken (der Hub zeigt sie nacheinander, sobald kein anderes Fenster offen ist)
func queue_story(chain: String) -> void:
	if chain != "" and not chain in story_queue:
		story_queue.append(chain)


## Story-Einsatz als Angebot (Brücke, ohne Ablauf): {chain, kind, title, difficulty, …} oder leer
func story_mission() -> Dictionary:
	return story_engine().pending_mission()


## Story-Einsatz starten, wo das Schiff liegt: "ground" (Bodenkampf, active gesetzt) oder "space" (Raumkampf, space_ctx;
## Blockade = erst Raumkampf, bei Sieg der Bodenkampf). "" = keiner offen.
func start_story_mission() -> String:
	var m := story_mission()
	if m.is_empty():
		return ""
	var kind := String(m.get("kind", "boden"))
	if kind == "boden":
		active = _story_ground(m)
		return "ground"
	space_ctx = {"kind": "story", "offer_id": -1, "faction": String(m.get("faction", SpaceEvents.faction_id(self, position))),
		"difficulty": String(m.get("difficulty", "mittel")), "mission": String(m.get("title", "Story")), "then_ground": kind == "blockade",
		"elite": String(m.get("elite", "")), "boss_name": String(m.get("boss_name", ""))}
	return "space"


func _story_ground(m: Dictionary) -> Dictionary:
	return {"id": -3, "system": position, "seed": randi() % 1000000, "difficulty": String(m.get("difficulty", "mittel")),
		"expires": day, "retry": false, "story": true, "title": String(m.get("title", "")), "faction": String(m.get("faction", "")),
		"elite": String(m.get("elite", "")),
		"map": story_map(m)}


## Kartentyp eines Story-Einsatzes (Entscheidung des Nutzers 19.10.2026): Feld „map“ der Vorlage (MapTypes-ID), sonst
## der Kartentyp des Story-Orts, wenn das Schiff dort liegt, sonst "" (zufällig)
func story_map(m: Dictionary) -> String:
	var id := String(m.get("map", ""))
	if id != "" and MapTypes.TYPES.has(StringName(id)):
		return id
	var e: Dictionary = story_engine().state.chains.get(String(m.get("chain", "")), {})
	var sp := story_place(m.get("loc", e.get("place", -1)), cur_sector)
	if int(sp.sector) == cur_sector and int(sp.system) == position and int(sp.place) >= 0:
		var pl: Array = sector.systems[position].get("places", [])
		if int(sp.place) < pl.size() and Places.has_ground(String(pl[int(sp.place)].kind)):
			return String(Places.map_for(String(pl[int(sp.place)].kind), randi()))
	return ""


## Story-Ort in einheitlicher Form {sector, system, place} (Hub Auftrag 3 / Story Auftrag 5). Neue Form: Dictionary;
## alte Form: Systemnummer (gilt im Sektor cur, ohne Ort). system < 0 = kein Ort ({} = überall).
static func story_place(v: Variant, cur := 0) -> Dictionary:
	if v is Dictionary:
		return {"sector": int(v.get("sector", cur)), "system": int(v.get("system", -1)), "place": int(v.get("place", -1))}
	return {"sector": cur, "system": int(v) if v != null else -1, "place": -1}


## Story-Orte im aktuellen Sektor: [{system, place, chain, title}]; Orte in anderen Sektoren zeigt nur das Logbuch
func story_markers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m in story_engine().markers():
		var sp := story_place(m, cur_sector)
		if int(sp.sector) == cur_sector and int(sp.system) >= 0 and int(sp.system) < sector.systems.size():
			out.append({"system": int(sp.system), "place": int(sp.place), "chain": String(m.get("chain", "")), "title": String(m.get("title", ""))})
	return out


## Ankunft im System für die Story (startet Ketten für das ganze System, Kopfgeldjäger, Schmuggel)
func story_arrive() -> String:
	return story_engine().on_arrive(cur_sector, position)


## Ort im aktuellen System anfliegen (Hub Auftrag 4, ohne Zeit): startet eine Story-Kette an diesem Ort. Gibt sie zurück oder "".
func visit_place(index: int) -> String:
	if Places.place(self, index).is_empty():
		return ""
	return story_engine().on_visit(cur_sector, position, index)


## Zahl der erreichten Sektoren (Story-Schlüssel „sectors“)
func sectors_reached() -> int:
	return known_sectors.size()


## IDs gefangener Crewmitglieder (StoryState.captured): gesperrt für Truppwahl, Reiseposten, Krankenstation, Arbeiten,
## Geschützposten, Kombüse, Training und Heilung (Entscheidung des Nutzers 19.10.2026)
func captured_ids() -> Array:
	return story_engine().state.captured.duplicate()


## Mit Spielstand: ist die Figur gefangen? (ohne Spiel nie)
static func captured(c: Character) -> bool:
	return game != null and game.is_captured(c)


func is_captured(c: Character) -> bool:
	return c != null and String(c.id) in captured_ids()


## Story-Einsatz beendet: Folgeszene vormerken
func _story_done(outcome: String) -> void:
	queue_story(story_engine().mission_done(outcome))


# ---------------------------------------------------------------- Sektoren und Sprungtore (Auftrag 2, 19.10.2026)

## Spielstand vor dem Sektorumbau (ein Sektor ohne Orte und Tore): wird nicht mehr geladen (Entscheidung des Nutzers)
static func outdated(d: Dictionary) -> bool:
	return not d.has("sectors")


## Preis der Papiere eines Betreibers (Grundpreis, nach Verhandeln, nur im Hafen)
const PAPERS_PRICE := 500


func papers_price() -> int:
	return TradeSkills.adj(PAPERS_PRICE, TradeSkills.BUY[TradeSkills.result(self, &"verhandeln")])


func can_buy_papers(operator: String) -> bool:
	return operator != "" and is_harbor(position) and not operator in papers and credits >= papers_price()


func buy_papers(operator: String) -> bool:
	if not can_buy_papers(operator):
		return false
	credits -= papers_price()
	papers.append(operator)
	return true


## Gebühr eines Tors nach Verhandeln (ohne Stationsaufschlag)
func gate_fee(gate: Dictionary) -> int:
	return TradeSkills.adj(int(gate.fee), TradeSkills.BUY[TradeSkills.result(self, &"verhandeln")])


## Grund, warum der Sprung nicht geht ("" = möglich): Schiff muss am Tor liegen, Papiere, Credits, Antrieb
func jump_block(gate: Dictionary) -> String:
	if int(gate.system) != position:
		return "Das Schiff muss im System des Tors liegen."
	if bool(gate.papers) and not String(gate.operator) in papers:
		return "Papiere fehlen: %s" % _operator_name(String(gate.operator))
	if credits < gate_fee(gate):
		return "Nicht genug Credits für die Gebühr."
	if stranded():
		return "Das Schiff ist festgesetzt."
	return ""


func _operator_name(path: String) -> String:
	var f: FactionData = load(path) if path != "" and ResourceLoader.exists(path) else null
	return f.name if f else "unbekannt"


## Sprung durch ein Tor: Gebühr, 1 Tag, neuer Sektor (beim ersten Mal aufgedeckt); offene Aufträge des alten Sektors
## entfallen, der neue Sektor bekommt eigene
func jump(gate: Dictionary) -> bool:
	if jump_block(gate) != "":
		return false
	credits -= gate_fee(gate)
	cur_sector = int(gate.to_sector)
	sector = sectors[cur_sector]
	position = int(gate.to_system)
	if not cur_sector in known_sectors:
		known_sectors.append(cur_sector)
	offers = []
	pending_offer = -1
	travel_rest = {}
	advance_days(1, true)
	return true
