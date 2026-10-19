class_name Story
extends RefCounted
## Story-Engine ohne Grafik: Szenen mit Wahl, Proben, Bedingungen, Folgen, Kampagnenziele, Logbuch.
## Daten: StoryData (data/story/*.json), Fortschritt: StoryState. Planung: docs/Planung_Story.md.
## Anbindung an den Hub über die Einhängepunkte unten (offers, on_arrive, travel_event, contacts, on_day,
## pending_mission/mission_done, markers). Im Spiel hält HubState.story_engine() das Story-Objekt, der Zustand liegt in HubState.story.

## Ressourcen, die Folgen und Bedingungen ändern bzw. prüfen dürfen (Feldnamen in HubState)
const RESOURCES := ["credits", "material", "provisions", "fuel"]
const RESOURCE_NAMES := {"credits": "Credits", "material": "Schiffsmaterial", "provisions": "Proviant", "fuel": "Treibstoff"}
## Ergebnisstufe → Ersatzstufe, wenn eine Wahl für die Stufe nichts festlegt
const RESULT_FALLBACK := {"herausragend": "erfolg", "teilerfolg": "fehlschlag", "patzer": "fehlschlag"}
## Chance je Reisetag, dass eine Reise-Kette auslöst (wenn eine bereitsteht)
const TRAVEL_CHANCE := 0.15
## Chance je Reisetag, dass ein erzeugter Story-Schritt mit Einstieg „Reise“ auslöst
const STEP_TRAVEL_CHANCE := 0.45
## Chance je Reisetag für eine erzeugte Ereigniskette (Wrack, Passagier), wenn keine offen ist
const EVENT_CHANCE := 0.08
## Chance je Hafenankunft für einen Schmuggel-Kontakt, wenn keiner offen ist
const SMUGGLE_CHANCE := 0.25
## Ereignisketten des Generators: Reise bzw. Hafen
const TRAVEL_EVENTS := ["wrack", "passagier"]
const HARBOR_EVENTS := ["schmuggel"]

var state: StoryState
## Spielstand (null in Tests und der Demo; dann gelten res und day)
var game: HubState
## Crew für Proben und Bedingungen; leer = an Bord verfügbare Crew (Voyage.available) bzw. Campaign.crew()
var crew_override: Array[Character] = []
## Ressourcen ohne Spielstand
var res := {"credits": 0, "material": 0, "provisions": 0, "fuel": 0}
## Spieltag ohne Spielstand
var day := 1
## eigener Zufall der Story, damit sie die Zufallsfolge anderer Module (Hub, Kampf) nicht verschiebt
var rng := RandomNumberGenerator.new()
## Tests: feste Reise-Auslösung (-1 = würfeln, 0 = nie, 1 = immer)
static var fixed_travel := -1
## false = Ketten mit Auslöser „start“ (Kapitel 1) beginnen nicht von selbst (Selbsttests, die keine Szenen wegklicken)
static var auto_start := true


static func create(st: StoryState = null, g: HubState = null) -> Story:
	var s := Story.new()
	s.rng.randomize()
	s.state = st if st != null else StoryState.create()
	s.game = g
	return s


# ---------------------------------------------------------------- Umgebung

func today() -> int:
	return game.day if game != null else day


## ohne Gefangene (StoryState.captured)
func crew() -> Array[Character]:
	var all: Array[Character] = crew_override if not crew_override.is_empty() else (Voyage.available(game) if game != null else Campaign.crew())
	if state.captured.is_empty():
		return all
	return all.filter(func(c: Character) -> bool: return not String(c.id) in state.captured)


func resource(key: String) -> int:
	if game != null:
		return int(game.get(key))
	return int(res.get(key, 0))


## Ressource ändern; gibt die tatsächliche Änderung zurück. Im Spiel nach den Regeln des Hubs (HubState.apply_story:
## Credits dürfen unter 0, Material und Proviant nicht, Treibstoff 0 bis Tankgröße), ohne Spielstand nicht unter 0.
func add_resource(key: String, n: int) -> int:
	if game != null:
		return int(game.apply_story({key: n}).get(key, 0))
	var v0 := int(res.get(key, 0))
	res[key] = maxi(0, v0 + n)
	return int(res[key]) - v0


