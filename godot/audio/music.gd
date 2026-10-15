extends Node
## Musik (Autoload "Music"). Ein Anlass = ein Ordner unter res://audio/music/ mit beliebig vielen MP3/OGG-Dateien;
## liegen mehrere darin, wechselt die Musik nach jedem Stück zufällig (ein Stück allein läuft in Schleife).
## Alle Anlässe laufen in Schleife, bis ein anderer Anlass kommt; Wechsel werden weich überblendet.
## Aufruf: Music.play(Music.SHIP). Leerer oder fehlender Ordner = Stille.
## Lautstärke Musik und Effekte über die Audio-Busse "Music" und "SFX", gespeichert in user://audio.cfg.

const DIR := "res://audio/music/"
const START := &"start"          # Startmenü (auch Roster)
const SHIP := &"ship"            # Schiff mit Sternenkarte
const BRIEFING := &"briefing"    # Bodenkampf: Briefing und Aufstellung (Runde 0)
const BATTLE := &"battle"        # Bodenkampf ab Runde 1
const VICTORY := &"victory"      # Ergebnis Sieg
const DEFEAT := &"defeat"        # Ergebnis Niederlage oder Rückzug
const THEMES := [START, SHIP, BRIEFING, BATTLE, VICTORY, DEFEAT]

const FADE := 1.5
const SILENT_DB := -60.0
const CFG := "user://audio.cfg"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
## Lautstärke in Prozent, Schritte für die Regler
const STEP := 10
const DEFAULT_VOLUME := {BUS_MUSIC: 70, BUS_SFX: 100}

var theme := &""
var track := ""
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _tweens: Array[Tween] = [null, null]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(b) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, b)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")
	# Effekte (Autoload Sfx, vor Music geladen) auf den Effekt-Bus legen
	var sfx := get_node_or_null(^"/root/Sfx")
	if sfx:
		for c in sfx.get_children():
			if c is AudioStreamPlayer:
				(c as AudioStreamPlayer).bus = BUS_SFX
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = BUS_MUSIC
		p.volume_db = SILENT_DB
		p.finished.connect(_on_finished.bind(i))
		add_child(p)
		_players.append(p)
	for b in [BUS_MUSIC, BUS_SFX]:
		_apply_volume(b)


## Musik für einen Anlass (THEMES). Läuft der Anlass schon, passiert nichts.
func play(name: StringName) -> void:
	if name == theme:
		return
	theme = name
	_start(_pick(tracks(name), ""))


## Weich ausblenden (Stille)
func stop() -> void:
	theme = &""
	_start("")


## Stücke eines Anlasses (Pfade, sortiert)
static func tracks(name: StringName) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DIR + String(name) + "/"
	var files := ResourceLoader.list_directory(dir) if DirAccess.dir_exists_absolute(dir) else PackedStringArray()
	for f in files:
		var e := f.get_extension().to_lower()
		if e == "mp3" or e == "ogg":
			out.append(dir + f)
	out.sort()
	return out


func _pick(list: PackedStringArray, avoid: String) -> String:
	if list.is_empty():
		return ""
	if list.size() == 1:
		return list[0]
	var pool := Array(list).filter(func(t: String) -> bool: return t != avoid)
	return pool[randi() % pool.size()]


## Neues Stück auf dem freien Spieler einblenden, das alte ausblenden ("" = nur ausblenden)
func _start(path: String) -> void:
	var old := _active
	_fade(old, SILENT_DB, true)
	track = path
	if path == "":
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	var single := tracks(theme).size() <= 1
	if "loop" in stream:
		stream.set("loop", single)
	_active = 1 - old
	var p := _players[_active]
	p.stream = stream
	p.volume_db = SILENT_DB
	p.play()
	_fade(_active, 0.0, false)


func _fade(i: int, db: float, stop_after: bool) -> void:
	if _tweens[i]:
		_tweens[i].kill()
	var p := _players[i]
	if not p.playing:
		return
	var t := create_tween()
	t.tween_property(p, "volume_db", db, FADE)
	if stop_after:
		t.tween_callback(p.stop)
	_tweens[i] = t


## Stück zu Ende (mehrere Stücke im Anlass): nächstes, möglichst ein anderes
func _on_finished(i: int) -> void:
	if i != _active or theme == &"":
		return
	var path := _pick(tracks(theme), track)
	if path == "":
		return
	track = path
	var p := _players[i]
	p.stream = load(path)
	p.volume_db = 0.0
	p.play()


# ---------------------------------------------------------------- Lautstärke

## Lautstärke in Prozent (0–100) für BUS_MUSIC oder BUS_SFX
static func get_volume(bus: StringName) -> int:
	var cfg := ConfigFile.new()
	cfg.load(CFG)
	return clampi(int(cfg.get_value("volume", String(bus), DEFAULT_VOLUME[bus])), 0, 100)


func set_volume(bus: StringName, percent: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(CFG)
	cfg.set_value("volume", String(bus), clampi(percent, 0, 100))
	cfg.save(CFG)
	_apply_volume(bus)


func _apply_volume(bus: StringName) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	var v := get_volume(bus)
	AudioServer.set_bus_mute(i, v <= 0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 1) / 100.0))


## Zwei Regler „Musik“ und „Effekte“ (10er-Schritte, sofort wirksam) zum Einbauen in Einstellungsdialoge
func volume_rows() -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	for spec in [[BUS_MUSIC, "Musik"], [BUS_SFX, "Effekte"]]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var title := UiTheme.label(spec[1], 15)
		title.custom_minimum_size.x = 110
		row.add_child(title)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 100
		s.step = STEP
		s.value = get_volume(spec[0])
		s.custom_minimum_size = Vector2(260, 32)
		s.tooltip_text = "Lautstärke %s" % spec[1]
		row.add_child(s)
		var val := UiTheme.label("%d %%" % int(s.value), 15)
		val.custom_minimum_size.x = 60
		row.add_child(val)
		var bus: StringName = spec[0]
		s.value_changed.connect(func(x: float) -> void:
			set_volume(bus, int(x))
			val.text = "%d %%" % int(x))
		v.add_child(row)
	return v
