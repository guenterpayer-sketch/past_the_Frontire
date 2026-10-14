class_name BattleUI
extends Control
## Oberfläche als schwebende Kästen über der Karte (die Karte nutzt den ganzen Bildschirm):
## oben links Initiative, oben rechts Menü und Infokasten, unten links Würfel, Kampflog und Figurenkarte,
## unten rechts Aktionsblock (eigener Zug, Aufstellung) oder Karte der Figur, die die KI steuert.

signal action(name: StringName, arg: Variant)

const MARGIN := 14.0
const GAP := 8.0

var top_menu: TopMenu
var info: InfoBox
var initiative: InitiativeBar
var dice_panel: DicePanel
var combat_log: CombatLog
var card: UnitCard           # unten links: eigene Figur
var ai_card: UnitCard        # unten rechts: Figur unter KI-Steuerung
var actions: ActionPanel
var sheet: SheetDialog
var tables: TablesDialog
var end_dialog: EndDialog
var briefing: BriefingDialog
var help: Modal
var _left: VBoxContainer
var _right: VBoxContainer
var _top_right: VBoxContainer


func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	initiative = InitiativeBar.new()
	initiative.focus_unit.connect(func(u: Combatant) -> void: action.emit(&"focus", u))
	initiative.jump.connect(func(u: Combatant) -> void: action.emit(&"jump", u))
	add_child(initiative)

	_top_right = _stack(false)
	top_menu = TopMenu.new()
	top_menu.action.connect(func(n: StringName, a: Variant) -> void: action.emit(n, a))
	_top_right.add_child(top_menu)
	info = InfoBox.new()
	info.confirm.connect(func() -> void: action.emit(&"confirm", null))
	_top_right.add_child(info)
	info.size_flags_horizontal = Control.SIZE_SHRINK_END
	top_menu.size_flags_horizontal = Control.SIZE_SHRINK_END

	_left = _stack(true)
	dice_panel = DicePanel.new()
	dice_panel.custom_minimum_size.x = 360
	_left.add_child(dice_panel)
	combat_log = CombatLog.new()
	_left.add_child(combat_log)
	card = UnitCard.new()
	card.action.connect(func(n: StringName, a: Variant) -> void: action.emit(n, a))
	_left.add_child(card)

	_right = _stack(true)
	ai_card = UnitCard.new()
	_right.add_child(ai_card)
	actions = ActionPanel.new()
	actions.action.connect(func(n: StringName, a: Variant) -> void: action.emit(n, a))
	_right.add_child(actions)
	ai_card.size_flags_horizontal = Control.SIZE_SHRINK_END
	actions.size_flags_horizontal = Control.SIZE_SHRINK_END

	sheet = SheetDialog.new()
	tables = TablesDialog.new()
	end_dialog = EndDialog.new()
	briefing = BriefingDialog.new()
	help = Modal.new()
	for d in [sheet, tables, end_dialog, briefing, help]:
		add_child(d)
	end_dialog.next_battle.connect(func() -> void: action.emit(&"next_battle", null))
	end_dialog.reset_crew.connect(func() -> void: action.emit(&"reset_crew", null))
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


func _process(_d: float) -> void:
	# Stapel passen sich ihrem Inhalt an (Karten werden bei jedem Zug neu gefüllt)
	for v in [_left, _right, _top_right]:
		v.reset_size()
	_place(_left, Vector2(MARGIN, size.y - MARGIN - _left.size.y))
	_place(_right, Vector2(size.x - MARGIN - _right.size.x, size.y - MARGIN - _right.size.y))
	_place(_top_right, Vector2(size.x - MARGIN - _top_right.size.x, MARGIN))
	initiative.position = Vector2(MARGIN, MARGIN)
	initiative.size = Vector2(maxf(200.0, size.x - top_menu.size.x - MARGIN * 3), 44)


func _place(v: Control, p: Vector2) -> void:
	if v.position != p:
		v.position = p


func set_toggle(name: StringName, on: bool, tip := "") -> void:
	top_menu.set_toggle(name, on, tip)


func any_dialog_open() -> bool:
	return sheet.visible or tables.visible or end_dialog.visible or briefing.visible or help.visible


func close_dialogs() -> bool:
	for d in [sheet, tables, briefing, help]:
		if d.visible:
			d.close()
			return true
	return false


func show_help() -> void:
	help.open("Bedienung")
	var l := UiTheme.label("""Maus über ein blaues Feld: Vorschau im Infokasten oben rechts. Grüne Linien/Ringe = von dort treffbar, rote = wer dich dort treffen kann.
Blaues Feld anklicken: bewegen (Gangart im Aktionsblock). Rot umrandeten Gegner anklicken: angreifen (Aktivität 20–100 %).
Rechtsklick: Figur drehen. Sichtfeld 180° nach vorne – Angriffe von der Seite (+15) oder hinten (+30) überraschen.
Kamera: ziehen (links/Mitte), WASD/Pfeile, Mausrad = Zoom, Q/E = um 90° drehen. Enter = Zug beenden, R = Reichweite, G = Raster, Esc = abbrechen.
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
	for c in [top_menu, info, dice_panel, combat_log, card, ai_card, actions]:
		if c.visible and c.get_global_rect().has_point(p):
			return true
	for c in initiative.get_children():
		if c.get_global_rect().has_point(p):
			return true
	return false
