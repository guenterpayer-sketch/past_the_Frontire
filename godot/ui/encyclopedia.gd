class_name Encyclopedia
extends Modal
## Enzyklopädie (docs/archiv/Planung_Enzyklopaedie.md): ein Dialog für alle Module. Links Suche und Bereiche, in der Mitte die
## Einträge, rechts der Text. Verweise im Text sind anklickbar ([url=bereich:eintrag]).
## Öffnen: Encyclopedia.show_on(control, &"waffen", "Sturmgewehr") – legt den Dialog bei Bedarf unter control an.
## Bereiche Bodenkampf: waffen, ruestungen, tabellen, kritische, patzer, psi, fertigkeiten, regeln.
## Bereiche Raumkampf (Entscheidungen des Nutzers 19.10.2026, Daten nur gelesen aus ShipWeapons, SpaceTemplates,
## SpaceSetup, ShipUpgrades, ShipArms, docs/Raumkampf.md): s_waffen, s_schiffe, s_seiten, s_ausbau, s_munition,
## s_stationen, s_regeln. Leiste mit zwei Gruppen, Werte als Einzelseiten mit „Übersicht“ als Vergleichstabelle.
## Hub Auftrag 5 (Entscheidungen des Nutzers 19.10.2026): fraktionen, gegner (Bodenkampf, Daten aus data/missions und
## data/units/enemies), Gruppe REISE mit orte (Places) und sektoren (Sector, Sprungtore, Papiere, Häfen).

const SECTIONS := [
	[&"waffen", "Waffen"], [&"ruestungen", "Rüstungen"], [&"tabellen", "Angriffstabellen"], [&"kritische", "Kritische Treffer"],
	[&"patzer", "Patzer"], [&"psi", "Psi-Listen"], [&"fertigkeiten", "Fertigkeiten"], [&"fraktionen", "Fraktionen"],
	[&"gegner", "Gegnertypen"], [&"regeln", "Kurzregeln"],
	[&"s_waffen", "Schiffswaffen"], [&"s_schiffe", "Gegnerschiffe"], [&"s_seiten", "Gegnerseiten"], [&"s_ausbau", "Schiffsausbau"],
	[&"s_munition", "Schiffsmunition"], [&"s_stationen", "Stationen"], [&"s_regeln", "Kurzregeln Raumkampf"],
	[&"orte", "Orte"], [&"sektoren", "Sektoren und Tore"],
]
## Zwischenüberschriften der Leiste: vor diesem Bereich beginnt die Gruppe
const GROUPS := {&"waffen": "BODENKAMPF", &"s_waffen": "RAUMKAMPF", &"orte": "REISE"}
## Kurzregeln Raumkampf: Eintrag → Überschrift-Anfang in docs/Raumkampf.md (ohne „Offene Fragen“)
const SPACE_RULES := [
	["Karte und Ablauf", "## 1."], ["Stationen (Regel)", "## 2."], ["Jäger", "## 3."], ["Treffer und Schaden", "## 4."],
	["Waffen, Schilde, Munition", "## 4a."], ["Kampfende", "## 4b."], ["Entern", "## 4c."], ["Erfahrung im Raumkampf", "## 5."],
]
const SPACE_RULES_FILE := "../docs/Raumkampf.md"
const OVERVIEW := "Übersicht"
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
static var _rules_md := {}       # Datei → Markdown


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
	_side.add_theme_constant_override("separation", 2)
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
	# drei Gruppen in der Leiste: knapp gesetzt, damit alle Bereiche ohne Scrollen sichtbar sind (Hub Auftrag 5)
	_search = LineEdit.new()
	_search.placeholder_text = "Suche, z. B. Deckung"
	_search.custom_minimum_size.y = 38
	_search.text = query
	_search.text_changed.connect(func(t: String) -> void:
		query = t.strip_edges()
		_render())
	_side.add_child(_search)
	for s in SECTIONS:
		if GROUPS.has(s[0]):
			_side.add_child(UiTheme.label(GROUPS[s[0]], 12, UiTheme.MUTED))
		var n := entries(s[0]).filter(func(e: Dictionary) -> bool: return not e.get("head", false) and e.name != OVERVIEW).size()
		var b := UiTheme.button("%s   (%d)" % [s[1], n], "", true)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.button_pressed = s[0] == section and query == ""
		b.custom_minimum_size.y = 28
		b.add_theme_font_size_override("font_size", 15)
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
			var elite := elite_seen(Gear.WEAPON_DIR)
			if not elite.is_empty():
				out.append({"name": "— erbeutet (Elite) —", "head": true, "text": ""})
			for w in elite:
				out.append({"name": w.name, "text": weapon_text(w)})
			var own := Gear.weapons()
			if not own.is_empty():
				out.append({"name": "— eigene —", "head": true, "text": ""})
			for w in own:
				out.append({"name": w.name + ("  [frei]" if Gear.is_free(w) else ""), "text": weapon_text(w)})
		&"ruestungen":
			for a in Gear.base_armors() + Gear.armors():
				out.append({"name": a.name + ("  [frei]" if Gear.is_free(a) else ""), "text": armor_text(a)})
			var elite := elite_seen(Gear.ARMOR_DIR)
			if not elite.is_empty():
				out.append({"name": "— erbeutet (Elite) —", "head": true, "text": ""})
			for a in elite:
				out.append({"name": a.name, "text": armor_text(a)})
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
		&"s_regeln":
			for r in SPACE_RULES:
				out.append({"name": r[0], "text": rule_text(r[1], SPACE_RULES_FILE)})
		&"fraktionen", &"gegner", &"orte", &"sektoren":
			out = world_entries(sec)
		_:
			out = space_entries(sec)
	return out


