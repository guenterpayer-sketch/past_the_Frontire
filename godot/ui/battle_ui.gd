class_name BattleUI
extends Control
## Oberfläche als schwebende Kästen über der Karte (die Karte nutzt den ganzen Bildschirm), Variante C
## (Entscheidung Nutzer 15.10.2026): oben links Initiative, oben rechts Menü; darunter rechts eine **Seitenleiste**
## (Figurenkarte, Aktionen in einklappbaren Abschnitten, „Zug beenden“), selbst einklappbar; links daneben der
## Infokasten; unten links Würfel und Kampflog (eingeklappt eine Zeile).

signal action(name: StringName, arg: Variant)

const MARGIN := 14.0
const GAP := 8.0
const SIDE_W := 290.0

var top_menu: TopMenu
var info: InfoBox
var initiative: InitiativeBar
var dice_panel: DicePanel
var combat_log: CombatLog
var card: UnitCard           # Seitenleiste: eigene Figur
var ai_card: UnitCard        # Seitenleiste: Figur unter KI-Steuerung
var actions: ActionPanel
var sheet: SheetDialog
var briefing: BriefingDialog
var help: Modal
## Waffenkammer im Briefing beim Entern (Charakter-Modul, nur aufgerufen; Bodenkampf Auftrag 2)
var armory: ArmoryDialog
var result_banner: ResultBanner
var active_tag: ActiveTag
var context_menu: ContextMenu
var _confirm: ConfirmationDialog
var side: PanelContainer     # Seitenleiste rechts
var _fold: Button            # Seitenleiste ein-/ausklappen
var _left: VBoxContainer


func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	initiative = InitiativeBar.new()
	initiative.focus_unit.connect(func(u: Combatant) -> void: action.emit(&"focus", u))
	initiative.jump.connect(func(u: Combatant) -> void: action.emit(&"jump", u))
	add_child(initiative)

	top_menu = TopMenu.new()
	top_menu.action.connect(func(n: StringName, a: Variant) -> void: action.emit(n, a))
	add_child(top_menu)
	info = InfoBox.new()
	info.confirm.connect(func() -> void: action.emit(&"confirm", null))
	add_child(info)

	_left = _stack(true)
	dice_panel = DicePanel.new()
	dice_panel.custom_minimum_size.x = 360
	dice_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_left.add_child(dice_panel)
	combat_log = CombatLog.new()
	_left.add_child(combat_log)

	side = PanelContainer.new()
	side.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.94), UiTheme.LINE, 10, 10))
	side.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(side)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 6)
	side.add_child(sv)
	card = UnitCard.new()
	card.action.connect(func(n: StringName, a: Variant) -> void: action.emit(n, a))
	sv.add_child(card)
	ai_card = UnitCard.new()
	sv.add_child(ai_card)
	actions = ActionPanel.new()
	actions.action.connect(func(n: StringName, a: Variant) -> void: action.emit(n, a))
	sv.add_child(actions)
	_fold = UiTheme.button("›", "Seitenleiste einklappen")
	_fold.custom_minimum_size = Vector2(26, 44)
	_fold.pressed.connect(func() -> void: set_side_open(not side.visible))
	add_child(_fold)
	set_side_open(Prefs.get_bool("side_open", true))

	sheet = SheetDialog.new()
	briefing = BriefingDialog.new()
	help = Modal.new()
	armory = ArmoryDialog.new()
	for d in [sheet, briefing, help, armory]:
		add_child(d)
	active_tag = ActiveTag.new()
	add_child(active_tag)
	move_child(active_tag, 0)   # unter allen Kästen und Dialogen
	context_menu = ContextMenu.new()
	add_child(context_menu)
	result_banner = ResultBanner.new()
	add_child(result_banner)
	_confirm = ConfirmationDialog.new()
	_confirm.cancel_button_text = "Abbrechen"
	add_child(_confirm)
	briefing.reroll.connect(func(diff: String) -> void: action.emit(&"reroll", diff))
	combat_log.set_expanded(Prefs.get_bool("log_open", false))
	combat_log.toggled.connect(func(on: bool) -> void: Prefs.set_bool("log_open", on))


## senkrechter Stapel schwebender Kästen; Position setzt _process an die jeweilige Ecke
func _stack(bottom: bool) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", GAP)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.alignment = BoxContainer.ALIGNMENT_END if bottom else BoxContainer.ALIGNMENT_BEGIN
	add_child(v)
	return v


## Seitenleiste ein- oder ausklappen (gespeichert); eingeklappt bleibt nur der Knopf am Rand (Enter beendet den Zug)
func set_side_open(on: bool) -> void:
	side.visible = on
	_fold.text = "›" if on else "‹"
	_fold.tooltip_text = "Seitenleiste einklappen" if on else "Seitenleiste ausklappen (Aktionen, Zug beenden)"
	Prefs.set_bool("side_open", on)


