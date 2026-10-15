class_name Battle
extends Node3D
## Hauptszene: verbindet Kampflogik (Combat, CombatAI), Darstellung (MapView, UnitView, Overlay, Fx),
## Ablauf der Ereignisse (EventPlayer), Bedienung (PlayerController) und Oberfläche (BattleUI).
## Kampfmodul: bekommt Kopien der Charaktere (im Briefing gewählter Trupp, Campaign.candidates), gibt am Ende ein MissionResult zurück
## und wechselt ins Charakter-Modul (crew.tscn).
## Aus dem Schiff gestartet (HubState.in_mission) kommt die Mission von der Sternenkarte; danach geht es
## mit einem Einsatzbericht zurück ins Schiff statt ins Charakter-Modul.

const AI_DELAY := 0.22
const LONG_PRESS := 0.55

var combat: Combat
var mission: Mission
var deploy_sel: Combatant = null   # Runde 0: gewählte Figur
var ai := CombatAI.new()
var player: PlayerController
var views := {}                  # Combatant -> UnitView
var auto_crew := false
var show_grid := true
## Truppwahl: Kandidaten (Campaign.candidates) und gewählter Trupp dieses Einsatzes
var candidates: Array[Dictionary] = []
var squad: Array[Character] = []
var _seed := 0
var _keep_squad := false         # Neuaufbau nach der Truppwahl: Auswahl unverändert übernehmen

var _hover: Variant = null       # Feld unter der Maus (Vector2i) oder null
var _hover_unit: Combatant = null
var _ai_thread: Thread
var _ai_wait := 0.0
var _dirty := true
var _end_shown := false
# Touch
var _touches := {}
var _pinch_dist := 0.0
var _touch_moved := false
var _touch_start_ms := 0
var _long_fired := false
var _tap_key := ""
var _tap_pos := Vector2.ZERO
var _menu_target: Combatant = null
var _touch_used := false
var _mouse_drag := false
var _drag_moved := false
var _drag_accum := Vector2.ZERO

@onready var map_view: MapView = $World/MapView
@onready var overlay: Overlay = $World/Overlay
@onready var fx: Fx = $World/Fx
@onready var units_root: Node3D = $World/Units
@onready var rig: CameraRig = $CameraRig
@onready var events: EventPlayer = $EventPlayer
@onready var ui: BattleUI = $UI/BattleUI


func _ready() -> void:
	Dice.randomize()
	if OS.has_feature("mobile") or "--no-shadows" in OS.get_cmdline_user_args():
		$Sun.shadow_enabled = false
	overlay.map_view = map_view
	events.map_view = map_view
	events.fx = fx
	events.camera = rig
	events.dice_panel = ui.dice_panel
	events.combat_log = ui.combat_log
	events.dice_enabled = Prefs.get_bool("dice", true)
	events.idle_changed.connect(func(_idle: bool) -> void: _dirty = true)
	show_grid = Prefs.get_bool("grid", true)
	ui.action.connect(_on_action)
	ui.context_menu.chosen.connect(_on_context)
	ui.briefing.accepted.connect(_on_squad)
	ui.briefing.quick = HubState.quick_battle
	ui.set_toggle(&"sound", Sfx.enabled)
	ui.set_toggle(&"dice", events.dice_enabled)
	rig.rotated.connect(func() -> void: map_view.update_cutaway(rig.view_dir()))
	var hub_mission := HubState.active_mission()
	ui.briefing.hub_mode = hub_mission != null
	if hub_mission:
		ui.top_menu.set_menu_text(&"new", "Einsatz abbrechen / Rückzug")
		new_battle(hub_mission.map_seed, "", "", true, hub_mission)
	else:
		new_battle(randi() % 1000000)
	var args := OS.get_cmdline_user_args()
	if ("--autotest" in args or "--autotest-player" in args or "--autotest-psi" in args) and not get_tree().root.has_node("Autotest"):
		# der Selbsttest hängt an der Wurzel, damit er den Wechsel ins Charakter-Modul übersteht
		var t: Node = load("res://tests/autotest.gd").new()
		t.name = "Autotest"
		t.battle = self
		get_tree().root.add_child.call_deferred(t)