## Elite-/Boss-Stücke aus <dir>/elite, die im laufenden Spiel schon erbeutet wurden (HubState.elite_seen), nach Namen
static func elite_seen(dir: String) -> Array:
	var out := []
	var g := HubState.game
	if g == null:
		return out
	var d := dir.path_join("elite")
	for f in ResourceLoader.list_directory(d):
		if f.ends_with(".tres") and d.path_join(f) in g.elite_seen:
			out.append(load(d.path_join(f)))
	out.sort_custom(func(a: Resource, b: Resource) -> bool: return String(a.name) < String(b.name))
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
static func rule_text(head: String, file := RULES_FILE) -> String:
	var md := _rules(file)
	if md == "":
		return "[color=%s]%s nicht gefunden (die Kurzregeln werden aus dem Regeldokument im Projektordner gelesen).[/color]" % [MUTED, file.trim_prefix("../")]
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


static func _rules(file := RULES_FILE) -> String:
	if String(_rules_md.get(file, "")) == "":
		var p := ProjectSettings.globalize_path("res://").path_join(file)
		if FileAccess.file_exists(p):
			_rules_md[file] = FileAccess.get_file_as_string(p)
	return String(_rules_md.get(file, ""))


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


# ---------------------------------------------------------------- Raumkampf (nur lesen)

const SHIP_CLASSES := ["Jäger", "leicht", "mittel", "schwer"]
const DIFF_NAMES := {"leicht": "Leicht", "mittel": "Mittel", "schwer": "Schwer"}


## Einträge der Raumkampf-Bereiche (außer Kurzregeln)
static func space_entries(sec: StringName) -> Array:
	var out := []
	match sec:
		&"s_waffen":
			out.append({"name": OVERVIEW, "text": ship_weapons_overview()})
			for k in ShipWeapons.CATALOG:
				out.append({"name": ShipWeapons.name(k), "text": ship_weapon_text(k)})
		&"s_schiffe":
			var ships := SpaceTemplates.ships()
			out.append({"name": OVERVIEW, "text": enemy_ships_overview()})
			for id in ships:
				out.append({"name": String(ships[id].name), "text": enemy_ship_text(id)})
		&"s_seiten":
			var sides := SpaceTemplates.factions()
			for id in sides:
				out.append({"name": String(sides[id].name), "text": side_text(id)})
			out.append({"name": "Standardaufstellungen", "text": "[font_size=24][b]Standardaufstellungen[/b][/font_size]\n\n"
				+ "[color=%s]Für Gegnerseiten ohne eigene Aufstellungen; je Kampf wird eine Zeile der Schwierigkeit gewürfelt.[/color]\n\n" % MUTED
				+ _groups_table(SpaceTemplates.DEFAULT_GROUPS)})
		&"s_ausbau":
			out.append({"name": "Frontire (Grundwerte)", "text": own_ship_text()})
			for id in [&"shields", &"armor", &"reactor", &"slots"]:
				out.append({"name": String(ShipUpgrades.AREAS[id].name), "text": upgrade_text(id)})
		&"s_munition":
			for t in ShipWeapons.AMMO_TYPES:
				out.append({"name": String(ShipWeapons.AMMO_TYPES[t]), "text": ship_ammo_text(t)})
			out.append({"name": "Energie", "text": energy_text()})
		&"s_stationen":
			for st in SpaceSetup.BASE_STATIONS:
				out.append({"name": SpaceSetup.station_name(st), "text": station_text(SpaceSetup.station_name(st), SpaceSetup.STATION_SKILL.get(st, &""))})
			out.append({"name": "Geschütze", "text": station_text("Geschütze", &"", "Geschütze")})
			out.append({"name": "Punktverteidigung", "text": station_text("Punktverteidigung", &"", "Punktverteidigung")})
			out.append({"name": "Technik 2 und 3", "text": station_text("Technik 2 und 3", &"", "Technik")})
			out.append({"name": "Freie Stationen", "text": free_stations_text()})
	return out


