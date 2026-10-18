class_name CustomMaps
extends RefCounted
## Eigene Kampfkarten aus dem Karteneditor (Startmenü „Karteneditor“, docs/Planung_Kampfkarten.md Schritt 2).
## Global gespeichert als JSON in user://maps/<id>.json (wie die eigene Ausrüstung, für alle Spielstände):
##   id, name, type (MapTypes), size_id, square, cols, rows, active (im Spiel verwenden),
##   cells (je Feld "gelände:höhe", zeilenweise), crew / enemy (gezeichnete Startfelder [Spalte, Reihe]).
## Im Spiel: aktive Karten des passenden Kartentyps ersetzen mit CHANCE die Zufallskarte (fest je Missions-Seed).
## Startfelder: Lage „Standard“ nimmt die gezeichneten (wenn genug), sonst wie bei Zufallskarten automatisch je Lage;
## klappt eine Lage nicht, gelten die gezeichneten bzw. die Standard-Startfelder.

static var dir := "user://maps"
## Anteil der Einsätze mit eigener Karte, wenn für den Kartentyp eine aktive Karte da ist
const CHANCE := 0.3
## Höhenstufen im Editor
const MAX_H := 5
## Probekampf aus dem Editor: diese Karte im nächsten Schnellkampf
static var test_map := ""
## nach dem Probekampf zurück in den Editor zu dieser Karte ("" = Startmenü)
static var editor_return := ""
const EDITOR_SCENE := "res://map_editor.tscn"

## Felder dieser Gelände werden zu rechteckigen Objekten zusammengefasst (Darstellung als ein Körper)
const GROUPED := [&"container", &"regal", &"galerie", &"kiste", &"barriere", &"theke", &"schrank", &"server",
	&"auto", &"sofa", &"schreibtisch", &"podest"]
## Standardhöhe je Gelände beim Malen (sonst 0)
const DEFAULT_H := {&"kiste": 1, &"container": 2, &"regal": 3, &"galerie": 2, &"podest": 1}


# ---------------------------------------------------------------- Liste und Speichern

static func list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			var d := load_map(f.get_basename())
			if not d.is_empty():
				out.append(d)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a.name).naturalnocasecmp_to(b.name) < 0)
	return out


static func load_map(id: String) -> Dictionary:
	var path := dir.path_join(id + ".json")
	if id == "" or not FileAccess.file_exists(path):
		return {}
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (v is Dictionary) or not v.has("cells"):
		return {}
	var d: Dictionary = v
	d.id = id
	d.cols = int(d.cols)
	d.rows = int(d.rows)
	if (d.cells as Array).size() != d.cols * d.rows:
		return {}
	return d


## Speichert (neue Karte bekommt eine id); Rückgabe: id oder ""
static func save(d: Dictionary) -> String:
	DirAccess.make_dir_recursive_absolute(dir)
	if String(d.get("id", "")) == "":
		d.id = "karte_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 10000]
	var f := FileAccess.open(dir.path_join(String(d.id) + ".json"), FileAccess.WRITE)
	if f == null:
		return ""
	f.store_string(JSON.stringify(d, "\t"))
	return String(d.id)


static func delete(id: String) -> bool:
	return id != "" and DirAccess.remove_absolute(dir.path_join(id + ".json")) == OK


# ---------------------------------------------------------------- Neue Karten

static func size_dict(size_id: String, square: bool) -> Dictionary:
	var sz: Dictionary = BattleMap.SIZES[1]
	for s in BattleMap.SIZES:
		if s.id == size_id:
			sz = s
	sz = sz.duplicate()
	if square:
		sz.cols = sz.sq
		sz.rows = sz.sq
		sz.square = true
	return sz


static func _empty(name: String, type: StringName, size_id: String, square: bool) -> Dictionary:
	var sz := size_dict(size_id, square)
	return {"id": "", "name": name, "type": String(type), "size_id": sz.id, "square": square,
		"cols": sz.cols, "rows": sz.rows, "active": false, "cells": [], "crew": [], "enemy": []}


## Leere Karte: Boden mit Außenwand (Raumschiff: Innenwand als Hülle), Eingang links
static func blank(name: String, type: StringName, size_id: String, square := false) -> Dictionary:
	var d := _empty(name, type, size_id, square)
	var wall := "innenwand" if type == MapTypes.SHIP else "wand"
	var mid: int = d.rows / 2
	for r in d.rows:
		for c in d.cols:
			var edge: bool = r == 0 or r == d.rows - 1 or c == 0 or c == d.cols - 1
			var door: bool = c == 0 and r >= mid - 2 and r < mid + 2
			d.cells.append(("%s:0" % wall) if edge and not door else "boden:0")
	return d


