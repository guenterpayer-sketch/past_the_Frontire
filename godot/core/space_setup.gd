class_name SpaceSetup
extends RefCounted
## Eingang des Raumkampfs (Schnittstelle in docs/module/raumkampf.md): Konstanten zu Slots, Stationen und Ausbau-Stufen,
## Startschiff und Schnellkampf. Alle Werte hinter den Stufen sind Platzhalter bis zur Simulation.

## Slots des Startschiffs und die, die der Ausbau „slots“ je Stufe dazugibt
const BASE_SLOTS := ["bug", "backbord", "steuerbord", "turm"]
## Ausbau „slots“ hat 5 Stufen (Entscheidung des Nutzers 16.10.2026)
const SLOTS_BY_LEVEL := ["", "heck", "backbord2", "steuerbord2", "bug2", "turm2"]
const SLOTS_MAX_LEVEL := 5
const SLOT_NAMES := {"bug": "Bug", "bug2": "Bug 2", "backbord": "Backbord", "backbord2": "Backbord 2",
	"steuerbord": "Steuerbord", "steuerbord2": "Steuerbord 2", "turm": "Turm", "turm2": "Turm 2", "heck": "Heck"}
## Startbewaffnung und Startvorrat Schiffsmunition (neuer Spielstand)
const START_SLOTS := {"bug": "laserbank", "backbord": "massebeschleuniger", "steuerbord": "raketenwerfer",
	"turm": "abwehrgeschuetz"}
const START_AMMO := {"schiffsraketen": 6, "geschosse": 40}

## Stationen ohne Geschütze; Geschützstationen heißen "geschuetz_<Slot-ID>"
const BASE_STATIONS := ["steuer", "navigation", "schilde", "technik", "computer"]
## weitere Techniker (nur mit Crew besetzt, nicht mit der Bord-KI); je Techniker 1 Baustelle, eine 2. mit −20
const EXTRA_TECH := ["technik_2", "technik_3"]
const SECOND_TASK_MALUS := -20
const STATION_NAMES := {"steuer": "Steuer", "navigation": "Navigation", "schilde": "Schilde", "technik": "Technik",
	"technik_2": "Technik 2", "technik_3": "Technik 3", "computer": "Computer"}
## Fertigkeit je Station (Geschütze: je nach Waffe, ShipWeapons.skill)
const STATION_SKILL := {"steuer": &"pilot", "navigation": &"navigation", "schilde": &"schutzschild",
	"technik": &"notReparatur", "technik_2": &"notReparatur", "technik_3": &"notReparatur", "computer": &"computer"}
## Posten aus dem Charakter (Character.station, Creation.STATIONS) → Station
const POST_FROM_CHARACTER := {"Steuer": "steuer", "Navigation": "navigation", "Schilde": "schilde",
	"Technik": "technik", "Computer": "computer"}
const KI := "ki"
const KI_BONUS := 0
const DOUBLE_MALUS := -30

## Werte je Ausbau-Stufe 0–3 (Platzhalter)
const SHIELD_PER_SIDE := [10, 14, 18, 24]
const ARMOR_PER_HIT := [0, 1, 2, 4]
const REACTOR_ENERGY := [10, 12, 14, 17]
## eigenes Mutterschiff: Klasse mittel, Grund-VW, Tempo
const OWN_CLASS := 2
const OWN_VW := 5
const OWN_MAX_SPEED := 4
const OWN_TURNS := 1


## Slot-IDs bei Ausbau-Stufe lv
static func slots_for(lv: int) -> Array[String]:
	var out: Array[String] = []
	out.assign(BASE_SLOTS)
	for i in range(1, clampi(lv, 0, SLOTS_MAX_LEVEL) + 1):
		out.append(SLOTS_BY_LEVEL[i])
	return out


static func gun_station(slot_id: String) -> String:
	return "geschuetz_" + slot_id


