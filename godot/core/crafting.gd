class_name Crafting
extends RefCounted
## Handwerk (docs/Planung_Ausbau_Lager_Handwerk.md, Entscheidungen des Nutzers 16.10.2026, Mockup „Schiff-Hub Mockup“
## Bildschirme 29–31): Bauen, Zerlegen und Reparieren in der Werkstatt (Waffenkammer), Medikits in der Krankenstation.
## Eine Arbeit je Figur (HubState.jobs {Figur-ID: Arbeit}), der Handwerker ist nicht gesperrt. Probe „mittel“ am Ende
## der Arbeit (Voyage.check, EP für die Fertigkeit). Handwerksmaterial HubState.craft_material, 1 Einheit = 10 Cr.
## Material: Bauen/Reparieren aufgerundet und sofort verbraucht, Zerlegen abgerundet am Ende.

## Wert einer Einheit Handwerksmaterial (Kauf/Verkauf im Raumhafen nach Handeln)
const MATERIAL_VALUE := 10
## Bauen: Material im Wert von 50 % des Kaufpreises (in Promille für ganzzahlige Rechnung)
const BUILD_SHARE := 500
## Reparieren: 5 % des Kaufpreises je −10
const REPAIR_SHARE := 50
## Zerlegen: Material nach Ergebnis (Promille des Kaufpreises)
const TAKE_SHARE := {&"patzer": 0, &"fehlschlag": 100, &"teilerfolg": 200, &"erfolg": 300, &"herausragend": 400}
## Bauen: Zustand des Stücks nach Ergebnis (wie Character.wear; null = nichts)
const BUILD_WEAR := {&"fehlschlag": -20, &"teilerfolg": -10, &"erfolg": 0, &"herausragend": 5}
## Bauen: 1 Spieltag je angefangene DAY_PRICE Cr Kaufpreis; Zerlegen und Reparieren 1 Tag
const DAY_PRICE := 200
## Werkstatt-Ausbau (ShipUpgrades &"workshop") je Stufe 0–3: Bonus, Dauerfaktor, Kaufpreisgrenze fürs Bauen (−1 = keine)
const WORKSHOP_BONUS := [0, 10, 10, 20]
const WORKSHOP_SPEED := [1.0, 1.0, 0.5, 0.5]
const WORKSHOP_LIMIT := [200, 400, -1, -1]
## Munition je Auftrag (Schuss) und Lagerschlüssel-Präfix
const AMMO_BATCH := {"energie": 30, "projektil": 30, "raketen": 1}
const AMMO_PREFIX := "ammo:"
const SKILL_WEAPON := &"hwWaffen"
const SKILL_ARMOR := &"hwRuestung"
const SKILL_MEDS := &"medikamente"


# ---------------------------------------------------------------- Stücke

static func ammo_key(t: String) -> String:
	return AMMO_PREFIX + t


static func is_ammo(key: String) -> bool:
	return key.begins_with(AMMO_PREFIX)


## Kaufpreis (Munition: Preis des Auftrags)
static func price(key: String) -> int:
	if is_ammo(key):
		var t := key.trim_prefix(AMMO_PREFIX)
		return int(Voyage.AMMO_PRICE[t]) * int(AMMO_BATCH[t])
	return Stock.price(key)


static func name_of(key: String) -> String:
	if is_ammo(key):
		var t := key.trim_prefix(AMMO_PREFIX)
		return "%s ×%d" % [Ammo.TYPES.get(StringName(t), t), AMMO_BATCH[t]]
	return Stock.name_of(key)


## Fertigkeit: Waffen/Munition → Waffen herstellen, Rüstung → Rüstung herstellen, Medikit → Medikamente
static func skill_of(key: String) -> StringName:
	if key == Stock.MEDKIT:
		return SKILL_MEDS
	if is_ammo(key):
		return SKILL_WEAPON
	var r: Resource = load(Stock.base_of(key)) if ResourceLoader.exists(Stock.base_of(key)) else null
	return SKILL_ARMOR if r is ArmorData else SKILL_WEAPON