static func _num(v: float) -> String:
	return str(v).replace(".", ",")


static func _page(title: String, rows: Array, tail := "") -> String:
	var s := "[font_size=24][b]%s[/b][/font_size]\n\n[table=2]" % title
	for r in rows:
		s += "[cell][color=%s]%s[/color]   [/cell][cell]%s[/cell]" % [MUTED, r[0], r[1]]
	return s + "[/table]\n" + (("\n" + tail) if tail != "" else "")


## Tabelle mit Kopfzeile (Übersichten)
static func _grid(head: Array, rows: Array) -> String:
	var s := "[table=%d]" % head.size()
	for h in head:
		s += "[cell][b]%s[/b]   [/cell]" % h
	for r in rows:
		for v in r:
			s += "[cell]%s   [/cell]" % v
	return s + "[/table]"


static func _weapon_use(w: Dictionary) -> String:
	return "%d Energie je Schuss" % int(w.energy) if String(w.ammo) == "" else _link("s_munition", String(ShipWeapons.AMMO_TYPES[w.ammo]))


static func ship_weapons_overview() -> String:
	var rows := []
	for k in ShipWeapons.CATALOG:
		var w: Dictionary = ShipWeapons.CATALOG[k]
		rows.append([_link("s_waffen", String(w.name)), ShipWeapons.ART_NAMES[w.art], "Turm" if w.slot == "turm" else "normal",
			_weapon_use(w), str(w.shots), str(w.range), "×" + _num(w.dmg), Dice.fmt(int(w.mod)),
			("%d Cr" % int(w.price)) if w.trade else "nur Gegner"])
	return "[font_size=24][b]Schiffswaffen[/b][/font_size]\n\n" + _grid(["Waffe", "Art", "Slot", "Munition", "Schuss", "Reichw.", "Schaden", "Bonus", "Preis"], rows) \
		+ "\n\n[color=%s]Reichweite in Feldern, darüber −10 je Feld. Schaden = Faktor auf den Treffer. Preise: Grundpreis, im Hafen nach Verhandeln.[/color]" % MUTED


static func ship_weapon_text(k: String) -> String:
	var w := ShipWeapons.data(k)
	var used := []
	var ships := SpaceTemplates.ships()
	for id in ships:
		if k in ships[id].weapons:
			used.append(_link("s_schiffe", String(ships[id].name)))
	var rows := [["Art", ShipWeapons.ART_NAMES[w.art]], ["Fertigkeit", Rules.skill_name(ShipWeapons.skill(k))],
		["Slot", "nur Turm-Slots (Punktverteidigung)" if w.slot == "turm" else "alle Slots außer Turm"], ["Munition", _weapon_use(w)],
		["Schüsse je Runde", str(w.shots)], ["Reichweite", "%d Felder (darüber −10 je Feld)" % int(w.range)],
		["Schaden", "×" + _num(w.dmg)], ["Angriffsbonus", Dice.fmt(int(w.mod))],
		["Preis", ("%d Cr (Grundpreis, im Hafen nach Verhandeln)" % int(w.price)) if w.trade else "kein Handel, nur bei Gegnern"],
		["Bei Gegnern", ", ".join(used) if not used.is_empty() else "–"]]
	return _page(String(w.name), rows)


static func _weapons_links(list: Array) -> String:
	return ", ".join(list.map(func(k) -> String: return _link("s_waffen", ShipWeapons.name(String(k))))) if not list.is_empty() else "–"


static func enemy_ships_overview() -> String:
	var rows := []
	var ships := SpaceTemplates.ships()
	for id in ships:
		var t: Dictionary = ships[id]
		rows.append([_link("s_schiffe", String(t.name)), SHIP_CLASSES[int(t.cls)], str(t.hull), "%d / %d" % [int(t.shield), int(t.recharge)],
			str(t.armor), str(t.vw), "%d (max. %d)" % [int(t.speed), int(t.max_speed)], _weapons_links(t.weapons), Dice.fmt(int(t.skill)),
			"%d Cr, %d Mat." % [int(t.credits), int(t.material)]])
	return "[font_size=24][b]Gegnerschiffe[/b][/font_size]\n\n" + _grid(["Schiff", "Klasse", "Hülle", "Schild/Aufl.", "Panz.", "VW", "Tempo",
		"Waffen", "Besatz.", "Beute"], rows)


