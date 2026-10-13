class_name WeaponData
extends Resource
## Eine Waffe. Reichweite in Metern je Reichweitenstufe (inc_m) und Anzahl Stufen.

@export var id: StringName
@export var name := ""
## Fertigkeit, mit der die Waffe geführt wird (Schlüssel aus Rules.SKILLS)
@export var skill: StringName
@export var table: AttackTableData
@export var melee := false
@export var psi := false
@export var inc_m := 0
@export var stages := 0
## Mindestabstand in Metern (Raketenwerfer)
@export var min_range_m := 0
## Höchstes Ergebnis auf der Angriffstabelle
@export var max_result := 150
## Unmodifizierter Wurf bis zu diesem Wert ist ein Patzer
@export var fumble := 2
## Schadensfaktor
@export var damage := 1.0
## Zusätzlicher Angriffsbonus (Feuerstoß)
@export var ob_bonus := 0
## Schuss pro Ladung (0 = kein Nachladen nötig)
@export var magazine := 0
## Schuss insgesamt
@export var ammo_total := 0
## Abzug der Druckwelle je Ring (1,5 m, 3 m)
@export var splash: PackedInt32Array = PackedInt32Array()
## Psi-Punkte pro Einsatz
@export var pp_cost := 0


func max_range_m() -> int:
	return inc_m * stages


func sound() -> StringName:
	if psi:
		return &"psi"
	if melee:
		return &"nahkampf"
	if not splash.is_empty():
		return &"rakete"
	if table and table.id == &"strahl":
		return &"laser"
	if ob_bonus > 0:
		return &"mg"
	return &"gewehr"
