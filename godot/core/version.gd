class_name Version
## Spielversion aus project.godot (application/config/version, gepflegt vom Koordinator; Hub Auftrag 7).
## Gemeinsam für alle Module: Burgermenü (add_to) und Spielstände (SaveSlots).

## Kennung der Versionszeile im Burgermenü (nicht anklickbar)
const MENU_ID := 9000


## Version, z. B. „0.1 (19.10.2026)“; "" wenn nicht gesetzt
static func current() -> String:
	return String(ProjectSettings.get_setting("application/config/version", ""))


## Anzeigetext, z. B. „Version 0.1 (19.10.2026)“ („–“ ohne Angabe)
static func label(v := "") -> String:
	return "Version %s" % (v if v != "" else "–")


## Versionszeile unten ins Burgermenü: Trennstrich, graue Zeile, nicht anklickbar
static func add_to(popup: PopupMenu) -> void:
	popup.add_separator()
	popup.add_item(label(current()), MENU_ID)
	popup.set_item_disabled(popup.get_item_index(MENU_ID), true)
	popup.add_theme_color_override("font_disabled_color", UiTheme.MUTED)
