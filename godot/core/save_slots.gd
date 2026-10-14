class_name SaveSlots
extends RefCounted
## Spielstände: COUNT benannte Slots in user://saves/slot_N.json. Ein Slot enthält das Spiel im Schiff
## (HubState) und den Fortschritt der Crew (Inhalt von user://crew.json zum Zeitpunkt des Speicherns).

## Ordner der Spielstände (Tests setzen einen eigenen)
static var dir := "user://saves"
const COUNT := 3
const VERSION := 1


static func path(slot: int) -> String:
	return "%s/slot_%d.json" % [dir, slot]


## Kurzinfo eines Slots: {} wenn leer, sonst {name, day, system, missions, saved_at}
static func info(slot: int) -> Dictionary:
	var d := _read(slot)
	if d.is_empty():
		return {}
	var g: Dictionary = d.get("game", {})
	var sys := ""
	var systems: Array = g.get("sector", {}).get("systems", [])
	var pos := int(g.get("position", 0))
	if pos >= 0 and pos < systems.size():
		sys = systems[pos].get("name", "")
	return {"name": d.get("name", ""), "day": int(g.get("day", 1)), "system": sys,
		"missions": int(g.get("missions_done", 0)), "saved_at": int(d.get("saved_at", 0))}


## zuletzt gespeicherter Slot (für „Fortsetzen“), 0 = keiner
static func latest() -> int:
	var best := 0
	var best_t := -1
	for s in range(1, COUNT + 1):
		var i := info(s)
		if not i.is_empty() and i.saved_at > best_t:
			best_t = i.saved_at
			best = s
	return best


static func save(slot: int, name: String, g: HubState) -> bool:
	DirAccess.make_dir_recursive_absolute(dir)
	var crew := {}
	if FileAccess.file_exists(Roster.PATH):
		var c = JSON.parse_string(FileAccess.get_file_as_string(Roster.PATH))
		if typeof(c) == TYPE_DICTIONARY:
			crew = c
	g.slot = slot
	g.slot_name = name
	var data := {"version": VERSION, "name": name, "saved_at": int(Time.get_unix_time_from_system()),
		"game": g.to_dict(), "crew": crew}
	var f := FileAccess.open(path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


## Slot laden: setzt HubState.game und schreibt den Crew-Fortschritt nach user://crew.json
static func load_slot(slot: int) -> bool:
	var d := _read(slot)
	if d.is_empty():
		return false
	var crew: Dictionary = d.get("crew", {})
	if crew.is_empty():
		Roster.reset()
	else:
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		if f == null:
			return false
		f.store_string(JSON.stringify(crew, "\t"))
	HubState.game = HubState.from_dict(d.get("game", {}), slot)
	HubState.game.slot_name = d.get("name", HubState.game.slot_name)
	return true


static func delete(slot: int) -> void:
	if FileAccess.file_exists(path(slot)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(slot)))


static func _read(slot: int) -> Dictionary:
	if not FileAccess.file_exists(path(slot)):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path(slot)))
	return d if typeof(d) == TYPE_DICTIONARY else {}
