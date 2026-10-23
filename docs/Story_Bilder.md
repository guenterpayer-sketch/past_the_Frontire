# Story-Bilder: Liste und Prompts

Stil (Entscheidung des Nutzers 19.10.2026): **Comic/Graphic Novel**, also klare Linien, Schraffur und kräftige Schatten. Format **4:3**, z. B. 1200 × 900 px. Ablage: `godot/art/story/<id>.png`. Das Szenenfenster zeigt das Bild links im Bildbereich, ohne Datei steht dort „Bild folgt“.

Die Prompts sind auf Englisch, weil Bildgeneratoren damit meist genauer arbeiten. Ob das für Artisly.ai gilt, weiß ich nicht. An jeden Prompt wird der Stilsatz angehängt:

> *Stil:* `graphic novel illustration, bold ink lines, cross-hatching, heavy shadows, limited muted palette with one accent color, gritty sci-fi, cinematic composition, no text, no speech bubbles, 4:3`

## Kapitel 1

| ID | Szene | Prompt |
|---|---|---|
| `k1_glaeubiger` | Besuch an der Schleuse | `two well-dressed debt collectors standing in the open airlock of a worn freighter, one holding a data tablet with a contract, harsh corridor light from behind, the crew silhouetted in the foreground` |
| `k1_rate` | Rate zahlen | `a courier in a long coat counting credit chips at a cramped spaceport counter, neon sign reflections, wary crew member watching` |
| `k1_rueck_zins` | Strafzinsen | `close-up of a glowing contract screen, numbers rising, a gloved hand stamping a red penalty seal, cold office light` |
| `k1_rueck_pfaendung` | Pfändung | `armed bailiffs carrying crates and ship parts out of a freighter cargo bay, crew held back, flickering warning lights` |
| `k1_rueck_gefangen` | Geisel | `a crew member being dragged away by masked enforcers down a dark docking ramp, one enforcer looking back threateningly` |
| `k1_rueck_kopfgeld` | Kopfgeld | `a wanted poster hologram with the ship's crew faces, flickering above a crowded spaceport bar, bounty hunters in the shadows` |
| `k1_kopfgeld` | Kopfgeldjäger im Hafen | `three bounty hunters blocking a docking bay walkway, weapons drawn, steam and floodlights, the freighter behind them` |
| `k1_station` | Die Station von Abteilung 9 | `a sterile secret research station on a barren moon, corporate logo half scratched off, searchlights, armored guards at the gate, the number 9 stenciled on the wall` |
| `k1_lio` | Lio | `a young psychic girl sitting inside a glass cell, faint glowing energy around her hands, monitoring equipment flickering, rescuers' reflections in the glass` |

## Erzeugte Story-Schritte

| ID | Szene | Prompt |
|---|---|---|
| `schritt_befreien` | Befreiung | `a prisoner behind bars in a dim holding cell, guards with rifles in the corridor, the crew preparing a breach charge at the door` |
| `schritt_bergen` | Bergung | `a guarded warehouse at night, a sealed glowing data core on a pedestal, laser tripwires, crew sneaking along catwalks` |
| `schritt_abfangen` | Abfangen | `a small courier ship chased by a battered freighter through an asteroid field, engine trails, targeting reticle overlay` |
| `schritt_gespraech` | Gespräch | `a nervous informant in a booth of a smoky spaceport bar, leaning in to whisper, a crew member sliding credits across the table` |

## Ereignisketten

| ID | Szene | Prompt |
|---|---|---|
| `ev_wrack` | Notsignal / Wrack | `a derelict starship drifting in deep space, hull breached, emergency beacon blinking red, the crew's freighter approaching with floodlights` |
| `ev_passagier` | Blinder Passagier | `a frightened stowaway hiding between cargo crates in a dim freighter hold, caught in a flashlight beam` |
| `ev_schmuggel` | Schmuggelware | `a shady broker in a hooded jacket presenting sealed unmarked crates in a back alley of a spaceport, money changing hands` |

## Ergänzt am 21.10.2026: jede Szene ein eigenes Bild

Der Nutzer hat entschieden: Jede Szene bekommt ein Bildfeld (`"image"`), die Bilder fehlen noch. Die Dateinamen sind `<Kette oder Vorlage>_<Szene>` (bei Ausgängen mit dem Ausgangsnamen dazwischen). Die Startszenen der Vorlagen (`{bild}`) haben schon ein Bild je Vorlage und stehen nicht in dieser Liste. Die Testketten (`test: true`) sind nicht erfasst. Die Prompts unten sind die vom Nutzer überarbeitete Fassung (23.10.2026, gemischte Crew mit Frauen und Männern); der Stilsatz oben gehört weiter an jeden Prompt.

