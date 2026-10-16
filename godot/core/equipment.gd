class_name Equipment
extends RefCounted
## Ausrüstung ändern (Waffenkammer, docs/Planung_Waffenkammer.md): Waffe 1 (Pflicht), Waffe 2 (darf leer sein),
## Rüstung, Schild. Psi-Waffen sind nicht wählbar (Psi-Angriffe kommen aus den Psi-Listen).
## Keine Waffe doppelt; Schild nur, wenn Waffe 1 und Waffe 2 einhändig sind (Waffe 2 darf leer sein).
## Lager (Schritt 3, docs/Planung_Ausbau_Lager_Handwerk.md; Entscheidungen des Nutzers 16.10.2026): Ausrüsten nimmt
## aus dem Lager des Schiffs (Stock), Ablegen legt zurück; Fäuste und „keine Rüstung“ sind immer da; der Schild ist
## ein Lagergegenstand (SHIELD); Medikits aus dem Lager, höchstens MAX_MEDKITS je Figur. g = HubState.game;
## g == null (Schnellkampf, Tests ohne Spiel) = unbegrenzt.

## Lager-Schlüssel des Schilds (kein Ressourcenpfad; Handel/Preis/Name im Hub)
const SHIELD := "schild"
const MAX_MEDKITS := 3

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


# ---------------------------------------------------------------- Lager

## immer verfügbar, zählt nicht im Lager (Fäuste, keine Rüstung)
static func is_free_item(r: Resource) -> bool:
	return r != null and r.resource_path in Stock.EXCLUDE


## Stück im Lager (immer verfügbare: sehr viele)
static func in_stock(g: HubState, r: Resource) -> int:
	return 1 << 20 if is_free_item(r) else Stock.count(g, Stock.key_of(r))


## anzeigen? (im Lager, immer verfügbar, oder getragen)
static func listed(g: HubState, r: Resource, worn: bool) -> bool:
	return worn or in_stock(g, r) > 0


static func _put_back(g: HubState, r: Resource) -> void:
	if r and not is_free_item(r):
		Stock.add(g, Stock.key_of(r))


static func _take(g: HubState, r: Resource) -> bool:
	return r == null or is_free_item(r) or Stock.take(g, Stock.key_of(r))


## Waffe im Platz (0 oder 1) oder null
static func weapon(ch: Character, slot: int) -> WeaponData:
	return ch.weapons[slot] if slot < ch.weapons.size() else null


## Warum die Waffe in diesem Platz nicht geht ("" = erlaubt)
static func weapon_block(ch: Character, slot: int, w: WeaponData, g: HubState = null) -> String:
	if w == null:
		return "Waffe 1 ist Pflicht" if slot == 0 else ""
	if w.psi:
		return "Psi-Angriffe kommen aus den Psi-Listen"
	var other := weapon(ch, 1 - slot)
	if other and other.id == w.id:
		return "schon als Waffe %d gewählt" % (2 - slot)
	if w != weapon(ch, slot) and in_stock(g, w) < 1:
		return "nicht im Lager"
	return ""


## Waffe setzen (null in Platz 1 = Waffe 2 leer). Legt den Schild ab, wenn eine zweihändige Waffe dazukommt.
## Gibt "" zurück oder den Grund, warum es nicht geht.
static func set_weapon(ch: Character, slot: int, w: WeaponData, g: HubState = null) -> String:
	var why := weapon_block(ch, slot, w, g)
	if why != "":
		return why
	var old := weapon(ch, slot)
	if old == w:
		return ""
	_take(g, w)
	_put_back(g, old)
	if blocks_shield(w) and ch.shield:
		ch.shield = false
		Stock.add(g, SHIELD)
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


static func set_shield(ch: Character, on: bool, g: HubState = null) -> String:
	if on == ch.shield:
		return ""
	if on and shield_block(ch) != "":
		return shield_block(ch)
	if on and not Stock.take(g, SHIELD):
		return "kein Schild im Lager"
	if not on:
		Stock.add(g, SHIELD)
	ch.shield = on
	return ""


## Rüstung wechseln (alte zurück ins Lager)
static func set_armor(ch: Character, a: ArmorData, g: HubState = null) -> String:
	if a == ch.armor:
		return ""
	if in_stock(g, a) < 1:
		return "nicht im Lager"
	_take(g, a)
	_put_back(g, ch.armor)
	ch.armor = a
	return ""


## Medikits auf n setzen (0 … MAX_MEDKITS); Differenz aus dem bzw. ins Lager. Gibt die neue Zahl zurück.
static func set_medkits(ch: Character, n: int, g: HubState = null) -> int:
	n = clampi(n, 0, maxi(MAX_MEDKITS, ch.medkits))
	if n > ch.medkits:
		n = ch.medkits + mini(n - ch.medkits, Stock.count(g, Stock.MEDKIT))
		Stock.take(g, Stock.MEDKIT, n - ch.medkits)
	elif n < ch.medkits:
		Stock.add(g, Stock.MEDKIT, ch.medkits - n)
	ch.medkits = n
	return n


## Ausrüstung auf einen früheren Stand {weapons, armor, shield, medkits} zurücksetzen; tauscht mit dem Lager.
## "" = erledigt, sonst Grund (dann bleibt alles, wie es war).
static func restore(ch: Character, snap: Dictionary, g: HubState = null) -> String:
	var now := {"weapons": ch.weapons.duplicate(), "armor": ch.armor, "shield": ch.shield, "medkits": ch.medkits}
	_give_back(ch, g)
	var need := {}
	for r in snap.weapons + [snap.armor]:
		if r and not is_free_item(r):
			need[Stock.key_of(r)] = int(need.get(Stock.key_of(r), 0)) + 1
	if snap.shield:
		need[SHIELD] = int(need.get(SHIELD, 0)) + 1
	if int(snap.medkits) > 0:
		need[Stock.MEDKIT] = int(need.get(Stock.MEDKIT, 0)) + int(snap.medkits)
	for k in need:
		if Stock.count(g, k) < need[k]:
			_equip(ch, now, g)
			return "%s nicht mehr im Lager" % ("Schild" if k == SHIELD else Stock.name_of(k))
	_equip(ch, snap, g)
	return ""


static func _give_back(ch: Character, g: HubState) -> void:
	for w in ch.weapons:
		_put_back(g, w)
	_put_back(g, ch.armor)
	if ch.shield:
		Stock.add(g, SHIELD)
	Stock.add(g, Stock.MEDKIT, ch.medkits)


static func _equip(ch: Character, st: Dictionary, g: HubState) -> void:
	ch.weapons.assign(st.weapons)
	ch.armor = st.armor
	ch.shield = st.shield
	ch.medkits = int(st.medkits)
	for w in ch.weapons:
		_take(g, w)
	_take(g, ch.armor)
	if ch.shield:
		Stock.take(g, SHIELD)
	Stock.take(g, Stock.MEDKIT, ch.medkits)


## Verteidigungsbonus des Schilds für diese Figur (wie im Kampf: +10 + ½ Rangbonus Schild, mindestens +10)
static func shield_bonus(ch: Character) -> int:
	return 10 + maxi(0, Rules.rank_bonus(Rules.skill_rank(ch, &"schild")) / 2)


## Faktor für erhaltenen Schaden je Rüstungsklasse (nicht gegen Psi)
static func damage_taken(a: ArmorData) -> float:
	return Tables.ARMOR_DMG[a.cls] if a else 1.0
