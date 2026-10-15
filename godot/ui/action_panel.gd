class_name ActionPanel
extends VBoxContainer
## Aktionsteil der Seitenleiste rechts (Variante C, Entscheidung Nutzer 15.10.2026): Abschnitte Waffe, Gangart,
## Aktivität, Psi und Aktionen, je einklappbar (Zustand in Prefs), darunter immer „Zug beenden“.
## In Runde 0 stattdessen die Aufstellung. Meldet Bedienung über action(name, arg); ausgeführt wird in Battle.

signal action(name: StringName, arg: Variant)

const BTN_H := 30
const FONT := 12
## Abschnitte und ob sie ohne gespeicherte Einstellung offen sind
const SECTIONS := {&"weapon": true, &"gait": true, &"act": true, &"psi": false, &"more": false}
const PSI_LINE := Color("6a4a9a")

var _scroll: ScrollContainer
var _box: VBoxContainer
var _bottom: VBoxContainer


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_scroll)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 2)
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_box)
	_bottom = VBoxContainer.new()
	_bottom.add_theme_constant_override("separation", 6)
	add_child(_bottom)


static func is_open(id: StringName) -> bool:
	return Prefs.get_bool("side_" + id, SECTIONS.get(id, true))


static func set_open(id: StringName, on: bool) -> void:
	Prefs.set_bool("side_" + id, on)