Hinweis: Mehrere Szenen haben denselben Text („Gut vorbereitet“, „Entdeckt“, „Geschafft“, „Zu spät“) in den drei Vorlagen Abfangen, Befreien und Bergen. Entscheidung des Nutzers (21.10.2026): ein eigenes Bild pro Vorlage, kein geteiltes Bild.

### Kapitel 1, Finale

| ID | Szene | Prompt |
|---|---|---|
| `k1_drin` | Drinnen | `Two crew members, a woman in a flight jacket and a man with a breaching tool, slipping through a breached security door into a dark research station corridor, red emergency lights, nobody has noticed them yet.` |
| `k1_alarm` | Alarm | `Research station corridor flooding with red alarm light, psionic soldiers in dark armor taking cover behind consoles, a female soldier with faint psi energy crackling around her hands, one crew member pinned behind a broken console in the foreground.` |
| `k1_zurueck` | Zurückgeschlagen | `Battered mixed crew running back across a landing pad under fire, a woman carrying a wounded female companion on her shoulder, the freighter's ramp closing, the station burning behind them.` |

### Erzeugte Story-Schritte

| ID | Szene | Prompt |
|---|---|---|
| `abfangen_vorteil` | Gut vorbereitet | `A woman and a man of the crew studying holographic route maps and guard schedules on a freighter bridge, focused faces, data screens glowing.` |
| `abfangen_entdeckt` | Entdeckt | `Freighter bridge with alarm lights, a female pilot at the controls, a patrol ship turning toward the crew's ship, searchlights sweeping through the viewport.` |
| `abfangen_erfolg` | Geschafft | `A stopped freighter with its cargo hatch open, a female crew chief inspecting a terminal with forged cargo papers next to a male crew member, tense relieved faces.` |
| `abfangen_fehlschlag` | Zu spät | `A freighter escaping into a hyperspace flash, the crew's small ship left behind in a spray of sparks, through the cockpit glass a woman slumping over the controls in frustration.` |
| `befreien_vorteil` | Gut vorbereitet | `A female crew member in a dim spaceport planning room pointing at a route on a floor plan of a prison block spread across the table, sketches of guard rotations, male crew members leaning in around her.` |
| `befreien_entdeckt` | Entdeckt | `Prison corridor filling with guards turning toward the camera, rifle barrels raised, a man and a woman of the crew caught in a doorway.` |
| `befreien_erfolg` | Geschafft | `A freed female prisoner in a worn coat embracing a woman of the crew at a cell door, a data chip pressed into another crew member's hand, guards down in the background.` |
| `befreien_fehlschlag` | Zu spät | `An empty cell with the door open, torn restraints on the floor, a female and a male crew member in the doorway with cold expressions, one blinking light.` |
| `bergen_vorteil` | Gut vorbereitet | `A woman on a catwalk above a warehouse reading a wall plan with patrol paths marked in chalk, male crew members crouched beside her, moonlight through high windows.` |
| `bergen_entdeckt` | Entdeckt | `Mixed crew in a warehouse aisle, guards with flashlights converging from both ends, a female crew member stepping carefully over a laser tripwire glowing red at their feet.` |
| `bergen_erfolg` | Geschafft | `A woman and a man of the crew carrying a sealed data core out of a warehouse at dawn, an encrypted label glowing on the core, a shadowy female figure watching from afar.` |
| `bergen_fehlschlag` | Zu spät | `Empty pedestal in a warehouse, a broken lock, dust in the light, a female rival disappearing through a side door.` |
| `gespraech_erfolg` | Ein Name | `A male informant leaning across a bar table to whisper, a female crew member's hand sliding a data slip with the number 9 across the table, nervous look on both faces.` |
| `gespraech_fehlschlag` | Kein Wort | `A bar booth with the informant gone, half-finished drink, a female crew member staring at the empty seat, neon reflections on the table.` |

### Hinterhalt (Kopfgeldjäger)

| ID | Szene | Prompt |
|---|---|---|
| `hinterhalt_frei` | Abgezogen | `Bounty hunters retreating down a spaceport corridor, a female hunter raising a hand in resignation, the mixed crew standing unharmed at the ship ramp.` |
| `hinterhalt_bezahlt` | Bezahlt | `A female bounty leader counting credit chips on a crate, a male crew member handing over the stack, the other hunters lowering their weapons.` |
| `hinterhalt_geschlagen` | Geschlagen | `Bounty hunters scrambling away with loot, leaving gear on the dock, a battered mixed crew standing, a woman helping a wounded man to his feet.` |

