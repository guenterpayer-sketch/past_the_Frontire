class_name GearEditor
extends Modal
## Editor für eigene Waffen und Rüstungen (Startmenü „Ausrüstung“). Links die eigenen Einträge (Reiter Waffen/Rüstungen),
## rechts der Entwurf: Name, Fertigkeit, Tabelle, Modell, Hände, Zahlenwerte in Grenzen um die Vorlage (oder frei),
## „Auch für Gegner“ mit Fraktionen. Regeln und Speichern: Gear.

const ORANGE := Color("ff8a3d")
## Hinweise zu den Munitionswerten (ohne Grenzen)
const UNLIMITED_NOTE := {"magazine": "ohne Grenzen · 0 = braucht keine Munition", "ammo_total": "ohne Grenzen · Obergrenze der Mitnahme, 0 = 3 Magazine",
	"shots": "ohne Grenzen · ab 2: Feuerstoß, +5 je Kugel"}

var tab := 0                  # 0 Waffen, 1 Rüstungen
var draft: Resource           # Entwurf (Kopie), null = nichts gewählt
var original: Resource        # gespeicherter Eintrag oder null (neu)
var picking := false          # Vorlage wählen
var _cols: HBoxContainer
var _list: VBoxContainer
var _form: VBoxContainer
var _confirm: Modal


func _ready() -> void:
	super._ready()
	max_size = Vector2(1300, 860)
	_confirm = Modal.new()
	_confirm.max_size = Vector2(600, 300)
	add_child(_confirm)


func show_editor() -> void:
	open("Eigene Ausrüstung")
	_cols = HBoxContainer.new()
	_cols.add_theme_constant_override("separation", 24)
	_cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(_cols)
	_list = VBoxContainer.new()
	_list.custom_minimum_size.x = 340
	_list.add_theme_constant_override("separation", 8)
	_cols.add_child(_list)
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size.x = 1
	_cols.add_child(sep)
	_form = VBoxContainer.new()
	_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_form.add_theme_constant_override("separation", 10)
	_cols.add_child(_form)
	refresh()


func refresh() -> void:
	_render_list()
	_render_form()


## Fußleiste: Löschen (bei gespeicherten), Speichern (bei Entwurf), Schließen
func _render_footer() -> void:
	UiTheme.clear(footer)
	footer.add_theme_constant_override("separation", 8)
	if draft and original:
		var del := UiTheme.button("Löschen")
		del.pressed.connect(_ask_delete)
		footer.add_child(del)
	if draft:
		var save := UiTheme.button("Speichern")
		save.add_theme_color_override("font_color", UiTheme.ACCENT)
		save.custom_minimum_size.x = 140
		save.pressed.connect(_save)
		footer.add_child(save)
	add_close()


# ---------------------------------------------------------------- Liste links