func refresh(c: Combat, pc: PlayerController, u: Combatant, player_turn: bool) -> void:
	UiTheme.clear(_box)
	UiTheme.clear(_bottom)
	if u == null or c.result != &"":
		hide()
		return
	show()
	var dis := func(cond: bool) -> bool: return not player_turn or not cond
	var w := pc.weapon_of(u)

	# Waffe (Psi-Angriffskräfte stehen mit lila Rand dabei)
	var wflow := _flow()
	var usable := c.usable_weapons(u)
	for wd in u.weapons:
		var extra := ""
		if wd.magazine:
			extra = " %d/%d" % [u.loaded.get(wd.id, 0), wd.magazine]
		elif wd.pp_cost:
			extra = " %d PP" % wd.pp_cost
		var b := _btn("%s%s%s" % [wd.name, " ✓" if wd == u.weapon else "", extra], &"weapon", wd, wd == w, dis.call(usable.has(wd)))
		b.tooltip_text = "%s%s, %s, max. %d m%s" % [wd.name, extra, "Nahkampf" if wd.melee else "%d m/Stufe" % wd.inc_m, wd.max_range_m(),
			(" · Reserve %d" % u.ammo.get(wd.id, 0)) if wd.magazine else ""]
		if wd.power != "":
			_psi_border(b)
			b.tooltip_text = psi_tip(PsiCombat.list_of(wd.power), PsiCombat.level_of(wd.power))
		wflow.add_child(b)
	_section(&"weapon", "WAFFE  (Wechsel beim Angriff −%d %%)" % Combat.COST.swap, wflow)

	var grow := HBoxContainer.new()
	grow.add_theme_constant_override("separation", 4)
	for g in Combat.GAITS:
		var gd: Dictionary = Combat.GAITS[g]
		var b := _btn("%s\n%s Hex" % [gd.name, str(c.pace(u, g)).trim_suffix(".0")], &"gait", g, pc.gait == g and pc.mode == PlayerController.Mode.MOVE, dis.call(c.can_move(u, g)))
		b.tooltip_text = "%s Hex je 10 %%%s" % [str(c.pace(u, g)), (" · Angriff %d" % gd.attack_mod) if gd.attack_mod else (" · kein Angriff danach" if gd.get("no_attack", false) else "")]
		b.custom_minimum_size.y = 38
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grow.add_child(b)
	_section(&"gait", "GANGART (je 10 % Aktivität)", grow)

	var can_atk := pc.can_attack_now(u)
	var pct := pc.attack_pct(u, w)
	var pg := GridContainer.new()
	pg.columns = 5
	pg.add_theme_constant_override("h_separation", 4)
	pg.add_theme_constant_override("v_separation", 4)
	for p in [20, 30, 40, 50, 60, 70, 80, 90, 100]:
		var b := _btn("%d" % p, &"pct", p, pct == p and can_atk, dis.call(can_atk and p <= pc.max_attack_pct(u, w)))
		b.tooltip_text = "%d %% Aktivität: Angriff %s" % [p, Dice.fmt(Combat.activity_mod(p))]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pg.add_child(b)
	_section(&"act", "ANGRIFF MIT %d %% AKTIVITÄT (%s)" % [pct, Dice.fmt(Combat.activity_mod(pct))], pg)

	if not PsiCombat.known(u).is_empty():
		var learned: Array[StringName] = PsiLists.learned(u)
		var names: Array[String] = []
		for list in learned:
			names.append(PsiLists.LISTS[list].name)
		_section(&"psi", "PSI · %d PP · %s" % [u.pp, ", ".join(names)], _psi_box(c, pc, u, w, player_turn), Color("c9a8f0"))

	var more := _flow()
	var add_action := func(text: String, name: StringName, arg: Variant, enabled: bool, sel: bool, tip: String) -> void:
		var b := _btn(text, name, arg, sel, dis.call(enabled))
		b.tooltip_text = tip
		more.add_child(b)
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
	_section(&"more", "AKTIONEN (Ducken, Abwarten, Feuerbereit, …)", more)

	var hint := _hint(pc)
	if hint != "":
		var l := UiTheme.label(hint, FONT, UiTheme.ACCENT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_bottom.add_child(l)
	var free := u.free_hex + int(u.move_spare)
	var end := _btn("Zug beenden ⏎", &"end", null, false, not player_turn)
	end.toggle_mode = false
	end.tooltip_text = "Enter. Übrige Aktivität (%d %%) zählt bis zum nächsten Zug als Ausweichen." % maxi(u.act, 0)
	end.custom_minimum_size.y = 40
	end.add_theme_font_size_override("font_size", 15)
	if u.act < 10 and free <= 0:
		_accent(end)
	_bottom.add_child(end)


## Runde 0: Aufstellung im Eingangsbereich
func refresh_deploy(c: Combat, sel: Combatant, mission: Mission) -> void:
	UiTheme.clear(_box)
	UiTheme.clear(_bottom)
	show()
	_box.add_child(UiTheme.label("Runde 0 – Aufstellung", 15, UiTheme.ACCENT))
	var l := UiTheme.label("Figur anklicken oder hier wählen, dann ein blaues Feld im Eingangsbereich: dorthin stellen (mit einer anderen Figur wird getauscht). Rechtsklick bzw. lange drücken: Blickrichtung.", FONT, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(l)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 4)
	for u in c.crew():
		var b := _btn("%s  %s" % [u.letter, u.name], &"deploy_select", u, u == sel, false)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.custom_minimum_size.x = 0
		b.clip_text = true
		g.add_child(b)
	_box.add_child(g)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for spec in [["⟲ drehen", 1], ["drehen ⟳", -1], ["Briefing", null]]:
		var b := _btn(spec[0], &"deploy_turn" if spec[1] != null else &"briefing", spec[1], false, spec[1] != null and sel == null)
		b.toggle_mode = false
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	_box.add_child(row)
	if mission:
		var m := UiTheme.label("%s · %s · Schwierigkeit %s · %s" % [mission.title, mission.faction.name, mission.difficulty_name(), mission.enemy_summary()], 11, UiTheme.MUTED)
		m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_box.add_child(m)
	var start := _btn("Kampf beginnen ⏎", &"begin", null, false, false)
	start.toggle_mode = false
	start.custom_minimum_size.y = 40
	start.add_theme_font_size_override("font_size", 15)
	_accent(start)
	_bottom.add_child(start)


## einklappbarer Abschnitt: Kopfzeile (Klick klappt, gespeichert) und Inhalt
func _section(id: StringName, title: String, content: Control, color := UiTheme.MUTED) -> void:
	var open := is_open(id)
	var head := UiTheme.button("%s  %s" % [title, "▾" if open else "▸"])
	head.flat = true
	head.alignment = HORIZONTAL_ALIGNMENT_LEFT
	head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	head.clip_text = true
	head.custom_minimum_size = Vector2(0, 26)
	head.add_theme_font_size_override("font_size", 11)
	for fc in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		head.add_theme_color_override(fc, color)
	head.tooltip_text = title
	head.pressed.connect(func() -> void:
		set_open(id, not open)
		action.emit(&"panel", id))
	_box.add_child(head)
	if open:
		_box.add_child(content)
		var gap := Control.new()
		gap.custom_minimum_size.y = 4
		_box.add_child(gap)
	else:
		content.free()
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 2)
	_box.add_child(sep)


func _flow() -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 4)
	f.add_theme_constant_override("v_separation", 4)
	return f


