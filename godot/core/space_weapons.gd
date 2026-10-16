class_name ShipWeapons
extends RefCounted
## Katalog der Schiffswaffen (Raumkampf, docs/module/raumkampf.md „Schnittstellen“). Der Hub liest daraus Keys, Namen
## und Preise für Handel, Lager und Anzeige. Alle Zahlen sind Platzhalter bis zur Simulation.
## art: strahl/ballistik/rakete/abwehr · slot: "normal" oder "turm" · ammo: "" (Energie) oder Schiffsmunition ·
## energy: Energie je Schuss · shots: Schüsse je Runde · range: Reichweite in Feldern (darüber −10 je Feld) ·
## dmg: Schadensfaktor · mod: Angriffsmodifikator · trade: im Handel und als Beute (false = nur Gegner)

const AMMO_TYPES := {"schiffsraketen": "Schiffsraketen", "geschosse": "Geschosse"}

const CATALOG := {
	"laserbank": {"name": "Laserbank", "art": "strahl", "slot": "normal", "ammo": "", "energy": 2, "shots": 1,
		"range": 6, "dmg": 1.0, "mod": 5, "price": 900, "trade": true},
	"partikelkanone": {"name": "Partikelkanone", "art": "strahl", "slot": "normal", "ammo": "", "energy": 4, "shots": 1,
		"range": 5, "dmg": 1.6, "mod": 0, "price": 1800, "trade": true},
	"massebeschleuniger": {"name": "Massebeschleuniger", "art": "ballistik", "slot": "normal", "ammo": "geschosse",
		"energy": 0, "shots": 1, "range": 8, "dmg": 1.3, "mod": 0, "price": 1200, "trade": true},
	"schnellfeuerkanone": {"name": "Schnellfeuerkanone", "art": "ballistik", "slot": "normal", "ammo": "geschosse",
		"energy": 0, "shots": 2, "range": 4, "dmg": 0.7, "mod": 10, "price": 1100, "trade": true},
	"raketenwerfer": {"name": "Raketenwerfer", "art": "rakete", "slot": "normal", "ammo": "schiffsraketen", "energy": 0,
		"shots": 1, "range": 10, "dmg": 2.0, "mod": 10, "price": 1300, "trade": true},
	"raketenbatterie": {"name": "Raketenbatterie", "art": "rakete", "slot": "normal", "ammo": "schiffsraketen",
		"energy": 0, "shots": 2, "range": 8, "dmg": 1.5, "mod": 5, "price": 2200, "trade": true},
	"abwehrgeschuetz": {"name": "Abwehrgeschütz", "art": "abwehr", "slot": "turm", "ammo": "geschosse", "energy": 0,
		"shots": 2, "range": 3, "dmg": 0.8, "mod": 10, "price": 800, "trade": true},
	"abwehrlaser": {"name": "Abwehrlaser", "art": "abwehr", "slot": "turm", "ammo": "", "energy": 1, "shots": 2,
		"range": 3, "dmg": 0.7, "mod": 15, "price": 1000, "trade": true},
	# nur Gegner (kein Handel)
	"jaegerkanone": {"name": "Jägerkanone", "art": "strahl", "slot": "normal", "ammo": "", "energy": 0, "shots": 1,
		"range": 3, "dmg": 0.8, "mod": 10, "price": 0, "trade": false},
}

const ART_NAMES := {"strahl": "Strahl", "ballistik": "Ballistik", "rakete": "Rakete", "abwehr": "Abwehr"}
## Fertigkeit der Geschützstation je Art (Abwehr: Ballistik-Geschütze, Vorschlag aus docs/Raumkampf.md)
const ART_SKILL := {"strahl": &"strahlGeschuetze", "ballistik": &"ballistikGeschuetze", "rakete": &"raketen",
	"abwehr": &"ballistikGeschuetze"}


## Handelbare Waffen (Schnittstelle zum Hub)
static func keys() -> Array[String]:
	var out: Array[String] = []
	for k in CATALOG:
		if CATALOG[k].trade:
			out.append(k)
	return out


static func has(key: String) -> bool:
	return CATALOG.has(key)


static func data(key: String) -> Dictionary:
	return CATALOG.get(key, {})


static func name(key: String) -> String:
	return String(CATALOG[key].name) if CATALOG.has(key) else key


static func price(key: String) -> int:
	return int(CATALOG[key].price) if CATALOG.has(key) else 0


## "" = Energie (keine Munition), sonst Schiffsmunition (AMMO_TYPES)
static func ammo(key: String) -> String:
	return String(CATALOG[key].ammo) if CATALOG.has(key) else ""


static func skill(key: String) -> StringName:
	return ART_SKILL[CATALOG[key].art]


## Passt die Waffe in den Slot? Turm-Slots nur Abwehrwaffen, alle anderen jede andere Waffe.
static func fits(key: String, slot_id: String) -> bool:
	if not CATALOG.has(key):
		return false
	var turret := slot_id.begins_with("turm")
	return (CATALOG[key].slot == "turm") == turret


static func describe(key: String) -> String:
	if not CATALOG.has(key):
		return key
	var w: Dictionary = CATALOG[key]
	var use := "%d Energie" % w.energy if w.ammo == "" else String(AMMO_TYPES[w.ammo])
	return "%s · %s · %d Schuss/Runde · Reichweite %d · %s" % [w.name, ART_NAMES[w.art], w.shots, w.range, use]
