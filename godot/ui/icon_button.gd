class_name IconButton
extends Button
## Quadratischer Knopf mit gezeichnetem Strich-Symbol (keine Bilddateien, keine Sonderzeichen in der Schrift nötig).

var icon_id: StringName


func _init(id: StringName, tip: String, is_toggle := false, side := 44.0) -> void:
	icon_id = id
	tooltip_text = tip
	toggle_mode = is_toggle
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(side, side)
	toggled.connect(func(_on: bool) -> void: queue_redraw())


func _draw() -> void:
	var c := UiTheme.ACCENT if button_pressed else (UiTheme.TEXT if not disabled else UiTheme.MUTED)
	var o := size / 2.0
	var k := minf(size.x, size.y) / 48.0  # Symbole auf einem 24er-Raster entworfen, halb so groß wie der Knopf
	var w := 2.0
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x - 12.0, y - 12.0) * k
	match icon_id:
		&"person":
			draw_arc(p.call(12, 8), 4 * k, 0, TAU, 24, c, w, true)
			draw_polyline(_curve(p, [[4, 21], [6, 17], [12, 15], [18, 17], [20, 21]]), c, w, true)
		&"table":
			draw_rect(Rect2(p.call(3, 4), Vector2(18, 16) * k), c, false, w)
			draw_line(p.call(3, 10), p.call(21, 10), c, w, true)
			draw_line(p.call(3, 15), p.call(21, 15), c, w, true)
			draw_line(p.call(10, 4), p.call(10, 20), c, w, true)
		&"chip":
			draw_rect(Rect2(p.call(6, 6), Vector2(12, 12) * k), c, false, w)
			for v in [9.0, 15.0]:
				draw_line(p.call(v, 2), p.call(v, 6), c, w, true)
				draw_line(p.call(v, 18), p.call(v, 22), c, w, true)
				draw_line(p.call(2, v), p.call(6, v), c, w, true)
				draw_line(p.call(18, v), p.call(22, v), c, w, true)
		&"speaker":
			draw_polyline(_curve(p, [[4, 9], [8, 9], [13, 5], [13, 19], [8, 15], [4, 15], [4, 9]]), c, w, true)
			if button_pressed:
				draw_arc(p.call(13, 12), 4 * k, -0.9, 0.9, 12, c, w, true)
				draw_arc(p.call(13, 12), 7.5 * k, -0.9, 0.9, 16, c, w, true)
			else:
				draw_line(p.call(16, 9), p.call(21, 15), c, w, true)
				draw_line(p.call(21, 9), p.call(16, 15), c, w, true)
		&"dice":
			draw_polyline(_curve(p, [[12, 2], [21, 9], [17.5, 20], [6.5, 20], [3, 9], [12, 2]]), c, w, true)
			draw_polyline(_curve(p, [[3, 9], [12, 10], [21, 9]]), c, w, true)
			draw_line(p.call(12, 2), p.call(12, 10), c, w, true)
			draw_line(p.call(12, 10), p.call(6.5, 20), c, w, true)
			draw_line(p.call(12, 10), p.call(17.5, 20), c, w, true)
		&"menu":
			for y in [6.0, 12.0, 18.0]:
				draw_line(p.call(4, y), p.call(20, y), c, w, true)
		&"rot_l", &"rot_r":
			# Bogen oben mit Pfeilspitze: rot_r im Uhrzeigersinn (Spitze rechts), rot_l gespiegelt
			var m := 1.0 if icon_id == &"rot_r" else -1.0
			var pts := PackedVector2Array()
			for i in 17:
				var a := lerpf(PI * 0.9, PI * 2.1, i / 16.0)
				pts.append(p.call(12 + m * cos(a) * 8, 14 + sin(a) * 8))
			draw_polyline(pts, c, w, true)
			var e := pts[pts.size() - 1]
			draw_line(e, e + Vector2(m * 4, -3) * k, c, w, true)
			draw_line(e, e + Vector2(m * -1.5, -4.8) * k, c, w, true)
		&"log":
			draw_rect(Rect2(p.call(5, 4), Vector2(14, 16) * k), c, false, w)
			for y in [9.0, 13.0]:
				draw_line(p.call(8, y), p.call(16, y), c, w, true)
			draw_line(p.call(8, 17), p.call(13, 17), c, w, true)


func _curve(p: Callable, pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(p.call(float(q[0]), float(q[1])))
	return out
