class_name Equipment
extends RefCounted
## Ausrüstung ändern (Waffenkammer, docs/Planung_Waffenkammer.md): Waffe 1 (Pflicht), Waffe 2 (darf leer sein),
## Rüstung, Schild. Psi-Waffen sind nicht wählbar (Psi-Angriffe kommen aus den Psi-Listen).
## Keine Waffe doppelt; Schild nur, wenn Waffe 1 und Waffe 2 einhändig sind (Waffe 2 darf leer sein).
## Lager (Schritt 3, docs/Planung_Ausbau_Lager_Handwerk.md; Entscheidungen des Nutzers 16.10.2026): Ausrüsten nimmt
## aus dem Lager des Schiffs (Stock), Ablegen legt zurück; Fäuste und „keine Rüstung“ sind immer da; der Schild ist
## ein Lagergegenstand (SHIELD); Medikits aus dem Lager, höchstens MAX_MEDKITS je Figur. g = HubState.game;
## g == null (Schnellkampf, Tests ohne Spiel) = unbegrenzt.
## Beschädigung (Character.wear) gehört zum Teil im Platz: Beschädigte Stücke liegen einzeln mit Schaden im Lager
## (Schlüssel Stock.damaged_key, docs/module/hub.md); Anlegen übernimmt den Schaden in den Platz, Ablegen legt das
## Stück mit Schaden zurück. Fäuste und „keine Rüstung“ sind nie beschädigt im Lager. damage = 0 (intakt) bis −30,
## +5 = gutes Stück aus dem Handwerk (Stock.BONUS, Schlüssel „…|+5“), angelegt und abgelegt wie beschädigte Stücke.

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


## Lager-Schlüssel eines Stücks mit Schaden
static func stock_key(r: Resource, damage := 0) -> String:
	return Stock.damaged_key(Stock.key_of(r), damage)


## Stück im Lager mit diesem Schaden (immer verfügbare: sehr viele, aber nur intakt)
static func in_stock(g: HubState, r: Resource, damage := 0) -> int:
	if is_free_item(r):
		return 1 << 20 if damage == 0 else 0
	if g == null and damage != 0:
		return 0   # ohne Spiel gibt es nur intakte Stücke
	return Stock.count(g, stock_key(r, damage))


## Zustände, in denen r im Lager liegt (+5 gut, 0 intakt, dann −10, −20, −30)
static func stock_damages(g: HubState, r: Resource) -> Array[int]:
	var out: Array[int] = []
	for d in [Stock.BONUS, 0, -10, -20, -30]:
		if in_stock(g, r, d) > 0:
			out.append(d)
	return out


## anzeigen? (im Lager, immer verfügbar, oder getragen)
static func listed(g: HubState, r: Resource, worn: bool) -> bool:
	return worn or not stock_damages(g, r).is_empty()


static func _put_back(g: HubState, r: Resource, damage := 0) -> void:
	if r and not is_free_item(r):
		Stock.add(g, stock_key(r, damage))


static func _take(g: HubState, r: Resource, damage := 0) -> bool:
	return r == null or is_free_item(r) or Stock.take(g, stock_key(r, damage))


## Abzug eines Platzes setzen (0 = heil, Eintrag fällt weg)
static func _set_wear(ch: Character, slot: String, damage: int) -> void:
	if damage != 0:
		ch.wear[slot] = damage
	else:
		ch.wear.erase(slot)


## Waffe im Platz (0 oder 1) oder null
static func weapon(ch: Character, slot: int) -> WeaponData:
	return ch.weapons[slot] if slot < ch.weapons.size() else null


## Warum die Waffe (mit diesem Schaden) in diesem Platz nicht geht ("" = erlaubt)
static func weapon_block(ch: Character, slot: int, w: WeaponData, g: HubState = null, damage := 0) -> String:
	if w == null:
		return "Waffe 1 ist Pflicht" if slot == 0 else ""
	if w.psi:
		return "Psi-Angriffe kommen aus den Psi-Listen"
	var other := weapon(ch, 1 - slot)
	if other and other.id == w.id:
		return "schon als Waffe %d gewählt" % (2 - slot)
	if not _is_worn(ch, "w%d" % slot, w, damage) and in_stock(g, w, damage) < 1:
		return "nicht im Lager"
	return ""


## trägt die Figur genau dieses Stück (Teil und Schaden) im Platz?
static func _is_worn(ch: Character, slot: String, r: Resource, damage: int) -> bool:
	return gear_at(ch, slot) == r and ch.wear_of(slot) == damage