func _render_list() -> void:
	UiTheme.clear(_list)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	_list.add_child(tabs)
	for i in 2:
		var b := UiTheme.button(["Waffen", "Rüstungen"][i], "", true)
		b.button_pressed = i == tab
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 40
		b.pressed.connect(func() -> void:
			tab = i
			draft = null
			original = null
			picking = false
			refresh())
		tabs.add_child(b)
	_list.add_child(UiTheme.label("EIGENE", 13, UiTheme.MUTED))
	var items: Array = Gear.weapons() if tab == 0 else Gear.armors()
	if items.is_empty():
		_list.add_child(UiTheme.label("noch keine", 14, UiTheme.MUTED))
	for r in items:
		_list.add_child(_item(r))
	var add := UiTheme.button("+ Neu (Vorlage wählen)")
	add.custom_minimum_size.y = 40
	add.pressed.connect(func() -> void:
		picking = true
		draft = null
		original = null
		refresh())
	_list.add_child(add)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(sp)
	var note := UiTheme.label("Gespeichert für alle Spielstände und den Schnellkampf. Die vorhandenen Waffen und Rüstungen bleiben unverändert.", 12, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list.add_child(note)


func _item(r: Resource) -> Control:
	var b := Button.new()
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size.y = 48
	b.text = "%s%s\n%s" % [r.get("name"), "   [frei]" if Gear.is_free(r) else "", _sub(r)]
	b.add_theme_font_size_override("font_size", 14)
	if r == original:
		b.add_theme_stylebox_override("normal", UiTheme.box(Color("3a3215"), UiTheme.ACCENT, 6, 8))
	if Gear.is_free(r):
		b.add_theme_color_override("font_color", ORANGE)
	b.pressed.connect(func() -> void: _edit(r))
	return b


func _sub(r: Resource) -> String:
	if r is WeaponData:
		var w := r as WeaponData
		return "%s · %s" % [Rules.skill_name(w.skill), w.table.name if w.table else "–"]
	return "Klasse %d" % (r as ArmorData).cls


func _edit(r: Resource) -> void:
	original = r
	draft = r.duplicate()
	for m in r.get_meta_list():
		draft.set_meta(m, r.get_meta(m))
	picking = false
	refresh()


# ---------------------------------------------------------------- Formular rechts

func _render_form() -> void:
	UiTheme.clear(_form)
	_render_footer()
	if picking:
		_render_templates()
		return
	if draft == null:
		var l := UiTheme.label("Links einen Eintrag wählen oder „+ Neu“ für eine neue %s aus einer Vorlage." % ["Waffe", "Rüstung"][tab], 15, UiTheme.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_form.add_child(l)
		return
	# Name
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	_form.add_child(head)
	head.add_child(_cap("Name"))
	var name_edit := LineEdit.new()
	name_edit.text = String(draft.get("name"))
	name_edit.custom_minimum_size = Vector2(320, 38)
	name_edit.text_changed.connect(func(t: String) -> void: draft.set("name", t))
	head.add_child(name_edit)
	var t := Gear.template_of(draft)
	head.add_child(UiTheme.label("Vorlage: %s" % (t.get("name") if t else "–"), 13, UiTheme.MUTED))
	if Gear.is_free(draft):
		head.add_child(UiTheme.label("frei", 13, ORANGE))
	# Auswahl
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	_form.add_child(grid)
	if draft is WeaponData:
		_weapon_choices(grid, draft as WeaponData)
	else:
		grid.add_child(_cap("Klasse"))
		grid.add_child(UiTheme.label(str((draft as ArmorData).cls), 15, UiTheme.MUTED))
		grid.add_child(UiTheme.label("wie Vorlage", 13, UiTheme.MUTED))
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size.y = 1
	_form.add_child(sep)
	# Zahlenwerte
	var nums := GridContainer.new()
	nums.columns = 3
	nums.add_theme_constant_override("h_separation", 12)
	nums.add_theme_constant_override("v_separation", 6)
	_form.add_child(nums)
	for f in Gear.fields(draft):
		var lim := Gear.limits(draft, f)
		if lim.x == lim.y and not Gear.is_free(draft):
			continue          # kein Spielraum (z. B. Magazin 0 = ohne Nachladen)
		_num_row(nums, f)
	var free := CheckBox.new()
	free.text = "Werte frei eintragen (ohne Grenzen)"
	free.button_pressed = Gear.is_free(draft)
	free.toggled.connect(func(on: bool) -> void:
		draft.set_meta(&"free", on)
		if not on:
			Gear.clamp_all(draft)
		_render_form())
	_form.add_child(free)
	if Gear.is_free(draft):
		var w := UiTheme.label("Ohne Grenzen: Der Eintrag trägt überall den Vermerk „frei“ (Editor, Waffenkammer).", 14, ORANGE)
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_form.add_child(w)
	_form.add_child(_enemy_box())


func _render_templates() -> void:
	_form.add_child(UiTheme.label("VORLAGE WÄHLEN", 13, UiTheme.MUTED))
	var l := UiTheme.label("Die neue %s startet mit den Werten der Vorlage; die Zahlen lassen sich in Grenzen um die Vorlage ändern (oder frei)." % ["Waffe", "Rüstung"][tab], 14, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_form.add_child(l)
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 8)
	g.add_theme_constant_override("v_separation", 8)
	_form.add_child(g)
	var list: Array = Gear.base_weapons() if tab == 0 else Gear.base_armors()
	for t in list:
		var b := UiTheme.button(String(t.get("name")))
		b.custom_minimum_size = Vector2(260, 44)
		b.pressed.connect(func() -> void:
			draft = Gear.from_template(t)
			original = null
			picking = false
			refresh())
		g.add_child(b)


func _cap(text: String) -> Label:
	var l := UiTheme.label(text, 15)
	l.custom_minimum_size.x = 170
	return l


func _option(items: Array, selected: int, on_pick: Callable) -> OptionButton:
	var o := OptionButton.new()
	o.custom_minimum_size = Vector2(220, 34)
	for it in items:
		o.add_item(it)
	o.select(selected)
	o.item_selected.connect(on_pick)
	return o


func _weapon_choices(grid: GridContainer, w: WeaponData) -> void:
	grid.add_child(_cap("Fertigkeit"))
	var skills: Array = Gear.SKILLS
	grid.add_child(_option(skills.map(func(s: StringName) -> String: return Rules.skill_name(s)), maxi(0, skills.find(w.skill)),
		func(i: int) -> void: w.skill = skills[i]))
	grid.add_child(Control.new())
	grid.add_child(_cap("Angriffstabelle"))
	var tabs := Gear.tables()
	var ti := 0
	for i in tabs.size():
		if w.table and tabs[i].resource_path == w.table.resource_path:
			ti = i
	grid.add_child(_option(tabs.map(func(t: AttackTableData) -> String: return t.name), ti, func(i: int) -> void: w.table = tabs[i]))
	grid.add_child(Control.new())
	grid.add_child(_cap("Modell"))
	# Modell-Katalog des Bodenkampfs (WeaponModels): Nahkampfwaffen nur Nahkampfmodelle, Schusswaffen nur Schusswaffen
	var models: Array = WeaponModels.all().filter(func(m: Dictionary) -> bool: return bool(m.melee) == w.melee)
	var names := ["ohne"] + models.map(func(m: Dictionary) -> String: return m.name)
	var mi := 0
	for i in models.size():
		if w.model and models[i].model == w.model.resource_path:
			mi = i + 1
	grid.add_child(_option(names, mi, func(i: int) -> void:
		if i == 0:
			w.model = null
		else:
			var e: Dictionary = models[i - 1]
			WeaponModels.apply(w, e)
			if e.has("sound"):
				w.sound_id = e.sound
		_render_form()))
	grid.add_child(UiTheme.label("setzt Länge, Griff, Hände und den passenden Klang", 13, UiTheme.MUTED))
	grid.add_child(_cap("Klang"))
	var keys: Array = [&""] + WeaponData.SOUNDS.keys()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.add_child(_option(keys.map(func(k: StringName) -> String: return "automatisch (%s)" % WeaponData.SOUNDS.get(Gear.auto_sound(w), "") if k == &"" else String(WeaponData.SOUNDS[k])),
		maxi(0, keys.find(w.sound_id)), func(i: int) -> void: w.sound_id = keys[i]))
	var hear := UiTheme.button("▶", "Klang anhören")
	hear.custom_minimum_size = Vector2(40, 34)
	hear.pressed.connect(func() -> void: Sfx.play(w.sound()))
	row.add_child(hear)
	grid.add_child(row)
	grid.add_child(UiTheme.label("automatisch = aus den Werten abgeleitet", 13, UiTheme.MUTED))
	if not w.melee:
		grid.add_child(_cap("Munitionsart"))
		var types: Array = [&""] + Ammo.TYPES.keys()
		grid.add_child(_option(types.map(func(t: StringName) -> String: return "keine" if t == &"" else String(Ammo.TYPES[t])),
			maxi(0, types.find(w.ammo_type)), func(i: int) -> void: w.ammo_type = types[i]))
		grid.add_child(UiTheme.label("Schiffsvorrat dieser Art", 13, UiTheme.MUTED))
	grid.add_child(_cap("Hände"))
	grid.add_child(_option(["einhändig", "zweihändig"], 1 if w.two_handed else 0, func(i: int) -> void: w.two_handed = i == 1))
	grid.add_child(UiTheme.label("einhändig: Schild möglich", 13, UiTheme.MUTED))
	grid.add_child(_cap("Art"))
	grid.add_child(UiTheme.label("Nahkampf" if w.melee else "Fernkampf", 15, UiTheme.MUTED))
	grid.add_child(UiTheme.label("wie Vorlage", 13, UiTheme.MUTED))


## Zeile: Name, Wert (− / + in Grenzen, frei als Eingabefeld), Bereich
func _num_row(grid: GridContainer, f: Dictionary) -> void:
	grid.add_child(_cap(f.name))
	var v := Gear.get_value(draft, f)
	var lim := Gear.limits(draft, f)
	if Gear.is_free(draft) or f.get("unlimited", false):
		var s := SpinBox.new()
		s.min_value = lim.x
		s.max_value = lim.y
		s.step = f.step
		s.value = v
		s.custom_minimum_size = Vector2(160, 34)
		s.value_changed.connect(func(x: float) -> void: Gear.set_value(draft, f, x))
		grid.add_child(s)
		grid.add_child(UiTheme.label(String(UNLIMITED_NOTE.get(f.key, "")), 13, UiTheme.MUTED) if f.get("unlimited", false) else Control.new())
		return
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var minus := UiTheme.button("−")
	minus.custom_minimum_size = Vector2(36, 34)
	minus.disabled = v <= lim.x + 0.001
	var val := UiTheme.label(Gear.fmt(f, v), 16)
	val.custom_minimum_size.x = 80
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var plus := UiTheme.button("+")
	plus.custom_minimum_size = Vector2(36, 34)
	plus.disabled = v >= lim.y - 0.001
	for pair in [[minus, -1.0], [plus, 1.0]]:
		var dirv: float = pair[1]
		(pair[0] as Button).pressed.connect(func() -> void:
			Gear.set_value(draft, f, Gear.clamp_value(draft, f, Gear.get_value(draft, f) + dirv * float(f.step)))
			_render_form())
	row.add_child(minus)
	row.add_child(val)
	row.add_child(plus)
	grid.add_child(row)
	var t := Gear.template_of(draft)
	var tv := Gear.get_value(t, f) if t else v
	grid.add_child(UiTheme.label("%s bis %s (Vorlage %s)" % [Gear.fmt(f, lim.x), Gear.fmt(f, lim.y), Gear.fmt(f, tv)], 13, UiTheme.MUTED))


func _enemy_box() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BG, UiTheme.LINE, 8, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var on := CheckBox.new()
	on.text = "Auch für Gegner"
	on.button_pressed = bool(draft.get_meta(&"enemy", false))
	on.toggled.connect(func(x: bool) -> void:
		draft.set_meta(&"enemy", x)
		_render_form())
	v.add_child(on)
	# Fraktionsknöpfe umbrechen (seit Bodenkampf Auftrag 1 sind es 14 Fraktionen; nebeneinander lief das Fenster über)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	v.add_child(row)
	var fs: Array = draft.get_meta(&"factions", [])
	for f in Mission.all_factions():
		var b := UiTheme.button(f.name.split(" ")[0] if f.name.length() > 18 else f.name, f.name, true)
		b.button_pressed = f.resource_path in fs
		b.disabled = not on.button_pressed
		b.add_theme_color_override("font_color", f.color)
		b.add_theme_color_override("font_pressed_color", f.color)
		b.toggled.connect(func(x: bool) -> void:
			var cur: Array = draft.get_meta(&"factions", []).duplicate()
			if x and not f.resource_path in cur:
				cur.append(f.resource_path)
			elif not x:
				cur.erase(f.resource_path)
			draft.set_meta(&"factions", cur))
		row.add_child(b)
	return p


# ---------------------------------------------------------------- Speichern, Löschen

func _save() -> void:
	if String(draft.get("name")).strip_edges() == "":
		draft.set("name", "Ohne Namen")
	var r := Gear.save(draft, original)
	if r == null:
		return
	Sfx.play(&"klick")
	_edit(r)


func _ask_delete() -> void:
	_confirm.open("%s löschen?" % original.get("name"))
	var l := UiTheme.label("Gilt für alle Spielstände und den Roster. Wer sie trägt, bekommt stattdessen:\n%s" % (
		"Waffe 1 → Fäuste, Waffe 2 → leer." if original is WeaponData else "Rüstung → keine."), 15)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm.content.add_child(l)
	_confirm.add_close("Abbrechen")
	var del := UiTheme.button("Löschen")
	del.add_theme_color_override("font_color", UiTheme.BAD)
	del.pressed.connect(func() -> void:
		Gear.delete(original)
		original = null
		draft = null
		_confirm.hide()
		refresh())
	_confirm.footer.add_child(del)
	_confirm.move_to_front()