## Neuer Einsatz: Mission würfeln (Gegner, Halle), Karte bauen, Runde 0 (Aufstellung) mit Briefing.
## size_id/difficulty leer = vom Missionsgenerator bestimmt; briefing = false überspringt die Einsatzbesprechung;
## m = fertige Mission (aus dem Schiff).
func new_battle(seed_value: int, size_id := "", difficulty := "", briefing := true, m: Mission = null) -> void:
	mission = m if m else Mission.generate(seed_value, difficulty)
	if size_id != "":
		mission.size_id = size_id
	_seed = seed_value
	_pick_squad()
	_wait_ai()
	events.clear()
	ui.combat_log.clear()
	ui.result_banner.hide()
	_end_shown = false
	Music.play(Music.BRIEFING)   # Briefing und Runde 0 (Musikspieler des Hubs)
	var map := MapGenerator.generate(seed_value, mission.size_id)
	combat = Combat.new(map, Roster.build_crew(squad), Roster.build_units(mission.enemies, &"enemy"))
	ai = CombatAI.new()
	player = PlayerController.new(combat)
	map_view.theme = GameData.hall_theme()
	map_view.build(map)
	map_view.set_grid_visible(show_grid)
	for c in units_root.get_children():
		c.queue_free()
	views.clear()
	for u in combat.units:
		var v := UnitView.new()
		units_root.add_child(v)
		v.setup(u)
		v.position = map_view.tile_top(u.pos)
		views[u] = v
	events.views = views
	events.bind(combat)
	combat.ended.connect(func(_r: StringName) -> void: _dirty = true)
	var c := map_view.center()
	rig.bounds = Rect2(-2, -2, c.x * 2 + 4, c.z * 2 + 4)
	rig.focus(map_view.tile_top(map.crew_start[0].pos).lerp(c, 0.35))
	map_view.update_cutaway(rig.view_dir())
	var sz: Dictionary = map.size_info
	ui.top_menu.set_mission(mission.title, "%s · %s · Lagerhalle %s, ca. %d×%d m · Karte %d" % [mission.title, mission.faction.name, sz.name, roundi(sz.cols * Hex.SIZE_M), roundi(sz.rows * Hex.ROW_M), map.map_seed])
	ui.combat_log.add("Einsatz „%s“ (%s): %d Crewmitglieder gegen %s (%s) in einer Lagerhalle (%s)." % [
		mission.title, mission.difficulty_name(), combat.crew().size(), mission.faction.name, mission.enemy_summary(), sz.name], &"round")
	ui.combat_log.add("Runde 0: Crew im Eingangsbereich aufstellen, dann „Kampf beginnen“.", &"")
	deploy_sel = combat.crew()[0] if not combat.crew().is_empty() else null
	_mark_current(deploy_sel)
	if briefing:
		ui.briefing.show_mission(mission, candidates, squad)
	_dirty = true


## Kandidaten und Vorbelegung (Charakter-Modul): im Spiel neu aus der Crew (letzter Trupp, Gesperrte heraus, aufgefüllt);
## Schnellkampf: Roster-Kopien einmal holen, Auswahl bleibt bei „Andere Mission“ erhalten.
## Arzt der Krankenstation gesperrt über HubState.blocked_ids() (Hub).
func _pick_squad() -> void:
	if _keep_squad:
		_keep_squad = false
		return
	if HubState.quick_battle:
		if candidates.is_empty():
			candidates = Campaign.candidates(true)
			squad = Campaign.suggested_squad(candidates)
			Campaign.quick_squad = squad.duplicate()
		return
	candidates = Campaign.candidates(false, HubState.blocked_ids())
	squad = Campaign.suggested_squad(candidates)


## Briefing geschlossen: Trupp ans Charakter-Modul (Campaign.set_squad, Schnellkampf quick_squad);
## anderer Trupp → Runde 0 mit derselben Karte neu aufbauen
func _on_squad(sel: Array[Character]) -> void:
	if sel.is_empty() or not combat.deploying:
		return
	if HubState.quick_battle:
		Campaign.quick_squad = sel.duplicate()
	else:
		Campaign.set_squad(sel)
	if sel == squad:
		return
	squad = sel.duplicate()
	_keep_squad = true
	new_battle(_seed, mission.size_id, "", false, mission)


