class_name SaveSlots
extends RefCounted
## Spielstände: COUNT benannte Slots in user://saves/slot_N.json. Ein Slot enthält das Spiel im Schiff
## (HubState) und den Fortschritt der Crew (Inhalt von user://crew.json zum Zeitpunkt des Speicherns).

## Ordner der Spielstände (Tests setzen einen eigenen)
static var dir := "user://saves"
const COUNT := 3
const VERSION := 1
## Auto-Spielstand (Hub Auftrag 8, Entscheidung des Nutzers 20.10.2026): eigener Slot „Automatisch“, überschrieben nach
## jedem Kampf, jeder Reise und jedem abgeschlossenen Story-Fenster; die Slots 1–COUNT des Nutzers bleiben unberührt.
const AUTO := 0
const AUTO_NAME := "Automatisch"


static func path(slot: int) -> String:
	return "%s/auto.json" % dir if slot == AUTO else "%s/slot_%d.json" % [dir, slot]


## Kurzinfo eines Slots: {} wenn leer, sonst {name, day, system, missions, saved_at}
static func info(slot: int) -> Dictionary:
	var d := _read(slot)
	if d.is_empty():
		return {}
	var g: Dictionary = d.get("game", {})
	var sys := ""
	var cur: Array = g.get("sectors", [])
	var systems: Array = cur[clampi(int(g.get("cur_sector", 0)), 0, cur.size() - 1)].get("systems", []) if not cur.is_empty() \
		else g.get("sector", {}).get("systems", [])
	var pos := int(g.get("position", 0))
	if pos >= 0 and pos < systems.size():
		sys = systems[pos].get("name", "")
	return {"name": d.get("name", ""), "day": int(g.get("day", 1)), "system": sys,
		"missions": int(g.get("missions_done", 0)), "saved_at": int(d.get("saved_at", 0)), "outdated": HubState.outdated(g),
		"game_version": String(d.get("game_version", ""))}


## zuletzt gespeicherter Slot (für „Fortsetzen“, auch der Auto-Spielstand AUTO = 0), −1 = keiner.
## Bei gleicher Zeit gewinnt der Slot des Nutzers.
static func latest() -> int:
	var best := -1
	var best_t := -1
	for s in range(AUTO, COUNT + 1):
		var i := info(s)
		if not i.is_empty() and not i.outdated and i.saved_at >= best_t:
			best_t = i.saved_at
			best = s
	return best


static func save(slot: int, name: String, g: HubState) -> bool:
	DirAccess.make_dir_recursive_absolute(dir)
	Campaign.save()
	var crew := {}
	if FileAccess.file_exists(Roster.PATH):
		var c = JSON.parse_string(FileAccess.get_file_as_string(Roster.PATH))
		if typeof(c) == TYPE_DICTIONARY:
			crew = c
	var from_slot := g.slot
	if slot != AUTO:
		g.slot = slot
		g.slot_name = name
	var data := {"version": VERSION, "game_version": Version.current(), "name": name, "saved_at": int(Time.get_unix_time_from_system()),
		"game": g.to_dict(), "crew": crew}
	if slot == AUTO:
		data.from_slot = from_slot
	var f := FileAccess.open(path(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


## Slot laden: setzt HubState.game, schreibt die Crew nach user://crew.json und lädt sie in Campaign neu
static func load_slot(slot: int) -> bool:
	var d := _read(slot)
	# vor dem Sektorumbau gespeichert: nicht mehr laden (Entscheidung des Nutzers 19.10.2026)
	if d.is_empty() or HubState.outdated(d.get("game", {})):
		return false
	var crew: Dictionary = d.get("crew", {})
	if crew.is_empty():
		Roster.reset()
	else:
		var f := FileAccess.open(Roster.PATH, FileAccess.WRITE)
		if f == null:
			return false
		f.store_string(JSON.stringify(crew, "\t"))
	Campaign.reload()
	HubState.game = HubState.from_dict(d.get("game", {}), int(d.get("from_slot", 0)) if slot == AUTO else slot)
	HubState.game.slot_name = d.get("name", HubState.game.slot_name)
	return true


## Auto-Spielstand schreiben (Name und Slot des laufenden Spiels bleiben); nicht im Schnellkampf
static func autosave(g: HubState) -> bool:
	if g == null or HubState.quick_battle:
		return false
	return save(AUTO, g.slot_name, g)


static func delete(slot: int) -> void:
	if FileAccess.file_exists(path(slot)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(slot)))


static func _read(slot: int) -> Dictionary:
	if not FileAccess.file_exists(path(slot)):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path(slot)))
	return d if typeof(d) == TYPE_DICTIONARY else {}
