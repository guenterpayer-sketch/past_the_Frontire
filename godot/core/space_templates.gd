class_name SpaceTemplates
extends RefCounted
## Gegnervorlagen für den Raumkampf: Schiffe/Jäger und Gegnerseiten (Missionsfraktionen aus data/missions und eigene
## Raumgegner). Gewählt wird aus faction + difficulty im setup. Alle Zahlen und die Gegnerzahl je Schwierigkeit sind
## Platzhalter bis zur Simulation (Entscheidung des Nutzers 16.10.2026). Vorerst als Konstanten statt data/ships/.

## cls: Index in SpaceShip.CLASSES · vw: Grund-VW (dazu die halbe Besatzung wie beim eigenen Schiff der halbe
## Pilot-Bonus) · skill: Bonus der Besatzung · init: Initiative-Bonus · loot: Credits/Material
const SHIPS := {
	"jaeger": {"name": "Jäger", "cls": 0, "hull": 14, "shield": 0, "recharge": 0, "armor": 0, "vw": 15, "speed": 4,
		"max_speed": 6, "turns": 3, "weapons": ["jaegerkanone"], "skill": 35, "init": 10, "credits": 60, "material": 0},
	"drohne": {"name": "Kampfdrohne", "cls": 0, "hull": 10, "shield": 0, "recharge": 0, "armor": 0, "vw": 15, "speed": 4,
		"max_speed": 5, "turns": 3, "weapons": ["jaegerkanone"], "skill": 30, "init": 8, "credits": 20, "material": 1},
	"korvette": {"name": "Korvette", "cls": 1, "hull": 60, "shield": 8, "recharge": 3, "armor": 1, "vw": 5, "speed": 3,
		"max_speed": 4, "turns": 2, "weapons": ["laserbank", "raketenwerfer"], "skill": 35, "init": 6, "credits": 300,
		"material": 3},
	"fregatte": {"name": "Fregatte", "cls": 2, "hull": 110, "shield": 14, "recharge": 4, "armor": 2, "vw": 0, "speed": 2,
		"max_speed": 3, "turns": 1, "weapons": ["partikelkanone", "massebeschleuniger", "abwehrgeschuetz"], "skill": 45,
		"init": 4, "credits": 700, "material": 6},
	"kreuzer": {"name": "Kreuzer", "cls": 3, "hull": 180, "shield": 20, "recharge": 6, "armor": 3, "vw": -5, "speed": 2,
		"max_speed": 2, "turns": 1, "weapons": ["partikelkanone", "partikelkanone", "raketenbatterie", "abwehrlaser"],
		"skill": 50, "init": 2, "credits": 1400, "material": 10},
}

## Gegnerseiten: on_win "entern"/"abziehen" (Niederlage der Crew → Entern bzw. Notfall), ransom: Lösegeld in Credits
## (0 = nimmt keins), flee_at: Hüllenanteil, ab dem ein Gegnerschiff abdreht (0 = nie).
## groups je Schwierigkeit: Liste möglicher Aufstellungen, eine wird gewürfelt.
const FACTIONS := {
	"piraten": {"name": "Piraten", "on_win": "entern", "ransom": 400, "flee_at": 0.25},
	"militaer": {"name": "Militär", "on_win": "abziehen", "ransom": 0, "flee_at": 0.0},
	"drohnen": {"name": "Drohnenschwarm", "on_win": "abziehen", "ransom": 0, "flee_at": 0.0,
		"groups": {"leicht": [["drohne", "drohne"]], "mittel": [["drohne", "drohne", "drohne", "drohne"]],
			"schwer": [["fregatte", "drohne", "drohne", "drohne", "drohne"]]}},
	# Missionsfraktionen (data/missions/<id>.tres)
	"rote_sonne": {"name": "Söldner der Roten Sonne", "on_win": "entern", "ransom": 600, "flee_at": 0.2},
	"schmuggler": {"name": "Schmuggler", "on_win": "entern", "ransom": 300, "flee_at": 0.35},
	"konzern": {"name": "Konzernsicherheit", "on_win": "abziehen", "ransom": 800, "flee_at": 0.0},
	"leeres_licht": {"name": "Leeres Licht", "on_win": "entern", "ransom": 0, "flee_at": 0.0},
}

## Aufstellungen für Seiten ohne eigene groups
const DEFAULT_GROUPS := {
	"leicht": [["korvette"], ["jaeger", "jaeger", "jaeger"]],
	"mittel": [["korvette", "jaeger"], ["korvette", "jaeger", "jaeger"]],
	"schwer": [["fregatte", "jaeger", "jaeger"], ["kreuzer"], ["korvette", "korvette", "jaeger", "jaeger"]],
}


static func faction(id: String) -> Dictionary:
	return FACTIONS.get(id, FACTIONS.piraten)


static func faction_name(id: String) -> String:
	return String(faction(id).name)


## Aufstellung (Liste von Vorlagen-IDs) für Seite und Schwierigkeit
static func pick_group(faction_id: String, difficulty: String, rng: RandomNumberGenerator) -> Array:
	var groups: Dictionary = faction(faction_id).get("groups", DEFAULT_GROUPS)
	var list: Array = groups.get(difficulty, groups.get("mittel", DEFAULT_GROUPS.mittel))
	return list[rng.randi_range(0, list.size() - 1)].duplicate()


## Neues Gegnerschiff aus einer Vorlage
static func make(template_id: String, idx: int) -> SpaceShip:
	var t: Dictionary = SHIPS[template_id]
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
