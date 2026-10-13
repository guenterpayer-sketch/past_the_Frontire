extends Node
## Soundeffekte, synthetisch erzeugt wie in der HTML-Version (Rauschen durch Filter, Töne mit Frequenzverlauf).
## Autoload "Sfx". Die Klänge werden beim ersten Abspielen berechnet und dann zwischengespeichert.

const RATE := 22050
const VOICES := 12
const MASTER := 0.5

var enabled := true
var _cache := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _noise := PackedFloat32Array()


func _ready() -> void:
	enabled = Prefs.get_bool("sound", true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	_noise.resize(RATE)
	for i in RATE:
		_noise[i] = rng.randf_range(-1.0, 1.0)
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func toggle() -> bool:
	enabled = not enabled
	Prefs.set_bool("sound", enabled)
	return enabled


func play(name: StringName, delay := 0.0) -> void:
	if not enabled:
		return
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(play.bind(name))
		return
	var stream := _stream(name)
	if stream == null:
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = stream
	p.play()


func _stream(name: StringName) -> AudioStreamWAV:
	if not _cache.has(name):
		var buf := _synth(name)
		_cache[name] = _to_wav(buf) if not buf.is_empty() else null
	return _cache[name]


# ---------------------------------------------------------------- Klänge

func _synth(name: StringName) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	match name:
		&"gewehr":
			_noise_at(b, 0.0, 0.12, "bandpass", 1800, 0, 0.7, 0.8)
			_tone(b, 0.0, 0.12, 140, 50, "triangle", 0.5)
		&"mg":
			for i in 4:
				_noise_at(b, i * 0.07, 0.07, "bandpass", 1500, 0, 0.8, 0.7)
				_tone(b, i * 0.07, 0.06, 120, 60, "triangle", 0.35)
		&"laser":
			_tone(b, 0.0, 0.18, 1600, 280, "saw", 0.18)
			_tone(b, 0.0, 0.18, 1200, 200, "square", 0.08)
		&"psi":
			_tone(b, 0.0, 0.5, 220, 660, "sine", 0.25)
			_tone(b, 0.05, 0.45, 330, 110, "triangle", 0.15)
		&"rakete":
			_noise_at(b, 0.0, 0.3, "bandpass", 400, 2500, 2.0, 0.5)
			_mix(b, _synth(&"explosion"), 0.28)
		&"explosion":
			_noise_at(b, 0.0, 0.8, "lowpass", 900, 120, 0.5, 1.0)
			_tone(b, 0.0, 0.7, 90, 30, "sine", 0.6)
		&"nahkampf":
			_noise_at(b, 0.0, 0.12, "highpass", 2500, 900, 0.5, 0.4)
			_tone(b, 0.08, 0.1, 160, 70, "triangle", 0.4)
		&"treffer":
			_tone(b, 0.0, 0.12, 180, 70, "triangle", 0.45)
			_noise_at(b, 0.0, 0.06, "lowpass", 800, 0, 1.0, 0.4)
		&"daneben":
			_tone(b, 0.0, 0.16, 2400, 900, "sine", 0.07)
		&"krit":
			_tone(b, 0.0, 0.25, 880, 880, "triangle", 0.2)
			_tone(b, 0.06, 0.3, 1320, 1320, "triangle", 0.15)
		&"tod":
			_tone(b, 0.0, 0.7, 300, 55, "triangle", 0.35)
		&"heilen":
			for i in 3:
				var f: float = [523.0, 659.0, 784.0][i]
				_tone(b, i * 0.08, 0.25, f, f, "sine", 0.18)
		&"patzer":
			_tone(b, 0.0, 0.3, 110, 90, "square", 0.12)
		&"schritt":
			_noise_at(b, 0.0, 0.04, "lowpass", 700, 0, 1.0, 0.25)
		&"ducken":
			_noise_at(b, 0.0, 0.1, "bandpass", 600, 300, 1.0, 0.3)
		&"alarm":
			_tone(b, 0.0, 0.08, 950, 950, "square", 0.1)
			_tone(b, 0.1, 0.08, 700, 700, "square", 0.1)
		&"runde":
			_tone(b, 0.0, 0.6, 220, 218, "sine", 0.15)
			_tone(b, 0.0, 0.6, 330, 328, "sine", 0.07)
		&"nachladen":
			_noise_at(b, 0.0, 0.05, "highpass", 3000, 0, 1.0, 0.3)
			_noise_at(b, 0.15, 0.06, "highpass", 2200, 0, 1.0, 0.35)
		&"wuerfel":
			var t := 0.0
			for i in 6:
				_noise_at(b, t, 0.025, "bandpass", 3000 + i * 300, 0, 4.0, 0.35 - i * 0.04)
				t += 0.045 + 0.05 * fmod(i * 0.37, 1.0)
		&"klick":
			_tone(b, 0.0, 0.04, 1200, 900, "sine", 0.08)
	return b


## Ton mit exponentiellem Frequenzverlauf und kurzer Hüllkurve (wie Web Audio)
func _tone(b: PackedFloat32Array, t0: float, dur: float, f0: float, f1: float, wave: String, gain: float) -> void:
	var start := int(t0 * RATE)
	var n := int((dur + 0.05) * RATE)
	_ensure(b, start + n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := minf(t / dur, 1.0)
		var f := f0 * pow(f1 / f0, k) if f1 != f0 else f0
		phase = fmod(phase + f / RATE, 1.0)
		var s: float
		match wave:
			"triangle":
				s = 4.0 * absf(phase - 0.5) - 1.0
			"square":
				s = 1.0 if phase < 0.5 else -1.0
			"saw":
				s = 2.0 * phase - 1.0
			_:
				s = sin(TAU * phase)
		b[start + i] += s * _env(t, dur, gain)


## Rauschen durch einen Biquad-Filter (Frequenz optional exponentiell zum Endwert)
func _noise_at(b: PackedFloat32Array, t0: float, dur: float, type: String, freq: float, freq_end: float, q: float, gain: float) -> void:
	var start := int(t0 * RATE)
	var n := int((dur + 0.05) * RATE)
	_ensure(b, start + n)
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0
	var c := PackedFloat32Array()
	var offset := int(abs(hash(str(t0, freq))) % (RATE / 2))
	for i in n:
		var t := float(i) / RATE
		if i % 32 == 0:
			var f := freq * pow(freq_end / freq, minf(t / dur, 1.0)) if freq_end > 0.0 else freq
			c = _biquad(type, minf(f, RATE * 0.45), q)
		var x := _noise[(offset + i) % RATE]
		var y := c[0] * x + c[1] * x1 + c[2] * x2 - c[3] * y1 - c[4] * y2
		x2 = x1
		x1 = x
		y2 = y1
		y1 = y
		b[start + i] += y * _env(t, dur, gain)


## Lautstärke: von gain exponentiell auf 0,001 am Ende der Dauer
func _env(t: float, dur: float, gain: float) -> float:
	if t < 0.005:
		return gain * t / 0.005
	if t > dur:
		return 0.0
	return gain * pow(0.001 / gain, t / dur) if gain > 0.001 else 0.0


## Biquad-Koeffizienten (RBJ-Kochbuch), normiert: [b0, b1, b2, a1, a2]
func _biquad(type: String, f: float, q: float) -> PackedFloat32Array:
	var w := TAU * f / RATE
	var cw := cos(w)
	var alpha := sin(w) / (2.0 * maxf(q, 0.0001))
	var b0: float
	var b1: float
	var b2: float
	match type:
		"lowpass":
			b0 = (1.0 - cw) / 2.0
			b1 = 1.0 - cw
			b2 = b0
		"highpass":
			b0 = (1.0 + cw) / 2.0
			b1 = -(1.0 + cw)
			b2 = b0
		_:
			b0 = alpha
			b1 = 0.0
			b2 = -alpha
	var a0 := 1.0 + alpha
	return PackedFloat32Array([b0 / a0, b1 / a0, b2 / a0, -2.0 * cw / a0, (1.0 - alpha) / a0])


func _mix(b: PackedFloat32Array, other: PackedFloat32Array, t0: float) -> void:
	var start := int(t0 * RATE)
	_ensure(b, start + other.size())
	for i in other.size():
		b[start + i] += other[i]


func _ensure(b: PackedFloat32Array, n: int) -> void:
	if b.size() < n:
		var old := b.size()
		b.resize(n)
		for i in range(old, n):
			b[i] = 0.0


func _to_wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i] * MASTER, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
