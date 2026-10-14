class_name Roster
extends RefCounted
## Speicherstand der Crew in user://crew.json: vollständige Charaktere (Version 3).
## Ohne Speicherstand ist die Startcrew aus res://data/units/crew.tres die Crew.
## Ältere Speicherstände (Version 1/2: nur Fortschritt je Figur) werden auf die Startcrew gelegt.

const PATH := "user://crew.json"
const VERSION := 3


static func load_crew() -> Array[Character]:
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
	if typeof(data) == TYPE_DICTIONARY and int(data.get("version", 0)) >= 3:
		var out: Array[Character] = []
		for d in data.get("crew", []):
			var c := Character.from_dict(d)
			if c.is_valid():
				out.append(c)
		if not out.is_empty():
			return out
	var progress := _old_progress(data) if typeof(data) == TYPE_DICTIONARY else {}
	return start_crew(progress)


## Startcrew aus den Vorlagen, optional mit altem Fortschritt {Figur-ID: {skills, attrs, free_xp}}
static func start_crew(progress := {}) -> Array[Character]:
	var out: Array[Character] = []
	for d in GameData.crew().units:
		out.append(Character.from_unit(d).apply_progress(progress.get(d.id, {})))
	return out


## Crew speichern; dazu die Entlassenen „im Hafen“ (mit Fortschritt) und der zuletzt gewählte Trupp (IDs)
static func save_crew(crew: Array[Character], harbor: Array[Character] = [], squad_ids: Array = []) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version": VERSION, "crew": crew.map(func(c: Character) -> Dictionary: return c.to_dict()),
			"harbor": harbor.map(func(c: Character) -> Dictionary: return c.to_dict()),
			"squad": squad_ids.map(func(id) -> String: return String(id))}, "\t"))


## Entlassene „im Hafen“ und gespeicherter Trupp: {harbor: Array[Character], squad: Array[StringName]}
static func load_extra() -> Dictionary:
	var harbor: Array[Character] = []
	var squad: Array[StringName] = []
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH)) if FileAccess.file_exists(PATH) else null
	if typeof(data) == TYPE_DICTIONARY:
		for d in data.get("harbor", []):
			var c := Character.from_dict(d)
			if c.is_valid():
				harbor.append(c)
		for id in data.get("squad", []):
			squad.append(StringName(id))
	return {"harbor": harbor, "squad": squad}


static func reset() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## Version 2: {version, crew: {Figur-ID: {skills, attrs, free_xp}}}; Version 1: {Figur-ID: {Fertigkeit: {rank, xp}}}
static func _old_progress(data: Dictionary) -> Dictionary:
	var crew: Dictionary = data.get("crew", {}) if data.has("version") else {}
	if not data.has("version"):
		for uid in data:
			crew[uid] = {"skills": data[uid]}
	var out := {}
	for uid in crew:
		out[StringName(uid)] = crew[uid]
	return out


## Kampfbereite Kopien der Charaktere
static func build_crew(crew: Array[Character]) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for c in crew:
		out.append(Combatant.from_character(c, &"crew"))
	return out


## Kampfbereite Figuren einer Mannschaft aus Vorlagen
static func build_team(team: TeamData, team_id: StringName) -> Array[Combatant]:
	return build_units(team.units, team_id)


static func build_units(units: Array[UnitData], team_id: StringName) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for d in units:
		out.append(Combatant.create(d, team_id))
	return out
