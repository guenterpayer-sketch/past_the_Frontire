class_name StoryState
extends RefCounted
## Story-Fortschritt eines Spielstands (Entscheidung 19.10.2026: nur im Spielstand-Slot).
## Wird als Dictionary gespeichert; der Hub legt es später als HubState.story ab.

## ausgewürfelte Bausteine beim Spielstart: {gruppe: schlüssel}
var vars := {}
## gesetzte Story-Flags: {name: true}
var flags := {}
## Ketten: {id: {status, scene, place}}; status: bekannt, aktiv, wartet (Einsatz), fertig, gescheitert
var chains := {}
## Kampagnenziele: {id: {name, chain, value, target, due, fail, done}}
var goals := {}
## Logbuch: [{day, kind (hinweis/verlauf), chain, text}]
var logbook: Array[Dictionary] = []
## laufender Story-Einsatz: {chain, title, kind, difficulty, sieg, niederlage, rueckzug, …} oder leer
var mission := {}
## vom Generator erzeugte Ketten (gleiches Format wie die JSON-Ketten): {id: Kette}
var generated := {}
## Zähler für die Kennungen erzeugter Ketten
var next_gen := 1
## gefangene Crewmitglieder (Character.id als Text), gesperrt bis zur Befreiung
var captured: Array[String] = []
## angeworbene Story-Figuren (z. B. "begabte"); das Charakter-Modul macht daraus eine Figur
var recruits: Array[String] = []


## neuer Spielstand: je Bausteingruppe einen Eintrag auswürfeln
static func create(rng: RandomNumberGenerator = null) -> StoryState:
	var st := StoryState.new()
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var b := StoryData.bausteine()
	for group in b:
		var keys: Array = b[group].keys()
		keys.sort()
		if not keys.is_empty():
			st.vars[group] = keys[rng.randi_range(0, keys.size() - 1)]
	return st


func status(chain_id: String) -> String:
	return String(chains.get(chain_id, {}).get("status", ""))


func is_open(chain_id: String) -> bool:
	return status(chain_id) in ["aktiv", "wartet"]


func add_log(day: int, kind: String, chain_id: String, text: String) -> void:
	logbook.append({"day": day, "kind": kind, "chain": chain_id, "text": text})


func entries(kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in logbook:
		if e.kind == kind:
			out.append(e)
	return out


func to_dict() -> Dictionary:
	return {"vars": vars.duplicate(true), "flags": flags.duplicate(true), "chains": chains.duplicate(true),
		"goals": goals.duplicate(true), "log": logbook.duplicate(true), "mission": mission.duplicate(true),
		"generated": generated.duplicate(true), "next_gen": next_gen, "captured": captured.duplicate(), "recruits": recruits.duplicate()}


static func from_dict(d: Dictionary) -> StoryState:
	var st := StoryState.new()
	st.vars = d.get("vars", {}).duplicate(true)
	st.flags = d.get("flags", {}).duplicate(true)
	st.chains = d.get("chains", {}).duplicate(true)
	st.goals = d.get("goals", {}).duplicate(true)
	for e in d.get("log", []):
		st.logbook.append(e.duplicate())
	st.mission = d.get("mission", {}).duplicate(true)
	st.generated = d.get("generated", {}).duplicate(true)
	st.next_gen = int(d.get("next_gen", 1))
	for c in d.get("captured", []):
		st.captured.append(String(c))
	for r in d.get("recruits", []):
		st.recruits.append(String(r))
	# JSON liefert Zahlen als float
	for id in st.chains:
		st.chains[id].place = int(st.chains[id].get("place", -1))
	for id in st.goals:
		for k in ["value", "target", "due", "rate", "every", "paid"]:
			st.goals[id][k] = int(st.goals[id].get(k, 0))
	for e in st.logbook:
		e.day = int(e.get("day", 0))
	return st
