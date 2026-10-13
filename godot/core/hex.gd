class_name Hex
extends RefCounted
## Hex-Mathematik: axiale Koordinaten Vector2i(q, r), Spitze oben, Karte im "odd-r"-Versatz.
## Welt: x nach rechts, z nach vorne; 1 Hex = 1,5 m.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]
const DIR_NAMES := ["O", "NO", "NW", "W", "SW", "SO"]
const SIZE_M := 1.5
const ROW_M := 1.2990381  # Reihenabstand = 1,5 · √3/2
const RADIUS_M := 0.8660254


static func from_offset(col: int, row: int) -> Vector2i:
	return Vector2i(col - (row - (row & 1)) / 2, row)


static func distance(a: Vector2i, b: Vector2i) -> int:
	var dq := a.x - b.x
	var dr := a.y - b.y
	return (absi(dq) + absi(dr) + absi(dq + dr)) / 2


static func neighbors(a: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS:
		out.append(a + d)
	return out


static func round_axial(fq: float, fr: float) -> Vector2i:
	var fs := -fq - fr
	var q := roundf(fq)
	var r := roundf(fr)
	var s := roundf(fs)
	var dq := absf(q - fq)
	var dr := absf(r - fr)
	var ds := absf(s - fs)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	return Vector2i(int(q), int(r))


## Winkel von a nach b in Grad (0° = Osten, positiv = im Uhrzeigersinn von oben gesehen)
static func angle(a: Vector2i, b: Vector2i) -> float:
	var dq := float(b.x - a.x)
	var dr := float(b.y - a.y)
	return rad_to_deg(atan2(1.5 * dr, sqrt(3.0) * (dq + dr / 2.0)))


static func dir_angle(d: int) -> float:
	return -60.0 * d


## Hexseite, die am ehesten von a nach b zeigt
static func dir_toward(a: Vector2i, b: Vector2i) -> int:
	return posmod(roundi(-angle(a, b) / 60.0), 6)


## Lage von p relativ zu einer Figur auf pos mit Blickrichtung dir: vorne (≤ 90°), Flanke (≤ 150°), Rücken
static func sector(pos: Vector2i, dir: int, p: Vector2i) -> StringName:
	var d := fmod(absf(angle(pos, p) - dir_angle(dir)), 360.0)
	if d > 180.0:
		d = 360.0 - d
	if d <= 90.0:
		return &"vorne"
	return &"flanke" if d <= 150.0 else &"ruecken"


## Hexfelder auf der Linie a→b inkl. Endpunkte; nudge (+1/−1) macht Linien entlang von Kanten eindeutig
static func line(a: Vector2i, b: Vector2i, nudge := 1) -> Array[Vector2i]:
	var n := distance(a, b)
	var e := 1e-6 * nudge
	var out: Array[Vector2i] = []
	for i in n + 1:
		var t := 0.0 if n == 0 else float(i) / n
		out.append(round_axial(a.x + e + (b.x - a.x) * t, a.y + e + (b.y - a.y) * t))
	return out


## Mittelpunkt in der Welt (x, z) in Metern
static func to_world(a: Vector2i) -> Vector2:
	return Vector2(SIZE_M * (a.x + a.y / 2.0), ROW_M * a.y)


static func from_world(p: Vector2) -> Vector2i:
	var r := p.y / ROW_M
	return round_axial(p.x / SIZE_M - r / 2.0, r)


## Weltrichtung (x, z) einer Blickrichtung
static func dir_vector(d: int) -> Vector2:
	return (to_world(DIRS[posmod(d, 6)]) - to_world(Vector2i.ZERO)).normalized()


## Ecken eines Feldes relativ zur Mitte (x, z), Spitze zeigt nach ±z
static func corners(radius := RADIUS_M) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i in 6:
		var a := deg_to_rad(60.0 * i + 30.0)
		out.append(Vector2(cos(a), sin(a)) * radius)
	return out
