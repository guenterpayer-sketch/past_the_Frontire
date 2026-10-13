class_name SheetDialog
extends Modal
## Charakterbogen: Eigenschaften, abgeleitete Werte, alle Fertigkeiten mit Rang, Boni und EP.

var _crew: Array[Combatant] = []


func show_sheet(crew: Array[Combatant], u: Combatant) -> void:
	_crew = crew
	open("Charakterbogen")
	var tabs := HBoxContainer.new()
	for o in crew:
		var b := UiTheme.button(o.name, "", true)
		b.button_pressed = o == u
		b.pressed.connect(show_sheet.bind(crew, o))
		tabs.add_child(b)
	content.add_child(tabs)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	content.add_child(cols)
	cols.add_child(Modal.rich(_side(u)))
	cols.get_child(0).custom_minimum_size.x = 300
	cols.get_child(0).size_flags_horizontal = Control.SIZE_FILL
	var groups := GridContainer.new()
	groups.columns = 2
	groups.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for g in Rules.SKILL_GROUPS:
		groups.add_child(Modal.rich(_group(u, g)))
	cols.add_child(groups)
	add_close()


func _side(u: Combatant) -> String:
	var s := "[font_size=20][b]%s[/b][/font_size]\n[color=#8291ad]%s[/color]\n\n[table=3]" % [u.name, u.role]
	s += "[cell][b]Eigenschaft[/b][/cell][cell][b]Wert[/b][/cell][cell][b]Bonus[/b][/cell]"
	for a in Rules.ATTRIBUTES:
		var v: int = u.attrs[a.id]
		s += "[cell]%s[/cell][cell]%d[/cell][cell]%s[/cell]" % [a.name, v, Dice.fmt(Rules.attr_bonus(v))]
	s += "[/table]\n\n[b]Abgeleitete Werte[/b]\n"
	s += "Trefferpunkte: %d (tot bei %d)\n" % [u.max_hp, Rules.death_at(u)]
	s += "Psi-Punkte: %d\n" % u.max_pp
	s += "Bewegung: Gehen 1 Hex je 10 %% Aktivität + %d Hex frei\n" % Rules.free_hexes(u)
	s += "Initiative: 2W10 %s\n" % Dice.fmt(Rules.initiative_bonus(u))
	s += "Rüstung: %s\n" % u.armor.name
	s += "Waffen: %s%s" % [", ".join(u.weapons.map(func(w: WeaponData) -> String: return w.name)), ", Schild" if u.shield else ""]
	return s


func _group(u: Combatant, g: Dictionary) -> String:
	var s := "[b]%s[/b]\n[table=7]" % g.name
	for h in ["Fertigkeit", "Eig.", "Rang", "Rangb.", "Eig.b.", "Gesamt", "EP"]:
		s += "[cell][color=#8291ad]%s[/color][/cell]" % h
	for sk in g.skills:
		var id := StringName(sk[0])
		var r := Rules.skill_rank(u, id)
		var xp: int = u.skills.get(id, {}).get("xp", 0)
		var ab := Rules.attr_bonus(u.attrs[sk[2]]) + Rules.attr_bonus(u.attrs[sk[3]])
		var col := "#dfe6f3" if r > 0 else "#66708a"
		s += "[cell][color=%s]%s[/color][/cell][cell][color=%s]%s+%s[/color][/cell][cell]%d[/cell][cell]%s[/cell][cell]%s[/cell][cell][b]%s[/b][/cell][cell]%d/%d[/cell]" % [
			col, sk[1], col, _short(sk[2]), _short(sk[3]), r, Dice.fmt(Rules.rank_bonus(r)), Dice.fmt(ab), Dice.fmt(Rules.skill_total(u, id)), xp, Rules.rank_cost(r)]
	return s + "[/table]"


func _short(id: String) -> String:
	for a in Rules.ATTRIBUTES:
		if a.id == id:
			return a.short
	return id
