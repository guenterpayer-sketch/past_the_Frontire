class_name Ammo
## Munition (Entscheidungen des Nutzers 15.10.2026, docs/Planung_Munition.md, docs/module/bodenkampf.md):
## - Munitionsarten mit gemeinsamem Schiffsvorrat (TYPES); Waffen ohne Magazin brauchen keine Munition.
## - Mitnahme je Waffe: MAGS Magazine (Zweitwaffe: MAGS_SECOND), höchstens „Munition gesamt“, solange der Vorrat reicht
##   (Trupp in Reihenfolge); Schnellkampf und Gegner: voll (Vorrat null).
## - Feuerstoß: Schuss pro Angriff ≥ 2 gibt +BURST je abgefeuerter Kugel; reicht das Magazin nicht, mit dem Rest.

const TYPES := {&"energie": "Energiezellen", &"projektil": "Projektil", &"raketen": "Raketen"}
const MAGS := 3
const MAGS_SECOND := 1   # Waffe 2 einer Figur (Entscheidung des Nutzers 15.10.2026: Vorrat bleibt für die Hauptwaffe)
const BURST := 5


## Schuss, die eine Figur mit dieser Waffe in den Einsatz mitnimmt, wenn genug Vorrat da ist;
## slot = Platz in der Waffenliste der Figur (0 = Waffe 1, danach Zweitwaffe)
static func carry(w: WeaponData, slot := 0) -> int:
	if w.magazine <= 0:
		return 0
	var n := w.magazine * (MAGS if slot == 0 else MAGS_SECOND)
	return mini(n, w.ammo_total) if w.ammo_total > 0 else n


## Feuerstoß-Bonus für n abgefeuerte Kugeln (Einzelschuss: 0)
static func burst_bonus(n: int) -> int:
	return n * BURST if n >= 2 else 0


## Kugeln des nächsten Angriffs: Schuss pro Angriff, bei Magazin höchstens das Geladene
static func shots_next(w: WeaponData, loaded: int) -> int:
	var s := maxi(1, w.shots)
	return mini(s, loaded) if w.magazine > 0 else s


## Verteilung des Vorrats auf Waffenlisten (eine Liste je Figur, in Trupp-Reihenfolge).
## stock: {Art: Schuss} oder null (= alles voll). Ergebnis:
## {give: [{Waffen-ID: Schuss}, …] je Figur, short: [[Hinweis, …], …] je Figur, take: {Art: Schuss}}
static func plan(loadouts: Array, stock: Variant) -> Dictionary:
	var left := {}
	if stock is Dictionary:
		for t in TYPES:
			left[t] = int(stock.get(t, stock.get(String(t), 0)))
	var give: Array = []
	var short: Array = []
	var take := {}
	for ws in loadouts:
		var g := {}
		var notes: Array[String] = []
		for slot in ws.size():
			var w: WeaponData = ws[slot]
			var want := carry(w, slot)
			if want <= 0:
				continue
			var n := want
			if stock is Dictionary and w.ammo_type != &"":
				n = mini(want, left.get(w.ammo_type, 0))
				left[w.ammo_type] = left.get(w.ammo_type, 0) - n
			g[w.id] = n
			if w.ammo_type != &"":
				take[w.ammo_type] = take.get(w.ammo_type, 0) + n
			if n <= 0:
				notes.append("%s: keine Munition" % w.name)
			elif n < want:
				notes.append("%s: nur %d von %d Schuss" % [w.name, n, want])
		give.append(g)
		short.append(notes)
	return {"give": give, "short": short, "take": take}


## Munition gemäß Plan in die Figuren legen (Magazin zuerst, Rest als Reserve)
static func apply(units: Array, stock: Variant) -> Dictionary:
	var loadouts: Array = []
	for u: Combatant in units:
		loadouts.append(u.weapons)
	var p := plan(loadouts, stock)
	for i in units.size():
		var u: Combatant = units[i]
		for w in u.weapons:
			if w.magazine <= 0:
				continue
			var n: int = p.give[i].get(w.id, 0)
			u.loaded[w.id] = mini(n, w.magazine)
			u.ammo[w.id] = n - u.loaded[w.id]
			u.ammo_start[w.id] = n
	return p


## Verbrauch je Munitionsart (Schuss) aller übergebenen Figuren
static func used(units: Array) -> Dictionary:
	var res := {}
	for u: Combatant in units:
		for w in u.weapons:
			if w.magazine <= 0 or w.ammo_type == &"":
				continue
			var n: int = u.ammo_start.get(w.id, 0) - u.loaded.get(w.id, 0) - u.ammo.get(w.id, 0)
			if n > 0:
				res[String(w.ammo_type)] = res.get(String(w.ammo_type), 0) + n
	return res
