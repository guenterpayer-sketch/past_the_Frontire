class_name ArmoryDialog
extends Modal
## Waffenkammer (Mockup „Frontire Waffenkammer“): Ausrüstung der Crew ändern – Waffe 1/2, Rüstung, Schild –
## mit Werten aus WeaponData/ArmorData und dem Bonus der Figur; Medikits aus dem Lager, Munition nur anzeigen.
## Am Lager des Schiffs (Equipment, Stock): Ausrüsten nimmt heraus, Ablegen legt zurück; nicht Vorrätiges wird
## ausgeblendet. Ohne Spiel (HubState.game == null) ist der Bestand unbegrenzt.
## Der Hub öffnet ihn im Raum „Waffenkammer“: open_for(Campaign.crew()). „Fertig“ speichert über Campaign.save().

## nach „Fertig“ (schon gespeichert)
signal done

var _crew: Array[Character] = []
var _idx := 0
var _slot := "w0"            # w0, w1, armor, shield
var _snap := {}              # Character -> {weapons, armor, shield, medkits} beim Öffnen
var _tabs: HBoxContainer
var _left: VBoxContainer
var _right: VBoxContainer
var _preview: FigurePreview
var _changed: Label
var _weapons: Array[WeaponData] = []
var _armors: Array[ArmorData] = []


func open_for(crew: Array[Character], idx := 0) -> void:
	_crew = crew
	_idx = clampi(idx, 0, maxi(0, crew.size() - 1))
	_slot = "w0"
	_weapons = Equipment.weapons()
	_armors = Equipment.armors()
	_snap.clear()
	for c in crew:
		_snap[c] = Equipment.snapshot(c)
	if _preview and _preview.get_parent():
		_preview.get_parent().remove_child(_preview)
	open("Waffenkammer")
	var head := UiTheme.label(("Lager des Schiffs: Ausrüsten nimmt heraus, Ablegen legt zurück" if _g() else "Bestand unbegrenzt (ohne Spielstand)") + " · Änderungen gelten für die Figur in diesem Spiel", 13, UiTheme.MUTED)
	content.add_child(head)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 6)
	content.add_child(_tabs)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	content.add_child(cols)
	var lp := PanelContainer.new()
	lp.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 12))
	lp.custom_minimum_size.x = 400
	cols.add_child(lp)
	_left = VBoxContainer.new()
	lp.add_child(_left)
	var rp := PanelContainer.new()
	rp.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 12))
	rp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(rp)
	_right = VBoxContainer.new()
	rp.add_child(_right)
	_changed = UiTheme.label("", 13, UiTheme.MUTED)
	_changed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_changed)
	var undo := UiTheme.button("zurücknehmen", "Ausrüstung dieser Figur auf den Stand beim Öffnen zurücksetzen")
	undo.pressed.connect(func() -> void:
		var why := Equipment.restore(current(), _snap[current()], _g())
		_render()
		if why != "":
			_changed.text = "Zurücknehmen nicht möglich: " + why)
	footer.add_child(undo)
	var ok := UiTheme.button("Fertig")
	ok.add_theme_color_override("font_color", UiTheme.ACCENT)
	ok.pressed.connect(func() -> void:
		Campaign.save()
		hide()
		done.emit())
	footer.add_child(ok)
	_render()


## Lager des laufenden Spiels (null = unbegrenzt)
func _g() -> HubState:
	return HubState.game


func current() -> Character:
	return _crew[_idx] if not _crew.is_empty() else null


func _is_changed(u: Character) -> bool:
	var s: Dictionary = _snap.get(u, {})
	return not s.is_empty() and (s.weapons != u.weapons or s.armor != u.armor or s.shield != u.shield or s.medkits != u.medkits)


func _render() -> void:
	if _preview and _preview.get_parent():
		_preview.get_parent().remove_child(_preview)
	UiTheme.clear(_tabs)
	UiTheme.clear(_left)
	UiTheme.clear(_right)
	for i in _crew.size():
		var o := _crew[i]
		var b := UiTheme.button("%s %s%s" % [o.letter, o.name.split(" ")[0], " •" if _is_changed(o) else ""], o.name, true)
		b.button_pressed = i == _idx
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void:
			_idx = i
			_render())
		_tabs.add_child(b)
	var n := _crew.filter(_is_changed).size()
	_changed.text = ("%d %s geändert (• am Reiter)" % [n, "Figur" if n == 1 else "Figuren"]) if n else ""
	var u := current()
	if u == null:
		return
	_render_left(u)
	_render_right(u)


# ---------------------------------------------------------------- links: Figur und Plätze

