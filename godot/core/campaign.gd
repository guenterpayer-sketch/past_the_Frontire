class_name Campaign
extends RefCounted
## Laufender Spielstand zwischen den Modulen (bleibt beim Szenenwechsel erhalten):
## Charakter-Modul (Crew-Szene) ⇄ Kampfmodul (Bodenkampf-Szene).
## Hinein in den Kampf gehen Kopien der Charaktere, heraus kommt ein MissionResult.

const CREW_SCENE := "res://crew.tscn"
const BATTLE_SCENE := "res://main.tscn"

static var _crew: Array[Character] = []
## Ergebnis des letzten Einsatzes (leer, wenn die Crew-Szene nicht nach einem Kampf geöffnet wurde)
static var last_result := {}


static func crew() -> Array[Character]:
	if _crew.is_empty():
		_crew = Roster.load_crew()
	return _crew


## Einsatzergebnis verbuchen und sofort speichern
static func finish_mission(result: Dictionary) -> void:
	var units: Dictionary = result.get("units", {})
	for c in crew():
		if units.has(c.id):
			c.apply_result(units[c.id])
	last_result = result
	save()


## Neues Crewmitglied aufnehmen (replace = ersetztes Mitglied oder null) und speichern
static func add_member(ch: Character, replace: Character = null) -> void:
	var i := crew().find(replace) if replace else -1
	if i >= 0:
		_crew[i] = ch
	else:
		_crew.append(ch)
	save()


static func save() -> void:
	Roster.save_crew(crew())


## Crew neu von der Festplatte lesen (z. B. nachdem ein Spielstand user://crew.json ersetzt hat);
## das letzte Einsatzergebnis wird verworfen
static func reload() -> void:
	_crew = Roster.load_crew()
	last_result = {}


## Speicherstand löschen, Startcrew laden
static func reset() -> void:
	Roster.reset()
	_crew = Roster.start_crew()
	last_result = {}
