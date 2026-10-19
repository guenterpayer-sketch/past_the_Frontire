class_name Story
extends RefCounted
## Story-Engine ohne Grafik: Szenen mit Wahl, Proben, Bedingungen, Folgen, Kampagnenziele, Logbuch.
## Daten: StoryData (data/story/*.json), Fortschritt: StoryState. Planung: docs/Planung_Story.md.
## Anbindung an den Hub über die Einhängepunkte unten (offers, on_arrive, travel_event, contacts, on_day,
## pending_mission/mission_done, markers). Solange HubState.story fehlt, hält for_game() den Zustand als Stub.

## Ressourcen, die Folgen und Bedingungen ändern bzw. prüfen dürfen (Feldnamen in HubState)
const RESOURCES := ["credits", "material", "provisions", "fuel"]
const RESOURCE_NAMES := {"credits": "Credits", "material": "Schiffsmaterial", "provisions": "Proviant", "fuel": "Treibstoff"}
## Ergebnisstufe → Ersatzstufe, wenn eine Wahl für die Stufe nichts festlegt
const RESULT_FALLBACK := {"herausragend": "erfolg", "teilerfolg": "fehlschlag", "patzer": "fehlschlag"}
## Chance je Reisetag, dass eine Reise-Kette auslöst (wenn eine bereitsteht)
const TRAVEL_CHANCE := 0.15

var state: StoryState
## Spielstand (null in Tests und der Demo; dann gelten res und day)
var game: HubState
## Crew für Proben und Bedingungen; leer = an Bord verfügbare Crew (Voyage.available) bzw. Campaign.crew()
var crew_override: Array[Character] = []
## Ressourcen ohne Spielstand
var res := {"credits": 0, "material": 0, "provisions": 0, "fuel": 0}
## Spieltag ohne Spielstand
var day := 1
## Tests: feste Reise-Auslösung (-1 = würfeln, 0 = nie, 1 = immer)
static var fixed_travel := -1

## Stub bis HubState.story existiert: Zustand je Spielstand (Schlüssel: Slot)
static var _stub_states := {}


static func create(st: StoryState = null, g: HubState = null) -> Story:
	var s := Story.new()
	s.state = st if st != null else StoryState.create()
	s.game = g
	return s


## Story zum laufenden Spiel. Stub: Zustand liegt bis zur Hub-Anbindung im Speicher, nicht im Spielstand.
static func for_game(g: HubState) -> Story:
	var key := g.slot if g != null else 0
	if not _stub_states.has(key):
		_stub_states[key] = StoryState.create()
	return create(_stub_states[key], g)


# ---------------------------------------------------------------- Umgebung

func today() -> int:
	return game.day if game != null else day


func crew() -> Array[Character]:
	if not crew_override.is_empty():
		return crew_override
	if game != null:
		return Voyage.available(game)
	return Campaign.crew()


func resource(key: String) -> int:
	if game != null:
		return int(game.get(key))
	return int(res.get(key, 0))


func add_resource(key: String, n: int) -> void:
	if game != null:
		# Stub: direkt ins Feld; später über HubState.apply_story (Regeln bleiben im Hub)
		game.set(key, maxi(0, int(game.get(key)) + n))
	else:
		res[key] = maxi(0, int(res.get(key, 0)) + n)


# ---------------------------------------------------------------- Ketten

## Kette beginnen (Startszene, Ziele anlegen). false, wenn sie fehlt oder schon läuft.
func start(chain_id: String) -> bool:
	var c := StoryData.chain(chain_id)
	if c.is_empty() or state.is_open(chain_id):
		return false
	var entry: Dictionary = state.chains.get(chain_id, {"place": -1})
	entry.status = "aktiv"
	entry.scene = String(c.start)
	state.chains[chain_id] = entry
	for g in c.get("goals", []):
		state.goals[String(g.id)] = {"name": String(g.get("name", g.id)), "chain": chain_id,
			"value": int(g.get("value", 0)), "target": int(g.get("target", 0)),
			"due": today() + int(g.due_in) if g.has("due_in") else 0, "fail": String(g.get("fail", "")), "done": false}
	state.add_log(today(), "verlauf", chain_id, "Begonnen: %s" % c.get("title", chain_id))
	return true


func current_scene_id(chain_id: String) -> String:
	return String(state.chains.get(chain_id, {}).get("scene", ""))


