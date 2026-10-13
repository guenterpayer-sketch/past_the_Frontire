class_name ArmorData
extends Resource
## Rüstung: Spalte in den Angriffstabellen (cls 0–3), Verteidigungsmalus, Bewegungsmalus.

@export var id: StringName
@export var name := ""
@export_range(0, 3) var cls := 0
@export var db := 0
@export var move := 0
