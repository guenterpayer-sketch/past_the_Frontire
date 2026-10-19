class_name HubUI
extends Control
## Oberfläche im Schiff (Hub), schwebend über dem 3D-Deck: oben links Status (Spielstand, Tag, Position, Crew),
## oben rechts Speichern/Laden/Menü und Infokasten zum Raum unter der Maus, unten links die Räume als Knöpfe,
## über jedem Raum ein Namensschild. Dialoge: Sternenkarte, Crewquartiere, Charakterbogen, Spielstände, Bericht.

signal action(name: StringName, arg: Variant)
## Beuteauswahl abgeschlossen (HubState.take_loot), beim Schließen des Einsatzberichts
signal loot_taken(result: Dictionary)
## Feindkontakt: kämpfen (true) oder ausweichen versuchen (false)
signal contact_choice(fight: bool)
## Bericht nach dem Raumkampf geschlossen
signal space_report_closed

const MARGIN := 14.0
const MENU := [[&"encyclopedia", "Enzyklopädie"], [&"logbook", "Logbuch"], [&"main_menu", "Hauptmenü"], [&"sound", "Ton an/aus"], [&"ui_scale", "Einstellungen …"], [&"help", "Bedienung"]]

## Größe des Hinweisfensters (Meldungen, Auswahl)
const NOTICE_SIZE := Vector2(640, 440)

var status: Label
var info: InfoBox
var star_map: StarMap
var crew: CrewOverview
var sheet: SheetDialog
var slots: SlotsDialog
var report: Modal
## Raumkampf im Spiel: Feindkontakt (Wahl kämpfen/ausweichen) und Bericht nach dem Raumkampf
var contact: Modal
var space_report: Modal
var medbay: MedbayDialog
var galley: GalleyDialog
var armory: ArmoryDialog
var notice: Modal
var help: Modal
var room_tags := {}           # Raum-ID -> Button über dem Raum
var room_buttons := {}        # Raum-ID -> Button unten links
var _status_box: PanelContainer
var _res_row: HBoxContainer
var _warn_box: VBoxContainer
var travel_report: Modal
var engine: EngineDialog
var trade: TradeDialog
var craft: CraftDialog
var ship_arms: ShipArmsDialog
var port: PortDialog
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
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 8)
	_status_box.add_child(sv)
	status = UiTheme.label("", 15)
	sv.add_child(status)
	_res_row = HBoxContainer.new()
	_res_row.add_theme_constant_override("separation", 22)
	sv.add_child(_res_row)
	_warn_box = VBoxContainer.new()
	_warn_box.add_theme_constant_override("separation", 4)
	sv.add_child(_warn_box)
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
	Version.add_to(popup)
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
	if DisplayServer.is_touchscreen_available() or "--autotest-touch" in OS.get_cmdline_user_args():
		# Tablet (Hub Auftrag 6, Entscheidung des Nutzers): Touch-Hinweis und Drehknöpfe in der Hinweisleiste
		var hrow := HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 8)
		_hint.add_child(hrow)
		var hl := UiTheme.label("Wischen: Kamera · zwei Finger: Zoom/drehen · Raum antippen", 13, UiTheme.MUTED)
		hl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hrow.add_child(hl)
		for spec in [[-90, "Ansicht nach links drehen (⟲)"], [90, "Ansicht nach rechts drehen (⟳)"]]:
			var rb := UiTheme.button("", spec[1])
			rb.custom_minimum_size = Vector2(44, 44)
			var deg: int = spec[0]
			# Pfeil im Kreis selbst zeichnen (die Schrift hat ⟲/⟳ nicht sicher), wie das Burgermenü
			rb.draw.connect(func() -> void: _draw_turn(rb, deg < 0))
			rb.pressed.connect(func() -> void: action.emit(&"rotate", deg))
			hrow.add_child(rb)
	else:
		_hint.add_child(UiTheme.label("Ziehen / WASD: Kamera · Mausrad: Zoom · Q/E: drehen · Raum anklicken", 13, UiTheme.MUTED))
	add_child(_hint)

	star_map = StarMap.new()
	crew = CrewOverview.new()
	sheet = SheetDialog.new()
	slots = SlotsDialog.new()
	report = Modal.new()
	contact = Modal.new()
	space_report = Modal.new()
	medbay = MedbayDialog.new()
	galley = GalleyDialog.new()
	armory = ArmoryDialog.new()
	travel_report = Modal.new()
	engine = EngineDialog.new()
	trade = TradeDialog.new()
	craft = CraftDialog.new()
	ship_arms = ShipArmsDialog.new()
	port = PortDialog.new()
	notice = Modal.new()
	help = Modal.new()
	for d in [star_map, crew, sheet, slots, report, notice, help, medbay, galley, armory, travel_report, engine, trade, craft, ship_arms, port, contact, space_report]:
		add_child(d)
	travel_report.max_size = Vector2(1100, 640)
	notice.max_size = NOTICE_SIZE
	report.max_size = Vector2(900, 700)
	report.visibility_changed.connect(_on_report_visibility)
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
	UiTheme.clear(_res_row)
	_res_row.add_child(_stat("Credits", "%d Cr" % g.credits, UiTheme.BAD if g.credits < 0 else UiTheme.ACCENT))
	_res_row.add_child(_meter("Treibstoff", g.fuel, g.tank_max(), UiTheme.CREW))
	_res_row.add_child(_meter("Hülle", g.hull, g.hull_max(), UiTheme.GOOD))
	_res_row.add_child(_stat("Material", str(g.material), UiTheme.TEXT))
	_res_row.add_child(_stat("Proviant", provisions_text(g), UiTheme.BAD if g.provisions <= 0 else UiTheme.TEXT))
	_res_row.add_child(_stat("Munition", ammo_text(g), UiTheme.TEXT))
	UiTheme.clear(_warn_box)
	for w in warnings(g):
		_warn_box.add_child(UiTheme.label(w[0], 14, w[1]))