## Kampf vorbei: Ergebnis an das Charakter-Modul geben (dort verbucht und gespeichert), dann
## aus dem Schiff gestartet: Bericht ans Schiff und zurück dorthin; sonst ins Charakter-Modul.
## Schnellkampf aus dem Startmenü (HubState.quick_battle): nichts verbuchen, zurück ins Startmenü.
func finish_mission() -> void:
	var c := combat
	Music.play(Music.VICTORY if c.result == &"sieg" else Music.DEFEAT)   # Niederlage auch bei Rückzug
	if HubState.quick_battle:
		ui.combat_log.add("%s – Schnellkampf, nichts verbucht. Zurück ins Startmenü …" % ("Sieg" if c.result == &"sieg" else "Niederlage"), &"round")
		await get_tree().create_timer(2.5).timeout
		if combat == c:
			get_tree().change_scene_to_file(HubState.START_SCENE)
		return
	var result := MissionResult.from_combat(c, mission)
	Campaign.finish_mission(result)
	var to_ship := HubState.in_mission()
	if to_ship:
		var rep := hub_report(result)
		if c.retreated:
			rep.title = "%s (Rückzug)" % rep.title
		HubState.game.finish_mission(rep)
	# Ergebnis über der Karte zeigen; die Szene wechselt erst auf „Weiter“
	await get_tree().create_timer(0.6).timeout
	ui.result_banner.show_result(c, result, "Zurück ins Schiff" if to_ship else "Zur Crew")
	await ui.result_banner.continued
	if combat == c:
		get_tree().change_scene_to_file(HubState.HUB_SCENE if to_ship else Campaign.CREW_SCENE)


## Einsatzbericht fürs Schiff aus dem MissionResult (Namen aus der Crew)
func hub_report(result: Dictionary) -> Dictionary:
	var g := HubState.game
	var units := []
	var states := {"ok": "kampffähig", "ko": "bewusstlos", "sterbend": "sterbend", "tot": "tot"}
	for ch in Campaign.crew() + Campaign.last_fallen:
		var r: Dictionary = result.units.get(ch.id, {})
		if r.is_empty():
			continue
		var xp: Dictionary = r.get("xp", {})
		var keys := xp.keys()
		keys.sort_custom(func(a, b) -> bool: return xp[a] > xp[b])
		units.append({"letter": ch.letter, "name": ch.name, "state": "stabilisiert" if r.get("stabilized", false) else states.get(r.status.state, r.status.state),
			"xp": ", ".join(keys.map(func(k) -> String: return "%s +%d" % [Rules.skill_name(k), xp[k]]))})
	return {"outcome": result.outcome, "title": result.mission, "faction": mission.faction.name,
		"system": g.sector.systems[g.position].name, "rounds": result.rounds, "reward_xp": result.reward_xp,
		"free_xp": MissionResult.FREE_XP + result.reward_xp, "units": units}


## „Einsatz abbrechen“ im Schiffsmodus: vor Runde 1 zurück ins Schiff (Auftrag bleibt offen),
## danach Rückzug (zählt als Niederlage, EP bleiben); jeweils mit Rückfrage
func _ask_leave() -> void:
	if combat.result != &"":
		return
	if combat.deploying:
		ui.ask("Einsatz abbrechen und zurück ins Schiff?\nDer Auftrag bleibt auf der Sternenkarte offen.", "Zurück ins Schiff", return_to_ship)
	else:
		ui.ask("Rückzug antreten?\nDer Einsatz zählt als Niederlage: Der Auftrag ist verloren und die Zeit vergeht.\nDie EP aus diesem Kampf bleiben.", "Rückzug",
			func() -> void: combat.retreat())


## Einsatz abbrechen: zurück ins Schiff, der Auftrag bleibt offen
func return_to_ship() -> void:
	_wait_ai()
	HubState.game.abort_mission()
	get_tree().change_scene_to_file(HubState.HUB_SCENE)


## Eintrag im Kontextmenü gewählt: Psi-Angriff oder unterstützende Kraft auf das gemerkte Ziel
func _on_context(e: Dictionary) -> void:
	var u := combat.current
	if not player_turn() or _menu_target == null:
		return
	if e.has("attack"):
		var w: WeaponData = e.attack
		player.select_weapon(u, w)
		combat.do_attack(u, _menu_target, w, player.attack_pct(u, w))
	else:
		combat.do_power(u, e.k, u if PsiCombat.SUPPORT[e.k].target in ["self", "area", "foes"] else _menu_target)
	player.mode = PlayerController.Mode.MOVE
	_menu_target = null
	_dirty = true


