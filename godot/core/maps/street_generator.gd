extends MapGenerator
## Straßenkampf: Häuserzeilen oben und unten mit Gassen, Fahrbahn mit Gehwegen und einer Querstraße,
## Fahrzeuge (volle Deckung), Laternen, Müllcontainer, Barrieren, ein Flachdach (Höhe 2) über eine Leiter.
## Die Straße ist links und rechts offen.


func _init() -> void:
	check_all = true


func _layout(cols: int, rows: int) -> void:
	_ground(cols, rows)
	var top := maxi(3, rows / 5)
	var bot := rows - top
	# Häuserblöcke
	for r in range(0, top):
		_hwall(r, 0, cols - 1, [], &"gebaeude")
	for r in range(bot, rows):
		_hwall(r, 0, cols - 1, [], &"gebaeude")
	# Querstraße
	var cx := cols / 2 - 1 + _ri(-2, 2)
	for r in rows:
		for c in range(cx, cx + 3):
			var t := m.at_offset(c, r)
			t.terrain = &"boden"
			t.reserved = false
	# Gassen (Sackgassen) in beide Häuserzeilen
	var c := _ri(4, 7)
	while c < cols - 4:
		if absi(c - cx) > 3:
			for r in range(1, top):
				for k in 2:
					_floor(c + k, r)
			if rng.randf() < 0.6:
				_cell(c + _ri(0, 1), 1, &"tonne")
		c += _ri(6, 9)
	c = _ri(5, 9)
	while c < cols - 4:
		if absi(c - cx) > 3:
			for r in range(bot, rows - 1):
				for k in 2:
					_floor(c + k, r)
			if rng.randf() < 0.6:
				_cell(c + _ri(0, 1), rows - 2, &"tonne")
		c += _ri(7, 10)
	# Flachdach (Höhe 2) in der unteren Häuserzeile, Leiter vom Gehweg
	var rc := _ri(5, maxi(5, cx - 7))
	if rc + 5 < cx:
		_rect(rc, bot, 5, rows - bot - 1, &"podest", 2)
		_cell(rc + 2, bot - 1, &"leiter")
	# Gehwege mit Laternen
	for x in cols:
		for r in [top, bot - 1]:
			var t := m.at_offset(x, r)
			if t.terrain == &"boden" and not t.reserved:
				t.terrain = &"gehweg"
	for x in range(3, cols - 2, 6):
		_lamp(x, top)
		_lamp(x + 3, bot - 1)
	# Fahrzeuge auf den Spuren (3 Felder lang), Barrieren dazwischen
	var mid := (top + bot) / 2
	for r in [top + 2, mid - 1 if (mid - top) % 2 else mid, bot - 3]:
		var x := _ri(3, 6)
		while x < cols - 5:
			if rng.randf() < 0.7 and _all_free(_line_tiles(x, r, 3, false)) and (x + 3 < cx or x > cx + 3):
				_rect(x, r, 3, 1, &"auto")
			x += _ri(5, 9)
	_place(&"barriere", 2, 1, maxi(3, cols / 6), 6, top + 2, cols - 6, bot - 3)
	_place(&"tonne", 1, 1, maxi(2, cols / 8), 5, top + 1, cols - 5, bot - 2)


func _floor(c: int, r: int) -> void:
	var t := m.at_offset(c, r)
	if t:
		t.terrain = &"boden"
		t.reserved = false
		t.obj = 0


func _lamp(c: int, r: int) -> void:
	var t := m.at_offset(c, r)
	if t and t.terrain == &"gehweg" and not t.reserved:
		_put(t, &"laterne", 0)
