class_name UnitData
extends Resource
## Vorlage einer Figur. Fertigkeiten als {Fertigkeit: Rang}, nicht genannte haben Rang 0.

@export var id: StringName
@export var name := ""
@export var letter := ""
@export var role := ""
@export var color := Color.WHITE
@export var attrs := {"STA": 50, "GEW": 50, "KOO": 50, "KON": 50, "INT": 50, "EMP": 50, "MEN": 50}
@export var skills := {}
@export var weapons: Array[WeaponData] = []
@export var armor: ArmorData
@export var shield := false
@export var medkits := 0
