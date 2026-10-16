class_name ShipArmsDialog
extends Modal
## Maschinenraum für den Raumkampf (Mockup „Schiff-Hub Mockup“ Bildschirme 33–34): Waffenslots mit Ein-/Ausbau (nur im
## Hafen) und Geschützposten, feste Posten aus Character.station; Systemschäden und beschädigte Schiffswaffen mit
## Crew-Reparatur (1 Tag) und Werft. Regeln: ShipArms.

signal changed
## Crew-Reparatur: ein Tag ist vergangen (das Schiff zeigt Geheilte, Training usw.)
signal day_passed

var game: HubState
var _mode := &"slots"
var _pick := ""               # Slot, für den gerade eine Waffe gewählt wird
var _last := ""               # Ergebnis der letzten Crew-Reparatur


func show_slots(g: HubState) -> void:
	game = g
	_mode = &"slots"
	_pick = ""
	_render()


func show_damage(g: HubState) -> void:
	game = g
	_mode = &"damage"
	_last = ""
	_render()


func _render() -> void:
	max_size = Vector2(1300, 820)
	if _mode == &"slots":
		open("Maschinenraum: Waffenslots und Posten")
		_render_slots()
	else:
		open("Maschinenraum: Systemschäden")
		_render_damage()
	add_close()


func _again() -> void:
	Sfx.play(&"klick")
	changed.emit()
	_render()


# ---------------------------------------------------------------- Waffenslots

