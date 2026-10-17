class_name SpaceEvents
extends RefCounted
## Raumkampf im Spiel, Hub-Seite (Teil 2, Entscheidungen des Nutzers 16.10.2026, docs/module/hub.md): Feindkontakt auf
## der Reise (nach Gebiet), Ausweichen per Probe Navigation, Auftragsarten (Boden, Blockade, Abfangen, Eskorte),
## Auswertung des Raumkampf-Ergebnisses (SpaceBattle.take_result) und die Notfall-Regel (Plünderung + Treiben).
## Ablauf und Zustand liegen im HubState (contact, travel_rest, space_ctx, pending_offer); hier nur die Regeln.

## Feindkontakt je Reisetag: neutrales System bzw. System einer Fraktion; höchstens ein Kampf je Reise
const CONTACT_NEUTRAL := 0.05
const CONTACT_FACTION := 0.20
## Raumgegner in neutralen Systemen
const NEUTRAL_ENEMY := "piraten"
## Ausweichen: Probe Navigation (mittel), Erfolg oder Herausragend = ausgewichen
const DODGE_SKILL := &"navigation"
## Neue Aufträge: Anteil je Art (Rest = Boden), davon Bodenaufträge mit Blockade
const KIND_SHARE := {"abfangen": 0.2, "eskorte": 0.2}
const BLOCKADE_SHARE := 0.25
## Eskorte: Ziel 1–3 Reisetage entfernt, Lohn ×1,5 eines Bodeneinsatzes
const ESCORT_DAYS := [1, 3]
const ESCORT_PAY := 1.5
## Notfall: Plünderung (Anteil der Credits, nur wenn positiv, und jeder Schiffsmunition) und bis zu 3 Lagerstücke
const PLUNDER_SHARE := 0.25
const PLUNDER_ITEMS := 3

## Für Tests: Tag des Feindkontakts erzwingen (Index des Reisetags; −1 = würfeln, −2 = nie)
static var fixed_contact := -1
## Für Tests: Art neuer Aufträge erzwingen ("boden", "blockade", "abfangen", "eskorte"; "" = würfeln)
static var fixed_kind := ""


## Fraktions-ID eines Systems für den Raumkampf (Dateiname der FactionData; neutral = Piraten)
static func faction_id(g: HubState, system: int) -> String:
	var p := String(g.sector.systems[system].faction)
	return p.get_file().get_basename() if p != "" else NEUTRAL_ENEMY


## Kontaktwahrscheinlichkeit je Reisetag im System
static func contact_chance(g: HubState, system: int) -> float:
	return CONTACT_NEUTRAL if g.is_harbor(system) else CONTACT_FACTION


## Würfelt den Feindkontakt für Reisetag i (0 …) im System
static func roll_contact(g: HubState, system: int, i: int) -> bool:
	if fixed_contact == -2:
		return false
	if fixed_contact >= 0:
		return i == fixed_contact
	return randf() < contact_chance(g, system)


## Schwierigkeit eines zufälligen Raumkampfs (wie bei neuen Aufträgen)
static func roll_difficulty() -> String:
	return HubState.DIFFICULTY_ROLL[randi() % HubState.DIFFICULTY_ROLL.size()]


## Wer ausweicht: Reiseposten Navigation, sonst null
static func navigator(g: HubState) -> Character:
	for e in Voyage.assign(g):
		if e.post.skill == DODGE_SKILL:
			return e.ch
	return null


## Ausweichen versuchen: Probe Navigation (mittel, Ausbau Systeme, Proviant, Sensorschaden); r.dodged = ausgewichen
static func dodge(g: HubState) -> Dictionary:
	var c := navigator(g)
	if c == null:
		return {"dodged": false, "name": "niemand", "result_name": "keine Probe", "total": 0, "xp": 0, "result": "fehlschlag"}
	var r := Voyage.check(c, DODGE_SKILL, g.travel_bonus() + Galley.malus(g) + ShipArms.travel_malus(g, DODGE_SKILL))
	r.dodged = Rules.is_success(Rules.maneuver_result(int(r.total)))
	return r


## Art eines neuen Auftrags würfeln: {kind: "boden"/"abfangen"/"eskorte", blockade: bool}
static func roll_kind() -> Dictionary:
	if fixed_kind != "":
		return {"kind": "boden" if fixed_kind == "blockade" else fixed_kind, "blockade": fixed_kind == "blockade"}
	var x := randf()
	if x < float(KIND_SHARE.abfangen):
		return {"kind": "abfangen", "blockade": false}
	if x < float(KIND_SHARE.abfangen) + float(KIND_SHARE.eskorte):
		return {"kind": "eskorte", "blockade": false}
	return {"kind": "boden", "blockade": randf() < BLOCKADE_SHARE}


