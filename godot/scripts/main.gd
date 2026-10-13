extends Node3D
## Godot-Prototyp: Lagerhalle in 3D, Vela (Crew) gegen einen Plünderer.
## Regeln wie in der HTML-Version (W100 aus 2W10, Angriffstabelle, Reichweite, Deckung, Höhe),
## aber vereinfachter Zug: bis 6 Hex bewegen und einmal angreifen.

const Dice := preload("res://scripts/dice.gd")
const Rules := preload("res://scripts/rules.gd")
const Hex := preload("res://scripts/hexgrid.gd")
const UnitScript := preload("res://scripts/unit.gd")
const DicePanel := preload("res://scripts/dice_panel.gd")

const COLS := 22
const ROWS := 16
const LEVEL := 1.5       # m pro Höhenstufe
const MOVE_HEX := 6
const EYE := 1.5         # Augenhöhe
const TORSO := 0.8       # Rumpfmitte
const HALF_COVER := 40

var tiles := {}          # Vector2i -> {"h": int, "walk": bool}
var crew: Node3D
var enemy: Node3D
var state := "player"    # player, busy, over
var moved := false
var attacked := false
var round_no := 1
var reach := {}          # Vector2i -> Weg (Array)
var hover_tile := Vector2i(-1, -1)
var hover_unit: Node3D = null
var show_grid := true
var autotest := false

var pivot: Node3D
var arm: Node3D
var cam: Camera3D
var yaw := 30.0
var mark_root: Node3D
var hover_mark: MeshInstance3D
var grid_mesh: MeshInstance3D
var disc_mesh: CylinderMesh
var reach_mat: StandardMaterial3D
var path_mat: StandardMaterial3D

var info_label: Label
var hint_label: Label
var log_box: RichTextLabel
var end_button: Button
var dice_panel: PanelContainer


func _ready() -> void:
	autotest = "--autotest" in OS.get_cmdline_user_args()
	if autotest:
		Dice.rng.seed = 7
	else:
		Dice.rng.randomize()
	_build_environment()
	_build_map()
	_build_grid()
	_build_units()
	_build_camera()
	_build_ui()
	_log("[b]Lagerhalle[/b] – Vela (Crew) gegen einen Plünderer auf der Galerie.")
	_start_player_turn()
	if autotest:
		_run_autotest()


# ---------------------------------------------------------------- Aufbau

func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.045, 0.07)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.6, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, -35, 0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	sun.shadow_bias = 0.08
	sun.shadow_normal_bias = 1.5
	add_child(sun)
	# Hallenlampen
	for i in 3:
		var p := Vector3(6.0 + i * 11.0, 7.5, 11.0)
		var lamp := OmniLight3D.new()
		lamp.position = p
		lamp.omni_range = 15.0
		lamp.light_energy = 1.3
		lamp.light_color = Color(1.0, 0.93, 0.8)
		add_child(lamp)
		var housing := _add_box(p + Vector3(0, 0.3, 0), Vector3(2.2, 0.15, 0.6), Color(1, 0.95, 0.85), false, false)
		housing.material_override = _glow_mat(Color(1, 0.95, 0.85), 2.0)


