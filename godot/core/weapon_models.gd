class_name WeaponModels
## Katalog der Waffenmodelle (Auftrag „neue Waffenmodelle und Klänge“, 16.10.2026): Modell, Anzeigename und wie es in der
## Hand sitzt (Länge in Metern, Griff-Versatz, zweihändig); bei neuen Schusswaffen ein vorgeschlagener Klang ("sound",
## Schlüssel aus WeaponData.SOUNDS). Der Ausrüstungs-Editor des Hubs bietet diese Liste an;
## apply() überträgt einen Eintrag auf eine Waffe. Modelle liegen entlang x (Nahkampfwaffen über eine .tscn-Hülle gedreht),
## Griff-Drehung immer GRIP_ROT. Die Mündung zeigt nach +x.

const GRIP_ROT := Vector3(0, 0, 90)

const LIST := [
	# Schusswaffen (Quaternius „Sci-Fi Modular Gun Pack“, bisher schon im Spiel)
	{"model": "res://assets/weapons/pistol_1.glb", "name": "Laserpistole", "melee": false, "length_m": 0.35, "grip_offset": Vector3(0, 0.063, 0), "two_handed": false},
	{"model": "res://assets/weapons/ar_3.glb", "name": "Laserkarabiner", "melee": false, "length_m": 0.85, "grip_offset": Vector3(0, 0.153, 0), "two_handed": true},
	{"model": "res://assets/weapons/ar_1.glb", "name": "Sturmgewehr", "melee": false, "length_m": 0.95, "grip_offset": Vector3(0, 0.171, 0), "two_handed": true},
	{"model": "res://assets/weapons/ar_6.glb", "name": "Schweres MG", "melee": false, "length_m": 1.1, "grip_offset": Vector3(0, 0.198, 0), "two_handed": true},
	{"model": "res://assets/weapons/grenade_launcher.glb", "name": "Raketenwerfer", "melee": false, "length_m": 1.1, "grip_offset": Vector3(0, 0.198, 0), "two_handed": true},
	# Schusswaffen (Quaternius „Ultimate Guns Pack“, GLB von poly.pizza)
	{"model": "res://assets/weapons/guns/assault_rifle.glb", "name": "Sturmgewehr A", "melee": false, "length_m": 0.9, "grip_offset": Vector3(0, 0.162, 0), "two_handed": true, "sound": &"sturmgewehr"},
	{"model": "res://assets/weapons/guns/assault_rifle_2.glb", "name": "Sturmgewehr B", "melee": false, "length_m": 0.9, "grip_offset": Vector3(0, 0.162, 0), "two_handed": true, "sound": &"sturmgewehr"},
	{"model": "res://assets/weapons/guns/assault_rifle_3.glb", "name": "Sturmgewehr C", "melee": false, "length_m": 0.9, "grip_offset": Vector3(0, 0.162, 0), "two_handed": true, "sound": &"sturmgewehr"},
	{"model": "res://assets/weapons/guns/bullpup.glb", "name": "Bullpup-Gewehr", "melee": false, "length_m": 0.75, "grip_offset": Vector3(0, 0.135, 0), "two_handed": true, "sound": &"sturmgewehr"},
	{"model": "res://assets/weapons/guns/pistol.glb", "name": "Pistole A", "melee": false, "length_m": 0.3, "grip_offset": Vector3(0, 0.054, 0), "two_handed": false, "sound": &"pistole"},
	{"model": "res://assets/weapons/guns/pistol_2.glb", "name": "Pistole B", "melee": false, "length_m": 0.32, "grip_offset": Vector3(0, 0.058, 0), "two_handed": false, "sound": &"pistole"},
	{"model": "res://assets/weapons/guns/pistol_3.glb", "name": "Pistole C", "melee": false, "length_m": 0.3, "grip_offset": Vector3(0, 0.054, 0), "two_handed": false, "sound": &"pistole"},
	{"model": "res://assets/weapons/guns/pistol_4.glb", "name": "Pistole D", "melee": false, "length_m": 0.3, "grip_offset": Vector3(0, 0.054, 0), "two_handed": false, "sound": &"pistole"},
	{"model": "res://assets/weapons/guns/revolver.glb", "name": "Revolver A", "melee": false, "length_m": 0.32, "grip_offset": Vector3(0, 0.058, 0), "two_handed": false, "sound": &"revolver"},
	{"model": "res://assets/weapons/guns/revolver_2.glb", "name": "Revolver B", "melee": false, "length_m": 0.32, "grip_offset": Vector3(0, 0.058, 0), "two_handed": false, "sound": &"revolver"},
	{"model": "res://assets/weapons/guns/revolver_3.glb", "name": "Revolver C", "melee": false, "length_m": 0.32, "grip_offset": Vector3(0, 0.058, 0), "two_handed": false, "sound": &"revolver"},
	{"model": "res://assets/weapons/guns/shotgun.glb", "name": "Schrotflinte A", "melee": false, "length_m": 1.0, "grip_offset": Vector3(0, 0.18, 0), "two_handed": true, "sound": &"schrotflinte"},
	{"model": "res://assets/weapons/guns/shotgun_2.glb", "name": "Schrotflinte B", "melee": false, "length_m": 1.0, "grip_offset": Vector3(0, 0.18, 0), "two_handed": true, "sound": &"schrotflinte"},
	{"model": "res://assets/weapons/guns/shotgun_sawed_off.glb", "name": "Abgesägte Schrotflinte", "melee": false, "length_m": 0.6, "grip_offset": Vector3(0, 0.108, 0), "two_handed": false, "sound": &"schrotflinte"},
	{"model": "res://assets/weapons/guns/shotgun_short_stock.glb", "name": "Schrotflinte (kurzer Schaft)", "melee": false, "length_m": 0.85, "grip_offset": Vector3(0, 0.153, 0), "two_handed": true, "sound": &"schrotflinte"},
	{"model": "res://assets/weapons/guns/sniper_rifle.glb", "name": "Scharfschützengewehr A", "melee": false, "length_m": 1.2, "grip_offset": Vector3(0, 0.216, 0), "two_handed": true, "sound": &"gewehr_schwer"},
	{"model": "res://assets/weapons/guns/sniper_rifle_2.glb", "name": "Scharfschützengewehr B", "melee": false, "length_m": 1.25, "grip_offset": Vector3(0, 0.225, 0), "two_handed": true, "sound": &"gewehr_schwer"},
	{"model": "res://assets/weapons/guns/sniper_rifle_3.glb", "name": "Scharfschützengewehr C", "melee": false, "length_m": 1.25, "grip_offset": Vector3(0, 0.225, 0), "two_handed": true, "sound": &"gewehr_schwer"},
	{"model": "res://assets/weapons/guns/sniper_rifle_4.glb", "name": "Scharfschützengewehr D", "melee": false, "length_m": 1.2, "grip_offset": Vector3(0, 0.216, 0), "two_handed": true, "sound": &"gewehr_schwer"},
	{"model": "res://assets/weapons/guns/submachine_gun.glb", "name": "Maschinenpistole A", "melee": false, "length_m": 0.6, "grip_offset": Vector3(0, 0.108, 0), "two_handed": true, "sound": &"mp"},
	{"model": "res://assets/weapons/guns/submachine_gun_2.glb", "name": "Maschinenpistole B", "melee": false, "length_m": 0.6, "grip_offset": Vector3(0, 0.108, 0), "two_handed": true, "sound": &"mp"},
	# Blaster (Kenney „Blaster Kit“ 2.1; .tscn-Hülle dreht z → x)
	{"model": "res://assets/weapons/blaster/blaster-a.tscn", "name": "Blaster A", "melee": false, "length_m": 0.6, "grip_offset": Vector3(0, 0.108, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-b.tscn", "name": "Blaster B", "melee": false, "length_m": 0.32, "grip_offset": Vector3(0, 0.058, 0), "two_handed": false, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-c.tscn", "name": "Blaster C", "melee": false, "length_m": 0.36, "grip_offset": Vector3(0, 0.065, 0), "two_handed": false, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-d.tscn", "name": "Blaster D", "melee": false, "length_m": 0.68, "grip_offset": Vector3(0, 0.122, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-e.tscn", "name": "Blaster E", "melee": false, "length_m": 1.04, "grip_offset": Vector3(0, 0.187, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-f.tscn", "name": "Blaster F", "melee": false, "length_m": 0.98, "grip_offset": Vector3(0, 0.176, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-g.tscn", "name": "Blaster G", "melee": false, "length_m": 0.59, "grip_offset": Vector3(0, 0.106, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-h.tscn", "name": "Blaster H", "melee": false, "length_m": 0.49, "grip_offset": Vector3(0, 0.088, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-i.tscn", "name": "Blaster I", "melee": false, "length_m": 0.39, "grip_offset": Vector3(0, 0.07, 0), "two_handed": false, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-j.tscn", "name": "Blaster J", "melee": false, "length_m": 0.46, "grip_offset": Vector3(0, 0.083, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-k.tscn", "name": "Blaster K", "melee": false, "length_m": 0.35, "grip_offset": Vector3(0, 0.063, 0), "two_handed": false, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-l.tscn", "name": "Blaster L", "melee": false, "length_m": 0.41, "grip_offset": Vector3(0, 0.074, 0), "two_handed": false, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-m.tscn", "name": "Blaster M", "melee": false, "length_m": 0.46, "grip_offset": Vector3(0, 0.083, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-n.tscn", "name": "Blaster N", "melee": false, "length_m": 0.48, "grip_offset": Vector3(0, 0.086, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-o.tscn", "name": "Blaster O", "melee": false, "length_m": 0.36, "grip_offset": Vector3(0, 0.065, 0), "two_handed": false, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-p.tscn", "name": "Blaster P", "melee": false, "length_m": 0.65, "grip_offset": Vector3(0, 0.117, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-q.tscn", "name": "Blaster Q", "melee": false, "length_m": 0.53, "grip_offset": Vector3(0, 0.095, 0), "two_handed": true, "sound": &"laser"},
	{"model": "res://assets/weapons/blaster/blaster-r.tscn", "name": "Blaster R", "melee": false, "length_m": 0.51, "grip_offset": Vector3(0, 0.092, 0), "two_handed": true, "sound": &"laser"},
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