## Figur markieren, die am Zug ist bzw. aufgestellt wird (Ring, Sichtfeld, Schild); die anderen abdunkeln
func _mark_current(cur: Combatant) -> void:
	for o in views:
		views[o].set_current(o == cur, cur != null)


## Schild „am Zug“ über der Figur halten (aus dem Bild: ausblenden)
func _update_active_tag() -> void:
	var u: Combatant = deploy_sel if combat.deploying else combat.current
	if u == null or combat.result != &"" or not views.has(u) or not u.is_ok():
		ui.active_tag.hide()
		return
	var v: UnitView = views[u]
	if rig.camera.is_position_behind(v.tag_point()):
		ui.active_tag.hide()
		return
	var p := rig.camera.unproject_position(v.tag_point())
	var r := get_viewport().get_visible_rect()
	if not r.has_point(p):
		ui.active_tag.hide()
		return
	var text := "%s · %s" % [u.name.split(" ")[0], "aufstellen" if combat.deploying else "am Zug"]
	ui.active_tag.show_at(p, text, u.color, not u.is_crew)


## Runde 0 beenden: Kampf mit Runde 1 starten
func begin_combat() -> void:
	if not combat.deploying:
		return
	deploy_sel = null
	_mark_current(null)
	ui.briefing.hide()
	Music.play(Music.BATTLE)
	combat.start()
	_dirty = true


func is_ai(u: Combatant) -> bool:
	return u != null and (not u.is_crew or auto_crew)


func player_turn() -> bool:
	var u := combat.current
	return u != null and not is_ai(u) and combat.result == &"" and events.is_idle() and u.is_ok() and _ai_thread == null


func _process(delta: float) -> void:
	_tick_ai(delta)
	_update_active_tag()
	if _dirty and events.is_idle():
		_dirty = false
		_refresh()
	if combat.result != &"" and events.is_idle() and not _end_shown:
		_end_shown = true
		finish_mission()
	if _touches.size() == 1 and not _touch_moved and not _long_fired and Time.get_ticks_msec() - _touch_start_ms > LONG_PRESS * 1000:
		_long_fired = true
		var p: Vector2 = _touches.values()[0]
		_face_at(p)


## KI-Züge: Planung in einem eigenen Thread (die Halle bleibt bedienbar), Ausführung im Hauptthread
func _tick_ai(delta: float) -> void:
	if _ai_thread:
		if not _ai_thread.is_alive():
			var step: Dictionary = _ai_thread.wait_to_finish()
			_ai_thread = null
			var u := combat.current
			if u and is_ai(u) and combat.result == &"":
				if step.type == &"end" or not ai.execute(combat, u, step):
					combat.end_turn()
			_dirty = true
		return
	if combat.result != &"" or not events.is_idle():
		_ai_wait = 0.0
		return
	var u := combat.current
	if u == null:
		return
	if not u.is_ok():
		combat.end_turn()
		return
	if not is_ai(u):
		return
	_ai_wait += delta
	if _ai_wait < AI_DELAY:
		return
	_ai_wait = 0.0
	_ai_thread = Thread.new()
	_ai_thread.start(ai.plan_step.bind(combat, u))


func _wait_ai() -> void:
	if _ai_thread:
		_ai_thread.wait_to_finish()
		_ai_thread = null


func _exit_tree() -> void:
	_wait_ai()


# ---------------------------------------------------------------- Anzeige

func _refresh() -> void:
	var u := combat.current
	var pt := player_turn()
	if not pt and ui.context_menu.visible:
		ui.context_menu.hide()
	ui.top_menu.set_round("Runde %d" % combat.round_no if not combat.deploying else "Runde 0 – Aufstellung")
	ui.initiative.refresh(combat, is_ai)
	if combat.deploying:
		ui.card.refresh(combat, deploy_sel)
		ui.ai_card.refresh(combat, null)
		ui.actions.refresh_deploy(combat, deploy_sel, mission)
	elif u == null or combat.result != &"":
		ui.card.refresh(combat, null)
		ui.ai_card.refresh(combat, null)
		ui.actions.refresh(combat, player, null, false)
	elif is_ai(u):
		# KI am Zug: deren Figur unten rechts, kein Aktionsblock
		ui.card.refresh(combat, null)
		ui.ai_card.refresh(combat, u, "%s ist am Zug …" % ("Gegner" if not u.is_crew else "KI"))
		ui.actions.refresh(combat, player, null, false)
	else:
		ui.card.refresh(combat, u, "", player.weapon_of(u))
		ui.ai_card.refresh(combat, null)
		ui.actions.refresh(combat, player, u, pt)
	_update_overlay()