## Psi: Reiter je Liste (mit Rang), darunter die Kräfte der gewählten Liste.
## Angriffskräfte wählen wie eine Waffe, unterstützende Kräfte wirken sofort oder warten auf ein Ziel.
func _psi_box(c: Combat, pc: PlayerController, u: Combatant, w: WeaponData, player_turn: bool) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	var tabs := _flow()
	var learned: Array[StringName] = PsiLists.learned(u)
	if not learned.has(pc.psi_tab):
		pc.psi_tab = learned[0] if not learned.is_empty() else &""
	for list in PsiLists.LISTS:
		var r := Rules.skill_rank(u, list)
		if r <= 0:
			continue
		var tb := _btn("%s %d" % [PsiLists.LISTS[list].name, r], &"psi_tab", list, list == pc.psi_tab, false)
		_psi_border(tb)
		tabs.add_child(tb)
	v.add_child(tabs)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var rank := Rules.skill_rank(u, pc.psi_tab)
	for p in PsiLists.LISTS.get(pc.psi_tab, {}).get("powers", []):
		var k := PsiCombat.key(pc.psi_tab, p[0])
		var lvl: int = p[0]
		var b: Button
		if lvl > rank:
			b = _btn("%s\nSt. %d · fehlt Rang" % [p[1], lvl], &"", null, false, true)
			b.tooltip_text = psi_tip(pc.psi_tab, lvl) + "\nAb Rang %d in %s (jetzt %d)." % [lvl, PsiLists.LISTS[pc.psi_tab].name, rank]
		elif PsiCombat.is_attack(k):
			var pw := PsiCombat.weapon(k)
			var ok := c.usable_weapons(u).has(pw)
			b = _btn("%s\nSt. %d · %d PP · Angriff" % [p[1], lvl, lvl], &"weapon", pw, pw == w, not player_turn or not ok)
			b.tooltip_text = psi_tip(pc.psi_tab, lvl) + "\nWählen, dann Gegner anklicken."
		elif PsiCombat.SUPPORT.has(k):
			var spec: Dictionary = PsiCombat.SUPPORT[k]
			b = _btn("%s\nSt. %d · %d PP · %d %%" % [p[1], lvl, lvl, Combat.COST.psi], &"power", k,
				pc.mode == PlayerController.Mode.PSI and pc.power == k, not player_turn or not c.can_power(u, k))
			b.tooltip_text = psi_tip(pc.psi_tab, lvl)
		else:
			b = _btn("%s\nSt. %d · nicht im Kampf" % [p[1], lvl], &"", null, false, true)
			b.tooltip_text = psi_tip(pc.psi_tab, lvl)
		b.add_theme_font_size_override("font_size", 11)
		b.custom_minimum_size = Vector2(0, 40)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		grid.add_child(b)
	v.add_child(grid)
	return v


func _hint(pc: PlayerController) -> String:
	match pc.mode:
		PlayerController.Mode.AID:
			return "Grün markierte Figur anklicken. Esc bricht ab."
		PlayerController.Mode.PSI:
			return "Grün markierte Figur für %s anklicken. Esc bricht ab." % PsiCombat.name_of(pc.power)
		PlayerController.Mode.FACE:
			return "Feld anklicken, in dessen Richtung die Figur schauen soll."
	return ""


## Tooltip einer Psi-Kraft: Wirkung, Ziel, Kosten, Probe (Daten aus PsiLists/PsiCombat, Auftrag „Übersicht Psi-Listen“)
static func psi_tip(list: StringName, level: int) -> String:
	var p := PsiLists.power_at(list, level)
	if p.is_empty():
		return ""
	var kind := PsiLists.kind(list, level)
	var lines := PackedStringArray()
	lines.append("%s (%s, Stufe %d)" % [p[1], PsiLists.LISTS[list].name, level])
	lines.append("Wirkung: %s" % p[2])
	var tgt := PsiLists.target(list, level)
	if tgt != "":
		lines.append("Ziel: %s" % tgt)
	if kind == PsiLists.ATTACK:
		lines.append("Kosten: %d PP, Aktivität wie beim Angriff" % level)
		lines.append("Probe: Psi-Angriffe gegen Psi-VW des Ziels")
	elif kind == PsiLists.SUPPORT:
		lines.append("Kosten: %d PP, %d %% Aktivität" % [level, Combat.COST.psi])
		lines.append("Probe: Psi wirken (Mittel)")
	else:
		lines.append("Im Kampf nicht einsetzbar.")
	return "\n".join(lines)


func _psi_border(b: Button) -> void:
	if b.button_pressed or b.disabled:
		return
	b.add_theme_stylebox_override("normal", UiTheme._btn_box(UiTheme.PANEL2, PSI_LINE))
	b.add_theme_stylebox_override("hover", UiTheme._btn_box(UiTheme.PANEL2.lightened(0.08), PSI_LINE.lightened(0.3)))


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
	b.custom_minimum_size.y = BTN_H
	b.add_theme_font_size_override("font_size", FONT)
	b.pressed.connect(action.emit.bind(name, arg))
	return b