## „Energie 200 · Projektil 300 · Raketen 6“
static func ammo_text(g: HubState) -> String:
	var parts := []
	for t in Voyage.AMMO_START:
		parts.append("%s %d" % [String(Ammo.TYPES.get(StringName(t), t)).split("zellen")[0], int(g.ammo.get(t, 0))])
	return " · ".join(parts)


## „48 · 6 je Tag“ bzw. „48 · im Hafen kein Verbrauch“
static func provisions_text(g: HubState) -> String:
	if g.is_harbor(g.position):
		return "%d · im Hafen kein Verbrauch" % g.provisions
	return "%d · %d je Tag" % [g.provisions, Galley.need()]


## Warnungen unter der Statusleiste: [Text, Farbe]
static func warnings(g: HubState) -> Array:
	var out := []
	var port := g.nearest_harbor()
	var port_text := ""
	if port >= 0 and port != g.position:
		var d: int = g.sector.route(g.position, port).days
		port_text = " (%s, %d %s)" % [g.sector.systems[port].name, d, "Tag" if d == 1 else "Tage"]
	if g.fuel <= 0:
		out.append(["Tank leer: Notsprit – nur Kurs zum nächsten Hafen%s" % port_text, UiTheme.BAD])
	elif g.fuel < Voyage.FUEL_LOW:
		out.append(["Treibstoff knapp: reicht für etwa %d Reisetage" % maxi(1, g.fuel / maxi(1, Voyage.estimate_fuel(g, 1))), Color("ff8a3d")])
	if g.hull <= 0:
		out.append(["Hülle 0: nur Kurs zum nächsten Hafen%s" % port_text, UiTheme.BAD])
	if g.provisions <= 0 and not Campaign.crew().is_empty():
		out.append(["Proviant leer: %d auf Proben im Schiff, bis wieder Proviant gekauft ist" % Galley.MALUS, UiTheme.BAD])
	elif not g.is_harbor(g.position) and Galley.days_left(g) < Galley.LOW_DAYS:
		out.append(["Proviant knapp: reicht etwa %d %s" % [Galley.days_left(g), "Tag" if Galley.days_left(g) == 1 else "Tage"], Color("ff8a3d")])
	if g.credits < 0:
		out.append(["Notkredit: %d Cr Schulden, der nächste Lohn gleicht aus" % -g.credits, UiTheme.BAD])
	return out


func _stat(title: String, value: String, col: Color) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.add_child(UiTheme.label(title, 12, UiTheme.MUTED))
	v.add_child(UiTheme.label(value, 16, col))
	return v


func _meter(title: String, value: int, max_value: int, col: Color) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.custom_minimum_size.x = 120
	v.add_child(UiTheme.label(title, 12, UiTheme.MUTED))
	v.add_child(UiTheme.label("%d / %d" % [value, max_value], 15, UiTheme.TEXT if value > 0 else UiTheme.BAD))
	var bar := ProgressBar.new()
	bar.max_value = max_value
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(120, 6)
	bar.add_theme_stylebox_override("background", UiTheme.box(UiTheme.BG, UiTheme.BG, 3, 0))
	bar.add_theme_stylebox_override("fill", UiTheme.box(col, col, 3, 0))
	v.add_child(bar)
	return v


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


