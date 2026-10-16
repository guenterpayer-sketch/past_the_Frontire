class_name Encyclopedia
extends Modal
## Enzyklopädie (docs/Planung_Enzyklopaedie.md): ein Dialog für alle Module. Links Suche und Bereiche, in der Mitte die
## Einträge, rechts der Text. Verweise im Text sind anklickbar ([url=bereich:eintrag]).
## Öffnen: Encyclopedia.show_on(control, &"waffen", "Sturmgewehr") – legt den Dialog bei Bedarf unter control an.
## Bereiche: waffen, ruestungen, tabellen, kritische, patzer, psi, fertigkeiten, regeln.

const SECTIONS := [
	[&"waffen", "Waffen"], [&"ruestungen", "Rüstungen"], [&"tabellen", "Angriffstabellen"], [&"kritische", "Kritische Treffer"],
	[&"patzer", "Patzer"], [&"psi", "Psi-Listen"], [&"fertigkeiten", "Fertigkeiten"], [&"regeln", "Kurzregeln"],
]
## Kurzregeln: Eintrag → Überschrift-Anfang in docs/Skillsystem.md
const RULES := [
	["Der offene W100", "## 1."], ["Proben", "## 4."], ["Angriff", "### 5.1"], ["Kritische Treffer (Regel)", "### 5.3"],
	["Reichweite und Deckung", "### 5.4"], ["Aktivität und Runde", "## 7."], ["Ducken, Abwarten, Feuerbereitschaft", "### 7.2"],
	["Steigerung und Erfahrung", "## 8."], ["Verwundung und Heilung", "## 8a."], ["Reise, Schiff, Credits", "## 8b."],
]
const RULES_FILE := "../docs/Skillsystem.md"
const NAME := "Encyclopedia"
const LINK := "#5db7ff"
const MUTED := "#8291ad"

var section: StringName = &"waffen"
var entry := ""
var query := ""
var _side: VBoxContainer
var _list: VBoxContainer
var _text: RichTextLabel
var _search: LineEdit
var _cache := {}             # Bereich → [{name, text}]
static var _rules_md := ""


## Dialog unter parent (einmal angelegt) an der Stelle öffnen
static func show_on(parent: Node, sec: StringName = &"", item := "") -> Encyclopedia:
	var e := parent.get_node_or_null(NAME) as Encyclopedia
	if e == null:
		e = Encyclopedia.new()
		e.name = NAME
		parent.add_child(e)
	e.show_at(sec, item)
	return e


func _ready() -> void:
	super._ready()
	max_size = Vector2(1460, 860)


func show_at(sec: StringName = &"", item := "") -> void:
	_cache.clear()
	if sec != &"":
		section = sec
	entry = item
	query = ""
	open("Enzyklopädie")
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	content.add_child(cols)
	_side = VBoxContainer.new()
	_side.custom_minimum_size.x = 230
	_side.add_theme_constant_override("separation", 4)
	cols.add_child(_side)
	_list = VBoxContainer.new()
	_list.custom_minimum_size.x = 240
	_list.add_theme_constant_override("separation", 2)
	cols.add_child(_list)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 15)
	_text.add_theme_font_size_override("bold_font_size", 15)
	_text.meta_clicked.connect(_on_link)
	cols.add_child(_text)
	add_close()
	_render_side()
	_render()
	move_to_front()


# ---------------------------------------------------------------- Aufbau

func _render_side() -> void:
	UiTheme.clear(_side)
	_side.add_child(UiTheme.label("Suche", 12, UiTheme.MUTED))
	_search = LineEdit.new()
	_search.placeholder_text = "z. B. Deckung, Psi-Stoß"
	_search.custom_minimum_size.y = 38
	_search.text = query
	_search.text_changed.connect(func(t: String) -> void:
		query = t.strip_edges()
		_render())
	_side.add_child(_search)
	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	_side.add_child(gap)
	for s in SECTIONS:
		var b := UiTheme.button("%s   (%d)" % [s[1], entries(s[0]).size()], "", true)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.button_pressed = s[0] == section and query == ""
		b.custom_minimum_size.y = 40
		var id: StringName = s[0]
		b.pressed.connect(func() -> void:
			section = id
			entry = ""
			query = ""
			_render_side()
			_render())
		_side.add_child(b)


func _render() -> void:
	UiTheme.clear(_list)
	if query != "":
		_render_search()
		return
	var list := entries(section)
	if entry == "" or not list.any(func(e: Dictionary) -> bool: return e.name == entry):
		entry = list[0].name if not list.is_empty() else ""
	for e in list:
		if e.get("head", false):
			_list.add_child(UiTheme.label(e.name, 12, UiTheme.MUTED))
			continue
		_list.add_child(_entry_button(section, e.name, e.name))
	var cur: Array = list.filter(func(e: Dictionary) -> bool: return e.name == entry)
	_text.text = String(cur[0].text) if not cur.is_empty() else ""


