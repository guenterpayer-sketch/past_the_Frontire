class_name StatusRow
extends Node3D
## Reihe farbiger Zustandssymbole mit Zahl über dem Namensschild (feste Bildschirmgröße wie das Schild).
## Höchstens StatusIcons.MAX_SHOWN Symbole, danach „+N“.

const PIXEL := 0.0011     # wie das Namensschild (UnitView._make_label)
const ICON := 32.0        # Symbolgröße in Schild-Einheiten (24 war im Spiel zu klein)
const FONT := 26
const GAP := 6.0

var lift := 34.0          # Abstand nach oben in Schild-Einheiten (negativ = unter dem Punkt)
var _icons: Array[Sprite3D] = []
var _texts: Array[Label3D] = []
var _more: Label3D
var _pulse: Sprite3D       # „sterbend“ pulsiert
var _t := 0.0
var _alpha := 1.0


func _init() -> void:
	for i in StatusIcons.MAX_SHOWN:
		var s := Sprite3D.new()
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.no_depth_test = true
		s.fixed_size = true
		s.pixel_size = PIXEL * ICON / StatusIcons.SIZE
		s.render_priority = 3
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(s)
		_icons.append(s)
		_texts.append(_label())
	_more = _label()
	_more.modulate = Color(0.85, 0.88, 0.93)


func _label() -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = PIXEL
	l.font_size = FONT
	l.outline_size = 8
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.render_priority = 3
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(l)
	return l


## Symbole neu setzen; alpha: Deckkraft (abgedunkelt, wenn eine andere Figur am Zug ist)
func show_for(u: Combatant, alpha: float) -> void:
	_alpha = alpha
	var e := StatusIcons.entries(u)
	var shown := mini(e.size(), StatusIcons.MAX_SHOWN)
	var font := ThemeDB.fallback_font
	# Breite der Reihe bestimmen, dann mittig ausrichten
	var widths: Array[float] = []
	var total := 0.0
	for i in shown:
		var w := ICON
		var t: String = e[i].text
		if t != "":
			w += 2.0 + font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT).x
		widths.append(w)
		total += w + (GAP if i > 0 else 0.0)
	var more := e.size() - shown
	var more_text := "+%d" % more
	if more > 0:
		total += GAP + font.get_string_size(more_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT).x
	var x := -total / 2.0
	_pulse = null
	for i in StatusIcons.MAX_SHOWN:
		var s := _icons[i]
		var l := _texts[i]
		if i >= shown:
			s.visible = false
			l.visible = false
			continue
		var id: StringName = e[i].id
		s.visible = true
		s.texture = StatusIcons.texture(id)
		# Sprite-Versatz in Texturpixeln, Mitte des Symbols
		var k := StatusIcons.SIZE / ICON
		s.offset = Vector2(x + ICON / 2.0, lift) * k
		s.modulate = Color(1, 1, 1, alpha)
		if id == &"dying":
			_pulse = s
		var t: String = e[i].text
		l.visible = t != ""
		l.text = t
		l.offset = Vector2(x + ICON + 2.0, lift)
		l.modulate = Color(StatusIcons.COLORS.get(id, Color.WHITE), alpha)
		x += widths[i] + GAP
	_more.visible = more > 0
	_more.text = more_text
	_more.offset = Vector2(x, lift)
	_more.modulate.a = alpha
	visible = shown > 0


func _process(delta: float) -> void:
	if _pulse and visible:
		_t += delta
		var a := (0.75 + 0.25 * sin(_t * 5.5)) * _alpha
		_pulse.modulate.a = a
		_texts[_icons.find(_pulse)].modulate.a = a
