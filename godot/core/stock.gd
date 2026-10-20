class_name Stock
extends RefCounted
## Lager des Schiffs und Handel im Raumhafen (docs/archiv/Planung_Ausbau_Lager_Handwerk.md, Schritt 2; Entscheidungen des
## Nutzers 16.10.2026). Das Lager zählt Stück je Gegenstand in HubState.stock {Schlüssel: Anzahl}; Schlüssel ist der
## resource_path der WeaponData/ArmorData (auch eigene aus dem Editor), MEDKIT oder Equipment.SHIELD. Was die Crew trägt, gehört nicht
## dazu. Munition bleibt im eigenen Vorrat (HubState.ammo). Ohne Spiel (Schnellkampf) gilt alles als vorhanden.
## Beschädigte Stücke (Entscheidungen 16.10.2026) liegen als eigener Schlüssel „Grundschlüssel|Schaden“, z. B.
## "res://data/weapons/sturmgewehr.tres|-20" (Schaden −10/−20/−30 wie Combatant.wear); gleicher Schaden wird gezählt.
## damaged_key(), base_of(), damage_of() bauen und zerlegen ihn; intakte Stücke behalten den Grundschlüssel.
## Gute Stücke aus dem Handwerk (Herausragend, Entscheidung 16.10.2026) liegen unter „Grundschlüssel|+5“, an der Figur
## Character.wear[platz] = BONUS (positiver Wert = Bonus; der erste Schaden nimmt ihn: +5 → 0 → −10 …).

const MEDKIT := "medkit"
const MEDKIT_NAME := "Medikit"
## Schild (Lagergegenstand des Charakter-Moduls, Schlüssel Equipment.SHIELD)
const SHIELD_NAME := "Schild"
## Kaufpreise der mitgelieferten Gegenstände (Dateiname ohne Endung); Verkauf SELL_FACTOR davon
const PRICES := {
	"vibroklinge": 120, "energiehammer": 250, "laserpistole": 150, "laserkarabiner": 300, "sturmgewehr": 280, "mg": 500,
	"raketenwerfer": 600, "leicht": 150, "mittel": 350, "schwer": 700, MEDKIT: 30, Equipment.SHIELD: 150,
}
const DEFAULT_PRICE := 100
const SELL_FACTOR := 0.5
## Kein Handelsgut
const EXCLUDE := ["res://data/weapons/faeuste.tres", "res://data/armor/keine.tres"]
## Sortiment: je Hafen ein Anteil der Waffen/Rüstungen (Gassenwissen, TradeSkills.SHARE), neu gemischt alle SHOP_DAYS
## Spieltage; Medikits immer. SHOP_SHARE = Anteil ohne Probe zum Vergleich.
const SHOP_SHARE := 0.5
const SHOP_DAYS := 10
## Bonus eines guten Stücks (Waffe auf Angriffe, Rüstung auf die Verteidigung)
const BONUS := 5
## Verkauf eines guten Stücks: Verkaufspreis × SELL_BONUS
const SELL_BONUS := 1.5
## Trenner zwischen Grundschlüssel und Schaden
const DAMAGE_SEP := "|"
## Verkauf beschädigt: je −10 Schaden 25 % weniger
const SELL_DAMAGE_STEP := 0.25
## Werkstatt im Raumhafen: je −10 Schaden 10 % vom Kaufpreis, nach Handeln (TradeSkills.buy_factor), sofort und ganz
const REPAIR_SHARE := 0.1
## Schrottwert nicht mitgenommener Beute: 15 % vom Kaufpreis, ohne Probe; ab −30 (unbrauchbar) nichts
const SCRAP_SHARE := 0.15


static func key_of(r: Resource) -> String:
	return r.resource_path if r else ""


## Schlüssel eines Stücks mit Zustand wie Character.wear: 0 = intakt → Grundschlüssel, negativ = Schaden (höchstens −30),
## positiv = gutes Stück "|+5"
static func damaged_key(key: String, damage: int) -> String:
	key = base_of(key)
	if damage > 0:
		return "%s%s+%d" % [key, DAMAGE_SEP, BONUS]
	return key if damage == 0 else "%s%s%d" % [key, DAMAGE_SEP, maxi(damage, Combatant.WEAR_BROKEN)]


## Gutes Stück (+5)?
static func is_fine(key: String) -> bool:
	return damage_of(key) > 0


## Grundschlüssel ohne Schaden
static func base_of(key: String) -> String:
	return key.get_slice(DAMAGE_SEP, 0)


## Zustand eines Schlüssels wie Character.wear (0 = intakt, −10 … −30 Schaden, +5 gutes Stück)
static func damage_of(key: String) -> int:
	return int(key.get_slice(DAMAGE_SEP, 1)) if DAMAGE_SEP in key else 0


## Schadensstufen (−20 → 2)
static func damage_steps(key: String) -> int:
	return mini(0, damage_of(key)) / Combatant.WEAR_STEP


## Zusatz zum Namen: "" / " (+5)" / " (−20)" / " (−30, unbrauchbar)"
static func damage_text(damage: int) -> String:
	if damage > 0:
		return " (+%d)" % BONUS
	if damage == 0:
		return ""
	var t := ("%d" % damage).replace("-", "−")
	return " (%s, unbrauchbar)" % t if damage <= Combatant.WEAR_BROKEN else " (%s)" % t


## Anzeigename eines Schlüssels (beschädigt mit Schaden)
static func name_of(key: String) -> String:
	if DAMAGE_SEP in key:
		return name_of(base_of(key)) + damage_text(damage_of(key))
	if key == MEDKIT:
		return MEDKIT_NAME
	if key == Equipment.SHIELD:
		return SHIELD_NAME
	var r := load(key) if ResourceLoader.exists(key) else null
	return String(r.get("name")) if r else key.get_file().get_basename()


