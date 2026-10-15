class_name UiScale
extends RefCounted
## Einstellung „UI-Größe“ fürs ganze Spiel: Faktor auf die Oberfläche (Window.content_scale_factor, wirkt auf alle
## 2D-Elemente aller Szenen; die 3D-Ansicht bleibt unverändert). Gespeichert in user://ui.cfg, beim Start angewendet.
## Lesen/Setzen: UiScale.get_factor(), UiScale.set_factor(f, tree). Auswahl-Knöpfe: UiScale.picker(tree).

const PATH := "user://ui.cfg"
const STEPS := [0.75, 0.9, 1.0, 1.25]
const DEFAULT := 1.0


## Gespeicherter Faktor (eine der STEPS)
static func get_factor() -> float:
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	var f := float(cfg.get_value("ui", "scale", DEFAULT))
	return f if f in STEPS else DEFAULT


## Faktor setzen, speichern und sofort anwenden
static func set_factor(f: float, tree: SceneTree) -> void:
	if not f in STEPS:
		return
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("ui", "scale", f)
	cfg.save(PATH)
	apply(tree)


## Gespeicherten Faktor auf das Fenster anwenden (beim Start; mehrfach aufrufbar)
static func apply(tree: SceneTree) -> void:
	if tree and tree.root:
		tree.root.content_scale_factor = get_factor()


static func label(f: float) -> String:
	return "%d %%" % roundi(f * 100)


## Zeile mit einem Knopf je Stufe (gewählte hervorgehoben); zum Einbauen in Einstellungs- oder Menüdialoge
static func picker(tree: SceneTree) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var title := UiTheme.label("UI-Größe", 15)
	title.custom_minimum_size.x = 110
	row.add_child(title)
	var buttons: Array[Button] = []
	for f in STEPS:
		var b := UiTheme.button(label(f), "Größe der Oberfläche (Schrift, Kästen); 3D-Ansicht bleibt gleich", true)
		b.custom_minimum_size = Vector2(70, 36)
		b.button_pressed = is_equal_approx(f, get_factor())
		buttons.append(b)
		row.add_child(b)
	for i in buttons.size():
		var f: float = STEPS[i]
		buttons[i].pressed.connect(func() -> void:
			set_factor(f, tree)
			for k in buttons.size():
				buttons[k].set_pressed_no_signal(k == i))
	return row