static func station_name(st: String) -> String:
	if st.begins_with("geschuetz_"):
		var slot := st.trim_prefix("geschuetz_")
		return ("Punktverteidigung %s" % SLOT_NAMES.get(slot, slot)) if slot.begins_with("turm") \
			else "Geschütz %s" % SLOT_NAMES.get(slot, slot)
	return String(STATION_NAMES.get(st, st))


## Alle Stationen eines Schiffs: Grundstationen, je bestücktem Slot eine Geschützstation, weitere Techniker
static func stations_for(slots: Dictionary) -> Array[String]:
	var out: Array[String] = []
	out.assign(BASE_STATIONS)
	for s in slots:
		if String(slots[s].get("key", "")) != "":
			out.append(gun_station(String(s)))
	out.append_array(EXTRA_TECH)
	return out


static func is_tech(st: String) -> bool:
	return st == "technik" or st in EXTRA_TECH


## Startslots als {Slot-ID: {key, damage}} (für Hub und Schnellkampf)
static func start_slots() -> Dictionary:
	var out := {}
	for s in BASE_SLOTS:
		out[s] = {"key": START_SLOTS.get(s, ""), "damage": 0}
	return out


## Vorbelegung der Posten aus Character.station; Geschütz-Posten der Reihe nach auf die Geschützstationen,
## übrige Stationen auf die Bord-KI
static func posts_from_crew(crew: Array, slots: Dictionary) -> Dictionary:
	var posts := {}
	var stations := stations_for(slots)
	var guns: Array = stations.filter(func(s: String) -> bool: return s.begins_with("geschuetz_"))
	for ch in crew:
		var st: String = ch.station
		if POST_FROM_CHARACTER.has(st) and not posts.has(POST_FROM_CHARACTER[st]):
			posts[POST_FROM_CHARACTER[st]] = String(ch.id)
		elif st == "Geschütze" and not guns.is_empty():
			posts[guns.pop_front()] = String(ch.id)
	for s in stations:
		if not posts.has(s):
			posts[s] = KI
	return posts


## Freie Stationen (Bord-KI) mit den Besten besetzen, die noch keinen Posten haben und die Station besser
## können als die Bord-KI
static func fill_posts(crew: Array, slots: Dictionary, posts: Dictionary) -> Dictionary:
	var out := posts.duplicate()
	var free: Array = crew.filter(func(c) -> bool: return not out.values().has(String(c.id)))
	for st in stations_for(slots):
		if out.get(st, KI) != KI:
			continue
		var skill: StringName = ShipWeapons.skill(String(slots[st.trim_prefix("geschuetz_")].key)) \
			if st.begins_with("geschuetz_") else STATION_SKILL[st]
		var best = null
		for c in free:
			if Rules.skill_total(c, skill) > KI_BONUS and (best == null or Rules.skill_total(c, skill) > Rules.skill_total(best, skill)):
				best = c
		if best != null:
			out[st] = String(best.id)
			free.erase(best)
	return out


## Schnellkampf: feste Testwerte ohne HubState. Crew aus Campaign.quick_squad, sonst die Startcrew des Rosters.
static func quick(difficulty := "mittel", faction := "piraten", elite := false, boss := false) -> Dictionary:
	var crew: Array = []
	if not Campaign.quick_squad.is_empty():
		crew.assign(Campaign.quick_squad)
	else:
		crew.assign(Roster.start_crew())
	var slots := start_slots()
	var posts := fill_posts(crew, slots, posts_from_crew(crew, slots))
	return {"crew": crew, "posts": posts,
		"ship": {"hull": 100, "hull_max": 100, "levels": {"shields": 0, "armor": 0, "reactor": 0, "slots": 0},
			"slots": slots, "damage": {}},
		"ship_ammo": START_AMMO.duplicate(), "fuel": 60, "credits": 1000,
		"enemy": {"faction": faction, "difficulty": difficulty, "elite": elite, "boss": boss},
		"source": "schnell", "mission": "Schnellkampf im All", "return_scene": HubState.START_SCENE}