## Kaufpreis (des intakten Stücks): mitgeliefert aus PRICES; eigene wie ihre Vorlage, mit Vermerk „frei“ doppelt
static func price(key: String) -> int:
	key = base_of(key)
	if key == MEDKIT or key == Equipment.SHIELD:
		return PRICES[key]
	var r: Resource = load(key) if ResourceLoader.exists(key) else null
	if r and Gear.is_custom(r):
		var t := Gear.template_of(r)
		var p := price(t.resource_path) if t else DEFAULT_PRICE
		return p * (2 if Gear.is_free(r) else 1)
	return int(PRICES.get(key.get_file().get_basename(), DEFAULT_PRICE))


## Verkaufspreis (ohne Spiel: SELL_FACTOR; im Hafen nach Handeln, TradeSkills); beschädigt je −10 SELL_DAMAGE_STEP weniger
static func sell_price(key: String, g: HubState = null) -> int:
	var f := SELL_BONUS if is_fine(key) else maxf(0.0, 1.0 - SELL_DAMAGE_STEP * damage_steps(key))
	return int(floor(price(key) * (TradeSkills.sell_factor(g) if g else SELL_FACTOR) * f))


## Werkstatt: Preis für die ganze Reparatur (0 = intakt)
static func repair_cost(g: HubState, key: String) -> int:
	var n := damage_steps(key)
	return 0 if n <= 0 else TradeSkills.adj(price(key) * REPAIR_SHARE * n, TradeSkills.buy_factor(g))


## Schrottwert nicht mitgenommener Beute (ohne Probe)
static func scrap_value(key: String) -> int:
	return 0 if damage_of(key) <= Combatant.WEAR_BROKEN else int(floor(price(key) * SCRAP_SHARE))


## Kaufpreis im Hafen nach Handeln (TradeSkills)
static func buy_price(g: HubState, key: String) -> int:
	return TradeSkills.adj(price(key), TradeSkills.buy_factor(g))


## Alle Handelsgüter (Schlüssel): mitgelieferte Waffen ohne Psi/Fäuste, Rüstungen ohne „Keine“, eigene aus dem Editor,
## Schild
static func goods() -> Array[String]:
	var out: Array[String] = [Equipment.SHIELD]
	for w in Gear.base_weapons() + Gear.weapons():
		if not w.resource_path in EXCLUDE:
			out.append(w.resource_path)
	for a in Gear.base_armors() + Gear.armors():
		if not a.resource_path in EXCLUDE:
			out.append(a.resource_path)
	return out


# ---------------------------------------------------------------- Lager

static func count(g: HubState, key: String) -> int:
	return int(g.stock.get(key, 0)) if g else 1 << 20


static func add(g: HubState, key: String, n := 1) -> void:
	if g == null or key == "" or n <= 0:
		return
	g.stock[key] = count(g, key) + n


## Ein Stück herausnehmen (Ausrüsten); false, wenn keins da ist. Ohne Spiel immer true.
static func take(g: HubState, key: String, n := 1) -> bool:
	if g == null:
		return true
	if count(g, key) < n:
		return false
	g.stock[key] = count(g, key) - n
	if int(g.stock[key]) <= 0:
		g.stock.erase(key)
	return true


## Lagerinhalt als sortierte Liste [{key, name, count, damage}]
static func items(g: HubState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in g.stock:
		if int(g.stock[k]) > 0:
			out.append({"key": k, "name": name_of(k), "count": int(g.stock[k]), "damage": damage_of(k)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.name < b.name)
	return out


# ---------------------------------------------------------------- Raumhafen

## Sortiment des Hafens (Schlüssel), alle SHOP_DAYS Tage neu gemischt; Medikits immer
static func shop(g: HubState, system: int) -> Array[String]:
	var period := g.day / SHOP_DAYS
	if int(g.shop.get("_period", -1)) != period:
		g.shop = {"_period": period}
	var k := str(system)
	if not g.shop.has(k):
		var all := goods()
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%s/%d/%d" % [g.sector.name, system, period])
		for i in range(all.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t: String = all[i]
			all[i] = all[j]
			all[j] = t
		g.shop[k] = all
	# gemischte Liste; davon der Anteil nach Gassenwissen (TradeSkills), mehr ergänzt nur
	var list: Array = g.shop[k].filter(func(s: String) -> bool: return s == Equipment.SHIELD or ResourceLoader.exists(s))
	var n := maxi(1, ceili(goods().size() * TradeSkills.shop_share(g)))
	var out: Array[String] = [MEDKIT]
	for s in list.slice(0, n):
		out.append(s)
	return out


static func can_buy(g: HubState, key: String) -> bool:
	return g.at_market() and key in shop(g, g.position) and g.credits >= buy_price(g, key)


static func buy(g: HubState, key: String) -> bool:
	if not can_buy(g, key):
		return false
	g.credits -= buy_price(g, key)
	add(g, key)
	return true


static func can_sell(g: HubState, key: String) -> bool:
	return g.at_market() and count(g, key) > 0


static func sell(g: HubState, key: String) -> bool:
	if not can_sell(g, key):
		return false
	g.credits += sell_price(key, g)
	take(g, key)
	return true


## Werkstatt im Raumhafen: beschädigtes Stück aus dem Lager, genug Credits
static func can_repair(g: HubState, key: String) -> bool:
	return g.at_market() and damage_of(key) < 0 and count(g, key) > 0 and g.credits >= repair_cost(g, key)


## Ein Stück ganz reparieren: beschädigtes heraus, intaktes hinein
static func repair(g: HubState, key: String) -> bool:
	if not can_repair(g, key):
		return false
	g.credits -= repair_cost(g, key)
	take(g, key)
	add(g, base_of(key))
	return true
