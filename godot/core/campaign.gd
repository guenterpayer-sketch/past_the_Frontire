class_name Campaign
extends RefCounted
## Laufender Spielstand zwischen den Modulen (bleibt beim Szenenwechsel erhalten):
## Charakter-Modul (Crew-Szene) ⇄ Kampfmodul (Bodenkampf-Szene).
## Hinein in den Kampf gehen Kopien der Charaktere, heraus kommt ein MissionResult.

const CREW_SCENE := "res://crew.tscn"
const BATTLE_SCENE := "res://main.tscn"
const ROSTER_SCENE := "res://roster.tscn"
## Plätze an Bord zu Beginn (6 Einsatz + 2 Reserve; der Hub kann später mehr erlauben)
const START_SEATS := 8
## höchstens so viele Figuren gehen in einen Einsatz
const MAX_SQUAD := 6
## Truppgröße bei „schwer“ (Entscheidung des Nutzers 18.10.2026; Bodenkampf, gilt für jeden schweren Bodenkampf)
const HARD_SQUAD := 8


## Höchste Truppgröße für eine Schwierigkeit: schwer 8, sonst MAX_SQUAD
static func max_squad(difficulty: String) -> int:
	return HARD_SQUAD if difficulty == "schwer" else MAX_SQUAD

static var _crew: Array[Character] = []
## Entlassene mit ihrem Fortschritt; warten „im Hafen“ und können in diesem Spiel wieder angeheuert werden
static var _harbor: Array[Character] = []
static var _loaded := false
## Ergebnis des letzten Einsatzes (leer, wenn die Crew-Szene nicht nach einem Kampf geöffnet wurde)
static var last_result := {}
## im Briefing gewählter Trupp (bis HARD_SQUAD; leer = die ersten nicht gesperrten der Crew); wird mit der Crew gespeichert
static var chosen_squad: Array[Character] = []
## Schnellkampf: Kopien aus dem globalen Roster (gehen nicht in die Crew, nichts wird verbucht); leer = kein Schnellkampf
static var quick_squad: Array[Character] = []
## im letzten Einsatz Gestorbene (haben die Crew verlassen; für Bericht und Anzeige)
static var last_fallen: Array[Character] = []


static func crew() -> Array[Character]:
	if not _loaded:
		_load()
	return _crew


static func harbor() -> Array[Character]:
	crew()
	return _harbor


static func _load() -> void:
	_crew = Roster.load_crew()
	var extra := Roster.load_extra()
	_harbor = extra.harbor
	chosen_squad = []
	for id in extra.squad:
		for c in _crew:
			if c.id == id:
				chosen_squad.append(c)
	_loaded = true


## Einsatzergebnis verbuchen (EP, freie EP, Verwundung) und sofort speichern.
## Tote (nur durch den Todeswurf, wenn die ganze Crew gefallen ist) verlassen die Crew; der Roster-Eintrag bleibt.
static func finish_mission(result: Dictionary) -> void:
	var units: Dictionary = result.get("units", {})
	last_fallen = []
	for c in crew().duplicate():
		if not units.has(c.id):
			continue
		var r: Dictionary = units[c.id]
		if r.get("died", false):
			last_fallen.append(c)
			_crew.erase(c)
			chosen_squad.erase(c)
		else:
			c.apply_result(r)
	last_result = result
	quick_squad = []
	save()


## Tage vergehen (Reisen, Warten, Einsatz): alle Verwundeten heilen um days Tage, dazu bonus_days
## (Ergebnis der Zweite-Hilfe-Probe der Krankenstation, vom Hub). Gibt die wieder Gesunden zurück.
static func pass_days(days: int, bonus_days := 0) -> Array[Character]:
	var healed: Array[Character] = []
	for c in crew():
		if c.injury != "" and c.heal(days + bonus_days):
			healed.append(c)
	for c in _harbor:
		c.heal(days)
	save()
	return healed


## Verwundete an Bord (für die Krankenstation)
static func patients() -> Array[Character]:
	return crew().filter(func(c: Character) -> bool: return c.injury != "")