func _entry_button(sec: StringName, item: String, label: String) -> Button:
	var b := Button.new()
	b.text = label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.flat = not (sec == section and item == entry and query == "")
	b.add_theme_font_size_override("font_size", 14)
	if sec == section and item == entry:
		b.add_theme_color_override("font_color", UiTheme.ACCENT)
	b.pressed.connect(func() -> void:
		section = sec
		entry = item
		query = ""
		_search.text = ""
		_render_side()
		_render())
	return b


## Suche in Namen und Texten aller Bereiche
func _render_search() -> void:
	var q := query.to_lower()
	var hits := 0
	for s in SECTIONS:
		for e in entries(s[0]):
			if e.get("head", false):
				continue
			if String(e.name).to_lower().contains(q) or _plain(String(e.text)).to_lower().contains(q):
				_list.add_child(_entry_button(s[0], e.name, "%s › %s" % [s[1], e.name]))
				hits += 1
	_text.text = "[color=%s]%d Treffer für „%s“. Eintrag links anklicken.[/color]" % [MUTED, hits, query]


func _on_link(meta: Variant) -> void:
	var p := String(meta).split(":", true, 1)
	if p.size() == 2:
		section = StringName(p[0])
		entry = p[1]
		query = ""
		_search.text = ""
		_render_side()
		_render()


static func _plain(bb: String) -> String:
	var r := RegEx.new()
	r.compile("\\[[^\\]]*\\]")
	return r.sub(bb, "", true)


static func _link(sec: String, item: String, label := "") -> String:
	return "[url=%s:%s][color=%s][u]%s[/u][/color][/url]" % [sec, item, LINK, label if label != "" else item]


# ---------------------------------------------------------------- Inhalte

## Einträge eines Bereichs: [{name, text (BBCode), head (Zwischenüberschrift)}]
func entries(sec: StringName) -> Array:
	if not _cache.has(sec):
		_cache[sec] = _build(sec)
	return _cache[sec]


func _build(sec: StringName) -> Array:
	var out := []
	match sec:
		&"waffen":
			for w in Gear.base_weapons():
				out.append({"name": w.name, "text": weapon_text(w)})
			var own := Gear.weapons()
			if not own.is_empty():
				out.append({"name": "— eigene —", "head": true, "text": ""})
			for w in own:
				out.append({"name": w.name + ("  [frei]" if Gear.is_free(w) else ""), "text": weapon_text(w)})
		&"ruestungen":
			for a in Gear.base_armors() + Gear.armors():
				out.append({"name": a.name + ("  [frei]" if Gear.is_free(a) else ""), "text": armor_text(a)})
		&"tabellen":
			for t in Gear.tables():
				out.append({"name": t.name, "text": table_text(t)})
		&"kritische":
			for t in GameData.crit_tables():
				out.append({"name": t.name, "text": crit_text(t)})
		&"patzer":
			out.append({"name": "Patzer (W100)", "text": fumble_text()})
		&"psi":
			for id in PsiLists.LISTS:
				out.append({"name": PsiLists.LISTS[id].name, "text": psi_text(id)})
		&"fertigkeiten":
			for g in Rules.SKILL_GROUPS:
				out.append({"name": g.name, "head": true, "text": ""})
				for s in g.skills:
					out.append({"name": s[1], "text": skill_text(g, s)})
		&"regeln":
			for r in RULES:
				out.append({"name": r[0], "text": rule_text(r[1])})
	return out


