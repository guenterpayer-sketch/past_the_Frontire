class_name ShipTemplateData
extends Resource
## Vorlage eines Gegnerschiffs im Raumkampf (data/ships/schiffe/<id>.tres). Werte abgestimmt per Simulation
## (tests/sim_space.gd, 17.10.2026). Dateiname = Kennung, auf die die Gegnerseiten verweisen.

@export var name := ""
## Klasse: 0 Jäger, 1 leicht, 2 mittel, 3 schwer (Trefferschwellen, Schaden, Modellgröße)
@export_enum("Jäger", "leicht", "mittel", "schwer") var cls := 1
@export var hull := 50
## Schildpunkte je Seite und Aufladung je Seite und Runde
@export var shield := 0
@export var recharge := 0
## Abzug je Treffer auf die Hülle
@export var armor := 0
## Grund-VW; dazu kommt die halbe Besatzung (wie beim eigenen Schiff der halbe Pilot-Bonus)
@export var vw := 0
@export var speed := 2
@export var max_speed := 3
## Drehungen um 60° je Runde
@export var turns := 1
## Waffen-Keys aus ShipWeapons (Abwehrwaffen kommen in Turm-Slots)
@export var weapons: PackedStringArray = []
## Bonus der Besatzung auf Geschütze, Pilot, Schilde
@export var skill := 20
@export var init := 5
## Beute, wenn das Schiff zerstört wird (Credits ×0,6–1,0)
@export var credits := 100
@export var material := 1