func _render_left(u: Character) -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	if _preview == null:
		_preview = FigurePreview.new()
		_preview.custom_minimum_size = Vector2(130, 180)
	top.add_child(_preview)
	_preview.show_character(u)
	var nv := VBoxContainer.new()
	nv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nv.add_child(UiTheme.label(u.name, 18, UiTheme.CREW))
	nv.add_child(UiTheme.label(u.role, 12, UiTheme.MUTED))
	if u.injury != "":
		nv.add_child(UiTheme.label(u.injury_text(), 12, UiTheme.BAD if u.is_locked() else Color("ffb04d")))
	top.add_child(nv)
	_left.add_child(top)
	_left.add_child(UiTheme.label("Ausrüstung", 13, UiTheme.MUTED))
	for slot in 2:
		var w := Equipment.weapon(u, slot)
		if w:
			_left.add_child(_slot_button("w%d" % slot, "Waffe %d" % (slot + 1), Equipment.label(w),
				"%s · %s" % [Rules.skill_name(w.skill), "Nahkampf" if w.melee else "Fernkampf"], Rules.skill_total(u, w.skill),
				Equipment.wear_text(u, "w%d" % slot)))
		else:
			_left.add_child(_slot_button("w%d" % slot, "Waffe %d" % (slot + 1), "leer", "keine zweite Waffe", null))
	var a := u.armor
	_left.add_child(_slot_button("armor", "Rüstung", Equipment.label(a), _armor_text(a), null, Equipment.wear_text(u, "armor")))
	_left.add_child(_slot_button("shield", "Schild", "getragen" if u.shield else "kein Schild",
		"Verteidigung +10 + ½ Rangbonus Schild", Equipment.shield_bonus(u) if u.shield else null))
	_left.add_child(UiTheme.label("Vorrat", 13, UiTheme.MUTED))
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 12)
	g.add_child(UiTheme.label("Medikits", 13, UiTheme.MUTED))
	g.add_child(_medkit_row(u))
	var any_ammo := false
	for w in u.weapons:
		if w.magazine > 0:
			any_ammo = true
			g.add_child(UiTheme.label("Mitnahme %s" % w.name, 13, UiTheme.MUTED))
			g.add_child(UiTheme.label("%d Schuss %s" % [Ammo.carry(w), Ammo.TYPES.get(w.ammo_type, "")], 13))
	if not any_ammo:
		g.add_child(UiTheme.label("Munition", 13, UiTheme.MUTED))
		g.add_child(UiTheme.label("keine nötig", 13))
	_left.add_child(g)
	var note := UiTheme.label("Mitnahme je Waffe: %d Magazine, höchstens „Munition gesamt“ der Waffe, solange der Munitionsvorrat des Schiffs reicht (Schnellkampf: voll)." % Ammo.MAGS, 11, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_left.add_child(note)
	if Rules.skill_rank(u, &"psiAngriff") > 0 or Rules.skill_rank(u, &"lAngriff") > 0:
		var pn := UiTheme.label("Psi-Angriffe kommen aus den gelernten Psi-Listen und brauchen keinen Waffenplatz.", 11, Color("b07ae8"))
		pn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_left.add_child(pn)


## Medikits: − / Anzahl / + (aus dem bzw. ins Lager, höchstens Equipment.MAX_MEDKITS)
func _medkit_row(u: Character) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var minus := UiTheme.button("−", "Ein Medikit ins Lager zurücklegen")
	minus.disabled = u.medkits <= 0
	minus.pressed.connect(func() -> void:
		Equipment.set_medkits(u, u.medkits - 1, _g())
		_render())
	h.add_child(minus)
	h.add_child(UiTheme.label("%d / %d" % [u.medkits, Equipment.MAX_MEDKITS], 13))
	var left := Stock.count(_g(), Stock.MEDKIT)
	var plus := UiTheme.button("+", "Ein Medikit aus dem Lager nehmen")
	plus.disabled = u.medkits >= Equipment.MAX_MEDKITS or left <= 0
	plus.pressed.connect(func() -> void:
		Equipment.set_medkits(u, u.medkits + 1, _g())
		_render())
	h.add_child(plus)
	if _g():
		h.add_child(UiTheme.label("Lager: %d" % left, 12, UiTheme.MUTED))
	return h


## Stückzahl im Lager als Text („immer“ für Fäuste/keine Rüstung, leer ohne Spiel)
func _stock_text(r: Resource) -> String:
	if Equipment.is_free_item(r):
		return "immer"
	return str(Equipment.in_stock(_g(), r)) if _g() else "–"


## wear = Beschädigung des Platzes als Text ("" = heil, sonst orange bzw. rot bei „unbrauchbar“ neben dem Namen)
func _slot_button(key: String, title: String, value: String, sub: String, bonus: Variant, wear := "") -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.button_pressed = _slot == key
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 50)
	var h := HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -10
	b.add_child(h)
	var k := UiTheme.label(title, 12, UiTheme.MUTED)
	k.custom_minimum_size.x = 70
	k.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(k)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vh := HBoxContainer.new()
	vh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vh.add_child(UiTheme.label(value, 14))
	if wear != "":
		vh.add_child(UiTheme.label(wear, 12, UiTheme.BAD if wear == "unbrauchbar" else Color("ffb04d")))
	v.add_child(vh)
	var s := UiTheme.label(sub, 11, UiTheme.MUTED)
	s.clip_text = true
	s.custom_minimum_size.x = 200
	v.add_child(s)
	h.add_child(v)
	if bonus != null:
		var bl := UiTheme.label(Dice.fmt(bonus), 14, _col(bonus))
		bl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bl)
	b.pressed.connect(func() -> void:
		_slot = key
		_render())
	return b