## Baubare Stücke der Werkstatt: Waffen, Rüstungen (auch eigene), Munition; ohne Schild
static func buildable() -> Array[String]:
	var out: Array[String] = []
	for k in Stock.goods():
		if k != Equipment.SHIELD:
			out.append(k)
	for t in AMMO_BATCH:
		out.append(ammo_key(t))
	return out


# ---------------------------------------------------------------- Werkstatt

static func level(g: HubState) -> int:
	return ShipUpgrades.level(g, &"workshop")


## Bonus auf die Probe: Werkstatt, für Medikits der Ausbau der Krankenstation
static func bonus(g: HubState, key: String) -> int:
	return g.heal_bonus() if key == Stock.MEDKIT else int(WORKSHOP_BONUS[level(g)])


## Freigeschaltet: Kaufpreis bis zur Grenze der Werkstattstufe (Medikits immer)
static func unlocked(g: HubState, key: String) -> bool:
	var lim: int = WORKSHOP_LIMIT[level(g)]
	return key == Stock.MEDKIT or lim < 0 or price(key) <= lim


## Stufe, ab der das Stück baubar ist
static func unlock_level(key: String) -> int:
	for lv in WORKSHOP_LIMIT.size():
		if WORKSHOP_LIMIT[lv] < 0 or price(key) <= WORKSHOP_LIMIT[lv]:
			return lv
	return WORKSHOP_LIMIT.size() - 1


static func build_material(key: String) -> int:
	return (price(key) * BUILD_SHARE + 9999) / 10000


static func repair_material(key: String) -> int:
	return (Stock.price(key) * REPAIR_SHARE * Stock.damage_steps(key) + 9999) / 10000


static func take_material(key: String, res: StringName) -> int:
	return Stock.price(key) * int(TAKE_SHARE[res]) / 10000


## Bau-Dauer in Tagen (Werkstatt ab Stufe 2 schneller, mindestens 1)
static func build_days(g: HubState, key: String) -> int:
	var d := maxi(1, ceili(price(key) / float(DAY_PRICE)))
	if key != Stock.MEDKIT:
		d = ceili(d * float(WORKSHOP_SPEED[level(g)]))
	return maxi(1, d)


## Probenwert ohne Wurf (Fertigkeit + Schwierigkeit „mittel“ + Bonus) für die Anzeige
static func check_bonus(g: HubState, c: Character, key: String) -> int:
	return Rules.skill_total(c, skill_of(key)) + int(Rules.DIFFICULTY[Voyage.DIFF].mod) + bonus(g, key)


# ---------------------------------------------------------------- Arbeiten

static func job_of(g: HubState, c: Character) -> Dictionary:
	return g.jobs.get(String(c.id), {}) if c else {}


static func is_busy(g: HubState, c: Character) -> bool:
	return not job_of(g, c).is_empty()


static func can_build(g: HubState, c: Character, key: String) -> bool:
	return c != null and not is_busy(g, c) and unlocked(g, key) and g.craft_material >= build_material(key)


static func can_take_apart(g: HubState, c: Character, key: String) -> bool:
	return c != null and not is_busy(g, c) and key != Stock.MEDKIT and key != Equipment.SHIELD and Stock.count(g, key) > 0


static func can_repair(g: HubState, c: Character, key: String) -> bool:
	return c != null and not is_busy(g, c) and Stock.damage_of(key) < 0 and Stock.count(g, key) > 0 \
		and g.craft_material >= repair_material(key)


## Bauen beginnen: Material sofort
static func build(g: HubState, c: Character, key: String) -> bool:
	if not can_build(g, c, key):
		return false
	var m := build_material(key)
	g.craft_material -= m
	_start(g, c, {"kind": "build", "key": key, "days": build_days(g, key), "material": m})
	return true


## Zerlegen beginnen: Stück sofort aus dem Lager
static func take_apart(g: HubState, c: Character, key: String) -> bool:
	if not can_take_apart(g, c, key):
		return false
	Stock.take(g, key)
	_start(g, c, {"kind": "take", "key": key, "days": 1, "material": 0})
	return true


## Reparieren beginnen: Material sofort, Stück bleibt während der Arbeit in der Werkstatt
static func repair(g: HubState, c: Character, key: String) -> bool:
	if not can_repair(g, c, key):
		return false
	var m := repair_material(key)
	g.craft_material -= m
	Stock.take(g, key)
	_start(g, c, {"kind": "repair", "key": key, "days": 1, "material": m})
	return true


