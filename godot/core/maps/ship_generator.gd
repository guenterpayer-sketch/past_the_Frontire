extends MapGenerator
## Raumschiff-Inneres (nur beim Entern): Rumpf mit spitzem Bug rechts, Luftschleuse links, Schotts mit
## Durchgängen, Laderaum mit Kisten, Containern und Laufsteg (Höhe 2, Leiter), Maschinenraum mit Tanks,
## Brücke mit Konsolen. Außerhalb des Rumpfs: Außenraum (nicht begehbar).


func _init() -> void:
	check_all = true


func _layout(cols: int, rows: int) -> void:
	_ground(cols, rows, &"leer")
	var mid := (rows - 1) / 2.0
	# Rumpf: Heck links etwas schmaler, Bug rechts spitz zulaufend
	for t in m.list:
		var x := float(t.col) / (cols - 1)
		var half := rows / 2.0 * (0.62 + x * 3.0 if x < 0.12 else (maxf(0.38, 1.0 - (x - 0.8) * 3.0) if x > 0.8 else 0.98))
		if absf(t.row - mid) < half - 0.3 and t.col > 0 and t.col < cols - 1:
			t.terrain = &"boden"
	# Außenhaut: Bodenfelder am Rand des Rumpfs
	var hull: Array[T] = []
	for t in m.list:
		if t.terrain != &"boden":
			continue
		for n in Hex.neighbors(t.pos):
			var nt := m.tile(n)
			if nt == null or nt.terrain == &"leer":
				hull.append(t)
				break
	for t in hull:
		_put(t, &"innenwand", 0)
	# Luftschleuse links in der Mitte
	var mr := int(mid)
	for r in [mr, mr + 1]:
		for c in cols:
			var t := m.at_offset(c, r)
			if t.terrain == &"innenwand":
				t.terrain = &"boden"
				t.reserved = false
				break
	# Schotts mit Durchgängen (Mittelgang und je ein Seitengang)
	var bays: Array[int] = [cols * 22 / 100, cols * 55 / 100, cols * 80 / 100]
	for bc in bays:
		var side := maxi(3, rows / 5)
		_vwall(bc, 1, rows - 2, [[mr - 1, 3], [mr - side - 1, 2], [mr + side, 2]])
		# Wandfelder außerhalb des Rumpfs zurücksetzen
		for r in rows:
			var t := m.at_offset(bc, r)
			if t.terrain == &"innenwand" and _outside(t):
				t.terrain = &"leer"
	# Laderaum: Laufsteg oben, Container, Kisten
	var c0 := bays[0] + 1
	var c1 := bays[1] - 1
	var top := _first_row(c0 + 2)
	if top > 0:
		var gal := _next_obj()
		for c in range(c0, c1 + 1):
			var t := m.at_offset(c, top)
			if t.terrain == &"boden" and not t.reserved:
				_put(t, &"galerie", 2, gal)
		_cell(c0 + 2, top + 1, &"leiter")
	_place(&"container", 2, 2, maxi(1, (c1 - c0) / 6), c0 + 1, top + 2, c1 - 1, rows - 3, 2)
	_place(&"kiste", 1, 1, maxi(3, (c1 - c0) * rows / 40), c0 + 1, top + 2, c1, rows - 2, 1)
	# Maschinenraum: Tanks oben und unten
	for c in range(bays[1] + 2, bays[2] - 1, 3):
		for r in [mr - 3, mr + 4]:
			var t := m.at_offset(c, r)
			if _free(t):
				_put(t, &"tank", 0)
	_place(&"kiste", 1, 1, maxi(2, (bays[2] - bays[1]) / 3), bays[1] + 1, 1, bays[2] - 1, rows - 2, 1)
	_place(&"schrank", 1, 1, 2, bays[1] + 1, 1, bays[2] - 1, rows - 2)
	# Brücke: Konsolenreihen
	for r in [mr - 2, mr, mr + 3]:
		for c in range(bays[2] + 2 + (1 if r == mr else 0), cols - 3, 3):
			var t := m.at_offset(c, r)
			if _free(t):
				_put(t, &"konsole", 0)
	# Heck: ein paar Kisten
	_place(&"kiste", 1, 1, 2, 5, 1, bays[0] - 1, rows - 2, 1)
	# Container sind über Kisten oder Leiter erreichbar: freie Leiter an jedem Container
	for t in m.list:
		if t.terrain == &"container":
			_ladder_next_to(t)


func _outside(t: T) -> bool:
	for n in Hex.neighbors(t.pos):
		var nt := m.tile(n)
		if nt and nt.terrain == &"boden":
			return false
	return true


## oberste Bodenreihe in Spalte c (unterhalb der Außenhaut)
func _first_row(c: int) -> int:
	for r in m.rows:
		var t := m.at_offset(c, r)
		if t and t.terrain == &"boden":
			return r
	return -1


var _laddered := {}

func _ladder_next_to(t: T) -> void:
	if _laddered.has(t.obj):
		return
	for n in Hex.neighbors(t.pos):
		var nt := m.tile(n)
		if _free(nt):
			_put(nt, &"leiter", 0)
			_laddered[t.obj] = true
			return
