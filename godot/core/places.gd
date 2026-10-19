class_name Places
extends RefCounted
## Orte in einem System (Auftrag 2, Entscheidungen des Nutzers 19.10.2026, Mockup Bildschirm 46): 2–4 je System,
## je Ort {kind, name, done}. Funktionen: Station = Handel (in Fraktionssystemen 20 % teurer als im Hafen),
## Wrack = Bergung, Gasriese/Nebel = Treibstoff schöpfen, Planet/Mond/Station/Wrack = Kartentyp der Bodeneinsätze.

const KINDS := {"station": "Station", "planet": "Planet", "mond": "Mond", "wrack": "Wrack", "gas": "Gasriese", "nebel": "Nebel"}
## Zufallsgewichte der Ortsarten (ohne die Station, die jeder Hafen bekommt)
const WEIGHTS := {"station": 3, "planet": 4, "mond": 2, "wrack": 2, "gas": 2, "nebel": 1}
const MIN_PLACES := 2
const MAX_PLACES := 4
## Kartentypen der Bodeneinsätze je Ortsart
const MAPS := {"station": [&"buero", &"bar"], "planet": [&"strasse", &"tempel", &"halle"], "mond": [&"halle", &"tempel"],
	"wrack": [&"halle"]}
## Handel an Stationen außerhalb eines Hafens: Preise ×1,2
const STATION_FACTOR := 1.2
## Bergung am Wrack: Probe Reparatur (mittel), 1 Tag
const SALVAGE_SKILL := &"rsReparatur"
const SALVAGE := {&"patzer": {"hull": -5}, &"fehlschlag": {}, &"teilerfolg": {"material": 1},
	&"erfolg": {"material": 3, "craft": 2}, &"herausragend": {"material": 3, "craft": 2, "weapon": true}}
## Treibstoff schöpfen: Probe Pilot (mittel), 1 Tag
const SKIM_SKILL := &"pilot"
const SKIM := {&"patzer": -5, &"fehlschlag": 0, &"teilerfolg": 10, &"erfolg": 20, &"herausragend": 30}
const WRECK_NAMES := ["Ilsa", "Kormoran", "Varga", "Sennet", "Halcyon", "Mira", "Tolsk", "Orgo", "Fenwick", "Ruun"]
const MOONS := ["I", "II", "III"]


