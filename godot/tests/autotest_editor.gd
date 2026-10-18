extends Node
## Selbsttest des Karteneditors mit Screenshots (Zielordner PTF_OUT), hängt an der Wurzel:
##   godot --path godot res://map_editor.tscn -- --autotest-editor
## Eigene Karten landen in user://maps_autotest (die echten bleiben unberührt). Am Ende Probekampf auf der Karte.

var editor: MapEditor
var out := ""


func _ready() -> void:
	out = OS.get_environment("PTF_OUT")
	if out == "":
		out = "user://"
	CustomMaps.dir = "user://maps_autotest"
	if DirAccess.dir_exists_absolute(CustomMaps.dir):
		for f in DirAccess.get_files_at(CustomMaps.dir):
			DirAccess.remove_absolute(CustomMaps.dir.path_join(f))
	_run.call_deferred()


func _run() -> void:
	await _frames(10)
	editor.new_map("Probe-Bar", 1, &"bar", "mittel")
	await _frames(5)
	await _shot("e1_draufsicht")
	# Pinsel mit echten Mausereignissen: Wandstück ziehen
	editor.set_brush(&"innenwand")
	var cv := editor.canvas
	var a := cv.global_position + cv.to_screen(Hex.from_offset(8, 10))
	var b := cv.global_position + cv.to_screen(Hex.from_offset(14, 10))
	_mouse(a, true)
	for i in 7:
		_move(a.lerp(b, i / 6.0))
		await _frames(1)
	_mouse(b, false)
	await _frames(2)
	print("Pinsel gezogen: (8..14,10) = %s, Rückgängig-Stufen %d" % [
		range(8, 15).map(func(c: int) -> String: return String(CustomMaps.cell(editor.d, c, 10)[0])), editor._undo.size()])
	# Rechteck: Container 3×2 in Höhe 2
	editor.set_brush(&"container")
	editor.set_tool(&"rechteck")
	editor._press(Vector2i(17, 14))
	editor._drag(Vector2i(19, 15))
	editor._release()
	editor.set_brush(&"kiste")
	editor.set_tool(&"pinsel")
	editor._press(Vector2i(16, 14))
	editor._release()
	print("Rechteck Container: %s, Höhe %d" % [CustomMaps.cell(editor.d, 18, 15)[0], CustomMaps.cell(editor.d, 18, 15)[1]])
	# Startfelder zeichnen: Crew rechts, Gegner links
	editor.set_brush(MapEditor.CREW_MARK)
	for r in range(6, 14):
		editor.paint(Vector2i(25, r))
	editor.set_brush(MapEditor.ENEMY_MARK)
	for r in range(5, 14):
		editor.paint(Vector2i(3, r))
	editor.run_check()
	print("Prüfung: nutzbar %s, Lagen %s, Fehler %s" % [editor.check_res.ok, editor.check_res.lagen, editor.check_res.errors])
	await _frames(3)
	await _shot("e2_gemalt")
	editor.set_view(true)
	await _frames(20)
	await _shot("e3_3d")
	editor.rig.rotate_by(90)
	await get_tree().create_timer(0.6).timeout
	await _shot("e4_3d_gedreht")
	# in 3D malen (Mitte des Bildes)
	editor.set_brush(&"barriere")
	var mid := get_viewport().get_visible_rect().size / 2.0
	var cell: Variant = editor._pick_3d(mid)
	editor._press(cell)
	editor._release()
	await _frames(10)
	print("3D gemalt auf %s: %s" % [cell, CustomMaps.cell(editor.d, cell.x, cell.y)[0] if cell != null else "-"])
	editor.set_view(false)
	editor._active.button_pressed = true
	print("Speichern: %s, Liste %d, aktiv %s" % [editor.save(), CustomMaps.list().size(), CustomMaps.list()[0].active])
	await _frames(3)
	await _shot("e5_gespeichert")
	# leere Raumschiffkarte, Dialog „Neu“
	editor._show_new()
	await _frames(3)
	await _shot("e6_neu_dialog")
	editor._new_dlg.close()
	editor.new_map("Leeres Schiff", 0, &"schiff", "klein", true)
	editor.run_check()
	await _frames(3)
	await _shot("e7_leer_schiff")
	print("Leeres Schiff: nutzbar %s, Lagen %s" % [editor.check_res.ok, editor.check_res.lagen.keys()])
	# Probekampf auf der Bar-Karte
	editor.dirty = false
	editor._select(CustomMaps.list()[0])
	editor._test_battle()
	await get_tree().create_timer(2.0).timeout
	await _frames(10)
	var battle := get_tree().current_scene as Battle
	print("Probekampf: Karte „%s“, Typ %s, Mission %s, Crew-Start gezeichnet %s" % [battle.combat.map.custom_name, battle.combat.map.map_type,
		battle.mission.custom_name, battle.combat.map.crew_start.all(func(t: BattleMap.Tile) -> bool: return t.col == 25) if battle.mission.lage == &"standard" else "Lage " + battle.mission.lage])
	await _shot("e8_probekampf_briefing")
	print("Briefing Orte: %s" % BriefingDialog.place_choices().map(func(c: Array) -> String: return c[1]).slice(-1))
	for f in DirAccess.get_files_at(CustomMaps.dir):
		DirAccess.remove_absolute(CustomMaps.dir.path_join(f))
	print("EDITOR-AUTOTEST FERTIG")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _move(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = get_viewport().get_final_transform() * p
	e.global_position = e.position
	Input.parse_input_event(e)


func _mouse(p: Vector2, pressed: bool) -> void:
	_move(p)
	var e := InputEventMouseButton.new()
	e.position = get_viewport().get_final_transform() * p
	e.global_position = e.position
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	Input.parse_input_event(e)