## Einstellungen im Schiff: UI-Größe und Lautstärke Musik/Effekte (gelten fürs ganze Spiel, sofort, gespeichert)
func show_ui_scale() -> void:
	notice.open("Einstellungen")
	notice.content.add_child(UiScale.picker(get_tree()))
	notice.content.add_child(Music.volume_rows())
	var l := UiTheme.label("UI-Größe: Schrift und Kästen im ganzen Spiel, die 3D-Ansicht bleibt gleich. Alles wird gespeichert.", 13, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.content.add_child(l)
	notice.add_close()
	notice.move_to_front()


## Kleine Auswahl (z. B. Waffenkammer: Ausrüstung oder Werkstatt): options = [[Knopftext, Callable], …]
func show_choice(title: String, text: String, options: Array) -> void:
	notice.max_size = NOTICE_SIZE
	notice.open(title)
	var l := UiTheme.label(text, 15)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.content.add_child(l)
	for o in options:
		var b := UiTheme.button(String(o[0]))
		b.add_theme_color_override("font_color", UiTheme.ACCENT)
		var act: Callable = o[1]
		b.pressed.connect(func() -> void:
			notice.hide()
			act.call())
		notice.footer.add_child(b)
	notice.add_close("Abbrechen")
	notice.move_to_front()


func show_notice(title: String, text: String) -> void:
	notice.max_size = NOTICE_SIZE
	notice.open(title)
	var l := UiTheme.label(text, 15)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.content.add_child(l)
	notice.add_close()


## Einsatzbericht nach der Rückkehr aus dem Bodenkampf
func show_report(rep: Dictionary) -> void:
	var win: bool = rep.get("outcome", &"") == &"sieg"
	var retreat := bool(rep.get("retreated", false))
	var title := String(rep.get("title", "")).trim_suffix(" (Rückzug)")
	var head_name := "Rückzug" if retreat else ("Sieg" if win else "Niederlage")
	if rep.get("defend", false) and not retreat:
		head_name = "Sieg (Entern abgewehrt)" if win else "Niederlage (Schiff übernommen)"
	report.open("Einsatzbericht: %s – %s" % [head_name, title])
	if retreat:
		var rb := UiTheme.label("Rückzug · der Auftrag bleibt offen bis Tag %d (auf der Brücke als „erneuter Versuch“). Kein Lohn, keine Beute; Ausrüstung: kein Verlust, Kampfunfähige können Schaden bekommen." % int(rep.get("expires", 0)), 15, UiTheme.RETREAT)
		rb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		report.content.add_child(rb)
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
	if int(rep.get("training", 0)) > 0:
		report.content.add_child(UiTheme.label("Training: +%d freie EP für alle an Bord" % rep.training, 15, UiTheme.GOOD))
	var board_xp := {}
	for e in rep.get("cook", []):
		add_xp(board_xp, String(e.get("cook", "")), Galley.SKILL, int(e.get("xp", 0)))
	add_events(report.content, rep, board_xp)
	if not board_xp.is_empty():
		report.content.add_child(UiTheme.label("ERFAHRUNG AN BORD (KOCHEN, WERKSTATT, AUSBAU)", 13, UiTheme.MUTED))
		report.content.add_child(xp_list(board_xp))
	if rep.has("prov0"):
		var ck: Array = rep.get("cook", [])
		var kt := ("   ·   Kochen: " + ", ".join(ck.map(func(e: Dictionary) -> String: return cook_text(e)))) if not ck.is_empty() else ""
		report.content.add_child(UiTheme.label("Proviant %d → %d%s" % [rep.prov0, rep.prov1, kt], 15, UiTheme.BAD if int(rep.prov1) <= 0 else UiTheme.TEXT))
	if rep.get("defend", false):
		report.content.add_child(UiTheme.label("Entern abgewehrt: der Raumkampf ist gewonnen." if win else "Die Gegner haben das Schiff übernommen.", 15,
			UiTheme.GOOD if win else UiTheme.BAD))
	if String(rep.get("next", "")) == "ground":
		var gl := UiTheme.label("Die Blockade ist durchbrochen: weiter zum Bodeneinsatz. In der Einsatzbesprechung den Trupp neu wählen (Verwundete können an Bord bleiben).", 15, UiTheme.ACCENT)
		gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		report.content.add_child(gl)
	if not rep.get("plunder", {}).is_empty():
		_plunder_box(report.content, rep.plunder)
	_payout(rep)
	_loot(HubState.game)
	var go := UiTheme.button("Zu den Crewquartieren")
	go.add_theme_color_override("font_color", UiTheme.ACCENT)
	go.pressed.connect(func() -> void:
		report.hide()
		action.emit(&"room", &"quarters"))
	report.footer.add_child(go)
	report.add_close()


## Lohn und Beute im Einsatzbericht (HubState.finish_mission → rep.payout)
func _payout(rep: Dictionary) -> void:
	if not rep.has("payout"):
		return
	var used: Dictionary = rep.get("ammo_used", {})
	if not used.is_empty():
		var parts := []
		for t in used:
			parts.append("%s −%d" % [Ammo.TYPES.get(StringName(t), t), used[t]])
		report.content.add_child(UiTheme.label("Munitionsverbrauch: " + ", ".join(parts), 14))
	report.content.add_child(UiTheme.label("LOHN UND BEUTE", 13, UiTheme.MUTED))
	var p: Dictionary = rep.payout
	if rep.get("story", false):
		# Story-Einsatz: kein Lohn (Entscheidung des Nutzers 19.10.2026), Belohnung in der Folgeszene
		report.content.add_child(UiTheme.label("Story-Einsatz: kein Lohn; was er bringt, zeigt die Folgeszene.", 14, StoryDialog.STORY_COLOR))
		if int(rep.get("medkits", 0)) > 0:
			report.content.add_child(UiTheme.label("Beute: Medikits (ins Lager) +%d" % int(rep.medkits), 15, UiTheme.GOOD))
		return
	if rep.has("board"):
		# Entern (selbst oder abgewehrt): Beute des Schiffs, Lohn eines Abfang-Auftrags, Medikits aus dem Bodenkampf
		if int(rep.get("pay", 0)) > 0:
			report.content.add_child(UiTheme.label("Auftragslohn +%d Cr" % int(rep.pay), 15, UiTheme.GOOD))
		report.content.add_child(_board_label(rep))
		if int(rep.get("medkits", 0)) > 0:
			report.content.add_child(UiTheme.label("Beute: Medikits (ins Lager) +%d" % int(rep.medkits), 15, UiTheme.GOOD))
		return
	if p.is_empty():
		report.content.add_child(UiTheme.label("Niederlage oder Rückzug: kein Lohn, keine Beute.", 14, UiTheme.MUTED))
		return
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 40)
	g.add_child(UiTheme.label("Missionslohn (%s)" % p.difficulty, 15))
	g.add_child(UiTheme.label("%d Cr" % p.pay, 15))
	if int(p.bonus) != 0:
		g.add_child(UiTheme.label("Fraktion: %s ×%s" % [rep.get("faction", ""), str(p.factor).replace(".", ",")], 15))
		g.add_child(UiTheme.label("%+d Cr" % p.bonus, 15))
	g.add_child(UiTheme.label("Beute: Schiffsmaterial", 15))
	g.add_child(UiTheme.label("+%d" % p.loot, 15))
	for t in p.get("ammo", {}):
		g.add_child(UiTheme.label("Beute: %s" % Ammo.TYPES.get(StringName(t), t), 15))
		g.add_child(UiTheme.label("+%d" % p.ammo[t], 15))
	if int(p.get("medkits", 0)) > 0:
		g.add_child(UiTheme.label("Beute: Medikits (ins Lager)", 15))
		g.add_child(UiTheme.label("+%d" % p.medkits, 15))
	g.add_child(UiTheme.label("Credits", 15, UiTheme.ACCENT))
	g.add_child(UiTheme.label("%d → %d Cr" % [p.credits0, p.credits1], 15, UiTheme.ACCENT))
	report.content.add_child(g)


