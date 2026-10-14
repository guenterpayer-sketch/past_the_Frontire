class_name Injury
extends RefCounted
## Verwundung statt Tod (docs/Skillsystem.md, 8a; docs/Planung_Roster_Verwundung.md, B):
## Stufe und Resttage aus dem Einsatzergebnis einer Figur, Heilung in Spieltagen.

const NONE := ""
const LIGHT := "angeschlagen"      # darf mit, Malus
const DOWN := "kampfunfaehig"      # gesperrt
const SEVERE := "schwer"           # gesperrt

const ORDER := [NONE, LIGHT, DOWN, SEVERE]
const NAMES := {NONE: "unverletzt", LIGHT: "angeschlagen", DOWN: "kampfunfähig", SEVERE: "schwer verwundet"}
## Grundtage je Stufe und Zuschlag für den schwersten erlittenen Kritischen (Werte aus docs/module/hub.md)
const DAYS := {LIGHT: 2, DOWN: 5, SEVERE: 10}
const CRIT_DAYS := {"": 0, "A": 0, "B": 1, "C": 2, "D": 3, "E": 4}
## Malus im Einsatz für Angeschlagene (Wundmalus wie bei Kritischen, negativ)
const LIGHT_MALUS := -10


## Stufe und Tage aus dem MissionResult einer Figur: {stage, days} (stage "" = unverletzt)
static func from_result(r: Dictionary) -> Dictionary:
	var st: Dictionary = r.get("status", {})
	var crit: String = r.get("worst_crit", "")
	var stage := NONE
	if r.get("dying", false) or r.get("stabilized", false) or st.get("state", "") == "sterbend":
		stage = SEVERE
	elif st.get("state", "") == "ko":
		stage = DOWN
	elif crit != "" or int(st.get("hp", 0)) * 2 < int(st.get("max_hp", 0)):
		stage = LIGHT
	if stage == NONE:
		return {"stage": NONE, "days": 0}
	return {"stage": stage, "days": DAYS[stage] + int(CRIT_DAYS.get(crit, 0))}


## Neue Verwundung zur bestehenden: die schlimmere Stufe, Tage addiert
static func combine(old_stage: String, old_days: int, new: Dictionary) -> Dictionary:
	if new.stage == NONE:
		return {"stage": old_stage, "days": old_days}
	if old_stage == NONE:
		return new.duplicate()
	var stage: String = old_stage if ORDER.find(old_stage) >= ORDER.find(new.stage) else new.stage
	return {"stage": stage, "days": old_days + int(new.days)}


## gesperrt für Einsätze (kampfunfähig, schwer verwundet)
static func is_locked(stage: String) -> bool:
	return stage == DOWN or stage == SEVERE


static func name(stage: String) -> String:
	return NAMES.get(stage, stage)
