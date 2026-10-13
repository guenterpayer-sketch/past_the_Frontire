class_name ModelFigure
extends Figure
## Figur als 3D-Modell mit Animationen (CharacterVisual). Waffe in der rechten Hand.

## Spielzustand -> Animationsname (übertragene KayKit-Animationen); CharacterVisual.anim_names überschreibt
const DEFAULT_ANIMS := {
	"idle": "idle", "aim2": "aim2", "aim1": "aim1", "walk": "walk", "run": "run", "shoot2": "shoot2",
	"shoot1": "shoot1", "melee": "melee", "punch": "punch", "spell": "spell", "hit": "hit", "death": "death",
	"ko": "ko", "standup": "standup", "aid": "aid", "reload": "reload", "cheer": "cheer", "crouch": "crouch",
}
## Anteil der Handlungsanimation, bis der Schuss/Schlag fällt
const HIT_POINT := 0.45

var visual: CharacterVisual
var _model: Node3D
var _player: AnimationPlayer
var _skeleton: Skeleton3D
var _weapon_node: Node3D
var _ghost: StandardMaterial3D
var _meshes: Array[MeshInstance3D] = []
var _moving: StringName = &""
var _busy := false
var _prefix := ""


func setup(u: Combatant) -> void:
	super(u)
	visual = u.data.visual
	_model = visual.model.instantiate()
	add_child(_model)
	var aabb := _measure(_model)
	var k := visual.height_m / maxf(aabb.size.y, 0.01)
	_model.scale = Vector3.ONE * k
	_model.rotation_degrees.y = visual.rotation_y_deg
	_model.position.y = -aabb.position.y * k
	_skeleton = _first(_model, "Skeleton3D")
	if visual.animations:
		_player = AnimationPlayer.new()
		_model.add_child(_player)
		_player.root_node = _player.get_path_to(_model)
		_player.add_animation_library("ptf", visual.animations)
		_prefix = "ptf/"
	else:
		_player = _first(_model, "AnimationPlayer")
	_ghost = StandardMaterial3D.new()
	_ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost.set("depth_test", 1)  # umgekehrter Tiefentest: nur sichtbar, wo die Figur verdeckt ist
	_ghost.albedo_color = Color(u.color, 0.2)
	_ghost.render_priority = -1
	for mi in _model.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(mi)
		mi.material_overlay = _ghost
	_attach_weapon(u.weapons[0])
	if u.shield:
		_attach_shield()
	if _player:
		_player.animation_finished.connect(func(_n: StringName) -> void:
			if not _busy:
				_play_base())
	_play_base()


func set_pose(p: Pose) -> void:
	super(p)
	if not _busy and _moving == &"":
		_play_base()


func set_moving(gait: StringName) -> void:
	if gait == _moving:
		return
	_moving = gait
	if _busy:
		return
	if gait == &"":
		_play_base()
	else:
		_play("run" if gait != &"gehen" else "walk", 0.15)


func act(action: StringName, weapon: WeaponData = null) -> void:
	var state := String(action)
	if action == &"attack" and weapon:
		if weapon.psi:
			state = "spell"
		elif weapon.melee:
			state = "punch" if weapon.id == &"faeuste" else "melee"
		else:
			state = "shoot2" if weapon.two_handed else "shoot1"
		_show_weapon(weapon)
	var anim := _anim(state)
	if anim == "":
		return
	_busy = true
	_player.play(anim, 0.1)
	var length := _player.get_animation(anim).length
	await get_tree().create_timer(length * HIT_POINT).timeout
	_finish_action(anim, length * (1.0 - HIT_POINT))


func _finish_action(anim: String, rest: float) -> void:
	await get_tree().create_timer(rest).timeout
	if _player.current_animation == anim or not _player.is_playing():
		_busy = false
		_play_base()
	else:
		_busy = false


func play_hit() -> void:
	if pose == Pose.KO or pose == Pose.DEAD or _busy:
		return
	_busy = true
	var anim := _anim("hit")
	if anim == "":
		_busy = false
		return
	_player.play(anim, 0.05)
	_finish_action(anim, _player.get_animation(anim).length)


func fall(dead: bool) -> void:
	_busy = true
	pose = Pose.DEAD if dead else Pose.KO
	var anim := _anim("death" if dead else "ko")
	if anim != "":
		_player.play(anim, 0.1)
		await get_tree().create_timer(_player.get_animation(anim).length).timeout
	_busy = false


func stand_up() -> void:
	var anim := _anim("standup")
	pose = Pose.STAND
	if anim == "":
		_play_base()
		return
	_busy = true
	_player.play(anim, 0.1)
	_finish_action(anim, _player.get_animation(anim).length)


func set_ghost(on: bool) -> void:
	_ghost.albedo_color.a = 0.2 if on else 0.0


func head_height() -> float:
	return visual.height_m


func muzzle() -> Vector3:
	if _weapon_node and _weapon_node.visible:
		var tip := Vector3(_weapon_node.get_meta("length", 0.8) / 2.0, 0, 0)
		return _weapon_node.global_transform.origin + _weapon_node.global_transform.basis.orthonormalized() * tip
	return super()