## Lager: Stückzahl, hinzufügen, nehmen (im Spiel Stock auf HubState.stock, sonst res.stock)
func item_count(key: String) -> int:
	if game != null:
		return Stock.count(game, key)
	return int(res.get("stock", {}).get(key, 0))


func item_add(key: String, n: int) -> int:
	if n > 0:
		if game != null:
			Stock.add(game, key, n)
		else:
			if not res.has("stock"):
				res.stock = {}
			res.stock[key] = int(res.stock.get(key, 0)) + n
		return n
	var took := 0
	for i in -n:
		if game != null:
			if not Stock.take(game, key):
				break
		elif int(res.get("stock", {}).get(key, 0)) > 0:
			res.stock[key] = int(res.stock[key]) - 1
			if res.stock[key] == 0:
				res.stock.erase(key)
		else:
			break
		took += 1
	return -took


func item_name(key: String) -> String:
	return Stock.name_of(key) if key.contains("/") or key == Stock.MEDKIT else key


## Schlüssel aller Gegenstände im Lager
func item_keys() -> Array:
	if game != null:
		return game.stock.keys()
	return res.get("stock", {}).keys()


## Story-Schlüssel: Summe der Ausbaustufen, Summe der Crew-Ränge, erreichte Sektoren
func ship_level() -> int:
	if game == null:
		return int(res.get("ship_level", 0))
	var n := 0
	for k in game.upgrades:
		n += int(game.upgrades[k])
	return n


func crew_ranks() -> int:
	var n := 0
	for c in crew():
		for k in c.skills:
			n += int(c.skills[k].get("rank", 0))
	return n


## Stub bis zum Sektorumbau des Hubs: ein Sektor
func sectors() -> int:
	return int(res.get("sectors", 1)) if game == null else 1


# ---------------------------------------------------------------- Ketten

## Kette nach Kennung: geschriebene (StoryData) oder erzeugte (StoryState.generated)
func chain_of(id: String) -> Dictionary:
	if state.generated.has(id):
		return state.generated[id]
	return StoryData.chain(id)


func scene_of(id: String, sid: String) -> Dictionary:
	return chain_of(id).get("scenes", {}).get(sid, {})


## Ziel aus der Beschreibung einer Kette: target_rand [a, b] würfelt das Ziel, rate/every = wiederkehrende Rate
func _make_goal(g: Dictionary, chain_id: String) -> void:
	var target := int(g.get("target", 0))
	if g.has("target_rand"):
		target = rng.randi_range(int(g.target_rand[0]), int(g.target_rand[1]))
	var every := int(g.get("every", 0))
	var due := today() + int(g.due_in) if g.has("due_in") else (today() + every if every > 0 else 0)
	state.goals[String(g.id)] = {"name": String(g.get("name", g.id)), "chain": chain_id, "value": int(g.get("value", 0)),
		"target": target, "due": due, "fail": String(g.get("fail", "")), "done": false,
		"rate": int(g.get("rate", 0)), "every": every, "paid": 0, "backlash": g.get("backlash", []).duplicate()}

## Kette beginnen (Startszene, Ziele anlegen). false, wenn sie fehlt oder schon läuft.
func start(chain_id: String) -> bool:
	var c := chain_of(chain_id)
	if c.is_empty() or state.is_open(chain_id):
		return false
	var entry: Dictionary = state.chains.get(chain_id, {"place": -1})
	entry.status = "aktiv"
	entry.scene = String(c.start)
	state.chains[chain_id] = entry
	for g in c.get("goals", []):
		_make_goal(g, chain_id)
	state.add_log(today(), "verlauf", chain_id, "Begonnen: %s" % c.get("title", chain_id))
	return true


func current_scene_id(chain_id: String) -> String:
	return String(state.chains.get(chain_id, {}).get("scene", ""))


