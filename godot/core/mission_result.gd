class_name MissionResult
extends RefCounted
## Was ein Kampfmodul (Bodenkampf, später Raumkampf) nach dem Einsatz an das Charakter-Modul zurückgibt.
## Reine Daten (Dictionary), damit jedes Kampfmodul dasselbe Format liefern kann:
## {outcome: &"sieg"/&"niederlage", mission: Titel, rounds, reward_xp,
##  units: {Figur-ID: {xp: {Fertigkeit: EP}, free_xp, kills,
##          status: {state: "ok"/"ko"/"tot", hp, max_hp, bleed, malus},
##          used: {medkits, ammo: {Waffen-ID: Schuss}}}}}

## freie EP pro Einsatz für jede Figur (dazu bei Sieg die Missionsbelohnung)
const FREE_XP := 3
const STATES := ["ok", "ko", "tot"]


static func from_combat(c: Combat, mission: Mission = null) -> Dictionary:
	var win := c.result == &"sieg"
	var reward := mission.reward_xp if mission and win else 0
	var units := {}
	for u in c.crew():
		var ammo := {}
		for w in u.weapons:
			if w.magazine > 0:
				var n: int = w.ammo_total - u.loaded.get(w.id, 0) - u.ammo.get(w.id, 0)
				if n > 0:
					ammo[String(w.id)] = n
		units[u.id] = {
			"xp": u.xp_log.duplicate(),
			"free_xp": FREE_XP + reward,
			"kills": u.kills,
			"status": {"state": STATES[u.state], "hp": u.hp, "max_hp": u.max_hp, "bleed": u.bleed, "malus": u.malus},
			"used": {"medkits": u.medkit_start - u.medkit, "ammo": ammo},
		}
	return {"outcome": c.result, "mission": mission.title if mission else "", "rounds": c.round_no,
		"reward_xp": reward, "units": units}
