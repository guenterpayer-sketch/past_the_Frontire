class_name MapEditor
extends Node3D
## Karteneditor (Startmenü „Karteneditor“, eigene Szene map_editor.tscn). Links die eigenen Karten und die Angaben
## der gewählten Karte (Name, Kartentyp, „im Spiel verwenden“, Prüfung), oben Ansicht (Draufsicht / 3D) und Werkzeuge
## (Pinsel, Rechteck, Pipette, Höhe, Rückgängig), rechts die Bausteine (Gelände) und Startfelder. Gemalt wird in
## beiden Ansichten mit der linken Maustaste; rechte/mittlere Taste verschiebt, Mausrad zoomt, Q/E dreht die 3D-Ansicht.
## Speichern und Regeln: CustomMaps.

const LEFT_W := 300.0
const RIGHT_W := 236.0
const TOP_H := 52.0
const CREW_MARK := &"@crew"
const ENEMY_MARK := &"@enemy"
const CLEAR_MARK := &"@clear"
## Bausteine in Gruppen (Gelände aus BattleMap.TERRAIN)
const PALETTE := [
	["Boden", [&"boden", &"gehweg", &"podest", &"treppe", &"leiter"]],
	["Wände (sperren die Sicht)", [&"wand", &"innenwand", &"gebaeude", &"leer"]],
	["Begehbar, erhöht", [&"kiste", &"container", &"regal", &"galerie"]],
	["Halbe Deckung", [&"fass", &"barriere", &"theke", &"tisch", &"sofa", &"tonne", &"bruch", &"geroell", &"altar", &"schreibtisch", &"konsole"]],
	["Volle Deckung", [&"saeule", &"schrank", &"server", &"auto", &"statue", &"tank", &"steinsaeule", &"laterne"]],
]
## Farben der Draufsicht
const COLORS := {&"gehweg": Color(0.5, 0.5, 0.53), &"podest": Color(0.55, 0.42, 0.3), &"treppe": Color(0.75, 0.65, 0.3),
	&"leiter": Color(0.9, 0.75, 0.2), &"wand": Color(0.08, 0.09, 0.13), &"innenwand": Color(0.13, 0.15, 0.2),
	&"gebaeude": Color(0.24, 0.2, 0.2), &"leer": Color(0.02, 0.02, 0.04), &"kiste": Color(0.66, 0.48, 0.27),
	&"container": Color(0.62, 0.32, 0.25), &"regal": Color(0.45, 0.33, 0.22), &"galerie": Color(0.42, 0.5, 0.6)}
const HALF_COLOR := Color(0.62, 0.6, 0.35)
const FULL_COLOR := Color(0.55, 0.3, 0.32)

var d := {}                  # Karte (CustomMaps-Format), leer = keine gewählt
var crew := {}               # Vector2i(Spalte, Reihe) -> true
var enemy := {}
var brush: StringName = &"innenwand"
var brush_h := 0
var tool: StringName = &"pinsel"   # pinsel, rechteck, pipette
var view_3d := false
var dirty := false
var check_res := {}
var _undo: Array = []
var _stroke := false
var _rect_from: Variant = null     # Vector2i (Spalte, Reihe) beim Rechteck
var _hover: Variant = null
var _panning := false
var _pos_cell := {}                # axiale Position -> Vector2i(Spalte, Reihe)

var _env: WorldEnvironment
var _sun: DirectionalLight3D
var map_view: MapView
var rig: CameraRig
var _marks: Node3D
var _hover_mi: MeshInstance3D
var _view_map: BattleMap
var _view_stale := true

var root: Control
var canvas: Canvas
var _list: VBoxContainer
var _name: LineEdit
var _type: OptionButton
var _size_l: Label
var _active: CheckButton
var _check_l: RichTextLabel
var _info_l: Label
var _height_l: Label
var _tool_btns := {}
var _view_btns: Array[Button] = []
var _brush_btns := {}
var _right: PanelContainer
var _new_dlg: Modal
var _confirm: Modal