func _armor_text(a: ArmorData) -> String:
	if a == null:
		return ""
	var parts := ["Klasse %d" % a.cls, "Schaden ×%s" % _num(Equipment.damage_taken(a), 2)]
	if a.db:
		parts.append("Verteidigung %s" % Dice.fmt(a.db))
	if a.move:
		parts.append("Bewegung %d" % a.move)
	return " · ".join(parts)


# ---------------------------------------------------------------- rechts: Auswahl

func _render_right(u: Character) -> void:
	match _slot:
		"w0", "w1":
			_weapon_list(u, int(_slot[1]))
		"armor":
			_armor_list(u)
		_:
			_shield_list(u)


func _weapon_list(u: Character, slot: int) -> void:
	_right.add_child(UiTheme.label("Waffe %d wählen" % (slot + 1), 13, UiTheme.ACCENT))
	var g := GridContainer.new()
	g.columns = 7
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 6)
	for h in ["Waffe", "Lager", "Fertigkeit", "Bonus " + u.letter, "Reichweite", "Schaden", "Besonderes"]:
		g.add_child(UiTheme.label(h, 11, UiTheme.MUTED))
	var cur := Equipment.weapon(u, slot)
	for w in _weapons:
		if not Equipment.listed(_g(), w, w in u.weapons):
			continue
		var why := Equipment.weapon_block(u, slot, w, _g())
		var b := UiTheme.button(("▸ " if w == cur else "") + Equipment.label(w), why if why != "" else "%s als Waffe %d nehmen" % [w.name, slot + 1])
		b.disabled = why != "" and w != cur
		if w == cur:
			b.add_theme_color_override("font_color", UiTheme.ACCENT)
		b.custom_minimum_size.x = 190
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void:
			Equipment.set_weapon(u, slot, w, _g())
			_render())
		g.add_child(b)
		g.add_child(UiTheme.label(_stock_text(w), 12, UiTheme.MUTED))
		g.add_child(UiTheme.label(Rules.skill_name(w.skill), 12, UiTheme.MUTED))
		var tot := Rules.skill_total(u, w.skill)
		g.add_child(UiTheme.label(Dice.fmt(tot), 13, _col(tot)))
		g.add_child(UiTheme.label(_range(w), 12, UiTheme.MUTED))
		g.add_child(UiTheme.label("×" + _num(w.damage, 1), 13))
		var ex := UiTheme.label(_extra(w), 12, UiTheme.MUTED)
		ex.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ex.custom_minimum_size.x = 150
		g.add_child(ex)
	_right.add_child(g)
	if slot == 1:
		var none := UiTheme.button(("▸ " if cur == null else "") + "Waffe 2 leer lassen", "Nur eine Waffe tragen")
		none.pressed.connect(func() -> void:
			Equipment.set_weapon(u, 1, null, _g())
			_render())
		_right.add_child(none)
	var note := UiTheme.label("Bonus = Gesamtbonus der Figur in der Fertigkeit der Waffe (Rang + Eigenschaften), ohne Lage und Ziel. Schaden = Faktor auf das Tabellenergebnis. Keine Waffe doppelt; Schild nur mit einhändigen Waffen (eine zweihändige Waffe legt ihn ab). Angezeigt wird nur, was im Lager liegt oder getragen wird; Nachschub über den Handel im Raumhafen.", 11, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(note)


func _armor_list(u: Character) -> void:
	_right.add_child(UiTheme.label("Rüstung wählen", 13, UiTheme.ACCENT))
	var g := GridContainer.new()
	g.columns = 6
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 6)
	for h in ["Rüstung", "Lager", "Klasse", "Schaden erhalten", "Verteidigung", "Bewegung"]:
		g.add_child(UiTheme.label(h, 11, UiTheme.MUTED))
	for a in _armors:
		if not Equipment.listed(_g(), a, a == u.armor):
			continue
		var b := UiTheme.button(("▸ " if a == u.armor else "") + Equipment.label(a))
		if a == u.armor:
			b.add_theme_color_override("font_color", UiTheme.ACCENT)
		b.custom_minimum_size.x = 220
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void:
			Equipment.set_armor(u, a, _g())
			_render())
		g.add_child(b)
		g.add_child(UiTheme.label(_stock_text(a), 12, UiTheme.MUTED))
		g.add_child(UiTheme.label(str(a.cls), 13))
		g.add_child(UiTheme.label("×" + _num(Equipment.damage_taken(a), 2), 13))
		g.add_child(UiTheme.label(Dice.fmt(a.db) if a.db else "–", 13, _col(a.db)))
		g.add_child(UiTheme.label(("%d Gratis-Feld" % a.move) if a.move else "–", 13, _col(a.move)))
	_right.add_child(g)
	var note := UiTheme.label("Die Klasse bestimmt die Spalte der Angriffstabelle. „Schaden erhalten“ gilt nicht gegen Psi. Angezeigt wird nur, was im Lager liegt oder getragen wird.", 11, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(note)


func _shield_list(u: Character) -> void:
	_right.add_child(UiTheme.label("Schild", 13, UiTheme.ACCENT))
	var why := Equipment.shield_block(u)
	var rb := Rules.rank_bonus(Rules.skill_rank(u, &"schild"))
	var left := Stock.count(_g(), Equipment.SHIELD)
	if why == "" and not u.shield and left <= 0:
		why = "kein Schild im Lager"
	var on := UiTheme.button(("▸ " if u.shield else "") + "Schild tragen  (Verteidigung +%d)%s" % [Equipment.shield_bonus(u), ("  · Lager: %d" % left) if _g() else ""], why)
	on.disabled = why != "" and not u.shield
	on.pressed.connect(func() -> void:
		Equipment.set_shield(u, true, _g())
		_render())
	_right.add_child(on)
	var off := UiTheme.button(("▸ " if not u.shield else "") + "kein Schild")
	off.pressed.connect(func() -> void:
		Equipment.set_shield(u, false, _g())
		_render())
	_right.add_child(off)
	var t := "+10 + ½ Rangbonus Schild (%s → %s); nicht bei Überraschung." % [Dice.fmt(rb), Dice.fmt(maxi(0, rb / 2))]
	if why != "":
		t += " Nicht möglich: " + why + "."
	var note := UiTheme.label(t, 12, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(note)


func _range(w: WeaponData) -> String:
	if w.melee:
		return "Nahkampf"
	var s := "%d m je Stufe, bis %d m" % [w.inc_m, w.inc_m * w.stages]
	if w.min_range_m:
		s += ", mind. %d m" % w.min_range_m
	return s


func _extra(w: WeaponData) -> String:
	var parts: Array[String] = []
	if w.shots >= 2:
		parts.append("Feuerstoß ×%d (%s)" % [w.shots, Dice.fmt(Ammo.burst_bonus(w.shots))])
	if w.ob_bonus:
		parts.append("Angriffsbonus %s" % Dice.fmt(w.ob_bonus))
	if not w.splash.is_empty():
		parts.append("Druckwelle %s" % "/".join(Array(w.splash).map(func(v: int) -> String: return str(v))))
	if w.magazine:
		var cap := " (höchstens %d)" % w.ammo_total if w.ammo_total > 0 and w.ammo_total < w.magazine * Ammo.MAGS else ""
		parts.append("%s, Magazin %d, Mitnahme %d%s" % [Ammo.TYPES.get(w.ammo_type, "Munition"), w.magazine, Ammo.carry(w), cap])
	parts.append("zweihändig" if Equipment.blocks_shield(w) else ("mit Schild möglich" if w.two_handed else "einhändig"))
	return " · ".join(parts)


static func _num(v: float, digits: int) -> String:
	return (("%." + str(digits) + "f") % v).replace(".", ",")


static func _col(v: int) -> Color:
	return UiTheme.GOOD if v > 0 else (UiTheme.BAD if v < 0 else UiTheme.TEXT)


func _exit_tree() -> void:
	if _preview and not _preview.is_inside_tree():
		_preview.free()
