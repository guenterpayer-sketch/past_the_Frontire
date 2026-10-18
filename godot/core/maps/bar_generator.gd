extends MapGenerator
## Bar: Theke mit Flaschenregal oben, Tische, Sitzecken, Bühne (Höhe 1), rechts Hinterzimmer und Toiletten
## hinter einer Wand mit Durchgängen. Eingang links.


func _init() -> void:
	check_all = true


func _layout(cols: int, rows: int) -> void:
	_ground(cols, rows)
	_border(cols, rows)
	var mid := rows / 2
	# rechts: Hinterzimmer (oben) und Toiletten (unten) hinter einer Wand
	var back := cols - maxi(7, cols / 4)
	_vwall(back, 1, rows - 2, [[mid - 1, 2], [3, 2], [rows - 5, 2]])
	var split := mid - 2
	_hwall(split, back + 1, cols - 2, [[back + 2, 2]])
	_place(&"kiste", 1, 1, maxi(2, (cols - back) * split / 14), back + 1, 1, cols - 2, split - 1, 1)
	for c in range(back + 3, cols - 2, 3):
		_vwall(c, rows - 4, rows - 2)
	# Theke oben mittig (L-Form), dahinter das Flaschenregal an der Wand
	var t0 := maxi(6, back * 3 / 10)
	var t1 := maxi(t0 + 5, back * 3 / 4)
	var bar_obj := _next_obj()
	for c in range(t0, t1):
		_cell(c, 4, &"theke", 0, bar_obj)
	_cell(t1, 4, &"theke", 0, bar_obj)
	_cell(t1, 3, &"theke", 0, bar_obj)
	_rect(t0, 1, t1 - t0, 1, &"schrank")
	# Bühne unten (Höhe 1) mit Stufen an beiden Seiten
	var sw := maxi(4, back / 4)
	var sc := clampi(back / 2 - sw / 2, 6, back - sw - 2)
	_rect(sc, rows - 4, sw, 3, &"podest", 1)
	_cell(sc - 1, rows - 3, &"treppe")
	_cell(sc + sw, rows - 3, &"treppe")
	# Sitzecken an der unteren Wand links der Bühne und an der oberen Wand links der Theke
	for c in range(5, sc - 2, 4):
		_rect(c, rows - 2, 2, 1, &"sofa")
	for c in range(5, t0 - 2, 4):
		_rect(c, 1, 2, 1, &"sofa")
	# runde Tische im Raum
	_place(&"tisch", 1, 1, maxi(4, back * rows / 34), 5, 6, back - 2, rows - 6)