static func enemy_ship_text(id: String) -> String:
	var t := SpaceTemplates.ship(id)
	var where := []
	var sides := SpaceTemplates.factions()
	for f in sides:
		var groups: Dictionary = sides[f].get("groups", SpaceTemplates.DEFAULT_GROUPS)
		for d in groups:
			if groups[d].any(func(g: Array) -> bool: return id in g):
				where.append(_link("s_seiten", String(sides[f].name)))
				break
	var rows := [["Klasse", SHIP_CLASSES[int(t.cls)]], ["Hülle", str(t.hull)],
		["Schild", "%d je Seite, Aufladung %d je Seite und Runde" % [int(t.shield), int(t.recharge)]],
		["Panzerung", "%d Abzug je Treffer auf die Hülle" % int(t.armor)], ["Verteidigung", "VW %d + halbe Besatzung" % int(t.vw)],
		["Tempo", "%d, höchstens %d · %d %s je Runde" % [int(t.speed), int(t.max_speed), int(t.turns), "Drehung" if int(t.turns) == 1 else "Drehungen"]],
		["Waffen", _weapons_links(t.weapons)], ["Besatzung", "%s auf Geschütze, Pilot, Schilde · Initiative %d" % [Dice.fmt(int(t.skill)), int(t.init)]],
		["Beute", "%d Cr (×0,6–1,0), %d Schiffsmaterial" % [int(t.credits), int(t.material)]],
		["Kommt vor bei", ", ".join(where) if not where.is_empty() else "–"]]
	return _page(String(t.name), rows)


static func _groups_table(groups: Dictionary) -> String:
	var rows := []
	for d in SpaceTemplates.DIFFS:
		for g in groups.get(d, []):
			rows.append([DIFF_NAMES[d], ", ".join(g.map(func(s) -> String: return _link("s_schiffe", String(SpaceTemplates.ship(String(s)).get("name", s)))))])
	return _grid(["Schwierigkeit", "Aufstellung"], rows)


static func side_text(id: String) -> String:
	var f := SpaceTemplates.faction(id)
	var rows := [["Gewinnt die Seite", "entert die Frontire (Bodenkampf an Bord)" if f.on_win == "entern" else "zieht ab (Notfall: Plünderung, Schiff treibt)"],
		["Lösegeld", ("%d Cr bei Kapitulation" % int(f.ransom)) if int(f.ransom) > 0 else "nimmt keins"],
		["Fluchtgrenze", ("Schiffe drehen unter %d %% Hülle ab (Jäger nie)" % roundi(float(f.flee_at) * 100)) if float(f.flee_at) > 0 else "flieht nie"]]
	var groups: Dictionary = f.get("groups", {})
	var tail := "[color=%s]AUFSTELLUNGEN%s[/color]\n" % [MUTED, "" if not groups.is_empty() else " (Standard)"]
	return _page(String(f.name), rows, tail + _groups_table(groups if not groups.is_empty() else SpaceTemplates.DEFAULT_GROUPS))


static func own_ship_text() -> String:
	var rows := [["Klasse", SHIP_CLASSES[SpaceSetup.OWN_CLASS]], ["Verteidigung", "VW %d + halber Pilot-Bonus" % SpaceSetup.OWN_VW],
		["Tempo", "höchstens %d · %d Drehung je Runde" % [SpaceSetup.OWN_MAX_SPEED, SpaceSetup.OWN_TURNS]],
		["Startslots", ", ".join(SpaceSetup.START_SLOTS.keys().map(func(s) -> String: return "%s: %s" % [SpaceSetup.SLOT_NAMES[s], _link("s_waffen", ShipWeapons.name(String(SpaceSetup.START_SLOTS[s])))]))],
		["Startmunition", ", ".join(SpaceSetup.START_AMMO.keys().map(func(t) -> String: return "%d %s" % [int(SpaceSetup.START_AMMO[t]), ShipWeapons.AMMO_TYPES[t]]))],
		["Ausbau", ", ".join([&"shields", &"armor", &"reactor", &"slots"].map(func(id) -> String: return _link("s_ausbau", String(ShipUpgrades.AREAS[id].name))))]]
	return _page("Frontire (Grundwerte)", rows)


## Ausbau-Stufen mit Wirkung im Raumkampf und Kosten (Werft / Crew)
static func upgrade_text(id: StringName) -> String:
	var rows := []
	for lv in ShipUpgrades.max_level(id) + 1:
		var eff := ""
		match id:
			&"shields":
				eff = "%d Schildpunkte je Seite" % SpaceSetup.SHIELD_PER_SIDE[lv]
			&"armor":
				eff = "%d Abzug je Treffer auf die Hülle" % SpaceSetup.ARMOR_PER_HIT[lv]
			&"reactor":
				eff = "%d Energie je Runde" % SpaceSetup.REACTOR_ENERGY[lv]
			&"slots":
				eff = ", ".join(SpaceSetup.slots_for(lv).map(func(s) -> String: return String(SpaceSetup.SLOT_NAMES[s])))
		var cost := "Start" if lv == 0 else "Werft %d Cr · Crew %d Material, %d Tage" % [ShipUpgrades.YARD_COST[lv - 1], ShipUpgrades.CREW_MATERIAL[lv - 1], ShipUpgrades.CREW_DAYS[lv - 1]]
		rows.append(["Stufe %d" % lv, eff, cost])
	return "[font_size=24][b]%s[/b][/font_size]\n\n" % ShipUpgrades.AREAS[id].name + _grid(["Stufe", "Wirkung im Raumkampf", "Kosten"], rows) \
		+ "\n\n[color=%s]Ausbau im Maschinenraum (Crew, Probe Reparatur am Ende) oder in der Werft im Raumhafen (Credits nach Verhandeln).[/color]" % MUTED


