class_name CharacterVisual
extends Resource
## 3D-Modell einer Figur mit Animationen. Fehlt es, zeichnet das Spiel die Figur aus Grundkörpern.
## Animationen: entweder im Modell enthalten (z. B. Mechs) oder mit tools/bake_animations.gd
## von einem anderen Skelett übertragen (animations).

@export var model: PackedScene
## Größe der Figur im Spiel in Metern (das Modell wird darauf skaliert)
@export var height_m := 1.8
## Drehung des Modells, damit es nach vorne (−z) schaut
@export var rotation_y_deg := 180.0
## übertragene Animationen; leer = die Animationen des Modells selbst
@export var animations: AnimationLibrary
## Spielzustand -> Name der Animation (fehlende Einträge: Standardnamen der übertragenen KayKit-Animationen)
@export var anim_names := {}
## Knochen, an dem die Waffe hängt (leer = keine Waffe zeigen)
@export var hand_bone := "Hand.R"
## Animationen beim Umbacken von diesem Skelett übernehmen (siehe tools/bake_animations.gd)
@export var bake_from_kaykit := true
