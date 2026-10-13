class_name UnitPanel
extends VBoxContainer
## Panel der Figur am Zug: Werte, Waffe, Gangart, Angriffsaktivität und Aktionen.
## Meldet Bedienung über action(name, arg); ausgeführt wird in Battle.

signal action(name: StringName, arg: Variant)

var help_open := false


func refresh(c: Combat, pc: PlayerController, u: Combatant, player_turn: bool, grid_on: bool) -> void:
	UiTheme.clear(self)
	if u == null:
		return
	var ai := not player_turn and u.is_ok() and c.result == &""
	_header(u)
	add_child(_bar("TP %d/%d" % [maxi(u.hp, 0), u.max_hp], u.hp, u.max_hp, UiTheme.GOOD if u.hp > u.max_hp / 3 else UiTheme.BAD))
	if u.max_pp:
		add_child(_bar("PP %d/%d" % [u.pp, u.max_pp], u.pp, u.max_pp, Color("b07ae8")))
	var free := u.free_hex + int(u.move_spare)
	add_child(_bar("Aktivität %d %%%s" % [maxi(u.act, 0), (" + %d Hex frei" % free) if free > 0 else ""], maxi(u.act, 0), 100, Color("c9a227")))
	var w := pc.weapon_of(u)
	var stats := HBoxContainer.new()
	stats.add_child(_stat("AW", Rules.skill_total(u, w.skill), "Gesamtbonus der Waffenfertigkeit"))
	stats.add_child(_stat("VW", c.dodge_value(u), "Ausweichen ½ + ½ × übrige Aktivität, + Rüstung (ohne Deckung/Schild)"))
	stats.add_child(_stat("INI", u.init, "Initiative diese Runde"))
	var facing := UiTheme.label("Blick %s" % Hex.DIR_NAMES[u.facing], 13, UiTheme.MUTED)
	facing.tooltip_text = "Blickrichtung (Rechtsklick dreht)"
	facing.mouse_filter = Control.MOUSE_FILTER_PASS
	stats.add_child(facing)
	add_child(stats)
	var status := u.status_list()
	var st := UiTheme.label(" · ".join(status) if status else "keine Effekte", 12, UiTheme.ACCENT if status else UiTheme.MUTED)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(st)
	if ai:
		add_child(UiTheme.label("%s ist am Zug …" % ("Gegner" if not u.is_crew else "KI"), 14, UiTheme.ENEMY if not u.is_crew else UiTheme.CREW))
		return
	if c.result != &"":
		return
	var dis := func(cond: bool) -> bool: return not player_turn or not cond

	add_child(UiTheme.label("Waffe  (Wechsel beim Angriff −%d %%)" % Combat.COST.swap, 12, UiTheme.MUTED))
	var wg := GridContainer.new()
	wg.columns = 2
	var usable := c.usable_weapons(u)
	for wd in u.weapons:
		var extra := ""
		if wd.magazine:
			extra = " (%d/%d, Res. %d)" % [u.loaded.get(wd.id, 0), wd.magazine, u.ammo.get(wd.id, 0)]
		elif wd.pp_cost:
			extra = " (%d PP)" % wd.pp_cost
		var sub := "Nahkampf" if wd.melee else "%d m/Stufe, max %d m" % [wd.inc_m, wd.max_range_m()]
		var b := _btn("%s%s%s\n%s" % [wd.name, extra, " ✓" if wd == u.weapon else "", sub], &"weapon", wd, wd == w, dis.call(usable.has(wd)))
		b.add_theme_font_size_override("font_size", 12)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wg.add_child(b)
	add_child(wg)

	add_child(UiTheme.label("Gangart", 12, UiTheme.MUTED))
	var gr := HBoxContainer.new()
	for g in Combat.GAITS:
		var gd: Dictionary = Combat.GAITS[g]
		var b := _btn("%s\n%s Hex/10 %%" % [gd.name, str(c.pace(u, g)).trim_suffix(".0")], &"gait", g, pc.gait == g and pc.mode == PlayerController.Mode.MOVE, dis.call(c.can_move(u, g)))
		b.tooltip_text = "%s Hex je 10 %%%s" % [str(c.pace(u, g)), (" · Angriff %d" % gd.attack_mod) if gd.attack_mod else (" · kein Angriff danach" if gd.get("no_attack", false) else "")]
		b.add_theme_font_size_override("font_size", 12)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gr.add_child(b)
	add_child(gr)

	var can_atk := pc.can_attack_now(u)
	var pct := pc.attack_pct(u, w)
	add_child(UiTheme.label("Angriff mit %d %% Aktivität (%s)" % [pct, Dice.fmt(Combat.activity_mod(pct))], 12, UiTheme.MUTED))
	var pg := GridContainer.new()
	pg.columns = 9
	for p in [20, 30, 40, 50, 60, 70, 80, 90, 100]:
		var b := _btn("%d\n%s" % [p, Dice.fmt(Combat.activity_mod(p))], &"pct", p, pct == p and can_atk, dis.call(can_atk and p <= pc.max_attack_pct(u, w)))
		b.add_theme_font_size_override("font_size", 11)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pg.add_child(b)
	add_child(pg)

	var ag := GridContainer.new()
	ag.columns = 3
	var add_action := func(text: String, name: StringName, arg: Variant, enabled: bool, sel: bool, tip: String) -> void:
		var b := _btn(text, name, arg, sel, dis.call(enabled))
		b.tooltip_text = tip
		b.add_theme_font_size_override("font_size", 12)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ag.add_child(b)
	add_action.call("Ducken (%d %%)" % Combat.COST.crouch if not u.crouched else "Aufstehen (%d %%)" % Combat.COST.crouch, &"crouch", null, c.can_crouch(u), u.crouched,
		"Geduckt: +%d VW gegen Fernkampf, +%d AW im Fernkampf, halbe Deckung zählt als volle. Nur Gehen mit halber Geschwindigkeit." % [Combat.CROUCH_DB, Combat.CROUCH_OB])
	add_action.call("Abwarten (%d %%)" % Combat.COST.wait, &"wait", null, c.can_wait(u), false,
		"Zug nach hinten schieben. Über die Initiative-Leiste („einspringen“) nach jedem anderen Zug einsetzen, sonst am Rundenende.")
	add_action.call("Feuerbereit", &"overwatch", null, c.can_overwatch(u, w), false,
		"Restliche Aktivität (mind. %d %%) zurückhalten: Schuss auf den ersten Gegner, der im Sichtfeld handelt (%d)." % [Combat.MIN_OVERWATCH, Combat.REACTION_MOD])
	for rw in c.reloadable(u):
		add_action.call("Nachladen (%d %%)" % Combat.COST.reload, &"reload", rw, c.can_do(u, Combat.COST.reload), false, "%s nachladen" % rw.name)
	add_action.call("Erste Hilfe (%d %%)" % Combat.COST.aid, &"aid", null, c.can_do(u, Combat.COST.aid) and not c.first_aid_targets(u).is_empty(),
		pc.mode == PlayerController.Mode.AID, "Benachbarte Figur behandeln (Erste Hilfe, Leicht; Medikit +%d)" % Combat.MEDKIT_BONUS)
	if Rules.skill_rank(u, &"psiWirken") > 0:
		add_action.call("Psi-Schild (%d %%)" % Combat.COST.psi, &"psi", null, c.can_do(u, Combat.COST.psi) and not c.psi_shield_targets(u).is_empty(),
			pc.mode == PlayerController.Mode.PSI, "Psi wirken, %d PP: +%d VW für 1–3 Runden auf eine Figur bis 6 m" % [Combat.PSI_SHIELD_PP, Combat.PSI_SHIELD_BONUS])
	add_action.call("Reichweite (R)", &"range", null, true, pc.show_range, "Zeigt, welche Felder die gewählte Waffe von hier sieht (Farbe = Reichweitenstufe)")
	add_action.call("Raster (G)", &"grid", null, true, grid_on, "Hexraster ein-/ausblenden")
	add_action.call("Ausrichten", &"face", null, true, pc.mode == PlayerController.Mode.FACE, "Feld anklicken, in dessen Richtung die Figur schauen soll (kostenlos). Alternativ Rechtsklick.")
	add_child(ag)
	var end := _btn("Zug beenden%s" % ((" (%d %% → Ausweichen)" % u.act) if u.act > 0 else ""), &"end", null, false, not player_turn)
	end.tooltip_text = "Enter. Übrige Aktivität zählt bis zum nächsten Zug als Ausweichen."
	if u.act < 10 and free <= 0:
		end.add_theme_color_override("font_color", UiTheme.ACCENT)
	add_child(end)
	var hint := _hint(pc)
	if hint != "":
		var l := UiTheme.label(hint, 12, UiTheme.ACCENT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(l)
	else:
		var hb := UiTheme.button("▸ Hilfe" if not help_open else "▾ Hilfe")
		hb.flat = true
		hb.alignment = HORIZONTAL_ALIGNMENT_LEFT
		hb.add_theme_font_size_override("font_size", 12)
		hb.pressed.connect(func() -> void:
			help_open = not help_open
			action.emit(&"refresh", null))
		add_child(hb)
		if help_open:
			var l := UiTheme.label("Maus über ein blaues Feld: grüne Linien = von dort treffbar, rote Linien = wer dich dort treffen kann. Blaue Felder: Bewegung (Kosten im Tooltip). Rot umrandet: angreifbar. Rechtsklick: Figur drehen. Sichtfeld 180° nach vorne – Angriffe von der Seite (+15) oder hinten (+30) überraschen.\nHandy: ziehen = verschieben, zwei Finger = zoomen, antippen = Vorschau, nochmal antippen = ausführen, lange drücken = drehen.", 12, UiTheme.MUTED)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			add_child(l)


func _hint(pc: PlayerController) -> String:
	match pc.mode:
		PlayerController.Mode.AID:
			return "Grün markierte Figur anklicken. Esc bricht ab."
		PlayerController.Mode.PSI:
			return "Grün markierte Figur für den Psi-Schild anklicken."
		PlayerController.Mode.FACE:
			return "Feld anklicken, in dessen Richtung die Figur schauen soll."
	return ""


func _header(u: Combatant) -> void:
	var row := HBoxContainer.new()
	row.add_child(UiTheme.badge(u.letter, u.color, 32))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UiTheme.label(u.name, 16, UiTheme.CREW if u.is_crew else UiTheme.ENEMY))
	col.add_child(UiTheme.label("%s · %s" % [u.role, "Crew" if u.is_crew else "Gegner"], 12, UiTheme.MUTED))
	row.add_child(col)
	if u.is_crew:
		var b := UiTheme.button("Bogen", "Charakterbogen")
		b.pressed.connect(action.emit.bind(&"sheet", u))
		row.add_child(b)
	add_child(row)


func _bar(text: String, v: int, max_v: int, color: Color) -> Control:
	var pb := ProgressBar.new()
	pb.max_value = maxi(max_v, 1)
	pb.value = clampi(v, 0, max_v)
	pb.show_percentage = false
	pb.custom_minimum_size.y = 20
	pb.add_theme_stylebox_override("fill", UiTheme.box(Color(color, 0.75), color, 4, 0, 0))
	var l := UiTheme.label(text, 12, Color.WHITE)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.offset_left = 6
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pb.add_child(l)
	return pb


func _stat(name: String, v: int, tip: String) -> Label:
	var l := UiTheme.label("%s %d" % [name, v], 14)
	l.tooltip_text = tip
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _btn(text: String, name: StringName, arg: Variant, selected: bool, disabled: bool) -> Button:
	var b := UiTheme.button(text)
	b.toggle_mode = true
	b.button_pressed = selected
	b.disabled = disabled
	b.pressed.connect(action.emit.bind(name, arg))
	return b
