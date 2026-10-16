class_name Gear
extends RefCounted
## Eigene Waffen und Rüstungen (Editor im Startmenü, docs/Planung_Ausruestungs_Editor.md). Global gespeichert als
## Ressourcen-Dateien in user://gear/weapons/*.tres und user://gear/armor/*.tres; dadurch speichern Character und
## Spielstände sie wie die mitgelieferten über resource_path. Zusatzangaben als Metadaten:
##   template (Pfad der Vorlage), free (Werte ohne Grenzen), enemy (auch für Gegner), factions (Pfade, leer = keine).
## Werte bleiben in Grenzen um die Vorlage (FIELDS), außer bei free.

static var dir := "user://gear"

const WEAPON_DIR := "res://data/weapons"
const ARMOR_DIR := "res://data/armor"
const TABLE_DIR := "res://data/tables"
## Ersatz, wenn getragene eigene Ausrüstung gelöscht wurde (Entscheidung des Nutzers)
const FALLBACK_WEAPON := "res://data/weapons/faeuste.tres"
const FALLBACK_ARMOR := "res://data/armor/keine.tres"
## wählbare Fertigkeiten (Waffen-Fertigkeiten ohne Psi)
const SKILLS := [&"waffenlos", &"einhand", &"zweihand", &"pistolen", &"gewehre", &"schnellfeuer", &"raketenwerfer", &"geschuetze"]

## Einstellbare Zahlenwerte: key, Name, Art der Grenze (pct = ±50 %, abs = ±d), Schritt, Untergrenze, nur Fernkampf
const WEAPON_FIELDS := [
	{"key": "inc_m", "name": "Reichweite je Stufe", "unit": " m", "kind": "pct", "step": 1, "min": 1, "ranged": true},
	{"key": "stages", "name": "Stufen", "kind": "abs", "d": 1, "step": 1, "min": 1, "ranged": true},
	{"key": "min_range_m", "name": "Mindestabstand", "unit": " m", "kind": "pct", "step": 1, "min": 0, "ranged": true},
	{"key": "max_result", "name": "Höchstergebnis", "kind": "abs", "d": 10, "step": 1, "min": 50},
	{"key": "fumble", "name": "Patzer bis", "kind": "abs", "d": 2, "step": 1, "min": 1},
	{"key": "damage", "name": "Schaden", "kind": "abs", "d": 0.2, "step": 0.1, "min": 0.1},
	{"key": "ob_bonus", "name": "Angriffsbonus (fest)", "kind": "abs", "d": 10, "step": 1, "min": -100, "sign": true},
	# Munition: ohne Grenzen (Entscheidung des Nutzers), kein Vermerk „frei“; Regeln core/ammo.gd
	{"key": "magazine", "name": "Magazin (0 = ohne)", "kind": "pct", "step": 1, "min": 0, "unlimited": true, "ranged": true},
	{"key": "ammo_total", "name": "Munition gesamt", "kind": "pct", "step": 1, "min": 0, "unlimited": true, "ranged": true},
	{"key": "shots", "name": "Schuss pro Angriff", "kind": "abs", "d": 0, "step": 1, "min": 1, "unlimited": true, "ranged": true},
	{"key": "splash0", "name": "Druckwelle 1,5 m", "kind": "abs", "d": 10, "step": 1, "min": -100, "sign": true, "splash": 0},
	{"key": "splash1", "name": "Druckwelle 3 m", "kind": "abs", "d": 10, "step": 1, "min": -100, "sign": true, "splash": 1},
]
const ARMOR_FIELDS := [
	{"key": "db", "name": "Verteidigung", "kind": "abs", "d": 5, "step": 1, "min": -100, "sign": true},
	{"key": "move", "name": "Bewegung", "kind": "abs", "d": 1, "step": 1, "min": -10, "sign": true},
]
## Obergrenze bei frei eingetragenen Werten (nur gegen Unsinn wie 1e9)
const FREE_MAX := 1000


# ---------------------------------------------------------------- Liste und Speichern

