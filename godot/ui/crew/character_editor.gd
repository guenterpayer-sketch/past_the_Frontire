class_name CharacterEditor
extends Modal
## Charakter-Modul: neues Crewmitglied erschaffen (Regeln: Creation, docs/Skillsystem.md 7a).
## 7 Würfe frei auf die Eigenschaften legen, Fertigkeitspunkte verteilen, Station, Aussehen und Ausrüstung wählen.
## Im Roster (open_for_roster): neue Figur für den globalen Roster. Im Spiel (open_new, nur noch für alte Aufrufe):
## als neues Mitglied (wenn Platz ist) oder als Ersatz für ein vorhandenes.

signal saved(ch: Character, replace: Character)

const MAX_CREW := 6
const COLORS := [Color("ffd34d"), Color("5db7ff"), Color("6fdc6f"), Color("ff9f5d"), Color("c58bff"), Color("5de0d0"), Color("ff7eb6")]

var _crew: Array[Character] = []
var _ch: Character
var _pool: Array[int] = []
var _assign := {}          # Eigenschaft -> Index im Wurf
var _target := -1          # -1 = neues Mitglied, sonst Index des ersetzten Mitglieds
var _for_roster := false
var _left: VBoxContainer
var _right: VBoxContainer
var _points: Label
var _save: Button
var _weapons: Array[WeaponData] = []
var _armors: Array[ArmorData] = []
var _visuals: Array[CharacterVisual] = []
var _psi_view: PsiListView


func _ready() -> void:
	super()
	title_bar.add_child(CrewWidgets.burger(self))


## Neue Figur für den globalen Roster erschaffen; saved(ch, null) liefert sie (noch nicht gespeichert)
func open_for_roster() -> void:
	open_new([], 0, true)


## Editor für ein neues Crewmitglied öffnen; replace_idx = vorgeschlagenes Mitglied zum Ersetzen (bei voller Crew)
func open_new(crew: Array[Character], replace_idx := 0, for_roster := false) -> void:
	_crew = crew
	_for_roster = for_roster
	_load_choices()
	_ch = Character.new()
	_ch.name = "Neue Figur" if for_roster else "Neues Crewmitglied"
	_ch.letter = "N"
	_ch.color = COLORS[crew.size() % COLORS.size()]
	_ch.medkits = 3
	_ch.weapons = [_find_weapon(&"laserpistole"), _find_weapon(&"faeuste")]
	_ch.armor = _armors[mini(1, _armors.size() - 1)]
	# Vorgabe: erstes Menschen-Modell (der Mech passt nicht zu einer neuen Figur)
	var human := _visuals.filter(func(v: CharacterVisual) -> bool: return not v.resource_path.get_file().begins_with("mech"))
	_ch.visual = human[0] if not human.is_empty() else (_visuals[0] if not _visuals.is_empty() else null)
	_target = -1 if crew.size() < MAX_CREW else clampi(replace_idx, 0, crew.size() - 1)
	_reroll()
	if _psi_view:
		_psi_view.hide()
	open("Neue Figur für den Roster erschaffen" if for_roster else "Neues Crewmitglied erschaffen")
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	content.add_child(cols)
	_left = VBoxContainer.new()
	_left.custom_minimum_size.x = 420
	cols.add_child(_left)
	_right = VBoxContainer.new()
	_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(_right)
	_points = UiTheme.label("", 18, UiTheme.ACCENT)
	_points.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_points)
	var target := OptionButton.new()
	if crew.size() < MAX_CREW:
		target.add_item("als neues Mitglied", 0)
	for i in crew.size():
		target.add_item("ersetzt %s" % crew[i].name, i + 1)
	target.select(target.get_item_index(_target + 1))
	target.item_selected.connect(func(idx: int) -> void: _target = target.get_item_id(idx) - 1)
	target.tooltip_text = "Die Crew hat höchstens %d Mitglieder" % MAX_CREW
	if not for_roster:
		footer.add_child(target)
	else:
		target.free()
	add_close("Abbrechen")
	_save = UiTheme.button("Übernehmen")
	_save.add_theme_color_override("font_color", UiTheme.ACCENT)
	_save.pressed.connect(_finish)
	footer.add_child(_save)
	_render()


func _load_choices() -> void:
	_weapons = GameData.weapons()
	_armors = []
	for f in ResourceLoader.list_directory("res://data/armor"):
		if f.ends_with(".tres"):
			_armors.append(load("res://data/armor/" + f))
	_armors.sort_custom(func(a: ArmorData, b: ArmorData) -> bool: return a.resource_path < b.resource_path)
	_visuals = []
	for f in ResourceLoader.list_directory("res://data/visuals/characters"):
		if f.ends_with(".tres"):
			_visuals.append(load("res://data/visuals/characters/" + f))