static func ship_ammo_text(t: String) -> String:
	var used := []
	for k in ShipWeapons.CATALOG:
		if String(ShipWeapons.CATALOG[k].ammo) == t:
			used.append(_link("s_waffen", ShipWeapons.name(k)))
	var rows := [["Preis", "%d Cr je Stück (Grundpreis, nach Verhandeln)" % int(ShipArms.AMMO_PRICE[t])],
		["Packungen im Handel", " / ".join(ShipArms.AMMO_PACKS[t].map(func(n) -> String: return str(n)))],
		["Startvorrat", str(SpaceSetup.START_AMMO.get(t, 0))], ["Für", ", ".join(used) if not used.is_empty() else "–"]]
	return _page(String(ShipWeapons.AMMO_TYPES[t]), rows, "[color=%s]Kauf und Verkauf beim Schiffshändler im Raumhafen; Beute aus dem Raumkampf.[/color]" % MUTED)


static func energy_text() -> String:
	var used := []
	for k in ShipWeapons.CATALOG:
		if String(ShipWeapons.CATALOG[k].ammo) == "":
			used.append("%s (%d)" % [_link("s_waffen", ShipWeapons.name(k)), int(ShipWeapons.CATALOG[k].energy)])
	var rows := [["Quelle", "%s: %s Energie je Runde" % [_link("s_ausbau", "Reaktor"), " / ".join(SpaceSetup.REACTOR_ENERGY.map(func(n) -> String: return str(n)))]],
		["Waffen (Energie je Schuss)", ", ".join(used)]]
	return _page("Energie", rows)


## Zeile der Stationstabelle aus docs/Raumkampf.md (Abschnitt 2), die mit key beginnt: [Station, Fertigkeit, Aktion]
static func _station_row(key: String) -> Array:
	var md := _rules(SPACE_RULES_FILE)
	for ln in md.split("\n"):
		if ln.begins_with("|"):
			var c := ln.strip_edges().trim_prefix("|").trim_suffix("|").split("|")
			if c.size() >= 3 and String(c[0]).strip_edges().begins_with(key):
				return [String(c[0]).strip_edges(), String(c[1]).strip_edges(), String(c[2]).strip_edges()]
	return []


static func station_text(title: String, skill: StringName, key := "") -> String:
	var r := _station_row(key if key != "" else title)
	var rows := []
	rows.append(["Fertigkeit", Rules.skill_name(skill) if skill != &"" else (r[1] if not r.is_empty() else "–")])
	if not r.is_empty():
		rows.append(["Aufgabe", _inline(r[2])])
	match key:
		"Geschütze":
			rows.append(["Anzahl", "je bestücktem Slot eine Geschützstation (Fertigkeit nach Art der %s)" % _link("s_waffen", OVERVIEW, "Waffe")])
		"Punktverteidigung":
			rows.append(["Anzahl", "je bestücktem Turm-Slot"])
		"Technik":
			rows.append(["Hinweis", "weitere Techniker an Bord; arbeiten wie die Station Technik"])
	return _page(title, rows, "[color=%s]Regel: %s[/color]" % [MUTED, _link("s_regeln", "Stationen (Regel)")])


static func free_stations_text() -> String:
	var rows := [["Bord-KI", "fester Bonus %s" % Dice.fmt(SpaceSetup.KI_BONUS)], ["Doppelbesetzung", "eine Person an zwei Stationen, beide Würfe %d" % SpaceSetup.DOUBLE_MALUS]]
	return _page("Freie Stationen", rows)


# ---------------------------------------------------------------- Fraktionen, Gegnertypen, Orte, Sektoren (Hub Auftrag 5)

const ENEMY_DIR := "res://data/units/enemies"
const ATTRS := ["STA", "GEW", "KOO", "KON", "INT", "EMP", "MEN"]


