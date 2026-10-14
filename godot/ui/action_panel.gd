class_name ActionPanel
extends PanelContainer
## Aktionsblock unten rechts: Waffe, Gangart, Angriffsaktivität, Aktionen, Zug beenden.
## In Runde 0 stattdessen die Aufstellung. Meldet Bedienung über action(name, arg); ausgeführt wird in Battle.

signal action(name: StringName, arg: Variant)

var _box: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.94), UiTheme.LINE, 12, 12))
	custom_minimum_size.x = 720
	mouse_filter = Control.MOUSE_FILTER_STOP
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	add_child(_box)


func refresh(c: Combat, pc: PlayerController, u: Combatant, player_turn: bool) -> void:
	UiTheme.clear(_box)
	if u == null or c.result != &"":
		hide()
		return
	show()
	var dis := func(cond: bool) -> bool: return not player_turn or not cond
	var w := pc.weapon_of(u)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	var wcol := _group("WAFFE  (Wechsel beim Angriff −%d %%)" % Combat.COST.swap)
	var wrow := HBoxContainer.new()
	var usable := c.usable_weapons(u)
	for wd in u.weapons:
		if wd.power != "":
			continue   # Psi-Angriffskräfte stehen in der Psi-Zeile
		var extra := ""
		if wd.magazine:
			extra = " %d/%d" % [u.loaded.get(wd.id, 0), wd.magazine]
		elif wd.pp_cost:
			extra = " %d PP" % wd.pp_cost
		var sub := "Nahkampf" if wd.melee else "%d m/Stufe" % wd.inc_m
		var b := _btn("%s%s%s\n%s" % [wd.name, " ✓" if wd == u.weapon else "", extra, sub], &"weapon", wd, wd == w, dis.call(usable.has(wd)))
		b.tooltip_text = "%s%s, max. %d m%s" % [wd.name, extra, wd.max_range_m(), (" · Reserve %d" % u.ammo.get(wd.id, 0)) if wd.magazine else ""]
		_big(b, 48)
		wrow.add_child(b)
	wcol.add_child(wrow)
	top.add_child(wcol)
	var gcol := _group("GANGART")
	var grow := HBoxContainer.new()
	for g in Combat.GAITS:
		var gd: Dictionary = Combat.GAITS[g]
		var b := _btn("%s\n%s Hex/10 %%" % [gd.name, str(c.pace(u, g)).trim_suffix(".0")], &"gait", g, pc.gait == g and pc.mode == PlayerController.Mode.MOVE, dis.call(c.can_move(u, g)))
		b.tooltip_text = "%s Hex je 10 %%%s" % [str(c.pace(u, g)), (" · Angriff %d" % gd.attack_mod) if gd.attack_mod else (" · kein Angriff danach" if gd.get("no_attack", false) else "")]
		_big(b, 48)
		grow.add_child(b)
	gcol.add_child(grow)
	top.add_child(gcol)
	_box.add_child(top)
	if not PsiCombat.known(u).is_empty():
		_box.add_child(_psi_box(c, pc, u, w, player_turn))

	var can_atk := pc.can_attack_now(u)
	var pct := pc.attack_pct(u, w)
	var acol := _group("ANGRIFF MIT %d %% AKTIVITÄT (%s)" % [pct, Dice.fmt(Combat.activity_mod(pct))])
	var pg := GridContainer.new()
	pg.columns = 9
	pg.add_theme_constant_override("h_separation", 6)
	for p in [20, 30, 40, 50, 60, 70, 80, 90, 100]:
		var b := _btn("%d" % p, &"pct", p, pct == p and can_atk, dis.call(can_atk and p <= pc.max_attack_pct(u, w)))
		b.tooltip_text = "%d %% Aktivität: Angriff %s" % [p, Dice.fmt(Combat.activity_mod(p))]
		_big(b, 40)
		pg.add_child(b)
	acol.add_child(pg)
	_box.add_child(acol)

	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	var add_action := func(text: String, name: StringName, arg: Variant, enabled: bool, sel: bool, tip: String) -> void:
		var b := _btn(text, name, arg, sel, dis.call(enabled))
		b.tooltip_text = tip
		b.custom_minimum_size.y = 44
		row.add_child(b)
	add_action.call("Ducken %d %%" % Combat.COST.crouch if not u.crouched else "Aufstehen %d %%" % Combat.COST.crouch, &"crouch", null, c.can_crouch(u), u.crouched,
		"Geduckt: +%d VW gegen Fernkampf, +%d AW im Fernkampf, halbe Deckung zählt als volle. Nur Gehen mit halber Geschwindigkeit." % [Combat.CROUCH_DB, Combat.CROUCH_OB])
	add_action.call("Abwarten %d %%" % Combat.COST.wait, &"wait", null, c.can_wait(u), false,
		"Zug nach hinten schieben. Über die Initiative-Leiste („einspringen“) nach jedem anderen Zug einsetzen, sonst am Rundenende.")
	add_action.call("Feuerbereit", &"overwatch", null, c.can_overwatch(u, w), false,
		"Restliche Aktivität (mind. %d %%) zurückhalten: Schuss auf den ersten Gegner, der im Sichtfeld handelt (%d)." % [Combat.MIN_OVERWATCH, Combat.REACTION_MOD])
	for rw in c.reloadable(u):
		add_action.call("Nachladen %d %%" % Combat.COST.reload, &"reload", rw, c.can_do(u, Combat.COST.reload), false, "%s nachladen" % rw.name)
	add_action.call("Erste Hilfe %d %%" % Combat.COST.aid, &"aid", null, c.can_do(u, Combat.COST.aid) and not c.first_aid_targets(u).is_empty(),
		pc.mode == PlayerController.Mode.AID, "Benachbarte Figur behandeln (Erste Hilfe, Leicht; Medikit +%d)" % Combat.MEDKIT_BONUS)
	add_action.call("Ausrichten", &"face", null, true, pc.mode == PlayerController.Mode.FACE, "Feld anklicken, in dessen Richtung die Figur schauen soll (kostenlos). Alternativ Rechtsklick.")
	var free := u.free_hex + int(u.move_spare)
	var end := _btn("Zug beenden ⏎", &"end", null, false, not player_turn)
	end.toggle_mode = false
	end.tooltip_text = "Enter. Übrige Aktivität (%d %%) zählt bis zum nächsten Zug als Ausweichen." % maxi(u.act, 0)
	end.custom_minimum_size = Vector2(160, 44)
	end.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end.add_theme_font_size_override("font_size", 16)
	if u.act < 10 and free <= 0:
		_accent(end)
	row.add_child(end)
	_box.add_child(row)
	var hint := _hint(pc)
	if hint != "":
		var l := UiTheme.label(hint, 13, UiTheme.ACCENT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_box.add_child(l)
	reset_size()


## Runde 0: Aufstellung im Eingangsbereich
func refresh_deploy(c: Combat, sel: Combatant, mission: Mission) -> void:
	UiTheme.clear(_box)
	show()
	_box.add_child(UiTheme.label("Runde 0 – Aufstellung", 17, UiTheme.ACCENT))
	var l := UiTheme.label("Figur anklicken oder unten wählen, dann ein blaues Feld im Eingangsbereich: dorthin stellen (mit einer anderen Figur der Crew wird getauscht). Rechtsklick bzw. lange drücken: Blickrichtung.", 13, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(l)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 6)
	g.add_theme_constant_override("v_separation", 6)
	for u in c.crew():
		var b := _btn("%s  %s" % [u.letter, u.name], &"deploy_select", u, u == sel, false)
		_big(b, 44)
		g.add_child(b)
	_box.add_child(g)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for spec in [["⟲ drehen", 1], ["drehen ⟳", -1]]:
		var b := _btn(spec[0], &"deploy_turn", spec[1], false, sel == null)
		b.toggle_mode = false
		b.custom_minimum_size = Vector2(120, 44)
		row.add_child(b)
	var bb := _btn("Briefing", &"briefing", null, false, false)
	bb.toggle_mode = false
	bb.custom_minimum_size = Vector2(120, 44)
	row.add_child(bb)
	var start := _btn("Kampf beginnen ⏎", &"begin", null, false, false)
	start.toggle_mode = false
	start.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start.custom_minimum_size.y = 44
	start.add_theme_font_size_override("font_size", 16)
	_accent(start)
	row.add_child(start)
	_box.add_child(row)
	if mission:
		var m := UiTheme.label("%s · %s · Schwierigkeit %s · %s" % [mission.title, mission.faction.name, mission.difficulty_name(), mission.enemy_summary()], 12, UiTheme.MUTED)
		m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_box.add_child(m)
	reset_size()


## Psi-Zeile: Reiter je Liste (mit Rang), darunter die Kräfte der gewählten Liste.
## Angriffskräfte wählen wie eine Waffe, unterstützende Kräfte wirken sofort oder warten auf ein Ziel.
func _psi_box(c: Combat, pc: PlayerController, u: Combatant, w: WeaponData, player_turn: bool) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiTheme.box(Color(0.24, 0.16, 0.36, 0.35), Color("6a4a9a"), 8, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	box.add_child(v)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	tabs.add_child(UiTheme.label("PSI · %d PP" % u.pp, 12, Color("c9a8f0")))
	var learned: Array[StringName] = PsiLists.learned(u)
	if not learned.has(pc.psi_tab):
		pc.psi_tab = learned[0] if not learned.is_empty() else &""
	for list in PsiLists.LISTS:
		var r := Rules.skill_rank(u, list)
		var tb := _btn("%s %s" % [PsiLists.LISTS[list].name, str(r) if r > 0 else "–"], &"psi_tab", list, list == pc.psi_tab, r <= 0)
		tb.toggle_mode = false
		tb.add_theme_font_size_override("font_size", 12)
		tb.custom_minimum_size.y = 32
		tabs.add_child(tb)
	v.add_child(tabs)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var rank := Rules.skill_rank(u, pc.psi_tab)
	for p in PsiLists.LISTS.get(pc.psi_tab, {}).get("powers", []):
		var k := PsiCombat.key(pc.psi_tab, p[0])
		var lvl: int = p[0]
		var b: Button
		if lvl > rank:
			b = _btn("%s\nSt. %d · fehlt Rang" % [p[1], lvl], &"", null, false, true)
		elif PsiCombat.is_attack(k):
			var pw := PsiCombat.weapon(k)
			var ok := c.usable_weapons(u).has(pw)
			b = _btn("%s\nSt. %d · %d PP · Angriff" % [p[1], lvl, lvl], &"weapon", pw, pw == w, not player_turn or not ok)
			b.tooltip_text = "%s: %s. Wählen, dann Gegner anklicken (Aktivität wie beim Angriff)." % [p[1], p[2]]
		elif PsiCombat.SUPPORT.has(k):
			var spec: Dictionary = PsiCombat.SUPPORT[k]
			b = _btn("%s\nSt. %d · %d PP · %d %%" % [p[1], lvl, lvl, Combat.COST.psi], &"power", k,
				pc.mode == PlayerController.Mode.PSI and pc.power == k, not player_turn or not c.can_power(u, k))
			b.tooltip_text = "%s: %s (Probe Psi wirken, Mittel)." % [p[1], spec.hint]
		else:
			b = _btn("%s\nSt. %d · nicht im Kampf" % [p[1], lvl], &"", null, false, true)
		b.add_theme_font_size_override("font_size", 12)
		b.custom_minimum_size = Vector2(0, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
	v.add_child(grid)
	return box


func _hint(pc: PlayerController) -> String:
	match pc.mode:
		PlayerController.Mode.AID:
			return "Grün markierte Figur anklicken. Esc bricht ab."
		PlayerController.Mode.PSI:
			return "Grün markierte Figur für %s anklicken. Esc bricht ab." % PsiCombat.name_of(pc.power)
		PlayerController.Mode.FACE:
			return "Feld anklicken, in dessen Richtung die Figur schauen soll."
	return ""


func _group(title: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiTheme.label(title, 12, UiTheme.MUTED))
	return v


func _big(b: Button, h: float) -> void:
	b.custom_minimum_size.y = h
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 13)


## gelber Hauptknopf (Zug beenden, Kampf beginnen)
func _accent(b: Button) -> void:
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, UiTheme.box(UiTheme.ACCENT if st != "hover" else UiTheme.ACCENT.lightened(0.15), UiTheme.ACCENT, 6, 6))
	for fc in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(fc, UiTheme.BG)


func _btn(text: String, name: StringName, arg: Variant, selected: bool, disabled: bool) -> Button:
	var b := UiTheme.button(text)
	b.toggle_mode = true
	b.button_pressed = selected
	b.disabled = disabled
	b.pressed.connect(action.emit.bind(name, arg))
	return b