func _find_weapon(id: StringName) -> WeaponData:
	for w in _weapons:
		if w.id == id:
			return w
	return _weapons[0]


## Neu würfeln: Würfe der Reihe nach auf die Eigenschaften legen, Ränge verfallen
func _reroll() -> void:
	_pool = Creation.roll_pool()
	_assign.clear()
	for i in Rules.ATTRIBUTES.size():
		_assign[Rules.ATTRIBUTES[i].id] = i
	_ch.skills = {}
	_sync_attrs()


func _sync_attrs() -> void:
	_ch.attrs = {}
	for a in Rules.ATTRIBUTES:
		_ch.attrs[a.id] = _pool[_assign[a.id]]


func _render() -> void:
	UiTheme.clear(_left)
	UiTheme.clear(_right)
	_render_left()
	_render_skills()
	var left := Creation.points_left(_ch)
	_points.text = "Fertigkeitspunkte: %d von %d frei" % [left, Creation.budget(_ch)]
	_points.add_theme_color_override("font_color", UiTheme.BAD if left < 0 else UiTheme.ACCENT)
	_save.disabled = left < 0 or _ch.name.strip_edges() == ""


# ---------------------------------------------------------------- links: Person, Würfe, Eigenschaften

func _render_left() -> void:
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	_left.add_child(g)
	g.add_child(UiTheme.label("Name", 13, UiTheme.MUTED))
	var name_edit := LineEdit.new()
	name_edit.text = _ch.name
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.text_changed.connect(func(t: String) -> void:
		_ch.name = t
		_save.disabled = Creation.points_left(_ch) < 0 or t.strip_edges() == "")
	g.add_child(name_edit)
	g.add_child(UiTheme.label("Kürzel, Farbe", 13, UiTheme.MUTED))
	var hb := HBoxContainer.new()
	var letter := LineEdit.new()
	letter.text = _ch.letter
	letter.max_length = 1
	letter.custom_minimum_size.x = 40
	letter.text_changed.connect(func(t: String) -> void: _ch.letter = t.to_upper())
	hb.add_child(letter)
	var col := ColorPickerButton.new()
	col.color = _ch.color
	col.edit_alpha = false
	col.custom_minimum_size = Vector2(60, 28)
	col.color_changed.connect(func(c: Color) -> void: _ch.color = c)
	hb.add_child(col)
	g.add_child(hb)
	g.add_child(UiTheme.label("Station", 13, UiTheme.MUTED))
	var st := OptionButton.new()
	for i in Creation.STATIONS.size():
		var s: String = Creation.STATIONS[i]
		st.add_item(s if s != "" else "keine", i)
		st.set_item_disabled(i, not Creation.station_free(_crew_without_target(), s))
	st.select(Creation.STATIONS.find(_ch.station))
	st.item_selected.connect(func(i: int) -> void:
		_ch.station = Creation.STATIONS[i]
		_ch.role = _ch.station)
	st.tooltip_text = "Jede Station nur einmal, Jäger mehrfach (docs/Raumkampf.md)"
	g.add_child(st)
	g.add_child(UiTheme.label("Aussehen", 13, UiTheme.MUTED))
	g.add_child(_choice(_visuals.map(func(v: CharacterVisual) -> String: return v.resource_path.get_file().get_basename().replace("_", " ")),
		_visuals.find(_ch.visual), func(i: int) -> void: _ch.visual = _visuals[i]))
	for slot in 2:
		g.add_child(UiTheme.label("Waffe %d" % (slot + 1), 13, UiTheme.MUTED))
		g.add_child(_choice(_weapons.map(func(w: WeaponData) -> String: return w.name), _weapons.find(_ch.weapons[slot]),
			func(i: int) -> void: _ch.weapons[slot] = _weapons[i]))
	g.add_child(UiTheme.label("Rüstung", 13, UiTheme.MUTED))
	var ah := HBoxContainer.new()
	ah.add_child(_choice(_armors.map(func(a: ArmorData) -> String: return a.name), _armors.find(_ch.armor),
		func(i: int) -> void: _ch.armor = _armors[i]))
	var shield := CheckBox.new()
	shield.text = "Schild"
	shield.button_pressed = _ch.shield
	shield.toggled.connect(func(on: bool) -> void: _ch.shield = on)
	ah.add_child(shield)
	g.add_child(ah)
	var hint := UiTheme.label("Ausrüstung frei wählbar (Regeln für Kauf gibt es noch nicht).", 11, UiTheme.MUTED)
	_left.add_child(hint)

	# Würfe
	var wh := HBoxContainer.new()
	var wl := UiTheme.label("Würfe (der niedrigste wurde zu %d)" % Creation.LOWEST_TO, 13, UiTheme.MUTED)
	wl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wh.add_child(wl)
	var rr := UiTheme.button("neu würfeln", "Neue Würfe; verteilte Ränge verfallen")
	rr.pressed.connect(func() -> void:
		_reroll()
		_render())
	wh.add_child(rr)
	_left.add_child(wh)
	_left.add_child(UiTheme.label("  ".join(_pool.map(func(v: int) -> String: return str(v))), 18, UiTheme.TEXT))

	var ag := GridContainer.new()
	ag.columns = 3
	ag.add_theme_constant_override("h_separation", 12)
	for h in ["Eigenschaft", "Wurf", "Bonus"]:
		ag.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	for a in Rules.ATTRIBUTES:
		ag.add_child(UiTheme.label(a.name, 13))
		var ob := OptionButton.new()
		for i in _pool.size():
			ob.add_item(str(_pool[i]), i)
		ob.select(_assign[a.id])
		ob.tooltip_text = "Wurf wählen; die Eigenschaft, die ihn hatte, bekommt den bisherigen"
		ob.item_selected.connect(_swap.bind(a.id))
		ag.add_child(ob)
		var b := Rules.attr_bonus(_ch.attrs[a.id])
		ag.add_child(UiTheme.label(Dice.fmt(b), 13, UiTheme.GOOD if b > 0 else (UiTheme.BAD if b < 0 else UiTheme.TEXT)))
	_left.add_child(ag)

	var d := UiTheme.label("Eigenschaftssumme %d → %d Fertigkeitspunkte (× %s)\nTrefferpunkte %d · Psi-Punkte %s · Initiative 2W10 %s" % [
		Creation.attr_sum(_ch), Creation.budget(_ch), str(Creation.POINTS_FACTOR).replace(".", ","), Rules.max_hp(_ch),
		str(Rules.max_pp(_ch)) if Rules.has_psi(_ch) else "–", Dice.fmt(Rules.initiative_bonus(_ch))], 13, UiTheme.MUTED)
	_left.add_child(d)
	_left.add_child(_psi_powers())


