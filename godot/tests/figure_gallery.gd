extends SceneTree
## Figurengalerie: alle 12 Figuren nebeneinander, Bilder je Haltung (zum Prüfen von Modellen, Animationen, Waffen).
## godot --path godot --script res://tests/figure_gallery.gd   (Bilder in PTF_OUT)

func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var units: Array[Combatant] = []
	units.append_array(Roster.build_team(GameData.crew(), &"crew"))
	units.append_array(Roster.build_team(GameData.enemies(), &"enemy"))
	var views: Array[UnitView] = []
	for i in units.size():
		var v := UnitView.new()
		root.add_child(v)
		v.setup(units[i])
		v.position = Vector3((i % 6) * 1.6 - 4.0, 0, (i / 6) * 3.0)
		v.set_facing(5, false)
		views.append(v)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.position = Vector3(0.0, 2.6, 8.5)
	cam.look_at(Vector3(0.0, 0.9, 1.5))
	cam.fov = 50
	var light := DirectionalLight3D.new()
	root.add_child(light)
	light.rotation_degrees = Vector3(-50, 25, 0)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.18, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	we.environment = env
	root.add_child(we)
	var out := OS.get_environment("PTF_OUT")
	for i in 10:
		await process_frame
	await _shot(out + "/g1_stehen.png")
	for v in views:
		v.act(&"attack", v.unit.weapons[0])
	await create_timer(0.35).timeout
	await _shot(out + "/g2_angriff.png")
	await create_timer(1.5).timeout
	for v in views:
		v.unit.crouched = true
		v.sync()
	await create_timer(0.6).timeout
	await _shot(out + "/g3_geduckt.png")
	for v in views:
		v.play_down(true)
	await create_timer(1.8).timeout
	await _shot(out + "/g4_tot.png")
	quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(path)
