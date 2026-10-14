class_name BriefingDialog
extends Modal
## Einsatzbesprechung vor Runde 0: Auftrag, Gegnergruppe, Schwierigkeit, Halle, Belohnung.
## "Neu würfeln" erzeugt eine andere Mission (wahlweise mit fester Schwierigkeit).

signal reroll(difficulty: String)
signal accepted

const DIFF_CHOICES := [["", "zufällig"], ["leicht", "leicht"], ["mittel", "mittel"], ["schwer", "schwer"]]

var _diff := 0


func show_mission(m: Mission) -> void:
	open("Einsatz: %s" % m.title)
	var t := UiTheme.label(m.text, 15)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(t)
	var f := UiTheme.label("%s – %s" % [m.faction.name, m.faction.description], 13, UiTheme.MUTED)
	f.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(f)
	var sz: Dictionary = {}
	for s in BattleMap.SIZES:
		if s.id == m.size_id:
			sz = s
	var s := "[b]Ziel:[/b] alle Gegner ausschalten\n"
	s += "[b]Schwierigkeit:[/b] %s · [b]Halle:[/b] %s · [b]Belohnung bei Sieg:[/b] +%d freie EP je Figur (zusätzlich zu den %d freien EP pro Einsatz)\n\n" % [
		m.difficulty_name(), sz.get("name", m.size_id), m.reward_xp, MissionResult.FREE_XP]
	s += "[b]Gegner (%d)[/b]\n[table=4]" % m.enemies.size()
	for h in ["", "Typ", "Rolle", "Ausrüstung"]:
		s += "[cell][color=#8291ad]%s[/color][/cell]" % h
	for d in m.enemies:
		var gear := ", ".join(d.weapons.map(func(w: WeaponData) -> String: return w.name))
		if d.armor:
			gear += " · " + d.armor.name
		s += "[cell][b]%s[/b][/cell][cell]%s[/cell][cell]%s[/cell][cell]%s[/cell]" % [d.letter, d.name, d.role, gear]
	s += "[/table]"
	content.add_child(Modal.rich(s))
	var ob := OptionButton.new()
	for c in DIFF_CHOICES:
		ob.add_item("Schwierigkeit: %s" % c[1])
	ob.select(_diff)
	ob.item_selected.connect(func(i: int) -> void: _diff = i)
	footer.add_child(ob)
	var again := UiTheme.button("Andere Mission")
	again.pressed.connect(func() -> void:
		hide()
		reroll.emit(DIFF_CHOICES[_diff][0]))
	footer.add_child(again)
	var go := UiTheme.button("Zur Aufstellung")
	go.add_theme_color_override("font_color", UiTheme.ACCENT)
	go.pressed.connect(close)
	footer.add_child(go)


func close() -> void:
	super.close()
	accepted.emit()