func _build_map() -> void:
	for r in ROWS:
		for c in COLS:
			tiles[Vector2i(c, r)] = {"h": 0, "walk": true}
	# Galerie hinten (Reihe 0–2) auf Höhe 3 m, Treppe in Spalte 3–4 (Reihe 3 auf 1,5 m)
	for r in 3:
		for c in COLS:
			tiles[Vector2i(c, r)].h = 2
	tiles[Vector2i(3, 3)].h = 1
	tiles[Vector2i(4, 3)].h = 1

	var x1 := COLS * Hex.W
	var edge_z := 2 * Hex.ROW_H + 0.65
	# Boden
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(x1 + 4.0, ROWS * Hex.ROW_H + 4.0)
	floor_mi.mesh = pm
	floor_mi.position = Vector3(x1 / 2.0 - 0.4, 0, ROWS * Hex.ROW_H / 2.0 - 0.3)
	var fm := StandardMaterial3D.new()
	var nt := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	nt.noise = noise
	nt.seamless = true
	var grad := Gradient.new()
	grad.set_color(0, Color(0.86, 0.86, 0.88))
	grad.set_color(1, Color(1, 1, 1))
	nt.color_ramp = grad
	fm.albedo_texture = nt
	fm.albedo_color = Color(0.36, 0.37, 0.4)
	fm.roughness = 0.95
	fm.uv1_scale = Vector3(4, 3, 1)
	floor_mi.material_override = fm
	add_child(floor_mi)
	var fb := StaticBody3D.new()
	var fcs := CollisionShape3D.new()
	var fsh := BoxShape3D.new()
	fsh.size = Vector3(pm.size.x, 0.2, pm.size.y)
	fcs.shape = fsh
	fcs.position.y = -0.1
	fb.add_child(fcs)
	floor_mi.add_child(fb)
	# Bodenmarkierung: gelbe Fahrspur
	for z in [6.2, 17.2]:
		_add_box(Vector3(x1 / 2.0, 0.005, z), Vector3(x1 - 2.0, 0.01, 0.12), Color(0.85, 0.68, 0.15), false, false)

	# Galerie mit Geländer
	var gal := _add_box(Vector3((x1 - 0.75) / 2.0, 1.5, (edge_z - 0.75) / 2.0), Vector3(x1 + 0.75, 3.0, edge_z + 0.75), Color(0.36, 0.4, 0.46), false)
	gal.material_override = _mat(Color(0.36, 0.4, 0.46), 0.7, 0.3)
	_add_box(Vector3((x1 - 0.75) / 2.0, 2.95, edge_z - 0.02), Vector3(x1 + 0.75, 0.12, 0.08), Color(0.85, 0.68, 0.15), false, false)
	for c in COLS:
		_add_box(Vector3(c * Hex.W + 0.75, 1.4, edge_z - 0.05), Vector3(0.18, 2.8, 0.18), Color(0.25, 0.28, 0.33), false, false)
	var gap_x0 := 4.2
	var gap_x1 := 7.8
	# Brüstung (0,9 m, halbe Deckung) mit gelbem Handlauf, Lücke an der Treppe
	for seg in [[-0.75, gap_x0], [gap_x1, x1]]:
		var cx: float = (seg[0] + seg[1]) / 2.0
		var lx: float = seg[1] - seg[0]
		_add_box(Vector3(cx, 3.42, edge_z - 0.1), Vector3(lx, 0.84, 0.06), Color(0.3, 0.33, 0.38), false)
		_add_box(Vector3(cx, 3.88, edge_z - 0.1), Vector3(lx, 0.06, 0.1), Color(0.85, 0.68, 0.15), false, false)
	# Treppe: Podest auf 1,5 m und eine Stufe davor
	var st_z := 3 * Hex.ROW_H
	_add_box(Vector3(6.0, 0.75, st_z), Vector3(3.0, 1.5, 1.3), Color(0.42, 0.45, 0.5), false)
	_add_box(Vector3(6.0, 0.375, st_z + 0.9), Vector3(3.0, 0.75, 0.5), Color(0.42, 0.45, 0.5), false)
	_add_box(Vector3(6.0, 2.25, st_z - 0.55), Vector3(3.0, 1.5, 0.2), Color(0.42, 0.45, 0.5), false)

	# Hallenwände
	var wall_c := Color(0.2, 0.23, 0.28)
	_add_box(Vector3(x1 / 2.0, 4.0, -1.5), Vector3(x1 + 4.0, 8.0, 0.4), wall_c, false)
	_add_box(Vector3(-1.7, 4.0, ROWS * Hex.ROW_H / 2.0 - 0.5), Vector3(0.4, 8.0, ROWS * Hex.ROW_H + 2.4), wall_c, false)
	_add_box(Vector3(x1 + 1.0, 4.0, ROWS * Hex.ROW_H / 2.0 - 0.5), Vector3(0.4, 8.0, ROWS * Hex.ROW_H + 2.4), wall_c, false)

	# Container (volle Deckung, 2,6 m hoch)
	_add_container(Vector3(9.0, 1.3, 10.4), Vector3(2.4, 2.6, 6.0), Color(0.24, 0.43, 0.62))
	_add_container(Vector3(19.5, 1.3, 7.8), Vector3(6.0, 2.6, 2.4), Color(0.66, 0.27, 0.22))
	_add_container(Vector3(19.5, 3.9, 7.8), Vector3(6.0, 2.6, 2.4), Color(0.28, 0.52, 0.34))
	_add_container(Vector3(27.0, 1.3, 14.4), Vector3(2.4, 2.6, 6.0), Color(0.78, 0.56, 0.2))
	# Kisten (halbe Deckung, 1 m hoch)
	for p in [Vector3(4.5, 0.5, 9.1), Vector3(13.5, 0.5, 13.0), Vector3(14.7, 0.5, 13.0), Vector3(22.5, 0.5, 11.7),
			Vector3(29.25, 0.5, 6.5), Vector3(6.0, 0.5, 15.6), Vector3(21.0, 0.5, 16.9), Vector3(16.5, 0.5, 18.2)]:
		_add_crate(p)


