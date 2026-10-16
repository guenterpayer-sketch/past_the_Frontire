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
## Zusätzlicher fester Angriffsbonus (z. B. Psi-Angriffe); der Feuerstoß ergibt sich aus shots (Ammo.burst_bonus)
@export var ob_bonus := 0
## Schuss pro Angriff (Feuerstoß ab 2: +5 je Kugel, Ammo.BURST)
@export var shots := 1
## Munitionsart für den Schiffsvorrat (Ammo.TYPES: energie, projektil, raketen; leer = keine)
@export var ammo_type: StringName = &""
## Schuss pro Ladung (0 = unbegrenzt, kein Nachladen nötig)
@export var magazine := 0
## Höchstens mitgeführte Schuss (0 = nur Ammo.MAGS Magazine)
@export var ammo_total := 0
## Abzug der Druckwelle je Ring (1,5 m, 3 m)
@export var splash: PackedInt32Array = PackedInt32Array()
## Psi-Punkte pro Einsatz
@export var pp_cost := 0
## Klang beim Angriff (Schlüssel aus SOUNDS); leer = aus den Werten abgeleitet (sound())
@export var sound_id: StringName = &""
## Psi-Kraft, aus der die Waffe im Kampf erzeugt wurde (PsiCombat, z. B. "lAngriff/2"); leer = echte Waffe
var power := ""
## Sonderwirkung der Kraft: "" Schaden, stun, push, disarm, lance, wave (siehe PsiCombat.ATTACKS)
var power_effect: StringName = &""

@export_group("Darstellung")
## 3D-Modell in der Hand der Figur (leer = Grundkörper)
@export var model: PackedScene
## Länge der Waffe im Spiel in Metern (das Modell wird darauf skaliert)
@export var length_m := 0.8
## Lage in der Hand: Verschiebung (m) und Drehung (Grad) gegenüber dem Handknochen
@export var grip_offset := Vector3.ZERO
@export var grip_rotation_deg := Vector3.ZERO
## mit beiden Händen gehalten (Gewehre) oder einer (Pistolen)
@export var two_handed := true


func max_range_m() -> int:
	return inc_m * stages


## Wählbare Klänge (Ausrüstungs-Editor): Schlüssel → Name. Synthetisch erzeugt (Sfx) oder als Datei
## res://audio/sfx/<Schlüssel>.ogg (Free Firearm Sound Library, CC0; siehe assets/LICENSES.md).
const SOUNDS := {
	&"laser": "Laser", &"gewehr": "Gewehr (synthetisch)", &"mg": "MG (synthetisch)", &"rakete": "Rakete",
	&"nahkampf": "Nahkampf", &"psi": "Psi",
	&"pistole": "Pistole", &"revolver": "Revolver", &"mp": "MP (Salve)", &"sturmgewehr": "Sturmgewehr (Salve)",
	&"minigun": "Minigun", &"schrotflinte": "Schrotflinte", &"gewehr_schwer": "Schweres Gewehr",
}


func sound() -> StringName:
	if sound_id != &"":
		return sound_id
	if psi:
		return &"psi"
	if melee:
		return &"nahkampf"
	if not splash.is_empty():
		return &"rakete"
	if table and table.id == &"strahl":
		return &"laser"
	if shots > 1:   # Feuerstoß (früher ob_bonus > 0; seit den Magazinen spielte das MG sonst den Gewehr-Klang)
		return &"mg"
	return &"gewehr"
