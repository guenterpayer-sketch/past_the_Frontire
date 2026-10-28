class_name MapTypes
extends RefCounted
## Kartentypen des Bodenkampfs (Entscheidungen des Nutzers 17.10.2026): Lagerhalle, Bar, Straße, Tempel, Büro
## (gleich verteilt) und Raumschiff-Inneres (nur beim Entern). Je Typ: Name, Boden, Farben, Licht und Modelle
## (CC0, Herkunft in assets/LICENSES.md). Fehlt ein Modell, zeichnet MapView einen Grundkörper.

const GROUND := [&"halle", &"bar", &"strasse", &"tempel", &"buero"]
const SHIP := &"schiff"

## Ordner der Molten-Maps-Modelle (Raumschiff)
const M := "res://assets/packs/molten/"
## Ordner des Quaternius Modular Sci-Fi MegaKit (Halle und andere urbane Karten)
const K := "res://assets/packs/megakit/"

## light: ambient (Farbe, Stärke), sun (Farbe, Stärke), lamps (Farben im Wechsel), lamp_energy, lamp_range,
## lamp_h (Höhe), bg (Hintergrund). props: Gelände → Modellpfade (eins je Objekt zufällig).
const TYPES := {
	&"halle": {
		"name": "Lagerhalle", "floor_name": "Hallenboden",
		"floor": Color(0.37, 0.38, 0.41), "wall": Color(0.24, 0.27, 0.32), "inner": Color(0.3, 0.33, 0.38),
		"ambient": Color(0.55, 0.6, 0.72), "ambient_energy": 0.55, "sun": Color(1, 1, 1), "sun_energy": 0.8,
		"lamps": [Color(1.0, 0.92, 0.78)], "lamp_energy": 1.1, "lamp_range": 16.0, "lamp_h": 8.0,
		"bg": Color(0.035, 0.045, 0.07),
		"props": {},
		# MegaKit (Nutzer 28.10.2026): Bodenplatten 4×4 m im Wechsel, Außenwände aus Wandteil unten + Abschluss oben
		# (zusammen auf WALL_H gestreckt), niedriger Schnitt als kurze Wand; Objekte gemischt alt/neu
		"floor_step": 4.0,
		"floors": [[1.01, [K + "Platforms/Platform_Metal.gltf", K + "Platforms/Platform_Metal2.gltf", K + "Platforms/Platform_DarkPlates.gltf",
			K + "Platforms/Platform_CenterPlate.gltf", K + "Platforms/Platform_Squares.gltf", K + "Platforms/Platform_3Plates.gltf"]]],
		"hall_walls": [[K + "Walls/WallAstra_Straight.gltf", K + "Walls/TopAstra_Straight.gltf"],
			[K + "Walls/WallAstra_Straight_Divided.gltf", K + "Walls/TopAstra_Straight.gltf"],
			[K + "Walls/WallBand_Straight.gltf", K + "Walls/TopCables_Straight.gltf"],
			[K + "Walls/WallAstra_Straight_Window.gltf", K + "Walls/TopWindow_Straight.gltf"]],
		"hall_walls_low": [K + "Walls/ShortWall_Band2_Straight.gltf", K + "Walls/ShortWall_Metal2_Straight.gltf", K + "Walls/ShortWall_DarkMetal2_Straight.gltf"],
		"alt_chance": 0.5,
		"alt": {
			&"kiste": [K + "Props/Prop_Crate3.gltf", K + "Props/Prop_Crate4.gltf"],
			&"fass": [K + "Props/Prop_Barrel_Large.gltf"],
			&"saeule": [K + "Columns/Column_Pipes.gltf", K + "Columns/Column_Round.gltf", K + "Columns/Column_Simple.gltf"],
			&"barriere": [K + "Walls/ShortWall_Band2_Straight.gltf", K + "Walls/ShortWall_Triangles_Straight.gltf", K + "Walls/ShortWall_AccentStrip_Straight.gltf"],
			&"regal": [K + "Props/Prop_PipeHolder.gltf"],
		},
	},
	&"bar": {
		"name": "Bar", "floor_name": "Dielenboden",
		"floor": Color(0.36, 0.25, 0.2), "wall": Color(0.22, 0.14, 0.2), "inner": Color(0.3, 0.2, 0.26),
		"podest": Color(0.42, 0.24, 0.16),
		"ambient": Color(0.45, 0.32, 0.55), "ambient_energy": 0.4, "sun": Color(0.8, 0.6, 1.0), "sun_energy": 0.25,
		"lamps": [Color(1.0, 0.3, 0.75), Color(0.15, 0.85, 0.9), Color(1.0, 0.75, 0.45)], "lamp_energy": 1.6,
		"lamp_range": 11.0, "lamp_h": 4.5, "bg": Color(0.05, 0.02, 0.06),
		"props": {
			&"tisch": ["res://assets/maps/bar/Table_RoundSmall.glb"],
			&"sofa": ["res://assets/maps/bar/Couch_Medium1.glb"],
			&"theke": ["res://assets/maps/bar/Kitchen_2Drawers.glb"],
			&"schrank": ["res://assets/maps/bar/Shelf_Large.glb"],
			&"hocker": ["res://assets/maps/bar/Stool.glb"],
		},
	},
	&"strasse": {
		"name": "Straße", "floor_name": "Fahrbahn",
		"floor": Color(0.2, 0.21, 0.24), "wall": Color(0.3, 0.27, 0.27), "inner": Color(0.34, 0.3, 0.3),
		"gehweg": Color(0.42, 0.42, 0.44), "podest": Color(0.32, 0.3, 0.3), "roof": Color(0.22, 0.22, 0.25),
		"ambient": Color(0.3, 0.4, 0.68), "ambient_energy": 0.5, "sun": Color(0.55, 0.65, 1.0), "sun_energy": 0.35,
		"lamps": [Color(1.0, 0.65, 0.3)], "lamp_energy": 2.2, "lamp_range": 10.0, "lamp_h": 4.6,
		"bg": Color(0.02, 0.03, 0.08), "lamps_at": &"laterne",
		"props": {
			&"auto": ["res://assets/maps/strasse/vehicle-truck-red.glb", "res://assets/maps/strasse/vehicle-truck-green.glb",
				"res://assets/maps/strasse/vehicle-truck-yellow.glb"],
			&"laterne": ["res://assets/maps/strasse/Streetlight_Single.glb"],
			&"tonne": ["res://assets/maps/strasse/Trashcan_Large.glb"],
		},
		# MegaKit (Nutzer 28.10.2026): gerade Fassaden statt Sechsecksäulen, je Haus Hochhaus oder Hütte,
		# Stil je Karte (alt oder ein Paar); Gehweg mit MegaKit-Platten; Barrieren und Tonnen gemischt
		"facades": [[K + "Walls/WallAstra_Straight_Window.gltf", K + "Walls/TopWindow_Straight.gltf"],
			[K + "Walls/WallAstra_Straight_Flat_Window.gltf", K + "Walls/TopPlastic_Straight.gltf"],
			[K + "Walls/WallBand_Straight.gltf", K + "Walls/TopCables_Straight.gltf"],
			[K + "Walls/WallAstra_Straight_Divided.gltf", K + "Walls/TopAstra_Straight.gltf"]],
		"facades_low": [K + "Walls/ShortWall_Band2_Straight.gltf", K + "Walls/ShortWall_Metal2_Straight.gltf", K + "Walls/ShortWall_DarkMetal2_Straight.gltf"],
		"sidewalk": [K + "Platforms/Platform_Simple.gltf", K + "Platforms/Platform_Squares.gltf", K + "Platforms/Platform_3Plates.gltf"],
		"alt_chance": 0.5,
		"alt": {
			&"tonne": [K + "Props/Prop_Chest.gltf", K + "Props/Prop_Barrel_Large.gltf"],
			&"barriere": [K + "Walls/ShortWall_Band2_Straight.gltf", K + "Walls/ShortWall_Triangles_Straight.gltf", K + "Walls/ShortWall_AccentStrip_Straight.gltf"],
		},
	},
	&"tempel": {
		"name": "Antiker Tempel", "floor_name": "Steinboden",
		"floor": Color(0.4, 0.35, 0.28), "wall": Color(0.33, 0.29, 0.24), "inner": Color(0.38, 0.33, 0.27),
		"podest": Color(0.5, 0.44, 0.34),
		"ambient": Color(0.55, 0.4, 0.28), "ambient_energy": 0.3, "sun": Color(1.0, 0.7, 0.45), "sun_energy": 0.2,
		"lamps": [Color(1.0, 0.55, 0.2), Color(1.0, 0.7, 0.35)], "lamp_energy": 1.7, "lamp_range": 11.0, "lamp_h": 4.0,
		"bg": Color(0.04, 0.025, 0.015),
		"props": {
			&"steinsaeule": ["res://assets/maps/tempel/Column.glb"],
			&"bruch": ["res://assets/maps/tempel/Column_Broken.glb", "res://assets/maps/tempel/Column_Broken2.glb"],
			&"geroell": ["res://assets/maps/tempel/Rock1.glb", "res://assets/maps/tempel/Rock2.glb", "res://assets/maps/tempel/Rock3.glb"],
			&"altar": ["res://assets/maps/tempel/Pedestal2.glb"],
			&"statue": ["res://assets/maps/tempel/Statue_Horse.glb"],
		},
	},
	&"buero": {
		"name": "Büroräume", "floor_name": "Teppichboden",
		"floor": Color(0.3, 0.34, 0.39), "wall": Color(0.4, 0.43, 0.47), "inner": Color(0.46, 0.49, 0.53),
		"ambient": Color(0.72, 0.8, 0.92), "ambient_energy": 0.5, "sun": Color(0.9, 0.95, 1.0), "sun_energy": 0.45,
		"lamps": [Color(0.9, 0.96, 1.0)], "lamp_energy": 1.0, "lamp_range": 12.0, "lamp_h": 5.0,
		"bg": Color(0.06, 0.07, 0.09),
		"props": {
			&"schrank": ["res://assets/maps/buero/Bookshelf.glb", "res://assets/maps/buero/Drawer_3.glb"],
			&"server": ["res://assets/maps/buero/Computer_Large.glb"],
			&"computer": ["res://assets/maps/buero/Computer.glb"],
			&"stuhl": ["res://assets/maps/buero/Chair_1.glb"],
			&"pflanze": ["res://assets/maps/buero/Houseplant_1.glb"],
		},
		# MegaKit/Molten (Nutzer 28.10.2026): Außenwände zweiteilig, Innenwände gerade (Wandteil des Paars der Karte),
		# Stil je Karte (alt oder ein Paar); Teppich gemischt mit Molten-Teppichflächen; Einrichtung gemischt
		"hall_walls": [[K + "Walls/WallAstra_Straight_Flat.gltf", K + "Walls/TopPlastic_Straight.gltf"],
			[K + "Walls/WallAstra_Straight_Flat_Window.gltf", K + "Walls/TopSimple_Straight.gltf"],
			[K + "Walls/WallBand_Straight.gltf", K + "Walls/TopAstra_Straight.gltf"],
			[K + "Walls/WallAstra_Straight_Divided.gltf", K + "Walls/TopPlastic_Straight.gltf"]],
		"hall_walls_low": [K + "Walls/ShortWall_WhitePlate2_Straight.gltf", K + "Walls/ShortWall_Simple1_Straight.gltf", K + "Walls/ShortWall_Band2_Straight.gltf"],
		"wall_panels": [],   # leer: Innenwände aus dem Wandteil des Paars der Karte
		"meeting_carpet": M + "Floor_Tile_Carpet_Grey.glb",   # nur unter dem Besprechungstisch
		"alt_chance": 0.5,
		"alt": {
			&"computer": [M + "Large_Monitor_Blue.glb", M + "Large_Monitor_White.glb", M + "Large_Monitor_Off.glb"],
			&"stuhl": [M + "Chair_1.glb", "res://assets/packs/essentials/Prop_Chair.gltf", "res://assets/maps/buero/Chair_1.glb"],
			&"schreibtisch": ["res://assets/packs/essentials/Prop_Desk_Small.gltf", "res://assets/packs/essentials/Prop_Desk_Medium.gltf"],
			&"besprechung": [M + "Meeting_Table.glb", M + "Octo_Table.glb"],
			&"server": [K + "Props/Prop_Computer.gltf", K + "Props/Prop_AccessPoint.gltf", "res://assets/packs/ultimate/props_computer.glb", "res://assets/packs/ultimate/props_computersmall.glb"],
			&"schrank": [M + "Briefing_Screen_Blue.glb", M + "Briefing_Screen_Off.glb", K + "Props/Prop_PipeHolder.gltf",
				"res://assets/packs/essentials/Prop_Locker.gltf", "res://assets/packs/essentials/Prop_Shelves_WideTall.gltf", "res://assets/packs/essentials/Prop_Shelves_ThinTall.gltf"],
		},
		"deco": [M + "Plant_1.glb", M + "Floor_Lamp.glb", "res://assets/maps/buero/Houseplant_1.glb"],
	},
	&"schiff": {
		"name": "Raumschiff", "floor_name": "Deckplatten",
		"floor": Color(0.3, 0.34, 0.4), "wall": Color(0.36, 0.4, 0.47), "inner": Color(0.42, 0.46, 0.53),
		"podest": Color(0.35, 0.38, 0.44),
		"ambient": Color(0.5, 0.62, 0.85), "ambient_energy": 0.5, "sun": Color(0.75, 0.85, 1.0), "sun_energy": 0.3,
		"lamps": [Color(0.75, 0.88, 1.0), Color(0.75, 0.88, 1.0), Color(1.0, 0.25, 0.2)], "lamp_energy": 1.3,
		"lamp_range": 10.0, "lamp_h": 4.0, "bg": Color(0.0, 0.0, 0.015),
		"props": {
			&"konsole": ["res://assets/ship/props_computer.glb"],
			&"tank": ["res://assets/ship/props_vessel_tall.glb"],
			&"schrank": ["res://assets/ship/props_shelf_tall.glb"],
		},
		# Molten Maps (Nutzer 28.10.2026): Bodenplatten je Raum, Wandplatten an den Kanten der Wandfelder,
		# je Objekt mit alt_chance das neue Modell statt des alten (gemischt), wenig Deko (nur Grafik)
		"floors": [[0.22, [M + "Floor_Metal_Square.glb", M + "Floor_Tile_Metal.glb"]],
			[0.55, [M + "Floor_Metal_Square_Grate.glb", M + "Floor_Tile_Metal.glb", M + "Floor_Metal_Square.glb", M + "Floor_Tile_Metal.glb"]],
			[0.80, [M + "Floor_Metal_Circles.glb", M + "Floor_Tile_Metal.glb"]],
			[1.01, [M + "Floor_Tile_Carpet_Grey.glb", M + "Floor_Tile_Carpet_Blue.glb"]]],
		"floor_hazard": M + "Hazard_Floor_1.glb",
		"wall_panels": [M + "Wall_Grey.glb", M + "Wall_Grey.glb", M + "Wall_Grey.glb", M + "Wall_Blue.glb",
			M + "Wall_Light_White.glb", M + "Wall_Pipe.glb", M + "Wall_Blue_Greeblies.glb", M + "Wall_Display_Blue.glb"],
		"alt_chance": 0.5,
		"alt": {
			&"kiste": [M + "Battery_Blue.glb", M + "Battery_Orange.glb", M + "Battery_Grey.glb", M + "Battery_Green.glb", M + "Battery_Red.glb"],
			&"container": [M + "Generator.glb", M + "Generator_Pile_Chonky.glb"],
			&"konsole": [M + "Large_Monitor_Blue.glb", M + "Large_Monitor_White.glb", M + "BioMonitor_Blue.glb"],
			&"tank": [M + "Cryo_Tube_ON.glb", M + "Generator_Pile_Small.glb"],
			&"schrank": [M + "Bunk_Double_Grey.glb", M + "Bunk_Double_Blue.glb", M + "Briefing_Screen_Blue.glb"],
		},
		"deco": [M + "Plant_1.glb", M + "Chair_1.glb", M + "Space_Ketchup.glb", M + "Space_Mayo_Naise.glb"],
	},
}


static func info(id: StringName) -> Dictionary:
	return TYPES.get(id, TYPES[&"halle"])


static func type_name(id: StringName) -> String:
	return info(id).name
