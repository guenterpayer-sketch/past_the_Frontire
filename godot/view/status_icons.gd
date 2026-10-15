class_name StatusIcons
## Symbole für Zustände über dem Namensschild (Entwurf: Artifact „Statuseffekte Bodenkampf“, Entscheidung 15.10.2026).
## Die Bilder sind SVG-Text und werden beim ersten Gebrauch zu Texturen gerendert (kein Import nötig).

const SIZE := 64          # Kantenlänge der Textur in Pixeln
const MAX_SHOWN := 5      # mehr Symbole → „+N“, die volle Liste steht in der Figurenkarte

const COLORS := {
	&"blood": Color("e0453a"), &"stun": Color("f2d24c"), &"dying": Color("ff5a4f"), &"stab": Color("5fd38a"),
	&"ko": Color("9aa4b2"), &"wound": Color("f2994a"), &"disarm": Color("f2994a"), &"prone": Color("f2994a"),
	&"shield": Color("6fb7ff"), &"buff": Color("b48cff"), &"debuff": Color("e06bd0"), &"ow": Color("f2c94c"),
	&"wait": Color("f2c94c"), &"star": Color("f2d24c"),
}

## Psi-Wirkungen, die gegen die Figur laufen (alle anderen Einträge in buffs helfen ihr)
const DEBUFFS := [&"geortet", &"schwachstelle"]

const SVG := {
	&"blood": '<path d="M10 2C10 2 4 9.5 4 13a6 6 0 0 0 12 0c0-3.5-6-11-6-11z" fill="#e0453a" stroke="#000" stroke-width="1.4"/>',
	&"stun": '<g fill="#f2d24c" stroke="#000" stroke-width="1.2"><path d="M6 2l1.3 3 3.2.3-2.4 2 .8 3.1L6 8.7 3.1 10.4l.8-3.1-2.4-2 3.2-.3z"/><path d="M14 8l1.3 3 3.2.3-2.4 2 .8 3.1-2.9-1.7-2.9 1.7.8-3.1-2.4-2 3.2-.3z"/></g>',
	&"star": '<path d="M10 1.5l2.6 5.6 6.1.7-4.5 4.1 1.2 6-5.4-3-5.4 3 1.2-6-4.5-4.1 6.1-.7z" fill="#f2d24c" stroke="#000" stroke-width="1.2"/>',
	&"dying": '<path d="M10 17S2.5 12 2.5 7A4 4 0 0 1 10 5a4 4 0 0 1 7.5 2c0 5-7.5 10-7.5 10z" fill="#ff5a4f" stroke="#000" stroke-width="1.4"/><path d="M5 9h3l1-2 2 4 1-2h3" fill="none" stroke="#000" stroke-width="1.5"/>',
	&"stab": '<path d="M10 17S2.5 12 2.5 7A4 4 0 0 1 10 5a4 4 0 0 1 7.5 2c0 5-7.5 10-7.5 10z" fill="#5fd38a" stroke="#000" stroke-width="1.4"/><path d="M10 7.5v6M7 10.5h6" stroke="#000" stroke-width="2"/>',
	&"ko": '<path d="M3 6h7l-7 8h7" fill="none" stroke="#000" stroke-width="4" stroke-linejoin="round"/><path d="M3 6h7l-7 8h7" fill="none" stroke="#9aa4b2" stroke-width="2" stroke-linejoin="round"/><path d="M12 3h5l-5 6h5" fill="none" stroke="#000" stroke-width="3.4" stroke-linejoin="round"/><path d="M12 3h5l-5 6h5" fill="none" stroke="#9aa4b2" stroke-width="1.6" stroke-linejoin="round"/>',
	&"wound": '<path d="M8 2l-2 6 4 2-2 8" fill="none" stroke="#000" stroke-width="4.4" stroke-linecap="round" stroke-linejoin="round"/><path d="M8 2l-2 6 4 2-2 8" fill="none" stroke="#f2994a" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/><path d="M13 4l4 4M13 12l4 4" stroke="#000" stroke-width="3.4" stroke-linecap="round"/><path d="M13 4l4 4M13 12l4 4" stroke="#f2994a" stroke-width="1.8" stroke-linecap="round"/>',
	&"disarm": '<path d="M3 9h10v3H6l-1 4H3z" fill="#f2994a" stroke="#000" stroke-width="1.2"/><path d="M2 2l16 16" stroke="#000" stroke-width="3.4"/><path d="M2 2l16 16" stroke="#ff5a4f" stroke-width="2"/>',
	&"prone": '<circle cx="4" cy="12" r="2.5" fill="#f2994a" stroke="#000"/><path d="M7 12h10" stroke="#000" stroke-width="4" stroke-linecap="round"/><path d="M7 12h10" stroke="#f2994a" stroke-width="2.4" stroke-linecap="round"/><path d="M2 17h16" stroke="#000" stroke-width="2.6"/><path d="M2 17h16" stroke="#9aa4b2" stroke-width="1.4"/>',
	&"shield": '<path d="M10 2l7 3v5c0 4-3 6.5-7 8-4-1.5-7-4-7-8V5z" fill="#6fb7ff" stroke="#000" stroke-width="1.4"/>',
	&"buff": '<path d="M10 2l2.2 5.8L18 10l-5.8 2.2L10 18l-2.2-5.8L2 10l5.8-2.2z" fill="#b48cff" stroke="#000" stroke-width="1.2"/>',
	&"debuff": '<circle cx="10" cy="10" r="7" fill="none" stroke="#000" stroke-width="3.6"/><circle cx="10" cy="10" r="7" fill="none" stroke="#e06bd0" stroke-width="2"/><path d="M10 1v6M10 13v6M1 10h6M13 10h6" stroke="#000" stroke-width="3.4"/><path d="M10 1v6M10 13v6M1 10h6M13 10h6" stroke="#e06bd0" stroke-width="1.8"/>',
	&"ow": '<circle cx="10" cy="10" r="7" fill="none" stroke="#000" stroke-width="4"/><circle cx="10" cy="10" r="7" fill="none" stroke="#f2c94c" stroke-width="2.4"/><circle cx="10" cy="10" r="2.8" fill="#f2c94c" stroke="#000"/>',
	&"wait": '<rect x="4" y="3" width="4.5" height="14" rx="1" fill="#f2c94c" stroke="#000" stroke-width="1.2"/><rect x="11.5" y="3" width="4.5" height="14" rx="1" fill="#f2c94c" stroke="#000" stroke-width="1.2"/>',
}