## Draufsicht: Hexfelder als Flächen, Höhe als Zahl, Startfelder als Kreise
class Canvas:
	extends Control
	var ed: MapEditor
	var zoom := 18.0
	var origin := Vector2(40, 40)

	func to_screen(p: Vector2i) -> Vector2:
		return origin + Hex.to_world(p) * zoom

	func cell_at(screen: Vector2) -> Variant:
		var ax := Hex.from_world((screen - origin) / zoom)
		return ed._pos_cell.get(ax)

	func fit() -> void:
		if ed.d.is_empty():
			return
		var w: float = ed.d.cols * Hex.SIZE_M + 1.0
		var h: float = ed.d.rows * Hex.ROW_M + 1.0
		zoom = minf((size.x - 40) / w, (size.y - 40) / h)
		origin = (size - Vector2(w, h) * zoom) / 2.0 + Vector2(0.9, 0.9) * zoom
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), UiTheme.BG)
		if ed.d.is_empty():
			return
		var font := ThemeDB.fallback_font
		var cs := Hex.corners(Hex.RADIUS_M * zoom * 0.99)
		var small := Hex.corners(Hex.RADIUS_M * zoom * 0.62)
		var floor: Color = MapTypes.info(StringName(ed.d.type)).floor
		var unreach := {}
		for p in ed.check_res.get("unreachable", []):
			unreach[Vector2i(int(p[0]), int(p[1]))] = true
		var rect: Array = ed._rect_cells()
		for r in ed.d.rows:
			for c in ed.d.cols:
				var x := CustomMaps.cell(ed.d, c, r)
				var t: StringName = x[0]
				var h: int = x[1]
				var ctr := to_screen(Hex.from_offset(c, r))
				var info: Dictionary = BattleMap.TERRAIN[t]
				var obj: float = info.get("obj", 0.0)
				var base: Color = COLORS.get(t, floor)
				if obj > 0.0 and not COLORS.has(t):
					base = floor
				base = base.lightened(minf(h * 0.08, 0.4))
				draw_colored_polygon(_shift(cs, ctr), base)
				if obj > 0.0 and not COLORS.has(t):
					draw_colored_polygon(_shift(small, ctr), FULL_COLOR if obj >= BattleMap.FULL else HALF_COLOR)
				if zoom >= 14.0:
					var tag := ""
					if obj > 0.0 and not COLORS.has(t):
						tag = String(info.name).substr(0, 2)
					elif h > 0:
						tag = str(h)
					if tag != "":
						var fs := int(zoom * 0.5)
						draw_string(font, ctr + Vector2(-zoom * 0.45, fs * 0.35), tag, HORIZONTAL_ALIGNMENT_CENTER, zoom * 0.9, fs, Color(1, 1, 1, 0.85))
				var cell := Vector2i(c, r)
				if ed.crew.has(cell):
					draw_circle(ctr, zoom * 0.38, UiTheme.CREW)
				if ed.enemy.has(cell):
					draw_circle(ctr, zoom * 0.38, UiTheme.ENEMY)
				if unreach.has(cell):
					draw_polyline(_shift(cs, ctr, true), UiTheme.BAD, 2.0)
				if cell in rect:
					draw_polyline(_shift(cs, ctr, true), UiTheme.ACCENT, 2.0)
		if ed._hover != null and rect.is_empty():
			draw_polyline(_shift(cs, to_screen(Hex.from_offset(ed._hover.x, ed._hover.y)), true), Color.WHITE, 2.0)

	func _shift(pts: Array[Vector2], c: Vector2, closed := false) -> PackedVector2Array:
		var out := PackedVector2Array()
		for p in pts:
			out.append(c + p)
		if closed:
			out.append(c + pts[0])
		return out

	func _gui_input(e: InputEvent) -> void:
		ed._canvas_input(e)


func _ready() -> void:
	UiScale.apply(get_tree())
	_build_scene()
	_build_ui()
	var maps := CustomMaps.list()
	var back := CustomMaps.load_map(CustomMaps.editor_return)
	CustomMaps.editor_return = ""
	if not back.is_empty():
		_select(back)
	elif maps.is_empty():
		_select(CustomMaps.from_generator("Meine erste Karte", &"halle", "mittel", false, randi() % 100000))
	else:
		_select(maps[0])
	if "--autotest-editor" in OS.get_cmdline_user_args() and not get_tree().root.has_node("EditorAutotest"):
		var t: Node = load("res://tests/autotest_editor.gd").new()
		t.name = "EditorAutotest"
		t.set("editor", self)
		get_tree().root.add_child.call_deferred(t)


# ---------------------------------------------------------------- 3D-Szene

func _build_scene() -> void:
	_env = WorldEnvironment.new()
	_env.environment = Environment.new()
	_env.environment.background_mode = Environment.BG_COLOR
	_env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(_env)
	_sun = DirectionalLight3D.new()
	_sun.transform = Transform3D(Basis(Vector3(0.819, 0, 0.574), Vector3(0.33, 0.818, -0.471), Vector3(-0.469, 0.575, 0.67)), Vector3(0, 20, 0))
	_sun.shadow_enabled = not OS.has_feature("mobile")
	_sun.shadow_bias = 0.08
	_sun.shadow_normal_bias = 1.5
	add_child(_sun)
	map_view = MapView.new()
	add_child(map_view)
	_marks = Node3D.new()
	add_child(_marks)
	rig = CameraRig.new()
	var arm := Node3D.new()
	arm.name = "Arm"
	rig.add_child(arm)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	arm.add_child(cam)
	add_child(rig)
	cam.current = true
	rig.rotated.connect(func() -> void: map_view.update_cutaway(rig.view_dir()))
	_hover_mi = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = Hex.RADIUS_M * 0.95
	cyl.bottom_radius = Hex.RADIUS_M * 0.95
	cyl.height = 0.06
	cyl.radial_segments = 6
	_hover_mi.mesh = cyl
	_hover_mi.material_override = _unshaded(Color(1, 1, 1, 0.45))
	_hover_mi.rotation.y = PI / 6.0
	_hover_mi.visible = false
	add_child(_hover_mi)