## Anzeige der aktuellen Szene: {chain, kind, title, text, image, choices: [{index, text, enabled, reason, check}]}
func view(chain_id: String) -> Dictionary:
	var c := chain_of(chain_id)
	var sid := current_scene_id(chain_id)
	var s := scene_of(chain_id, sid)
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
	var s := scene_of(chain_id, current_scene_id(chain_id))
	var choices: Array = s.get("choices", [])
	if state.status(chain_id) != "aktiv" or index < 0 or index >= choices.size():
		return {"ok": false}
	var ch: Dictionary = choices[index]
	if blocked_reason(ch.get("requires", [])) != "":
		return {"ok": false}
	var out := {"ok": true, "check": {}, "text": "", "effects": [], "next": String(ch.get("next", "")), "ended": "", "mission": {}}
	var line := "%s: %s" % [text_of(s.get("title", "")), text_of(ch.get("text", ""))]
	if ch.has("result"):
		out.text = text_of(ch.result)
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
	_finish_repeat(chain_id)
	return out


## wiederholbare Ketten (repeat, z. B. Rate zahlen) stehen nach dem Ende wieder bereit
func _finish_repeat(chain_id: String) -> void:
	if chain_of(chain_id).get("repeat", false) and state.status(chain_id) in ["fertig", "gescheitert"]:
		state.chains.erase(chain_id)


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
	if c.has("day"):
		return "" if today() >= int(c.day) else "ab Tag %d" % int(c.day)
	if c.has("item"):
		var need_items := int(c.get("count", 1))
		return "" if item_count(String(c.item)) >= need_items else "braucht: %d × %s im Lager" % [need_items, item_name(String(c.item))]
	if c.has("ship_level"):
		return "" if ship_level() >= int(c.ship_level) else "braucht: Schiffsausbau %d (jetzt %d)" % [int(c.ship_level), ship_level()]
	if c.has("crew_ranks"):
		return "" if crew_ranks() >= int(c.crew_ranks) else "braucht: Crew-Ränge %d (jetzt %d)" % [int(c.crew_ranks), crew_ranks()]
	if c.has("sectors"):
		return "" if sectors() >= int(c.sectors) else "braucht: %d Sektoren (jetzt %d)" % [int(c.sectors), sectors()]
	if c.has("goal_open"):
		var g: Dictionary = state.goals.get(String(c.goal_open), {})
		return "" if not g.is_empty() and not g.done else String(c.get("reason", "nicht mehr nötig"))
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
		elif e.has("item"):
			var d := item_add(String(e.item), int(e.get("add", 0)) - int(e.get("take", 0)))
			if d != 0:
				out.effects.append("%+d %s (Lager)" % [d, item_name(String(e.item))])
		elif e.has("item_random"):
			var keys := item_keys()
			if not keys.is_empty():
				var k: String = keys[rng.randi_range(0, keys.size() - 1)]
				if item_add(k, -1) != 0:
					out.effects.append("−1 %s (Lager)" % item_name(k))
		elif e.has("credits_pct"):
			var cr := resource("credits")
			if cr > 0:
				var d := add_resource("credits", roundi(cr * int(e.credits_pct) / 100.0))
				if d != 0:
					out.effects.append("%+d Credits" % d)
		elif e.has("step_done"):
			_step_result(chain_id, true, out)
		elif e.has("step_failed"):
			_step_result(chain_id, false, out)
		elif e.has("step"):
			StoryGen.step(self, String(e.step))
			out.effects.append("Logbuch: neue Spur zu verfolgen")
		elif e.has("spur"):
			_add_spur(String(e.spur), out)
		elif e.has("capture"):
			_capture(out)
		elif e.has("recruit"):
			state.recruits.append(String(e.recruit))
		else:
			for k in RESOURCES:
				if e.has(k):
					var d := add_resource(k, int(e[k]))
					if d != 0:
						out.effects.append("%+d %s" % [d, RESOURCE_NAMES[k]])


