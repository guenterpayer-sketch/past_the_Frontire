class_name Stock
extends RefCounted
## Lager des Schiffs und Handel im Raumhafen (docs/Planung_Ausbau_Lager_Handwerk.md, Schritt 2; Entscheidungen des
## Nutzers 16.10.2026). Das Lager zählt Stück je Gegenstand in HubState.stock {Schlüssel: Anzahl}; Schlüssel ist der
## resource_path der WeaponData/ArmorData (auch eigene aus dem Editor), MEDKIT oder Equipment.SHIELD. Was die Crew trägt, gehört nicht
## dazu. Munition bleibt im eigenen Vorrat (HubState.ammo). Ohne Spiel (Schnellkampf) gilt alles als vorhanden.

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


static func key_of(r: Resource) -> String:
	return r.resource_path if r else ""


## Anzeigename eines Schlüssels
static func name_of(key: String) -> String:
	if key == MEDKIT:
		return MEDKIT_NAME
	if key == Equipment.SHIELD:
		return SHIELD_NAME
	var r := load(key) if ResourceLoader.exists(key) else null
	return String(r.get("name")) if r else key.get_file().get_basename()


## Kaufpreis: mitgeliefert aus PRICES; eigene wie ihre Vorlage, mit Vermerk „frei“ doppelt
static func price(key: String) -> int:
	if key == MEDKIT or key == Equipment.SHIELD:
		return PRICES[key]
	var r: Resource = load(key) if ResourceLoader.exists(key) else null
	if r and Gear.is_custom(r):
		var t := Gear.template_of(r)
		var p := price(t.resource_path) if t else DEFAULT_PRICE
		return p * (2 if Gear.is_free(r) else 1)
	return int(PRICES.get(key.get_file().get_basename(), DEFAULT_PRICE))


## Verkaufspreis (ohne Spiel: SELL_FACTOR; im Hafen nach Handeln, TradeSkills)
static func sell_price(key: String, g: HubState = null) -> int:
	return int(floor(price(key) * (TradeSkills.sell_factor(g) if g else SELL_FACTOR)))


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


## Lagerinhalt als sortierte Liste [{key, name, count}]
static func items(g: HubState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in g.stock:
		if int(g.stock[k]) > 0:
			out.append({"key": k, "name": name_of(k), "count": int(g.stock[k])})
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
	return g.is_harbor(g.position) and key in shop(g, g.position) and g.credits >= buy_price(g, key)


static func buy(g: HubState, key: String) -> bool:
	if not can_buy(g, key):
		return false
	g.credits -= buy_price(g, key)
	add(g, key)
	return true


static func can_sell(g: HubState, key: String) -> bool:
	return g.is_harbor(g.position) and count(g, key) > 0


static func sell(g: HubState, key: String) -> bool:
	if not can_sell(g, key):
		return false
	g.credits += sell_price(key, g)
	take(g, key)
	return true
