extends Node
## Selbsttests mit Screenshots (Zielordner in der Umgebungsvariable PTF_OUT):
##   godot --path godot -- --autotest          KI gegen KI, Kampfende, Charakterbogen, Tabellen
##   godot --path godot -- --autotest-player   Bedienung mit simulierten Mausklicks
##   godot --path godot -- --autotest-psi      Psi-Zeile und Kontextmenü (Nyx)
##   godot --path godot -- --autotest-maps     alle Kartentypen (Übersicht, Nahansicht) und Startlagen aufbauen
## Optional: PTF_SECONDS = maximale Kampfdauer im KI-Test.

var battle: Battle
var b: Battle:
	get:
		return battle


func _ready() -> void:
	if "--autotest-player" in OS.get_cmdline_user_args():
		_run_player.call_deferred()
	elif "--autotest-psi" in OS.get_cmdline_user_args():
		_run_psi.call_deferred()
	elif "--autotest-maps" in OS.get_cmdline_user_args():
		_run_maps.call_deferred()
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
	# Anzeige Verwundeter (nur für den Screenshot, danach zurückgesetzt): angeschlagen markiert, schwer verwundet gesperrt
	var hurt: Character = Campaign.crew()[1]
	var down: Character = Campaign.crew()[3]
	hurt.injury = Injury.LIGHT
	hurt.injury_days = 2
	down.injury = Injury.SEVERE
	down.injury_days = 9
	var cands := Campaign.candidates(false)
	b.ui.briefing.show_mission(b.mission, cands, Campaign.suggested_squad(cands))
	for i in 5:
		await get_tree().process_frame
	print("Truppwahl verwundet: gesperrt %d, markiert %d, vorbelegt %d, %s gewählt %s" % [
		cands.filter(func(k: Dictionary) -> bool: return k.locked).size(), cands.filter(func(k: Dictionary) -> bool: return k.marked).size(),
		b.ui.briefing.selection().size(), down.name, down in b.ui.briefing.selection()])
	_mouse_click(b.ui.briefing._tiles[down].get_global_rect().get_center())
	await get_tree().create_timer(0.3).timeout
	print("Truppwahl: Klick auf Gesperrte ändert nichts %s" % (not down in b.ui.briefing.selection()))
	await _screenshot(out + "/00a_trupp_verwundet.png")
	for c in [hurt, down]:
		c.injury = Injury.NONE
		c.injury_days = 0
	b.ui.briefing.show_mission(b.mission, b.candidates, b.squad)
	for i in 5:
		await get_tree().process_frame
	# Truppwahl: letzte Figur per Klick abwählen, mit 5 in die Aufstellung
	var last_ch: Character = b.squad[b.squad.size() - 1]
	_mouse_click(b.ui.briefing._tiles[last_ch].get_global_rect().get_center())
	await get_tree().create_timer(0.3).timeout
	print("Truppwahl: %d gewählt, Knopf „%s“" % [b.ui.briefing.selection().size(), b.ui.briefing._go.text])
	await _screenshot(out + "/00b_trupp_5.png")
	await _click_button("Mit 5 zur Aufstellung")
	print("Truppwahl: Runde 0 mit %d Figuren (erwartet 5), gemerkt %d, Briefing zu %s" % [b.combat.crew().size(), Campaign.chosen_squad.size(), not b.ui.briefing.visible])
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
	_mouse_click(b.ui.briefing._tiles[last_ch].get_global_rect().get_center())
	await get_tree().create_timer(0.3).timeout
	await _click_button("Zur Aufstellung")
	print("Panel: Briefing zu %s, Truppwahl: wieder %d Figuren (erwartet 6)" % [not b.ui.briefing.visible, b.combat.crew().size()])
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
	var t0_banner := Time.get_ticks_msec()
	while not b.ui.result_banner.visible and Time.get_ticks_msec() - t0_banner < 10000:
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	print("Ergebnis-Banner: ", b.ui.result_banner.visible)
	await _screenshot(out + "/04_ende.png")
	await _click_button("Zur Crew")
	# Kampfmodul gibt das Ergebnis ab und wechselt ins Charakter-Modul
	var t0_scene := Time.get_ticks_msec()
	while not (get_tree().current_scene is CrewScreen) and Time.get_ticks_msec() - t0_scene < 10000:
		await get_tree().process_frame
	var cs := get_tree().current_scene as CrewScreen
	print("Charakter-Modul offen: ", cs != null, ", Ergebnis: ", Campaign.last_result.get("outcome", ""))
	for i in 10:
		await get_tree().process_frame
	var ed := cs.overview
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
	print("Bogen über Übersicht offen: ", cs.sheet.visible and ed.visible)
	await _screenshot(out + "/04d_bogen_ueber_uebersicht.png")
	cs.sheet.close()
	ed.page(2)
	await get_tree().create_timer(0.3).timeout
	await _screenshot(out + "/04c_uebersicht_seite3.png")
	# Übersicht der Psi-Listen: Seite einer Psi-Figur, dann der Dialog
	var psi_idx := -1
	for i in ed._crew.size():
		if psi_idx < 0 and not PsiLists.learned(ed._crew[i]).is_empty():
			psi_idx = i
	if psi_idx >= 0:
		ed.page(psi_idx - ed._idx)
		await get_tree().create_timer(0.3).timeout
		await _screenshot(out + "/04f_uebersicht_psi.png")
		ed.psi_view().open_for(ed.current(), &"")
		ed.psi_view().move_to_front()
		print("Psi-Listen offen: ", ed.psi_view().visible, " für ", ed.current().name)
		await get_tree().create_timer(0.3).timeout
		await _screenshot(out + "/04g_psi_listen.png")
		ed.psi_view().close()
		var enc := Encyclopedia.show_on(ed, &"psi", "Angriff")
		enc.move_to_front()
		print("Enzyklopädie aus der Übersicht offen: ", enc.visible)
		await get_tree().create_timer(0.3).timeout
		await _screenshot(out + "/04h_enzyklopaedie_psi.png")
		enc.close()
	# Roster: Figur erschaffen (Editor im Roster-Modus), anheuern, entlassen; danach wieder aus dem Roster löschen
	var ce := cs.editor
	ce.open_for_roster()
	ce.move_to_front()
	print("Editor offen: ", ce.visible, ", Punkte ", Creation.budget(ce._ch))
	for id in [&"gewehre", &"gewehre", &"ausweichen", &"psiAngriff", &"lAngriff", &"lAngriff", &"koerper"]:
		Creation.raise(ce._ch, id)
	ce._ch.name = "Testfigur"
	ce._render()
	await get_tree().create_timer(0.3).timeout
	await _screenshot(out + "/04e_editor.png")
	ce._finish()
	var tf: Array = GlobalRoster.own().filter(func(c: Character) -> bool: return c.name == "Testfigur")
	print("Roster: Testfigur gespeichert ", not tf.is_empty())
	var before := Campaign.crew().size()
	Campaign.hire(tf[0])
	ed._crew = Campaign.crew()
	ed._reopen()
	var hired := Campaign.crew().filter(func(c: Character) -> bool: return c.name == "Testfigur")
	print("Anheuern: Crew %d -> %d, Testfigur an Bord %s" % [before, Campaign.crew().size(), not hired.is_empty()])
	if not hired.is_empty():
		Campaign.fire(hired[0])
		ed._crew = Campaign.crew()
		ed._reopen()
	print("Entlassen: Crew %d, im Hafen %d" % [Campaign.crew().size(), Campaign.harbor().size()])
	for h in Campaign.harbor().duplicate():
		if h.name == "Testfigur":
			Campaign.harbor().erase(h)
	Campaign.save()
	for c in tf:
		GlobalRoster.remove(c.id)
	ed.next_battle.emit()
	var t0_battle := Time.get_ticks_msec()
	while not (get_tree().current_scene is Battle) and Time.get_ticks_msec() - t0_battle < 10000:
		await get_tree().process_frame
	battle = get_tree().current_scene as Battle
	for i in 20:
		await get_tree().process_frame
	var saved := Roster.load_crew()
	var sv: Character = saved.filter(func(c: Character) -> bool: return c.id == cu.id)[0]
	print("Gespeichert: KON ", sv.attrs.KON, ", freie EP ", sv.free_xp)
	b.ui.briefing.close()
	var nu: Combatant = b.combat.crew().filter(func(c: Combatant) -> bool: return c.id == cu.id)[0]
	print("Neuer Kampf: %d Figuren, KON von %s im Kampf %d" % [b.combat.crew().size(), nu.name, nu.attrs.KON])
	b.ui.sheet.show_sheet(b.combat.crew(), b.combat.crew()[0])
	await get_tree().create_timer(0.3).timeout
	await _screenshot(out + "/05_bogen.png")
	b.ui.sheet.hide()
	b.ui.show_encyclopedia(b.combat.crew()[0].weapons[0])
	await get_tree().create_timer(0.3).timeout
	print("Enzyklopädie (Tabellen): offen %s, Bereich %s, Eintrag %s" % [b.ui.encyclopedia().visible, b.ui.encyclopedia().section, b.ui.encyclopedia().entry])
	await _screenshot(out + "/06_tabellen.png")
	print("AUTOTEST FERTIG")
	get_tree().quit()