## Waffe setzen (null in Platz 1 = Waffe 2 leer), damage = Schaden des Stücks aus dem Lager.
## Legt die alte Waffe mit ihrem Schaden ins Lager und den Schild ab, wenn eine zweihändige Waffe dazukommt.
## Gibt "" zurück oder den Grund, warum es nicht geht.
static func set_weapon(ch: Character, slot: int, w: WeaponData, g: HubState = null, damage := 0) -> String:
	var why := weapon_block(ch, slot, w, g, damage)
	if why != "":
		return why
	var key := "w%d" % slot
	if _is_worn(ch, key, w, damage):
		return ""
	var old := weapon(ch, slot)
	_take(g, w, damage)
	_put_back(g, old, ch.wear_of(key))
	_set_wear(ch, key, damage if w else 0)
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


## Rüstung wechseln, damage = Schaden des Stücks aus dem Lager (alte mit ihrem Schaden zurück ins Lager)
static func set_armor(ch: Character, a: ArmorData, g: HubState = null, damage := 0) -> String:
	if _is_worn(ch, "armor", a, damage):
		return ""
	if in_stock(g, a, damage) < 1:
		return "nicht im Lager"
	_take(g, a, damage)
	_put_back(g, ch.armor, ch.wear_of("armor"))
	_set_wear(ch, "armor", damage)
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


## Ausrüstung auf einen früheren Stand {weapons, armor, shield, medkits, wear} zurücksetzen; tauscht mit dem Lager.
## "" = erledigt, sonst Grund (dann bleibt alles, wie es war).
static func restore(ch: Character, snap: Dictionary, g: HubState = null) -> String:
	var now := snapshot(ch)
	_give_back(ch, g)
	var need := {}
	var sw: Dictionary = snap.get("wear", {})
	for i in snap.weapons.size() + 1:
		var r: Resource = snap.armor if i == snap.weapons.size() else snap.weapons[i]
		var k := stock_key(r, int(sw.get("armor" if i == snap.weapons.size() else "w%d" % i, 0)))
		if r and not is_free_item(r):
			need[k] = int(need.get(k, 0)) + 1
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


## Stand der Ausrüstung für restore
static func snapshot(ch: Character) -> Dictionary:
	return {"weapons": ch.weapons.duplicate(), "armor": ch.armor, "shield": ch.shield, "medkits": ch.medkits, "wear": ch.wear.duplicate()}


static func _give_back(ch: Character, g: HubState) -> void:
	for i in ch.weapons.size():
		_put_back(g, ch.weapons[i], ch.wear_of("w%d" % i))
	_put_back(g, ch.armor, ch.wear_of("armor"))
	if ch.shield:
		Stock.add(g, SHIELD)
	Stock.add(g, Stock.MEDKIT, ch.medkits)


static func _equip(ch: Character, st: Dictionary, g: HubState) -> void:
	ch.weapons.assign(st.weapons)
	ch.armor = st.armor
	ch.shield = st.shield
	ch.medkits = int(st.medkits)
	ch.wear = (st.get("wear", {}) as Dictionary).duplicate()
	for i in ch.weapons.size():
		_take(g, ch.weapons[i], ch.wear_of("w%d" % i))
	_take(g, ch.armor, ch.wear_of("armor"))
	if ch.shield:
		Stock.take(g, SHIELD)
	Stock.take(g, Stock.MEDKIT, ch.medkits)


## Beschädigung eines Platzes als Text ("" = heil), z. B. „beschädigt −10“ (Dice.fmt) oder „unbrauchbar“
static func wear_text(ch: Character, slot: String) -> String:
	var v := ch.wear_of(slot)
	if v > 0:
		return Dice.fmt(v)
	if v == 0:
		return ""
	return "unbrauchbar" if v <= Combatant.WEAR_BROKEN else "beschädigt " + Dice.fmt(v)


## Teil eines Platzes ("w0"/"w1"/"armor") oder null
static func gear_at(ch: Character, slot: String) -> Resource:
	match slot:
		"w0": return weapon(ch, 0)
		"w1": return weapon(ch, 1)
		"armor": return ch.armor
	return null


## alle beschädigten Teile als Text, z. B. „Sturmgewehr beschädigt −10, Leichte Rüstung unbrauchbar“ ("" = alles heil)
## fine = true: stattdessen die guten Stücke, z. B. „Sturmgewehr +5“
static func wear_summary(ch: Character, fine := false) -> String:
	var parts: Array[String] = []
	for slot in ["w0", "w1", "armor"]:
		var r := gear_at(ch, slot)
		if r and (ch.wear_of(slot) > 0 if fine else ch.wear_of(slot) < 0):
			parts.append("%s %s" % [r.get("name"), wear_text(ch, slot)])
	return ", ".join(parts)


## Verteidigungsbonus des Schilds für diese Figur (wie im Kampf: +10 + ½ Rangbonus Schild, mindestens +10)
static func shield_bonus(ch: Character) -> int:
	return 10 + maxi(0, Rules.rank_bonus(Rules.skill_rank(ch, &"schild")) / 2)


## Faktor für erhaltenen Schaden je Rüstungsklasse (nicht gegen Psi)
static func damage_taken(a: ArmorData) -> float:
	return Tables.ARMOR_DMG[a.cls] if a else 1.0
