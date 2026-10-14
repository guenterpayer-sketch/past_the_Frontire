class_name Campaign
extends RefCounted
## Laufender Spielstand zwischen den Modulen (bleibt beim Szenenwechsel erhalten):
## Charakter-Modul (Crew-Szene) ⇄ Kampfmodul (Bodenkampf-Szene).
## Hinein in den Kampf gehen Kopien der Charaktere, heraus kommt ein MissionResult.

const CREW_SCENE := "res://crew.tscn"
const BATTLE_SCENE := "res://main.tscn"
const ROSTER_SCENE := "res://roster.tscn"
## Plätze an Bord zu Beginn (6 Einsatz + 2 Reserve; der Hub kann später mehr erlauben)
const START_SEATS := 8
## höchstens so viele Figuren gehen in einen Einsatz
const MAX_SQUAD := 6

static var _crew: Array[Character] = []
## Ergebnis des letzten Einsatzes (leer, wenn die Crew-Szene nicht nach einem Kampf geöffnet wurde)
static var last_result := {}
## vom Hub vor dem Einsatz gewählter Trupp (leer = die ersten MAX_SQUAD der Crew)
static var chosen_squad: Array[Character] = []


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


## Neues Spiel: Crew aus Roster-Figuren (Kopien; der Roster bleibt unverändert) und speichern
static func new_game(picked: Array[Character]) -> void:
	_crew = []
	for r in picked:
		_crew.append(_copy_from_roster(r))
	last_result = {}
	chosen_squad = []
	save()


## Roster-Figur anheuern (Kopie mit dem Stand des Roster-Eintrags); null, wenn sie schon an Bord ist
static func hire(entry: Character) -> Character:
	if is_aboard(entry.roster_id):
		return null
	var c := _copy_from_roster(entry)
	crew().append(c)
	save()
	return c


## Figur entlassen: ihr Fortschritt in diesem Spiel geht verloren, der Roster-Eintrag bleibt
static func fire(ch: Character) -> void:
	crew().erase(ch)
	chosen_squad.erase(ch)
	save()


static func is_aboard(roster_id: StringName) -> bool:
	return crew().any(func(c: Character) -> bool: return c.roster_id == roster_id)


## Figuren für den nächsten Einsatz: der vom Hub gewählte Trupp oder die ersten MAX_SQUAD der Crew
static func squad() -> Array[Character]:
	var s: Array[Character] = chosen_squad.filter(func(c: Character) -> bool: return c in crew())
	if s.is_empty():
		s = crew().slice(0, MAX_SQUAD)
	return s.slice(0, MAX_SQUAD)


static func _copy_from_roster(r: Character) -> Character:
	var c := r.duplicate_character()
	c.roster_id = r.roster_id if r.roster_id != &"" else r.id
	var taken := _crew.map(func(o: Character) -> StringName: return o.id)
	var id := c.id
	var i := 2
	while id in taken:
		id = StringName("%s_%d" % [c.id, i])
		i += 1
	c.id = id
	return c


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