static func _start(g: HubState, c: Character, job: Dictionary) -> void:
	job.name = c.name
	g.jobs[String(c.id)] = job


## Kurztext einer laufenden Arbeit
static func job_text(job: Dictionary) -> String:
	var what: String = {"build": "baut", "take": "zerlegt", "repair": "repariert"}.get(String(job.kind), "")
	var d := int(job.days)
	return "%s %s – noch %d %s" % [what, name_of(String(job.key)), d, "Tag" if d == 1 else "Tage"]


## Ein Spieltag: Arbeiten laufen weiter, fertige werden gewürfelt; Meldungen zurück
static func work_day(g: HubState) -> Array[String]:
	var out: Array[String] = []
	for id in g.jobs.keys():
		var job: Dictionary = g.jobs[id]
		job.days = int(job.days) - 1
		if int(job.days) > 0:
			continue
		g.jobs.erase(id)
		var c: Character = null
		for x in Campaign.crew():
			if String(x.id) == String(id):
				c = x
		out.append(_finish(g, c, job))
	return out


static func _finish(g: HubState, c: Character, job: Dictionary) -> String:
	var key := String(job.key)
	if c == null:
		# Handwerker nicht mehr an Bord: Material und Stück zurück
		g.craft_material += int(job.material)
		if String(job.kind) != "build":
			Stock.add(g, key)
		return "%s: %s abgebrochen (nicht mehr an Bord), Material und Stück zurück" % [job.get("name", "?"), name_of(key)]
	var r := Voyage.check(c, skill_of(key), bonus(g, key))
	var res := StringName(r.result)
	var head := "%s %s: %s (%d)" % [c.name, {"build": "baut " + name_of(key), "take": "zerlegt " + name_of(key),
		"repair": "repariert " + name_of(key)}[String(job.kind)], r.result_name, int(r.total)]
	match String(job.kind):
		"build":
			if res == &"patzer":
				return head + " → Material weg"
			if is_ammo(key):
				var t := key.trim_prefix(AMMO_PREFIX)
				g.ammo[t] = int(g.ammo.get(t, 0)) + int(AMMO_BATCH[t])
				return head + " → +%d Schuss" % AMMO_BATCH[t]
			var out_key := key if key == Stock.MEDKIT else Stock.damaged_key(key, int(BUILD_WEAR[res]))
			Stock.add(g, out_key)
			return head + " → %s ins Lager" % Stock.name_of(out_key)
		"take":
			var m := take_material(key, res)
			g.craft_material += m
			return head + " → +%d Material" % m
		_:
			var d := Stock.damage_of(key)
			match res:
				&"patzer":
					d = maxi(d + Combatant.WEAR_STEP, Combatant.WEAR_BROKEN)
				&"teilerfolg":
					d = mini(0, d - Combatant.WEAR_STEP)
				&"erfolg", &"herausragend":
					d = 0
			if res == &"herausragend":
				g.craft_material += int(job.material)
			var back := Stock.damaged_key(key, d)
			Stock.add(g, back)
			return head + " → %s ins Lager%s" % [Stock.name_of(back), " · Material zurück" if res == &"herausragend" else ""]


# ---------------------------------------------------------------- Raumhafen

static func material_price(g: HubState) -> int:
	return maxi(1, TradeSkills.adj(MATERIAL_VALUE, TradeSkills.buy_factor(g)))


static func material_sell(g: HubState) -> int:
	return int(floor(MATERIAL_VALUE * TradeSkills.sell_factor(g)))


static func can_buy_material(g: HubState, n := 1) -> bool:
	return g.is_harbor(g.position) and g.credits >= n * material_price(g)


static func buy_material(g: HubState, n := 1) -> bool:
	if not can_buy_material(g, n):
		return false
	g.credits -= n * material_price(g)
	g.craft_material += n
	return true


static func can_sell_material(g: HubState, n := 1) -> bool:
	return g.is_harbor(g.position) and g.craft_material >= n


static func sell_material(g: HubState, n := 1) -> bool:
	if not can_sell_material(g, n):
		return false
	g.credits += n * material_sell(g)
	g.craft_material -= n
	return true
