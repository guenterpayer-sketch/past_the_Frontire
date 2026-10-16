class_name SpaceBattle
extends RefCounted
## Einstieg und Rückweg des Raumkampfs (Schnittstelle docs/module/raumkampf.md). Der Hub ruft nur start() auf und holt
## nach der Rückkehr das Ergebnis mit take_result(). Die Szene liest setup und meldet das Ende über finish().

const SCENE := "res://space.tscn"

## laufender Kampf (von der Szene gelesen)
static var setup := {}
## Ergebnis des letzten Raumkampfs, bis der Hub es abholt
static var last_result := {}


## Raumkampf starten: Kopien der Charaktere, dann Szenenwechsel
static func start(tree: SceneTree, s: Dictionary) -> void:
	setup = prepare(s)
	last_result = {}
	tree.change_scene_to_file(SCENE)


## setup mit Kopien der Charaktere (der Kampf ändert nie die Crew selbst)
static func prepare(s: Dictionary) -> Dictionary:
	var out := s.duplicate(true)
	var copies: Array = []
	for ch in s.get("crew", []):
		copies.append(ch.duplicate_character())
	out["crew"] = copies
	return out


static func is_quick() -> bool:
	return String(setup.get("source", "")) == "schnell"


## Kampf vorbei: EP und Verwundung verbuchen (nicht im Schnellkampf), Ergebnis ablegen, zurück
static func finish(tree: SceneTree, result: Dictionary) -> void:
	if not is_quick():
		Campaign.finish_mission(result)
	last_result = result
	var back := String(setup.get("return_scene", HubState.START_SCENE))
	setup = {}
	tree.change_scene_to_file(back)


## Ergebnis einmal abholen (danach leer)
static func take_result() -> Dictionary:
	var r := last_result
	last_result = {}
	return r