func _screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)


## Selbsttest der Bedienung: Maus über ein Feld (Vorschau), Klick = bewegen, Maus über Gegner, Klick = angreifen
func _run_player() -> void:
	var out := OS.get_environment("PTF_OUT")
	b.new_battle(4711, "klein", "", false)
	for i in 10:
		await get_tree().process_frame
	# Aufstellung: Tab wählt die nächste Figur, Shift+Tab die vorige
	var first := b.deploy_sel
	b.ui.briefing.hide()   # im Spiel ist das Briefing in der Aufstellung geschlossen
	_key(KEY_TAB)
	await get_tree().create_timer(0.2).timeout
	var second := b.deploy_sel
	_key(KEY_TAB, true)
	await get_tree().create_timer(0.2).timeout
	print("Tab in der Aufstellung: %s → %s → zurück %s" % [first.name, second.name, b.deploy_sel.name])
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
	# F: sichtbare Gegner durchschalten (Vorschau im Infokasten)
	_key(KEY_F)
	await get_tree().create_timer(0.5).timeout
	print("F: Ziel %s | %s" % [b._target.name if b._target else "keins", b.ui.info.text().replace("\n", " | ").left(200)])
	await _screenshot(out + "/p1b_ziel_f.png")
	_key(KEY_F)
	await get_tree().process_frame
	print("F nochmal: Ziel %s" % (b._target.name if b._target else "keins"))
	# Leertaste greift das gewählte Ziel an (nur wenn angreifbar; sonst passiert nichts)
	var sel := b._target
	var w0 := b.player.weapon_of(u)
	var ok: bool = sel != null and b.combat.attack_info(u, sel, w0, {"pct": b.player.attack_pct(u, w0)}).valid
	var act0 := u.act
	_key(KEY_SPACE)
	await get_tree().create_timer(0.3).timeout
	while not b.events.is_idle():
		await get_tree().process_frame
	print("Leertaste: Ziel %s angreifbar %s, Aktivität %d → %d" % [sel.name if sel else "-", ok, act0, u.act])
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
	await _repair_shot(out, u)
	await _status_shot(out, u)
	# Tab beendet den Zug
	_key(KEY_TAB)
	await get_tree().process_frame
	print("Tab im Kampf: am Zug jetzt %s (vorher %s)" % [b.combat.current.name if b.combat.current else "-", u.name])
	print("AUTOTEST FERTIG")
	get_tree().quit()