## Anzeige der aktuellen Szene: {chain, kind, title, text, image, choices: [{index, text, enabled, reason, check}]}
func view(chain_id: String) -> Dictionary:
	var c := StoryData.chain(chain_id)
	var sid := current_scene_id(chain_id)
	var s := StoryData.scene(chain_id, sid)
	if s.is_empty():
		return {}
	var out := {"chain": chain_id, "scene": sid, "kind": String(c.get("kind", "kette")), "chain_title": String(c.get("title", "")),
		"title": String(s.get("title", "")), "text": text_of(s.get("text", "")), "image": String(s.get("image", "")), "choices": []}
	var choices: Array = s.get("choices", [])
	for i in choices.size():
		var ch: Dictionary = choices[i]
		var reason := blocked_reason(ch.get("requires", []))
		if reason != "" and ch.get("hide_locked", false):
			continue
		var info := {"index": i, "text": text_of(ch.get("text", "")), "enabled": reason == "", "reason": reason, "check": {}}
		if ch.has("check"):
			var diff: String = ch.check.get("diff", "mittel")
			info.check = {"skill": StringName(ch.check.skill), "skill_name": Rules.skill_name(StringName(ch.check.skill)),
				"diff": diff, "diff_name": String(Rules.DIFFICULTY[diff].name), "mod": int(ch.check.get("mod", 0))}
		out.choices.append(info)
	return out


