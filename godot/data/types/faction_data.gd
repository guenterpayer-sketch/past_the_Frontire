class_name FactionData
extends Resource
## Gegnergruppe für den Missionsgenerator: welche Gegnertypen wie häufig vorkommen.
## units und weights gehören paarweise zusammen (gleiche Länge); höheres Gewicht = häufiger.

@export var name := ""
@export_multiline var description := ""
@export var units: Array[UnitData] = []
@export var weights: Array[int] = []
## höchstens so viele Figuren desselben Typs
@export var max_same := 3
