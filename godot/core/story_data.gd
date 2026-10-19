class_name StoryData
extends RefCounted
## Story-Daten aus JSON-Dateien in data/story/ (Entscheidung 19.10.2026: JSON statt .tres).
## Jede Datei außer bausteine.json ist eine Kette oder enthält mehrere unter "chains" (z. B. die Rückschläge).
## Vorlagen für den Generator (StoryGen) liegen in data/story/vorlagen/.
## Aufbau einer Kette, Bedingungen und Folgen: docs/Planung_Story.md, Abschnitt „Datenformat“.

const DIR := "res://data/story"
const BAUSTEINE := "bausteine.json"
const KINDS := ["haupt", "kette"]
const TRIGGERS := ["start", "auftrag", "ort", "reise", "kontakt", "keiner"]
const CONDITIONS := ["flag", "not_flag", "skill", "psi", "credits", "material", "provisions", "fuel", "var", "day",
	"item", "ship_level", "crew_ranks", "sectors", "goal_open"]
const EFFECTS := ["flag", "unflag", "credits", "material", "provisions", "fuel", "hint", "log", "goal", "goal_new",
	"mission", "end", "chain", "reveal", "var", "item", "item_random", "credits_pct", "step_done", "step_failed", "step",
	"spur", "capture", "recruit"]
const RESULTS := ["herausragend", "erfolg", "teilerfolg", "fehlschlag", "patzer"]
const MISSION_OUTCOMES := ["sieg", "niederlage", "rueckzug"]

## Ordner (Tests können umstellen)
static var dir := DIR
static var _chains := {}
static var _bausteine := {}
static var _templates := {}
static var _loaded := false


static func reload() -> void:
	_chains = {}
	_bausteine = {}
	_templates = {}
	_loaded = true
	for f in _json_files(dir):
		var data: Dictionary = f.data
		if f.name == BAUSTEINE:
			_bausteine = data
		elif data.has("chains"):
			for c in data.chains:
				_chains[String(c.id)] = c
		elif data.has("id"):
			_chains[String(data.id)] = data
	for f in _json_files(dir.path_join("vorlagen")):
		if f.data.has("id"):
			_templates[String(f.data.id)] = f.data


## alle JSON-Objekte eines Ordners: [{name, data}]
static func _json_files(path: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var d := DirAccess.open(path)
	if d == null:
		return out
	var files := d.get_files()
	files.sort()
	for f in files:
		if not f.ends_with(".json"):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path.path_join(f)))
		if not data is Dictionary:
			push_warning("Story: %s ist kein gültiges JSON-Objekt" % f)
			continue
		out.append({"name": f, "data": data})
	return out


static func _ensure() -> void:
	if not _loaded:
		reload()


static func chains() -> Dictionary:
	_ensure()
	return _chains


static func chain(id: String) -> Dictionary:
	_ensure()
	return _chains.get(id, {})


static func scene(chain_id: String, scene_id: String) -> Dictionary:
	return chain(chain_id).get("scenes", {}).get(scene_id, {})


## Vorlagen des Generators: {id: Vorlage}
static func templates() -> Dictionary:
	_ensure()
	return _templates


## Bausteine je Gruppe ohne Infotexte: {gruppe: {schlüssel: {name, …}}}
static func bausteine() -> Dictionary:
	_ensure()
	var out := {}
	for k in _bausteine:
		if not String(k).begins_with("_"):
			out[k] = _bausteine[k]
	return out


## Fehler einer Kette (leer = in Ordnung): Szenen, Sprünge, Fertigkeiten, Bedingungen, Folgen
static func validate(c: Dictionary) -> PackedStringArray:
	var err := PackedStringArray()
	var id := String(c.get("id", "?"))
	if not c.get("kind", "") in KINDS:
		err.append("%s: kind muss haupt oder kette sein" % id)
	if not c.get("trigger", {}).get("type", "") in TRIGGERS:
		err.append("%s: unbekannter Auslöser" % id)
	var scenes: Dictionary = c.get("scenes", {})
	if not scenes.has(c.get("start", "")):
		err.append("%s: Startszene fehlt" % id)
	var goal_ids := []
	for g in c.get("goals", []):
		goal_ids.append(g.get("id", ""))
		if g.has("fail") and not scenes.has(g.fail):
			err.append("%s: Ziel %s verweist auf fehlende Szene %s" % [id, g.get("id", ""), g.fail])
	for sid in scenes:
		var s: Dictionary = scenes[sid]
		var where := "%s/%s" % [id, sid]
		for i in s.get("choices", []).size():
			var ch: Dictionary = s.choices[i]
			var w := "%s Wahl %d" % [where, i + 1]
			_check_jump(err, w, scenes, ch.get("next", ""))
			for cond in ch.get("requires", []):
				_check_condition(err, w, cond)
			_check_effects(err, w, ch.get("effects", []), scenes)
			if ch.has("check"):
				if Rules.skill(StringName(ch.check.get("skill", ""))).is_empty():
					err.append("%s: unbekannte Fertigkeit %s" % [w, ch.check.get("skill", "")])
				if not Rules.DIFFICULTY.has(ch.check.get("diff", "mittel")):
					err.append("%s: unbekannte Schwierigkeit" % w)
			for r in ch.get("results", {}):
				if not r in RESULTS:
					err.append("%s: unbekanntes Ergebnis %s" % [w, r])
				_check_jump(err, w, scenes, ch.results[r].get("next", ""))
				_check_effects(err, w, ch.results[r].get("effects", []), scenes)
	return err


static func _check_jump(err: PackedStringArray, w: String, scenes: Dictionary, nxt: String) -> void:
	if nxt != "" and not scenes.has(nxt):
		err.append("%s: Sprung zu fehlender Szene %s" % [w, nxt])


static func _check_condition(err: PackedStringArray, w: String, cond: Dictionary) -> void:
	var k := _key(cond, CONDITIONS)
	if k == "":
		err.append("%s: unbekannte Bedingung %s" % [w, cond])
	elif k == "skill" and Rules.skill(StringName(cond.skill)).is_empty():
		err.append("%s: unbekannte Fertigkeit %s" % [w, cond.skill])
	elif k == "psi" and not PsiLists.is_list(StringName(cond.psi)):
		err.append("%s: unbekannte Psi-Liste %s" % [w, cond.psi])


static func _check_effects(err: PackedStringArray, w: String, effects: Array, scenes: Dictionary) -> void:
	for e in effects:
		var k := _key(e, EFFECTS)
		if k == "":
			err.append("%s: unbekannte Folge %s" % [w, e])
		elif k == "mission":
			for o in MISSION_OUTCOMES:
				_check_jump(err, w + " Einsatz", scenes, e.mission.get(o, ""))


## erster bekannter Schlüssel eines Eintrags (Bedingung oder Folge), sonst ""
static func _key(entry: Dictionary, known: Array) -> String:
	for k in entry:
		if k in known:
			return k
	return ""