## Waffen-Reparatur: Waffe 1 unbrauchbar machen (nur für das Bild), Knopf zeigen und anklicken
func _repair_shot(out: String, u: Combatant) -> void:
	if b.combat.current != u or not u.is_ok():
		print("Reparatur: Figur nicht mehr am Zug")
		return
	u.act = 100
	u.wear["w0"] = Combatant.WEAR_BROKEN
	ActionPanel.set_open(&"more", true)
	b._refresh()
	await get_tree().create_timer(0.3).timeout
	await _screenshot(out + "/p4b_reparatur.png")
	await _click_button("Reparieren")
	while not b.events.is_idle():
		await get_tree().process_frame
	print("Reparatur: %s Waffe 1 jetzt %d, Aktivität %d, nochmal möglich %s" % [u.name, int(u.wear.get("w0", 0)), u.act,
		b.combat.repair_targets(u).any(func(t: Dictionary) -> bool: return t.unit == u and t.slot == "w0")])


## Zustandssymbole und -effekte: Zustände setzen (nur für das Bild), Symbole zählen, Screenshot
func _status_shot(out: String, u: Combatant) -> void:
	var foes := b.combat.opponents(u).filter(func(o: Combatant) -> bool: return o.is_ok())
	var mates := b.combat.units.filter(func(o: Combatant) -> bool: return o.team == u.team and o != u and o.is_ok())
	if foes.is_empty() or mates.is_empty():
		print("Status: keine Figuren für das Bild")
		return
	var f: Combatant = foes[0]
	f.bleed = 3
	f.stun = 2
	f.malus = -20
	f.prone = true
	f.disarmed = true
	f.buffs["geortet"] = {"rounds": 3, "team": u.team}
	u.psi_shield = 2
	u.buffs["abschirmen"] = {"rounds": 3, "val": 10}
	var m: Combatant = mates[0]
	m.state = Combatant.State.DYING
	m.hp = -4
	for o in [f, u, m]:
		b.views[o].sync()
	b.rig.focus(b.views[f].position.lerp(b.views[u].position, 0.5), false)
	await get_tree().create_timer(0.8).timeout
	var shown := func(o: Combatant) -> int:
		return b.views[o]._status._icons.filter(func(s: Sprite3D) -> bool: return s.visible).size()
	print("Status: Gegner %d Symbole (+%s), am Zug %d, sterbend %d" % [shown.call(f), b.views[f]._status._more.text, shown.call(u), shown.call(m)])
	await _screenshot(out + "/p5_status.png")