func _unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	return m


## 3D-Ansicht neu bauen (nach jedem Strich, beim Umschalten und beim Kartenwechsel)
func _rebuild_3d(refocus := false) -> void:
	_view_stale = false
	_view_map = CustomMaps.terrain_map(_data())
	var info := MapTypes.info(_view_map.map_type)
	_env.environment.background_color = info.bg
	_env.environment.ambient_light_color = info.ambient
	_env.environment.ambient_light_energy = info.ambient_energy
	_sun.light_color = info.sun
	_sun.light_energy = info.sun_energy
	map_view.theme = GameData.hall_theme()
	map_view.build(_view_map)
	map_view.set_grid_visible(true)
	var c := map_view.center()
	rig.bounds = Rect2(-2, -2, c.x * 2 + 4, c.z * 2 + 4)
	if refocus:
		rig.focus(c)
		rig.camera.size = clampf(maxf(d.cols, d.rows) * 1.25, CameraRig.MIN_SIZE, CameraRig.MAX_SIZE)
	rig.right_inset = RIGHT_W - LEFT_W
	map_view.update_cutaway(rig.view_dir())
	_rebuild_marks()


func _rebuild_marks() -> void:
	for ch in _marks.get_children():
		ch.queue_free()
	if _view_map == null:
		return
	var disc := CylinderMesh.new()
	disc.top_radius = 0.45
	disc.bottom_radius = 0.45
	disc.height = 0.08
	var mats := {CREW_MARK: _unshaded(Color(UiTheme.CREW, 0.85)), ENEMY_MARK: _unshaded(Color(UiTheme.ENEMY, 0.85)),
		&"bad": _unshaded(Color(UiTheme.BAD, 0.5))}
	var add := func(cell: Vector2i, kind: StringName) -> void:
		var mi := MeshInstance3D.new()
		mi.mesh = disc
		mi.material_override = mats[kind]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = map_view.tile_top(Hex.from_offset(cell.x, cell.y)) + Vector3(0, 0.08, 0)
		_marks.add_child(mi)
	for cell in crew:
		add.call(cell, CREW_MARK)
	for cell in enemy:
		add.call(cell, ENEMY_MARK)
	for p in check_res.get("unreachable", []):
		add.call(Vector2i(int(p[0]), int(p[1])), &"bad")


## Feld unter dem Mauszeiger in 3D (Ebenen je Höhenstufe von oben nach unten, wie im Kampf)
func _pick_3d(screen: Vector2) -> Variant:
	if _view_map == null:
		return null
	for h in range(CustomMaps.MAX_H + 1, -1, -1):
		var p: Variant = rig.ray_plane(screen, h * BattleMap.LEVEL_M)
		if p == null:
			continue
		var t := _view_map.tile(Hex.from_world(Vector2(p.x, p.z)))
		if t and t.h == h:
			return Vector2i(t.col, t.row)
	return null


# ---------------------------------------------------------------- Oberfläche

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	root = Control.new()
	root.theme = UiTheme.build()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	canvas = Canvas.new()
	canvas.ed = self
	canvas.anchor_right = 1.0
	canvas.anchor_bottom = 1.0
	canvas.offset_left = LEFT_W
	canvas.offset_right = -RIGHT_W
	canvas.offset_top = TOP_H
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.focus_mode = Control.FOCUS_NONE
	canvas.resized.connect(canvas.fit)
	root.add_child(canvas)
	_build_left()
	_build_top()
	_build_right()
	_new_dlg = Modal.new()
	_new_dlg.max_size = Vector2(620, 430)
	root.add_child(_new_dlg)
	_confirm = Modal.new()
	_confirm.max_size = Vector2(560, 260)
	root.add_child(_confirm)