## Eskorte: Zielsystem 1–3 Reisetage vom Start (−1 = keins gefunden)
static func escort_target(g: HubState, start: int) -> int:
	var cands := []
	for i in g.sector.systems.size():
		if i == start:
			continue
		var d: int = g.sector.route(start, i).days
		if d >= ESCORT_DAYS[0] and d <= ESCORT_DAYS[1]:
			cands.append(i)
	return cands[randi() % cands.size()] if not cands.is_empty() else -1


## Lohn eines Auftrags (Credits, ohne Material-/Munitionsbeute): Boden-Lohn der Schwierigkeit und Fraktion, Eskorte ×1,5
static func offer_pay(g: HubState, offer: Dictionary) -> int:
	var pay := Voyage.payout(String(offer.difficulty), String(g.sector.systems[offer.system].faction), true)
	var total := int(pay.pay) + int(pay.bonus)
	return roundi(total * ESCORT_PAY) if String(offer.get("kind", "boden")) == "eskorte" else total


# ---------------------------------------------------------------- Auswertung

## Schiffsteil des Ergebnisses buchen: Hülle, Systemschäden, Slots, Schiffsmunition, Treibstoff, Lösegeld, Kampfbeute.
## Gibt die Zeilen für den Bericht zurück.
static func book(g: HubState, result: Dictionary) -> Dictionary:
	var rep := {"hull0": g.hull, "damage0": g.ship_damage.duplicate(), "credits0": g.credits}
	var ship: Dictionary = result.get("ship", {})
	if ship.has("hull"):
		g.hull = clampi(int(ship.hull), 0, g.hull_max())
	if ship.has("damage"):
		g.ship_damage = {}
		for k in ship.damage:
			g.ship_damage[String(k)] = String(ship.damage[k])
	if ship.has("slots"):
		for s in ship.slots:
			if g.ship_slots.has(String(s)):
				g.ship_slots[String(s)] = {"key": String(ship.slots[s].get("key", "")), "damage": int(ship.slots[s].get("damage", 0))}
	var used: Dictionary = result.get("ship_ammo_used", {})
	for t in used:
		g.ship_ammo[String(t)] = maxi(0, int(g.ship_ammo.get(String(t), 0)) - int(used[t]))
	g.fuel = maxi(0, g.fuel - int(result.get("fuel_used", 0)))
	rep.ammo_used = used.duplicate()
	rep.fuel_used = int(result.get("fuel_used", 0))
	var ransom: Dictionary = result.get("ransom", {}) if bool(result.get("surrendered", false)) else {}
	if not ransom.is_empty():
		g.credits -= int(ransom.get("credits", 0))
		var ra: Dictionary = ransom.get("ship_ammo", {})
		for t in ra:
			g.ship_ammo[String(t)] = maxi(0, int(g.ship_ammo.get(String(t), 0)) - int(ra[t]))
	rep.ransom = ransom
	var loot: Dictionary = result.get("ship_loot", {})
	if not loot.is_empty():
		g.credits += int(loot.get("credits", 0))
		g.material += int(loot.get("material", 0))
		var la: Dictionary = loot.get("ship_ammo", {})
		for t in la:
			g.ship_ammo[String(t)] = int(g.ship_ammo.get(String(t), 0)) + int(la[t])
		for w in loot.get("weapons", []):
			ShipArms.stock_add(g, Stock.damaged_key(String(w.key), int(w.get("damage", 0))))
	rep.loot = loot.duplicate(true)
	rep.hull1 = g.hull
	rep.new_damage = {}
	for k in g.ship_damage:
		if String(rep.damage0.get(k, "")) != String(g.ship_damage[k]):
			rep.new_damage[k] = g.ship_damage[k]
	return rep


## Notfall-Regel: Plünderung (25 % Credits, wenn positiv; 25 % jeder Schiffsmunition; bis zu 3 Stücke aus Lager und
## Schiffslager), dann treibt das Schiff (Hülle 0 → „festgesetzt“, nur Kurs zum nächsten Hafen)
static func plunder(g: HubState) -> Dictionary:
	var out := {"credits": 0, "ship_ammo": {}, "items": []}
	if g.credits > 0:
		out.credits = int(floor(g.credits * PLUNDER_SHARE))
		g.credits -= out.credits
	for t in g.ship_ammo:
		var n := int(floor(int(g.ship_ammo[t]) * PLUNDER_SHARE))
		if n > 0:
			g.ship_ammo[t] = int(g.ship_ammo[t]) - n
			out.ship_ammo[t] = n
	for i in PLUNDER_ITEMS:
		var pool := []
		for k in g.stock:
			if int(g.stock[k]) > 0:
				pool.append(["stock", String(k)])
		for k in g.ship_stock:
			if int(g.ship_stock[k]) > 0:
				pool.append(["ship", String(k)])
		if pool.is_empty():
			break
		var pick: Array = pool[randi() % pool.size()]
		if pick[0] == "stock":
			Stock.take(g, pick[1])
			out.items.append(Stock.name_of(pick[1]))
		else:
			ShipArms.stock_take(g, pick[1])
			out.items.append(ShipArms.label(pick[1]))
	g.hull = 0
	return out
