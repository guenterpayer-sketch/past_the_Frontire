extends RefCounted
## Angriffstabellen und Waffen – übernommen aus js/tables.js (Ausschnitt für den Prototyp).

const ATTACK_TABLES := {
	"projektil": {"hit": [80, 85, 90, 100]},
	"strahl": {"hit": [80, 85, 90, 95]},
}
const ARMOR_NAMES := ["Keine", "Leicht", "Mittel", "Schwer"]
const ARMOR_DMG := [1.0, 0.9, 0.8, 0.65]
const CRIT_GAP := 40
const CRIT_STEP := 15
const SEVERITIES := ["A", "B", "C", "D", "E"]
const RANGE_STEP := -20
const POINT_BLANK_M := 3.0
const OUT_OF_RANGE := -999

const WEAPONS := {
	"sturmgewehr": {"name": "Sturmgewehr", "table": "projektil", "inc": 25.0, "stages": 4, "fumble": 3, "dmg": 1.0},
	"laserkarabiner": {"name": "Laserkarabiner", "table": "strahl", "inc": 15.0, "stages": 4, "fumble": 2, "dmg": 0.9},
}


## Wie lookupAttack in js/tables.js: Treffer ab Schwelle, Schaden steigt je 8 Punkte darüber,
## Kritische ab Schwelle + 40, alle 15 Punkte ein Grad mehr.
static func lookup_attack(table_id: String, total: int, armor_cls: int, dmg_mult: float) -> Dictionary:
	var thr: int = ATTACK_TABLES[table_id].hit[armor_cls]
	if total < thr:
		return {"hit": false, "threshold": thr}
	var dmg := maxi(1, roundi((2.0 + (total - thr) / 8.0) * dmg_mult * ARMOR_DMG[armor_cls]))
	var severity := ""
	var crit_start := thr + CRIT_GAP
	if total >= crit_start:
		severity = SEVERITIES[mini(4, floori((total - crit_start) / float(CRIT_STEP)))]
	return {"hit": true, "threshold": thr, "dmg": dmg, "severity": severity}


## Reichweitenstufen: bis 3 m +10, erste Stufe ±0, jede weitere −20
static func range_mod(w: Dictionary, dist_m: float) -> int:
	if dist_m <= POINT_BLANK_M:
		return 10
	var stage := ceili(dist_m / w.inc) - 1
	if stage >= w.stages:
		return OUT_OF_RANGE
	return stage * RANGE_STEP
