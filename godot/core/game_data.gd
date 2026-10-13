class_name GameData
extends RefCounted
## Zugriff auf die Spieldaten unter res://data (im Godot-Editor bearbeitbar).

const CREW_PATH := "res://data/units/crew.tres"
const ENEMIES_PATH := "res://data/units/enemies.tres"
const FUMBLE_PATH := "res://data/tables/fumble.tres"
const WEAPON_DIR := "res://data/weapons"
const HALL_THEME_PATH := "res://data/visuals/warehouse.tres"
const CRIT_IDS := ["durchschlag", "hitze", "wucht", "schnitt", "explosion", "psi"]


static func crew() -> TeamData:
	return load(CREW_PATH)


static func enemies() -> TeamData:
	return load(ENEMIES_PATH)


static func fumble_table() -> FumbleTableData:
	return load(FUMBLE_PATH)


static func weapons() -> Array[WeaponData]:
	var out: Array[WeaponData] = []
	for f in ResourceLoader.list_directory(WEAPON_DIR):
		if f.ends_with(".tres"):
			out.append(load(WEAPON_DIR.path_join(f)))
	out.sort_custom(func(a: WeaponData, b: WeaponData) -> bool: return a.name < b.name)
	return out


static func crit_tables() -> Array[CritTableData]:
	var out: Array[CritTableData] = []
	for id in CRIT_IDS:
		out.append(load("res://data/tables/crit_%s.tres" % id))
	return out


## Modelle für die Lagerhalle (fehlt die Datei, wird alles aus Grundkörpern gezeichnet)
static func hall_theme() -> HallTheme:
	return load(HALL_THEME_PATH) if ResourceLoader.exists(HALL_THEME_PATH) else null
