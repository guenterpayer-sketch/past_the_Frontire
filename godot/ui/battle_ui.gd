class_name BattleUI
extends Control
## Oberfläche: Kopfleiste, Initiative-Leiste, Panel rechts (Figur + Kampflog), Tooltip, Würfel, Dialoge.

signal action(name: StringName, arg: Variant)

const PANEL_W := 360.0
const PANEL_W_SMALL := 300.0
const TOP_H := 44.0

var unit_panel: UnitPanel
var combat_log: CombatLog
var initiative: InitiativeBar
var dice_panel: DicePanel
var sheet: SheetDialog
var tables: TablesDialog
var end_dialog: EndDialog
var round_label: Label
var hall_label: Label
var _top: PanelContainer
var _side: PanelContainer
var _tip: PanelContainer
var _tip_text: RichTextLabel
var _toggles := {}


func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top()
	_build_side()
	initiative = InitiativeBar.new()
	initiative.focus_unit.connect(func(u: Combatant) -> void: action.emit(&"focus", u))
	initiative.jump.connect(func(u: Combatant) -> void: action.emit(&"jump", u))
	add_child(initiative)
	dice_panel = DicePanel.new()
	add_child(dice_panel)
	_tip = PanelContainer.new()
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.BG, 0.95), UiTheme.LINE, 8, 10))
	_tip_text = RichTextLabel.new()
	_tip_text.bbcode_enabled = true
	_tip_text.fit_content = true
	_tip_text.scroll_active = false
	_tip_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_text.custom_minimum_size.x = 340
	_tip_text.add_theme_font_size_override("normal_font_size", 13)
	_tip_text.add_theme_font_size_override("bold_font_size", 13)
	_tip.add_child(_tip_text)
	_tip.hide()
	add_child(_tip)
	sheet = SheetDialog.new()
	tables = TablesDialog.new()
	end_dialog = EndDialog.new()
	for d in [sheet, tables, end_dialog]:
		add_child(d)
	end_dialog.next_battle.connect(func() -> void: action.emit(&"next_battle", null))
	end_dialog.reset_crew.connect(func() -> void: action.emit(&"reset_crew", null))
	resized.connect(_layout)
	_layout()


func panel_width() -> float:
	return PANEL_W_SMALL if size.x < 1100 else PANEL_W


func any_dialog_open() -> bool:
	return sheet.visible or tables.visible or end_dialog.visible


func close_dialogs() -> bool:
	for d in [sheet, tables, end_dialog]:
		if d.visible and d != end_dialog:
			d.close()
			return true
	return false


func set_toggle(name: StringName, on: bool, text := "") -> void:
	var b: Button = _toggles[name]
	b.set_pressed_no_signal(on)
	if text != "":
		b.text = text


func _build_top() -> void:
	_top = PanelContainer.new()
	_top.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.97), UiTheme.LINE, 0, 6))
	add_child(_top)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_top.add_child(row)
	row.add_child(UiTheme.label("Past the Frontire", 17))
	round_label = UiTheme.label("Runde 0", 14, UiTheme.ACCENT)
	row.add_child(round_label)
	hall_label = UiTheme.label("", 13, UiTheme.MUTED)
	hall_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hall_label.clip_text = true
	row.add_child(hall_label)
	for spec in [[&"sheet", "Charakterbogen", "", false], [&"tables", "Tabellen", "", false],
			[&"auto", "KI für Crew", "Die KI steuert auch die Crew (zum Zuschauen)", true],
			[&"sound", "Ton", "Soundeffekte an/aus", true], [&"dice", "Würfel", "Würfelanimation an/aus (2 W10: rot = Zehner, weiß = Einer)", true],
			[&"new", "Neue Karte", "", false]]:
		var b := UiTheme.button(spec[1], spec[2], spec[3])
		b.pressed.connect(func() -> void: action.emit(spec[0], b.button_pressed))
		row.add_child(b)
		if spec[3]:
			_toggles[spec[0]] = b


func _build_side() -> void:
	_side = PanelContainer.new()
	_side.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.97), UiTheme.LINE, 0, 8))
	add_child(_side)
	var v := VBoxContainer.new()
	_side.add_child(v)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 3.0
	v.add_child(scroll)
	unit_panel = UnitPanel.new()
	unit_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_panel.action.connect(func(n: StringName, a: Variant) -> void: action.emit(n, a))
	scroll.add_child(unit_panel)
	combat_log = CombatLog.new()
	combat_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_log.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.BG, 0.6), UiTheme.LINE, 6, 8))
	v.add_child(combat_log)


func _layout() -> void:
	var w := panel_width()
	_top.position = Vector2.ZERO
	_top.size = Vector2(size.x, TOP_H)
	_side.position = Vector2(size.x - w, TOP_H)
	_side.size = Vector2(w, size.y - TOP_H)
	if initiative:
		initiative.position = Vector2(8, TOP_H + 6)
		initiative.size = Vector2(size.x - w - 16, 30)
	if dice_panel:
		dice_panel.position = Vector2((size.x - w) / 2.0 - 120, TOP_H + 48)


## Tooltip an der Maus (auf Handys am unteren Kartenrand)
func show_tip(bbcode: String, at: Vector2, touch := false) -> void:
	if bbcode == "":
		_tip.hide()
		return
	_tip_text.text = bbcode
	_tip.show()
	_tip.reset_size()
	var map_w := size.x - panel_width()
	var s := _tip.get_combined_minimum_size()
	if touch:
		_tip.position = Vector2(8, size.y - s.y - 8)
	else:
		_tip.position = Vector2(clampf(at.x + 18, 8, map_w - s.x - 8), clampf(at.y + 18, TOP_H + 8, size.y - s.y - 8))


func hide_tip() -> void:
	_tip.hide()


## liegt der Punkt auf der Oberfläche (nicht auf der Karte)?
func covers(p: Vector2) -> bool:
	if any_dialog_open():
		return true
	if p.y < TOP_H or p.x > size.x - panel_width():
		return true
	if dice_panel.visible and dice_panel.get_global_rect().has_point(p):
		return true
	for c in initiative.get_children():
		if c.get_global_rect().has_point(p):
			return true
	return false