static func weapons() -> Array[WeaponData]:
	var out: Array[WeaponData] = []
	for r in _load_dir("weapons"):
		if r is WeaponData:
			out.append(r)
	return out


static func armors() -> Array[ArmorData]:
	var out: Array[ArmorData] = []
	for r in _load_dir("armor"):
		if r is ArmorData:
			out.append(r)
	return out


static func _load_dir(sub: String) -> Array:
	var out := []
	var d := dir.path_join(sub)
	if not DirAccess.dir_exists_absolute(d):
		return out
	for f in DirAccess.get_files_at(d):
		if f.ends_with(".tres"):
			var r := ResourceLoader.load(d.path_join(f))
			if r:
				out.append(r)
	out.sort_custom(func(a: Resource, b: Resource) -> bool: return String(a.get("name")) < String(b.get("name")))
	return out


## Eigene Ausrüstung (liegt im Gear-Ordner)?
static func is_custom(r: Resource) -> bool:
	return r != null and r.resource_path.begins_with(dir + "/")


## Werte ohne Grenzen eingetragen (Vermerk „frei“)
static func is_free(r: Resource) -> bool:
	return r != null and bool(r.get_meta(&"free", false))


## Für Gegner dieser Fraktion freigegeben (Pfad der FactionData)
static func for_enemy(r: Resource, faction_path: String) -> bool:
	return bool(r.get_meta(&"enemy", false)) and faction_path in r.get_meta(&"factions", [])


static func enemy_weapons(faction_path: String) -> Array[WeaponData]:
	return weapons().filter(func(w: WeaponData) -> bool: return for_enemy(w, faction_path))


static func enemy_armors(faction_path: String) -> Array[ArmorData]:
	return armors().filter(func(a: ArmorData) -> bool: return for_enemy(a, faction_path))


## Mitgelieferte Vorlagen (Waffen ohne Psi, Rüstungen nach Klasse)
static func base_weapons() -> Array[WeaponData]:
	var out: Array[WeaponData] = []
	for f in ResourceLoader.list_directory(WEAPON_DIR):
		if f.ends_with(".tres"):
			var w: WeaponData = load(WEAPON_DIR.path_join(f))
			if not w.psi:
				out.append(w)
	out.sort_custom(func(a: WeaponData, b: WeaponData) -> bool: return a.name < b.name)
	return out


static func base_armors() -> Array[ArmorData]:
	var out: Array[ArmorData] = []
	for f in ResourceLoader.list_directory(ARMOR_DIR):
		if f.ends_with(".tres"):
			out.append(load(ARMOR_DIR.path_join(f)))
	out.sort_custom(func(a: ArmorData, b: ArmorData) -> bool: return a.cls < b.cls)
	return out


static func tables() -> Array[AttackTableData]:
	var out: Array[AttackTableData] = []
	for f in ResourceLoader.list_directory(TABLE_DIR):
		if f.begins_with("attack_") and f.ends_with(".tres"):
			out.append(load(TABLE_DIR.path_join(f)))
	return out


## Klang, der ohne Auswahl gilt (WeaponData.sound() mit leerem sound_id)
static func auto_sound(w: WeaponData) -> StringName:
	var keep := w.sound_id
	w.sound_id = &""
	var s := w.sound()
	w.sound_id = keep
	return s


## Neuer Entwurf aus einer Vorlage (noch nicht gespeichert); alle Fraktionen vorbelegt, Gegner aus
static func from_template(t: Resource) -> Resource:
	var r: Resource = t.duplicate()
	r.set("id", StringName("eigen_%d" % (Time.get_unix_time_from_system() * 1000 + randi() % 1000)))
	r.set("name", "%s (eigen)" % t.get("name"))
	r.set_meta(&"template", t.resource_path)
	r.set_meta(&"free", false)
	r.set_meta(&"enemy", false)
	r.set_meta(&"factions", Mission.all_factions().map(func(f: FactionData) -> String: return f.resource_path))
	return r


## Vorlage eines eigenen Eintrags
static func template_of(r: Resource) -> Resource:
	var p := String(r.get_meta(&"template", ""))
	return load(p) if p != "" and ResourceLoader.exists(p) else null