func _add_container(center: Vector3, size: Vector3, c: Color) -> void:
	var mi := _add_box(center, size, c, true)
	mi.material_override = _mat(c, 0.55, 0.35)
	# Rippen an den Längsseiten
	var long_x := size.x > size.z
	var length := size.x if long_x else size.z
	var n := int(length / 0.45)
	for i in n:
		var off := -length / 2.0 + 0.3 + i * (length - 0.6) / maxf(1.0, n - 1.0)
		for side in [-1.0, 1.0]:
			var p := center
			var s := Vector3(0.06, size.y - 0.25, 0.06)
			if long_x:
				p += Vector3(off, 0, side * (size.z / 2.0 + 0.02))
			else:
				p += Vector3(side * (size.x / 2.0 + 0.02), 0, off)
			_add_box(p, s, c.darkened(0.25), false, false)
	# Eckpfosten
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_add_box(center + Vector3(sx * (size.x / 2.0 - 0.06), 0, sz * (size.z / 2.0 - 0.06)), Vector3(0.14, size.y + 0.02, 0.14), c.darkened(0.35), false, false)


func _add_crate(p: Vector3) -> void:
	var c := Color(0.62, 0.45, 0.25)
	_add_box(p, Vector3(1.2, 1.0, 1.2), c, true)
	_add_box(p, Vector3(1.24, 0.12, 1.24), c.darkened(0.3), false, false)
	_add_box(p + Vector3(0, 0.44, 0), Vector3(1.24, 0.08, 1.24), c.darkened(0.3), false, false)


## Quader mit optionaler Kollision (für Sichtlinien und Mausklicks).
## blocks: Felder, deren Mitte darunter liegt und tiefer als die Oberkante sind, werden unbetretbar.
func _add_box(center: Vector3, size: Vector3, c: Color, blocks: bool, collide := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(c)
	mi.position = center
	add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		mi.add_child(body)
	if blocks:
		var top := center.y + size.y / 2.0
		for t in tiles:
			var p := Hex.to_world(t)
			if absf(p.x - center.x) < size.x / 2.0 + 0.15 and absf(p.y - center.z) < size.z / 2.0 + 0.15 and tiles[t].h * LEVEL < top - 0.01:
				tiles[t].walk = false
	return mi


func _build_grid() -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var cs := Hex.corners(Hex.R * 0.97)
	for t in tiles:
		if not tiles[t].walk:
			continue
		var c := tile_pos(t) + Vector3(0, 0.02, 0)
		for i in 6:
			var a: Vector2 = cs[i]
			var b: Vector2 = cs[(i + 1) % 6]
			im.surface_add_vertex(c + Vector3(a.x, 0, a.y))
			im.surface_add_vertex(c + Vector3(b.x, 0, b.y))
	im.surface_end()
	grid_mesh = MeshInstance3D.new()
	grid_mesh.mesh = im
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.12)
	grid_mesh.material_override = m
	add_child(grid_mesh)
	mark_root = Node3D.new()
	add_child(mark_root)
	disc_mesh = CylinderMesh.new()
	disc_mesh.top_radius = Hex.R * 0.88
	disc_mesh.bottom_radius = Hex.R * 0.88
	disc_mesh.height = 0.03
	disc_mesh.radial_segments = 6
	disc_mesh.rings = 1
	reach_mat = _flat_mat(Color(0.25, 0.55, 1.0, 0.28))
	path_mat = _flat_mat(Color(0.4, 0.75, 1.0, 0.6))
	hover_mark = MeshInstance3D.new()
	hover_mark.mesh = disc_mesh
	hover_mark.material_override = _flat_mat(Color(1, 1, 1, 0.35))
	hover_mark.visible = false
	add_child(hover_mark)