func _panel(left: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.anchor_bottom = 1.0
	if left:
		p.offset_right = LEFT_W
	else:
		p.anchor_left = 1.0
		p.anchor_right = 1.0
		p.offset_left = -RIGHT_W
	root.add_child(p)
	return p


func _build_left() -> void:
	var p := _panel(true)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	v.add_child(UiTheme.label("KARTENEDITOR", 20, UiTheme.ACCENT))
	v.add_child(UiTheme.label("EIGENE KARTEN", 12, UiTheme.MUTED))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size.y = 190
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(_list)
	var row := HBoxContainer.new()
	v.add_child(row)
	var nb := UiTheme.button("+ Neu", "Neue Karte: leer, Zufallskarte als Vorlage oder Kopie")
	nb.pressed.connect(func() -> void: _ask_discard(_show_new))
	row.add_child(nb)
	var del := UiTheme.button("Löschen", "Gewählte Karte löschen")
	del.pressed.connect(_ask_delete)
	row.add_child(del)
	v.add_child(HSeparator.new())
	_name = LineEdit.new()
	_name.placeholder_text = "Name der Karte"
	_name.text_changed.connect(func(s: String) -> void:
		d.name = s
		_set_dirty())
	v.add_child(_name)
	_type = OptionButton.new()
	for id in MapTypes.TYPES:
		_type.add_item("Kartentyp: %s" % MapTypes.type_name(id))
		_type.set_item_metadata(_type.item_count - 1, String(id))
	_type.tooltip_text = "Aussehen, Licht und Modelle; im Spiel kommt die Karte nur bei Einsätzen dieses Typs (Raumschiff: beim Entern)"
	_type.item_selected.connect(func(i: int) -> void:
		d.type = _type.get_item_metadata(i)
		_set_dirty(true))
	v.add_child(_type)
	_size_l = UiTheme.label("", 13, UiTheme.MUTED)
	_size_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_size_l)
	_active = CheckButton.new()
	_active.text = "Im Spiel verwenden"
	_active.tooltip_text = "Aktive Karten ersetzen bei Einsätzen ihres Kartentyps mit %d %% die Zufallskarte (Schnellkampf: auch über „Ort“ wählbar)" % roundi(CustomMaps.CHANCE * 100)
	_active.toggled.connect(func(on: bool) -> void:
		d.active = on
		_set_dirty())
	v.add_child(_active)
	_info_l = UiTheme.label("", 13)
	_info_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_info_l)
	_check_l = Modal.rich("")
	_check_l.add_theme_font_size_override("normal_font_size", 12)
	v.add_child(_check_l)
	var row2 := HBoxContainer.new()
	v.add_child(row2)
	var chk := UiTheme.button("Prüfen", "Startfelder je Lage und Erreichbarkeit prüfen")
	chk.pressed.connect(run_check)
	row2.add_child(chk)
	var sv := UiTheme.button("Speichern")
	sv.add_theme_color_override("font_color", UiTheme.ACCENT)
	sv.pressed.connect(save)
	row2.add_child(sv)
	var test := UiTheme.button("Probekampf", "Speichern und einen Schnellkampf auf dieser Karte starten (Figuren aus dem Roster, nichts wird verbucht)")
	test.pressed.connect(_test_battle)
	row2.add_child(test)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	var help := UiTheme.label("Linke Maustaste malen · rechte/mittlere Taste verschieben · Mausrad zoomen · Q/E drehen (3D) · Strg+Z rückgängig · V Ansicht · B/R/I Werkzeug · Bild↑/↓ Höhe", 11, UiTheme.MUTED)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(help)
	var back := UiTheme.button("Zurück zum Startmenü")
	back.pressed.connect(func() -> void: _ask_discard(func() -> void: get_tree().change_scene_to_file(HubState.START_SCENE)))
	v.add_child(back)


func _build_top() -> void:
	var p := PanelContainer.new()
	p.anchor_right = 1.0
	p.offset_left = LEFT_W
	p.offset_right = -RIGHT_W
	p.offset_bottom = TOP_H
	root.add_child(p)
	var h := HBoxContainer.new()
	p.add_child(h)
	for i in 2:
		var b := UiTheme.button(["Draufsicht", "3D"][i], "", true)
		b.pressed.connect(func() -> void: set_view(i == 1))
		h.add_child(b)
		_view_btns.append(b)
	h.add_child(VSeparator.new())
	for spec in [[&"pinsel", "Pinsel", "Felder einzeln malen (ziehen malt weiter)"], [&"rechteck", "Rechteck", "Rechteck aufziehen und füllen"],
			[&"pipette", "Pipette", "Gelände und Höhe eines Felds übernehmen"]]:
		var b := UiTheme.button(spec[1], spec[2], true)
		b.pressed.connect(func() -> void: set_tool(spec[0]))
		h.add_child(b)
		_tool_btns[spec[0]] = b
	h.add_child(VSeparator.new())
	var minus := UiTheme.button(" − ", "Höhe des Bausteins senken")
	minus.pressed.connect(func() -> void: set_height(brush_h - 1))
	h.add_child(minus)
	_height_l = UiTheme.label("", 14)
	_height_l.custom_minimum_size.x = 96
	_height_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_child(_height_l)
	var plus := UiTheme.button(" + ", "Höhe des Bausteins erhöhen (1 Stufe = 1,5 m)")
	plus.pressed.connect(func() -> void: set_height(brush_h + 1))
	h.add_child(plus)
	h.add_child(VSeparator.new())
	var undo_b := UiTheme.button("Rückgängig", "Letzten Strich zurücknehmen (Strg+Z)")
	undo_b.pressed.connect(undo)
	h.add_child(undo_b)


