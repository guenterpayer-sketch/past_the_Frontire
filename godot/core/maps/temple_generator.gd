extends MapGenerator
## Antiker Tempel: Hauptschiff mit Säulenreihen (teils zerbrochen), Seitenkammern hinter Mauern mit Bögen,
## Geröll, Altar-Podest (Höhe 1, innen Höhe 2) auf der Gegnerseite. Eingang links.


func _init() -> void:
	check_all = true


func _layout(cols: int, rows: int) -> void:
	_ground(cols, rows)
	_border(cols, rows)
	var a := maxi(3, rows / 4)
	var b := rows - 1 - a
	# Seitenkammern: Mauern mit Bögen (2 Felder breit)
	var arches_a: Array = []
	var arches_b: Array = []
	var c := _ri(4, 6)
	while c < cols - 4:
		arches_a.append([c, 2])
		arches_b.append([c + _ri(1, 3), 2])
		c += _ri(6, 8)
	_hwall(a, 1, cols - 2, arches_a)
	_hwall(b, 1, cols - 2, arches_b)
	# Altar-Podest rechts
	var pc := cols - 7
	var p0 := a + 2
	var p1 := b - 2
	_rect(pc, p0, cols - 1 - pc, p1 - p0 + 1, &"podest", 1)
	var mid := rows / 2
	_rect(pc + 3, mid - 1, 2, 2, &"podest", 2)
	_cell(pc + 4, mid, &"altar", 2)
	for r in range(p0 + 1, p1, 3):
		_cell(pc - 1, r, &"treppe")
	# Säulenreihen im Hauptschiff
	for x in range(5, pc - 2, 3):
		for r in [a + 2, b - 2]:
			var t := m.at_offset(x, r)
			if _free(t):
				_put(t, &"bruch" if rng.randf() < 0.25 else &"steinsaeule", 0)
	# Seitenkammern: Geröll und Statuen
	_place(&"geroell", 1, 1, maxi(2, cols / 6), 2, 1, cols - 3, a - 1)
	_place(&"geroell", 1, 1, maxi(2, cols / 6), 2, b + 1, cols - 3, rows - 2)
	_place(&"statue", 1, 1, 1, 6, 1, cols - 4, a - 1)
	_place(&"statue", 1, 1, 1, 6, b + 1, cols - 4, rows - 2)
	# Geröll im Hauptschiff
	_place(&"geroell", 1, 1, maxi(2, cols * rows / 110), 5, a + 1, pc - 2, b - 1)