## Einträge der Bereiche fraktionen, gegner, orte, sektoren
static func world_entries(sec: StringName) -> Array:
	var out := []
	match sec:
		&"fraktionen":
			out.append({"name": OVERVIEW, "text": factions_overview()})
			for f in _factions():
				out.append({"name": f.name, "text": faction_text(f)})
		&"gegner":
			out.append({"name": OVERVIEW, "text": enemies_overview()})
			for u in enemy_units():
				out.append({"name": unit_label(u), "text": enemy_text(u)})
		&"orte":
			out.append({"name": OVERVIEW, "text": places_overview()})
			for k in Places.KINDS:
				out.append({"name": Places.kind_name(k), "text": place_text(k)})
		&"sektoren":
			out.append({"name": "Sektoren", "text": sectors_text()})
			out.append({"name": "Sprungtore", "text": gates_text()})
			out.append({"name": "Häfen", "text": harbors_text()})
	return out


## Fraktionen nach Oberart (Story zuletzt), dann Name
static func _factions() -> Array[FactionData]:
	var list := Mission.all_factions()
	var order := FactionData.KINDS.keys()
	list.sort_custom(func(a: FactionData, b: FactionData) -> bool:
		var ka := order.find(a.kind)
		var kb := order.find(b.kind)
		return ka < kb or (ka == kb and a.name < b.name))
	return list


## Gegnertypen aus data/units/enemies, nach Name
static func enemy_units() -> Array[UnitData]:
	var out: Array[UnitData] = []
	for f in ResourceLoader.list_directory(ENEMY_DIR):
		if f.ends_with(".tres"):
			out.append(load(ENEMY_DIR.path_join(f)))
	out.sort_custom(func(a: UnitData, b: UnitData) -> bool: return a.name < b.name)
	return out


## Eintragsname eines Gegnertyps; gleiche Namen (Plünderer) werden nach der Datei durchnummeriert
static func unit_label(u: UnitData) -> String:
	var same := enemy_units().filter(func(x: UnitData) -> bool: return x.name == u.name)
	if same.size() < 2:
		return u.name
	return "%s %d" % [u.name, same.map(func(x: UnitData) -> String: return x.resource_path).find(u.resource_path) + 1]


static func _maps_text(f: FactionData) -> String:
	if f.maps.is_empty():
		return "alle gleich oft"
	return "%s (%d %% der Einsätze)" % [", ".join(Array(f.maps).map(func(m) -> String: return MapTypes.type_name(m))), roundi(FactionData.MAP_CHANCE * 100)]


## Raumkampf-Seite der Fraktion: eigene Seite oder Ersatz „Piraten“
static func _side_link(f: FactionData) -> String:
	var id := f.resource_path.get_file().get_basename()
	var sides := SpaceTemplates.factions()
	if sides.has(id):
		return _link("s_seiten", String(sides[id].name))
	return "%s (Ersatz)" % _link("s_seiten", SpaceTemplates.faction_name("piraten"))


static func _trait_text(f: FactionData) -> String:
	return "%s: %s" % [f.trait_name, f.trait_text] if f.trait_name != "" else "–"


static func _color_dot(c: Color) -> String:
	return "[color=#%s]●[/color]" % c.to_html(false)


static func factions_overview() -> String:
	var rows := []
	for f in _factions():
		rows.append([_color_dot(f.color) + " " + _link("fraktionen", f.name), f.kind_name(), f.trait_name if f.trait_name != "" else "–",
			", ".join(Array(f.maps).map(func(m) -> String: return MapTypes.type_name(m))) if not f.maps.is_empty() else "alle", _side_link(f)])
	return "[font_size=24][b]Fraktionen[/b][/font_size]\n\n" + _grid(["Fraktion", "Oberart", "Eigenheit", "Karten", "Raumkampf"], rows) \
		+ "\n\n[color=%s]Je Sektor stellt jede Oberart (außer Story) eine Fraktion. Story-Fraktionen treten nur in Story-Einsätzen auf und zahlen keinen Lohn.[/color]" % MUTED