## Kandidaten für die Truppwahl im Briefing: [{ch, locked, reason, marked, note}].
## Im Spiel: Crew (Einsatz + Reserve); gesperrt = kampfunfähig, schwer verwundet oder Arzt (blocked_ids vom Hub);
## markiert = angeschlagen (Malus). Im Schnellkampf (quick): Kopien aus dem globalen Roster, nichts gesperrt.
static func candidates(quick := false, blocked_ids: Array = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var list: Array[Character] = []
	if quick:
		for r in GlobalRoster.entries():
			list.append(r.duplicate_character())
	else:
		list = crew()
	for c in list:
		var reason := ""
		if c.is_locked():
			reason = c.injury_text()
		elif c.id in blocked_ids:
			reason = "Arzt in der Krankenstation"
		out.append({"ch": c, "locked": reason != "", "reason": reason,
			"marked": c.injury == Injury.LIGHT, "note": c.injury_text()})
	return out


## Vorbelegung der Truppwahl: der letzte Trupp ohne Gesperrte, freie Plätze aus der Reserve aufgefüllt
static func suggested_squad(cands: Array[Dictionary], limit := MAX_SQUAD) -> Array[Character]:
	var free := cands.filter(func(k: Dictionary) -> bool: return not k.locked).map(func(k: Dictionary) -> Character: return k.ch)
	var out: Array[Character] = []
	for c in chosen_squad:
		if c in free and out.size() < limit:
			out.append(c)
	for c in free:
		if not c in out and out.size() < limit:
			out.append(c)
	return out


## Neues Crewmitglied aufnehmen (replace = ersetztes Mitglied oder null) und speichern
static func add_member(ch: Character, replace: Character = null) -> void:
	var i := crew().find(replace) if replace else -1
	if i >= 0:
		_crew[i] = ch
	else:
		_crew.append(ch)
	save()


## Neues Spiel: Crew aus Roster-Figuren (Kopien; der Roster bleibt unverändert) und speichern
static func new_game(picked: Array[Character]) -> void:
	_crew = []
	for r in picked:
		_crew.append(_copy_from_roster(r))
	_harbor = []
	last_result = {}
	chosen_squad = []
	quick_squad = []
	_loaded = true
	save()


## Anheuern (im Hafen; Ort und Platzprüfung macht der Hub): eine Figur „im Hafen“ kommt mit ihrem Fortschritt zurück,
## eine Roster-Figur als Kopie mit dem Roster-Stand (wartet sie schon im Hafen, kommt die Hafen-Figur).
## null, wenn sie schon an Bord ist.
static func hire(entry: Character) -> Character:
	harbor()
	if is_aboard(entry.roster_id):
		return null
	var c: Character = null
	for h in _harbor:
		if h == entry or h.roster_id == entry.roster_id:
			c = h
	if c:
		_harbor.erase(c)
	else:
		c = _copy_from_roster(entry)
	_crew.append(c)
	save()
	return c


## Figur entlassen: sie wartet mit ihrem Fortschritt „im Hafen“ (wieder anheuerbar in diesem Spiel); der Roster bleibt unberührt
static func fire(ch: Character) -> void:
	crew().erase(ch)
	chosen_squad.erase(ch)
	_harbor.append(ch)
	save()


static func is_aboard(roster_id: StringName) -> bool:
	return crew().any(func(c: Character) -> bool: return c.roster_id == roster_id)


## Figuren für den nächsten Einsatz: Schnellkampf-Trupp, sonst der gewählte Trupp, sonst die ersten nicht gesperrten;
## höchstens limit (max_squad(Schwierigkeit), Standard MAX_SQUAD)
static func squad(limit := MAX_SQUAD) -> Array[Character]:
	if not quick_squad.is_empty():
		return quick_squad.slice(0, limit)
	var s: Array[Character] = chosen_squad.filter(func(c: Character) -> bool: return c in crew() and not c.is_locked())
	if s.is_empty():
		s = crew().filter(func(c: Character) -> bool: return not c.is_locked())
	return s.slice(0, limit)


## Trupp aus der Truppwahl übernehmen und speichern (im Schnellkampf: quick_squad setzen statt dieser Funktion)
static func set_squad(chars: Array[Character]) -> void:
	chosen_squad = chars.slice(0, HARD_SQUAD)
	save()


static func _copy_from_roster(r: Character) -> Character:
	var c := r.duplicate_character()
	c.roster_id = r.roster_id if r.roster_id != &"" else r.id
	var taken := _crew.map(func(o: Character) -> StringName: return o.id)
	var id := c.id
	var i := 2
	while id in taken:
		id = StringName("%s_%d" % [c.id, i])
		i += 1
	c.id = id
	return c


static func save() -> void:
	Roster.save_crew(crew(), _harbor, chosen_squad.map(func(c: Character) -> StringName: return c.id))


## Crew neu von der Festplatte lesen (z. B. nachdem ein Spielstand user://crew.json ersetzt hat);
## das letzte Einsatzergebnis wird verworfen
static func reload() -> void:
	_load()
	last_result = {}
	quick_squad = []


## Speicherstand löschen, Startcrew laden
static func reset() -> void:
	Roster.reset()
	_crew = Roster.start_crew()
	_harbor = []
	chosen_squad = []
	quick_squad = []
	_loaded = true
	last_result = {}