## Wer kann würfeln: [{ch, total}] nach Gesamtbonus absteigend (Bester zuerst, der Spieler wählt)
func roller_options(skill: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in crew():
		out.append({"ch": c, "total": Rules.skill_total(c, skill)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.total > b.total)
	return out


## Wahl treffen. roller = wer würfelt (null = Bester). Ergebnis:
## {ok, check: {} oder Probe (Voyage.check + result), text, effects: [Textzeilen], next, ended, mission}
func choose(chain_id: String, index: int, roller: Character = null) -> Dictionary:
	var s := StoryData.scene(chain_id, current_scene_id(chain_id))
	var choices: Array = s.get("choices", [])
	if state.status(chain_id) != "aktiv" or index < 0 or index >= choices.size():
		return {"ok": false}
	var ch: Dictionary = choices[index]
	if blocked_reason(ch.get("requires", [])) != "":
		return {"ok": false}
	var out := {"ok": true, "check": {}, "text": "", "effects": [], "next": String(ch.get("next", "")), "ended": "", "mission": {}}
	var line := "%s: %s" % [text_of(s.get("title", "")), text_of(ch.get("text", ""))]
	_apply(chain_id, ch.get("effects", []), out)
	if ch.has("check"):
		var skill := StringName(ch.check.skill)
		if roller == null:
			var opts := roller_options(skill)
			roller = opts[0].ch if not opts.is_empty() else null
		if roller != null:
			var r := Voyage.check(roller, skill, int(ch.check.get("mod", 0)), String(ch.check.get("diff", "mittel")))
			out.check = r
			line += " (%s, %s: %s)" % [roller.name, Rules.skill_name(skill), r.result_name]
			var branch := _result_branch(ch.get("results", {}), String(r.result))
			if not branch.is_empty():
				out.text = text_of(branch.get("text", ""), roller)
				_apply(chain_id, branch.get("effects", []), out)
				if branch.has("next"):
					out.next = String(branch.next)
	state.add_log(today(), "verlauf", chain_id, line)
	if not out.mission.is_empty():
		state.chains[chain_id].status = "wartet"
	elif out.ended != "":
		state.chains[chain_id].status = out.ended
	elif out.next == "":
		state.chains[chain_id].status = "fertig"
	else:
		state.chains[chain_id].scene = out.next
	return out


func _result_branch(results: Dictionary, id: String) -> Dictionary:
	if results.has(id):
		return results[id]
	return results.get(RESULT_FALLBACK.get(id, ""), {})


# ---------------------------------------------------------------- Bedingungen

## "" = erfüllt, sonst Grund für die Anzeige (z. B. „braucht: Liste Wahrnehmung“)
func blocked_reason(conds: Array) -> String:
	for c in conds:
		var r := _condition(c)
		if r != "":
			return r
	return ""


func _condition(c: Dictionary) -> String:
	if c.has("flag"):
		return "" if state.flags.has(String(c.flag)) else String(c.get("reason", "noch nicht möglich"))
	if c.has("not_flag"):
		return "" if not state.flags.has(String(c.not_flag)) else String(c.get("reason", "nicht mehr möglich"))
	if c.has("var"):
		return "" if String(state.vars.get(String(c["var"]), "")) == String(c.get("is", "")) else String(c.get("reason", "nicht möglich"))
	if c.has("skill"):
		var need := int(c.get("rank", 1))
		for m in crew():
			if Rules.skill_rank(m, StringName(c.skill)) >= need:
				return ""
		return "braucht: %s Rang %d" % [Rules.skill_name(StringName(c.skill)), need]
	if c.has("psi"):
		for m in crew():
			if Rules.skill_rank(m, StringName(c.psi)) > 0:
				return ""
		return "braucht: %s" % Rules.skill_name(StringName(c.psi))
	for k in RESOURCES:
		if c.has(k):
			return "" if resource(k) >= int(c[k]) else "braucht: %d %s" % [int(c[k]), RESOURCE_NAMES[k]]
	return ""


# ---------------------------------------------------------------- Folgen

func _apply(chain_id: String, effects: Array, out: Dictionary) -> void:
	for e in effects:
		if e.has("flag"):
			state.flags[String(e.flag)] = true
		elif e.has("unflag"):
			state.flags.erase(String(e.unflag))
		elif e.has("var"):
			state.vars[String(e["var"])] = String(e.get("value", ""))
		elif e.has("hint"):
			state.add_log(today(), "hinweis", chain_id, text_of(e.hint))
			out.effects.append("Logbuch: neuer Hinweis")
		elif e.has("log"):
			state.add_log(today(), "verlauf", chain_id, text_of(e.log))
		elif e.has("goal"):
			_goal_effect(e, out)
		elif e.has("goal_new"):
			var g: Dictionary = e.goal_new
			state.goals[String(g.id)] = {"name": String(g.get("name", g.id)), "chain": chain_id, "value": int(g.get("value", 0)),
				"target": int(g.get("target", 0)), "due": today() + int(g.due_in) if g.has("due_in") else 0,
				"fail": String(g.get("fail", "")), "done": false}
		elif e.has("mission"):
			state.mission = e.mission.duplicate(true)
			state.mission.chain = chain_id
			out.mission = state.mission
		elif e.has("end"):
			out.ended = String(e.end)
		elif e.has("chain"):
			start(String(e.chain))
		elif e.has("reveal"):
			reveal(String(e.reveal))
		else:
			for k in RESOURCES:
				if e.has(k):
					add_resource(k, int(e[k]))
					out.effects.append("%+d %s" % [int(e[k]), RESOURCE_NAMES[k]])


## Ziel ändern: add (Fortschritt), target (Ziel erhöhen, z. B. Strafzins), due (Frist verschieben), done
func _goal_effect(e: Dictionary, out: Dictionary) -> void:
	var g: Dictionary = state.goals.get(String(e.goal), {})
	if g.is_empty():
		return
	if e.has("add"):
		g.value = int(g.value) + int(e.add)
	if e.has("target"):
		g.target = int(g.target) + int(e.target)
		out.effects.append("%s: Ziel %+d" % [g.name, int(e.target)])
	if e.has("due"):
		g.due = maxi(int(g.due), today()) + int(e.due)
		out.effects.append("%s: Frist bis Tag %d" % [g.name, g.due])
	if e.get("done", false) or (int(g.target) > 0 and int(g.value) >= int(g.target)):
		g.done = true
		g.due = 0


## Kette bekannt machen (Logbuch, bei Auslöser „ort“ ein Story-Ort auf der Karte)
func reveal(chain_id: String) -> void:
	var c := StoryData.chain(chain_id)
	if c.is_empty():
		return
	var entry: Dictionary = state.chains.get(chain_id, {"status": "bekannt", "scene": "", "place": -1})
	if c.get("trigger", {}).get("type", "") == "ort" and int(entry.place) < 0:
		entry.place = _pick_place()
	state.chains[chain_id] = entry


## Stub: zufälliges System außer dem aktuellen; später Orte im System (Sektorumbau im Hub)
func _pick_place() -> int:
	if game == null or game.sector == null:
		return -1
	var n := game.sector.systems.size()
	var i := randi_range(0, n - 1)
	if i == game.position and n > 1:
		i = (i + 1) % n
	return i


# ---------------------------------------------------------------- Texte

## Text aus Zeichenkette, Baustein-Auswahl {var, schlüssel: Text, "*": sonst} oder Liste davon; {gruppe}/{gruppe.feld} ersetzen
func text_of(t: Variant, roller: Character = null) -> String:
	var s := ""
	if t is Array:
		var parts := PackedStringArray()
		for p in t:
			parts.append(text_of(p, roller))
		return " ".join(parts).replace("\n ", "\n")
	if t is Dictionary:
		var key := String(state.vars.get(String(t.get("var", "")), ""))
		s = String(t.get(key, t.get("*", "")))
	else:
		s = String(t)
	var b := StoryData.bausteine()
	for group in state.vars:
		var item: Dictionary = b.get(group, {}).get(state.vars[group], {})
		for field in item:
			s = s.replace("{%s.%s}" % [group, field], String(item[field]))
		s = s.replace("{%s}" % group, String(item.get("name", state.vars[group])))
	if roller != null:
		s = s.replace("{wuerfler}", roller.name)
	return s


# ---------------------------------------------------------------- Einhängepunkte für den Hub

func _ready_chains(trigger: String) -> Array[String]:
	var out: Array[String] = []
	var ids: Array = StoryData.chains().keys()
	ids.sort()
	for id in ids:
		var c: Dictionary = StoryData.chain(id)
		if c.get("test", false) or c.get("trigger", {}).get("type", "") != trigger:
			continue
		if state.status(id) in ["aktiv", "wartet", "fertig", "gescheitert"]:
			continue
		if blocked_reason(c.trigger.get("requires", [])) == "":
			out.append(id)
	return out


## Story-Aufträge für die Auftragsliste (ohne Zeitlimit): [{chain, title, kind}]
func offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _ready_chains("auftrag"):
		var c := StoryData.chain(id)
		out.append({"chain": id, "title": text_of(c.get("title", id)), "kind": String(c.get("kind", "kette"))})
	return out


## Ankunft in einem System: Kette mit Story-Ort dort beginnen. Gibt die Kette zurück oder "".
func on_arrive(system: int) -> String:
	for id in state.chains:
		var e: Dictionary = state.chains[id]
		if e.get("status", "") == "bekannt" and int(e.get("place", -1)) == system:
			start(id)
			return id
	return ""


## Ein Reisetag: vielleicht löst eine Reise-Kette aus. Gibt die Kette zurück oder "".
func travel_event(rng: RandomNumberGenerator = null) -> String:
	var ready := _ready_chains("reise")
	if ready.is_empty():
		return ""
	var roll := randf() if rng == null else rng.randf()
	if fixed_travel == 0 or (fixed_travel < 0 and roll >= TRAVEL_CHANCE):
		return ""
	var id: String = ready[randi_range(0, ready.size() - 1) if rng == null else rng.randi_range(0, ready.size() - 1)]
	start(id)
	return id


## Kontakte im Raumhafen: [{chain, title}]; Ansprechen = start(chain)
func contacts() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _ready_chains("kontakt"):
		var c := StoryData.chain(id)
		out.append({"chain": id, "title": text_of(c.get("contact", c.get("title", id)))})
	return out


## Tageswechsel: abgelaufene Fristen lösen den Rückschlag aus (Szene „fail“ der Kette). Gibt die betroffenen Ketten zurück.
func on_day() -> Array[String]:
	var out: Array[String] = []
	for gid in state.goals:
		var g: Dictionary = state.goals[gid]
		if g.done or int(g.due) <= 0 or today() <= int(g.due):
			continue
		g.due = 0
		state.add_log(today(), "verlauf", g.chain, "Frist verpasst: %s" % g.name)
		if g.fail != "" and state.status(g.chain) != "wartet":
			state.chains[g.chain] = {"status": "aktiv", "scene": g.fail, "place": int(state.chains.get(g.chain, {}).get("place", -1))}
			out.append(String(g.chain))
	return out


## laufender Story-Einsatz für Hub/Bodenkampf/Raumkampf: {chain, kind, title, difficulty, …} oder leer
func pending_mission() -> Dictionary:
	return state.mission


## Einsatz beendet: outcome sieg, niederlage oder rueckzug → Folgeszene. Gibt die Kette zurück oder "".
func mission_done(outcome: String) -> String:
	if state.mission.is_empty():
		return ""
	var id := String(state.mission.chain)
	var nxt := String(state.mission.get(outcome, ""))
	state.add_log(today(), "verlauf", id, "Einsatz „%s“: %s" % [state.mission.get("title", ""), outcome])
	state.mission = {}
	if nxt == "":
		state.chains[id].status = "fertig"
		return id
	state.chains[id].status = "aktiv"
	state.chains[id].scene = nxt
	return id


## Story-Orte für die Sternenkarte: [{system, chain, title}]
func markers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in state.chains:
		var e: Dictionary = state.chains[id]
		if e.get("status", "") == "bekannt" and int(e.get("place", -1)) >= 0:
			out.append({"system": int(e.place), "chain": id, "title": text_of(StoryData.chain(id).get("title", id))})
	return out


## offene Ketten fürs Logbuch: [{chain, title, kind, status, place}]
func open_chains() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in state.chains:
		var e: Dictionary = state.chains[id]
		if e.get("status", "") in ["aktiv", "wartet", "bekannt"]:
			var c := StoryData.chain(id)
			out.append({"chain": id, "title": text_of(c.get("title", id)), "kind": String(c.get("kind", "kette")),
				"status": String(e.status), "place": int(e.get("place", -1))})
	return out
