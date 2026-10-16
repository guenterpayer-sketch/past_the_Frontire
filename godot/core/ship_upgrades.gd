class_name ShipUpgrades
extends RefCounted
## Schiffsausbau (docs/Planung_Ausbau_Lager_Handwerk.md, Entscheidungen des Nutzers 16.10.2026): 12 Bereiche (Werkstatt: Crafting;
## Schilde, Panzerung, Reaktor, Waffenslots für den Raumkampf, Wirkung im Kampf legt der Raumkampf fest; Waffenslots: ShipArms) mit je
## 3 Stufen. Werft im Hafen: Credits, sofort. Crew: Schiffsmaterial und Spieltage, am Ende eine Reparaturprobe
## (Station Technik, sonst der Beste); nur ein Crew-Ausbau zur Zeit. Stufen liegen in HubState.upgrades {id: Stufe},
## der laufende Crew-Ausbau in HubState.project {id, days}.

## Bereich → Name, Werte je Stufe (0 = heute), Einheit für die Anzeige
const AREAS := {
	&"berths": {"name": "Plätze an Bord", "values": [8, 9, 10, 12], "text": "%d Plätze"},
	&"tank": {"name": "Tank", "values": [100, 130, 160, 200], "text": "Tank %d"},
	&"hull": {"name": "Hülle", "values": [100, 125, 150, 200], "text": "Hülle %d"},
	&"engine": {"name": "Antrieb", "values": [10, 9, 8, 7], "text": "%d Treibstoff je Reisetag"},
	&"systems": {"name": "Systeme", "values": [0, 5, 10, 15], "text": "%+d auf Reiseproben"},
	&"medbay": {"name": "Krankenstation", "values": [0, 10, 20, 30], "text": "%+d auf die Heilprobe"},
	&"training": {"name": "Trainingsraum", "values": [3, 4, 5, 6], "text": "%d freie EP alle 5 Tage"},
	&"workshop": {"name": "Werkstatt", "values": [0, 1, 2, 3], "text": "Stufe %d", "texts": ["Bauen bis 200 Cr",
		"+10 Handwerk, bis 400 Cr", "+10, Dauer −50 %, alles", "+20, Dauer −50 %, alles"]},
	&"shields": {"name": "Schilde", "values": [0, 1, 2, 3], "text": "Stufe %d"},
	&"armor": {"name": "Panzerung", "values": [0, 1, 2, 3], "text": "Stufe %d"},
	&"reactor": {"name": "Reaktor", "values": [0, 1, 2, 3], "text": "Stufe %d"},
	&"slots": {"name": "Waffenslots", "values": [4, 5, 6, 7], "text": "%d Slots", "texts": ["4 Slots", "5 Slots (+ Heck)", "6 Slots (+ Bug 2)", "7 Slots (+ Turm 2)"]},
}
const MAX_LEVEL := 3
## Kosten der Stufe 1, 2, 3 (Index = Zielstufe − 1)
const YARD_COST := [600, 1200, 2200]
const CREW_MATERIAL := [3, 6, 9]
const CREW_DAYS := [3, 5, 8]
const SKILL := &"rsReparatur"
const DIFF := "mittel"


static func level(g: HubState, id: StringName) -> int:
	return int(g.upgrades.get(String(id), 0))


## Wert des Bereichs auf der aktuellen Stufe
static func value(g: HubState, id: StringName) -> int:
	return int(AREAS[id].values[level(g, id)])


static func value_at(id: StringName, lv: int) -> int:
	return int(AREAS[id].values[clampi(lv, 0, MAX_LEVEL)])


static func describe(id: StringName, lv: int) -> String:
	if AREAS[id].has("texts"):
		return String(AREAS[id].texts[clampi(lv, 0, MAX_LEVEL)])
	return String(AREAS[id].text) % value_at(id, lv)


static func busy(g: HubState) -> bool:
	return not g.project.is_empty()


# ---------------------------------------------------------------- Werft

## Werftpreis der nächsten Stufe (nach Verhandeln)
static func yard_cost(g: HubState, id: StringName) -> int:
	return TradeSkills.adj(YARD_COST[mini(level(g, id), MAX_LEVEL - 1)], TradeSkills.ship_factor(g))


static func can_yard(g: HubState, id: StringName) -> bool:
	var lv := level(g, id)
	return lv < MAX_LEVEL and g.is_harbor(g.position) and g.credits >= yard_cost(g, id) and String(g.project.get("id", "")) != String(id)


static func buy_yard(g: HubState, id: StringName) -> bool:
	if not can_yard(g, id):
		return false
	g.credits -= yard_cost(g, id)
	_raise(g, id)
	return true


# ---------------------------------------------------------------- Crew

static func can_crew(g: HubState, id: StringName) -> bool:
	var lv := level(g, id)
	return lv < MAX_LEVEL and not busy(g) and g.material >= CREW_MATERIAL[lv] and Voyage.repairer(g) != null


## Crew-Ausbau beginnen: Material wird sofort verbraucht
static func start_crew(g: HubState, id: StringName) -> bool:
	if not can_crew(g, id):
		return false
	var lv := level(g, id)
	g.material -= CREW_MATERIAL[lv]
	g.project = {"id": String(id), "days": CREW_DAYS[lv]}
	return true


## Ein Tag Arbeit am Crew-Ausbau (aus HubState.advance_days). Gibt eine Meldung zurück ({} = nichts zu melden):
## {text, result ("" = keine Probe), name, skill, xp} wie Crafting.work_day.
## Am letzten Tag Reparaturprobe: Erfolg fertig, Teilerfolg +1 Tag, Fehlschlag/Patzer 1 Material weg und +1 Tag.
static func work_day(g: HubState) -> Dictionary:
	if not busy(g):
		return {}
	g.project.days = int(g.project.days) - 1
	if int(g.project.days) > 0:
		return {}
	var id := StringName(g.project.id)
	var who := Voyage.repairer(g)
	if who == null:
		g.project.days = 1
		return {"text": "%s: niemand für die Reparaturprobe verfügbar, 1 Tag länger" % AREAS[id].name, "result": "", "name": "", "skill": "", "xp": 0}
	var r := Voyage.check(who, SKILL, Galley.malus(g))
	var e := {"result": String(r.result), "name": who.name, "skill": String(SKILL), "xp": int(r.xp)}
	var head := "%s Stufe %d: %s, Reparatur %s %s = %d %s" % [AREAS[id].name, level(g, id) + 1, who.name,
		Dice.format_roll(r.roll), Dice.fmt(r.bonus), r.total, r.result_name]
	if Rules.is_success(Rules.maneuver_result(r.total)):
		_raise(g, id)
		g.project = {}
		e.text = head + " → fertig"
		return e
	g.project.days = 1
	if r.result == &"teilerfolg":
		e.text = head + " → 1 Tag länger"
	elif g.material > 0:
		g.material -= 1
		e.text = head + " → 1 Material verloren, 1 Tag länger"
	else:
		e.text = head + " → 1 Tag länger"
	return e


## Stufe erhöhen und abhängige Werte nachziehen (Plätze; Tank und Hülle bleiben, Maximum steigt)
static func _raise(g: HubState, id: StringName) -> void:
	g.upgrades[String(id)] = level(g, id) + 1
	if id == &"berths":
		g.berths = value(g, id)
	elif id == &"slots":
		for s in ShipArms.slot_ids(g):
			if not g.ship_slots.has(s):
				g.ship_slots[s] = {"key": "", "damage": 0}
