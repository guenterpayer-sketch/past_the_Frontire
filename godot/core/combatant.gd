class_name Combatant
extends RefCounted
## Eine Figur im Kampf: Kopie der dauerhaften Werte (Character) plus Kampfzustand.
## Änderungen hier wirken nicht auf den Character zurück; was bleibt, meldet MissionResult.

## DYING = sterbend: wäre nach den Regeln tot, ist aber nur kampfunfähig (Erste Hilfe kann stabilisieren).
## DEAD gibt es nur noch durch den Todeswurf am Kampfende, wenn die ganze Crew gefallen ist.
enum State { OK, KO, DYING, DEAD }

var visual: CharacterVisual
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
var medkit_start := 0
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
var powers: Array[String] = []   # unterstützende Psi-Kräfte (PsiCombat.SUPPORT)
const BUFF_NAMES := {"abschirmen": "Abgeschirmt", "ablenkfeld": "Ablenkfeld", "kuppel": "Schildkuppel", "barriere": "Letzte Barriere",
	"schmerz": "Schmerz gedämpft", "gefahrensinn": "Gefahrensinn", "geortet": "geortet", "vorahnung": "Vorahnung", "schwachstelle": "Schwachstelle"}
## laufende Wirkungen: Name → {rounds, …}; rounds −1 = bis verbraucht (Barriere, Vorahnung, Schwachstelle)
var buffs := {}
var disarmed := false            # Entwaffnen: im nächsten eigenen Zug kein Angriff
var stabilized := false        # sterbend, aber per Erster Hilfe stabilisiert
var worst_crit := ""           # schwerster erlittener Kritischer (A–E), "" = keiner
var free_xp := 0              # gesparte freie EP (für Fertigkeiten oder Eigenschaften)


## Figur aus einer Vorlage (Gegner, Tests); saved = Fortschritt im alten Format {skills, attrs, free_xp}
static func create(d: UnitData, team_id: StringName, saved := {}) -> Combatant:
	return from_character(Character.from_unit(d).apply_progress(saved), team_id)


## Kampfbereite Kopie eines Charakters (volle TP und PP, volle Ausrüstung)
static func from_character(ch: Character, team_id: StringName) -> Combatant:
	var u := Combatant.new()
	u.visual = ch.visual
	u.id = ch.id
	u.name = ch.name
	u.letter = ch.letter
	u.role = ch.role
	u.color = ch.color
	u.team = team_id
	u.is_crew = team_id == &"crew"
	u.attrs = ch.attrs.duplicate()
	u.skills = ch.skills.duplicate(true)
	u.free_xp = ch.free_xp
	# Psi gibt es im Kampf nur noch über die Listen: alte Psi-Waffen fallen weg, Angriffskräfte kommen als Waffen dazu
	u.weapons.assign(ch.weapons.filter(func(w: WeaponData) -> bool: return not w.psi))
	u.weapons.append_array(PsiCombat.attack_weapons(ch))
	if u.weapons.is_empty():
		u.weapons = ch.weapons.duplicate()   # Notfall: Figur hätte sonst gar nichts
	u.powers = PsiCombat.support_powers(ch)
	u.weapon = u.weapons[0]
	u.armor = ch.armor
	u.shield = ch.shield
	u.max_hp = Rules.max_hp(u)
	u.hp = u.max_hp
	u.max_pp = Rules.max_pp(u)
	u.pp = u.max_pp
	u.medkit = ch.medkits
	u.medkit_start = ch.medkits
	if ch.injury == Injury.LIGHT:
		u.malus = Injury.LIGHT_MALUS
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


## kampfunfähig am Boden (bewusstlos oder sterbend)
func is_down() -> bool:
	return state == State.KO or state == State.DYING


func state_name() -> String:
	if state == State.DYING and stabilized:
		return "stabilisiert"
	return ["kampffähig", "bewusstlos", "sterbend", "tot"][state]


func has_overwatch() -> bool:
	return not overwatch.is_empty()


func status_list() -> PackedStringArray:
	var s := PackedStringArray()
	if state == State.DYING:
		s.append("stabilisiert" if stabilized else "sterbend")
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
	for b in buffs:
		var r: int = buffs[b].get("rounds", -1)
		s.append(BUFF_NAMES.get(b, b) + ((" %d" % r) if r > 0 else ""))
	if disarmed:
		s.append("entwaffnet")
	if next_attack_malus:
		s.append("Waffe klemmt %d" % next_attack_malus)
	return s
