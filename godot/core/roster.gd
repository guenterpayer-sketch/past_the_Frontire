class_name Roster
extends RefCounted
## Fortschritt der Crew (Ränge und EP je Fertigkeit), gespeichert in user://crew.json.
## Ausrüstung und Grundwerte kommen immer aus den Vorlagen unter res://data/units.

const PATH := "user://crew.json"


## Gespeicherte Fertigkeiten: {Figur-ID: {Fertigkeit: {rank, xp}}}
static func load_progress() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	var out := {}
	for uid in data:
		var skills := {}
		for sid in data[uid]:
			var s: Dictionary = data[uid][sid]
			skills[StringName(sid)] = {"rank": int(s.get("rank", 0)), "xp": int(s.get("xp", 0))}
		out[StringName(uid)] = skills
	return out


static func save_progress(crew: Array[Combatant]) -> void:
	var data := {}
	for u in crew:
		var skills := {}
		for sid in u.skills:
			skills[String(sid)] = u.skills[sid]
		data[String(u.id)] = skills
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


static func reset() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## Kampfbereite Figuren einer Mannschaft
static func build_team(team: TeamData, team_id: StringName, progress := {}) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for d in team.units:
		out.append(Combatant.create(d, team_id, progress.get(d.id, {})))
	return out