func _build_units() -> void:
	crew = UnitScript.new()
	add_child(crew)
	crew.build("Vela Marrow", "crew", Color(0.95, 0.75, 0.25))
	crew.hp = 33
	crew.max_hp = 33
	crew.ob = 65
	crew.db = 20
	crew.armor = 1
	crew.weapon = "sturmgewehr"
	_place(crew, Vector2i(1, 14))
	enemy = UnitScript.new()
	add_child(enemy)
	enemy.build("Plünderer", "enemy", Color(0.85, 0.25, 0.22))
	enemy.hp = 30
	enemy.max_hp = 30
	enemy.ob = 50
	enemy.db = 10
	enemy.armor = 2
	enemy.weapon = "sturmgewehr"
	_place(enemy, Vector2i(16, 1))
	crew.face(enemy.position)
	enemy.face(crew.position)
	crew.update_label()
	enemy.update_label()


func _place(u: Node3D, t: Vector2i) -> void:
	u.tile = t
	u.h = tiles[t].h
	u.position = tile_pos(t)


func _build_camera() -> void:
	pivot = Node3D.new()
	pivot.position = Vector3(COLS * Hex.W / 2.0, 0, ROWS * Hex.ROW_H / 2.0)
	add_child(pivot)
	arm = Node3D.new()
	arm.rotation_degrees.x = -42.0
	pivot.add_child(arm)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 22.0
	cam.near = 0.1
	cam.far = 200.0
	cam.position = Vector3(0, 0, 45)
	arm.add_child(cam)
	pivot.rotation_degrees.y = yaw
	cam.current = true


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.88)
	sb.border_color = Color(0.17, 0.21, 0.31)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(10)

	var info_panel := PanelContainer.new()
	info_panel.add_theme_stylebox_override("panel", sb)
	info_panel.position = Vector2(12, 12)
	info_panel.custom_minimum_size = Vector2(340, 0)
	layer.add_child(info_panel)
	var vb := VBoxContainer.new()
	info_panel.add_child(vb)
	info_label = Label.new()
	info_label.add_theme_font_size_override("font_size", 15)
	vb.add_child(info_label)
	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size = Vector2(320, 0)
	vb.add_child(hint_label)
	end_button = Button.new()
	end_button.text = "Zug beenden (Enter)"
	end_button.pressed.connect(_end_player_turn)
	vb.add_child(end_button)

	var log_panel := PanelContainer.new()
	log_panel.add_theme_stylebox_override("panel", sb)
	log_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	log_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	log_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	log_panel.offset_right = -12
	log_panel.offset_bottom = -40
	log_panel.custom_minimum_size = Vector2(440, 220)
	layer.add_child(log_panel)
	log_box = RichTextLabel.new()
	log_box.bbcode_enabled = true
	log_box.scroll_following = true
	log_box.add_theme_font_size_override("normal_font_size", 13)
	log_box.add_theme_font_size_override("bold_font_size", 13)
	log_panel.add_child(log_box)

	var help := Label.new()
	help.text = "Linksklick: bewegen / angreifen · rechte Maustaste ziehen: Kamera verschieben · Mausrad: Zoom · Q/E: Kamera drehen · G: Raster · R: neu"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.offset_left = 12
	help.offset_top = -28
	help.offset_bottom = -8
	layer.add_child(help)

	dice_panel = DicePanel.new()
	dice_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	dice_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dice_panel.offset_top = 12
	layer.add_child(dice_panel)


# ---------------------------------------------------------------- Hilfsfunktionen

func tile_pos(t: Vector2i) -> Vector3:
	var p := Hex.to_world(t)
	return Vector3(p.x, tiles[t].h * LEVEL, p.y)


