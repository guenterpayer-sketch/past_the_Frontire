class_name Equipment
extends RefCounted
## Ausrüstung ändern (Waffenkammer, docs/Planung_Waffenkammer.md): Waffe 1 (Pflicht), Waffe 2 (darf leer sein),
## Rüstung, Schild. Bestand unbegrenzt. Psi-Waffen sind nicht wählbar (Psi-Angriffe kommen aus den Psi-Listen).
## Keine Waffe doppelt; Schild nur, wenn Waffe 1 und Waffe 2 einhändig sind (Waffe 2 darf leer sein).

## wählbare Waffen: mitgelieferte (außer Psi) nach Name, danach die eigenen aus dem Ausrüstungs-Editor (Gear)
static func weapons() -> Array[WeaponData]:
	var out: Array[WeaponData] = GameData.weapons().filter(func(w: WeaponData) -> bool: return not w.psi)
	var have := out.map(func(w: WeaponData) -> String: return w.resource_path)
	for w in Gear.weapons():
		if not w.psi and not w.resource_path in have:
			out.append(w)
	return out


## wählbare Rüstungen: mitgelieferte nach Klasse, danach die eigenen (Gear)
static func armors() -> Array[ArmorData]:
	var out: Array[ArmorData] = []
	for f in ResourceLoader.list_directory("res://data/armor"):
		if f.ends_with(".tres"):
			out.append(load("res://data/armor/" + f))
	out.sort_custom(func(a: ArmorData, b: ArmorData) -> bool: return a.cls < b.cls)
	out.append_array(Gear.armors())
	return out


## Name mit Vermerk „frei“ für eigene Ausrüstung mit Werten ohne Grenzen (Gear.is_free)
static func label(r: Resource) -> String:
	if r == null:
		return "–"
	return String(r.get("name")) + (" (frei)" if Gear.is_free(r) else "")


## Waffe im Platz (0 oder 1) oder null
static func weapon(ch: Character, slot: int) -> WeaponData:
	return ch.weapons[slot] if slot < ch.weapons.size() else null


## Warum die Waffe in diesem Platz nicht geht ("" = erlaubt)
static func weapon_block(ch: Character, slot: int, w: WeaponData) -> String:
	if w == null:
		return "Waffe 1 ist Pflicht" if slot == 0 else ""
	if w.psi:
		return "Psi-Angriffe kommen aus den Psi-Listen"
	var other := weapon(ch, 1 - slot)
	if other and other.id == w.id:
		return "schon als Waffe %d gewählt" % (2 - slot)
	return ""


## Waffe setzen (null in Platz 1 = Waffe 2 leer). Legt den Schild ab, wenn eine zweihändige Waffe dazukommt.
## Gibt "" zurück oder den Grund, warum es nicht geht.
static func set_weapon(ch: Character, slot: int, w: WeaponData) -> String:
	var why := weapon_block(ch, slot, w)
	if why != "":
		return why
	if blocks_shield(w) and ch.shield:
		ch.shield = false
	if slot == 0:
		ch.weapons[0] = w
	elif w == null:
		ch.weapons = ch.weapons.slice(0, 1)
	elif ch.weapons.size() > 1:
		ch.weapons[1] = w
	else:
		ch.weapons.append(w)
	return ""


## zweihändige Waffe (Fäuste zählen nicht: waffenloser Kampf geht auch mit Schild)
static func blocks_shield(w: WeaponData) -> bool:
	return w != null and w.two_handed and w.skill != &"waffenlos"


static func shield_block(ch: Character) -> String:
	for w in ch.weapons:
		if blocks_shield(w):
			return "nur mit einhändigen Waffen (%s ist zweihändig)" % w.name
	return ""


static func set_shield(ch: Character, on: bool) -> String:
	if on and shield_block(ch) != "":
		return shield_block(ch)
	ch.shield = on
	return ""


## Verteidigungsbonus des Schilds für diese Figur (wie im Kampf: +10 + ½ Rangbonus Schild, mindestens +10)
static func shield_bonus(ch: Character) -> int:
	return 10 + maxi(0, Rules.rank_bonus(Rules.skill_rank(ch, &"schild")) / 2)


## Faktor für erhaltenen Schaden je Rüstungsklasse (nicht gegen Psi)
static func damage_taken(a: ArmorData) -> float:
	return Tables.ARMOR_DMG[a.cls] if a else 1.0
