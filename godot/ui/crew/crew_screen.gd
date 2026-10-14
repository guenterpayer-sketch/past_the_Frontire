class_name CrewScreen
extends Control
## Charakter-Modul (eigene Szene crew.tscn): Crew ansehen und steigern, nach einem Einsatz mit dessen Ergebnis.
## „Speichern & nächste Mission“ wechselt in den Bodenkampf.

var overview: CrewOverview
var sheet: SheetDialog


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
