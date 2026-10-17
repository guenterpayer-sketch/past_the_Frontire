class_name SpaceFactionData
extends Resource
## Gegnerseite im Raumkampf (data/ships/seiten/<id>.tres; Kennung = Dateiname = Fraktions-ID im setup, bei
## Missionsfraktionen wie data/missions/<id>.tres). Aufstellungen je Schwierigkeit: je Zeile eine Aufstellung als
## Schiffskennungen mit Komma, z. B. „korvette,jaeger“. Leer = Standardaufstellungen (SpaceTemplates.DEFAULT_GROUPS).

@export var name := ""
## Bei Niederlage der Crew: entern (Bodenkampf) oder abziehen (Notfall)
@export_enum("entern", "abziehen") var on_win := "entern"
## Lösegeld in Credits (0 = nimmt keins)
@export var ransom := 0
## Gegnerschiffe drehen ab, wenn die Hülle unter diesen Anteil fällt (0 = nie; Jäger nie)
@export_range(0.0, 1.0, 0.05) var flee_at := 0.0
@export var leicht: PackedStringArray = []
@export var mittel: PackedStringArray = []
@export var schwer: PackedStringArray = []