static var _cache := {}


## Textur eines Symbols (gecacht)
static func texture(id: StringName) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 20 20">%s</svg>' % SVG.get(id, "")
	var img := Image.new()
	var tex: Texture2D = null
	if img.load_svg_from_string(svg, SIZE / 20.0) == OK:
		img.generate_mipmaps()
		tex = ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


## Symbole einer Figur in fester Reihenfolge: [{id, text}]
static func entries(u: Combatant) -> Array[Dictionary]:
	var e: Array[Dictionary] = []
	if u.state == Combatant.State.DYING:
		e.append({"id": &"stab" if u.stabilized else &"dying", "text": "" if u.stabilized else "sterbend"})
	elif u.state == Combatant.State.KO:
		e.append({"id": &"ko", "text": ""})
	if u.bleed:
		e.append({"id": &"blood", "text": str(u.bleed)})
	if u.stun:
		e.append({"id": &"stun", "text": str(u.stun)})
	if u.malus and not u.buffs.has("schmerz"):
		e.append({"id": &"wound", "text": str(u.malus) if u.malus < 0 else "−%d" % u.malus})
	if u.disarmed or u.next_attack_malus:
		e.append({"id": &"disarm", "text": ""})
	if u.prone:
		e.append({"id": &"prone", "text": ""})
	if u.psi_shield:
		e.append({"id": &"shield", "text": str(u.psi_shield)})
	var good: Variant = _shortest(u, false)
	if good != null:
		e.append({"id": &"buff", "text": good})
	var bad: Variant = _shortest(u, true)
	if bad != null:
		e.append({"id": &"debuff", "text": bad})
	if u.has_overwatch():
		e.append({"id": &"ow", "text": ""})
	if u.waiting:
		e.append({"id": &"wait", "text": ""})
	return e


## Mehrere Psi-Wirkungen zeigen ein Symbol; Zahl = kürzeste Restdauer (leer, wenn keine Rundenzahl). null = keine
static func _shortest(u: Combatant, debuff: bool) -> Variant:
	var found := false
	var best := 999
	for b in u.buffs:
		if (StringName(b) in DEBUFFS) != debuff:
			continue
		found = true
		var r: int = u.buffs[b].get("rounds", -1)
		if r > 0:
			best = mini(best, r)
	if not found:
		return null
	return "" if best == 999 else str(best)


## hat die Figur Psi-Wirkungen zu ihren Gunsten (für den Schimmerring)?
static func has_buff(u: Combatant) -> bool:
	return _shortest(u, false) != null