static func weapon_text(w: WeaponData) -> String:
	var rows := [["Fertigkeit", Rules.skill_name(w.skill)]]
	if w.table:
		rows.append(["Angriffstabelle", "%s (Kritische: %s)" % [_link("tabellen", w.table.name),
			_link("kritische", w.table.crit.name) if w.table.crit else "–"]])
	rows.append(["Art", "Nahkampf (benachbart)" if w.melee else "Reichweite %d m je Stufe, %d Stufen (max. %d m)%s" % [
		w.inc_m, w.stages, w.max_range_m(), (", Mindestabstand %d m" % w.min_range_m) if w.min_range_m else ""]])
	rows.append(["Höchstergebnis", str(w.max_result)])
	rows.append(["Patzer", "01–%02d (%s)" % [w.fumble, _link("patzer", "Patzer (W100)", "Tabelle")]])
	rows.append(["Schaden", "×%s" % str(w.damage).replace(".", ",")])
	if w.ob_bonus:
		rows.append(["Angriffsbonus", Dice.fmt(w.ob_bonus)])
	if w.magazine > 0:
		rows.append(["Munition", "%s · Magazin %d · Munition gesamt %s · Schuss pro Angriff %d" % [
			Ammo.TYPES.get(w.ammo_type, "–"), w.magazine, str(w.ammo_total) if w.ammo_total > 0 else "3 Magazine", maxi(1, w.shots)]])
	elif not w.melee:
		rows.append(["Munition", "braucht keine"])
	if not w.splash.is_empty():
		rows.append(["Druckwelle", ", ".join(Array(w.splash).map(func(v: int) -> String: return Dice.fmt(v))) + " (1,5 m, 3 m)"])
	rows.append(["Hände", "zweihändig" if w.two_handed else "einhändig"])
	if Gear.is_custom(w):
		rows.append(["Herkunft", "eigene Ausrüstung%s" % (" · frei eingetragen" if Gear.is_free(w) else "")])
	var s := "[font_size=24][b]%s[/b][/font_size]\n\n[table=2]" % w.name
	for r in rows:
		s += "[cell][color=%s]%s[/color]   [/cell][cell]%s[/cell]" % [MUTED, r[0], r[1]]
	s += "[/table]\n\n"
	if w.table:
		s += "[color=%s]ANGRIFFSTABELLE (TP und Kritischer Grad je Rüstungsklasse; * = auf das Höchstergebnis begrenzt)[/color]\n" % MUTED
		s += attack_grid(w.table, w.max_result, w.damage)
	return s


static func attack_grid(t: AttackTableData, max_result: int, damage: float) -> String:
	var s := "[table=5][cell][b]Ergebnis[/b]   [/cell]"
	for a in Tables.ARMOR_CLASSES:
		s += "[cell][b]%s[/b]   [/cell]" % a
	for total in range(50, 160, 5):
		var over := total > max_result
		s += "[cell]%s%d%s[/cell]" % ["[color=#66708a]" if over else "", total, "*[/color]" if over else ""]
		for cls in 4:
			var r := Tables.lookup_attack(t, mini(total, max_result), cls, damage)
			s += "[cell]%s[/cell]" % (("%d%s" % [r.dmg, (" " + r.severity) if r.severity else ""]) if r.hit else "–")
	return s + "[/table]"


static func armor_text(a: ArmorData) -> String:
	var s := "[font_size=24][b]%s[/b][/font_size]\n\n[table=2]" % a.name
	for r in [["Klasse", "%d (%s)" % [a.cls, Tables.ARMOR_CLASSES[a.cls]]], ["Verteidigung", Dice.fmt(a.db)], ["Bewegung", Dice.fmt(a.move)],
			["Schaden", "×%s (erlittener Schaden)" % str(Equipment.damage_taken(a)).replace(".", ",")]]:
		s += "[cell][color=%s]%s[/color]   [/cell][cell]%s[/cell]" % [MUTED, r[0], r[1]]
	s += "[/table]"
	if Gear.is_custom(a):
		s += "\n\n[color=%s]Eigene Ausrüstung%s[/color]" % [MUTED, " · frei eingetragen" if Gear.is_free(a) else ""]
	return s


static func table_text(t: AttackTableData) -> String:
	return "[font_size=24][b]Angriffstabelle %s[/b][/font_size]\n\n[color=%s]Grundtabelle ohne Waffe (Schaden ×1, Höchstergebnis 150). Kritische: %s.[/color]\n\n%s" % [
		t.name, MUTED, _link("kritische", t.crit.name) if t.crit else "–", attack_grid(t, 150, 1.0)]


static func crit_text(t: CritTableData) -> String:
	var s := "[font_size=24][b]Kritische Treffer: %s[/b][/font_size]\n\n[color=%s]W100 (geschlossen) + Grad: A −20, B −10, C ±0, D +10, E +20[/color]\n\n[table=2]" % [t.name, MUTED]
	for i in t.rows.size():
		var r: CritRowData = t.rows[i]
		s += "[cell][color=%s]%s[/color]   [/cell][cell]%s\n[color=%s][font_size=12]%s[/font_size][/color][/cell]" % [
			MUTED, Tables.CRIT_BAND_NAMES[i], r.text, MUTED, ", ".join(r.effects())]
	return s + "[/table]"


static func fumble_text() -> String:
	var s := "[font_size=24][b]Patzer (W100)[/b][/font_size]\n\n[color=%s]Liegt der unmodifizierte erste Wurf im Patzerbereich der Waffe, entfällt der Angriff und es wird hier gewürfelt.[/color]\n\n[table=2]" % MUTED
	var prev := 0
	for r in GameData.fumble_table().rows:
		s += "[cell]%d–%d   [/cell][cell]%s[/cell]" % [prev + 1, r.up_to, r.text]
		prev = r.up_to
	return s + "[/table]"


