class_name StoryGen
extends RefCounted
## Story-Generator (Entscheidung des Nutzers 19.10.2026: „ganz erzeugt“): baut aus Vorlagen (data/story/vorlagen/*.json)
## fertige Ketten im Format der JSON-Ketten und legt sie in StoryState.generated ab (bleiben nach dem Laden gleich).
## Vorlage: id, kind, title, contact, einstieg (Liste) oder trigger, werte {name: [Werte]}, ausgaenge {name: {Szenen}},
## orte (passende Ortsarten für einen Story-Ort), start, scenes. Platzhalter in allen Texten: {wert} bzw. {wert.feld}, {gegner},
## {gegner_id}, {diff}, {diff_leichter}, {diff_schwerer}, {system}, {ort} (Ort mit System, ggf. Sektor), {kontakt}, {einstieg}. {glaeubiger}, {konzern} usw. ersetzt erst Story.text_of.

## Gegnergruppen: Anzeigename (im Dativ, für „bewacht von …“), gewünschte Missionsfraktion (data/missions/<id>.tres) und Ersatz, solange sie fehlt
const GEGNER := {
	"abteilung9": {"name": "Abteilung 9", "id": "abteilung_9", "fallback": "konzern"},
	"klingen": {"name": "den Klingen der Wacht", "id": "wacht_klingen", "fallback": "leeres_licht"},
	"hirten": {"name": "den Hirten der Wacht", "id": "wacht_hirten", "fallback": "leeres_licht"},
	"hand": {"name": "Angeheuerten der Stillen Hand", "id": "stille_hand", "fallback": "rote_sonne"},
	"pluenderer": {"name": "Plünderern", "id": "aasgeier", "fallback": "schmuggler"},
}
## Hirten der Wacht nur als Gegner, wenn die Crew gegen Begabte gehandelt hat (Flag; Entscheidung des Nutzers 19.10.2026: „selten“)
const HIRTEN_FLAG := "hirten_feind"
## Leute des Gläubigers je Baustein „glaeubiger“
const GLAEUBIGER_GEGNER := {"syndikat": "schmuggler", "bank": "konzern", "person": "rote_sonne"}
const DIFFS := ["leicht", "mittel", "schwer"]
const KONTAKTE := ["Ines Varga, Frachtmaklerin", "der alte Oskar am Tresen", "Mira Sol, Dockarbeiterin", "Tavi, ein Informant mit Schulden",
	"Bruder Elias, ein Wanderprediger", "Kael Dorn, Ex-Söldner", "Juna, Funkerin der Hafenwache", "ein Mann ohne Namen im grauen Mantel"]
const EINSTIEG := {
	"kontakt": "Im Raumhafen von {system} wartet {kontakt}.",
	"ort": "Ein Hinweis führt zu {ort}.",
	"auftrag": "Auf der Brücke liegt eine verschlüsselte Nachricht ohne Absender.",
	"reise": "Unterwegs fängt das Schiff einen kurzen, verschlüsselten Funkspruch auf.",
}


## nächsten Schritt eines Rahmens erzeugen (z. B. Kapitel 1): Vorlage zufällig aus frame.steps
static func step(story: Story, frame: String) -> String:
	var f: Dictionary = story.chain_of(frame).get("frame", {})
	var steps: Array = f.get("steps", [])
	if steps.is_empty():
		return ""
	return make(story, String(steps[story.rng.randi_range(0, steps.size() - 1)]), {"frame": frame})


## Kette aus einer Vorlage erzeugen. extra: frame, rescue/rescue_name (Befreiung eines Crewmitglieds), place ({sector, system, place}),
## start (true = der Aufrufer startet sie gleich, sonst steht sie „bekannt“ im Logbuch). Gibt die Kennung zurück oder "".
static func make(story: Story, template_id: String, extra := {}) -> String:
	var t: Dictionary = StoryData.templates().get(template_id, {})
	if t.is_empty():
		push_warning("Story: Vorlage %s fehlt" % template_id)
		return ""
	var st := story.state
	var id := "g%d_%s" % [st.next_gen, template_id]
	st.next_gen += 1
	var vals := _values(story, t, extra)
	var entry: String = vals.einstieg_typ
	var c: Dictionary = {"id": id, "template": template_id, "kind": String(t.get("kind", "kette")), "title": t.get("title", template_id),
		"trigger": {"type": entry}, "start": String(t.get("start", "start")), "scenes": t.get("scenes", {}).duplicate(true)}
	if t.has("contact"):
		c.contact = t.contact
	var outs: Dictionary = t.get("ausgaenge", {})
	if not outs.is_empty():
		var keys := outs.keys()
		keys.sort()
		var pick: String = keys[story.rng.randi_range(0, keys.size() - 1)]
		c.ausgang = pick
		c.scenes.merge(outs[pick].duplicate(true), true)
	for k in ["frame", "rescue", "rescue_name"]:
		if extra.has(k):
			c[k] = extra[k]
	c = _fill(c, vals)
	st.generated[id] = c
	st.chains[id] = {"status": "" if extra.get("start", false) else "bekannt", "scene": "", "place": vals.place}
	return id


