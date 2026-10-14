class_name GlobalRoster
extends RefCounted
## Globaler Roster (docs/Planung_Roster_Verwundung.md, A): die 6 Startcharaktere (schreibgeschützt, aus
## res://data/units/crew.tres) plus alle selbst erschaffenen Figuren in user://roster.json. Gehört keinem Spielstand;
## Spiele bekommen Kopien (Campaign.new_game, Campaign.hire), deren Fortschritt nicht zurückfließt.

const PATH := "user://roster.json"
const VERSION := 1


## Alle Figuren: zuerst die Startcharaktere, dann die eigenen in der gespeicherten Reihenfolge
static func entries() -> Array[Character]:
	var out := Roster.start_crew()
	out.append_array(own())
	return out


## Nur die selbst erschaffenen Figuren
static func own() -> Array[Character]:
	var out: Array[Character] = []
	if not FileAccess.file_exists(PATH):
		return out
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return out
	for d in data.get("figures", []):
		var c := Character.from_dict(d)
		if c.is_valid():
			c.roster_id = c.id
			out.append(c)
	return out


static func find(id: StringName) -> Character:
	for c in entries():
		if c.id == id:
			return c
	return null


## Startcharaktere sind schreibgeschützt (nicht bearbeiten, nicht löschen; kopieren geht)
static func is_protected(ch: Character) -> bool:
	return GameData.crew().units.any(func(u: UnitData) -> bool: return u.id == ch.roster_id)


## Neue Figur aufnehmen (bekommt eine eindeutige ID)
static func add(ch: Character) -> Character:
	var list := own()
	ch.id = unique_id(ch.name)
	ch.roster_id = ch.id
	list.append(ch)
	_save(list)
	return ch


## Name, Kürzel, Farbe, Aussehen einer eigenen Figur übernehmen (Werte bleiben fest)
static func update(ch: Character) -> bool:
	if is_protected(ch):
		return false
	var list := own()
	for i in list.size():
		if list[i].id == ch.id:
			list[i].name = ch.name
			list[i].letter = ch.letter
			list[i].color = ch.color
			list[i].visual = ch.visual
			_save(list)
			return true
	return false


static func remove(id: StringName) -> bool:
	var list := own()
	var n := list.size()
	list = list.filter(func(c: Character) -> bool: return c.id != id)
	if list.size() == n:
		return false
	_save(list)
	return true


## Exakte Kopie unter neuem Namen (auch von Startcharakteren), als eigene Figur gespeichert
static func copy(ch: Character, new_name: String) -> Character:
	var c := ch.duplicate_character()
	c.name = new_name
	c.free_xp = 0
	c.status = {}
	c.used = {}
	c.new_list = &""
	return add(c)


static func unique_id(n: String) -> StringName:
	var base := n.to_lower().validate_filename().replace(" ", "_")
	if base == "":
		base = "figur"
	var taken := entries().map(func(c: Character) -> String: return String(c.id))
	var id := base
	var i := 2
	while id in taken:
		id = "%s_%d" % [base, i]
		i += 1
	return StringName(id)


static func _save(list: Array[Character]) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"version": VERSION, "figures": list.map(func(c: Character) -> Dictionary: return c.to_dict())}, "\t"))