## Ziel ändern: add (Fortschritt), target (Ziel erhöhen, z. B. Strafzins), due (Frist verschieben), done
func _goal_effect(e: Dictionary, out: Dictionary) -> void:
	var g: Dictionary = state.goals.get(String(e.goal), {})
	if g.is_empty():
		return
	if e.has("add"):
		g.value = int(g.value) + int(e.add)
	if e.get("pay", false):
		g.paid = int(g.get("paid", 0)) + int(e.get("add", 0))
	if e.has("target"):
		g.target = int(g.target) + int(e.target)
		out.effects.append("%s: Ziel %+d" % [g.name, int(e.target)])
	if e.has("target_pct"):
		var inc := roundi((int(g.target) - int(g.value)) * int(e.target_pct) / 100.0)
		g.target = int(g.target) + inc
		out.effects.append("%s: Schuld %+d" % [g.name, inc])
	if e.has("due"):
		g.due = maxi(int(g.due), today()) + int(e.due)
		out.effects.append("%s: Frist bis Tag %d" % [g.name, g.due])
	if e.get("done", false) or (int(g.target) > 0 and int(g.value) >= int(g.target)):
		g.done = true
		g.due = 0
		_goal_reached(String(e.goal), out)


## Ziel erreicht: Schulden getilgt → Gefangene frei
func _goal_reached(gid: String, out: Dictionary) -> void:
	state.add_log(today(), "verlauf", String(state.goals[gid].chain), "Ziel erreicht: %s" % state.goals[gid].name)
	if gid == "schulden" and not state.captured.is_empty():
		state.captured.clear()
		out.effects.append("Gefangene Crew kommt frei")


# ---------------------------------------------------------------- Rahmen und erzeugte Schritte

## Ergebnis eines erzeugten Schritts: Rahmen (frame) zählt Spuren und erzeugt den nächsten Schritt; Befreiung (rescue)
func _step_result(chain_id: String, ok: bool, out: Dictionary) -> void:
	var c := chain_of(chain_id)
	if c.has("rescue"):
		if ok:
			state.captured.erase(String(c.rescue))
			out.effects.append("%s ist wieder an Bord" % String(c.get("rescue_name", "Crewmitglied")))
		else:
			StoryGen.make(self, "befreien", {"rescue": String(c.rescue), "rescue_name": String(c.get("rescue_name", ""))})
		return
	var frame := String(c.get("frame", ""))
	if frame == "":
		return
	if ok:
		_add_spur(frame, out)
	elif not _frame_full(frame):
		StoryGen.step(self, frame)
		out.effects.append("Logbuch: neue Spur zu verfolgen")


func _frame(frame: String) -> Dictionary:
	return chain_of(frame).get("frame", {})


func _frame_full(frame: String) -> bool:
	var g: Dictionary = state.goals.get(String(_frame(frame).get("goal", "")), {})
	return not g.is_empty() and g.done


## Spur zählen; Ziel voll → Finale bekannt machen, sonst nächsten Schritt erzeugen (höchstens einer offen)
func _add_spur(frame: String, out: Dictionary) -> void:
	var f := _frame(frame)
	var gid := String(f.get("goal", ""))
	if f.is_empty() or not state.goals.has(gid) or state.goals[gid].done:
		return
	_goal_effect({"goal": gid, "add": 1}, out)
	out.effects.append("Spur gefunden (%d / %d)" % [state.goals[gid].value, state.goals[gid].target])
	if state.goals[gid].done:
		state.flags[frame + "_spuren"] = true
		reveal(String(f.get("finale", "")))
		out.effects.append("Logbuch: das Finale ist bekannt")
	elif _open_steps(frame) == 0:
		StoryGen.step(self, frame)
		out.effects.append("Logbuch: neue Spur zu verfolgen")


## offene erzeugte Schritte eines Rahmens (außer dem gerade laufenden Ende)
func _open_steps(frame: String) -> int:
	var n := 0
	for id in state.generated:
		if String(state.generated[id].get("frame", "")) == frame and state.status(id) in ["", "bekannt", "aktiv", "wartet"]:
			var sc := scene_of(id, current_scene_id(id))
			if state.status(id) != "aktiv" or not _is_end_scene(sc):
				n += 1
	return n


func _is_end_scene(sc: Dictionary) -> bool:
	for ch in sc.get("choices", []):
		for e in ch.get("effects", []):
			if e.has("step_done") or e.has("step_failed"):
				return true
	return false


## Rückschlag „Crew gefangen“: ein zufälliges Crewmitglied an Bord, Befreiung als erzeugter Schritt
func _capture(out: Dictionary) -> void:
	var list := crew()
	if list.size() <= 1:
		return
	var c: Character = list[rng.randi_range(0, list.size() - 1)]
	state.captured.append(String(c.id))
	out.effects.append("%s ist gefangen" % c.name)
	StoryGen.make(self, "befreien", {"rescue": String(c.id), "rescue_name": c.name})