## Werte würfeln: je Eintrag in werte einer; Gegner, Schwierigkeit, Einstieg, Ort, Kontakt
static func _values(story: Story, t: Dictionary, extra: Dictionary) -> Dictionary:
	var v := {}
	var werte: Dictionary = t.get("werte", {})
	for k in werte:
		var list: Array = werte[k]
		if k == "gegner" and not story.state.flags.has(HIRTEN_FLAG):
			list = list.filter(func(x: Variant) -> bool: return String(x) != "hirten")
		if not list.is_empty():
			v[k] = list[story.rng.randi_range(0, list.size() - 1)]
	if extra.has("rescue_name"):
		var rn := String(extra.rescue_name)
		v["ziel"] = {"name": rn, "kurz": rn, "titel": rn}
	# Einstieg
	var entries: Array = t.get("einstieg", [])
	var entry := String(t.get("trigger", "keiner"))
	if not entries.is_empty():
		entry = String(entries[story.rng.randi_range(0, entries.size() - 1)])
	if extra.get("start", false):
		entry = "keiner"
	v.einstieg_typ = entry
	# Ort: Kontakt im Hafen, Story-Ort an einem passenden Ort (Hauptstory selten in einem unbekannten Sektor),
	# sonst dort, wo das Schiff gerade ist
	var place: Dictionary = extra.get("place", {})
	if not extra.has("place"):
		if entry == "kontakt":
			place = story.pick_harbor()
		elif entry == "ort":
			place = story.pick_place(t.get("orte", []), extra.has("frame"))
	v.place = place
	var sys := story.system_of(place) if not place.is_empty() else (story.system_of({"system": story.game.position}) if story.game != null else {})
	var sys_name := String(sys.get("name", "diesem System"))
	v.system = sys_name
	v.ort = story.place_label(place) if not place.is_empty() else sys_name
	v.kontakt = KONTAKTE[story.rng.randi_range(0, KONTAKTE.size() - 1)]
	v.einstieg = String(EINSTIEG.get(entry, "")).replace("{system}", sys_name).replace("{ort}", String(v.ort)).replace("{kontakt}", String(v.kontakt))
	# Gegner
	var g := String(v.get("gegner", "lokal"))
	var gi := _gegner(story, g, sys)
	v.gegner = gi.name
	v.gegner_id = gi.id
	# Schwierigkeit
	var d := String(v.get("diff", "mittel"))
	var di := DIFFS.find(d)
	v.diff = d
	v.diff_leichter = DIFFS[maxi(0, di - 1)]
	v.diff_schwerer = DIFFS[mini(DIFFS.size() - 1, di + 1)]
	return v


## Gegnergruppe → {name, id}; „lokal“ = Fraktion des Systems, „glaeubiger“ = Leute des Gläubigers
static func _gegner(story: Story, g: String, sys: Dictionary) -> Dictionary:
	if g == "glaeubiger":
		return {"name": "den Leuten des Gläubigers", "id": _faction_id(String(GLAEUBIGER_GEGNER.get(String(story.state.vars.get("glaeubiger", "")), "rote_sonne")), "rote_sonne")}
	if GEGNER.has(g):
		return {"name": String(GEGNER[g].name), "id": _faction_id(String(GEGNER[g].id), String(GEGNER[g].fallback))}
	# lokal: kontrollierende Fraktion des Systems (im Hafen zufällig eine der vorhandenen)
	var path := String(sys.get("faction", ""))
	if path == "":
		var ids := _normal_factions()
		path = "res://data/missions/%s.tres" % ids[story.rng.randi_range(0, ids.size() - 1)]
	var f := load(path) as FactionData if ResourceLoader.exists(path) else null
	return {"name": f.name if f != null else "Bewaffnete", "id": path.get_file().get_basename()}


## alle Missionsfraktionen außer denen der Oberart „story“ (Kennung = Dateiname)
static func _normal_factions() -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open("res://data/missions")
	if d != null:
		for f in d.get_files():
			var file := f.trim_suffix(".remap")
			if file.ends_with(".tres"):
				var fd := load("res://data/missions/" + file) as FactionData
				if fd != null and fd.kind != &"story":
					out.append(file.get_basename())
	if out.is_empty():
		out.append("rote_sonne")
	return out


static func _faction_id(id: String, fallback: String) -> String:
	return id if ResourceLoader.exists("res://data/missions/%s.tres" % id) else fallback


## Platzhalter in allen Zeichenketten der Kette ersetzen (rekursiv)
static func _fill(x: Variant, vals: Dictionary) -> Variant:
	if x is String:
		var s: String = x
		for k in vals:
			var val: Variant = vals[k]
			if val is Dictionary:
				for f in val:
					s = s.replace("{%s.%s}" % [k, f], str(val[f]))
				s = s.replace("{%s}" % k, String(val.get("name", "")))
			else:
				s = s.replace("{%s}" % k, str(val))
		return s
	if x is Array:
		var a := []
		for e in x:
			a.append(_fill(e, vals))
		return a
	if x is Dictionary:
		var d := {}
		for k in x:
			d[k] = _fill(x[k], vals)
		return d
	return x