static func faction_text(f: FactionData) -> String:
	var total := 0
	for w in f.weights:
		total += w
	var units := []
	for i in f.units.size():
		var u := f.units[i]
		var w: int = f.weights[i] if i < f.weights.size() else 0
		units.append([_link("gegner", unit_label(u)), u.role, "%d %%" % roundi(100.0 * w / maxi(1, total))])
	var swap := []
	for k in f.weapon_swap:
		var to = f.weapon_swap[k]
		swap.append("%s → %s" % [String(k), _link("waffen", to.name) if to is WeaponData else str(to)])
	var pay := "kein Lohn (Story)" if f.kind == &"story" else "Lohn ×%s%s" % [_num(float(Voyage.PAY_FACTOR.get(f.resource_path.get_file().get_basename(), 1.0))),
		(", +%d Schiffsmaterial" % int(Voyage.LOOT_BONUS[f.resource_path.get_file().get_basename()])) if Voyage.LOOT_BONUS.has(f.resource_path.get_file().get_basename()) else ""]
	var rows := [["Oberart", f.kind_name()], ["Farbe", "%s auf der Sternenkarte" % _color_dot(f.color)], ["Eigenheit", _trait_text(f)],
		["Karten", _maps_text(f)], ["Waffentausch", ", ".join(swap) if not swap.is_empty() else "–"],
		["Höchstens gleich", "%d Figuren desselben Typs" % f.max_same], ["Auftraggeber", pay], ["Raumkampf", _side_link(f)]]
	var tail := ("[color=%s]%s[/color]\n\n" % [MUTED, f.description]) if f.description != "" else ""
	tail += "[color=%s]GEGNERZUSAMMENSTELLUNG (Anteil beim Würfeln)[/color]\n" % MUTED + _grid(["Gegnertyp", "Rolle", "Anteil"], units)
	return _page(f.name, rows, tail)


## Psi-Kräfte eines Gegnertyps aus seinen Listenrängen
static func _unit_psi(u: UnitData) -> String:
	var out := []
	for k in PsiCombat.ATTACKS.keys() + PsiCombat.SUPPORT.keys():
		var list := PsiCombat.list_of(k)
		if int(u.skills.get(String(list), 0)) >= PsiCombat.level_of(k):
			out.append(PsiCombat.name_of(k))
	return ", ".join(out) if not out.is_empty() else "–"


static func _unit_weapons(u: UnitData) -> String:
	return ", ".join(u.weapons.map(func(w: WeaponData) -> String: return _link("waffen", w.name))) if not u.weapons.is_empty() else "–"


static func enemies_overview() -> String:
	var rows := []
	for u in enemy_units():
		rows.append([_link("gegner", unit_label(u)), u.role, str(u.threat), _unit_weapons(u), _link("ruestungen", u.armor.name) if u.armor else "–", _unit_psi(u)])
	return "[font_size=24][b]Gegnertypen[/b][/font_size]\n\n" + _grid(["Gegner", "Rolle", "Bedrohung", "Waffen", "Rüstung", "Psi"], rows) \
		+ "\n\n[color=%s]Bedrohung = Kosten im Gegnerbudget des Missionsgenerators.[/color]" % MUTED


static func enemy_text(u: UnitData) -> String:
	var used := []
	for f in _factions():
		if u in f.units:
			used.append(_link("fraktionen", f.name))
	var skills := []
	var keys := u.skills.keys()
	keys.sort()
	for k in keys:
		skills.append("%s %d" % [Rules.skill_name(StringName(k)), int(u.skills[k])])
	var rows := [["Rolle", u.role], ["Bedrohung", str(u.threat)],
		["Eigenschaften", "  ".join(ATTRS.map(func(a: String) -> String: return "%s %d" % [a, int(u.attrs.get(a, 50))]))],
		["Fertigkeiten (Rang)", ", ".join(skills) if not skills.is_empty() else "–"], ["Waffen", _unit_weapons(u)],
		["Rüstung", _link("ruestungen", u.armor.name) if u.armor else "keine"], ["Schild", "ja" if u.shield else "nein"],
		["Medikits", str(u.medkits)], ["Psi", _unit_psi(u)], ["Fraktionen", ", ".join(used) if not used.is_empty() else "–"]]
	return _page(unit_label(u), rows, "[color=%s]Die Eigenheit der Fraktion (siehe dort) wirkt zusätzlich auf jede ihrer Figuren.[/color]" % MUTED)


static func _result_rows(table: Dictionary, fmt: Callable) -> Array:
	var rows := []
	for r in [&"herausragend", &"erfolg", &"teilerfolg", &"fehlschlag", &"patzer"]:
		rows.append([{&"herausragend": "Herausragend", &"erfolg": "Erfolg", &"teilerfolg": "Teilerfolg", &"fehlschlag": "Fehlschlag", &"patzer": "Patzer"}[r],
			fmt.call(table.get(r))])
	return rows


static func _salvage_gain(g: Dictionary) -> String:
	var parts := []
	if g.has("hull"):
		parts.append("Hülle %s" % Dice.fmt(int(g.hull)))
	if g.has("material"):
		parts.append("+%d Schiffsmaterial" % int(g.material))
	if g.has("craft"):
		parts.append("+%d Handwerksmaterial" % int(g.craft))
	if g.get("weapon", false):
		parts.append("eine beschädigte Schiffswaffe (−20)")
	return ", ".join(parts) if not parts.is_empty() else "nichts"


static func _place_maps(kind: String) -> String:
	return ", ".join(Places.MAPS[kind].map(func(m) -> String: return MapTypes.type_name(m))) if Places.has_ground(kind) else "keine Bodeneinsätze"