func _update_overlay() -> void:
	if combat.deploying:
		overlay.show_state({"reach_tiles": combat.deploy_tiles(), "helpers": [deploy_sel] if deploy_sel else [], "views": views,
			"hover": _hover})
		return
	var u := combat.current
	if not player_turn() or u == null:
		overlay.show_state({"hover": _hover if _hover != null and events.is_idle() else null})
		return
	var st := player.view_state(u, _hover, _hover_unit)
	st.views = views
	overlay.show_state(st)


func _update_hover(screen_pos: Vector2) -> void:
	var hit := _pick(screen_pos)
	if hit.tile != _hover or hit.unit != _hover_unit:
		_hover = hit.tile
		_hover_unit = hit.unit
		_update_overlay()
	var tip := ""
	if events.is_idle() and not ui.covers(screen_pos):
		tip = player.tooltip(combat.current, player_turn(), _hover, _hover_unit)
	ui.show_tip(tip, screen_pos, _touch_used and tip != "" and (player_turn() or combat.deploying))


## Feld und Figur unter einem Bildschirmpunkt: Figuren nach Bildschirmabstand,
## Felder über Ebenen je Höhenstufe (von oben nach unten)
func _pick(screen_pos: Vector2) -> Dictionary:
	if ui.covers(screen_pos):
		return {"tile": null, "unit": null}
	var best_u: Combatant = null
	var best_d := 1e9
	var vh := get_viewport().get_visible_rect().size.y
	var radius := 0.6 / rig.camera.size * vh
	for u in views:
		if u.is_dead():
			continue
		var v: UnitView = views[u]
		for y in [0.4, 1.0, 1.6]:
			var sp := rig.camera.unproject_position(v.position + Vector3(0, y, 0))
			var d := sp.distance_to(screen_pos)
			if d < radius and d < best_d:
				best_d = d
				best_u = u
	# Felder je Höhenstufe von oben nach unten; erreichbare Felder haben Vorrang (verdeckt hinter Kisten o. Ä.)
	var tile: Variant = null
	var reach: BattleMap.Reach = player.reach(combat.current) if player_turn() else null
	for h in range(6, -1, -1):
		var p: Variant = rig.ray_plane(screen_pos, h * BattleMap.LEVEL_M)
		if p == null:
			continue
		var t := combat.map.tile(Hex.from_world(Vector2(p.x, p.z)))
		if t and t.h == h:
			if reach and reach.has(t.pos) and t.pos != combat.current.pos:
				tile = t.pos
				break
			if tile == null:
				tile = t.pos
				if reach == null:
					break
	if best_u:
		tile = best_u.pos
	return {"tile": tile, "unit": best_u}


# ---------------------------------------------------------------- Eingabe

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		_touch_input(e)
		return
	if e is InputEventMouse and e.device == InputEvent.DEVICE_ID_EMULATION:
		return  # vom Touch erzeugte Mausereignisse: die Touch-Behandlung übernimmt
	if e is InputEventMouseMotion:
		if _mouse_drag and (e.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE)):
			_drag_accum += e.relative
			if _drag_moved or _drag_accum.length() > 6.0:
				_drag_moved = true
				rig.pan(e.relative)
		_update_hover(e.position)
	elif e is InputEventMouseButton:
		_mouse_button(e)
	elif e is InputEventKey and e.pressed and not e.echo:
		_key(e)


func _mouse_button(e: InputEventMouseButton) -> void:
	if ui.covers(e.position):
		return
	match e.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			if e.pressed:
				rig.zoom_at(e.position, 1.12)
		MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed:
				rig.zoom_at(e.position, 1 / 1.12)
		MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE:
			if e.pressed:
				_mouse_drag = true
				_drag_moved = false
				_drag_accum = Vector2.ZERO
			else:
				var was_drag := _drag_moved
				_mouse_drag = false
				_drag_moved = false
				if not was_drag and e.button_index == MOUSE_BUTTON_LEFT:
					_click(e.position)
		MOUSE_BUTTON_RIGHT:
			if e.pressed:
				_face_at(e.position)