## Orte eines Systems: ein Hafen (neutral) hat immer eine Station
static func generate(system_name: String, harbor: bool, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var n := rng.randi_range(MIN_PLACES, MAX_PLACES)
	if harbor:
		out.append({"kind": "station", "name": "Hafen " + system_name, "done": false})
	var planets := 0
	while out.size() < n:
		var kind := _pick(rng)
		if kind == "station" and out.any(func(p: Dictionary) -> bool: return p.kind == "station"):
			continue
		var nm := ""
		match kind:
			"station":
				nm = system_name + "-Ring"
			"planet":
				nm = "%s %s" % [system_name, "bcde"[planets]]
				planets += 1
			"mond":
				nm = "Mond %s %s" % [system_name, MOONS[rng.randi_range(0, MOONS.size() - 1)]]
			"wrack":
				nm = "Wrack „%s“" % WRECK_NAMES[rng.randi_range(0, WRECK_NAMES.size() - 1)]
			"gas":
				nm = system_name + " Gasriese"
			"nebel":
				nm = system_name + "-Nebel"
		if out.any(func(p: Dictionary) -> bool: return p.name == nm):
			continue
		out.append({"kind": kind, "name": nm, "done": false})
	return out


static func _pick(rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in WEIGHTS:
		total += int(WEIGHTS[k])
	var x := rng.randi_range(1, total)
	for k in WEIGHTS:
		x -= int(WEIGHTS[k])
		if x <= 0:
			return k
	return "planet"


static func kind_name(kind: String) -> String:
	return String(KINDS.get(kind, kind))


## Kurzbeschreibung der Möglichkeiten eines Orts
static func function_text(kind: String) -> String:
	return {"station": "Handel (in Fraktionssystemen 20 % teurer als im Hafen)", "planet": "Bodeneinsätze (Straße, Tempel, Lagerhalle)",
		"mond": "Bodeneinsätze (Lagerhalle, Tempel)", "wrack": "Bergung: 1 Tag, Probe Reparatur", "gas": "Treibstoff schöpfen: 1 Tag, Probe Pilot",
		"nebel": "Treibstoff schöpfen: 1 Tag, Probe Pilot"}.get(kind, "")


## Kann hier Bodenkampf stattfinden (Aufträge an diesem Ort)?
static func has_ground(kind: String) -> bool:
	return MAPS.has(kind)


## Kartentyp eines Bodeneinsatzes an diesem Ort (seed wählt unter den passenden)
static func map_for(kind: String, seed_value: int) -> StringName:
	var list: Array = MAPS.get(kind, MapTypes.GROUND)
	return list[absi(seed_value) % list.size()]


static func is_trade(kind: String) -> bool:
	return kind == "station"


static func is_fuel(kind: String) -> bool:
	return kind == "gas" or kind == "nebel"


# ---------------------------------------------------------------- Funktionen

## Ort im aktuellen System des Schiffs
static func place(g: HubState, index: int) -> Dictionary:
	var pl: Array = g.sector.systems[g.position].get("places", [])
	return pl[index] if index >= 0 and index < pl.size() else {}


## Wer würfelt: die oder der Beste in der Fertigkeit unter den verfügbaren (Voyage.available)
static func best(g: HubState, skill: StringName) -> Character:
	var out: Character = null
	for c in Voyage.available(g):
		if out == null or Rules.skill_total(c, skill) > Rules.skill_total(out, skill):
			out = c
	return out


static func can_salvage(g: HubState, index: int) -> bool:
	var p := place(g, index)
	return not p.is_empty() and p.kind == "wrack" and not p.done and best(g, SALVAGE_SKILL) != null


## Bergung am Wrack: 1 Tag, Probe, Beute; danach ist das Wrack leer. Gibt {text, result, name, skill, xp} zurück.
static func salvage(g: HubState, index: int) -> Dictionary:
	if not can_salvage(g, index):
		return {}
	var p := place(g, index)
	var c := best(g, SALVAGE_SKILL)
	var r := Voyage.check(c, SALVAGE_SKILL, Galley.malus(g))
	var gain: Dictionary = SALVAGE[StringName(r.result)]
	var parts := []
	if gain.has("hull"):
		g.hull = maxi(0, g.hull + int(gain.hull))
		parts.append("Hülle %d" % int(gain.hull))
	if gain.has("material"):
		g.material += int(gain.material)
		parts.append("+%d Schiffsmaterial" % int(gain.material))
	if gain.has("craft"):
		g.craft_material += int(gain.craft)
		parts.append("+%d Handwerksmaterial" % int(gain.craft))
	if gain.get("weapon", false):
		var keys := ShipWeapons.keys()
		var key := Stock.damaged_key(keys[randi() % keys.size()], -20)
		ShipArms.stock_add(g, key)
		parts.append(ShipArms.label(key) + " ins Schiffslager")
	p.done = true
	g.advance_days(1)
	return {"text": "%s birgt am %s: %s (%d) → %s" % [c.name, p.name, r.result_name, int(r.total), ", ".join(parts) if not parts.is_empty() else "nichts"],
		"result": String(r.result), "name": c.name, "skill": String(SALVAGE_SKILL), "xp": int(r.xp)}


static func can_skim(g: HubState, index: int) -> bool:
	var p := place(g, index)
	return not p.is_empty() and is_fuel(p.kind) and g.fuel < g.tank_max() and best(g, SKIM_SKILL) != null


## Treibstoff schöpfen: 1 Tag, Probe Pilot; beliebig oft
static func skim(g: HubState, index: int) -> Dictionary:
	if not can_skim(g, index):
		return {}
	var p := place(g, index)
	var c := best(g, SKIM_SKILL)
	var r := Voyage.check(c, SKIM_SKILL, Galley.malus(g))
	var n := int(SKIM[StringName(r.result)])
	var text := ""
	if n < 0:
		g.hull = maxi(0, g.hull + n)
		text = "Hülle %d" % n
	else:
		var f0 := g.fuel
		g.fuel = mini(g.tank_max(), g.fuel + n)
		text = "+%d Treibstoff" % (g.fuel - f0)
	g.advance_days(1)
	return {"text": "%s schöpft am %s: %s (%d) → %s" % [c.name, p.name, r.result_name, int(r.total), text],
		"result": String(r.result), "name": c.name, "skill": String(SKIM_SKILL), "xp": int(r.xp)}