func _build_right() -> void:
	_right = _panel(false)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_right.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 3)
	sc.add_child(v)
	for group in PALETTE:
		v.add_child(UiTheme.label(String(group[0]).to_upper(), 11, UiTheme.MUTED))
		for t in group[1]:
			var info: Dictionary = BattleMap.TERRAIN[t]
			var obj: float = info.get("obj", 0.0)
			var sub := ""
			if obj > 0.0 and not t in BattleMap.WALLS:
				sub = " (%s m)" % Combat._m(obj * BattleMap.LEVEL_M)
			_brush_button(v, t, "%s%s" % [info.name if t != &"boden" else "Boden", sub])
	v.add_child(UiTheme.label("STARTFELDER", 11, UiTheme.MUTED))
	_brush_button(v, CREW_MARK, "Crew-Start (blau)")
	_brush_button(v, ENEMY_MARK, "Gegner-Start (rot)")
	_brush_button(v, CLEAR_MARK, "Startfeld löschen")
	var note := UiTheme.label("Ohne gezeichnete Startfelder (mind. %d Crew, %d Gegner) setzt das Spiel sie je Lage selbst." % [Campaign.HARD_SQUAD, Mission.MAX_ENEMIES], 11, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)


func _brush_button(parent: Control, t: StringName, text: String) -> void:
	var b := UiTheme.button(text, "", true)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 13)
	b.custom_minimum_size.y = 28
	if BattleMap.TERRAIN.has(t):
		var sw := ColorRect.new()
		sw.custom_minimum_size = Vector2(12, 12)
		sw.color = _swatch(t)
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(sw)
		sw.position = Vector2(RIGHT_W - 44, 8)
	b.pressed.connect(func() -> void: set_brush(t))
	parent.add_child(b)
	_brush_btns[t] = b


func _swatch(t: StringName) -> Color:
	var obj: float = BattleMap.TERRAIN[t].get("obj", 0.0)
	if COLORS.has(t):
		return COLORS[t]
	if obj > 0.0:
		return FULL_COLOR if obj >= BattleMap.FULL else HALF_COLOR
	return Color(0.37, 0.38, 0.41)


func _refresh_ui() -> void:
	UiTheme.clear(_list)
	var maps := CustomMaps.list()
	if maps.is_empty() and d.is_empty():
		_list.add_child(UiTheme.label("noch keine gespeichert", 13, UiTheme.MUTED))
	var shown := false
	for m in maps:
		_list.add_child(_map_item(m, m.id == d.get("id", "")))
		shown = shown or m.id == d.get("id", "")
	if not shown and not d.is_empty():
		_list.add_child(_map_item(d, true))
	if d.is_empty():
		return
	_name.text = String(d.name)
	for i in _type.item_count:
		if _type.get_item_metadata(i) == String(d.type):
			_type.select(i)
	var sz := CustomMaps.size_dict(String(d.size_id), bool(d.square))
	_size_l.text = "Größe: %s%s, %d×%d Felder (ca. %d×%d m)" % [sz.name, ", quadratisch" if d.square else "", d.cols, d.rows,
		roundi(d.cols * Hex.SIZE_M), roundi(d.rows * Hex.ROW_M)]
	_active.set_pressed_no_signal(bool(d.get("active", false)))
	_refresh_tools()
	_refresh_info()


func _map_item(m: Dictionary, current: bool) -> Button:
	var b := UiTheme.button("%s%s%s\n%s" % ["✓ " if m.get("active", false) else "", m.name if String(m.name) != "" else "(ohne Namen)",
		"  (neu)" if String(m.get("id", "")) == "" else "",
		"%s · %s%s" % [MapTypes.type_name(StringName(m.type)), m.size_id, ", quadr." if m.square else ""]], "", true)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.clip_text = true
	b.custom_minimum_size.x = 0
	b.button_pressed = current
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(func() -> void:
		if current:
			b.set_pressed_no_signal(true)
			return
		_ask_discard(func() -> void: _select(CustomMaps.load_map(String(m.id)))))
	return b


func _refresh_tools() -> void:
	for k in _tool_btns:
		_tool_btns[k].set_pressed_no_signal(k == tool)
	for k in _brush_btns:
		_brush_btns[k].set_pressed_no_signal(k == brush)
	_view_btns[0].set_pressed_no_signal(not view_3d)
	_view_btns[1].set_pressed_no_signal(view_3d)
	_height_l.text = "Höhe %d (%s m)" % [brush_h, Combat._m(brush_h * BattleMap.LEVEL_M)]


