class_name SpaceBriefing
extends Modal
## Kampf-Briefing: Gegner, Zustand des Schiffs, Posten besetzen (vorbelegt aus den festen Posten, nur für diesen
## Kampf änderbar). Je Station Bord-KI oder ein Crewmitglied; zweimal dieselbe Person = Doppelbesetzung (−30).

signal confirmed(posts: Dictionary)

var view: SpaceView
var posts := {}
var _rows: VBoxContainer


func _ready() -> void:
	super._ready()
	closable = false
	max_size = Vector2(980, 760)


func open_for(v: SpaceView) -> void:
	view = v
	var c := v.combat
	posts = c.posts.duplicate()
	open("Kontakt: %s" % SpaceTemplates.faction_name(c.faction_id))
	var info := "[b]Gegner:[/b] "
	var names := PackedStringArray()
	for e in c.enemies():
		names.append("%s (%s)" % [e.name, SpaceShip.CLASSES[e.cls]])
	info += ", ".join(names)
	info += "\n[b]Bei Niederlage:[/b] %s" % ("[color=#ffd34d]entern[/color] (Bodenkampf)"
		if String(c.faction.get("on_win", "")) == "entern" else "ziehen ab (Notfall)")
	info += " · [b]Lösegeld:[/b] %s" % ("%d Credits" % c.faction.ransom if int(c.faction.get("ransom", 0)) > 0 else "nein")
	var dmg := PackedStringArray()
	for sys in c.own.damage:
		dmg.append("%s (%s)" % [c.system_name(String(sys)), c.own.damage[sys]])
	info += "\n[b]Schiff:[/b] Hülle %d/%d · Systemschäden: %s" % [c.own.hull, c.own.hull_max,
		", ".join(dmg) if not dmg.is_empty() else "keine"]
	var am := PackedStringArray()
	for k in ShipWeapons.AMMO_TYPES:
		am.append("%s %d" % [ShipWeapons.AMMO_TYPES[k], int(c.ship_ammo.get(k, 0))])
	info += " · " + ", ".join(am)
	content.add_child(Modal.rich(info))
	content.add_child(UiTheme.label("Posten besetzen", 16, UiTheme.ACCENT))
	content.add_child(UiTheme.label("Vorbelegt aus den festen Posten an Bord. Änderungen gelten nur für diesen Kampf.",
		12, UiTheme.MUTED))
	_rows = VBoxContainer.new()
	content.add_child(_rows)
	_build_rows()
	var auto := UiTheme.button("Freie mit den Besten besetzen")
	auto.pressed.connect(func() -> void:
		posts = SpaceSetup.fill_posts(c.crew, c.own.slots, posts)
		_build_rows())
	footer.add_child(auto)
	var start := UiTheme.button("Kampf beginnen")
	start.pressed.connect(close_and_start)
	footer.add_child(start)


func _build_rows() -> void:
	UiTheme.clear(_rows)
	var c := view.combat
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	_rows.add_child(grid)
	for st in c.stations():
		grid.add_child(UiTheme.label(SpaceSetup.station_name(st), 14))
		var ob := OptionButton.new()
		ob.focus_mode = Control.FOCUS_NONE
		ob.custom_minimum_size.x = 230
		ob.add_item("Bord-KI (+%d)" % SpaceSetup.KI_BONUS)
		ob.set_item_metadata(0, SpaceSetup.KI)
		var skill := _skill_of(st)
		var sel := 0
		for ch in c.crew:
			var locked: bool = ch.is_locked()
			ob.add_item("%s (%s %+d)" % [ch.name, Rules.skill_name(skill), Rules.skill_total(ch, skill)])
			ob.set_item_metadata(ob.item_count - 1, String(ch.id))
			ob.set_item_disabled(ob.item_count - 1, locked)
			if String(posts.get(st, "")) == String(ch.id):
				sel = ob.item_count - 1
		ob.select(sel)
		ob.item_selected.connect(func(i: int) -> void:
			posts[st] = ob.get_item_metadata(i)
			_build_rows())
		grid.add_child(ob)
		var note := ""
		var pid := String(posts.get(st, SpaceSetup.KI))
		if pid != SpaceSetup.KI and posts.values().count(pid) > 1:
			note = "doppelt (−30)"
		if posts.values().count(pid) > 2 and pid != SpaceSetup.KI:
			note = "höchstens zwei Stationen!"
		grid.add_child(UiTheme.label(note, 12, UiTheme.ACCENT))


func _skill_of(st: String) -> StringName:
	if st.begins_with("geschuetz_"):
		return ShipWeapons.skill(String(view.combat.own.slots[st.trim_prefix("geschuetz_")].key))
	return SpaceSetup.STATION_SKILL[st]


## Posten prüfen (höchstens zwei Stationen je Person), Kampf beginnen
func close_and_start() -> void:
	for pid in posts.values():
		if pid != SpaceSetup.KI and posts.values().count(pid) > 2:
			return
	hide()
	confirmed.emit(posts)