## Kette bekannt machen (Logbuch, bei Auslöser „ort“ ein Story-Ort auf der Karte)
func reveal(chain_id: String) -> void:
	var c := chain_of(chain_id)
	if c.is_empty():
		return
	var entry: Dictionary = state.chains.get(chain_id, {"status": "bekannt", "scene": "", "place": -1})
	if c.get("trigger", {}).get("type", "") == "ort" and int(entry.place) < 0:
		entry.place = _pick_place()
	state.chains[chain_id] = entry


## Stub: zufälliger Hafen (neutrales System) für einen Kontakt; ohne Spielstand -1 (überall)
func pick_harbor() -> int:
	if game == null or game.sector == null:
		return -1
	var list: Array[int] = []
	for i in game.sector.systems.size():
		if game.is_harbor(i):
			list.append(i)
	return list[rng.randi_range(0, list.size() - 1)] if not list.is_empty() else -1


## Stub: zufälliges System außer dem aktuellen; später Orte im System (Sektorumbau im Hub)
func pick_place() -> int:
	return _pick_place()


func _pick_place() -> int:
	if game == null or game.sector == null:
		return -1
	var n := game.sector.systems.size()
	var i := rng.randi_range(0, n - 1)
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

## bereite Ketten eines Auslösers (geschriebene und erzeugte, noch nicht begonnen); Kontakte nur im eigenen Hafen
func _ready_chains(trigger: String, system := -2) -> Array[String]:
	var out: Array[String] = []
	var ids: Array = StoryData.chains().keys() + state.generated.keys()
	ids.sort()
	for id in ids:
		var c: Dictionary = chain_of(id)
		if c.get("test", false) or c.get("trigger", {}).get("type", "") != trigger:
			continue
		if not state.status(id) in ["", "bekannt"]:
			continue
		var place := int(state.chains.get(id, {}).get("place", -1))
		if system != -2 and place >= 0 and place != system:
			continue
		if blocked_reason(c.trigger.get("requires", [])) == "":
			out.append(id)
	return out


## Story-Aufträge für die Auftragsliste (ohne Zeitlimit): [{chain, title, kind}]
func offers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _ready_chains("auftrag"):
		var c := chain_of(id)
		out.append({"chain": id, "title": text_of(c.get("title", id)), "kind": String(c.get("kind", "kette"))})
	return out


## Ankunft in einem System: Kette mit Story-Ort dort beginnen. Gibt die Kette zurück oder "".
## Im Hafen: Kopfgeldjäger (Verfolgung) oder vielleicht ein Schmuggel-Kontakt.
func on_arrive(system: int) -> String:
	for id in state.chains:
		var e: Dictionary = state.chains[id]
		if e.get("status", "") == "bekannt" and int(e.get("place", -1)) == system \
				and chain_of(id).get("trigger", {}).get("type", "") == "ort":
			start(id)
			return id
	var harbor := game != null and game.is_harbor(system)
	if harbor and state.flags.has("kopfgeld"):
		state.flags.erase("kopfgeld")
		var hid := StoryGen.make(self, "hinterhalt", {"start": true})
		start(hid)
		return hid
	if harbor and not _event_open(HARBOR_EVENTS) and rng.randf() < SMUGGLE_CHANCE:
		StoryGen.make(self, "schmuggel", {"place": system})
	return ""


## ist eine erzeugte Ereigniskette dieser Vorlagen offen?
func _event_open(kinds: Array) -> bool:
	for id in state.generated:
		if String(state.generated[id].get("template", "")) in kinds and state.status(id) in ["", "bekannt", "aktiv", "wartet"]:
			return true
	return false