## Kurzinfo (Startfelder, ungespeichert) und Prüfergebnis
func _refresh_info() -> void:
	var s := "Startfelder gezeichnet: Crew %d/%d, Gegner %d/%d" % [crew.size(), Campaign.HARD_SQUAD, enemy.size(), Mission.MAX_ENEMIES]
	if dirty:
		s += "\nungespeicherte Änderungen"
	_info_l.text = s
	if check_res.is_empty():
		_check_l.text = "[color=#8291ad]Noch nicht geprüft („Prüfen“ oder Speichern).[/color]"
		return
	var t := ("[color=#6fdc6f]Im Spiel nutzbar.[/color]" if check_res.ok else "[color=#ff6b6b]So nicht im Spiel nutzbar.[/color]") + "\n"
	for lage in Mission.LAGEN:
		var how: String = check_res.lagen.get(lage, "")
		t += "%s: %s\n" % [Mission.LAGEN[lage][0], how if how != "" else "[color=#ff6b6b]nicht möglich[/color]"]
	for e in check_res.errors:
		t += "[color=#ff8a3d]• %s[/color]\n" % e
	_check_l.text = t


# ---------------------------------------------------------------- Karte wählen, speichern, neu

func _select(m: Dictionary, unsaved := false) -> void:
	d = m.duplicate(true)
	crew.clear()
	enemy.clear()
	for p in d.get("crew", []):
		crew[Vector2i(int(p[0]), int(p[1]))] = true
	for p in d.get("enemy", []):
		enemy[Vector2i(int(p[0]), int(p[1]))] = true
	_pos_cell.clear()
	for r in d.rows:
		for c in d.cols:
			_pos_cell[Hex.from_offset(c, r)] = Vector2i(c, r)
	_undo.clear()
	_hover = null
	_rect_from = null
	check_res = {}
	dirty = unsaved
	_view_stale = true
	_refresh_ui()
	canvas.fit()
	if view_3d:
		_rebuild_3d(true)


## Karte im Speicherformat (Startfelder aus den Markierungen)
func _data() -> Dictionary:
	d.crew = crew.keys().map(func(k: Vector2i) -> Array: return [k.x, k.y])
	d.enemy = enemy.keys().map(func(k: Vector2i) -> Array: return [k.x, k.y])
	return d


func run_check() -> void:
	if d.is_empty():
		return
	check_res = CustomMaps.check(_data())
	_refresh_info()
	canvas.queue_redraw()
	if view_3d:
		_rebuild_marks()


## Speichern (mit Prüfung); nicht nutzbare Karten werden gespeichert, aber nicht aktiv
func save() -> bool:
	if d.is_empty():
		return false
	if String(d.name).strip_edges() == "":
		d.name = "Karte ohne Namen"
	run_check()
	if not check_res.ok:
		d.active = false
	var id := CustomMaps.save(_data())
	if id == "":
		return false
	dirty = false
	_refresh_ui()
	return true


func _set_dirty(rebuild := false) -> void:
	dirty = true
	if rebuild:
		_view_stale = true
		if view_3d:
			_rebuild_3d()
		canvas.queue_redraw()
	_refresh_info()


## Bei ungespeicherten Änderungen erst fragen, dann then ausführen
func _ask_discard(then: Callable) -> void:
	if not dirty:
		then.call()
		return
	_confirm.open("Ungespeicherte Änderungen")
	var l := UiTheme.label("Die Änderungen an „%s“ sind nicht gespeichert." % d.get("name", ""), 15)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm.content.add_child(l)
	var sv := UiTheme.button("Speichern")
	sv.pressed.connect(func() -> void:
		_confirm.close()
		if save():
			then.call())
	_confirm.footer.add_child(sv)
	var dis := UiTheme.button("Verwerfen")
	dis.pressed.connect(func() -> void:
		_confirm.close()
		dirty = false
		then.call())
	_confirm.footer.add_child(dis)
	_confirm.add_close("Abbrechen")


func _ask_delete() -> void:
	if d.is_empty():
		return
	_confirm.open("Karte löschen")
	_confirm.content.add_child(UiTheme.label("„%s“ endgültig löschen?" % d.name, 15))
	var yes := UiTheme.button("Löschen")
	yes.add_theme_color_override("font_color", UiTheme.BAD)
	yes.pressed.connect(func() -> void:
		_confirm.close()
		CustomMaps.delete(String(d.get("id", "")))
		dirty = false
		var maps := CustomMaps.list()
		if maps.is_empty():
			_select(CustomMaps.blank("Neue Karte", &"halle", "mittel"), true)
		else:
			_select(maps[0]))
	_confirm.footer.add_child(yes)
	_confirm.add_close("Abbrechen")


