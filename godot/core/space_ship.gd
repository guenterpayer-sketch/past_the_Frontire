class_name SpaceShip
extends RefCounted
## Ein Schiff im Raumkampf: eigenes Mutterschiff, Gegnerschiff oder Jäger. Reine Daten, die Regeln stehen in SpaceCombat.
## Lage: Hexfeld (axial) und Ausrichtung (Hex.DIRS-Index 0–5). Schilde je Seite relativ zur Ausrichtung:
## 0 Bug, 1 Bug-links, 2 Heck-links, 3 Heck, 4 Heck-rechts, 5 Bug-rechts (Hex.DIRS laufen gegen den Uhrzeigersinn).

const CLASSES := ["Jäger", "leicht", "mittel", "schwer"]
const SIDE_NAMES := ["Bug", "Bug links", "Heck links", "Heck", "Heck rechts", "Bug rechts"]

var id := ""
var name := ""
var side: StringName = &"crew"        # &"crew" oder &"enemy"
var cls := 2                          # Index in CLASSES
var template := ""                    # Vorlage (Gegner), "" = eigenes Schiff
var pos := Vector2i.ZERO
var facing := 0
var speed := 0                        # Felder je Runde (Trägheit: bleibt, bis der Pilot sie ändert)
var max_speed := 3
var turns := 1                        # Drehungen um 60° je Runde (Grundwert)
var hull := 100
var hull_max := 100
var shields: Array[int] = [0, 0, 0, 0, 0, 0]
var shield_max := 0                   # je Seite
var shield_recharge := 0              # Gegner: feste Aufladung je Runde
var armor := 0                        # Abzug je Treffer auf die Hülle
var vw := 0                           # Grund-VW (Größe/Bauart); dazu der halbe Pilot-Bonus
## Slots {Slot-ID: {"key", "damage"}} – eigene Waffen; Gegner haben sie ebenso
var slots := {}
## Systemschäden {System-ID: "A"–"E"}
var damage := {}
## Gegner: Fertigkeitsbonus der Besatzung (Pilot, Geschütze, Schilde) und Initiative-Bonus
var crew_skill := 0
var init_bonus := 0
var initiative := 0
var destroyed := false
var fled := false
## nur für diese Runde: Zielerfassung (+) bzw. Störung (−) durch den Computer {Ziel-ID: Wert}
var lock := {}
var jammed := 0


func is_active() -> bool:
	return not destroyed and not fled


func is_fighter() -> bool:
	return cls == 0


func label() -> String:
	return name


## Schadensstufe eines Systems als Index 0–5 (0 = heil, 5 = E)
func dmg_level(system: String) -> int:
	var s: String = damage.get(system, "")
	return 0 if s == "" else Tables.SEVERITIES.find(s) + 1


func is_out(system: String) -> bool:
	return damage.get(system, "") == "E"


func weapon_slots() -> Array[String]:
	var out: Array[String] = []
	for s in slots:
		if String(slots[s].get("key", "")) != "":
			out.append(String(s))
	return out


## Seite (0–5), auf die ein Angriff aus Richtung `from` trifft
func side_toward(from: Vector2i) -> int:
	if from == pos:
		return 0
	return posmod(Hex.dir_toward(pos, from) - facing, 6)


## Peilung zu einem Feld in Grad relativ zum Bug (−180…180; positiv = rechts/Steuerbord)
func bearing(to: Vector2i) -> float:
	var a := Hex.angle(pos, to) - Hex.dir_angle(facing)
	return wrapf(a, -180.0, 180.0)


func shield_total() -> int:
	var t := 0
	for v in shields:
		t += v
	return t
