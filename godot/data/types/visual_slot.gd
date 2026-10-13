class_name VisualSlot
extends Resource
## Ein Modell für eine Art von Hallenobjekt. Das Modell wird in den Platz des Objekts eingepasst.

enum Fit {
	STRETCH,   ## in alle Richtungen auf die Objektgröße strecken
	HEIGHT,    ## gleichmäßig auf die Objekthöhe skalieren, mittig stellen
	REPEAT,    ## entlang der längeren Seite wiederholen, Höhe und Tiefe strecken
}

@export var model: PackedScene
@export var fit := Fit.STRETCH
## zusätzliche Drehung um die Hochachse (Grad), z. B. wenn das Modell quer liegt
@export var rotation_y_deg := 0.0
## Länge eines Stücks beim Wiederholen (Meter)
@export var repeat_m := 2.0
