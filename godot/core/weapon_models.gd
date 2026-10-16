class_name WeaponModels
## Katalog der Waffenmodelle (Auftrag „neue Waffenmodelle und Klänge“, 16.10.2026): Modell, Anzeigename und wie es in der
## Hand sitzt (Länge in Metern, Griff-Versatz, zweihändig). Der Ausrüstungs-Editor des Hubs bietet diese Liste an;
## apply() überträgt einen Eintrag auf eine Waffe. Modelle liegen entlang x (Nahkampfwaffen über eine .tscn-Hülle gedreht),
## Griff-Drehung immer GRIP_ROT. Neue Schusswaffen-Modelle (Ultimate Guns, Blaster Kit) kommen hier dazu, sobald sie da sind.

const GRIP_ROT := Vector3(0, 0, 90)

const LIST := [
	# Schusswaffen (Quaternius „Sci-Fi Modular Gun Pack“, bisher schon im Spiel)
	{"model": "res://assets/weapons/pistol_1.glb", "name": "Laserpistole", "melee": false, "length_m": 0.35, "grip_offset": Vector3(0, 0.063, 0), "two_handed": false},
	{"model": "res://assets/weapons/ar_3.glb", "name": "Laserkarabiner", "melee": false, "length_m": 0.85, "grip_offset": Vector3(0, 0.153, 0), "two_handed": true},
	{"model": "res://assets/weapons/ar_1.glb", "name": "Sturmgewehr", "melee": false, "length_m": 0.95, "grip_offset": Vector3(0, 0.171, 0), "two_handed": true},
	{"model": "res://assets/weapons/ar_6.glb", "name": "Schweres MG", "melee": false, "length_m": 1.1, "grip_offset": Vector3(0, 0.198, 0), "two_handed": true},
	{"model": "res://assets/weapons/grenade_launcher.glb", "name": "Raketenwerfer", "melee": false, "length_m": 1.1, "grip_offset": Vector3(0, 0.198, 0), "two_handed": true},
	# Nahkampf, Bögen, Schilde (Quaternius „Modular Weapons Pack“)
	{"model": "res://assets/weapons/melee/sword.tscn", "name": "Schwert", "melee": true, "length_m": 0.95, "grip_offset": Vector3(0, 0.404, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/sword_2.tscn", "name": "Breitschwert", "melee": true, "length_m": 0.95, "grip_offset": Vector3(0, 0.401, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/sword_golden.tscn", "name": "Goldschwert", "melee": true, "length_m": 1.0, "grip_offset": Vector3(0, 0.448, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/sword_big.tscn", "name": "Langschwert", "melee": true, "length_m": 1.3, "grip_offset": Vector3(0, 0.615, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/claymore.tscn", "name": "Zweihänder", "melee": true, "length_m": 1.4, "grip_offset": Vector3(0, 0.666, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/dagger.tscn", "name": "Dolch", "melee": true, "length_m": 0.35, "grip_offset": Vector3(0, 0.136, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/dagger_2.tscn", "name": "Kampfmesser", "melee": true, "length_m": 0.4, "grip_offset": Vector3(0, 0.157, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/axe.tscn", "name": "Axt", "melee": true, "length_m": 0.8, "grip_offset": Vector3(0, 0.304, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/axe_small.tscn", "name": "Beil", "melee": true, "length_m": 0.5, "grip_offset": Vector3(0, 0.19, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/axe_double.tscn", "name": "Doppelaxt", "melee": true, "length_m": 1.1, "grip_offset": Vector3(0, 0.418, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/hammer_small.tscn", "name": "Hammer", "melee": true, "length_m": 0.6, "grip_offset": Vector3(0, 0.228, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/hammer_double.tscn", "name": "Kriegshammer", "melee": true, "length_m": 1.1, "grip_offset": Vector3(0, 0.418, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/scythe.tscn", "name": "Sense", "melee": true, "length_m": 1.7, "grip_offset": Vector3(0, 0.646, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/spear.tscn", "name": "Speer", "melee": true, "length_m": 2.0, "grip_offset": Vector3(0, 0.76, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/bow_wooden.tscn", "name": "Bogen (Holz)", "melee": true, "length_m": 1.3, "grip_offset": Vector3(0, 0.0, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/bow_wooden2.tscn", "name": "Bogen (Holz 2)", "melee": true, "length_m": 1.3, "grip_offset": Vector3(0, 0.0, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/bow_golden.tscn", "name": "Bogen (Gold)", "melee": true, "length_m": 1.3, "grip_offset": Vector3(0, 0.0, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/bow_evil.tscn", "name": "Bogen (dunkel)", "melee": true, "length_m": 1.3, "grip_offset": Vector3(0, 0.0, 0), "two_handed": true},
	{"model": "res://assets/weapons/melee/arrow.tscn", "name": "Pfeil", "melee": true, "length_m": 0.8, "grip_offset": Vector3(0, 0.0, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/shield_round.tscn", "name": "Rundschild", "melee": true, "length_m": 0.7, "grip_offset": Vector3(0, 0.0, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/shield_round_2.tscn", "name": "Rundschild 2", "melee": true, "length_m": 0.7, "grip_offset": Vector3(0, 0.0, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/shield_heater.tscn", "name": "Wappenschild", "melee": true, "length_m": 0.8, "grip_offset": Vector3(0, 0.0, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/shield_heater_2.tscn", "name": "Wappenschild 2", "melee": true, "length_m": 0.8, "grip_offset": Vector3(0, 0.0, 0), "two_handed": false},
	{"model": "res://assets/weapons/melee/shield_celtic_golden.tscn", "name": "Keltenschild", "melee": true, "length_m": 0.9, "grip_offset": Vector3(0, 0.0, 0), "two_handed": false},
]


## Alle Einträge, je mit geladenem Modell unter "scene"
static func all() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in LIST:
		if ResourceLoader.exists(e.model):
			var d: Dictionary = e.duplicate()
			d["scene"] = load(e.model)
			out.append(d)
	return out


## Eintrag zu einem Modell (Pfad) oder {}
static func find(model_path: String) -> Dictionary:
	for e in LIST:
		if e.model == model_path:
			return e
	return {}


## Modell samt Länge, Griff und Ein-/Zweihändigkeit auf eine Waffe übertragen
static func apply(w: WeaponData, e: Dictionary) -> void:
	w.model = load(e.model)
	w.length_m = e.length_m
	w.grip_offset = e.grip_offset
	w.grip_rotation_deg = GRIP_ROT
	w.two_handed = e.two_handed