func _mat(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _flat_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	return m


func _glow_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := _mat(c)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _passable(a: Vector2i, b: Vector2i) -> bool:
	return tiles.has(b) and tiles[b].walk and absi(tiles[a].h - tiles[b].h) <= 1


func _unit_at(t: Vector2i) -> Node3D:
	for u in [crew, enemy]:
		if not u.dead and u.tile == t:
			return u
	return null


## Alle Felder, die in MOVE_HEX Schritten erreichbar sind, mit Weg
func _reachable(u: Node3D) -> Dictionary:
	var res := {u.tile: [u.tile]}
	var frontier: Array = [u.tile]
	for step in MOVE_HEX:
		var nxt: Array = []
		for t in frontier:
			for n in Hex.neighbors(t):
				if res.has(n) or not _passable(t, n) or _unit_at(n) != null:
					continue
				var path: Array = res[t].duplicate()
				path.append(n)
				res[n] = path
				nxt.append(n)
		frontier = nxt
	res.erase(u.tile)
	return res


func _ray(a: Vector3, b: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(a, b, 1)
	return get_world_3d().direct_space_state.intersect_ray(q)


## Sichtlinie von einer Augenposition auf eine Figurposition: Kopf sichtbar = Ziel sichtbar,
## Rumpf verdeckt = halbe Deckung.
func _los(eye: Vector3, target_base: Vector3) -> Dictionary:
	if not _ray(eye, target_base + Vector3(0, EYE, 0)).is_empty():
		return {"visible": false, "cover": false}
	var covered := not _ray(eye, target_base + Vector3(0, TORSO, 0)).is_empty()
	return {"visible": true, "cover": covered}


## Trefferberechnung wie in der HTML-Version (ohne Aktivität und Blickrichtung)
func _attack_info(att: Node3D, def: Node3D, from_tile: Vector2i) -> Dictionary:
	var w: Dictionary = Rules.WEAPONS[att.weapon]
	var dist: float = Hex.distance(from_tile, def.tile) * Hex.W
	var rm := Rules.range_mod(w, dist)
	if rm == Rules.OUT_OF_RANGE:
		return {"ok": false, "why": "außer Reichweite (%d m)" % roundi(dist)}
	var l := _los(tile_pos(from_tile) + Vector3(0, EYE, 0), def.position)
	if not l.visible:
		return {"ok": false, "why": "keine Sichtlinie"}
	var mods: Array = [["Angriff (%s)" % w.name, att.ob], ["Verteidigung %s" % def.unit_name, -def.db]]
	if dist <= Rules.POINT_BLANK_M:
		mods.append(["Kernschussweite", 10])
	elif rm != 0:
		mods.append(["Reichweite %d m" % roundi(dist), rm])
	var dh: int = tiles[from_tile].h - def.h
	if dh != 0:
		mods.append(["%d Stufe(n) %s" % [absi(dh), "höher" if dh > 0 else "tiefer"], clampi(dh * 5, -15, 15)])
	if l.cover:
		mods.append(["Halbe Deckung", -HALF_COVER])
	var sum := 0
	for m in mods:
		sum += m[1]
	var thr: int = Rules.ATTACK_TABLES[w.table].hit[def.armor]
	var need := thr - sum
	return {"ok": true, "mods": mods, "sum": sum, "thr": thr, "need": need, "chance": clampi(101 - need, 0, 100), "cover": l.cover}


func _log(text: String) -> void:
	log_box.append_text(text + "\n")
	if autotest:
		print(RegEx.create_from_string("\\[/?[a-z]+[^\\]]*\\]").sub(text, "", true))


func _float_text(u: Node3D, text: String, c: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 56
	l.pixel_size = 0.014
	l.outline_size = 14
	l.modulate = c
	l.position = u.position + Vector3(0, 2.9, 0)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.2, 1.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.2).set_delay(0.5)
	tw.tween_callback(l.queue_free)


func _shot_fx(att: Node3D, target: Vector3) -> void:
	var muzzle: Vector3 = att.position + Vector3(0, 1.2, 0) + (target - att.position).normalized() * 0.8
	muzzle.y = att.position.y + 1.2
	var len := muzzle.distance_to(target)
	var tracer := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.05, len)
	tracer.mesh = bm
	var m := _glow_mat(Color(1, 0.85, 0.45), 4.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tracer.material_override = m
	add_child(tracer)
	tracer.position = (muzzle + target) / 2.0
	tracer.look_at(target, Vector3.UP)
	var flash := OmniLight3D.new()
	flash.light_color = Color(1, 0.8, 0.4)
	flash.light_energy = 4.0
	flash.omni_range = 4.0
	flash.position = muzzle
	add_child(flash)
	var tw := create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.25)
	tw.parallel().tween_property(flash, "light_energy", 0.0, 0.12)
	tw.tween_callback(tracer.queue_free)
	tw.tween_callback(flash.queue_free)


# ---------------------------------------------------------------- Ablauf

func _start_player_turn() -> void:
	state = "player"
	moved = false
	attacked = false
	reach = _reachable(crew)
	_show_reach()
	_update_ui()


func _show_reach() -> void:
	for c in mark_root.get_children():
		c.queue_free()
	if state != "player" or moved:
		return
	for t in reach:
		var mi := MeshInstance3D.new()
		mi.mesh = disc_mesh
		mi.material_override = reach_mat
		mi.position = tile_pos(t) + Vector3(0, 0.02, 0)
		mark_root.add_child(mi)


func _update_ui() -> void:
	var who := "Vela ist am Zug" if state == "player" else ("Plünderer ist am Zug" if state == "busy" else "Kampf vorbei")
	var acts := ""
	if state == "player":
		acts = "\nBewegung (6 Hex): %s · Angriff: %s" % ["erledigt" if moved else "frei", "erledigt" if attacked else "frei"]
	info_label.text = "Runde %d · %s%s\n%s: %d/%d TP · %s: %d/%d TP" % [round_no, who, acts,
		crew.unit_name, maxi(crew.hp, 0), crew.max_hp, enemy.unit_name, maxi(enemy.hp, 0), enemy.max_hp]
	end_button.disabled = state != "player"


func _update_hint() -> void:
	hover_mark.visible = false
	if state != "player":
		hint_label.text = ""
		return
	if hover_unit == enemy and not enemy.dead:
		if attacked:
			hint_label.text = "Diese Runde schon angegriffen."
			return
		var info := _attack_info(crew, enemy, crew.tile)
		if not info.ok:
			hint_label.text = "Angriff nicht möglich: %s" % info.why
			return
		var lines := ["Angriff: ca. %d %% Trefferchance" % info.chance]
		for m in info.mods:
			lines.append("  %s %s%d" % [m[0], "+" if m[1] >= 0 else "", m[1]])
		lines.append("Treffer ab Gesamtwert %d (%s-Rüstung) → W100 ab %d" % [info.thr, Rules.ARMOR_NAMES[enemy.armor], info.need])
		hint_label.text = "\n".join(lines)
		return
	if reach.has(hover_tile) and not moved:
		var path: Array = reach[hover_tile]
		hover_mark.visible = true
		hover_mark.position = tile_pos(hover_tile) + Vector3(0, 0.04, 0)
		var txt := "Bewegen: %d Hex (%.1f m)" % [path.size() - 1, (path.size() - 1) * Hex.W]
		if tiles[hover_tile].h > 0:
			txt += " · Höhe %.1f m" % (tiles[hover_tile].h * LEVEL)
		if not attacked:
			var info := _attack_info(crew, enemy, hover_tile)
			txt += "\nVon dort: " + ("ca. %d %% auf den Plünderer%s" % [info.chance, " (er hat Deckung)" if info.cover else ""] if info.ok else info.why)
		hint_label.text = txt
		return
	hint_label.text = ""


func _player_move(t: Vector2i) -> void:
	if state != "player" or moved or not reach.has(t):
		return
	moved = true
	state = "anim"
	_show_reach()
	await _move_unit(crew, reach[t])
	state = "player"
	_update_ui()
	_update_hint()


func _move_unit(u: Node3D, path: Array) -> void:
	for i in range(1, path.size()):
		var target := tile_pos(path[i])
		u.face(target)
		var tw := create_tween()
		tw.tween_property(u, "position", target, 0.16)
		await tw.finished
	u.tile = path[-1]
	u.h = tiles[u.tile].h


func _player_attack() -> void:
	if state != "player" or attacked or enemy.dead:
		return
	var info := _attack_info(crew, enemy, crew.tile)
	if not info.ok:
		_log("Angriff nicht möglich: %s" % info.why)
		return
	attacked = true
	state = "anim"
	_show_reach()
	await _resolve_attack(crew, enemy, info)
	if state != "over":
		state = "player"
		_show_reach()
	_update_ui()
	_update_hint()


func _resolve_attack(att: Node3D, def: Node3D, info: Dictionary) -> void:
	var w: Dictionary = Rules.WEAPONS[att.weapon]
	att.face(def.position)
	var roll := Dice.open_d100(w.fumble)
	await dice_panel.show_roll(roll, "%s → %s (%s)" % [att.unit_name, def.unit_name, w.name])
	var hit_pos: Vector3 = def.position + Vector3(0, 1.1, 0)
	var total: int = roll.total + info.sum
	var line := "%s → %s: Wurf %s %+d = %d" % [att.unit_name, def.unit_name, _fmt_roll(roll), info.sum, total]
	if roll.fumble:
		_shot_fx(att, hit_pos + Vector3(2.5, -1.0, 1.5))
		_float_text(att, "Patzer", Color(1, 0.45, 0.45))
		_log(line + " – [color=#ff8a8a]Patzer![/color]")
		return
	var res := Rules.lookup_attack(w.table, total, def.armor, w.dmg)
	if not res.hit:
		_shot_fx(att, hit_pos + Vector3(randf_range(-1.5, 1.5), randf_range(0.3, 1.0), randf_range(-1.5, 1.5)))
		_float_text(def, "daneben", Color(0.75, 0.8, 0.9))
		_log(line + " gegen %d – daneben" % res.threshold)
		return
	_shot_fx(att, hit_pos)
	var dmg: int = res.dmg
	var crit := ""
	if res.severity != "":
		# Vereinfachung im Prototyp: Kritische Treffer geben Zusatzschaden statt Tabellenwurf
		var extra: int = (Rules.SEVERITIES.find(res.severity) + 1) * 3
		dmg += extra
		crit = " · Kritischer Treffer %s (+%d)" % [res.severity, extra]
	def.hp -= dmg
	def.update_label()
	_float_text(def, "−%d" % dmg, Color(1, 0.6, 0.45) if crit == "" else Color(1, 0.85, 0.3))
	_log(line + " gegen %d – [color=#ffb38a]Treffer, %d Schaden%s[/color]" % [res.threshold, dmg, crit])
	if def.hp <= 0:
		def.die()
		state = "over"
		_log("[b]%s fällt. %s[/b] (R = neuer Kampf)" % [def.unit_name, "Sieg!" if def == enemy else "Niederlage."])
		_update_ui()


func _fmt_roll(roll: Dictionary) -> String:
	if roll.rolls.size() == 1:
		return str(roll.first)
	var parts := []
	for i in roll.rolls.size():
		var r: int = roll.rolls[i]
		parts.append(str(r) if i == 0 else ("−%d" % -r if r < 0 else "+%d" % r))
	return "(%s=%d)" % ["".join(parts), roll.total]


func _end_player_turn() -> void:
	if state != "player":
		return
	state = "busy"
	_show_reach()
	_update_ui()
	await _enemy_turn()
	if state == "over":
		return
	round_no += 1
	_log("[b]Runde %d[/b]" % round_no)
	_start_player_turn()


## Gegner-KI: bleibt stehen, wenn er gut trifft; sonst sucht er ein Feld mit Schussfeld, möglichst in Deckung
func _enemy_turn() -> void:
	await get_tree().create_timer(0.4).timeout
	var here := _attack_info(enemy, crew, enemy.tile)
	if not here.ok or here.chance < 30:
		var best: Variant = null
		var best_score := -1e9
		var r := _reachable(enemy)
		for t in r:
			var info := _attack_info(enemy, crew, t)
			var score := -Hex.distance(t, crew.tile) * 2.0
			if info.ok:
				score += 100.0 + info.chance
			var back := _los(crew.position + Vector3(0, EYE, 0), tile_pos(t))
			if not back.visible or back.cover:
				score += 25.0
			if score > best_score:
				best_score = score
				best = t
		if here.ok:
			var stay: float = 100.0 + here.chance - Hex.distance(enemy.tile, crew.tile) * 2.0
			if stay >= best_score:
				best = null
		if best != null:
			await _move_unit(enemy, r[best])
	var info := _attack_info(enemy, crew, enemy.tile)
	if info.ok:
		await get_tree().create_timer(0.25).timeout
		await _resolve_attack(enemy, crew, info)
	else:
		_log("Plünderer: kein Schuss möglich (%s)." % info.why)
	enemy.face(crew.position)


# ---------------------------------------------------------------- Eingabe

func _physics_process(_delta: float) -> void:
	var mp := get_viewport().get_mouse_position()
	var from := cam.project_ray_origin(mp)
	var q := PhysicsRayQueryParameters3D.create(from, from + cam.project_ray_normal(mp) * 300.0, 1 | 2)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var hu: Node3D = null
	var ht := Vector2i(-1, -1)
	if not hit.is_empty():
		var col: Object = hit.collider
		if col.has_meta("unit"):
			hu = col.get_meta("unit")
			ht = hu.tile
		elif hit.normal.y > 0.7:
			var t := Hex.from_world(Vector2(hit.position.x, hit.position.z))
			if tiles.has(t) and absf(tiles[t].h * LEVEL - hit.position.y) < 0.4:
				ht = t
	if ht != hover_tile or hu != hover_unit:
		hover_tile = ht
		hover_unit = hu
		_update_hint()


func _process(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		move.z -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		move.z += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		move.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		move.x += 1
	if move != Vector3.ZERO:
		pivot.position += pivot.basis * move.normalized() * delta * cam.size * 0.6


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if hover_unit == enemy:
					_player_attack()
				elif reach.has(hover_tile):
					_player_move(hover_tile)
			MOUSE_BUTTON_WHEEL_UP:
				cam.size = maxf(8.0, cam.size / 1.12)
			MOUSE_BUTTON_WHEEL_DOWN:
				cam.size = minf(60.0, cam.size * 1.12)
	elif event is InputEventMouseMotion and (event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)):
		var scale := cam.size / get_viewport().get_visible_rect().size.y
		var r: Vector2 = event.relative
		pivot.position -= pivot.basis * Vector3(r.x, 0, r.y / sin(deg_to_rad(42.0))) * scale
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_Q:
				_rotate_cam(-90.0)
			KEY_E:
				_rotate_cam(90.0)
			KEY_G:
				show_grid = not show_grid
				grid_mesh.visible = show_grid
			KEY_ENTER, KEY_KP_ENTER:
				_end_player_turn()
			KEY_R:
				get_tree().reload_current_scene()


func _rotate_cam(deg: float) -> void:
	yaw += deg
	var tw := create_tween()
	tw.tween_property(pivot, "rotation_degrees:y", yaw, 0.35).set_trans(Tween.TRANS_SINE)


# ---------------------------------------------------------------- Selbsttest (godot -- --autotest)

func _run_autotest() -> void:
	var out := OS.get_environment("PTF_OUT")
	if out == "":
		out = "user://"
	for i in 30:
		await get_tree().process_frame
	await _screenshot(out + "/01_start.png")
	# Bis zu 5 Runden: Feld mit bester Trefferchance wählen, sonst dem Gegner näher kommen
	for rnd in 5:
		if state == "over":
			break
		var best: Variant = null
		var best_score := -1e9
		for t in reach:
			var info := _attack_info(crew, enemy, t)
			var score: float = -Hex.distance(t, enemy.tile) * 2.0 + (100.0 + info.chance if info.ok else 0.0)
			if score > best_score:
				best_score = score
				best = t
		if best != null:
			hover_tile = best
			_update_hint()
			if rnd == 0:
				await _screenshot(out + "/02_vorschau.png")
			await _player_move(best)
		hover_unit = enemy
		_update_hint()
		print("Hinweis: ", hint_label.text.replace("\n", " | "))
		if _attack_info(crew, enemy, crew.tile).ok:
			_player_attack()
			await get_tree().create_timer(0.3).timeout
			await _screenshot(out + "/03_wuerfel_%d.png" % rnd)
			while state == "anim":
				await get_tree().process_frame
			await get_tree().create_timer(0.2).timeout
			await _screenshot(out + "/04_treffer_%d.png" % rnd)
		if state == "over":
			break
		await _end_player_turn()
		await get_tree().create_timer(0.6).timeout
		await _screenshot(out + "/05_gegner_%d.png" % rnd)
	_rotate_cam(90.0)
	await get_tree().create_timer(0.5).timeout
	await _screenshot(out + "/06_gedreht.png")
	print("AUTOTEST FERTIG")
	get_tree().quit()


func _screenshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
