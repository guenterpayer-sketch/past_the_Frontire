class_name PsiListView
extends Modal
## Übersicht der Psi-Listen (Mockup „Frontire Psi-Listen“): Reiter je Liste, Tabelle der Kräfte mit Stufe, Art,
## Ziel, Wirkung und PP. Mit Figur zusätzlich ihr Rang je Liste und der Stand jeder Kraft
## (verfügbar, nächste, ab Rang N). Gemeinsamer Baustein: Charakter-Modul und Bodenkampf rufen open_for() auf.
## Die Figur darf ein Character oder ein Combatant sein (gelesen werden nur name und skills).

const PSI := Color("b07ae8")
const KIND_COLORS := {PsiLists.ATTACK: UiTheme.BAD, PsiLists.SUPPORT: UiTheme.CREW, PsiLists.OFF: UiTheme.MUTED}

var _ch: Object
var _list: StringName = &"lAngriff"
var _tabs: HBoxContainer
var _body: VBoxContainer


func _ready() -> void:
	max_size = Vector2(1000, 600)
	super()


## Dialog öffnen; ch = Figur (null = nur die Listen), list = Reiter (leer = erste gelernte Liste)
func open_for(ch: Object = null, list: StringName = &"") -> void:
	_ch = ch
	if PsiLists.is_list(list):
		_list = list
	elif ch and not PsiLists.learned(ch).is_empty():
		_list = PsiLists.learned(ch)[0]
	open("Psi-Listen" + (" – %s" % ch.name if ch else ""))
	if ch:
		content.add_child(UiTheme.label("Psi wirken %s · Psi-Angriffe %s · PP %d" % [Dice.fmt(Rules.skill_total(ch, &"psiWirken")),
			Dice.fmt(Rules.skill_total(ch, &"psiAngriff")), _max_pp(ch)], 13, UiTheme.MUTED))
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 6)
	content.add_child(_tabs)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 12))
	content.add_child(card)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	card.add_child(_body)
	for t in ["Rang = höchste Stufe: mit Rang 4 sind alle Kräfte der Stufen 1–4 der Liste verfügbar. Eine Kraft kostet Stufe PP.",
			"Angriff: wie eine Waffe, Aktivität frei wählbar, Probe Psi-Angriffe gegen Psi-VW. Unterstützung: %d %% Aktivität, Probe Psi wirken (Mittel): herausragend = verstärkt, Erfolg = voll, Teilerfolg = schwach, Fehlschlag = nichts, Patzer = Rückkopplung (betäubt 1)." % Combat.COST.psi,
			"Psi-Listen bekommen keine EP durch Benutzung; EP gehen an Psi-Angriffe bzw. Psi wirken."]:
		var l := UiTheme.label(t, 12, UiTheme.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(l)
	add_close()
	_render()


func _max_pp(ch: Object) -> int:
	return ch.max_pp if "max_pp" in ch else Rules.max_pp(ch)


func _rank(id: StringName) -> int:
	return Rules.skill_rank(_ch, id) if _ch else 0


func _render() -> void:
	UiTheme.clear(_tabs)
	for id in PsiLists.LISTS:
		var b := UiTheme.button(PsiLists.LISTS[id].name + (" %d" % _rank(id) if _ch else ""), "", true)
		b.button_pressed = id == _list
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _ch and _rank(id) > 0:
			b.add_theme_color_override("font_color", PSI)
		b.pressed.connect(func() -> void:
			_list = id
			_render())
		_tabs.add_child(b)
	UiTheme.clear(_body)
	var l: Dictionary = PsiLists.LISTS[_list]
	var r := _rank(_list)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.add_child(UiTheme.label(l.name, 17, PSI))
	head.add_child(UiTheme.label("Probe: " + l.probe, 13, UiTheme.MUTED))
	if _ch:
		head.add_child(chip("%s: Rang %d" % [_ch.name, r], UiTheme.GOOD if r > 0 else UiTheme.MUTED))
	_body.add_child(head)
	var g := GridContainer.new()
	g.columns = 7 if _ch else 6
	g.add_theme_constant_override("h_separation", 12)
	g.add_theme_constant_override("v_separation", 6)
	for h in ["Stufe", "Kraft", "Art", "Ziel", "Wirkung", "PP"] + (["Stand"] if _ch else []):
		g.add_child(UiTheme.label(h, 11, UiTheme.MUTED))
	var nxt: Array = PsiLists.next_power(_ch, _list) if _ch else []
	for p in l.powers:
		var kind := PsiLists.kind(_list, p[0])
		var dim: bool = _ch != null and p[0] > r and p != nxt
		var cells: Array[Control] = [
			UiTheme.label(str(p[0]), 13, UiTheme.ACCENT if p == nxt else UiTheme.TEXT),
			UiTheme.label(p[1], 13, UiTheme.TEXT),
			chip(PsiLists.KIND_NAMES[kind], KIND_COLORS[kind]),
			UiTheme.label(PsiLists.target(_list, p[0]), 12, UiTheme.TEXT),
			UiTheme.label(p[2], 12, UiTheme.TEXT),
			UiTheme.label(str(p[0]), 13, UiTheme.TEXT)]
		cells[4].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cells[4].custom_minimum_size.x = 300
		cells[4].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _ch:
			if p[0] <= r:
				cells.append(chip("verfügbar", UiTheme.GOOD))
			elif p == nxt:
				cells.append(chip("nächste · ab Rang %d" % p[0], UiTheme.ACCENT))
			else:
				cells.append(chip("ab Rang %d" % p[0], UiTheme.MUTED))
		for c in cells:
			if dim:
				c.modulate.a = 0.55
			g.add_child(c)
	_body.add_child(g)


## kleines umrandetes Etikett
static func chip(text: String, color: Color) -> Control:
	var p := PanelContainer.new()
	var c := color
	c.a = 0.5
	p.add_theme_stylebox_override("panel", UiTheme.box(Color(0, 0, 0, 0), c, 9, 2))
	p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.add_child(UiTheme.label(text, 11, color))
	return p


## Was der nächste Rang bringt (Charakterübersicht, Aufleveln)
static func next_hint(ch: Object, id: StringName) -> String:
	var r := Rules.skill_rank(ch, id)
	var nxt := PsiLists.next_power(ch, id)
	if nxt.is_empty():
		return "alle Kräfte verfügbar"
	var t := _power_text(id, nxt)
	if nxt[0] == r + 1:
		return "Rang %d: %s" % [nxt[0], t]
	return "Rang %d: keine neue Kraft · Rang %d: %s" % [r + 1, nxt[0], t]


## Was die Liste bringt (Charakter-Editor): verfügbare Kräfte und die nächste; ungelernt die ersten drei mit Rang
static func preview_hint(ch: Object, id: StringName) -> String:
	var r := Rules.skill_rank(ch, id)
	var powers: Array = PsiLists.LISTS[id].powers
	if r == 0:
		var parts: Array[String] = []
		for i in mini(3, powers.size()):
			parts.append("Rang %d: %s" % [powers[i][0], powers[i][1]])
		return " · ".join(parts) + (" …" if powers.size() > 3 else "")
	var have: Array[String] = []
	for p in PsiLists.powers(ch, id):
		have.append(p[1])
	var nxt := PsiLists.next_power(ch, id)
	return "verfügbar: %s%s" % [", ".join(have), (" · Rang %d: %s" % [nxt[0], nxt[1]]) if not nxt.is_empty() else ""]


static func _power_text(id: StringName, p: Array) -> String:
	if PsiLists.kind(id, p[0]) == PsiLists.OFF:
		return "%s (nicht im Kampf)" % p[1]
	return "%s (%s)" % [p[1], p[2]]
