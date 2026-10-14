extends Node
## Selbsttests mit Screenshots (Zielordner in der Umgebungsvariable PTF_OUT):
##   godot --path godot -- --autotest          KI gegen KI, Kampfende, Charakterbogen, Tabellen
##   godot --path godot -- --autotest-player   Bedienung mit simulierten Mausklicks
## Optional: PTF_SECONDS = maximale Kampfdauer im KI-Test.

var battle: Battle
var b: Battle:
	get:
		return battle


func _ready() -> void:
	if "--autotest-player" in OS.get_cmdline_user_args():
		_run_player.call_deferred()
	else:
		_run_ai.call_deferred()



func _run_ai() -> void:
	var out := OS.get_environment("PTF_OUT")
	if out == "":
		out = "user://"
	b.new_battle(4711, "mittel")
	for i in 40:
		await get_tree().process_frame
	await _screenshot(out + "/00_briefing.png")
	b.ui.briefing.close()
	# Runde 0: erste Figur auf ein anderes Feld im Eingangsbereich stellen (per Mausklick)
	var crew0: Combatant = b.combat.crew()[0]
	var zone := b.combat.deploy_tiles()
	var target: Vector2i = zone[zone.size() - 1]
	for p in zone:
		if b.combat.unit_at(p) == null and b._pick(b.rig.camera.unproject_position(b.map_view.tile_top(p))).tile == p:
			target = p
	_mouse_click(b.rig.camera.unproject_position(b.map_view.tile_top(target)))
	await get_tree().create_timer(0.3).timeout
	print("Aufstellung: %s steht auf %s (Ziel %s)" % [crew0.name, crew0.pos, target])
	await _screenshot(out + "/01_aufstellung.png")
	# Buttons im Panel rechts mit echten Mausklicks bedienen
	var crew1: Combatant = b.combat.crew()[1]
	await _click_button(crew1.name)
	print("Panel: gewählt %s (erwartet %s)" % [b.deploy_sel.name if b.deploy_sel else "-", crew1.name])
	var f0 := crew1.facing
	await _click_button("drehen ⟳")
	print("Panel: Blick %d -> %d" % [f0, crew1.facing])
	await _click_button("Briefing")
	print("Panel: Briefing offen ", b.ui.briefing.visible)
	await _click_button("Zur Aufstellung")
	print("Panel: Briefing zu ", not b.ui.briefing.visible)
	await _click_button("Kampf beginnen")
	print("Panel: Kampf begonnen ", not b.combat.deploying)
	if b.combat.deploying:
		b.begin_combat()
	var shots := 1
	var t0 := Time.get_ticks_msec()
	b.auto_crew = true
	b.ui.set_toggle(&"auto", true)
	var last_print := 0
	var limit := int(OS.get_environment("PTF_SECONDS")) * 1000 if OS.get_environment("PTF_SECONDS") != "" else 120000
	while b.combat.result == &"" and Time.get_ticks_msec() - t0 < limit:
		await get_tree().create_timer(0.5).timeout
		if Time.get_ticks_msec() - last_print > 10000:
			last_print = Time.get_ticks_msec()
			print("t=%ds Runde %d, %d fps, %d Zeichenaufrufe" % [(last_print - t0) / 1000, b.combat.round_no, Engine.get_frames_per_second(),
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
		if b.ui.dice_panel.visible and shots == 1:
			shots += 1
			await _screenshot(out + "/02_wuerfel.png")
		if Time.get_ticks_msec() - t0 > 20000 and shots == 2:
			shots += 1
			b.rig.rotate_by(90)
			await get_tree().create_timer(0.6).timeout
			await _screenshot(out + "/03_gedreht.png")
	print("Kampf: ", b.combat.result, " nach Runde ", b.combat.round_no)
	if b.combat.result == &"":
		# Kampfende erzwingen, um den Abschluss zu prüfen
		for e in b.combat.enemies():
			e.state = Combatant.State.DEAD
		b.combat.check_end()
	await get_tree().create_timer(2.0).timeout
	await _screenshot(out + "/04_ende.png")
	var ed := b.ui.end_dialog
	var cu := ed.current()
	print("Übersicht: %s, freie EP %d" % [cu.name, cu.free_xp])
	cu.free_xp += 20
	var kon_before: int = cu.attrs.KON
	Rules.raise_attr(cu, "KON")
	ed.page(0)
	ed.page(1)
	ed.page(-1)
	print("KON %d -> %d, freie EP jetzt %d" % [kon_before, cu.attrs.KON, cu.free_xp])
	await get_tree().create_timer(0.3).timeout
	await _screenshot(out + "/04b_uebersicht.png")
	await _click_button("+5")
	print("Eingezahlt: freie EP jetzt %d" % cu.free_xp)
	await _click_button("Charakterbogen")
	print("Bogen über Übersicht offen: ", b.ui.sheet.visible and b.ui.end_dialog.visible)
	await _screenshot(out + "/04d_bogen_ueber_uebersicht.png")
	b.ui.sheet.close()
	ed.page(2)
	await get_tree().create_timer(0.3).timeout
	await _screenshot(out + "/04c_uebersicht_seite3.png")
	var xp_before: int = b.combat.crew()[0].skills.get(&"kampfsinn", {}).get("xp", 0)
	b.ui.end_dialog.next_battle.emit()
	b.ui.end_dialog.hide()
	for i in 20:
		await get_tree().process_frame
	var saved := Roster.load_progress()
	print("Gespeichert: KON ", saved[cu.id].attrs.get("KON"), ", freie EP ", saved[cu.id].free_xp)
	b.ui.briefing.close()
	print("Gespeichert: ", saved.size(), " Figuren, Kampfsinn-EP Vela vorher ", xp_before, ", jetzt ", b.combat.crew()[0].skills.get(&"kampfsinn", {}).get("xp", 0))
	b.ui.sheet.show_sheet(b.combat.crew(), b.combat.crew()[0])
	await get_tree().create_timer(0.3).timeout
	await _screenshot(out + "/05_bogen.png")
	b.ui.sheet.hide()
	b.ui.tables.show_tables()
	await get_tree().create_timer(0.3).timeout
	await _screenshot(out + "/06_tabellen.png")
	print("AUTOTEST FERTIG")
	get_tree().quit()


func _screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	b.get_viewport().get_texture().get_image().save_png(path)


## Selbsttest der Bedienung: Maus über ein Feld (Vorschau), Klick = bewegen, Maus über Gegner, Klick = angreifen
func _run_player() -> void:
	var out := OS.get_environment("PTF_OUT")
	b.new_battle(4711, "klein", "", false)
	b.begin_combat()
	for i in 30:
		await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	while not b.player_turn() and Time.get_ticks_msec() - t0 < 60000:
		await get_tree().create_timer(0.3).timeout
	var u := b.combat.current
	print("Spieler am Zug: ", u.name)
	# Feld mit bester Trefferchance in Reichweite suchen
	var r := b.player.reach(u)
	var best: Variant = null
	var best_c := -1
	for p in r.dest:
		if p == u.pos:
			continue
		if b._pick(b.rig.camera.unproject_position(b.map_view.tile_top(p))).tile != p:
			continue  # auf dem Bildschirm verdeckt
		var pv := b.player.preview_for(u, p, r.path_to(p))
		for t in pv.hit:
			if pv.hit[t] > best_c:
				best_c = pv.hit[t]
				best = p
	if best == null:
		best = r.dest.keys()[r.dest.size() - 1]
	var sp := b.rig.camera.unproject_position(b.map_view.tile_top(best))
	_mouse_move(sp)
	await get_tree().create_timer(0.4).timeout
	print("Tooltip Feld: ", b.ui.info.text().replace("\n", " | ").left(300))
	await _screenshot(out + "/p1_vorschau.png")
	_mouse_click(sp)
	await get_tree().create_timer(0.2).timeout
	while not b.events.is_idle():
		await get_tree().process_frame
	print("bewegt nach ", u.pos, " (Ziel ", best, "), Aktivität ", u.act)
	await get_tree().create_timer(0.3).timeout
	# angreifbaren Gegner suchen
	var target: Combatant = null
	for e in b.combat.opponents(u):
		var w := b.player.weapon_of(u)
		if b.combat.attack_info(u, e, w, {"pct": b.player.attack_pct(u, w)}).valid:
			target = e
			break
	if target:
		b.rig.focus(b.views[target].position.lerp(b.views[u].position, 0.5), false)
		await get_tree().create_timer(0.5).timeout
		var tp := b.rig.camera.unproject_position(b.views[target].position + Vector3(0, 1.0, 0))
		_mouse_move(tp)
		await get_tree().create_timer(0.4).timeout
		print("Tooltip Gegner: ", b.ui.info.text().replace("\n", " | ").left(400))
		await _screenshot(out + "/p2_ziel.png")
		_mouse_click(tp)
		await get_tree().create_timer(0.6).timeout
		await _screenshot(out + "/p3_wuerfel.png")
		while not b.events.is_idle():
			await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		await _screenshot(out + "/p4_nach_angriff.png")
		print("nach Angriff: ", target.name, " TP ", target.hp, ", Aktivität ", u.act)
	else:
		print("kein Gegner angreifbar")
	print("AUTOTEST FERTIG")
	get_tree().quit()


## Bildschirmkoordinaten der Szene in Fensterkoordinaten (Skalierung durch stretch/canvas_items)
func _to_window(p: Vector2) -> Vector2:
	return b.get_viewport().get_final_transform() * p


func _mouse_move(p: Vector2) -> void:
	p = _to_window(p)
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	Input.parse_input_event(e)


func _mouse_click(p: Vector2) -> void:
	p = _to_window(p)
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = p
		e.global_position = p
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		Input.parse_input_event(e)


## Sichtbaren Button mit passendem Text suchen und mit der Maus anklicken
func _click_button(text: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var found: Button = null
	for n in b.ui.find_children("*", "Button", true, false):
		var btn := n as Button
		if btn.is_visible_in_tree() and btn.text.contains(text):
			found = btn
			break
	if found == null:
		print("Button nicht gefunden: ", text)
		return
	_mouse_click(found.get_global_rect().get_center())
	await get_tree().create_timer(0.3).timeout