static func psi_text(id: StringName) -> String:
	var l: Dictionary = PsiLists.LISTS[id]
	var s := "[font_size=24][b]Psi-Liste: %s[/b][/font_size]\n\n[color=%s]Probe: %s · Rang = höchste verfügbare Stufe · eine Kraft kostet Stufe PP[/color]\n\n[table=5]" % [l.name, MUTED, l.probe]
	for h in ["Stufe (PP)", "Kraft", "Art", "Ziel", "Wirkung"]:
		s += "[cell][color=%s]%s[/color]   [/cell]" % [MUTED, h]
	for p in l.powers:
		var lv: int = p[0]
		s += "[cell][color=#ffd34d]%d[/color][/cell][cell][b]%s[/b]   [/cell][cell]%s   [/cell][cell]%s   [/cell][cell]%s[/cell]" % [
			lv, p[1], PsiLists.KIND_NAMES.get(PsiLists.kind(id, lv), ""), PsiLists.target(id, lv), p[2]]
	return s + "[/table]"


static func skill_text(g: Dictionary, s: Array) -> String:
	var id := StringName(s[0])
	var t := "[font_size=24][b]%s[/b][/font_size]\n\n[color=%s]Gruppe: %s · Eigenschaften: %s und %s[/color]\n\n%s" % [
		s[1], MUTED, g.name, Rules.attr_short(s[2]), Rules.attr_short(s[3]), SkillTexts.text(id)]
	if PsiLists.is_list(id):
		t += "\n\n" + _link("psi", PsiLists.LISTS[id].name, "Kräfte der Liste " + PsiLists.LISTS[id].name)
	return t


# ---------------------------------------------------------------- Kurzregeln aus docs/Skillsystem.md

## Text eines Abschnitts (bis zur nächsten Überschrift gleicher oder höherer Ebene) als BBCode
static func rule_text(head: String) -> String:
	var md := _rules()
	if md == "":
		return "[color=%s]docs/Skillsystem.md nicht gefunden (die Kurzregeln werden aus dem Regeldokument im Projektordner gelesen).[/color]" % MUTED
	var lines := md.split("\n")
	var level := head.split(" ")[0].length()
	var out := PackedStringArray()
	var on := false
	for ln in lines:
		if ln.begins_with("#"):
			var lv := ln.split(" ")[0].length()
			if on and lv <= level:
				break
			if ln.begins_with(head):
				on = true
		if on:
			out.append(ln)
	return md_to_bb("\n".join(out))


static func _rules() -> String:
	if _rules_md == "":
		var p := ProjectSettings.globalize_path("res://").path_join(RULES_FILE)
		if FileAccess.file_exists(p):
			_rules_md = FileAccess.get_file_as_string(p)
	return _rules_md


## Einfaches Markdown → BBCode (Überschriften, fett, kursiv, Code, Listen, Tabellen)
static func md_to_bb(md: String) -> String:
	var out := PackedStringArray()
	var table := []
	for ln in md.split("\n"):
		if ln.begins_with("|"):
			if ln.replace("|", "").replace("-", "").replace(":", "").strip_edges() == "":
				continue
			table.append(ln.strip_edges().trim_prefix("|").trim_suffix("|").split("|"))
			continue
		if not table.is_empty():
			out.append(_bb_table(table))
			table = []
		var l := ln
		if l.begins_with("#"):
			var t := l.lstrip("#").strip_edges()
			l = "[font_size=%d][b]%s[/b][/font_size]" % [24 if l.begins_with("## ") else 18, t]
		elif l.strip_edges().begins_with("- "):
			l = l.replace("- ", "• ")
		elif l.strip_edges() == "---":
			continue
		out.append(_inline(l))
	if not table.is_empty():
		out.append(_bb_table(table))
	return "\n".join(out)


static func _bb_table(rows: Array) -> String:
	var n: int = rows[0].size()
	var s := "[table=%d]" % n
	for i in rows.size():
		for c in n:
			var v: String = _inline(String(rows[i][c]).strip_edges()) if c < rows[i].size() else ""
			s += "[cell]%s%s%s   [/cell]" % ["[b]" if i == 0 else "", v, "[/b]" if i == 0 else ""]
	return s + "[/table]"


static func _inline(s: String) -> String:
	var r := RegEx.new()
	r.compile("\\*\\*(.+?)\\*\\*")
	s = r.sub(s, "[b]$1[/b]", true)
	r.compile("(?<![\\*\\w])\\*(?!\\s)(.+?)\\*")
	s = r.sub(s, "[i]$1[/i]", true)
	r.compile("`([^`]+)`")
	s = r.sub(s, "[code]$1[/code]", true)
	return s