func _crew_without_target() -> Array:
	return _crew.filter(func(c: Character) -> bool: return _target < 0 or c != _crew[_target])


func _choice(items: Array, selected: int, on_select: Callable) -> OptionButton:
	var ob := OptionButton.new()
	for i in items.size():
		ob.add_item(items[i], i)
	ob.select(maxi(0, selected))
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ob.item_selected.connect(func(i: int) -> void: on_select.call(i))
	return ob


## Wurf idx auf Eigenschaft attr legen; wer ihn hatte, bekommt den bisherigen Wurf
func _swap(idx: int, attr: String) -> void:
	var old: int = _assign[attr]
	for k in _assign:
		if k != attr and _assign[k] == idx:
			_assign[k] = old
	_assign[attr] = idx
	_sync_attrs()
	_render.call_deferred()


func _psi_powers() -> Control:
	var v := VBoxContainer.new()
	v.add_child(UiTheme.label("Psi-Kräfte", 13, UiTheme.MUTED))
	var learned := PsiLists.learned(_ch)
	if learned.is_empty():
		v.add_child(UiTheme.label("keine Psi-Liste gelernt (höchstens %d bei der Erschaffung)" % Creation.MAX_LISTS, 12, UiTheme.MUTED))
	for id in learned:
		var l: Dictionary = PsiLists.LISTS[id]
		var r := Rules.skill_rank(_ch, id)
		v.add_child(UiTheme.label("%s – Rang %d · %s" % [l.name, r, l.probe], 13, UiTheme.CREW))
		for p in l.powers:
			var on: bool = p[0] <= r
			var pl := UiTheme.label("  %d  %s (%d PP): %s" % [p[0], p[1], p[0], p[2]], 12, UiTheme.TEXT if on else UiTheme.MUTED)
			pl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			pl.custom_minimum_size.x = 400
			if not on:
				pl.modulate.a = 0.6
			v.add_child(pl)
	var all := _psi_info_button(&"", "Alle Psi-Listen ansehen")
	all.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(all)
	return v


## Knopf, der die Übersicht der Psi-Listen öffnet (list leer = erste gelernte Liste)
func _psi_info_button(list: StringName, text: String) -> Button:
	var b := UiTheme.button(text, "Diese Psi-Liste in der Enzyklopädie" if list != &"" else "Rang und Kräfte dieser Figur in allen Psi-Listen")
	b.add_theme_font_size_override("font_size", 12)
	b.add_theme_color_override("font_color", PsiListView.PSI)
	b.pressed.connect(func() -> void:
		if list != &"":
			Encyclopedia.show_on(self, &"psi", PsiLists.LISTS[list].name).move_to_front()
			return
		if _psi_view == null:
			_psi_view = PsiListView.new()
			add_child(_psi_view)
		_psi_view.open_for(_ch, list)
		_psi_view.move_to_front())
	return b


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE and CrewWidgets.close_encyclopedia(self):
		get_viewport().set_input_as_handled()
		return
	if _psi_view and _psi_view.visible and e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		_psi_view.close()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- rechts: Fertigkeiten