## Ein Reisetag: vielleicht löst eine Reise-Kette aus. Gibt die Kette zurück oder "".
## Reihenfolge: erzeugte Story-Schritte mit Einstieg „Reise“, geschriebene Reise-Ketten, erzeugte Ereignisketten.
func travel_event(r: RandomNumberGenerator = null) -> String:
	if r != null:
		rng = r
	if fixed_travel == 0:
		return ""
	var ready := _ready_chains("reise")
	var steps := ready.filter(func(id: String) -> bool: return state.generated.has(id))
	if not steps.is_empty() and (fixed_travel == 1 or rng.randf() < STEP_TRAVEL_CHANCE):
		start(steps[0])
		return steps[0]
	var written := ready.filter(func(id: String) -> bool: return not state.generated.has(id))
	if not written.is_empty() and (fixed_travel == 1 or rng.randf() < TRAVEL_CHANCE):
		var id: String = written[rng.randi_range(0, written.size() - 1)]
		start(id)
		return id
	if not _event_open(TRAVEL_EVENTS) and (fixed_travel == 1 or rng.randf() < EVENT_CHANCE):
		var eid := StoryGen.make(self, TRAVEL_EVENTS[rng.randi_range(0, TRAVEL_EVENTS.size() - 1)], {"start": true})
		if eid != "":
			start(eid)
			return eid
	return ""


## Kontakte im Raumhafen: [{chain, title}]; Ansprechen = start(chain)
func contacts() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _ready_chains("kontakt", game.position if game != null else -2):
		var c := chain_of(id)
		out.append({"chain": id, "title": text_of(c.get("contact", c.get("title", id)))})
	return out


## Tageswechsel: abgelaufene Fristen lösen den Rückschlag aus (Szene „fail“ der Kette). Gibt die betroffenen Ketten zurück.
## Außerdem: Ketten mit Auslöser „start“ beginnen, sobald ihre Bedingung erfüllt ist (z. B. Kapitel 1 ab Tag 3);
## wiederkehrende Raten: zu wenig gezahlt → zufälliger Rückschlag aus „backlash“.
func on_day() -> Array[String]:
	var out: Array[String] = []
	for id in _ready_chains("start") if auto_start else []:
		if start(id):
			out.append(id)
	for gid in state.goals:
		var g: Dictionary = state.goals[gid]
		if g.done or int(g.due) <= 0 or today() <= int(g.due):
			continue
		if int(g.get("rate", 0)) > 0:
			var bid := _rate_due(g)
			if bid != "" and not bid in out:
				out.append(bid)
			continue
		g.due = 0
		state.add_log(today(), "verlauf", g.chain, "Frist verpasst: %s" % g.name)
		if g.fail != "" and state.status(g.chain) != "wartet":
			state.chains[g.chain] = {"status": "aktiv", "scene": g.fail, "place": int(state.chains.get(g.chain, {}).get("place", -1))}
			out.append(String(g.chain))
	return out


## Rate fällig: genug gezahlt → nächste Frist; sonst Rückschlag (Kette aus backlash, zufällig). Gibt die Kette zurück oder "".
func _rate_due(g: Dictionary) -> String:
	var missed := int(g.get("paid", 0)) < int(g.rate)
	while today() > int(g.due):
		g.due = int(g.due) + maxi(1, int(g.every))
	g.paid = 0
	if not missed:
		return ""
	state.add_log(today(), "verlauf", g.chain, "Rate verpasst: %s" % g.name)
	var list: Array = g.get("backlash", [])
	if list.is_empty():
		return ""
	var bid := String(list[rng.randi_range(0, list.size() - 1)])
	if state.is_open(bid):
		return ""
	state.chains.erase(bid)
	return bid if start(bid) else ""


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
		_finish_repeat(id)
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
			out.append({"system": int(e.place), "chain": id, "title": text_of(chain_of(id).get("title", id))})
	return out


## offene Ketten fürs Logbuch: [{chain, title, kind, status, place, trigger, reason (was noch fehlt)}]
func open_chains() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in state.chains:
		var e: Dictionary = state.chains[id]
		if e.get("status", "") in ["aktiv", "wartet", "bekannt"]:
			var c := chain_of(id)
			out.append({"chain": id, "title": text_of(c.get("title", id)), "kind": String(c.get("kind", "kette")),
				"status": String(e.status), "place": int(e.get("place", -1)), "trigger": String(c.get("trigger", {}).get("type", "")),
				"reason": blocked_reason(c.get("trigger", {}).get("requires", [])) if e.status == "bekannt" else ""})
	return out
