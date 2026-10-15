class_name TablesDialog
extends Modal
## Tabellen: Angriffstabelle der gewählten Waffe, Kritische Treffer, Patzer; Knopf „Psi-Listen …“ öffnet die
## Übersicht der Psi-Listen (PsiListView des Charakter-Moduls) für die Figur am Zug.

var psi_view: PsiListView      # von BattleUI gesetzt
var _weapons: Array[WeaponData] = []
var _unit: Combatant


## selected: Waffe für die Angriffstabelle; unit: Figur für die Psi-Übersicht (null = nur die Listen)
func show_tables(selected: WeaponData = null, unit: Combatant = null) -> void:
	_unit = unit
	_weapons = GameData.weapons()
	if selected == null:
		selected = _weapons[0]
	open("Tabellen")
	var row := HBoxContainer.new()
	row.add_child(UiTheme.label("Waffe:"))
	var ob := OptionButton.new()
	for i in _weapons.size():
		ob.add_item(_weapons[i].name, i)
		if _weapons[i] == selected:
			ob.select(i)
	ob.item_selected.connect(func(i: int) -> void: show_tables(_weapons[i], _unit))
	row.add_child(ob)
	if psi_view:
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(gap)
		var pb := UiTheme.button("Psi-Listen …")
		pb.tooltip_text = "Alle Psi-Listen mit Kräften, Stufe (= PP), Ziel und Wirkung" + ("; Stand von %s" % _unit.name if _unit else "")
		pb.pressed.connect(func() -> void: psi_view.open_for(_unit if _unit and not PsiLists.learned(_unit).is_empty() else null))
		row.add_child(pb)
	content.add_child(row)
	content.add_child(Modal.rich(_attack_table(selected)))
	content.add_child(Modal.rich("[b]Kritische Treffer[/b]\n[color=#8291ad]W100 (geschlossen) + Grad: A −20, B −10, C ±0, D +10, E +20[/color]"))
	var grid := GridContainer.new()
	grid.columns = 3
	for t in GameData.crit_tables():
		grid.add_child(Modal.rich(_crit_table(t)))
	content.add_child(grid)
	content.add_child(Modal.rich(_fumbles()))
	add_close()


func _attack_table(w: WeaponData) -> String:
	var range_text := "Nahkampf (benachbart)" if w.melee else "Reichweite %d m je Stufe, %d Stufen (max. %d m), je Stufe ab der 2. %d, bis %d m +10%s" % [
		w.inc_m, w.stages, w.max_range_m(), Tables.RANGE_STEP, int(Tables.POINT_BLANK_M), (", Mindestabstand %d m" % w.min_range_m) if w.min_range_m else ""]
	var s := "[color=#8291ad]%s.\nTabelle %s, Fertigkeit %s, Schadensfaktor %s, Maximalergebnis %d (*: wird darauf begrenzt), Patzer 01–%02d. Eintrag: TP und Kritischer Grad.[/color]\n\n" % [
		range_text, w.table.name, Rules.skill_name(w.skill), str(w.damage), w.max_result, w.fumble]
	s += "[table=5][cell][b]Ergebnis[/b][/cell]"
	for a in Tables.ARMOR_CLASSES:
		s += "[cell][b]%s[/b][/cell]" % a
	for total in range(50, 160, 5):
		var over := total > w.max_result
		s += "[cell]%s%d%s[/cell]" % ["[color=#66708a]" if over else "", total, "*[/color]" if over else ""]
		for cls in 4:
			var r := Tables.lookup_attack(w.table, mini(total, w.max_result), cls, w.damage)
			s += "[cell]%s[/cell]" % (("%d%s" % [r.dmg, (" " + r.severity) if r.severity else ""]) if r.hit else "–")
	return s + "[/table]"


func _crit_table(t: CritTableData) -> String:
	var s := "[b]%s[/b]\n[table=2]" % t.name
	for i in t.rows.size():
		var r: CritRowData = t.rows[i]
		s += "[cell][color=#8291ad]%s[/color][/cell][cell]%s\n[color=#8291ad][font_size=11]%s[/font_size][/color][/cell]" % [Tables.CRIT_BAND_NAMES[i], r.text, ", ".join(r.effects())]
	return s + "[/table]"


func _fumbles() -> String:
	var s := "[b]Patzer (W100)[/b]\n[table=2]"
	var prev := 0
	for r in GameData.fumble_table().rows:
		s += "[cell]%d–%d[/cell][cell]%s[/cell]" % [prev + 1, r.up_to, r.text]
		prev = r.up_to
	return s + "[/table]"
