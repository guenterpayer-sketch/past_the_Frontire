class_name Figure
extends Node3D
## Gemeinsame Schnittstelle für die Darstellung einer Figur (Grundkörper oder 3D-Modell).
## Vorne ist −z. UnitView dreht die Figur und ruft diese Methoden auf.

enum Pose { STAND, AIM, CROUCH, KO, DEAD }

var unit: Combatant
var pose := Pose.STAND


func setup(u: Combatant) -> void:
	unit = u


## Grundhaltung setzen (wird gehalten, bis eine andere kommt)
func set_pose(p: Pose) -> void:
	pose = p


## laufen (gait: &"gehen", &"laufen", &"sprinten") oder stehen bleiben (&"")
func set_moving(_gait: StringName) -> void:
	pass


## kurze Handlung abspielen und warten, bis der Höhepunkt erreicht ist (z. B. der Schuss fällt)
func act(_action: StringName, _weapon: WeaponData = null) -> void:
	pass


func play_hit() -> void:
	pass


## umfallen (bewusstlos oder tot)
func fall(_dead: bool) -> void:
	pass


## wieder aufstehen (nach Erster Hilfe)
func stand_up() -> void:
	pass


## Röntgenumriss (durch Hindernisse sichtbar)
func set_ghost(_on: bool) -> void:
	pass


## Höhe des Kopfes über dem Boden (für Beschriftung und Effekte)
func head_height() -> float:
	return 1.8


## Mündung der Waffe in Weltkoordinaten (für die Leuchtspur)
func muzzle() -> Vector3:
	return global_position + global_basis * Vector3(0.2, 1.25, -0.8)
