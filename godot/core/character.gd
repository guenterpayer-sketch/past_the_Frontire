class_name Character
extends RefCounted
## Ein Mitglied der Crew zwischen den Einsätzen: alle dauerhaften Werte (Eigenschaften, Fertigkeiten mit Rang und EP,
## freie EP, Ausrüstung, Aussehen). Wird im Charakter-Modul bearbeitet und in user://crew.json gespeichert.
## Kampfmodule bekommen davon nur Kopien (Combatant.from_character) und geben ein Einsatzergebnis zurück
## (MissionResult), das apply_result verbucht.

var id: StringName
## Herkunft im globalen Roster (GlobalRoster); Kopien im Spiel behalten sie, damit niemand doppelt an Bord kommt
var roster_id: StringName
var name := ""
var letter := ""
var role := ""
var color := Color.WHITE
var attrs := {}
var skills := {}              # Fertigkeit -> {rank, xp}
var free_xp := 0
var weapons: Array[WeaponData] = []
var armor: ArmorData
var shield := false
var medkits := 0
var visual: CharacterVisual
## Station an Bord (Creation.STATIONS, "" = keine)
var station := ""
## Verwundung (Injury): Stufe ("" = unverletzt) und Resttage bis zur Heilung
var injury := ""
var injury_days := 0
## In dieser Levelphase neu begonnene Psi-Liste (höchstens eine; wird nach jedem Einsatz geleert)
var new_list: StringName = &""
## Zustand nach dem letzten Einsatz ({state, hp, max_hp, bleed, malus}); wird noch nicht ausgewertet
## (Heilung und Tod zwischen Einsätzen sind noch nicht gebaut)
var status := {}
## Verbrauch im letzten Einsatz ({medkits, ammo: {Waffen-ID: Schuss}}); wird noch nicht ausgewertet (kein Nachschub)
var used := {}

## Rules erwartet diese Felder bei jeder Figur
var is_crew := true
var xp_log := {}


## Neuer Charakter aus einer Vorlage (data/units/…)
static func from_unit(d: UnitData) -> Character:
	var c := Character.new()
	c.id = d.id
	c.roster_id = d.id
	c.name = d.name
	c.letter = d.letter
	c.role = d.role
	c.color = d.color
	c.attrs = {}
	for k in d.attrs:
		c.attrs[String(k)] = int(d.attrs[k])
	for k in d.skills:
		c.skills[StringName(k)] = {"rank": int(d.skills[k]), "xp": 0}
	c.weapons = d.weapons.duplicate()
	c.armor = d.armor
	c.shield = d.shield
	c.medkits = d.medkits
	c.visual = d.visual
	return c


## Fortschritt im alten Speicherformat (Version 1/2: nur Fertigkeiten, Eigenschaften, freie EP) übernehmen
func apply_progress(saved: Dictionary) -> Character:
	var saved_attrs: Dictionary = saved.get("attrs", {})
	for k in saved_attrs:
		attrs[String(k)] = int(saved_attrs[k])
	var saved_skills: Dictionary = saved.get("skills", {})
	for k in saved_skills:
		var s: Dictionary = saved_skills[k]
		skills[StringName(k)] = {"rank": int(s.get("rank", 0)), "xp": int(s.get("xp", 0))}
	free_xp = int(saved.get("free_xp", free_xp))
	return self


## Einsatzergebnis einer Figur verbuchen: EP auf die benutzten Fertigkeiten, freie EP, Zustand und Verbrauch merken
func apply_result(r: Dictionary) -> void:
	var xp: Dictionary = r.get("xp", {})
	for k in xp:
		Rules.ensure_skill(self, StringName(k)).xp += int(xp[k])
	free_xp += int(r.get("free_xp", 0))
	new_list = &""
	var inj := Injury.combine(injury, injury_days, Injury.from_result(r))
	injury = inj.stage
	injury_days = inj.days
	status = r.get("status", {}).duplicate(true)
	used = r.get("used", {}).duplicate(true)


## Heilung um n Tage; true, wenn die Figur danach wieder unverletzt ist
func heal(days: int) -> bool:
	if injury == "" or days <= 0:
		return false
	injury_days -= days
	if injury_days <= 0:
		injury = ""
		injury_days = 0
		return true
	return false


func is_locked() -> bool:
	return Injury.is_locked(injury)


## Zustand als Text, z. B. „schwer verwundet · noch 7 Tage“ ("" = unverletzt)
func injury_text() -> String:
	if injury == "":
		return ""
	return "%s · noch %d %s" % [Injury.name(injury), injury_days, "Tag" if injury_days == 1 else "Tage"]


func duplicate_character() -> Character:
	return Character.from_dict(to_dict())


# ---------------------------------------------------------------- Speichern

func to_dict() -> Dictionary:
	var sk := {}
	for k in skills:
		sk[String(k)] = {"rank": int(skills[k].rank), "xp": int(skills[k].xp)}
	return {
		"id": String(id), "roster_id": String(roster_id), "name": name, "letter": letter, "role": role, "color": color.to_html(false),
		"attrs": attrs.duplicate(), "skills": sk, "free_xp": free_xp,
		"weapons": weapons.map(func(w: WeaponData) -> String: return w.resource_path),
		"armor": armor.resource_path if armor else "", "shield": shield, "medkits": medkits,
		"visual": visual.resource_path if visual else "", "station": station, "new_list": String(new_list), "injury": injury, "injury_days": injury_days,
		"status": status.duplicate(true), "used": used.duplicate(true),
	}


static func from_dict(d: Dictionary) -> Character:
	var c := Character.new()
	c.id = StringName(d.get("id", ""))
	c.roster_id = StringName(d.get("roster_id", d.get("id", "")))
	c.name = d.get("name", "")
	c.letter = d.get("letter", "")
	c.role = d.get("role", "")
	c.color = Color.html(d.get("color", "ffffff"))
	c.attrs = {}
	var a: Dictionary = d.get("attrs", {})
	for k in a:
		c.attrs[String(k)] = int(a[k])
	c.apply_progress({"skills": d.get("skills", {})})
	c.free_xp = int(d.get("free_xp", 0))
	for p in d.get("weapons", []):
		var w := _load(p) as WeaponData
		if w:
			c.weapons.append(w)
	c.armor = _load(d.get("armor", "")) as ArmorData
	c.shield = bool(d.get("shield", false))
	c.medkits = int(d.get("medkits", 0))
	c.visual = _load(d.get("visual", "")) as CharacterVisual
	c.station = d.get("station", "")
	c.new_list = StringName(d.get("new_list", ""))
	c.injury = d.get("injury", "")
	c.injury_days = int(d.get("injury_days", 0))
	c.status = d.get("status", {})
	c.used = d.get("used", {})
	return c


## Ressource nur laden, wenn es sie (noch) gibt
static func _load(path: String) -> Resource:
	return load(path) if path != "" and ResourceLoader.exists(path) else null


## Vollständig genug für einen Kampf?
func is_valid() -> bool:
	return id != &"" and not weapons.is_empty() and armor != null and Rules.ATTRIBUTES.all(func(x: Dictionary) -> bool: return attrs.has(x.id))