## Entwurf speichern. original = der gespeicherte Eintrag (bearbeiten) oder null (neu). Gibt den gespeicherten zurück.
## Beim Bearbeiten werden die Werte in den vorhandenen Eintrag übernommen, damit getragene Ausrüstung sich mitändert.
static func save(draft: Resource, original: Resource = null) -> Resource:
	var target := draft
	if original:
		for p in draft.get_property_list():
			if p.usage & PROPERTY_USAGE_STORAGE and not p.name in ["resource_path", "resource_name", "script", "resource_local_to_scene"]:
				original.set(p.name, draft.get(p.name))
		for m in draft.get_meta_list():
			original.set_meta(m, draft.get_meta(m))
		target = original
	var sub := "weapons" if target is WeaponData else "armor"
	DirAccess.make_dir_recursive_absolute(dir.path_join(sub))
	var path := target.resource_path if original else dir.path_join(sub).path_join(String(target.get("id")) + ".tres")
	if ResourceSaver.save(target, path) != OK:
		return null
	if not original:
		target.take_over_path(path)
	return target


## Eintrag löschen. Wer ihn trägt, bekommt beim nächsten Laden FALLBACK_WEAPON / FALLBACK_ARMOR (Charakter-Modul).
static func delete(r: Resource) -> bool:
	if not is_custom(r):
		return false
	return DirAccess.remove_absolute(r.resource_path) == OK


# ---------------------------------------------------------------- Werte und Grenzen

static func fields(r: Resource) -> Array:
	if r is ArmorData:
		return ARMOR_FIELDS
	var w := r as WeaponData
	return WEAPON_FIELDS.filter(func(f: Dictionary) -> bool:
		if f.get("ranged", false) and w.melee:
			return false
		if f.has("splash"):
			var t := template_of(w)
			return t != null and (t as WeaponData).splash.size() > int(f.splash)
		return true)


static func get_value(r: Resource, f: Dictionary) -> float:
	if f.has("splash"):
		var s: PackedInt32Array = r.get("splash")
		return s[f.splash] if s.size() > int(f.splash) else 0
	return float(r.get(f.key))


static func set_value(r: Resource, f: Dictionary, v: float) -> void:
	if f.has("splash"):
		var s: PackedInt32Array = r.get("splash")
		if s.size() > int(f.splash):
			s[f.splash] = int(v)
			r.set("splash", s)
		return
	if typeof(r.get(f.key)) == TYPE_INT:
		r.set(f.key, int(round(v)))
	else:
		r.set(f.key, snappedf(v, 0.01))


## Grenzen [min, max] eines Werts um die Vorlage (bei free nur die Unter- und eine sehr hohe Obergrenze)
static func limits(r: Resource, f: Dictionary) -> Vector2:
	var lo := float(f.get("min", 0))
	if is_free(r) or f.get("unlimited", false):
		return Vector2(lo, FREE_MAX)
	var t := template_of(r)
	var base := get_value(t, f) if t else get_value(r, f)
	var a := base
	var b := base
	if f.kind == "pct":
		a = round(base * 0.5)
		b = round(base * 1.5)
	else:
		a = base - float(f.d)
		b = base + float(f.d)
	return Vector2(maxf(lo, a), maxf(lo, b))


## Wert in den Grenzen halten
static func clamp_value(r: Resource, f: Dictionary, v: float) -> float:
	var l := limits(r, f)
	return clampf(v, l.x, l.y)


## Alle Werte in die Grenzen bringen (z. B. nach Abschalten von „frei“)
static func clamp_all(r: Resource) -> void:
	for f in fields(r):
		set_value(r, f, clamp_value(r, f, get_value(r, f)))


## Anzeige eines Werts (Schaden mit Komma, Boni mit Vorzeichen)
static func fmt(f: Dictionary, v: float) -> String:
	var s := ""
	if f.key == "damage":
		s = ("%.1f" % v).replace(".", ",")
	elif f.get("sign", false):
		s = Dice.fmt(int(v))
	else:
		s = str(int(v))
	return s + String(f.get("unit", ""))