## Neue Karte: leer, Zufallskarte als Vorlage oder Kopie der gewählten
func _show_new() -> void:
	_new_dlg.open("Neue Karte")
	var c := _new_dlg.content
	var nm := LineEdit.new()
	nm.text = "Neue Karte %d" % (CustomMaps.list().size() + 1)
	c.add_child(UiTheme.label("Name", 12, UiTheme.MUTED))
	c.add_child(nm)
	c.add_child(UiTheme.label("Start", 12, UiTheme.MUTED))
	var start := OptionButton.new()
	start.add_item("Leere Karte (Boden mit Außenwand)")
	start.add_item("Zufallskarte als Vorlage")
	if not d.is_empty():
		start.add_item("Kopie von „%s“" % d.name)
	start.select(1)
	c.add_child(start)
	c.add_child(UiTheme.label("Kartentyp", 12, UiTheme.MUTED))
	var ty := OptionButton.new()
	for id in MapTypes.TYPES:
		ty.add_item(MapTypes.type_name(id))
		ty.set_item_metadata(ty.item_count - 1, String(id))
	c.add_child(ty)
	c.add_child(UiTheme.label("Größe", 12, UiTheme.MUTED))
	var sz := OptionButton.new()
	for s in BattleMap.SIZES:
		for sq in [false, true]:
			var n: int = s.sq if sq else s.cols
			sz.add_item("%s%s (%d×%d Felder)" % [s.name, ", quadratisch" if sq else "", n, s.sq if sq else s.rows])
			sz.set_item_metadata(sz.item_count - 1, [s.id, sq])
	sz.select(2)
	c.add_child(sz)
	var sync := func(i: int) -> void:
		ty.disabled = i == 2
		sz.disabled = i == 2
	start.item_selected.connect(sync)
	var ok := UiTheme.button("Anlegen")
	ok.add_theme_color_override("font_color", UiTheme.ACCENT)
	ok.pressed.connect(func() -> void:
		var name := nm.text.strip_edges() if nm.text.strip_edges() != "" else "Neue Karte"
		var t := StringName(ty.get_item_metadata(ty.selected))
		var s: Array = sz.get_item_metadata(sz.selected)
		var nd: Dictionary
		match start.selected:
			0:
				nd = CustomMaps.blank(name, t, s[0], s[1])
			1:
				nd = CustomMaps.from_generator(name, t, s[0], s[1], randi() % 1000000)
			_:
				nd = CustomMaps.copy(_data(), name)
		_new_dlg.close()
		_select(nd, true))
	_new_dlg.footer.add_child(ok)
	_new_dlg.add_close("Abbrechen")


## Neue Karte ohne Dialog (Selbsttest): start 0 leer, 1 Zufallskarte, 2 Kopie
func new_map(name: String, start: int, type: StringName = &"halle", size_id := "mittel", square := false) -> void:
	match start:
		0:
			_select(CustomMaps.blank(name, type, size_id, square), true)
		1:
			_select(CustomMaps.from_generator(name, type, size_id, square, 4711), true)
		_:
			_select(CustomMaps.copy(_data(), name), true)


func _test_battle() -> void:
	if not save():
		return
	if not check_res.ok:
		return
	CustomMaps.test_map = String(d.id)
	CustomMaps.editor_return = String(d.id)
	HubState.game = null
	HubState.quick_battle = true
	Campaign.new_game(GlobalRoster.entries())
	get_tree().change_scene_to_file(HubState.BATTLE_SCENE)


# ---------------------------------------------------------------- Werkzeuge und Malen

func set_view(three_d: bool) -> void:
	view_3d = three_d
	canvas.visible = not three_d
	_hover_mi.visible = false
	if three_d and (_view_stale or _view_map == null):
		_rebuild_3d(true)
	elif three_d:
		_rebuild_marks()
	_refresh_tools()


func set_tool(t: StringName) -> void:
	tool = t
	_rect_from = null
	_refresh_tools()
	canvas.queue_redraw()


func set_brush(t: StringName) -> void:
	brush = t
	if BattleMap.TERRAIN.has(t):
		brush_h = CustomMaps.DEFAULT_H.get(t, 0)
		if t == &"galerie" and String(d.get("type", "")) == "halle":
			brush_h = 3
	if tool == &"pipette":
		tool = &"pinsel"
	_refresh_tools()


func set_height(h: int) -> void:
	brush_h = clampi(h, 0, CustomMaps.MAX_H)
	_refresh_tools()


func undo() -> void:
	if _undo.is_empty():
		return
	var s: Array = _undo.pop_back()
	d.cells = s[0]
	crew = s[1]
	enemy = s[2]
	check_res = {}
	_set_dirty(true)


func _push_undo() -> void:
	_undo.append([d.cells.duplicate(), crew.duplicate(), enemy.duplicate()])
	if _undo.size() > 40:
		_undo.pop_front()


## Ein Feld mit dem Baustein bemalen (Gelände mit Höhe oder Startfeld)
func paint(cell: Vector2i) -> void:
	if d.is_empty() or cell.x < 0 or cell.y < 0 or cell.x >= d.cols or cell.y >= d.rows:
		return
	var i: int = cell.y * d.cols + cell.x
	match brush:
		CREW_MARK, ENEMY_MARK:
			var t: StringName = CustomMaps.cell(d, cell.x, cell.y)[0]
			if not BattleMap.TERRAIN[t].walk:
				return
			(crew if brush == CREW_MARK else enemy)[cell] = true
			(enemy if brush == CREW_MARK else crew).erase(cell)
		CLEAR_MARK:
			crew.erase(cell)
			enemy.erase(cell)
		_:
			d.cells[i] = "%s:%d" % [brush, brush_h]
			if not BattleMap.TERRAIN[brush].walk:
				crew.erase(cell)
				enemy.erase(cell)


