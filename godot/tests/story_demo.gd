extends Control
## Demo der Story-Engine mit der Test-Kette (im Editor: Szene öffnen, F6). Ohne Spielstand, Test-Crew, 1000 Credits.
## Screenshots (Zielordner PTF_OUT): godot --path godot res://tests/story_demo.tscn -- --shot

var story: Story


func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Hintergrund wie im Mockup (im Spiel liegt hier das Schiff)
	var grad := Gradient.new()
	grad.set_color(0, Color("2a3a62"))
	grad.set_color(1, Color("070a12"))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 1)
	var bg := TextureRect.new()
	bg.texture = gt
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	story = Story.create()
	story.res.credits = 1000
	story.crew_override = [_member("Mara", 6), _member("Jax", 2), _member("Ivo", 0)]
	story.start("test_kette")
	var d := StoryDialog.show_on(self, story, "test_kette")
	d.finished.connect(func(_id: String) -> void: StoryLog.show_on(self, story, 3))
	if "--shot" in OS.get_cmdline_user_args():
		_shots.call_deferred(d)


func _member(n: String, verhandeln: int) -> Character:
	var ch := Character.new()
	ch.id = StringName(n)
	ch.name = n
	ch.letter = n.left(1)
	ch.color = {"Mara": Color("f2c94c"), "Jax": Color("56ccf2"), "Ivo": Color("bb6bd9")}.get(n, Color.WHITE)
	for a in Rules.ATTRIBUTES:
		ch.attrs[a.id] = 55
	ch.skills[&"verhandeln"] = {"rank": verhandeln, "xp": 0}
	ch.skills[&"gassenwissen"] = {"rank": 3, "xp": 0}
	return ch


func _shots(d: StoryDialog) -> void:
	Voyage.fixed_result = &"erfolg"
	await _shot("st1_szene")
	d._on_choice(story.view("test_kette").choices[1])
	await _shot("st2_wuerfler")
	d._show_result(story.choose("test_kette", 1, story.crew_override[1]))
	await _shot("st3_ergebnis")
	story.state.add_log(story.today(), "hinweis", "test_kette", "Platzhalter: Der Mittelsmann arbeitet nicht allein.")
	story.reveal("test_ort")
	var log := StoryLog.show_on(self, story, 0)
	await _shot("st4_log_auftraege")
	for i in [1, 2, 3]:
		log.tab = i
		log._fill()
		await _shot("st%d_log_%s" % [4 + i, ["", "hinweise", "ziele", "verlauf"][i]])
	log.close()
	story.state.chains.test_ort.status = ""
	story.start("test_ort")
	d.show_chain(story, "test_ort")
	await _shot("st8_langer_text")
	get_tree().quit()


func _shot(file: String) -> void:
	for i in 8:
		await get_tree().process_frame
	var out := OS.get_environment("PTF_OUT")
	if out == "":
		out = "user://"
	get_viewport().get_texture().get_image().save_png(out.path_join(file + ".png"))