## Beuteauswahl nur zeigen (z. B. nach dem Laden eines Spielstands mit offener Beute)
func show_loot(g: HubState) -> void:
	report.open("Beute auswählen")
	_loot(g)
	report.add_close("Beute übernehmen")


## gewählte Beute (Indizes in HubState.loot_pending.items); leer und _loot_open = false: keine Auswahl offen
var _loot_picks: Array[int] = []
var _loot_open := false


## Abschnitt „Beute auswählen“: 1 Stück je Crewmitglied im Einsatz, Rest als Schrott (Mockup Bildschirm 27)
func _loot(g: HubState) -> void:
	_loot_open = false
	if g == null or g.loot_pending.is_empty():
		return
	_loot_open = true
	var items: Array = g.loot_pending.items
	var slots := int(g.loot_pending.slots)
	_loot_picks = g.loot_default()
	var head := HBoxContainer.new()
	var t := UiTheme.label("BEUTE AUSWÄHLEN", 13, UiTheme.MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var count := UiTheme.label("", 15)
	head.add_child(count)
	report.content.add_child(head)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	for h in ["", "Stück", "Zustand", "Schrottwert"]:
		grid.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	var boxes: Array[CheckBox] = []
	var scrap := UiTheme.label("", 15, UiTheme.ACCENT)
	var update := func() -> void:
		var full := _loot_picks.size() >= slots
		var sum := 0
		for i in boxes.size():
			boxes[i].set_pressed_no_signal(i in _loot_picks)
			boxes[i].disabled = full and not i in _loot_picks
			if not i in _loot_picks:
				sum += Stock.scrap_value(items[i])
		count.text = "Mitnehmen %d / %d (1 Stück je Crewmitglied im Einsatz)" % [_loot_picks.size(), slots]
		scrap.text = "Nicht Mitgenommenes als Schrott verkauft (%d Stück): +%d Cr" % [items.size() - _loot_picks.size(), sum]
	for i in items.size():
		var key: String = items[i]
		var d := Stock.damage_of(key)
		var b := CheckBox.new()
		b.toggled.connect(func(on: bool) -> void:
			if on and not i in _loot_picks:
				_loot_picks.append(i)
			elif not on:
				_loot_picks.erase(i)
			Sfx.play(&"klick")
			update.call())
		boxes.append(b)
		grid.add_child(b)
		grid.add_child(UiTheme.label(Stock.name_of(Stock.base_of(key)), 15))
		grid.add_child(UiTheme.label("intakt" if d == 0 else Stock.damage_text(d).strip_edges().trim_prefix("(").trim_suffix(")"), 15,
			UiTheme.GOOD if d == 0 else (UiTheme.BAD if d <= Combatant.WEAR_BROKEN else Color("ff8a3d"))))
		grid.add_child(UiTheme.label("%d Cr" % Stock.scrap_value(key), 15, UiTheme.MUTED))
	report.content.add_child(grid)
	report.content.add_child(scrap)
	var note := UiTheme.label("Mitgenommenes kommt mit seinem Schaden ins Lager. Schrottwert %d %% vom Kaufpreis, unbrauchbar (−30) 0 Cr. Die Auswahl gilt beim Schließen des Berichts." % roundi(Stock.SCRAP_SHARE * 100), 13, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report.content.add_child(note)
	update.call()


## Bericht geschlossen (egal wie): offene Beuteauswahl übernehmen
func _on_report_visibility() -> void:
	if report.visible or not _loot_open:
		return
	_loot_open = false
	var g := HubState.game
	if g and not g.loot_pending.is_empty():
		loot_taken.emit(g.take_loot(_loot_picks))


## Reisebericht nach jeder Reise: Proben je Tag, Treibstoff, Hülle, EP
func show_travel(rep: Dictionary) -> void:
	travel_report.open("Reise nach %s" % rep.to)
	travel_report.content.add_child(UiTheme.label("Tag %d → %d · %d %s" % [rep.day0, rep.day0 + rep.days, rep.days,
		"Reisetag" if rep.days == 1 else "Reisetage"], 14, UiTheme.MUTED))
	var g := GridContainer.new()
	var cook: Array = rep.get("cook", [])
	g.columns = 3 + Voyage.POSTS.size() + (1 if not cook.is_empty() else 0)
	g.add_theme_constant_override("h_separation", 18)
	g.add_theme_constant_override("v_separation", 6)
	g.add_child(UiTheme.label("Tag", 12, UiTheme.MUTED))
	for p in Voyage.POSTS:
		g.add_child(UiTheme.label(p.name, 12, UiTheme.MUTED))
	g.add_child(UiTheme.label("Treibstoff", 12, UiTheme.MUTED))
	g.add_child(UiTheme.label("Hülle", 12, UiTheme.MUTED))
	if not cook.is_empty():
		g.add_child(UiTheme.label("Kochen", 12, UiTheme.MUTED))
	var xp := {}
	for ri in rep.rows.size():
		var row: Dictionary = rep.rows[ri]
		g.add_child(UiTheme.label(str(row.day), 14))
		for c in row.checks:
			if c.is_empty():
				g.add_child(UiTheme.label("unbesetzt", 14, UiTheme.MUTED))
				continue
			var l := UiTheme.label("%s\n%s %s = %s %s" % [c.name, Dice.format_roll(c.roll), Dice.fmt(c.bonus), str(c.total).replace("-", "−"), c.result_name], 13, result_color(c.result))
			g.add_child(l)
			add_xp(xp, c.name, c.skill, int(c.xp))
		g.add_child(UiTheme.label(Dice.fmt(row.fuel) if row.fuel != 0 else "±0", 14))
		g.add_child(UiTheme.label(Dice.fmt(row.hull) if row.hull != 0 else "±0", 14, UiTheme.GOOD if row.hull > 0 else (UiTheme.BAD if row.hull < 0 else UiTheme.TEXT)))
		if not cook.is_empty():
			var e: Dictionary = cook[ri] if ri < cook.size() else {}
			g.add_child(UiTheme.label(cook_text(e), 13, cook_color(e)))
			if not e.is_empty():
				add_xp(xp, String(e.cook), Galley.SKILL, int(e.xp))
	travel_report.content.add_child(g)
	var sum := "Treibstoff %d → %d" % [rep.fuel0, rep.fuel1]
	if rep.emergency:
		sum += " (Notsprit)"
	else:
		sum += " (%s statt %s)" % [Dice.fmt(rep.fuel1 - rep.fuel0), Dice.fmt(-int(rep.get("per_day", Voyage.FUEL_PER_DAY)) * rep.days)]
	sum += "   ·   Hülle %d → %d" % [rep.hull0, rep.hull1]
	if rep.has("prov0"):
		sum += "   ·   Proviant %d → %d" % [rep.prov0, rep.prov1]
	travel_report.content.add_child(UiTheme.label(sum, 16, UiTheme.ACCENT))
	var ct: Dictionary = rep.get("contact", {})
	if not ct.is_empty():
		travel_report.content.add_child(UiTheme.label("Feindkontakt an Reisetag %d bei %s: %s%s" % [int(rep.days), rep.to,
			SpaceTemplates.faction_name(String(ct.faction)), " (Eskorte)" if ct.get("forced", false) else ""], 15, UiTheme.BAD))
	var esc: Dictionary = rep.get("escort", {})
	if not esc.is_empty():
		travel_report.content.add_child(UiTheme.label("%s: erfüllt, Lohn +%d Cr" % [esc.title, esc.pay] if int(esc.pay) > 0
			else "%s: nicht erfüllt (Flucht), der Auftrag bleibt offen" % esc.title, 15, UiTheme.GOOD if int(esc.pay) > 0 else UiTheme.RETREAT))
	var out_day := empty_day(cook)
	if out_day > 0:
		travel_report.content.add_child(UiTheme.label("Proviant aufgebraucht an Tag %d – ab jetzt %d auf Proben im Schiff, bis wieder Proviant gekauft ist." % [out_day, Galley.MALUS], 14, UiTheme.BAD))
	if int(rep.get("training", 0)) > 0:
		travel_report.content.add_child(UiTheme.label("Training: +%d freie EP für alle an Bord" % rep.training, 15, UiTheme.GOOD))
	add_events(travel_report.content, rep, xp)
	if rep.fuel1 <= 0 and not rep.emergency:
		travel_report.content.add_child(UiTheme.label("Tank leer: Notsprit. Weiter nur zum nächsten Hafen; dort kostet das Tanken das Doppelte.", 14, UiTheme.BAD))
	travel_report.content.add_child(UiTheme.label("ERFAHRUNG", 13, UiTheme.MUTED))
	travel_report.content.add_child(xp_list(xp))
	var rule := UiTheme.label("Grundverbrauch %d je Reisetag. Pilot, Navigation, Computer: Teilerfolg −1, Erfolg −2, Herausragend −4, mindestens %d je Tag. Reparatur: Patzer −10, Fehlschlag −5, Teilerfolg ±0, Erfolg +2, Herausragend +4 Hülle." % [
		int(rep.get("per_day", Voyage.FUEL_PER_DAY)), Voyage.FUEL_MIN], 12, UiTheme.MUTED)
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	travel_report.content.add_child(rule)
	var ok := UiTheme.button("Weiter")
	ok.add_theme_color_override("font_color", UiTheme.ACCENT)
	ok.pressed.connect(travel_report.close)
	travel_report.footer.add_child(ok)
	travel_report.move_to_front()


## Entern: Beute des geenterten Schiffs (nur bei Sieg verbucht)
func _board_label(rep: Dictionary) -> Label:
	var loot: Dictionary = rep.get("board_loot", {})
	var who := "Enterschiff" if rep.get("defend", false) else "Entern der"
	var t := "%s %s: " % [who, String(rep.board)] if String(rep.board) != "" else ("Enterschiff: " if rep.get("defend", false) else "Entern: ")
	if loot.is_empty():
		t += "Besatzung nicht besiegt, keine Beute aus dem Schiff."
	else:
		var parts := ["+%d Cr" % int(loot.get("credits", 0)), "+%d Schiffsmaterial" % int(loot.get("material", 0))]
		var am: Dictionary = loot.get("ship_ammo", {})
		for k in am:
			parts.append("+%d %s" % [int(am[k]), ShipArms.AMMO_NAMES.get(k, k)])
		for w in loot.get("weapons", []):
			parts.append(ShipArms.label(Stock.damaged_key(String(w.key), int(w.get("damage", 0)))) + " ins Schiffslager")
		t += "Beute " + ", ".join(parts)
	var l := UiTheme.label(t, 15, UiTheme.GOOD if not loot.is_empty() else UiTheme.BAD)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## Kochprobe eines Tages kurz: „Ikko: Erfolg (5)“ / „ohne Koch (6)“
static func cook_text(e: Dictionary) -> String:
	if e.is_empty():
		return "–"
	var who := (String(e.cook).split(" ")[0] + ": ") if String(e.cook) != "" else ""
	return "%s%s (%d)" % [who, e.result_name, int(e.use)]


static func cook_color(e: Dictionary) -> Color:
	return result_color(StringName(e.get("result", "")))


## Farbe eines Probenergebnisses, überall gleich (Entscheidung des Nutzers 16.10.2026, wie die Reisetabelle):
## Patzer rot, Fehlschlag weiß, Teilerfolg gelb, Erfolg und Herausragend grün
static func result_color(res: StringName) -> Color:
	match res:
		&"erfolg", &"herausragend":
			return UiTheme.GOOD
		&"teilerfolg":
			return UiTheme.ACCENT
		&"patzer":
			return UiTheme.BAD
	return UiTheme.TEXT


## EP sammeln je Figur (Vorname) und Fertigkeit: {Figur: {Fertigkeitsname: EP}}
static func add_xp(xp: Dictionary, who: String, skill: StringName, n: int) -> void:
	if n <= 0 or who == "":
		return
	var k := who.split(" ")[0]
	if not xp.has(k):
		xp[k] = {}
	var sk := Rules.skill_name(skill)
	xp[k][sk] = int(xp[k].get(sk, 0)) + n


## Erfahrung je Figur eine Zeile („Tulin: Pilot +2 · Kochen +1“), ab 5 Figuren in 2 Spalten
static func xp_list(xp: Dictionary) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2 if xp.size() > 4 else 1
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 2)
	if xp.is_empty():
		grid.add_child(UiTheme.label("–", 14))
	for who in xp:
		var parts := []
		for sk in xp[who]:
			parts.append("%s +%d" % [sk, xp[who][sk]])
		var l := UiTheme.label("%s: %s" % [who, " · ".join(parts)], 14)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 520
		grid.add_child(l)
	return grid


## Meldungen von Schiffsausbau und Werkstatt farbig nach Ergebnis; ihre EP kommen in xp
static func add_events(parent: Control, rep: Dictionary, xp: Dictionary) -> void:
	for spec in [["upgrade", "Schiffsausbau"], ["crafts", "Werkstatt"]]:
		for e in rep.get(spec[0], []):
			var l := UiTheme.label("%s: %s" % [e.get("label", spec[1]), e.get("text", "")], 15, result_color(StringName(e.get("result", ""))))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			parent.add_child(l)
			add_xp(xp, String(e.get("name", "")), StringName(e.get("skill", "")), int(e.get("xp", 0)))


## Meldung nach „1 Tag warten“ oder Crew-Reparatur: Schiffsausbau und Werkstatt farbig, mit Erfahrung
func show_events(upgrade: Array, crafts: Array) -> void:
	notice.max_size = Vector2(1180, 640)
	var labels := []
	if not upgrade.is_empty():
		labels.append("Schiffsausbau")
	for e in crafts:
		var lb := String(e.get("label", "Werkstatt"))
		if not lb in labels:
			labels.append(lb)
	notice.open(" und ".join(labels))
	var xp := {}
	add_events(notice.content, {"upgrade": upgrade, "crafts": crafts}, xp)
	if not xp.is_empty():
		notice.content.add_child(UiTheme.label("ERFAHRUNG", 13, UiTheme.MUTED))
		notice.content.add_child(xp_list(xp))
	notice.add_close()
	notice.move_to_front()


## erster Tag, an dem der Proviant ausging (0 = nicht ausgegangen)
static func empty_day(cook: Array) -> int:
	for e in cook:
		if bool(e.get("empty", false)) and int(e.p0) > 0:
			return int(e.day)
	return 0


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
	return star_map.visible or crew.visible or sheet.visible or slots.visible or report.visible or notice.visible or help.visible or medbay.visible or galley.visible or armory.visible or travel_report.visible or engine.visible or trade.visible or craft.visible or ship_arms.visible or port.visible or contact.visible or space_report.visible \
		or (has_node(Encyclopedia.NAME) and get_node(Encyclopedia.NAME).visible) or (has_node(StoryLog.NAME) and get_node(StoryLog.NAME).visible) \
		or (has_node(StoryDialog.NAME) and get_node(StoryDialog.NAME).visible)


func close_dialogs() -> bool:
	var enc := get_node_or_null(Encyclopedia.NAME)
	if enc and enc.visible:
		enc.close()
		return true
	var lg := get_node_or_null(StoryLog.NAME)
	if lg and lg.visible:
		lg.close()
		return true
	for d in [sheet, help, notice, slots, report, medbay, galley, armory, travel_report, engine, trade, craft, ship_arms, port, contact, space_report]:
		if d.visible:
			d.close()
			return true
	if star_map.visible:
		star_map.close()
		return true
	return false


## liegt der Punkt auf der Oberfläche (nicht auf dem Deck)?
## Drehpfeil ⟲ (links) oder ⟳ (rechts) auf einem Knopf
static func _draw_turn(b: Button, left: bool) -> void:
	var c := b.size / 2.0
	var r := 10.0
	var a0 := -PI * 0.9 if left else -PI * 0.1
	var a1 := a0 + (PI * 1.5 if not left else -PI * 1.5)
	b.draw_arc(c, r, minf(a0, a1), maxf(a0, a1), 24, UiTheme.TEXT, 2.0, true)
	var tip := c + Vector2(cos(a0), sin(a0)) * r
	var tang := Vector2(-sin(a0), cos(a0)) * (1.0 if left else -1.0)
	var side := (tip - c).normalized()
	b.draw_colored_polygon(PackedVector2Array([tip + tang * 5.0, tip + side * 5.0 - tang * 2.0, tip - side * 5.0 - tang * 2.0]), UiTheme.TEXT)


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


# ---------------------------------------------------------------- Raumkampf im Spiel (Mockup Bildschirme 42–44)

## Feindkontakt auf der Reise: Gegner, Wahl ausweichen (Probe Navigation) oder kämpfen
func show_contact(g: HubState) -> void:
	var ct := g.contact
	var f := SpaceTemplates.faction(String(ct.faction))
	contact.max_size = Vector2(1100, 640)
	contact.closable = false
	contact.open("Feindkontakt bei %s" % g.sector.systems[int(ct.system)].name)
	var head := UiTheme.label("Sensoren melden Schiffe: %s (%s). Feindkontakt %d %% je Reisetag in diesem Gebiet." % [f.name, ct.difficulty,
		roundi(SpaceEvents.contact_chance(g, int(ct.system)) * 100)], 16, UiTheme.ACCENT)
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contact.content.add_child(head)
	contact.content.add_child(UiTheme.label("Nimmt Lösegeld: %s · Bei Niederlage der Crew: %s" % ["%d Cr" % int(f.ransom) if int(f.ransom) > 0 else "nein",
		"entern → Bodenkampf an Bord" if String(f.on_win) == "entern" else "Plünderung, das Schiff treibt"], 14, UiTheme.MUTED))
	var nav := SpaceEvents.navigator(g)
	var bonus := Rules.skill_total(nav, SpaceEvents.DODGE_SKILL) + int(Rules.DIFFICULTY[Voyage.DIFF].mod) + g.travel_bonus() + Galley.malus(g) \
		+ ShipArms.travel_malus(g, SpaceEvents.DODGE_SKILL) if nav else 0
	_choice_box(contact.content, "Ausweichen: Probe Navigation (%s)" % ("%s, %s, mittel" % [nav.name, Dice.fmt(bonus)] if nav else "niemand"),
		"Erfolg oder Herausragend: ausgewichen, die Reise geht weiter. Sonst: Raumkampf.", "Ausweichen versuchen", nav != null,
		func() -> void:
			contact.hide()
			contact_choice.emit(false))
	_choice_box(contact.content, "Kämpfen", "Raumkampf. Danach geht die Reise mit den übrigen Tagen weiter; Flucht per Sprung: Reise geht weiter, keine Beute.",
		"Zum Raumkampf", true, func() -> void:
			contact.hide()
			contact_choice.emit(true))
	contact.move_to_front()


func _choice_box(parent: Control, title: String, text: String, action: String, ok: bool, act: Callable) -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	v.add_child(UiTheme.label(title, 16))
	var l := UiTheme.label(text, 13, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var b := UiTheme.button(action)
	b.add_theme_color_override("font_color", UiTheme.ACCENT)
	b.disabled = not ok
	b.custom_minimum_size.y = 40
	b.pressed.connect(act)
	v.add_child(b)
	parent.add_child(p)


## Bericht nach dem Raumkampf: Ausgang, Schiff, Figuren, Lohn und Beute, Notfall
func show_space_report(rep: Dictionary) -> void:
	space_report.max_size = Vector2(1200, 760)
	var out := StringName(rep.get("outcome", &"niederlage"))
	var name := "Sieg" if out == &"sieg" else ("Flucht" if rep.get("retreated", false) else ("Kapitulation" if rep.get("surrendered", false)
		else ("Gegner entern" if rep.get("next", "") == "defend" else "Niederlage – Notfall")))
	space_report.open("Einsatzbericht: %s – %s (Raumkampf)" % [name, rep.get("title", "")])
	space_report.content.add_child(UiTheme.label("%s · %d Runden · Tag %d" % [rep.get("faction", ""), int(rep.get("rounds", 0)), int(rep.get("day", 0))], 14, UiTheme.MUTED))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	space_report.content.add_child(cols)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	left.add_child(UiTheme.label("SCHIFF", 13, UiTheme.MUTED))
	left.add_child(UiTheme.label("Hülle %d → %d" % [int(rep.get("hull0", 0)), int(rep.get("hull1", 0))], 15,
		UiTheme.BAD if int(rep.get("hull1", 0)) < int(rep.get("hull0", 0)) else UiTheme.TEXT))
	var nd: Dictionary = rep.get("new_damage", {})
	if not nd.is_empty():
		var l := UiTheme.label("Neue Systemschäden: " + ", ".join(nd.keys().map(func(k) -> String: return "%s %s" % [ShipArms.system_name(k), nd[k]]))
			+ " · Reparatur im Maschinenraum oder in der Werft", 14, Color("ff8a3d"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(l)
	var used: Dictionary = rep.get("ammo_used", {})
	var parts := []
	for t in used:
		parts.append("%s −%d" % [ShipArms.AMMO_NAMES.get(t, t), int(used[t])])
	if int(rep.get("fuel_used", 0)) > 0:
		parts.append("Treibstoff −%d" % int(rep.fuel_used))
	if not parts.is_empty():
		left.add_child(UiTheme.label("Verbrauch: " + ", ".join(parts), 14))
	left.add_child(UiTheme.label("FIGUREN", 13, UiTheme.MUTED))
	for u in rep.get("units", []):
		var ul := UiTheme.label("%s %s · %s%s" % [u.letter, u.name, u.state, (" · " + u.xp) if String(u.xp) != "" else ""], 14,
			UiTheme.TEXT if String(u.state).begins_with("kampffähig") else Color("ff8a3d"))
		ul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(ul)
	right.add_child(UiTheme.label("LOHN UND BEUTE", 13, UiTheme.MUTED))
	if int(rep.get("pay", 0)) > 0:
		right.add_child(UiTheme.label("Lohn +%d Cr" % int(rep.pay), 15, UiTheme.GOOD))
	var loot: Dictionary = rep.get("loot", {})
	if not loot.is_empty():
		var lp := ["+%d Cr" % int(loot.get("credits", 0)), "+%d Schiffsmaterial" % int(loot.get("material", 0))]
		var la: Dictionary = loot.get("ship_ammo", {})
		for t in la:
			lp.append("%s +%d" % [ShipArms.AMMO_NAMES.get(t, t), int(la[t])])
		var ll := UiTheme.label("Kampfbeute: " + ", ".join(lp), 15, UiTheme.GOOD)
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		right.add_child(ll)
		for w in loot.get("weapons", []):
			right.add_child(UiTheme.label("%s ins Schiffslager" % ShipArms.label(Stock.damaged_key(String(w.key), int(w.get("damage", 0)))), 15, UiTheme.GOOD))
	var ransom: Dictionary = rep.get("ransom", {})
	if not ransom.is_empty():
		right.add_child(UiTheme.label("Lösegeld bezahlt: %d Cr" % int(ransom.get("credits", 0)), 15, UiTheme.BAD))
	if rep.get("retreated", false):
		right.add_child(UiTheme.label("Flucht per Sprung: keine Beute; ein Auftrag bleibt offen.", 15, UiTheme.RETREAT))
	if int(rep.get("pay", 0)) == 0 and loot.is_empty() and ransom.is_empty() and not rep.get("retreated", false):
		right.add_child(UiTheme.label("–", 14, UiTheme.MUTED))
	if not rep.get("plunder", {}).is_empty():
		_plunder_box(right, rep.plunder)
	var nx := String(rep.get("next", ""))
	if nx != "":
		var nt: String = {"ground": "Die Blockade ist durchbrochen: weiter zum Bodeneinsatz.", "board": "Die Crew entert das Gegnerschiff: Bodenkampf gegen die Besatzung.",
			"defend": "Die Gegner entern: Bodenkampf an Bord. Gewinnt die Crew, ist der Raumkampf gewonnen (mit der Beute des Enterschiffs); verliert sie, wird das Schiff geplündert und treibt."}[nx]
		var nl := UiTheme.label(nt, 15, UiTheme.ACCENT)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		space_report.content.add_child(nl)
	var ok := UiTheme.button("Weiter")
	ok.add_theme_color_override("font_color", UiTheme.ACCENT)
	ok.pressed.connect(func() -> void:
		space_report.hide()
		space_report_closed.emit())
	space_report.footer.add_child(ok)
	space_report.closable = false
	space_report.move_to_front()


## Notfall: was geplündert wurde, das Schiff treibt
func _plunder_box(parent: Control, p: Dictionary) -> void:
	parent.add_child(UiTheme.label("PLÜNDERUNG", 13, UiTheme.MUTED))
	var parts := ["−%d Cr" % int(p.get("credits", 0))]
	var am: Dictionary = p.get("ship_ammo", {})
	for t in am:
		parts.append("%s −%d" % [ShipArms.AMMO_NAMES.get(t, t), int(am[t])])
	for it in p.get("items", []):
		parts.append(String(it))
	var l := UiTheme.label(", ".join(parts), 15, UiTheme.BAD)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)
	var t := UiTheme.label("Das Schiff treibt: Hülle 0, nur noch Kurs zum nächsten Hafen.", 15, UiTheme.BAD)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(t)