func _render_skills() -> void:
	_right.add_child(UiTheme.label("Fertigkeiten: Rang kostet 10 + 2 × Rang; höchstens Rang %d, %d Fertigkeiten bis %d; höchstens %d Psi-Listen" % [
		Creation.RANK_CAP, Creation.HIGH_SKILLS, Creation.RANK_CAP_HIGH, Creation.MAX_LISTS], 13, UiTheme.MUTED))
	for grp in Rules.SKILL_GROUPS:
		_right.add_child(UiTheme.label(grp.name, 13, UiTheme.ACCENT))
		var g := GridContainer.new()
		g.columns = 6
		g.add_theme_constant_override("h_separation", 10)
		for sk in grp.skills:
			var id := StringName(sk[0])
			var r := Rules.skill_rank(_ch, id)
			var nl := UiTheme.label(sk[1], 13, UiTheme.TEXT if r > 0 else UiTheme.MUTED)
			nl.custom_minimum_size.x = 190
			if PsiLists.is_list(id):
				g.add_child(_psi_cell(id, nl))
			else:
				g.add_child(nl)
			var ab := Rules.attr_bonus(_ch.attrs[sk[2]]) + Rules.attr_bonus(_ch.attrs[sk[3]])
			var el := UiTheme.label("%s+%s %s" % [Rules.attr_short(sk[2]), Rules.attr_short(sk[3]), Dice.fmt(ab)], 12, UiTheme.MUTED)
			el.custom_minimum_size.x = 100
			g.add_child(el)
			g.add_child(UiTheme.label(str(r), 13))
			var fx := UiTheme.label(_effect(id, r), 13, UiTheme.TEXT if r > 0 else UiTheme.MUTED)
			fx.custom_minimum_size.x = 64
			g.add_child(fx)
			var minus := UiTheme.button("−", "Rang senken")
			minus.disabled = r == 0
			minus.custom_minimum_size.x = 30
			minus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			minus.pressed.connect(func() -> void:
				Creation.lower(_ch, id)
				_render.call_deferred())
			g.add_child(minus)
			var why := Creation.raise_block(_ch, id)
			var plus := UiTheme.button("+ (%d)" % Rules.rank_cost(r), why if why != "" else "Rang %d für %d Punkte" % [r + 1, Rules.rank_cost(r)])
			plus.disabled = why != ""
			plus.custom_minimum_size.x = 56
			plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			plus.pressed.connect(func() -> void:
				Creation.raise(_ch, id)
				_render.call_deferred())
			g.add_child(plus)
		_right.add_child(g)


## Name einer Psi-Liste mit ⓘ und darunter, was die Liste bringt (vor der Wahl: die ersten Kräfte)
func _psi_cell(id: StringName, name_label: Label) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var h := HBoxContainer.new()
	h.add_child(name_label)
	h.add_child(_psi_info_button(id, "ⓘ"))
	v.add_child(h)
	var hint := UiTheme.label(PsiListView.preview_hint(_ch, id), 11, UiTheme.MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.custom_minimum_size.x = 240
	v.add_child(hint)
	return v


## Was ein Rang bringt: Gesamtbonus, bei Entwicklung TP/PP, bei Listen die Zahl der Kräfte
func _effect(id: StringName, r: int) -> String:
	if id == &"koerper":
		return "+%d TP" % (r * Rules.HP_PER_RANK)
	if id == &"psiPunkte":
		return "+%d PP" % (r * Rules.PP_PER_RANK)
	if PsiLists.is_list(id):
		return "%d Kräfte" % PsiLists.powers(_ch, id).size()
	return Dice.fmt(Rules.skill_total(_ch, id))


func _finish() -> void:
	if Creation.points_left(_ch) < 0:
		return
	_ch.name = _ch.name.strip_edges()
	if _ch.letter == "":
		_ch.letter = _ch.name.left(1).to_upper()
	_ch.id = GlobalRoster.unique_id(_ch.name) if _for_roster else _unique_id(_ch.name)
	if _ch.role == "":
		_ch.role = _ch.station if _ch.station != "" else "Crew"
	var replace: Character = _crew[_target] if _target >= 0 else null
	closable = true
	hide()
	saved.emit(_ch, replace)


func _unique_id(n: String) -> StringName:
	var base := n.to_lower().validate_filename().replace(" ", "_")
	if base == "":
		base = "figur"
	var id := base
	var i := 2
	while _crew.any(func(c: Character) -> bool: return String(c.id) == id):
		id = "%s_%d" % [base, i]
		i += 1
	return StringName(id)
