class_name ShipArms
extends RefCounted
## Schiff für den Raumkampf, Hub-Seite (docs/module/raumkampf.md „Schnittstellen“, Entscheidungen des Nutzers 16.10.2026
## in docs/module/hub.md „Anbindung Raumkampf, Teil 1“): Waffenslots, Schiffswaffen im Lager, Schiffsmunition,
## Systemschäden A–E, Geschützposten, Handel im Hafen, Reparatur (Crew oder Werft) und das setup für SpaceBattle.start().
## Die Werte liegen im HubState (ship_slots, ship_stock, ship_ammo, ship_damage, gun_posts); hier nur die Regeln.
## Waffendaten aus dem Katalog des Raumkampfs (ShipWeapons), Slots und Startwerte aus SpaceSetup (Schnittstelle).

## Slots: die ersten vier ab Start, je Stufe des Ausbaus „Waffenslots“ (0–5) einer mehr (SpaceSetup.slots_for);
## Turm-Slots nur Abwehrwaffen
const SLOTS := ["bug", "backbord", "steuerbord", "turm", "heck", "backbord2", "steuerbord2", "bug2", "turm2"]
const START_SLOT_COUNT := 4
const SLOT_NAMES := SpaceSetup.SLOT_NAMES
const TURRETS := ["turm", "turm2"]

## Feste Posten aus Character.station (Station-ID → Stationsname im Charakter-Modul); Geschützposten je Slot und
## weitere Techniker (technik_2, technik_3; nur Crew, "ki" = frei) im Hub
const STATIONS := {"steuer": "Steuer", "navigation": "Navigation", "schilde": "Schilde", "technik": "Technik", "computer": "Computer"}
const EXTRA_TECH := SpaceSetup.EXTRA_TECH
const GUNNER_STATION := "Geschütze"
## Wer ohne andere Station einen Geschützposten oder eine weitere Technik-Station bekommen darf
const GUN_FREE_STATIONS := ["", "Geschütze", "Jäger"]
const KI := "ki"

## Schiffsmunition: Preis je Stück/Schuss (Kauf nach Verhandeln), Kaufpakete
const AMMO_NAMES := ShipWeapons.AMMO_TYPES
const AMMO_PRICE := {"schiffsraketen": 60, "geschosse": 3}
const AMMO_PACKS := {"schiffsraketen": [1, 3], "geschosse": [10, 40]}

## Systeme und Schadensstufen A–E (E = ausgefallen)
const SYSTEMS := {"antrieb": "Antrieb", "sensoren": "Sensoren", "lebenserhaltung": "Lebenserhaltung", "schilde": "Schilde",
	"reaktor": "Reaktor"}
const STAGES := ["A", "B", "C", "D", "E"]
const BROKEN := 5
## Reiseprobe → System, je Stufe STAGE_MALUS
const TRAVEL_SYSTEM := {&"pilot": "antrieb", &"navigation": "sensoren", &"computer": "reaktor"}
const STAGE_MALUS := -5

## Reparatur: Crew 1 Tag, 1 Material, Probe (Stufen je Ergebnis); Werft je Stufe Credits + Material, Waffen Anteil vom Kaufpreis
const SKILL := &"rsReparatur"
const CREW_MATERIAL := 1
const CREW_STAGES := {&"patzer": 1, &"fehlschlag": 0, &"teilerfolg": 0, &"erfolg": -1, &"herausragend": -2}
const YARD_STAGE_COST := 50
const YARD_STAGE_MATERIAL := 1
const YARD_WEAPON_SHARE := 0.1
## Verkauf beschädigt: je −10 um diesen Anteil weniger (wie Stock)
const SELL_DAMAGE_STEP := 0.25


# ---------------------------------------------------------------- Katalog (ShipWeapons)

static func keys() -> Array[String]:
	return ShipWeapons.keys()


