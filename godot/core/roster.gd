class_name Roster
extends RefCounted
## Fortschritt der Crew (Fertigkeiten mit Rang und EP, gesteigerte Eigenschaften, gesparte freie EP),
## gespeichert in user://crew.json. Ausrüstung und übrige Werte kommen immer aus den Vorlagen unter res://data/units.

const PATH := "user://crew.json"
const VERSION := 2


## Gespeicherter Fortschritt: {Figur-ID: {skills: {Fertigkeit: {rank, xp}}, attrs: {...}, free_xp}}
## Liest auch das alte Format (nur {Figur-ID: {Fertigkeit: {rank, xp}}}).
static func load_progress() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	var crew: Dictionary = data.get("crew", {}) if data.has("version") else {}
	if not data.has("version"):
		for uid in data:
			crew[uid] = {"skills": data[uid]}
	var out := {}
	for uid in crew:
		var entry: Dictionary = crew[uid]
		var skills := {}
		var raw: Dictionary = entry.get("skills", {})
		for sid in raw:
			var s: Dictionary = raw[sid]
			skills[StringName(sid)] = {"rank": int(s.get("rank", 0)), "xp": int(s.get("xp", 0))}
		var attrs := {}
		var raw_attrs: Dictionary = entry.get("attrs", {})
		for a in raw_attrs:
			attrs[String(a)] = int(raw_attrs[a])
		out[StringName(uid)] = {"skills": skills, "attrs": attrs, "free_xp": int(entry.get("free_xp", 0))}
	return out


static func save_progress(crew: Array[Combatant]) -> void:
	var data := {}
	for u in crew:
		var skills := {}
		for sid in u.skills:
			skills[String(sid)] = u.skills[sid]
		data[String(u.id)] = {"skills": skills, "attrs": u.attrs, "free_xp": u.free_xp}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version": VERSION, "crew": data}, "\t"))


static func reset() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


## Kampfbereite Figuren einer Mannschaft
static func build_team(team: TeamData, team_id: StringName, progress := {}) -> Array[Combatant]:
	return build_units(team.units, team_id, progress)


static func build_units(units: Array[UnitData], team_id: StringName, progress := {}) -> Array[Combatant]:
	var out: Array[Combatant] = []
	for d in units:
		out.append(Combatant.create(d, team_id, progress.get(d.id, {})))
	return out