func _click(p: Vector2) -> void:
	if ui.context_menu.visible:
		ui.context_menu.hide()
		return
	if combat.deploying:
		_deploy_click(p)
		return
	if not player_turn():
		return
	var hit := _pick(p)
	player.click(combat.current, hit.tile, hit.unit)
	ui.hide_tip()
	_dirty = true


## Runde 0: Figur der Crew anklicken = wählen, Feld im Eingangsbereich = dorthin stellen (oder tauschen)
func _deploy_click(p: Vector2) -> void:
	var hit := _pick(p)
	ui.hide_tip()
	if hit.unit and hit.unit.is_crew and hit.unit != deploy_sel:
		deploy_sel = hit.unit
		_mark_current(deploy_sel)
	elif hit.tile != null and deploy_sel:
		var other := combat.deploy(deploy_sel, hit.tile)
		if combat.unit_at(hit.tile) == deploy_sel:
			Sfx.play(&"schritt")
			views[deploy_sel].position = map_view.tile_top(deploy_sel.pos)
			if other:
				views[other].position = map_view.tile_top(other.pos)
	_dirty = true


func _deploy_turn(u: Combatant, dir: int) -> void:
	combat.deploy_face(u, dir)
	views[u].set_facing(u.facing)
	_dirty = true


func _face_at(p: Vector2) -> void:
	if not combat.deploying and player_turn():
		# Rechtsklick auf eine Figur: Kontextmenü mit passenden Psi-Kräften (sonst drehen wie bisher)
		var h := _pick(p)
		var u := combat.current
		if h.unit:
			var entries := player.context_powers(u, h.unit)
			if not entries.is_empty():
				_menu_target = h.unit
				var rel := "selbst" if h.unit == u else ("verbündet" if h.unit.team == u.team else "Gegner")
				ui.hide_tip()
				ui.context_menu.open_at("%s · %s, %d Hex" % [h.unit.name.split(" ")[0], rel, Hex.distance(u.pos, h.unit.pos)],
					"PSI-KRÄFTE (%s, %d PP)" % [u.name.split(" ")[0], u.pp], entries, p)
				return
	if combat.deploying:
		var hit := _pick(p)
		if deploy_sel and hit.tile != null and hit.tile != deploy_sel.pos:
			_deploy_turn(deploy_sel, Hex.dir_toward(deploy_sel.pos, hit.tile))
		return
	if not player_turn():
		return
	var hit := _pick(p)
	if hit.tile != null:
		player.face_toward(combat.current, hit.tile)
		_dirty = true


func _key(e: InputEventKey) -> void:
	match e.keycode:
		KEY_ESCAPE:
			if not ui.close_dialogs():
				player.mode = PlayerController.Mode.MOVE
		KEY_ENTER, KEY_KP_ENTER:
			if ui.result_banner.visible:
				ui.result_banner.confirm()
			elif combat.deploying and not ui.any_dialog_open():
				begin_combat()
			elif player_turn():
				combat.end_turn()
		KEY_R:
			player.show_range = not player.show_range
		KEY_G:
			_toggle_grid()
		KEY_Q:
			rig.rotate_by(-90)
		KEY_E:
			rig.rotate_by(90)
		KEY_A, KEY_LEFT:
			rig.pan(Vector2(80, 0))
		KEY_D, KEY_RIGHT:
			rig.pan(Vector2(-80, 0))
		KEY_W, KEY_UP:
			rig.pan(Vector2(0, 80))
		KEY_S, KEY_DOWN:
			rig.pan(Vector2(0, -80))
		KEY_PLUS, KEY_KP_ADD, KEY_EQUAL:
			rig.zoom_at(get_viewport().get_visible_rect().size / 2.0, 1.2)
		KEY_MINUS, KEY_KP_SUBTRACT:
			rig.zoom_at(get_viewport().get_visible_rect().size / 2.0, 1 / 1.2)
	_dirty = true


## Handy/Tablet: ziehen = verschieben, zwei Finger = zoomen, Antippen = Vorschau, nochmal = ausführen, lange drücken = drehen
func _touch_input(e: InputEvent) -> void:
	_touch_used = true
	if e is InputEventScreenTouch:
		if e.pressed:
			if ui.covers(e.position):
				return
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_touch_moved = false
				_drag_accum = Vector2.ZERO
				_long_fired = false
				_touch_start_ms = Time.get_ticks_msec()
			else:
				_touch_moved = true
				_pinch_dist = _pinch_state().d
		else:
			var was: bool = _touches.has(e.index)
			_touches.erase(e.index)
			if was and _touches.is_empty() and not _touch_moved and not _long_fired:
				_tap(e.position)
	elif e is InputEventScreenDrag:
		if not _touches.has(e.index):
			return
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			var st := _pinch_state()
			if _pinch_dist > 0:
				rig.zoom_at(st.c, st.d / _pinch_dist)
			_pinch_dist = st.d
			rig.pan(e.relative / 2.0)
		else:
			if not _touch_moved:
				_drag_accum += e.relative
				if _drag_accum.length() < 10.0:
					return
				_touch_moved = true
			rig.pan(e.relative)