func _render_slots() -> void:
	var harbor := game.is_harbor(game.position)
	content.add_child(UiTheme.label("%s · Schiffsraketen %d · Geschosse %d" % ["Hafen: Ein- und Ausbau möglich" if harbor
		else "kein Hafen: Ein- und Ausbau nur im Hafen", int(game.ship_ammo.get("schiffsraketen", 0)), int(game.ship_ammo.get("geschosse", 0))], 15))
	content.add_child(UiTheme.label("WAFFENSLOTS (EIN-/AUSBAU NUR IM HAFEN, SOFORT, KOSTENLOS; WAFFEN AUS DEM LAGER UND ZURÜCK)", 13, UiTheme.MUTED))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	for h in ["Slot", "Waffe", "Munition", "Geschützposten", ""]:
		grid.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	var open_ids := ShipArms.slot_ids(game)
	for s in ShipArms.SLOTS:
		var nm := String(ShipArms.SLOT_NAMES[s]) + (" (nur Abwehr)" if s in ShipArms.TURRETS else "")
		if not s in open_ids:
			grid.add_child(UiTheme.label(nm, 15, UiTheme.MUTED))
			grid.add_child(UiTheme.label("gesperrt: Ausbau „Waffenslots“ Stufe %d" % (ShipArms.SLOTS.find(s) - ShipArms.START_SLOT_COUNT + 1), 14, UiTheme.MUTED))
			for i in 3:
				grid.add_child(Control.new())
			continue
		var key := ShipArms.slot_key(game, s)
		grid.add_child(UiTheme.label(nm, 15))
		if key == "":
			grid.add_child(UiTheme.label("leer", 15, UiTheme.MUTED))
			grid.add_child(Control.new())
			grid.add_child(Control.new())
		else:
			var dmg := ShipArms.slot_damage(game, s)
			grid.add_child(UiTheme.label(ShipArms.label(ShipArms.slot_stock_key(game, s)), 15, Color("ff8a3d") if dmg < 0 else UiTheme.TEXT))
			grid.add_child(UiTheme.label(ShipArms.ammo_name(key), 14, UiTheme.MUTED))
			grid.add_child(_post_pick(s))
		var acts := HBoxContainer.new()
		acts.add_theme_constant_override("separation", 6)
		var sw := UiTheme.button("Tauschen …" if key != "" else "Einbauen …", "Waffe aus dem Lager wählen (nur im Hafen)")
		sw.add_theme_color_override("font_color", UiTheme.ACCENT)
		sw.disabled = not harbor or ShipArms.fitting(game, s).is_empty()
		sw.pressed.connect(func() -> void:
			_pick = "" if _pick == s else s
			_render())
		acts.add_child(sw)
		if key != "":
			var out := UiTheme.button("Ausbauen", "Waffe ins Lager (nur im Hafen)")
			out.disabled = not ShipArms.can_uninstall(game, s)
			out.pressed.connect(func() -> void:
				ShipArms.uninstall(game, s)
				_pick = ""
				_again())
			acts.add_child(out)
		grid.add_child(acts)
	if _pick != "":
		content.add_child(_pick_box(_pick))
	_line()
	content.add_child(UiTheme.label("FESTE POSTEN (AUS DER CHARAKTERÜBERSICHT, „STATION“; DORT ÄNDERN)", 13, UiTheme.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	for st in ShipArms.STATIONS:
		row.add_child(_station_box(st))
	_note("Geschützposten je bestücktem Slot: Crew an Bord ohne andere Station (oder mit Station „Geschütze“) oder Bord-KI; ohne Eintrag steht, wer die Station „Geschütze“ hat, am ersten bestückten Slot. Doppelbesetzung (−30) und Änderungen kurz vor dem Kampf macht das Kampf-Briefing des Raumkampfs. Verwundete ohne Einsatzfreigabe und Personal der Krankenstation fallen weg, ihr Posten geht an die Bord-KI.")


## Auswahl Geschützposten (Figur oder Bord-KI)
func _post_pick(slot: String) -> OptionButton:
	var pick := OptionButton.new()
	pick.custom_minimum_size = Vector2(260, 32)
	var ids: Array[String] = [ShipArms.KI]
	pick.add_item("Bord-KI (+20)")
	var skill := _gun_skill(ShipArms.slot_key(game, slot))
	for c in ShipArms.gun_candidates(game):
		ids.append(String(c.id))
		pick.add_item("%s (%s %s)" % [c.name, Rules.skill_name(skill), Dice.fmt(Rules.skill_total(c, skill))])
	pick.select(maxi(0, ids.find(ShipArms.gun_post(game, slot))))
	pick.item_selected.connect(func(i: int) -> void:
		ShipArms.set_gun_post(game, slot, ids[i])
		_again())
	return pick


## Fertigkeit des Geschützes nach Art der Waffe (für die Anzeige)
func _gun_skill(key: String) -> StringName:
	match ShipArms.kind(key):
		"Strahl":
			return &"strahlGeschuetze"
		"Rakete":
			return &"raketen"
	return &"ballistikGeschuetze"


func _pick_box(slot: String) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BG, UiTheme.ACCENT, 8, 10))
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(UiTheme.label("%s (%s): Auswahl aus dem Lager, nur passende Waffen; die alte Waffe geht ins Lager, ihr Schaden bleibt am Stück." % [
		"Tauschen" if ShipArms.slot_key(game, slot) != "" else "Einbauen", ShipArms.SLOT_NAMES[slot]], 14, UiTheme.ACCENT))
	for it in ShipArms.fitting(game, slot):
		var key: String = it.key
		var r := HBoxContainer.new()
		r.add_theme_constant_override("separation", 10)
		var n := UiTheme.label("%s ×%d" % [it.name, it.count], 15)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.add_child(n)
		var b := UiTheme.button("Einbauen")
		b.disabled = not ShipArms.can_install(game, slot, key)
		b.pressed.connect(func() -> void:
			ShipArms.install(game, slot, key)
			_pick = ""
			_again())
		r.add_child(b)
		v.add_child(r)
	return p


