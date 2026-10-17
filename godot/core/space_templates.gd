class_name SpaceTemplates
extends RefCounted
## Gegnervorlagen für den Raumkampf: Schiffe/Jäger (data/ships/schiffe/*.tres, ShipTemplateData) und Gegnerseiten
## (data/ships/seiten/*.tres, SpaceFactionData: Missionsfraktionen aus data/missions und eigene Raumgegner).
## Gewählt wird aus faction + difficulty im setup. Werte abgestimmt per Simulation (tests/sim_space.gd, 17.10.2026).

const SHIP_DIR := "res://data/ships/schiffe/"
const FACTION_DIR := "res://data/ships/seiten/"
const DIFFS := ["leicht", "mittel", "schwer"]

static var _ships := {}
static var _factions := {}


## Aufstellungen für Seiten ohne eigene groups
const DEFAULT_GROUPS := {
	"leicht": [["korvette"], ["jaeger", "jaeger", "jaeger"]],
	"mittel": [["korvette", "jaeger"], ["korvette", "jaeger", "jaeger"]],
	"schwer": [["fregatte", "jaeger"], ["kreuzer"], ["korvette", "korvette"]],
}


## Alle Ressourcen eines Ordners {Kennung: Resource} (im exportierten Spiel heißen die Dateien *.tres.remap)
static func _load_dir(dir: String) -> Dictionary:
	var out := {}
	var files := DirAccess.get_files_at(dir)
	files.sort()
	for f in files:
		var name := f.trim_suffix(".remap")
		if name.ends_with(".tres"):
			var r := load(dir + name)
			if r:
				out[name.get_basename()] = r
	return out


## Schiffsvorlagen {Kennung: {name, cls, hull, shield, recharge, armor, vw, speed, max_speed, turns, weapons, skill,
## init, credits, material}}
static func ships() -> Dictionary:
	if _ships.is_empty():
		var res := _load_dir(SHIP_DIR)
		for id in res:
			var t: ShipTemplateData = res[id]
			_ships[id] = {"name": t.name, "cls": t.cls, "hull": t.hull, "shield": t.shield, "recharge": t.recharge,
				"armor": t.armor, "vw": t.vw, "speed": t.speed, "max_speed": t.max_speed, "turns": t.turns,
				"weapons": Array(t.weapons), "skill": t.skill, "init": t.init, "credits": t.credits, "material": t.material}
	return _ships


static func ship(id: String) -> Dictionary:
	return ships().get(id, {})


## Gegnerseiten {Kennung: {name, on_win, ransom, flee_at, groups (nur wenn eigene Aufstellungen)}}
static func factions() -> Dictionary:
	if _factions.is_empty():
		var res := _load_dir(FACTION_DIR)
		for id in res:
			var f: SpaceFactionData = res[id]
			var d := {"name": f.name, "on_win": f.on_win, "ransom": f.ransom, "flee_at": f.flee_at}
			var groups := {}
			for diff in DIFFS:
				var rows: PackedStringArray = f.get(diff)
				if not rows.is_empty():
					var list: Array = []
					for row in rows:
						list.append(Array(row.replace(" ", "").split(",", false)))
					groups[diff] = list
			if not groups.is_empty():
				d["groups"] = groups
			_factions[id] = d
	return _factions


static func faction_ids() -> Array:
	return factions().keys()


static func faction(id: String) -> Dictionary:
	return factions().get(id, factions().get("piraten", {"name": id, "on_win": "abziehen", "ransom": 0, "flee_at": 0.0}))


static func faction_name(id: String) -> String:
	return String(faction(id).name)


## Aufstellung (Liste von Vorlagen-IDs) für Seite und Schwierigkeit
static func pick_group(faction_id: String, difficulty: String, rng: RandomNumberGenerator) -> Array:
	var groups: Dictionary = faction(faction_id).get("groups", DEFAULT_GROUPS)
	var list: Array = groups.get(difficulty, groups.get("mittel", DEFAULT_GROUPS.mittel))
	return list[rng.randi_range(0, list.size() - 1)].duplicate()


## Neues Gegnerschiff aus einer Vorlage
static func make(template_id: String, idx: int) -> SpaceShip:
	var t: Dictionary = ship(template_id)
	var s := SpaceShip.new()
	s.id = "g%d" % idx
	s.template = template_id
	s.name = String(t.name) if idx <= 0 else "%s %s" % [t.name, char(0x3B1 + (idx - 1) % 24)]
	s.side = &"enemy"
	s.cls = int(t.cls)
	s.hull = int(t.hull)
	s.hull_max = int(t.hull)
	s.shield_max = int(t.shield)
	s.shield_recharge = int(t.recharge)
	for i in 6:
		s.shields[i] = s.shield_max
	s.armor = int(t.armor)
	s.vw = int(t.vw)
	s.speed = int(t.speed)
	s.max_speed = int(t.max_speed)
	s.turns = int(t.turns)
	s.crew_skill = int(t.skill)
	s.init_bonus = int(t.init)
	var n := 0
	for w in t.weapons:
		var slot := "turm" if ShipWeapons.data(w).slot == "turm" else "w%d" % n
		if slot == "turm" and s.slots.has("turm"):
			slot = "turm%d" % n
		s.slots[slot] = {"key": w, "damage": 0}
		n += 1
	return s