func _pinch_state() -> Dictionary:
	var ps: Array = _touches.values()
	var a: Vector2 = ps[0]
	var b: Vector2 = ps[1]
	return {"d": a.distance_to(b), "c": (a + b) / 2.0}


func _tap(p: Vector2) -> void:
	_update_hover(p)
	var key := ""
	if _hover_unit:
		key = "u:%s" % _hover_unit.id
	elif _hover != null:
		key = str(_hover)
	if key != "" and key == _tap_key:
		_tap_key = ""
		_click(p)
	else:
		_tap_key = key
		_tap_pos = p


# ---------------------------------------------------------------- Aktionen aus der Oberfläche

func _on_action(name: StringName, arg: Variant) -> void:
	var u := combat.current
	match name:
		&"sheet":
			var target: Combatant = arg if arg is Combatant else (u if u and u.is_crew else combat.crew()[0])
			ui.sheet.show_sheet(combat.crew(), target)
		&"tables":
			ui.tables.show_tables(player.weapon_of(u) if u else null, u if u and u.is_crew else null)
		&"auto":
			auto_crew = arg
		&"sound":
			Sfx.toggle()
			ui.set_toggle(&"sound", Sfx.enabled)
		&"dice":
			events.dice_enabled = not events.dice_enabled
			Prefs.set_bool("dice", events.dice_enabled)
			ui.set_toggle(&"dice", events.dice_enabled)
			if not events.dice_enabled:
				ui.dice_panel.hide()
		&"new":
			if HubState.in_mission():
				_ask_leave()
			else:
				new_battle(randi() % 1000000)
		&"reroll":
			if HubState.in_mission():
				return_to_ship()
			else:
				new_battle(randi() % 1000000, "", arg)
		&"briefing":
			ui.briefing.show_mission(mission, candidates, squad)
		&"psi_tab":
			player.psi_tab = arg
		&"help":
			ui.show_help()
		&"range":
			player.show_range = not player.show_range
		&"confirm":
			# Touch: "Ausführen" im Infokasten = zweites Antippen
			if _tap_key != "":
				_tap_key = ""
				_click(_tap_pos)
		&"begin":
			begin_combat()
		&"deploy_select":
			deploy_sel = arg
			_mark_current(arg)
			rig.focus(views[arg].position, false)
		&"deploy_turn":
			if deploy_sel:
				_deploy_turn(deploy_sel, posmod(deploy_sel.facing + arg, 6))
		&"focus":
			rig.focus(views[arg].position, false)
		&"jump":
			if not is_ai(arg):
				combat.request_jump(arg)
		&"grid":
			_toggle_grid()
		&"refresh", &"panel":
			pass
		&"ui_scale":
			ui.show_ui_scale()
		_:
			if player_turn():
				_panel_action(u, name, arg)
	_dirty = true


func _panel_action(u: Combatant, name: StringName, arg: Variant) -> void:
	match name:
		&"weapon":
			player.select_weapon(u, arg)
		&"gait":
			player.gait = arg
			player.mode = PlayerController.Mode.MOVE
		&"pct":
			player.pct = arg
		&"overwatch":
			combat.do_overwatch(u, player.weapon_of(u))
		&"reload":
			combat.do_reload(u, arg)
		&"aid":
			player.toggle_mode(PlayerController.Mode.AID)
		&"power":
			player.choose_power(u, arg)
		&"face":
			player.toggle_mode(PlayerController.Mode.FACE)
		&"crouch":
			combat.do_crouch(u)
		&"wait":
			combat.do_wait(u)
		&"end":
			combat.end_turn()
	Sfx.play(&"klick")


func _toggle_grid() -> void:
	show_grid = not show_grid
	Prefs.set_bool("grid", show_grid)
	map_view.set_grid_visible(show_grid)
