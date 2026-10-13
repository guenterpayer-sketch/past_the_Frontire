class_name AttackTableData
extends Resource
## Angriffstabelle: Trefferschwelle je Rüstungsklasse (Keine, Leicht, Mittel, Schwer).

@export var id: StringName
@export var name := ""
@export var thresholds: PackedInt32Array = PackedInt32Array([80, 85, 90, 100])
@export var crit: CritTableData
@export var ignores_armor := false
