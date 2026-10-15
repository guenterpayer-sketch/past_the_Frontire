class_name HubUI
extends Control
## Oberfläche im Schiff (Hub), schwebend über dem 3D-Deck: oben links Status (Spielstand, Tag, Position, Crew),
## oben rechts Speichern/Laden/Menü und Infokasten zum Raum unter der Maus, unten links die Räume als Knöpfe,
## über jedem Raum ein Namensschild. Dialoge: Sternenkarte, Crewquartiere, Charakterbogen, Spielstände, Bericht.

signal action(name: StringName, arg: Variant)

const MARGIN := 14.0
const MENU := [[&"main_menu", "Hauptmenü"], [&"sound", "Ton an/aus"], [&"ui_scale", "UI-Größe …"], [&"help", "Bedienung"]]

var status: Label
var info: InfoBox
var star_map: StarMap
var crew: CrewOverview
var sheet: SheetDialog
var slots: SlotsDialog
var report: Modal
var medbay: MedbayDialog
var armory: ArmoryDialog
var notice: Modal
var help: Modal
var room_tags := {}           # Raum-ID -> Button über dem Raum
var room_buttons := {}        # Raum-ID -> Button unten links
var _status_box: PanelContainer
var _top_right: VBoxContainer
var _rooms_box: PanelContainer
var _hint: PanelContainer


func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	for r in ShipView.ROOMS:
		var t := Button.new()
		t.text = r.name.to_upper() + ("" if r.ready else "\nkommt noch")
		t.focus_mode = Control.FOCUS_NONE
		t.add_theme_font_size_override("font_size", 15)
		t.add_theme_stylebox_override("normal", UiTheme.box(Color(UiTheme.PANEL, 0.88), UiTheme.ACCENT if r.ready else UiTheme.LINE, 6, 6))
		t.add_theme_stylebox_override("hover", UiTheme.box(Color("3a3215"), UiTheme.ACCENT, 6, 6))
		t.add_theme_color_override("font_color", UiTheme.ACCENT if r.ready else UiTheme.MUTED)
		t.pressed.connect(func() -> void: action.emit(&"room", r.id))
		t.mouse_entered.connect(func() -> void: action.emit(&"hover_room", r.id))
		add_child(t)
		room_tags[r.id] = t

	_status_box = PanelContainer.new()
	_status_box.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.LINE, 10, 12))
	status = UiTheme.label("", 15)
	_status_box.add_child(status)
	add_child(_status_box)

	_top_right = VBoxContainer.new()
	_top_right.add_theme_constant_override("separation", 8)
	_top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top_right)
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.LINE, 10, 6))
	bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	_top_right.add_child(bar)
	var row := HBoxContainer.new()
	bar.add_child(row)
	for spec in [[&"save", "Speichern"], [&"load", "Laden"]]:
		var b := UiTheme.button(spec[1])
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(func() -> void: action.emit(spec[0], null))
		row.add_child(b)
	var menu := MenuButton.new()
	menu.tooltip_text = "Menü: Hauptmenü, Ton, Bedienung"
	menu.custom_minimum_size = Vector2(44, 44)
	menu.focus_mode = Control.FOCUS_NONE
	menu.flat = false
	var popup := menu.get_popup()
	for i in MENU.size():
		popup.add_item(MENU[i][1], i)
	popup.add_theme_font_size_override("font_size", 15)
	popup.id_pressed.connect(func(id: int) -> void: action.emit(MENU[id][0], null))
	menu.draw.connect(func() -> void:
		var o := menu.size / 2.0
		for y in [-6.0, 0.0, 6.0]:
			menu.draw_line(o + Vector2(-8, y), o + Vector2(8, y), UiTheme.TEXT, 2.0, true))
	row.add_child(menu)
	info = InfoBox.new()
	info.size_flags_horizontal = Control.SIZE_SHRINK_END
	_top_right.add_child(info)

	_rooms_box = PanelContainer.new()
	_rooms_box.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.LINE, 10, 6))
	add_child(_rooms_box)
	var rrow := HBoxContainer.new()
	_rooms_box.add_child(rrow)
	for r in ShipView.ROOMS:
		var b := UiTheme.button(r.name, r.text if r.ready else r.text + " (kommt noch)")
		b.custom_minimum_size.y = 44
		if r.ready:
			b.add_theme_color_override("font_color", UiTheme.ACCENT)
		else:
			b.add_theme_color_override("font_color", UiTheme.MUTED)
		b.pressed.connect(func() -> void: action.emit(&"room", r.id))
		b.mouse_entered.connect(func() -> void: action.emit(&"hover_room", r.id))
		rrow.add_child(b)
		room_buttons[r.id] = b

	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.LINE, 8, 8))
	_hint.add_child(UiTheme.label("Ziehen / WASD: Kamera · Mausrad: Zoom · Q/E: drehen · Raum anklicken", 13, UiTheme.MUTED))
	add_child(_hint)

	star_map = StarMap.new()
	crew = CrewOverview.new()
	sheet = SheetDialog.new()
	slots = SlotsDialog.new()
	report = Modal.new()
	medbay = MedbayDialog.new()
	armory = ArmoryDialog.new()
	notice = Modal.new()
	help = Modal.new()
	for d in [star_map, crew, sheet, slots, report, notice, help, medbay, armory]:
		add_child(d)
	notice.max_size = Vector2(620, 320)
	report.max_size = Vector2(900, 540)
	crew.open_sheet.connect(func(c: Array[Character], u: Character) -> void:
		var units := Roster.build_crew(c)
		sheet.show_sheet(units, units[c.find(u)])
		sheet.move_to_front())