## Name, Preis, Munition, Art einer Schiffswaffe (Schlüssel auch mit Schaden)
static func name(key: String) -> String:
	return ShipWeapons.name(Stock.base_of(key))


static func price(key: String) -> int:
	return ShipWeapons.price(Stock.base_of(key))


static func ammo(key: String) -> String:
	return ShipWeapons.ammo(Stock.base_of(key))


static func kind(key: String) -> String:
	var d := ShipWeapons.data(Stock.base_of(key))
	return String(ShipWeapons.ART_NAMES.get(d.get("art", ""), ""))


## Fertigkeit der Geschützstation für diese Waffe
static func gun_skill(key: String) -> StringName:
	key = Stock.base_of(key)
	return ShipWeapons.skill(key) if ShipWeapons.has(key) else &"ballistikGeschuetze"


## Passt die Waffe in den Slot? Turm-Slots nehmen nur Abwehrwaffen, alle anderen Slots jede andere Waffe.
static func fits(key: String, slot: String) -> bool:
	return ShipWeapons.fits(Stock.base_of(key), slot)


## Anzeigename mit Schaden („Massebeschleuniger (−20)“)
static func label(key: String) -> String:
	return name(key) + Stock.damage_text(Stock.damage_of(key))


static func ammo_name(key: String) -> String:
	var a := ammo(key)
	return String(AMMO_NAMES.get(a, "Energie"))


static func start_slots() -> Dictionary:
	return SpaceSetup.start_slots()


static func start_ammo() -> Dictionary:
	return SpaceSetup.START_AMMO.duplicate()


# ---------------------------------------------------------------- Slots

## Freigeschaltete Slots (Ausbau „Waffenslots“)
static func slot_ids(g: HubState) -> Array[String]:
	var out: Array[String] = []
	out.assign(SpaceSetup.slots_for(ShipUpgrades.level(g, &"slots")))
	return out


static func slot_key(g: HubState, slot: String) -> String:
	return String(g.ship_slots.get(slot, {}).get("key", ""))


static func slot_damage(g: HubState, slot: String) -> int:
	return int(g.ship_slots.get(slot, {}).get("damage", 0))


## Bestückte Slots in fester Reihenfolge
static func armed(g: HubState) -> Array[String]:
	var out: Array[String] = []
	for id in slot_ids(g):
		if slot_key(g, id) != "":
			out.append(id)
	return out


## Lagerschlüssel des Stücks im Slot („raketenwerfer|-10“)
static func slot_stock_key(g: HubState, slot: String) -> String:
	return Stock.damaged_key(slot_key(g, slot), slot_damage(g, slot))


