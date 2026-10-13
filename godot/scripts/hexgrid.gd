extends RefCounted
## Hexraster wie in js/hex.js: Spitze oben (pointy-top), versetzte Reihen (odd-r), 1 Hex = 1,5 m.
## Feld = Vector2i(Spalte, Reihe); in der Welt liegt x nach rechts, z nach vorne (Reihen).

const W := 1.5             # Abstand der Feldmitten in einer Reihe
const ROW_H := 1.2990381   # Reihenabstand = 1,5 · √3/2
const R := 0.8660254       # Außenradius eines Feldes
const DIRS := [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]


static func to_world(t: Vector2i) -> Vector2:
	return Vector2(t.x * W + (W / 2.0 if (t.y & 1) == 1 else 0.0), t.y * ROW_H)


static func to_axial(t: Vector2i) -> Vector2i:
	return Vector2i(t.x - (t.y - (t.y & 1)) / 2, t.y)


static func from_axial(a: Vector2i) -> Vector2i:
	return Vector2i(a.x + (a.y - (a.y & 1)) / 2, a.y)


static func distance(a: Vector2i, b: Vector2i) -> int:
	var p := to_axial(a)
	var q := to_axial(b)
	var dq := p.x - q.x
	var dr := p.y - q.y
	return (absi(dq) + absi(dr) + absi(dq + dr)) / 2


static func from_world(p: Vector2) -> Vector2i:
	var z := p.y / ROW_H
	var x := p.x / W - z / 2.0
	var y := -x - z
	var rx := roundf(x)
	var ry := roundf(y)
	var rz := roundf(z)
	var dx := absf(rx - x)
	var dy := absf(ry - y)
	var dz := absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return from_axial(Vector2i(int(rx), int(rz)))


static func neighbors(t: Vector2i) -> Array:
	var a := to_axial(t)
	var res := []
	for d in DIRS:
		res.append(from_axial(a + d))
	return res


## Ecken eines Feldes (relativ zur Mitte), Spitze zeigt in ±z
static func corners(radius := R) -> Array:
	var res := []
	for i in 6:
		var ang := deg_to_rad(60.0 * i + 30.0)
		res.append(Vector2(cos(ang) * radius, sin(ang) * radius))
	return res