func _process(_d: float) -> void:
	_top_right.reset_size()
	_status_box.reset_size()
	_rooms_box.reset_size()
	_hint.reset_size()
	_status_box.position = Vector2(MARGIN, MARGIN)
	_top_right.position = Vector2(size.x - MARGIN - _top_right.size.x, MARGIN)
	_rooms_box.position = Vector2(MARGIN, size.y - MARGIN - _rooms_box.size.y)
	_hint.position = Vector2(size.x - MARGIN - _hint.size.x, size.y - MARGIN - _hint.size.y)


func set_status(g: HubState) -> void:
	var sys: Dictionary = g.sector.systems[g.position]
	var f := g.sector.faction_of(g.position)
	status.text = "%s   ·   Tag %d   ·   %s (%s)   ·   %s   ·   %d %s offen" % [
		g.slot_name if g.slot_name != "" else "nicht gespeichert", g.day, sys.name, f.name if f else "neutral",
		g.sector.name, g.offers.size(), "Auftrag" if g.offers.size() == 1 else "Aufträge"]


## Namensschilder über den Räumen (Bildschirmpunkte vom Schiff)
func place_tags(points: Dictionary) -> void:
	for id in room_tags:
		var t: Button = room_tags[id]
		t.reset_size()
		t.position = points[id] - t.size / 2.0
		t.visible = not any_dialog_open()


func show_room_info(r: Dictionary, g: HubState) -> void:
	if r.is_empty():
		info.show_info("")
		return
	var s := "[font_size=20][color=#ffd34d]%s[/color][/font_size]\n%s" % [r.name, r.text]
	if r.id == &"bridge" and g:
		var soon := g.offers.filter(func(o: Dictionary) -> bool: return int(o.expires) - g.day <= 2).size()
		s += "\n[color=#8291ad]%d %s offen%s[/color]" % [g.offers.size(), "Auftrag" if g.offers.size() == 1 else "Aufträge",
			(" · %d läuft bald ab" % soon) if soon else ""]
	s += "\n[color=#8291ad]%s[/color]" % ("Klick: öffnen" if r.ready else "kommt noch")
	info.show_info(s)


## Crewquartiere: Charakterübersicht des Charakter-Moduls; nach einem Einsatz mit dessen Ergebnis.
## Der Knopf „Speichern & nächste Mission“ heißt im Schiff „Speichern & zurück“; „Crew zurücksetzen“
## gibt es im Schiff nicht (dafür ein neues Spiel beginnen). Anheuern geht nur im Hafen auf der Brücke.
func show_crew() -> void:
	crew.seats = HubState.game.berths if HubState.game else Campaign.START_SEATS
	crew.show_crew(Campaign.crew(), Campaign.last_result)
	relabel_crew()


## Knopftexte der Übersicht fürs Schiff setzen (auch nach crew_changed, wenn sich die Übersicht neu aufbaut)
func relabel_crew() -> void:
	for b in crew.footer.get_children():
		if b is Button and (b as Button).text.begins_with("Speichern"):
			(b as Button).text = "Speichern & zurück"
		elif b is Button and (b as Button).text.begins_with("Crew zurücksetzen"):
			(b as Button).hide()


