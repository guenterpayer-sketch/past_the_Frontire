class_name EventPlayer
extends Node
## Spielt die Ereignisse des Kampfes der Reihe nach ab: Würfel rollen, Schuss, Treffer, Log-Eintrag.
## Die Spiellogik ist dabei schon weiter; erst wenn die Schlange leer ist, darf es weitergehen.

signal idle_changed(idle: bool)

var views := {}                # Combatant -> UnitView
var map_view: MapView
var fx: Fx
var camera: CameraRig
var dice_panel: DicePanel
var combat_log: CombatLog
var dice_enabled := true

var _queue: Array = []
var _playing := false


func is_idle() -> bool:
	return _queue.is_empty() and not _playing


func clear() -> void:
	_queue.clear()


## Kampf-Signale anschließen
func bind(c: Combat) -> void:
	c.logged.connect(func(text: String, kind: StringName) -> void: _push([&"log", text, kind]))
	c.rolled.connect(func(roll: Dictionary, label: String) -> void: _push([&"roll", roll, label]))
	c.floated.connect(func(u: Combatant, text: String, kind: StringName) -> void: _push([&"float", u, text, kind]))
	c.stepped.connect(func(u: Combatant, _from: Vector2i, to: Vector2i) -> void: _push([&"step", u, to]))
	c.faced.connect(func(u: Combatant) -> void: _push([&"face", u, u.facing]))
	c.attacked.connect(func(u: Combatant, t: Combatant, w: WeaponData) -> void: _push([&"attack", u, t, w]))
	c.unit_changed.connect(func(u: Combatant) -> void: _push([&"sync", u]))
	c.died.connect(func(u: Combatant) -> void: _push([&"death", u]))
	c.crouched.connect(func(u: Combatant) -> void: _push([&"sound", &"ducken", u]))
	c.reloaded.connect(func(u: Combatant) -> void: _push([&"sound", &"nachladen", u]))
	c.overwatch_fired.connect(func(u: Combatant) -> void: _push([&"sound", &"alarm", u]))
	c.round_started.connect(func(_n: int) -> void: _push([&"sound", &"runde", null]))
	c.turn_started.connect(func(u: Combatant) -> void: _push([&"turn", u]))


func _push(ev: Array) -> void:
	var was_idle := is_idle()
	_queue.append(ev)
	if was_idle:
		idle_changed.emit(false)
	if not _playing:
		_run()


func _run() -> void:
	_playing = true
	# erst im nächsten Bild anfangen, damit eine ganze Aktion in der Schlange liegt
	await get_tree().process_frame
	while not _queue.is_empty():
		var ev: Array = _queue.pop_front()
		await _play(ev)
	_playing = false
	idle_changed.emit(true)


func _play(ev: Array) -> void:
	match ev[0]:
		&"log":
			combat_log.add(ev[1], ev[2])
		&"roll":
			if dice_enabled:
				Sfx.play(&"wuerfel")
				await dice_panel.show_roll(ev[1], ev[2])
		&"float":
			var v: UnitView = views[ev[1]]
			fx.float_text(v.position, ev[2], ev[3])
			match ev[3]:
				&"miss":
					Sfx.play(&"daneben")
				&"fumble":
					Sfx.play(&"patzer")
				&"crit":
					Sfx.play(&"krit")
				&"heal":
					Sfx.play(&"heilen")
				&"hit", &"bleed":
					Sfx.play(&"treffer")
					v.play_hit()
					fx.blood(v.position + Vector3(0, 1.1, 0))
					camera.shake(1.0, 0.15)
			v.sync()
			await get_tree().create_timer(0.08).timeout
		&"step":
			var v: UnitView = views[ev[1]]
			Sfx.play(&"schritt")
			await v.step_to(map_view.tile_top(ev[2]))
		&"face":
			views[ev[1]].set_facing(ev[2])
		&"attack":
			await _attack(ev[1], ev[2], ev[3])
		&"sync":
			views[ev[1]].sync()
		&"death":
			Sfx.play(&"tod")
			await views[ev[1]].play_down()
		&"sound":
			Sfx.play(ev[1])
			if ev[2]:
				views[ev[2]].sync()
		&"turn":
			for u in views:
				views[u].set_current(u == ev[1])
			camera.ensure_visible(views[ev[1]].position)


func _attack(u: Combatant, t: Combatant, w: WeaponData) -> void:
	var a: UnitView = views[u]
	var b: UnitView = views[t]
	var dir := (b.position - a.position)
	dir.y = 0
	a.set_facing(Hex.dir_toward(u.pos, t.pos))
	Sfx.play(w.sound())
	var from := a.position + Vector3(0, 1.2, 0) + dir.normalized() * 0.7
	var to := b.position + Vector3(0, 1.0, 0)
	var color := Color(0.77, 0.55, 1.0) if w.psi else (Color(1, 0.35, 0.3) if w.table.id == &"strahl" else Color(1, 0.88, 0.55))
	if not w.splash.is_empty():
		color = Color(1, 0.6, 0.24)
	fx.shot(from, to, color, w.melee)
	if not w.splash.is_empty():
		await get_tree().create_timer(0.28).timeout
		fx.explosion(b.position)
		camera.shake(3.0, 0.35)
	elif not w.melee and not w.psi:
		fx.sparks(to, Color(1, 0.85, 0.5), 10)
	await get_tree().create_timer(0.18).timeout
