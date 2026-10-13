class_name Combatant
extends RefCounted
## Eine Figur im Kampf: Werte aus der Vorlage (UnitData) plus Kampfzustand.

enum State { OK, KO, DEAD }

var data: UnitData
var id: StringName
var name: String
var letter: String
var role: String
var color: Color
var team: StringName          # &"crew" oder &"enemy"
var is_crew := false
var attrs: Dictionary
var skills: Dictionary        # Fertigkeit -> {rank, xp}
var weapons: Array[WeaponData] = []
var weapon: WeaponData        # aktuell geführte Waffe
var armor: ArmorData
var shield := false

var max_hp := 0
var hp := 0
var max_pp := 0
var pp := 0
var state := State.OK
var bleed := 0
var stun := 0
var malus := 0
var prone := false
var next_attack_malus := 0
var psi_shield := 0
var medkit := 0
var loaded := {}   # Waffen-ID -> Schuss in der Waffe
var ammo := {}     # Waffen-ID -> Reserve

var pos := Vector2i.ZERO
var facing := 0
var crouched := false
var init := 0
var init_roll := ""

# Aktivität (RMSS): 100 % pro Runde
var act := 0
var reserve := 50             # zurückgehaltene Aktivität als Ausweichreserve
var acted := false
var has_attacked := false
var ran := false
var sprinted := false
var stunned_now := false
var free_hex := 0
var move_spare := 0.0
var overwatch := {}           # {} oder {"weapon": WeaponData, "pct": int}
var waiting := false
var wait_round := 0
var wait_act := 0

var xp_log := {}
var kills := 0


static func create(d: UnitData, team_id: StringName, saved_skills := {}) -> Combatant:
	var u := Combatant.new()
	u.data = d
	u.id = d.id
	u.name = d.name
	u.letter = d.letter
	u.role = d.role
	u.color = d.color
	u.team = team_id
	u.is_crew = team_id == &"crew"
	u.attrs = d.attrs.duplicate()
	u.skills = {}
	for k in d.skills:
		u.skills[StringName(k)] = {"rank": int(d.skills[k]), "xp": 0}
	for k in saved_skills:
		u.skills[StringName(k)] = saved_skills[k].duplicate()
	u.weapons = d.weapons.duplicate()
	u.weapon = u.weapons[0]
	u.armor = d.armor
	u.shield = d.shield
	u.max_hp = Rules.max_hp(u)
	u.hp = u.max_hp
	u.max_pp = Rules.max_pp(u)
	u.pp = u.max_pp
	u.medkit = d.medkits
	for w in u.weapons:
		if w.magazine > 0:
			u.loaded[w.id] = w.magazine
			u.ammo[w.id] = w.ammo_total - w.magazine
	u.facing = 0 if u.is_crew else 3
	return u


func is_ok() -> bool:
	return state == State.OK


func is_dead() -> bool:
	return state == State.DEAD


func state_name() -> String:
	return ["kampffähig", "bewusstlos", "tot"][state]


func has_overwatch() -> bool:
	return not overwatch.is_empty()


func status_list() -> PackedStringArray:
	var s := PackedStringArray()
	if bleed:
		s.append("Blutung %d" % bleed)
	if stun:
		s.append("Betäubt %d" % stun)
	if malus:
		s.append("Wunden %d" % malus)
	if prone:
		s.append("Niedergeworfen")
	if has_overwatch():
		s.append("Feuerbereitschaft %d %%" % overwatch.pct)
	if crouched:
		s.append("geduckt")
	if waiting:
		s.append("wartet ab")
	if medkit:
		s.append("Medikit %d×" % medkit)
	if ran:
		s.append("gelaufen (Angriff −20)")
	if sprinted:
		s.append("gesprintet (kein Angriff)")
	if psi_shield:
		s.append("Psi-Schild %d" % psi_shield)
	if next_attack_malus:
		s.append("Waffe klemmt %d" % next_attack_malus)
	return s
