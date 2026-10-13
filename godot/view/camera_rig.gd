class_name CameraRig
extends Node3D
## Isometrische Kamera: verschieben, zoomen (orthografisch), in 90°-Schritten drehen, kurz wackeln.

signal rotated

const PITCH := 42.0
const MIN_SIZE := 8.0
const MAX_SIZE := 70.0

var yaw := 30.0
## Bildschirmbreite (Pixel), die rechts vom Panel verdeckt ist – die Kartenmitte rückt nach links
var right_inset := 0.0
var _arm: Node3D
var _shake := 0.0
var _shake_t := 0.0
var bounds := Rect2()

@onready var camera: Camera3D = $Arm/Camera3D


func _ready() -> void:
	_arm = $Arm
	_arm.rotation_degrees.x = -PITCH
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 24.0
	camera.near = 0.1
	camera.far = 300.0
	camera.position = Vector3(0, 0, 80)
	rotation_degrees.y = yaw


func _process(delta: float) -> void:
	if _shake_t > 0.0:
		_shake_t -= delta
		var k := _shake * maxf(_shake_t, 0.0) * 4.0
		camera.v_offset = randf_range(-k, k) * 0.03
	else:
		camera.v_offset = 0.0
	# Kartenmitte im sichtbaren Bereich links vom Panel
	var vh := get_viewport().get_visible_rect().size.y
	camera.h_offset = right_inset / 2.0 * camera.size / maxf(vh, 1.0)


## Richtung von der Kartenmitte zur Kamera (waagerecht)
func view_dir() -> Vector3:
	var d := camera.global_position - global_position
	d.y = 0.0
	return d.normalized()


func focus(p: Vector3, instant := true) -> void:
	var target := Vector3(p.x, 0, p.z)
	if instant:
		position = target
	else:
		create_tween().tween_property(self, "position", target, 0.3).set_trans(Tween.TRANS_SINE)


## Figur im Bild halten
func ensure_visible(p: Vector3) -> void:
	var sp := camera.unproject_position(p)
	var r := get_viewport().get_visible_rect()
	var m := 90.0
	if sp.x < m or sp.y < m + 40.0 or sp.x > r.size.x - right_inset - m or sp.y > r.size.y - m:
		focus(p, false)


func pan(screen_delta: Vector2) -> void:
	var vh := get_viewport().get_visible_rect().size.y
	var s := camera.size / maxf(vh, 1.0)
	var right := basis.x
	var fwd := Vector3(-basis.z.x, 0, -basis.z.z).normalized()
	position -= right * screen_delta.x * s - fwd * screen_delta.y * s / sin(deg_to_rad(PITCH))
	_clamp()


func zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := _ground(screen_pos)
	camera.size = clampf(camera.size / factor, MIN_SIZE, MAX_SIZE)
	var after := _ground(screen_pos)
	position += before - after
	_clamp()


func rotate_by(deg: float) -> void:
	yaw += deg
	var tw := create_tween()
	tw.tween_property(self, "rotation_degrees:y", yaw, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(rotated.emit)


func shake(strength := 1.0, time := 0.25) -> void:
	_shake = strength
	_shake_t = time


## Schnittpunkt des Sichtstrahls mit der Ebene y = height
func ray_plane(screen_pos: Vector2, height := 0.0) -> Variant:
	var from := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 1e-5:
		return null
	var t := (height - from.y) / dir.y
	return from + dir * t if t > 0 else null


func _ground(screen_pos: Vector2) -> Vector3:
	var p: Variant = ray_plane(screen_pos, 0.0)
	return p if p != null else position


func _clamp() -> void:
	if bounds.size == Vector2.ZERO:
		return
	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.z = clampf(position.z, bounds.position.y, bounds.end.y)