### Ereignisketten: Blinder Passagier

| ID | Szene | Prompt |
|---|---|---|
| `passagier_fluechtling_ausgang` | Auf der Flucht | `A female fugitive in worn harbor clothes crouched behind crates, pursuers' flashlights closing in, a crew member offering a hand.` |
| `passagier_fluechtling_sieg` | Dankbar | `A female fugitive pressing a small bundle of credit chips into a crew member's hands, pursuers retreating into spaceport fog.` |
| `passagier_fluechtling_niederlage` | Geholt | `A female fugitive dragged away by armored enforcers, one of them a woman in dark armor, the crew frozen at the foot of a loading ramp.` |
| `passagier_begabt_ausgang` | Eine Begabte | `A frightened teenage girl in a faded jacket, lights flickering around her, figures in white hooded robes closing in from the shadows, one of them a tall woman.` |
| `passagier_begabt_sieg` | In Sicherheit | `A girl wrapped in a blanket in a freighter corridor, a female crew member kneeling beside her reassuringly, the rest of the crew around them, a red glow fading from the hallway behind.` |
| `passagier_begabt_niederlage` | Verloren | `Robed guards, one of them a woman, escorting a girl up a dark ramp, her hand reaching back toward the crew, emergency lights above.` |
| `passagier_dieb_ausgang` | Ein Dieb | `A shadowy female thief slipping through a cargo hold, a crate lid half open, supplies vanishing into her coat, a crew member turning too late.` |
| `passagier_harmlos_ausgang` | Ein Ausreißer | `A young boy in an oversized coat sitting on a crate in a spaceport hall, holding a worn map, a female crew member kneeling down to talk to him.` |

### Ereignisketten: Schmuggelware

| ID | Szene | Prompt |
|---|---|---|
| `schmuggel_zoll_ausgang` | Kontrolle | `A female customs officer with a scanner wand boarding a freighter, mixed crew with hands raised, cargo crates marked with warning stencils.` |
| `schmuggel_zoll_geliefert` | Geliefert | `Crates being loaded onto a buyer's cargo lift, a female broker and a male crew member shaking hands, a briefcase of credits passed between them.` |
| `schmuggel_zoll_erwischt` | Erwischt | `Customs officers hauling sealed crates away on hovertrucks, a female crew member receiving a fine slip, red warning lights.` |
| `schmuggel_verrat_ausgang` | Die Übergabe | `A deserted dock crowded with armed men and women in dark coats, a woman giving a hand signal, the crew's crate in the middle, tension in every face.` |
| `schmuggel_verrat_sieg` | Doch bezahlt | `A mixed crew standing over defeated gunmen, a woman taking a bag of credits from a fallen buyer's coat, smoke drifting across the dock.` |
| `schmuggel_verrat_niederlage` | Ausgeraubt | `Empty dock at dawn, crates gone, a mixed crew walking away with empty hands, a woman letting a torn payment slip fall to the ground.` |
| `schmuggel_lebendig_ausgang` | Lebende Fracht | `A crate lid lifting, drugged people in pale clothing inside, a female crew member's flashlight revealing a numbered wristband on a woman's arm.` |

### Ereignisketten: Wrack

| ID | Szene | Prompt |
|---|---|---|
| `wrack_ueberlebende_ausgang` | Überlebende | `Three survivors huddled in a freezing wreck mess hall, a wounded woman wrapped in a torn blanket, a female crew member entering with medkits, breath visible in the cold.` |
| `wrack_beute_ausgang` | Verlassen | `Abandoned freighter cargo hold, scattered crates, an open toolbox, a woman scanning with a flashlight while her male crewmate pries open a crate, eerie silence.` |
| `wrack_falle_ausgang` | Eine Falle | `A mixed crew stepping into a wreck's airlock, lights suddenly flaring on, armed raiders emerging from behind bulkheads, among them a tall woman with a rifle.` |
| `wrack_falle_sieg` | Abgewehrt | `Defeated raiders sprawled on a wreck deck, a female crew member standing over them with a raised weapon, a safe open with credit bundles spilling out.` |
| `wrack_falle_niederlage` | Zurück an Bord | `A woman sprinting up a boarding ramp back to her ship, raiders firing behind her, engines already glowing, her crewmates pulling her aboard.` |
| `wrack_spur_ausgang` | Ein Schiff ohne Namen | `A derelict ship's laboratory with rows of empty glass cells, a flickering screen showing the number 9, a woman and a man of the crew reflected in the glass.` |
