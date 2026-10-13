class_name Fx
extends Node3D
## Effekte: Schüsse (Leuchtspur, Mündungsfeuer), Funken, Blut, Explosionen, schwebende Zahlen.

const FLOAT_COLORS := {
	&"hit": Color(1, 0.55, 0.4), &"crit": Color(1, 0.84, 0.31), &"miss": Color(0.8, 0.85, 0.88),
	&"heal": Color(0.5, 0.78, 0.52), &"bleed": Color(1, 0.42, 0.42), &"fumble": Color(1, 0.32, 0.32),
}


func shot(from: Vector3, to: Vector3, color: Color, melee := false) -> void:
	if melee:
		_flash(to, color, 2.0, 2.5)
		sparks(to, Color(0.9, 0.95, 1.0), 10)
		return
	var length := from.distance_to(to)
	if length < 0.1:
		return
	var tracer := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 0.06, length)
	tracer.mesh = bm
	var m := _glow(color, 5.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tracer.material_override = m
	tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(tracer)
	tracer.position = (from + to) / 2.0
	tracer.look_at_from_position(tracer.position, to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.RIGHT)
	_flash(from, color, 4.0, 4.0)
	var tw := create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, 0.25)
	tw.tween_callback(tracer.queue_free)


func explosion(at: Vector3) -> void:
	_flash(at + Vector3(0, 1, 0), Color(1, 0.6, 0.25), 8.0, 9.0)
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	ball.mesh = sm
	var m := _glow(Color(1, 0.6, 0.2), 4.0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ball.material_override = m
	ball.position = at + Vector3(0, 0.6, 0)
	add_child(ball)
	var tw := create_tween()
	tw.tween_property(ball, "scale", Vector3.ONE * 5.0, 0.4).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.45)
	tw.tween_callback(ball.queue_free)
	_burst(at + Vector3(0, 0.5, 0), Color(1, 0.7, 0.3), 40, 6.0, 0.7)
	_burst(at + Vector3(0, 0.5, 0), Color(0.3, 0.3, 0.32), 24, 2.5, 1.2)


func sparks(at: Vector3, color: Color, amount := 14) -> void:
	_burst(at, color, amount, 4.0, 0.35)


func blood(at: Vector3) -> void:
	_burst(at, Color(0.6, 0.05, 0.05), 16, 2.5, 0.5)


func float_text(at: Vector3, text: String, kind: StringName) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0012
	l.font_size = 40
	l.outline_size = 10
	l.render_priority = 3
	l.modulate = FLOAT_COLORS.get(kind, Color.WHITE)
	l.position = at + Vector3(0, 2.9, 0)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y + 1.4, 1.3).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.8)
	tw.tween_callback(l.queue_free)


func _flash(at: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.position = at
	add_child(light)
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.18)
	tw.tween_callback(light.queue_free)


func _burst(at: Vector3, color: Color, amount: int, speed: float, life: float) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9.0, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.07, 0.07, 0.07)
	p.mesh = mesh
	p.material_override = _glow(color, 2.0)
	p.position = at
	add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.3).timeout.connect(p.queue_free)


func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
