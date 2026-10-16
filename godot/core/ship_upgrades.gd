class_name ShipUpgrades
extends RefCounted
## Schiffsausbau (docs/Planung_Ausbau_Lager_Handwerk.md, Entscheidungen des Nutzers 16.10.2026): 7 Bereiche mit je
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
	return String(AREAS[id].text) % value_at(id, lv)


static func busy(g: HubState) -> bool:
	return not g.project.is_empty()


# ---------------------------------------------------------------- Werft

static func can_yard(g: HubState, id: StringName) -> bool:
	var lv := level(g, id)
	return lv < MAX_LEVEL and g.is_harbor(g.position) and g.credits >= YARD_COST[lv] and String(g.project.get("id", "")) != String(id)


static func buy_yard(g: HubState, id: StringName) -> bool:
	if not can_yard(g, id):
		return false
	g.credits -= YARD_COST[level(g, id)]
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


## Ein Tag Arbeit am Crew-Ausbau (aus HubState.advance_days). Gibt eine Meldung zurück ("" = nichts zu melden).
## Am letzten Tag Reparaturprobe: Erfolg fertig, Teilerfolg +1 Tag, Fehlschlag/Patzer 1 Material weg und +1 Tag.
static func work_day(g: HubState) -> String:
	if not busy(g):
		return ""
	g.project.days = int(g.project.days) - 1
	if int(g.project.days) > 0:
		return ""
	var id := StringName(g.project.id)
	var who := Voyage.repairer(g)
	if who == null:
		g.project.days = 1
		return "%s: niemand für die Reparaturprobe verfügbar, 1 Tag länger" % AREAS[id].name
	var r := Voyage.check(who, SKILL)
	var head := "%s Stufe %d: %s, Reparatur %s %s = %d %s" % [AREAS[id].name, level(g, id) + 1, who.name,
		Dice.format_roll(r.roll), Dice.fmt(r.bonus), r.total, r.result_name]
	if Rules.is_success(Rules.maneuver_result(r.total)):
		_raise(g, id)
		g.project = {}
		return head + " → fertig"
	g.project.days = 1
	if r.result == &"teilerfolg":
		return head + " → 1 Tag länger"
	if g.material > 0:
		g.material -= 1
		return head + " → 1 Material verloren, 1 Tag länger"
	return head + " → 1 Tag länger"


## Stufe erhöhen und abhängige Werte nachziehen (Plätze; Tank und Hülle bleiben, Maximum steigt)
static func _raise(g: HubState, id: StringName) -> void:
	g.upgrades[String(id)] = level(g, id) + 1
	if id == &"berths":
		g.berths = value(g, id)