## Kurze Meldung oben in der Mitte (verschwindet nach einigen Sekunden), auch über offenen Fenstern
func show_toast(text: String) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL2, 0.97), UiTheme.GOOD, 8, 12))
	p.add_child(UiTheme.label(text, 16, UiTheme.GOOD))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	p.reset_size()
	p.position = Vector2((size.x - p.size.x) / 2.0, 70)
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)


## Einstellung UI-Größe (gilt fürs ganze Spiel, sofort)
func show_ui_scale() -> void:
	notice.open("UI-Größe")
	notice.content.add_child(UiScale.picker(get_tree()))
	var l := UiTheme.label("Größe von Schrift und Kästen im ganzen Spiel; die 3D-Ansicht bleibt gleich. Wird gespeichert.", 13, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.content.add_child(l)
	notice.add_close()
	notice.move_to_front()


func show_notice(title: String, text: String) -> void:
	notice.open(title)
	var l := UiTheme.label(text, 15)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.content.add_child(l)
	notice.add_close()


## Einsatzbericht nach der Rückkehr aus dem Bodenkampf
func show_report(rep: Dictionary) -> void:
	var win: bool = rep.get("outcome", &"") == &"sieg"
	report.open("Einsatzbericht: %s – %s" % ["Sieg" if win else "Niederlage", rep.get("title", "")])
	var rounds: int = rep.get("rounds", 0)
	var head := UiTheme.label("%s · %s · %d %s · zurück an Bord an Tag %d" % [rep.get("system", ""), rep.get("faction", ""),
		rounds, "Runde" if rounds == 1 else "Runden", rep.get("day", 0)], 14, UiTheme.MUTED)
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report.content.add_child(head)
	report.content.add_child(UiTheme.label("Jede Figur: +%d freie EP%s" % [rep.get("free_xp", 0),
		(" (davon +%d Missionsbelohnung)" % rep.reward_xp) if rep.get("reward_xp", 0) > 0 else " (keine Missionsbelohnung)"], 15, UiTheme.ACCENT))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 16)
	for h in ["Figur", "Zustand", "Fertigkeits-EP im Einsatz"]:
		g.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	for u in rep.get("units", []):
		g.add_child(UiTheme.label("%s %s" % [u.letter, u.name], 14, UiTheme.CREW))
		g.add_child(UiTheme.label(u.state, 14, UiTheme.GOOD if u.state == "kampffähig" else UiTheme.BAD))
		var xl := UiTheme.label(u.xp if u.xp != "" else "–", 13)
		xl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		xl.custom_minimum_size.x = 420
		g.add_child(xl)
	report.content.add_child(g)
	var note := UiTheme.label("Prototyp: Verletzte und Ausgefallene sind beim nächsten Einsatz wieder voll da (Heilung und Tod zwischen Einsätzen sind noch offen).", 12, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report.content.add_child(note)
	var go := UiTheme.button("Zu den Crewquartieren")
	go.add_theme_color_override("font_color", UiTheme.ACCENT)
	go.pressed.connect(func() -> void:
		report.hide()
		action.emit(&"room", &"quarters"))
	report.footer.add_child(go)
	report.add_close()


func show_help() -> void:
	help.open("Bedienung im Schiff")
	var l := UiTheme.label("""Raum anklicken (oder Knopf unten links): Brücke = Sternenkarte und Aufträge, Crewquartiere = Crew steigern.
Kamera: ziehen (links/Mitte), WASD/Pfeile, Mausrad = Zoom, Q/E = um 90° drehen.
Sternenkarte: System anklicken; „Kurs setzen“ fliegt hin (Tage vergehen, Aufträge laufen ab), „Hinfliegen & Briefing“ nimmt den gewählten Auftrag an.
Speichern geht nur im Schiff (oben rechts).""", 15)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.content.add_child(l)
	help.add_close()


func any_dialog_open() -> bool:
	return star_map.visible or crew.visible or sheet.visible or slots.visible or report.visible or notice.visible or help.visible or medbay.visible or armory.visible


func close_dialogs() -> bool:
	for d in [sheet, help, notice, slots, report, medbay, armory]:
		if d.visible:
			d.close()
			return true
	if star_map.visible:
		star_map.close()
		return true
	return false


## liegt der Punkt auf der Oberfläche (nicht auf dem Deck)?
func covers(p: Vector2) -> bool:
	if any_dialog_open():
		return true
	for c in [_status_box, _top_right, _rooms_box, _hint]:
		if c.get_global_rect().has_point(p):
			return true
	for t in room_tags.values():
		if t.visible and t.get_global_rect().has_point(p):
			return true
	return false
