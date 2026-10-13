class_name Tables
extends RefCounted
## Nachschlagen auf Angriffstabellen, Kritische Treffer, Patzer. Daten liegen unter res://data/tables.

const ARMOR_CLASSES := ["Keine", "Leicht", "Mittel", "Schwer"]
const ARMOR_DMG := [1.0, 0.9, 0.8, 0.65]
const SEVERITIES := ["A", "B", "C", "D", "E"]
const SEVERITY_MOD := {"A": -20, "B": -10, "C": 0, "D": 10, "E": 20}
const CRIT_GAP := 40       # ab Schwelle + 40 beginnt der kritische Bereich
const CRIT_STEP := 15      # alle 15 Punkte ein Grad mehr (E ab Schwelle + 100)
const CRIT_BANDS := [20, 40, 60, 80, 95, 110]
const CRIT_BAND_NAMES := ["01–20", "21–40", "41–60", "61–80", "81–95", "96–110", "111+"]
const RANGE_STEP := -20    # je Reichweitenstufe über der ersten
const POINT_BLANK_M := 3.0 # bis 3 m: +10


## Ergebnis auf einer Angriffstabelle: {hit, threshold, dmg, severity ("" = keiner), crit}
static func lookup_attack(table: AttackTableData, total: int, armor_cls: int, dmg_mult: float) -> Dictionary:
	var thr: int = table.thresholds[armor_cls]
	if total < thr:
		return {"hit": false, "threshold": thr}
	var armor_f: float = 1.0 if table.ignores_armor else ARMOR_DMG[armor_cls]
	var dmg := maxi(1, roundi((2.0 + (total - thr) / 8.0) * dmg_mult * armor_f))
	var severity := ""
	var crit_start := thr + CRIT_GAP
	if total >= crit_start:
		severity = SEVERITIES[mini(4, floori(float(total - crit_start) / CRIT_STEP))]
	return {"hit": true, "threshold": thr, "dmg": dmg, "severity": severity, "crit": table.crit}


## Kritischer Treffer: W100 (geschlossen) + Grad-Modifikator
static func roll_crit(table: CritTableData, severity: String) -> Dictionary:
	var roll := Dice.d100()
	var total: int = roll + SEVERITY_MOD[severity]
	var idx := CRIT_BANDS.size()
	for i in CRIT_BANDS.size():
		if total <= CRIT_BANDS[i]:
			idx = i
			break
	return {"roll": roll, "total": total, "row": table.rows[idx], "table": table.name}


static func roll_fumble(table: FumbleTableData) -> Dictionary:
	var roll := Dice.d100()
	for row in table.rows:
		if roll <= row.up_to:
			return {"roll": roll, "row": row}
	return {"roll": roll, "row": table.rows[-1]}