# ---------------------------------------------------------------- intern

func _play_base() -> void:
	if _player == null:
		return
	if _moving != &"":
		_play("run" if _moving != &"gehen" else "walk", 0.15)
		return
	match pose:
		Pose.AIM:
			_play("aim2" if unit.weapon.two_handed else "aim1", 0.2)
		Pose.CROUCH:
			_play("crouch", 0.25)
		Pose.KO:
			_hold_end("ko")
		Pose.DEAD:
			_hold_end("death")
		_:
			_play("idle", 0.25)


func _play(state: String, blend: float) -> void:
	var anim := _anim(state)
	if anim != "" and _player.current_animation != anim:
		_player.play(anim, blend)


## letzte Haltung einer Animation halten (liegen bleiben)
func _hold_end(state: String) -> void:
	var anim := _anim(state)
	if anim == "":
		return
	_player.play(anim)
	_player.seek(_player.get_animation(anim).length, true)
	_player.pause()


func _anim(state: String) -> String:
	if _player == null:
		return ""
	var name: String = visual.anim_names.get(state, DEFAULT_ANIMS.get(state, ""))
	if name == "":
		return ""
	var full := _prefix + name
	return full if _player.has_animation(full) else ""


func _attach_weapon(w: WeaponData) -> void:
	if visual.hand_bone == "" or _skeleton == null or _skeleton.find_bone(visual.hand_bone) < 0:
		return
	var att := BoneAttachment3D.new()
	_skeleton.add_child(att)
	att.bone_name = visual.hand_bone
	_weapon_node = Node3D.new()
	att.add_child(_weapon_node)
	_show_weapon(w)


## Waffenmodell in die Hand (bei Waffenwechsel neu). Die Modelle liegen entlang x;
## sie werden auf length_m skaliert, die Lage in der Hand stellen grip_offset/grip_rotation_deg ein.
func _show_weapon(w: WeaponData) -> void:
	if _weapon_node == null:
		return
	for c in _weapon_node.get_children():
		c.queue_free()
	var m := _weapon_mesh(w)
	_weapon_node.visible = m != null
	if m == null:
		return
	_weapon_node.add_child(m)
	# der Handknochen trägt die Skalierung von Modell und Skelett: hier ausgleichen, damit Meter gelten
	var s_att := (_weapon_node.get_parent() as Node3D).global_transform.basis.get_scale().x
	_weapon_node.scale = Vector3.ONE / maxf(s_att, 0.0001)
	var grip := w.grip_offset if w.model else Vector3(0, 0.12, 0)
	_weapon_node.position = grip / maxf(s_att, 0.0001)
	_weapon_node.rotation_degrees = w.grip_rotation_deg if w.model else Vector3(0, 0, 90)
	_weapon_node.set_meta("length", w.length_m if w.model else 0.3)


## Waffenmodell (entlang x, Mitte im Ursprung) oder leuchtender Ersatz für Klinge und Psi; Fäuste: nichts
func _weapon_mesh(w: WeaponData) -> Node3D:
	if w.model:
		var m: Node3D = w.model.instantiate()
		var aabb := _measure(m)
		var k := w.length_m / maxf(aabb.size.x, 0.01)
		m.scale = Vector3.ONE * k
		m.position = -aabb.get_center() * k
		return m
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	if w.psi:
		var orb := SphereMesh.new()
		orb.radius = 0.1
		orb.height = 0.2
		mi.mesh = orb
		mat.albedo_color = Color(0.75, 0.5, 1.0)
	elif w.melee and w.id != &"faeuste":
		var blade := BoxMesh.new()
		blade.size = Vector3(0.85, 0.06, 0.02)
		mi.mesh = blade
		mi.position.x = 0.35
		mat.albedo_color = Color(0.6, 0.85, 1.0)
	else:
		return null
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 2.0
	mi.material_override = mat
	return mi


## Schild an der linken Hand (nur Grundform, es gibt kein passendes Modell)
func _attach_shield() -> void:
	var bone := visual.hand_bone.replace(".R", ".L")
	if _skeleton == null or _skeleton.find_bone(bone) < 0:
		return
	var att := BoneAttachment3D.new()
	_skeleton.add_child(att)
	att.bone_name = bone
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.5, 0.65, 0.05)
	mi.mesh = b
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.55, 0.62)
	mat.metallic = 0.6
	mat.roughness = 0.4
	mi.material_override = mat
	att.add_child(mi)
	var s_att := att.global_transform.basis.get_scale().x
	mi.scale = Vector3.ONE / maxf(s_att, 0.0001)
	mi.position = Vector3(0, 0.1, 0.12) / maxf(s_att, 0.0001)


static func _first(n: Node, cls: String) -> Node:
	var found := n.find_children("*", cls, true, false)
	return found[0] if not found.is_empty() else null


## Umriss aller Meshes eines Modells (in dessen eigenem Raum, ohne Animation)
static func _measure(root: Node) -> AABB:
	var out := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D()
		var n: Node = mi
		while n != root and n != null:
			if n is Node3D:
				xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var a: AABB = xf * (mi as MeshInstance3D).get_aabb()
		out = a if first else out.merge(a)
		first = false
	return out
