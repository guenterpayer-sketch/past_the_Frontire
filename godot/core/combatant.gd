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
var ammo_start := {}   # Waffen-ID -> mitgenommene Schuss (für den Verbrauch)

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
## Beschädigung der Ausrüstung (Entscheidungen des Nutzers 16.10.2026): Platz → Abzug (−10 je Schaden),
## Plätze "w0" (Waffe 1), "w1" (Waffe 2), "armor"; ab WEAR_BROKEN unbrauchbar. Kommt aus Character.wear (falls vorhanden).
## Positiver Wert = gutes Stück aus dem Handwerk (+5, Stock.BONUS): Bonus auf Angriff bzw. Verteidigung, der erste Schaden nimmt ihn (+5 → 0).
const WEAR_STEP := -10
const WEAR_BROKEN := -30
var wear := {}
var lost: Array[String] = []   # bei Niederlage ohne Rückzug verlorene Plätze
## Eigenheit der Fraktion (FactionData.trait_mods + name), leer bei der Crew
var faction_trait := {}
var repaired: Array[String] = []   # Waffen-Plätze, an denen in diesem Kampf schon repariert wurde (einmal je Stück)


## Figur aus einer Vorlage (Gegner, Tests); saved = Fortschritt im alten Format {skills, attrs, free_xp}
static func create(d: UnitData, team_id: StringName, saved := {}) -> Combatant:
	var u := from_character(Character.from_unit(d).apply_progress(saved), team_id)
	u.faction_trait = d.faction_trait.duplicate()
	var t := u.faction_trait
	if t.has("hp_pct"):
		u.max_hp = roundi(u.max_hp * (1.0 + float(t.hp_pct) / 100.0))
		u.hp = u.max_hp
	if t.has("wear"):
		for slot in ["w0", "w1"]:
			if int(slot.substr(1)) < u.weapons.size() and u.weapons[int(slot.substr(1))].power == "":
				u.wear[slot] = int(t.wear)
	return u


## Wert der Fraktions-Eigenheit (0, wenn keine)
func trait_val(key: String) -> int:
	return int(faction_trait.get(key, 0))


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
	var w0: Variant = ch.get("wear")
	if w0 is Dictionary:
		u.wear = (w0 as Dictionary).duplicate()
	if ch.injury == Injury.LIGHT:
		u.malus = Injury.LIGHT_MALUS
	for slot in u.weapons.size():
		var w := u.weapons[slot]
		if w.magazine > 0:   # voll; den Schiffsvorrat legt Ammo.apply() darüber
			var n := Ammo.carry(w, slot)
			u.loaded[w.id] = mini(n, w.magazine)
			u.ammo[w.id] = n - u.loaded[w.id]
			u.ammo_start[w.id] = n
	u.facing = 0 if u.is_crew else 3
	return u


## Platz einer Waffe ("w0"/"w1"); Psi-Kräfte und Waffen ab Platz 3 haben keinen
func slot_of(w: WeaponData) -> String:
	var i := weapons.find(w)
	return "w%d" % i if i >= 0 and i <= 1 and w.power == "" else ""


func weapon_wear(w: WeaponData) -> int:
	return int(wear.get(slot_of(w), 0))


func weapon_broken(w: WeaponData) -> bool:
	return weapon_wear(w) <= WEAR_BROKEN


## Rüstung ab WEAR_BROKEN wie keine: Klasse 0, keine Verteidigung
func armor_broken() -> bool:
	return int(wear.get("armor", 0)) <= WEAR_BROKEN


func armor_cls() -> int:
	return 0 if armor == null or armor_broken() else armor.cls


func armor_db() -> int:
	return 0 if armor == null or armor_broken() else armor.db


## Platz um einen Schaden verschlechtern (höchstens bis WEAR_BROKEN; ein Bonus fällt auf 0); gibt den neuen Wert zurück
func add_wear(slot: String) -> int:
	if slot == "":
		return 0
	var v := int(wear.get(slot, 0))
	wear[slot] = 0 if v > 0 else maxi(v + WEAR_STEP, WEAR_BROKEN)
	return wear[slot]


## Text für den Kampfbericht nach add_wear: „beschädigt (−10)“ bzw. „verliert den Bonus“
static func wear_log(v: int) -> String:
	return "verliert den Bonus" if v == 0 else "beschädigt (%d)" % v


## Ausrüstung eines Platzes (WeaponData/ArmorData) oder null
func gear_at(slot: String) -> Resource:
	if slot == "armor":
		return armor
	var i := int(slot.substr(1)) if slot.begins_with("w") else -1
	return weapons[i] if i >= 0 and i < weapons.size() and weapons[i].power == "" else null


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
	for slot in ["w0", "w1", "armor"]:
		var v := int(wear.get(slot, 0))
		var g := gear_at(slot)
		if v < 0 and g:
			s.append("%s %s" % [g.get("name"), "unbrauchbar" if v <= WEAR_BROKEN else "beschädigt %d" % v])
	return s
