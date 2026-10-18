extends MapGenerator
## Büroräume: oben ein Großraum mit Schreibtisch-Gruppen, Schränken und einem Zwischengeschoss (Höhe 2, Leiter),
## unten Einzelräume hinter einer Wand mit Türen (Besprechungsraum links, Serverraum rechts). Eingang links.


func _init() -> void:
	check_all = true


func _layout(cols: int, rows: int) -> void:
	_ground(cols, rows)
	_border(cols, rows)
	var wall_r := rows / 2 + 1
	# Einzelräume unten: Trennwände, je Raum eine Tür in der Wand zum Großraum
	var doors: Array = []
	var rooms: Array = []
	var c := 5
	while c < cols - 6:
		var w := _ri(5, 8)
		var end := mini(c + w, cols - 1)
		rooms.append([c, end])
		doors.append([c + 2, 2])
		if end < cols - 2:
			_vwall(end, wall_r + 1, rows - 2)
		c = end
	# Rest rechts neben dem letzten Raum (ohne eigene Trennwand) braucht auch eine Tür
	if not rooms.is_empty() and rooms[-1][1] < cols - 3:
		doors.append([rooms[-1][1] + 1, 2])
	_hwall(wall_r, 1, cols - 2, doors)
	_vwall(5, wall_r + 1, rows - 2, [[rows - 4, 2]])
	# Besprechungsraum (erster Raum): langer Tisch
	if rooms.size() > 0:
		var r0: Array = rooms[0]
		var len := maxi(2, rows - wall_r - 5)
		_rect(r0[0] + 2, wall_r + 3, 2, len, &"schreibtisch")
	# Serverraum (letzter Raum): Schrankreihen
	if rooms.size() > 1:
		var rl: Array = rooms[-1]
		for r in range(wall_r + 3, rows - 2, 2):
			_rect(rl[0] + 2, r, maxi(1, rl[1] - rl[0] - 3), 1, &"server")
	# übrige Räume: Schreibtisch und Schrank
	for i in range(1, rooms.size() - 1):
		var rr: Array = rooms[i]
		_place(&"schreibtisch", 2, 1, 1, rr[0] + 1, wall_r + 2, rr[1] - 1, rows - 2)
		_place(&"schrank", 1, 1, 1, rr[0] + 1, rows - 2, rr[1] - 1, rows - 2)
	# Zwischengeschoss oben rechts (Höhe 2) mit Leiter
	var zc := cols * 11 / 20
	_rect(zc, 1, cols - 1 - zc, 2, &"galerie", 2)
	_cell(zc + 1, 3, &"leiter")
	# Großraum: Schreibtisch-Gruppen 2×2, Schränke an der Rückwand
	for x in range(5, cols - 4, 5):
		for y in range(4, wall_r - 2, 4):
			if rng.randf() < 0.8 and _all_free(_line_tiles(x, y, 2, false, 2)) and _all_free(_line_tiles(x - 1, y - 1, 4, false, 1)):
				_rect(x, y, 2, 2, &"schreibtisch")
	for x in range(4, zc - 2, _ri(5, 7)):
		if _free(m.at_offset(x, 1)):
			_rect(x, 1, 2, 1, &"schrank")