static func places_overview() -> String:
	var rows := []
	for k in Places.KINDS:
		rows.append([_link("orte", Places.kind_name(k)), Places.function_text(k), _place_maps(k)])
	return "[font_size=24][b]Orte[/b][/font_size]\n\n" + _grid(["Ort", "Möglichkeiten", "Kartentypen"], rows) \
		+ "\n\n[color=%s]Jedes System hat %d–%d Orte, jeder Hafen eine Station. Doppelklick auf ein System öffnet die Systemansicht; dort Ort wählen und „Anfliegen“ (keine Zeit), Aktionen nur, wenn das Schiff im System liegt.[/color]" % [MUTED, Places.MIN_PLACES, Places.MAX_PLACES]


static func place_text(kind: String) -> String:
	var rows := [["Möglichkeiten", Places.function_text(kind)], ["Kartentypen", _place_maps(kind)]]
	var tail := ""
	match kind:
		"station":
			rows.append(["Handel", "Händler und Schiffshändler; außerhalb eines Hafens Preise ×%s" % _num(Places.STATION_FACTOR)])
		"wrack":
			rows.append(["Bergung", "1 Tag, Probe %s (mittel), wer an Bord am besten ist; danach ist das Wrack leer" % Rules.skill_name(Places.SALVAGE_SKILL)])
			tail = "[color=%s]ERGEBNISSE[/color]\n" % MUTED + _grid(["Probe", "Ertrag"], _result_rows(Places.SALVAGE, func(g) -> String: return _salvage_gain(g)))
		"gas", "nebel":
			rows.append(["Treibstoff schöpfen", "1 Tag, Probe %s (mittel), beliebig oft, bis der Tank voll ist" % Rules.skill_name(Places.SKIM_SKILL)])
			tail = "[color=%s]ERGEBNISSE[/color]\n" % MUTED + _grid(["Probe", "Ertrag"], _result_rows(Places.SKIM, func(n) -> String:
				return ("Hülle %s" % Dice.fmt(int(n))) if int(n) < 0 else ("+%d Treibstoff" % int(n)) if int(n) > 0 else "nichts"))
	rows.append(["Story", "Story-Orte können hier liegen; sie beginnen beim Anfliegen"])
	return _page(Places.kind_name(kind), rows, tail)


static func sectors_text() -> String:
	var rows := [["Sektoren", "%d je Spiel, im Dreieck durch Sprungtore verbunden" % Sector.SECTOR_COUNT],
		["Systeme", "%d–%d je Sektor, jedes mit seinen %d nächsten Nachbarn verbunden" % [Sector.SYSTEM_MIN, Sector.SYSTEM_MAX, Sector.NEIGHBORS]],
		["Reise", "höchstens %d Reisetage je Strecke, Reiseproben je Tag" % Sector.MAX_DAYS],
		["Fraktionen", "je Sektor eine %s je Oberart; jedes System gehört einer Fraktion oder ist ein Hafen" % _link("fraktionen", OVERVIEW, "Fraktion")],
		["Bekannt", "der Startsektor; weitere, sobald das Schiff durch ein Tor springt (Knopf „Sektoren“ in der Sternenkarte)"]]
	return _page("Sektoren", rows, _link("regeln", "Reise, Schiff, Credits", "Regeln zu Reise und Schiff"))


static func gates_text() -> String:
	var rows := [["Lage", "2 je Sektor, am Kartenrand, nie am Heimathafen"],
		["Gebühr", "%d–%d Cr, nach %s" % [Sector.GATE_FEE[0], Sector.GATE_FEE[1], Rules.skill_name(&"verhandeln")]],
		["Papiere", "etwa %d %% der Tore verlangen Papiere des Betreibers; Kauf im Hafen, %d Cr nach Verhandeln" % [roundi(Sector.PAPERS_CHANCE * 100), HubState.PAPERS_PRICE]],
		["Sprung", "das Schiff muss im System des Tors liegen; kostet 1 Tag; offene Aufträge des alten Sektors verfallen"],
		["Rückweg", "jedes Tor hat im Zielsektor ein Gegenstück zurück"]]
	return _page("Sprungtore", rows)


static func harbors_text() -> String:
	var rows := [["Anzahl", "%d neutrale Häfen je Sektor" % Sector.NEUTRAL], ["Station", "jeder Hafen hat eine Station"],
		["Angebot", "Händler, Schiffshändler, Werft, Crew anheuern, Papiere, Treibstoff, Proviant, Munition"],
		["Preise", "Grundpreise nach Verhandeln (Stationen außerhalb: ×%s)" % _num(Places.STATION_FACTOR)],
		["Sicherheit", "weniger Feindkontakt auf der Reise als in Fraktionssystemen"]]
	return _page("Häfen", rows)