func _station_box(st: String) -> Control:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 10))
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(UiTheme.label(ShipArms.STATIONS[st], 12, UiTheme.MUTED))
	var c := ShipArms.station_holder(game, st)
	var marked := _marked(st)
	if c:
		var skill: StringName = {"steuer": &"pilot", "navigation": &"navigation", "schilde": &"schutzschild", "technik": &"rsReparatur",
			"computer": &"computer"}[st]
		v.add_child(UiTheme.label(c.name, 15))
		v.add_child(UiTheme.label("%s %s" % [Rules.skill_name(skill), Dice.fmt(Rules.skill_total(c, skill))], 13, UiTheme.MUTED))
	elif marked:
		v.add_child(UiTheme.label(marked.name, 15, Color("ff8a3d")))
		v.add_child(UiTheme.label("nicht verfügbar: Bord-KI springt ein", 13, Color("ff8a3d")))
	else:
		v.add_child(UiTheme.label("Bord-KI (+20)", 15, UiTheme.CREW))
		v.add_child(UiTheme.label("niemand eingeteilt", 13, UiTheme.MUTED))
	return p


## Figur mit dieser Station, auch wenn sie gerade nicht verfügbar ist (verwundet, Krankenstation)
func _marked(st: String) -> Character:
	for c in Campaign.crew():
		if c.station == ShipArms.STATIONS[st]:
			return c
	return null


# ---------------------------------------------------------------- Systemschäden

func _render_damage() -> void:
	var who := ShipArms.repairer(game)
	var harbor := game.is_harbor(game.position)
	content.add_child(UiTheme.label("%d Cr · Material %d · %s · Technik: %s" % [game.credits, game.material,
		"Hafen: Werft offen" if harbor else "kein Hafen: Werft geschlossen",
		"%s (Reparatur %s)" % [who.name, Dice.fmt(Rules.skill_total(who, ShipArms.SKILL))] if who else "niemand verfügbar"], 15))
	if _last != "":
		var res := UiTheme.label(_last, 15, UiTheme.ACCENT)
		res.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(res)
	var bonus := Dice.fmt(Rules.skill_total(who, ShipArms.SKILL) + int(Rules.DIFFICULTY[Voyage.DIFF].mod) + Galley.malus(game)) if who else ""
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	content.add_child(grid)
	for h in ["System", "Schaden", "Wirkung außerhalb des Kampfes", "Crew (1 Tag, 1 Material, Probe)", "Werft (sofort, nur im Hafen)"]:
		grid.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	var dmg := ShipArms.damaged(game)
	for s in dmg:
		var n := ShipArms.stage(game, s)
		grid.add_child(UiTheme.label(ShipArms.system_name(s), 15))
		grid.add_child(UiTheme.label(ShipArms.stage_text(n), 15, UiTheme.BAD if n >= ShipArms.BROKEN else Color("ff8a3d")))
		grid.add_child(UiTheme.label(ShipArms.effect_text(s, n), 14, UiTheme.BAD if n >= ShipArms.BROKEN and ShipArms.effect_text(s, n) != "nur im Kampf" else UiTheme.MUTED))
		grid.add_child(_fix_button("Reparieren (%s)" % bonus, ShipArms.can_crew_fix_system(game, s), s))
		var y := UiTheme.button("1 Stufe: %d Cr + %d Mat." % [ShipArms.yard_stage_cost(game), ShipArms.YARD_STAGE_MATERIAL])
		y.disabled = not ShipArms.can_yard_system(game, s)
		y.pressed.connect(func() -> void:
			ShipArms.yard_system(game, s)
			_last = ""
			_again())
		grid.add_child(y)
	content.add_child(UiTheme.label("Alle Systeme heil." if dmg.is_empty() else "Übrige Systeme heil.", 14, UiTheme.GOOD))
	_line()
	content.add_child(UiTheme.label("BESCHÄDIGTE SCHIFFSWAFFEN (IM SLOT ODER IM LAGER)", 13, UiTheme.MUTED))
	var wg := GridContainer.new()
	wg.columns = 4
	wg.add_theme_constant_override("h_separation", 12)
	wg.add_theme_constant_override("v_separation", 6)
	content.add_child(wg)
	for h in ["Waffe", "Ort", "Crew (1 Tag, 1 Material, Probe)", "Werft (%d %% vom Kaufpreis je −10)" % roundi(ShipArms.YARD_WEAPON_SHARE * 100)]:
		wg.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	var any := false
	for s in ShipArms.armed(game):
		if ShipArms.slot_damage(game, s) < 0:
			any = true
			_weapon_row(wg, ShipArms.label(ShipArms.slot_stock_key(game, s)), "Slot " + String(ShipArms.SLOT_NAMES[s]), "slot:" + s, bonus)
	for it in ShipArms.stock_items(game):
		if int(it.damage) < 0:
			any = true
			_weapon_row(wg, "%s ×%d" % [it.name, it.count], "Lager", String(it.key), bonus)
	if not any:
		content.add_child(UiTheme.label("Keine beschädigten Schiffswaffen.", 14, UiTheme.GOOD))
	_note("Wirkung außerhalb des Kampfes: Antrieb → Pilot, Sensoren → Navigation, Reaktor → Computer, je Stufe −5 auf die Reiseprobe (A −5 … E −25). Antrieb E = keine Reise (nur Reparatur vor Ort), Lebenserhaltung E = Proviant doppelt. Schilde, Slots und Stationen wirken nur im Kampf.")
	_note("Crew-Reparatur (überall, Station Technik, sonst die oder der Beste; mittel): Patzer +1 Stufe bzw. −10 mehr · Fehlschlag/Teilerfolg nichts · Erfolg −1 Stufe bzw. −10 weg · Herausragend −2 Stufen bzw. −20 weg. 1 Tag vergeht. Werft: Systeme %d Cr + %d Material je Stufe, Waffen %d %% vom Kaufpreis je −10, jeweils nach Verhandeln." % [
		ShipArms.YARD_STAGE_COST, ShipArms.YARD_STAGE_MATERIAL, roundi(ShipArms.YARD_WEAPON_SHARE * 100)])


