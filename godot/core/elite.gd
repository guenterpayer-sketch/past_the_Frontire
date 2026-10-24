class_name Elite
## Elite- und Boss-Kämpfe und Schwierigkeitsgrad (Hub Auftrag 10, Entscheidungen des Nutzers 24.10.2026).
## Gemeinsame Funktion für Aufträge und Feindkontakt: roll(seed) ≈ 13 %. Stufe als Text: "" | "elite" | "boss".
## Boden: Mission.elite (StringName, vom Bodenkampf; Form Trupp/Kern/Boss wählt er), Raum: setup.enemy.elite/boss/boss_name.

const CHANCE := 0.13
const ELITE := "elite"
const BOSS := "boss"
## Anteil der Bodenaufträge mit einer Person als Ziel („Kopfgeld“, Boss-Kampf)
const BOUNTY_CHANCE := 0.10
## Schwierigkeitsgrad (Spieleinstellung, im Spielstand): Faktor für Boden (Mission.generate) und Raum (setup.difficulty_factor)
const LEVELS := {"leicht": 0.8, "normal": 1.0, "schwer": 1.25}
const LEVEL_NAMES := {"leicht": "Leicht", "normal": "Normal", "schwer": "Schwer"}
const BOSS_FIRST := ["Varek", "Mora", "Dask", "Ilyen", "Korr", "Sabine", "Tobor", "Neela", "Graff", "Yun", "Ostrow", "Kalla"]
const BOSS_EPITHET := ["die Klinge", "der Schlächter", "Eisenhand", "die Natter", "der Graue", "Zwei-Messer", "die Witwe",
	"der Lange", "Rostzahn", "die Stille"]


## Elite-Wurf aus dem Seed des Auftrags bzw. Kontakts (fest, damit Neuladen nichts ändert)
static func roll(seed_value: int) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("elite/%d" % seed_value)
	return rng.randf() < CHANCE


## Kennzeichen für Angebot, Kontakt und Bericht
static func label(level: String) -> String:
	return {ELITE: "★ Elite", BOSS: "★ Boss"}.get(level, "")


## Name einer Zielperson (Boss), fest aus dem Seed
static func boss_name(seed_value: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("boss/%d" % seed_value)
	return "%s „%s“" % [BOSS_FIRST[rng.randi_range(0, BOSS_FIRST.size() - 1)], BOSS_EPITHET[rng.randi_range(0, BOSS_EPITHET.size() - 1)]]


static func factor(level_id: String) -> float:
	return float(LEVELS.get(level_id, 1.0))


## Mission erzeugen: mit Schwierigkeitsfaktor, sobald Mission.generate ihn annimmt (Bodenkampf), sonst wie bisher
static func generate(seed_value: int, difficulty: String, faction_path: String, diff_factor := 1.0) -> Mission:
	if _generate_args() >= 4:
		return (Mission as Script).callv("generate", [seed_value, difficulty, faction_path, diff_factor]) as Mission
	var m := Mission.generate(seed_value, difficulty, faction_path)
	if "difficulty_factor" in m:
		m.set("difficulty_factor", diff_factor)
	return m


## Elite-Stufe an die Mission geben, sobald sie das Feld hat (Bodenkampf: Mission.elite = "" | &"elite" | &"boss")
static func apply(m: Mission, level: String) -> void:
	if m != null and level != "" and "elite" in m:
		m.set("elite", StringName(level))


static var _args := -1


static func _generate_args() -> int:
	if _args < 0:
		_args = 3
		for f in (Mission as Script).get_script_method_list():
			if String(f.name) == "generate":
				_args = (f.args as Array).size()
	return _args