## Schiffswaffen im Lager [{key, name, count, damage}]
static func stock_items(g: HubState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in g.ship_stock:
		if int(g.ship_stock[k]) > 0:
			out.append({"key": String(k), "name": label(k), "count": int(g.ship_stock[k]), "damage": Stock.damage_of(k)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.name < b.name)
	return out


static func stock_count(g: HubState, key: String) -> int:
	return int(g.ship_stock.get(key, 0))


static func stock_add(g: HubState, key: String, n := 1) -> void:
	if key != "" and n > 0:
		g.ship_stock[key] = stock_count(g, key) + n


static func stock_take(g: HubState, key: String) -> bool:
	if stock_count(g, key) <= 0:
		return false
	g.ship_stock[key] = stock_count(g, key) - 1
	if int(g.ship_stock[key]) <= 0:
		g.ship_stock.erase(key)
	return true


## Einbau nur im Hafen, sofort und kostenlos; passende Waffe aus dem Lager, die alte geht mit ihrem Schaden zurück
static func can_install(g: HubState, slot: String, key: String) -> bool:
	return g.is_harbor(g.position) and slot in slot_ids(g) and stock_count(g, key) > 0 and fits(key, slot)


static func install(g: HubState, slot: String, key: String) -> bool:
	if not can_install(g, slot, key):
		return false
	stock_take(g, key)
	if slot_key(g, slot) != "":
		stock_add(g, slot_stock_key(g, slot))
	g.ship_slots[slot] = {"key": Stock.base_of(key), "damage": Stock.damage_of(key)}
	return true


static func can_uninstall(g: HubState, slot: String) -> bool:
	return g.is_harbor(g.position) and slot_key(g, slot) != ""


static func uninstall(g: HubState, slot: String) -> bool:
	if not can_uninstall(g, slot):
		return false
	stock_add(g, slot_stock_key(g, slot))
	g.ship_slots[slot] = {"key": "", "damage": 0}
	g.gun_posts.erase(slot)
	return true


## Passende Waffen im Lager für einen Slot
static func fitting(g: HubState, slot: String) -> Array[Dictionary]:
	return stock_items(g).filter(func(it: Dictionary) -> bool: return fits(it.key, slot))


# ---------------------------------------------------------------- Posten

## Wer an Bord einen Posten übernehmen kann (wie die Reiseposten: nicht gesperrt, nicht Personal der Krankenstation)
static func available(g: HubState) -> Array[Character]:
	return Voyage.available(g)


static func _find(list: Array[Character], id: String) -> Character:
	for c in list:
		if String(c.id) == id:
			return c
	return null


## Figur auf einer festen Station (Character.station) oder null
static func station_holder(g: HubState, station_id: String) -> Character:
	for c in available(g):
		if c.station == STATIONS[station_id]:
			return c
	return null


## Kandidaten für Geschützposten: ohne andere Station (oder mit Station „Geschütze“)
static func gun_candidates(g: HubState) -> Array[Character]:
	var out: Array[Character] = []
	for c in available(g):
		if c.station in GUN_FREE_STATIONS:
			out.append(c)
	return out


## Geschützposten eines Slots bzw. weiterer Techniker (technik_2/3): Figur-ID oder KI (bei Technikern = frei).
## Ohne Eintrag steht, wer Station „Geschütze“ hat, am ersten bestückten Slot.
static func gun_post(g: HubState, slot: String) -> String:
	var cands := gun_candidates(g)
	if g.gun_posts.has(slot):
		var id := String(g.gun_posts[slot])
		return id if id != KI and _find(cands, id) != null else KI
	var ar := armed(g)
	if not ar.is_empty() and ar[0] == slot:
		for c in cands:
			if c.station == GUNNER_STATION and not String(c.id) in g.gun_posts.values():
				return String(c.id)
	return KI


## Geschützposten oder weiteren Techniker setzen; eine Figur hat nur einen dieser Posten (der andere geht an KI/frei)
static func set_gun_post(g: HubState, slot: String, id: String) -> void:
	if id != KI:
		for s in armed(g) + EXTRA_TECH:
			if s != slot and gun_post(g, s) == id:
				g.gun_posts[s] = KI
	g.gun_posts[slot] = id


## Posten für SpaceBattle: {Station-ID: Figur-ID oder "ki"}, Geschützposten als "geschuetz_<Slot>",
## weitere Techniker technik_2/technik_3 ("ki" = frei)
static func posts(g: HubState) -> Dictionary:
	var out := {}
	for st in STATIONS:
		var c := station_holder(g, st)
		out[st] = String(c.id) if c else KI
	for s in armed(g):
		out[SpaceSetup.gun_station(s)] = gun_post(g, s)
	for t in EXTRA_TECH:
		out[t] = gun_post(g, t)
	return out


# ---------------------------------------------------------------- Systemschäden

static func system_name(sys: String) -> String:
	if SYSTEMS.has(sys):
		return SYSTEMS[sys]
	if sys.begins_with("slot_"):
		return "Slot " + String(SLOT_NAMES.get(sys.trim_prefix("slot_"), sys))
	if sys.begins_with("station_geschuetz_"):
		return "Station Geschütz " + String(SLOT_NAMES.get(sys.trim_prefix("station_geschuetz_"), sys))
	if sys.begins_with("station_"):
		return "Station " + String(STATIONS.get(sys.trim_prefix("station_"), sys))
	return sys


## Schadensstufe 0 (heil) … 5 (E, ausgefallen)
static func stage(g: HubState, sys: String) -> int:
	return STAGES.find(String(g.ship_damage.get(sys, ""))) + 1


static func set_stage(g: HubState, sys: String, n: int) -> void:
	n = clampi(n, 0, BROKEN)
	if n == 0:
		g.ship_damage.erase(sys)
	else:
		g.ship_damage[sys] = STAGES[n - 1]


static func stage_text(n: int) -> String:
	return "heil" if n <= 0 else ("E ausgefallen" if n >= BROKEN else "%s (%d/5)" % [STAGES[n - 1], n])


## Beschädigte Systeme in fester Reihenfolge (Grundsysteme zuerst)
static func damaged(g: HubState) -> Array[String]:
	var out: Array[String] = []
	for s in SYSTEMS:
		if stage(g, s) > 0:
			out.append(s)
	var rest: Array = g.ship_damage.keys().filter(func(k) -> bool: return not SYSTEMS.has(String(k)))
	rest.sort()
	for s in rest:
		out.append(String(s))
	return out


## Anzahl offener Schäden (Systeme und beschädigte Schiffswaffen in Slots und Lager), für die Auswahl im Maschinenraum
static func damage_count(g: HubState) -> int:
	var n := damaged(g).size()
	for s in armed(g):
		if slot_damage(g, s) < 0:
			n += 1
	for it in stock_items(g):
		if int(it.damage) < 0:
			n += 1
	return n


## Wirkung außerhalb des Kampfes: −5 je Stufe auf die passende Reiseprobe
static func travel_malus(g: HubState, skill: StringName) -> int:
	return stage(g, TRAVEL_SYSTEM[skill]) * STAGE_MALUS if TRAVEL_SYSTEM.has(skill) else 0


## Antrieb ausgefallen (E): keine Reise
static func engine_down(g: HubState) -> bool:
	return stage(g, "antrieb") >= BROKEN


## Lebenserhaltung ausgefallen (E): Proviant doppelt
static func provision_factor(g: HubState) -> int:
	return 2 if stage(g, "lebenserhaltung") >= BROKEN else 1


## Kurztext der Wirkung im Hub
static func effect_text(sys: String, n: int) -> String:
	if n <= 0:
		return ""
	if sys == "antrieb" and n >= BROKEN:
		return "keine Reise möglich"
	if sys == "lebenserhaltung" and n >= BROKEN:
		return "Proviant doppelt"
	for sk in TRAVEL_SYSTEM:
		if TRAVEL_SYSTEM[sk] == sys:
			return "%s auf %s (Reiseprobe)" % [Dice.fmt(n * STAGE_MALUS), Rules.skill_name(sk)]
	return "nur im Kampf"


# ---------------------------------------------------------------- Reparatur

static func repairer(g: HubState) -> Character:
	return Voyage.repairer(g)


static func can_crew_fix_system(g: HubState, sys: String) -> bool:
	return stage(g, sys) > 0 and g.material >= CREW_MATERIAL and repairer(g) != null


## Wo eine beschädigte Waffe liegt: "slot:<Slot-ID>" oder ein Lagerschlüssel mit Schaden
static func weapon_damage(g: HubState, where: String) -> int:
	if where.begins_with("slot:"):
		return slot_damage(g, where.trim_prefix("slot:"))
	return Stock.damage_of(where) if stock_count(g, where) > 0 else 0


static func can_crew_fix_weapon(g: HubState, where: String) -> bool:
	return weapon_damage(g, where) < 0 and g.material >= CREW_MATERIAL and repairer(g) != null


## Crew-Reparatur eines Systems: 1 Material, Probe; der Tag vergeht im HubState (ship_fix). Leer = nicht möglich.
static func crew_fix_system(g: HubState, sys: String) -> Dictionary:
	if not can_crew_fix_system(g, sys):
		return {}
	var r := _roll(g)
	r.before = stage(g, sys)
	set_stage(g, sys, r.before + int(CREW_STAGES[r.result]))
	r.after = stage(g, sys)
	r.what = system_name(sys)
	return r


## Crew-Reparatur einer Waffe (Slot oder Lager): je Stufe 10 Punkte Schaden, nicht über −30
static func crew_fix_weapon(g: HubState, where: String) -> Dictionary:
	if not can_crew_fix_weapon(g, where):
		return {}
	var r := _roll(g)
	var d0 := weapon_damage(g, where)
	var d1 := clampi(d0 + int(CREW_STAGES[r.result]) * Combatant.WEAR_STEP, Combatant.WEAR_BROKEN, 0)
	_set_weapon_damage(g, where, d1)
	r.before = d0
	r.after = d1
	r.what = label(Stock.damaged_key(_weapon_key(g, where), d1))
	return r


static func _roll(g: HubState) -> Dictionary:
	var r := Voyage.check(repairer(g), SKILL, Galley.malus(g))
	g.material -= CREW_MATERIAL
	return r


static func _weapon_key(g: HubState, where: String) -> String:
	return slot_key(g, where.trim_prefix("slot:")) if where.begins_with("slot:") else Stock.base_of(where)


static func _set_weapon_damage(g: HubState, where: String, dmg: int) -> void:
	if where.begins_with("slot:"):
		g.ship_slots[where.trim_prefix("slot:")].damage = dmg
	else:
		stock_take(g, where)
		stock_add(g, Stock.damaged_key(where, dmg))


## Werft: eine Stufe eines Systems (Credits nach Verhandeln + Material), nur im Hafen
static func yard_stage_cost(g: HubState) -> int:
	return TradeSkills.adj(YARD_STAGE_COST, TradeSkills.ship_factor(g))


static func can_yard_system(g: HubState, sys: String) -> bool:
	return g.is_harbor(g.position) and stage(g, sys) > 0 and g.credits >= yard_stage_cost(g) and g.material >= YARD_STAGE_MATERIAL


static func yard_system(g: HubState, sys: String) -> bool:
	if not can_yard_system(g, sys):
		return false
	g.credits -= yard_stage_cost(g)
	g.material -= YARD_STAGE_MATERIAL
	set_stage(g, sys, stage(g, sys) - 1)
	return true


## Werft: Waffe ganz reparieren, 10 % vom Kaufpreis je −10 (nach Verhandeln)
static func yard_weapon_cost(g: HubState, where: String) -> int:
	var steps := mini(0, weapon_damage(g, where)) / Combatant.WEAR_STEP
	return TradeSkills.adj(price(_weapon_key(g, where)) * YARD_WEAPON_SHARE * steps, TradeSkills.ship_factor(g))


static func can_yard_weapon(g: HubState, where: String) -> bool:
	return g.is_harbor(g.position) and weapon_damage(g, where) < 0 and g.credits >= yard_weapon_cost(g, where)


static func yard_weapon(g: HubState, where: String) -> bool:
	if not can_yard_weapon(g, where):
		return false
	g.credits -= yard_weapon_cost(g, where)
	_set_weapon_damage(g, where, 0)
	return true


# ---------------------------------------------------------------- Handel (nach Verhandeln)

## Schiffswaffen im Sortiment des Hafens: gemischt je Hafen und Zeitraum (Stock.SHOP_DAYS), Anteil nach Gassenwissen
static func shop(g: HubState, system: int) -> Array[String]:
	var all := keys()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s/%d/%d/schiff" % [g.sector.name, system, g.day / Stock.SHOP_DAYS])
	for i in range(all.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t: String = all[i]
		all[i] = all[j]
		all[j] = t
	return all.slice(0, maxi(1, ceili(all.size() * TradeSkills.shop_share(g))))


static func buy_price(g: HubState, key: String) -> int:
	return TradeSkills.adj(price(key), TradeSkills.ship_factor(g))


## Verkauf nach Verhandeln (Anteil wie beim Handeln), beschädigt je −10 um 25 % weniger
static func sell_price(g: HubState, key: String) -> int:
	var f := maxf(0.0, 1.0 - SELL_DAMAGE_STEP * Stock.damage_steps(key))
	return int(floor(price(key) * TradeSkills.ship_sell_factor(g) * f))


static func can_buy(g: HubState, key: String) -> bool:
	return g.is_harbor(g.position) and key in shop(g, g.position) and g.credits >= buy_price(g, key)


static func buy(g: HubState, key: String) -> bool:
	if not can_buy(g, key):
		return false
	g.credits -= buy_price(g, key)
	stock_add(g, key)
	return true


static func can_sell(g: HubState, key: String) -> bool:
	return g.is_harbor(g.position) and stock_count(g, key) > 0


static func sell(g: HubState, key: String) -> bool:
	if not can_sell(g, key):
		return false
	g.credits += sell_price(g, key)
	stock_take(g, key)
	return true


static func ammo_price(g: HubState, type: String) -> int:
	return maxi(1, TradeSkills.adj(int(AMMO_PRICE[type]), TradeSkills.ship_factor(g)))


static func ammo_sell(g: HubState, type: String, n: int) -> int:
	return int(floor(n * int(AMMO_PRICE[type]) * TradeSkills.ship_sell_factor(g)))


static func can_buy_ammo(g: HubState, type: String, n: int) -> bool:
	return g.is_harbor(g.position) and n > 0 and g.credits >= n * ammo_price(g, type)


static func buy_ammo(g: HubState, type: String, n: int) -> bool:
	if not can_buy_ammo(g, type, n):
		return false
	g.credits -= n * ammo_price(g, type)
	g.ship_ammo[type] = int(g.ship_ammo.get(type, 0)) + n
	return true


static func can_sell_ammo(g: HubState, type: String, n: int) -> bool:
	return g.is_harbor(g.position) and n > 0 and int(g.ship_ammo.get(type, 0)) >= n


static func sell_ammo(g: HubState, type: String, n: int) -> bool:
	if not can_sell_ammo(g, type, n):
		return false
	g.ship_ammo[type] = int(g.ship_ammo[type]) - n
	g.credits += ammo_sell(g, type, n)
	return true


# ---------------------------------------------------------------- Raumkampf

## Eingang für SpaceBattle.start() aus dem HubState (Format docs/module/raumkampf.md „Eingang setup“).
## Crew: alle an Bord ohne Sperre (Verwundete ohne Einsatzfreigabe fehlen).
static func setup(g: HubState, enemy: Dictionary, source: String, mission := "", return_scene := HubState.HUB_SCENE) -> Dictionary:
	var crew: Array[Character] = []
	for c in Campaign.crew():
		if not c.is_locked():
			crew.append(c)
	var slots := {}
	for s in slot_ids(g):
		slots[s] = {"key": slot_key(g, s), "damage": slot_damage(g, s)}
	var levels := {}
	for a in ["shields", "armor", "reactor", "slots"]:
		levels[a] = ShipUpgrades.level(g, StringName(a))
	return {"crew": crew, "posts": posts(g),
		"ship": {"hull": g.hull, "hull_max": g.hull_max(), "levels": levels, "slots": slots, "damage": g.ship_damage.duplicate()},
		"ship_ammo": g.ship_ammo.duplicate(), "fuel": g.fuel, "credits": g.credits,
		"enemy": enemy.duplicate(), "source": source, "mission": mission, "return_scene": return_scene}