func _weapon_row(grid: GridContainer, text: String, where_text: String, where: String, bonus: String) -> void:
	grid.add_child(UiTheme.label(text, 15, Color("ff8a3d")))
	grid.add_child(UiTheme.label(where_text, 14, UiTheme.MUTED))
	grid.add_child(_fix_button("Reparieren (%s)" % bonus, ShipArms.can_crew_fix_weapon(game, where), where))
	var y := UiTheme.button("ganz: %d Cr" % ShipArms.yard_weapon_cost(game, where))
	y.disabled = not ShipArms.can_yard_weapon(game, where)
	y.pressed.connect(func() -> void:
		ShipArms.yard_weapon(game, where)
		_last = ""
		_again())
	grid.add_child(y)


## Crew-Reparatur: 1 Tag vergeht, Ergebnis oben im Dialog
func _fix_button(text: String, ok: bool, target: String) -> Button:
	var b := UiTheme.button(text, "1 Tag, 1 Material, Reparaturprobe (mittel)")
	b.add_theme_color_override("font_color", UiTheme.ACCENT)
	b.disabled = not ok
	b.pressed.connect(func() -> void:
		var r := game.ship_fix(target)
		if r.is_empty():
			return
		_last = "%s: %s, Reparatur %s %s = %d → %s · %s · 1 Material · +%d EP" % [r.what, r.name, Dice.format_roll(r.roll),
			Dice.fmt(r.bonus), r.total, r.result_name, _change_text(target, r), r.xp]
		day_passed.emit()
		_again())
	return b


func _change_text(target: String, r: Dictionary) -> String:
	if int(r.before) == int(r.after):
		return "keine Änderung"
	if ShipArms.SYSTEMS.has(target) or not (target.begins_with("slot:") or "|" in target):
		return "%s → %s" % [ShipArms.stage_text(int(r.before)), ShipArms.stage_text(int(r.after))]
	return "%s → %s" % [Stock.damage_text(int(r.before)).strip_edges(), "heil" if int(r.after) == 0 else Stock.damage_text(int(r.after)).strip_edges()]


# ---------------------------------------------------------------- Hilfen

func _line() -> void:
	var line := ColorRect.new()
	line.color = UiTheme.LINE
	line.custom_minimum_size.y = 1
	content.add_child(line)


func _note(text: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BG, UiTheme.LINE, 8, 10))
	var l := UiTheme.label(text, 13, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	content.add_child(p)