## Zufallskarte als Vorlage (Generator), Startfelder automatisch
static func from_generator(name: String, type: StringName, size_id: String, square: bool, seed_value: int) -> Dictionary:
	var m := MapGenerator.generate(seed_value, size_id, type, square)
	if m == null:
		return blank(name, type, size_id, square)
	return from_battle_map(m, name)


static func from_battle_map(m: BattleMap, name: String) -> Dictionary:
	var sq: bool = m.size_info.get("square", false)
	var d := _empty(name, m.map_type, String(m.size_info.get("id", "mittel")), sq)
	d.cols = m.cols
	d.rows = m.rows
	for r in m.rows:
		for c in m.cols:
			var t := m.at_offset(c, r)
			d.cells.append("%s:%d" % [t.terrain, t.h])
	return d


## Kopie unter neuem Namen (eigene id, nicht aktiv)
static func copy(d: Dictionary, name: String) -> Dictionary:
	var n: Dictionary = d.duplicate(true)
	n.id = ""
	n.name = name
	n.active = false
	return n


# ---------------------------------------------------------------- Karte bauen und prüfen

static func cell(d: Dictionary, c: int, r: int) -> Array:
	var parts := String(d.cells[r * d.cols + c]).split(":")
	var terrain := StringName(parts[0])
	if not BattleMap.TERRAIN.has(terrain):
		terrain = &"boden"
	return [terrain, clampi(int(parts[1]) if parts.size() > 1 else 0, 0, MAX_H)]


## BattleMap mit Startfeldern für die Lage; null, wenn keine Startfelder möglich sind
static func build(d: Dictionary, lage: StringName = &"standard", seed_value := 0) -> BattleMap:
	var gen := _grid(d, lage, seed_value)
	var m := gen.m
	var painted := _painted(m, d)
	var use_painted := false
	if lage == &"standard" and painted:
		use_painted = true
	elif gen._finish(m.cols, m.rows) != null:
		pass
	elif painted:
		use_painted = true
	elif lage != &"standard":
		gen.lage = &"standard"
		if gen._finish(m.cols, m.rows) == null:
			return null
	else:
		return null
	if use_painted:
		_painted(m, d)
		gen._shuffle(m.enemy_start)
	m.lage = lage
	return m


## Nur das Gelände (ohne Startfelder), z. B. für die 3D-Vorschau im Editor
static func terrain_map(d: Dictionary) -> BattleMap:
	return _grid(d, &"standard", 0).m


static func _grid(d: Dictionary, lage: StringName, seed_value: int) -> MapGenerator:
	var gen := MapGenerator.new()
	gen.rng.seed = seed_value
	gen.check_all = true
	gen.lage = lage
	var cols: int = d.cols
	var rows: int = d.rows
	gen.size = size_dict(String(d.get("size_id", "mittel")), bool(d.get("square", false)))
	gen.m = BattleMap.new(cols, rows)
	for r in rows:
		for c in cols:
			var x := cell(d, c, r)
			gen.m.add_floor(c, r, x[0], x[1])
	_group(gen, cols, rows)
	var m := gen.m
	m.map_seed = seed_value
	m.map_type = StringName(d.get("type", "halle"))
	if not MapTypes.TYPES.has(m.map_type):
		m.map_type = &"halle"
	m.floor_name = MapTypes.info(m.map_type).floor_name
	m.size_info = gen.size.duplicate()
	m.size_info.cols = cols
	m.size_info.rows = rows
	m.custom_name = String(d.get("name", ""))
	return gen


## Objekte: Außenwand je Seite (wie die Generatoren), sonst gleiche Gelände und Höhe als Rechtecke
## (waagerechte Läufe, darunter liegende Läufe mit gleicher Spanne gehören dazu)
static func _group(gen: MapGenerator, cols: int, rows: int) -> void:
	var m := gen.m
	gen._group_walls(cols, rows)
	var prev := {}   # "c0,c1,gelände,höhe" -> obj der Reihe darüber
	for r in rows:
		var cur := {}
		var c := 0
		while c < cols:
			var t := m.at_offset(c, r)
			if not t.terrain in GROUPED:
				c += 1
				continue
			var e := c
			while e + 1 < cols and m.at_offset(e + 1, r).terrain == t.terrain and m.at_offset(e + 1, r).h == t.h:
				e += 1
			var key := "%d,%d,%s,%d" % [c, e, t.terrain, t.h]
			var id: int = prev[key] if prev.has(key) else gen._next_obj()
			cur[key] = id
			var color := Color(MapGenerator.CONTAINER_COLORS[id % MapGenerator.CONTAINER_COLORS.size()])
			for x in range(c, e + 1):
				var xt := m.at_offset(x, r)
				xt.obj = id
				xt.color = color
			c = e + 1
		prev = cur