## Psi-Bedienung: Nyx an den Zug setzen, Psi-Zeile, Reiter Schutz, Rechtsklick auf Verbündete (Kontextmenü), Psi-Schild wirken
func _run_psi() -> void:
	var out := OS.get_environment("PTF_OUT")
	b.new_battle(4711, "klein", "", false)
	b.begin_combat()
	print("Psi: Kampf begonnen")
	var t0 := Time.get_ticks_msec()
	while not b.player_turn() and Time.get_ticks_msec() - t0 < 60000:
		await get_tree().create_timer(0.3).timeout
	var c := b.combat
	print("Psi: Spieler am Zug %s nach %d ms" % [b.player_turn(), Time.get_ticks_msec() - t0])
	var nyx: Combatant = c.crew().filter(func(u: Combatant) -> bool: return u.id == &"nyx")[0]
	c.turn_idx = c.order.find(nyx)
	c._begin_turn(nyx)
	b.events.views = b.views
	for u in b.views:
		b.views[u].set_current(u == nyx, true)
	b.rig.focus(b.views[nyx].position, true)
	b._dirty = true
	for i in 20:
		await get_tree().process_frame
	print("Psi: am Zug %s, Kräfte %s, Angriffskräfte %s" % [c.current.name, nyx.powers, nyx.weapons.filter(func(w: WeaponData) -> bool: return w.power != "").map(func(w: WeaponData) -> String: return w.name)])
	await _screenshot(out + "/s1_psi_zeile.png")
	if not ActionPanel.is_open(&"psi"):
		await _click_button("PSI ·")
	await _click_button("Schutz 4")
	await get_tree().create_timer(0.3).timeout
	await _screenshot(out + "/s2_reiter_schutz.png")
	var ally: Combatant = null
	for o in c.crew():
		if o != nyx and c.power_targets(nyx, "lSchutz/2").has(o):
			ally = o
			break
	print("Psi: Ziel für Psi-Schild: ", ally.name if ally else "-")
	if ally:
		var p := b.rig.camera.unproject_position(b.views[ally].position + Vector3(0, 1.0, 0))
		p = _to_window(p)
		for pressed in [true, false]:
			var e := InputEventMouseButton.new()
			e.position = p
			e.global_position = p
			e.button_index = MOUSE_BUTTON_RIGHT
			e.pressed = pressed
			Input.parse_input_event(e)
		await get_tree().create_timer(0.4).timeout
		print("Psi: Kontextmenü offen ", b.ui.context_menu.visible)
		await _screenshot(out + "/s3_kontextmenue.png")
		await _click_button("Psi-Schild", b.ui.context_menu)
		while not b.events.is_idle():
			await get_tree().process_frame
		await get_tree().create_timer(0.5).timeout
		print("Psi: nach Psi-Schild: %s Psi-Schild %d, Nyx PP %d, Aktivität %d" % [ally.name, ally.psi_shield, nyx.pp, nyx.act])
		await _screenshot(out + "/s4_nach_psi_schild.png")
	print("AUTOTEST FERTIG")
	get_tree().quit()