func _process(_d: float) -> void:
	# Stapel passen sich ihrem Inhalt an (Karten werden bei jedem Zug neu gefüllt)
	_left.reset_size()
	top_menu.reset_size()
	info.reset_size()
	_place(_left, Vector2(MARGIN, size.y - MARGIN - _left.size.y))
	_place(top_menu, Vector2(size.x - MARGIN - top_menu.size.x, MARGIN))
	var top := MARGIN + top_menu.size.y + GAP
	var side_x := size.x - MARGIN - SIDE_W
	_place(side, Vector2(side_x, top))
	# ohne Aktionen (Gegner/KI am Zug) nur so hoch wie die Figurenkarte
	var side_size := Vector2(SIDE_W, size.y - top - MARGIN if actions.visible else side.get_combined_minimum_size().y)
	if side.size != side_size:
		side.size = side_size
	_place(_fold, Vector2((side_x if side.visible else size.x - MARGIN) - _fold.size.x, top + 16))
	var info_right := (side_x if side.visible else size.x - MARGIN) - _fold.size.x - GAP
	_place(info, Vector2(info_right - info.size.x, top))
	if result_banner.visible:
		result_banner.reset_size()
		_place(result_banner, (size - result_banner.size) / 2.0)
	initiative.position = Vector2(MARGIN, MARGIN)
	initiative.size = Vector2(maxf(200.0, size.x - top_menu.size.x - MARGIN * 3), 44)


func _place(v: Control, p: Vector2) -> void:
	if v.position != p:
		v.position = p


func set_toggle(name: StringName, on: bool, tip := "") -> void:
	top_menu.set_toggle(name, on, tip)


func any_dialog_open() -> bool:
	var enc := encyclopedia()
	return sheet.visible or briefing.visible or help.visible or armory.visible or (enc != null and enc.visible) or _confirm.visible


func close_dialogs() -> bool:
	if context_menu.visible:
		context_menu.hide()
		return true
	for d in [encyclopedia(), sheet, briefing, help]:
		if d and d.visible:
			d.close()
			return true
	return false


## Enzyklopädie des Hubs (ersetzt seit 16.10.2026 den Dialog „Tabellen“); null, solange sie nie geöffnet wurde
func encyclopedia() -> Encyclopedia:
	return get_node_or_null(Encyclopedia.NAME) as Encyclopedia


## Enzyklopädie öffnen; w = gewählte Waffe (Psi-Angriffskraft → ihre Psi-Liste), null = Bereich Waffen
func show_encyclopedia(w: WeaponData = null) -> void:
	if w and w.power != "":
		Encyclopedia.show_on(self, &"psi", PsiLists.LISTS[PsiCombat.list_of(w.power)].name)
	else:
		Encyclopedia.show_on(self, &"waffen", w.name if w else "")


func show_help() -> void:
	help.open("Bedienung")
	var l := UiTheme.label("""Maus über ein blaues Feld: Vorschau im Infokasten oben (links neben der Seitenleiste). Grüne Linien/Ringe = von dort treffbar, rote = wer dich dort treffen kann.
Blaues Feld anklicken: bewegen (Gangart in der Seitenleiste rechts; Abschnitte per Klick auf die Überschrift ein-/ausklappen, „›“ klappt die ganze Leiste ein). Rot umrandeten Gegner anklicken: angreifen (Aktivität 20–100 %).
Rechtsklick: Figur drehen. Sichtfeld 180° nach vorne – Angriffe von der Seite (+15) oder hinten (+30) überraschen.
Kamera: ziehen (links/Mitte), WASD/Pfeile, Mausrad = Zoom, Q/E = um 90° drehen. Enter oder Tab = Zug beenden (Aufstellung: Tab/Shift+Tab = nächste/vorige Figur, Enter = Kampf beginnen), F/Shift+F = sichtbare Gegner durchschalten, Leertaste = gewählten Gegner angreifen, R = Reichweite, G = Raster, Esc = abbrechen.
Handy/Tablet: ziehen = verschieben, zwei Finger = zoomen, antippen = Vorschau, „Ausführen“ im Infokasten oder nochmal antippen = ausführen, lange drücken = drehen.""", 15)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.content.add_child(l)
	help.add_close()


## Infokasten oben rechts (ersetzt den Tooltip an der Maus); touch: mit Knopf "Ausführen"
func show_tip(bbcode: String, _at := Vector2.ZERO, touch := false) -> void:
	info.show_info(bbcode, touch)


func hide_tip() -> void:
	info.show_info("")


## liegt der Punkt auf der Oberfläche (nicht auf der Karte)?
func covers(p: Vector2) -> bool:
	if any_dialog_open():
		return true
	for c in [top_menu, info, dice_panel, combat_log, side, _fold, result_banner, context_menu]:
		if c.visible and c.get_global_rect().has_point(p):
			return true
	for c in initiative.get_children():
		if c.get_global_rect().has_point(p):
			return true
	return false


## Sicherheitsabfrage; on_ok wird nur bei Bestätigung aufgerufen
func ask(text: String, ok_text: String, on_ok: Callable) -> void:
	for c in _confirm.confirmed.get_connections():
		_confirm.confirmed.disconnect(c.callable)
	_confirm.dialog_text = text
	_confirm.ok_button_text = ok_text
	_confirm.confirmed.connect(on_ok, CONNECT_ONE_SHOT)
	_confirm.popup_centered()


## Einstellung UI-Größe (Funktion des Hubs, gilt fürs ganze Spiel, sofort)
func show_ui_scale() -> void:
	help.open("UI-Größe")
	var l := UiTheme.label("Größe der Oberfläche für das ganze Spiel (gespeichert). Die Karte bleibt gleich.", 14, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.content.add_child(l)
	help.content.add_child(UiScale.picker(get_tree()))
	help.add_close()