func _pick_cell(cell: Vector2i) -> void:
	var x := CustomMaps.cell(d, cell.x, cell.y)
	brush = x[0]
	brush_h = x[1]
	tool = &"pinsel"
	_refresh_tools()


## Felder des aufgezogenen Rechtecks (Spalten/Reihen von _rect_from bis zum Mauszeiger)
func _rect_cells() -> Array:
	var out := []
	if _rect_from == null or _hover == null:
		return out
	for r in range(mini(_rect_from.y, _hover.y), maxi(_rect_from.y, _hover.y) + 1):
		for c in range(mini(_rect_from.x, _hover.x), maxi(_rect_from.x, _hover.x) + 1):
			out.append(Vector2i(c, r))
	return out


## Linke Taste gedrückt / gezogen / losgelassen auf cell (beide Ansichten)
func _press(cell: Variant) -> void:
	if cell == null or d.is_empty():
		return
	match tool:
		&"pipette":
			_pick_cell(cell)
		&"rechteck":
			_rect_from = cell
			_stroke_mark(cell)
		_:
			_push_undo()
			_stroke = true
			paint(cell)
			_stroke_mark(cell)
			check_res = {}
			_set_dirty(false)
			canvas.queue_redraw()


func _drag(cell: Variant) -> void:
	if cell == _hover:
		return
	_hover = cell
	if _stroke and cell != null:
		paint(cell)
		_stroke_mark(cell)
	canvas.queue_redraw()


## 3D: bemalte Felder bis zum Loslassen markieren (die Ansicht wird erst danach neu gebaut)
func _stroke_mark(cell: Vector2i) -> void:
	if not view_3d or _view_map == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = _hover_mi.mesh
	mi.material_override = _unshaded(Color(UiTheme.ACCENT, 0.6))
	mi.rotation.y = PI / 6.0
	mi.position = map_view.tile_top(Hex.from_offset(cell.x, cell.y)) + Vector3(0, 0.07, 0)
	_marks.add_child(mi)


func _release() -> void:
	if tool == &"rechteck" and _rect_from != null:
		var cells := _rect_cells()
		if not cells.is_empty():
			_push_undo()
			for c in cells:
				paint(c)
			check_res = {}
		_rect_from = null
		_set_dirty(true)
	elif _stroke:
		_stroke = false
		_set_dirty(true)
	canvas.queue_redraw()


func _canvas_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if mb.pressed:
				var f := 1.15 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1 / 1.15
				var nz := clampf(canvas.zoom * f, 4.0, 80.0)
				canvas.origin = mb.position - (mb.position - canvas.origin) * (nz / canvas.zoom)
				canvas.zoom = nz
				canvas.queue_redraw()
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_hover = canvas.cell_at(mb.position)
				_press(_hover)
			else:
				_release()
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if _panning:
			canvas.origin += mm.relative
			canvas.queue_redraw()
		_drag(canvas.cell_at(mm.position))


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		var k := e as InputEventKey
		if k.keycode == KEY_Z and k.ctrl_pressed:
			undo()
		elif k.keycode == KEY_V:
			set_view(not view_3d)
		elif k.keycode == KEY_B:
			set_tool(&"pinsel")
		elif k.keycode == KEY_R:
			set_tool(&"rechteck")
		elif k.keycode == KEY_I:
			set_tool(&"pipette")
		elif k.keycode == KEY_PAGEUP:
			set_height(brush_h + 1)
		elif k.keycode == KEY_PAGEDOWN:
			set_height(brush_h - 1)
		elif view_3d and k.keycode == KEY_Q:
			rig.rotate_by(-90)
		elif view_3d and k.keycode == KEY_E:
			rig.rotate_by(90)
		return
	if not view_3d or _view_map == null:
		return
	var vp := get_viewport().get_visible_rect().size
	if e is InputEventMouse and ((e as InputEventMouse).position.x < LEFT_W or (e as InputEventMouse).position.x > vp.x - RIGHT_W
			or (e as InputEventMouse).position.y < TOP_H):
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			rig.zoom_at(mb.position, 1.12)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			rig.zoom_at(mb.position, 1 / 1.12)
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_hover = _pick_3d(mb.position)
				_press(_hover)
			else:
				_release()
	elif e is InputEventMouseMotion:
		var mm := e as InputEventMouseMotion
		if _panning:
			rig.pan(mm.relative)
		var cell: Variant = _pick_3d(mm.position)
		_drag(cell)
		_hover_mi.visible = cell != null
		if cell != null:
			_hover_mi.position = map_view.tile_top(Hex.from_offset(cell.x, cell.y)) + Vector3(0, 0.05, 0)
