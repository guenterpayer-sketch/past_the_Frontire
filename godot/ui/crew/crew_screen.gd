class_name CrewScreen
extends Control
## Charakter-Modul (eigene Szene crew.tscn): Crew ansehen und steigern, nach einem Einsatz mit dessen Ergebnis.
## „Speichern & nächste Mission“ wechselt in den Bodenkampf.

var overview: CrewOverview
var sheet: SheetDialog
var editor: CharacterEditor


func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.045, 0.07)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	overview = CrewOverview.new()
	sheet = SheetDialog.new()
	add_child(overview)
	add_child(sheet)
	editor = CharacterEditor.new()
	add_child(editor)
	overview.create_member.connect(func() -> void:
		editor.open_new(Campaign.crew(), Campaign.crew().find(overview.current()))
		editor.move_to_front())
	editor.saved.connect(func(ch: Character, replace: Character) -> void:
		Campaign.add_member(ch, replace)
		show_crew())
	overview.next_battle.connect(start_mission)
	overview.reset_crew.connect(func() -> void:
		Campaign.reset()
		show_crew())
	overview.open_sheet.connect(func(crew: Array[Character], u: Character) -> void:
		var units := Roster.build_crew(crew)
		sheet.show_sheet(units, units[crew.find(u)])
		sheet.move_to_front())
	show_crew()


func show_crew() -> void:
	overview.show_crew(Campaign.crew(), Campaign.last_result)


func start_mission() -> void:
	Campaign.save()
	Campaign.last_result = {}
	get_tree().change_scene_to_file(Campaign.BATTLE_SCENE)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		sheet.close()
		editor.close()
