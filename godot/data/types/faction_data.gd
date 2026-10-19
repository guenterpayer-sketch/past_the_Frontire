class_name FactionData
extends Resource
## Gegnergruppe für den Missionsgenerator: welche Gegnertypen wie häufig vorkommen.
## units und weights gehören paarweise zusammen (gleiche Länge); höheres Gewicht = häufiger.
## Oberart, Eigenheit, Waffentausch und bevorzugte Karten: Bodenkampf Auftrag 1 (Entscheidungen des Nutzers 19.10.2026).

## Oberarten (kind) mit Anzeigenamen; „story“ für die Story-Fraktionen (kommen später)
const KINDS := {&"konzern": "Konzern", &"soeldner": "Söldner", &"piraten": "Piraten", &"syndikat": "Syndikat",
	&"kult": "Kult", &"story": "Story"}
## Anteil der Einsätze auf einem bevorzugten Kartentyp (maps)
const MAP_CHANCE := 0.6

@export var name := ""
@export_multiline var description := ""
@export var kind: StringName = &"soeldner"
@export var units: Array[UnitData] = []
@export var weights: Array[int] = []
## höchstens so viele Figuren desselben Typs
@export var max_same := 3
## Farbe auf der Sternenkarte
@export var color := Color("8291ad")
## Eigenheit: Name und Satz fürs Briefing, Werte (alle optional):
##   ob (Angriff), melee_ob (Nahkampf), psi_ob (Psi-Angriff), db (Verteidigung), init (Initiative), hp_pct (TP in %),
##   medkits (mindestens so viele je Figur), wear (Waffen −10 beschädigt / +5 gute Stücke),
##   budget_pct (Gegnerbudget in %), loot_extra (Beuteplätze mehr bei Sieg)
@export var trait_name := ""
@export var trait_text := ""
@export var trait_mods := {}
## Waffentausch für alle Figuren der Fraktion: Waffen-ID → Waffe (z. B. Sturmgewehr → Laserkarabiner)
@export var weapon_swap := {}
## Bevorzugte Kartentypen (MapTypes.GROUND), leer = gleich verteilt
@export var maps: Array[StringName] = []


func kind_name() -> String:
	return KINDS.get(kind, String(kind))