static func _starts(m: BattleMap, cells: Variant) -> Array[BattleMap.Tile]:
	var out: Array[BattleMap.Tile] = []
	for p in cells if cells is Array else []:
		var t := m.at_offset(int(p[0]), int(p[1]))
		if t and m.walkable(t) and not out.has(t):
			out.append(t)
	return out


## Gezeichnete Startfelder gültig (genug, begehbar, alles erreichbar)? Dann gesetzt.
static func _painted(m: BattleMap, d: Dictionary) -> bool:
	var crew := _starts(m, d.get("crew", []))
	var enemy := _starts(m, d.get("enemy", []))
	enemy = enemy.filter(func(t: BattleMap.Tile) -> bool: return not crew.has(t))
	if crew.size() < Campaign.HARD_SQUAD or enemy.size() < Mission.MAX_ENEMIES:
		return false
	if not unreachable(m, crew[0]).is_empty():
		return false
	m.crew_start = crew
	m.enemy_start = enemy
	return true


## Begehbare Felder, die von start aus nicht erreichbar sind
static func unreachable(m: BattleMap, start: BattleMap.Tile) -> Array[BattleMap.Tile]:
	var out: Array[BattleMap.Tile] = []
	var reach := m.reachable(start.pos, INF)
	for t in m.list:
		if m.walkable(t) and not reach.all.has(t.pos):
			out.append(t)
	return out


## Prüfung für den Editor: Startfelder je Lage, Anzahl gezeichneter Startfelder, nicht erreichbare Felder.
## {ok (im Spiel nutzbar), lagen: {lage: "gezeichnet"|"automatisch"|"Ersatz"}, crew, enemy, unreachable: [[c, r]], errors}
static func check(d: Dictionary) -> Dictionary:
	var res := {"ok": false, "lagen": {}, "errors": [], "unreachable": []}
	var base := terrain_map(d)
	res.crew = _starts(base, d.get("crew", [])).size()
	res.enemy = _starts(base, d.get("enemy", [])).size()
	var painted := _painted(base, d)
	for lage in Mission.LAGEN:
		var gen := _grid(d, lage, 0)
		if lage == &"standard" and painted:
			res.lagen[lage] = "gezeichnet"
		elif gen._finish(base.cols, base.rows) != null:
			res.lagen[lage] = "automatisch"
		elif build(d, lage) != null:
			res.lagen[lage] = "Ersatz"
	res.ok = res.lagen.has(&"standard")
	# Erreichbarkeit: ab dem ersten gezeichneten Crew-Feld, sonst ab dem ersten begehbaren Feld links
	var start: BattleMap.Tile = null
	var crew := _starts(base, d.get("crew", []))
	if not crew.is_empty():
		start = crew[0]
	else:
		for c in base.cols:
			for r in base.rows:
				var t := base.at_offset(c, r)
				if start == null and base.walkable(t) and t.h == 0:
					start = t
	if start == null:
		res.errors.append("keine begehbaren Felder")
		res.ok = false
		return res
	for t in unreachable(base, start):
		res.unreachable.append([t.col, t.row])
	if not res.unreachable.is_empty():
		res.errors.append("%d begehbare Felder nicht erreichbar (rot umrandet)" % res.unreachable.size())
	if not res.ok:
		res.errors.append("keine Startfelder für „Standard“: links (Spalten 1–%d) zu wenig freier Boden oder nicht alles erreichbar; Startfelder von Hand zeichnen (mind. %d Crew, %d Gegner)" % [
			BattleMap.DEPLOY_COLS, Campaign.HARD_SQUAD, Mission.MAX_ENEMIES])
	return res


# ---------------------------------------------------------------- Im Spiel

## Aktive, nutzbare Karten eines Kartentyps
static func pool(type: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for d in list():
		if d.get("active", false) and StringName(d.get("type", "")) == type:
			out.append(d)
	return out


## Karte zur Mission: fest gewählte (Mission.custom_map, Schnellkampf) oder mit CHANCE eine aktive des Kartentyps.
## null = Zufallskarte. Setzt Mission.custom_map/custom_name, Größe und Form wie die Karte.
static func for_mission(seed_value: int, mission: Mission) -> BattleMap:
	var d := load_map(mission.custom_map) if mission.custom_map != "" else {}
	if d.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([seed_value, "eigene Karte"])
		var p := pool(mission.map_type)
		if p.is_empty() or rng.randf() >= CHANCE:
			return null
		d = p[rng.randi_range(0, p.size() - 1)]
	var m := build(d, mission.lage, seed_value)
	if m == null:
		return null
	mission.custom_map = String(d.id)
	mission.custom_name = String(d.name)
	mission.size_id = String(d.get("size_id", mission.size_id))
	mission.square = bool(d.get("square", false))
	return m