## Bildschirmkoordinaten der Szene in Fensterkoordinaten (Skalierung durch stretch/canvas_items)
## Kartentypen: jeden Typ (und die Abwehr an Bord) aufbauen, Übersicht und Nahansicht fotografieren
func _run_maps() -> void:
	var out := OS.get_environment("PTF_OUT")
	var i := 0
	for ty in MapTypes.GROUND + [MapTypes.SHIP]:
		b.new_battle(4711 + i, "mittel", "", false, null, ty)
		b.ui.briefing.hide()
		for k in 20:
			await get_tree().process_frame
		var m := b.combat.map
		print("Karte %s: %d×%d, Crew-Start %d, Gegner-Start %d, Titel „%s“" % [ty, m.cols, m.rows, m.crew_start.size(), m.enemy_start.size(), b.mission.title])
		b.rig.focus(b.map_view.center(), true)
		b.rig.zoom_at(get_viewport().get_visible_rect().size / 2.0, 1 / 1.6)
		await get_tree().create_timer(0.5).timeout
		await _screenshot(out + "/m%d_%s.png" % [i, ty])
		b.rig.zoom_at(get_viewport().get_visible_rect().size / 2.0, 2.6)
		await get_tree().create_timer(0.5).timeout
		await _screenshot(out + "/m%d_%s_nah.png" % [i, ty])
		i += 1
	# Startlagen in der Lagerhalle (Aufstellung: blaue Felder der Crew, Gegner)
	for lage in [&"hinterhalt", &"zange", &"verteilt", &"verteidigung"]:
		var mi := Mission.generate(4711)
		mi.map_type = &"halle"
		mi.size_id = "mittel"
		mi.square = false
		mi.lage = lage
		b.new_battle(4711, "", "", false, mi)
		b.ui.briefing.hide()
		for k in 20:
			await get_tree().process_frame
		print("Lage %s: Crew-Start %d, Gegner-Start %d" % [lage, b.combat.map.crew_start.size(), b.combat.map.enemy_start.size()])
		b.rig.focus(b.map_view.center(), true)
		b.rig.zoom_at(get_viewport().get_visible_rect().size / 2.0, 1 / 1.8)
		await get_tree().create_timer(0.5).timeout
		await _screenshot(out + "/l_%s.png" % lage)
	print("AUTOTEST FERTIG")
	get_tree().quit()


## Taste drücken (wie vom Spieler)
func _key(code: Key, shift := false) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.shift_pressed = shift
	e.pressed = true
	Input.parse_input_event(e)
	var r := e.duplicate() as InputEventKey
	r.pressed = false
	Input.parse_input_event(r)


func _to_window(p: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * p


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
## root = nur Knöpfe darunter (null = ganze Szene)
func _click_button(text: String, root: Node = null) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var found: Button = null
	for n in (root if root else get_tree().current_scene).find_children("*", "Button", true, false):
		var btn := n as Button
		if btn.is_visible_in_tree() and btn.text.contains(text):
			found = btn
			break
	if found == null:
		print("Button nicht gefunden: ", text)
		return
	_mouse_click(found.get_global_rect().get_center())
	await get_tree().create_timer(0.3).timeout
