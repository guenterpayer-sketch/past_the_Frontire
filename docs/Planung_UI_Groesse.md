# Planung: UI-Größe und Sichtlinie (Spieltest 15.10.2026)

## UI zu groß

**Beobachtung (Nutzer, Screenshot 1920×1080, Spiel 1600×900 im Godot-Editor):** Die Kampf-Oberfläche nimmt zu viel Platz ein: Aktionsfeld unten rechts (mit Psi-Zeile fast die halbe Höhe), Kampflog + Figurenkarte unten links, Leisten oben (Initiative, Runde, Menü).

**Technischer Stand (`godot/project.godot`):** Basisauflösung 1600×900, `stretch/mode = canvas_items`, `aspect = expand` – die Oberfläche skaliert mit dem Fenster und belegt immer denselben Anteil. Die Kästen sind also vom Entwurf her so groß, kein Skalierungsfehler (Annahme des Koordinators aus Code und Screenshot).

**Entschieden (Nutzer):** beides –
1. **Kampf-UI kompakter** (Bodenkampf): Aktionsfeld, Kampflog/Figurenkarte und Leisten oben kleiner (Schrift, Abstände), Selteneres einklappbar (z. B. Psi-Zeile, Aktivitätsstufen). **Erst Mockup**, Nutzer wählt.
2. **Einstellung „UI-Größe“** fürs ganze Spiel (z. B. 75 / 90 / 100 / 125 %), gespeichert. Hauptbildschirm des Nutzers: 1920×1080.

**Zuständigkeit (Koordinator):**
- **Hub:** Einstellung bauen – Speicherort (z. B. `user://settings.cfg`), Anwenden beim Start für das ganze Spiel (Vorschlag: `get_window().content_scale_factor`, dann wirkt es ohne Änderungen in den anderen Modulen), Auswahl im Startmenü (z. B. „Optionen“). Eine kleine Funktion zum Setzen/Lesen bereitstellen und in `hub.md` unter „Schnittstellen“ vermerken.
- **Bodenkampf:** Kampf-UI kompakter (Mockup zuerst); zusätzlich im Kampfmenü einen Eintrag, der die Funktion des Hubs nutzt (optional, mit dem Nutzer klären).
- **Charakter:** nichts, solange die Einstellung über das Fenster wirkt. Falls eigene Dialoge danach zu groß/klein wirken, melden.

## Sichtlinie

**Beobachtung (Nutzer):** Normina (Crew, unten Mitte am Regal) bekommt auf die Gruppe Plünderer (oben rechts, zwischen Kisten) „Kein Angriff: keine Sichtlinie“.

**Regel im Code (`core/battle_map.gd`, `line_of_sight`):** Linie von Augenhöhe (Feld + 1,1) zu Zielhöhe (Feld + 0,8); jedes Hindernis dazwischen, dessen Oberkante über der Linie liegt, blockiert. Niedrige Deckung direkt neben Schütze/Ziel zählt nicht; neben hoher Deckung darf man von Nachbarfeldern aus „um die Ecke“ schauen.

**Entschieden (Nutzer):** **als möglichen Fehler prüfen lassen** (Bodenkampf). Die genaue Szene ist nicht gespeichert; den Fall nachstellen (Schütze hinter Regal/Container, Ziele zwischen Kistenstapeln auf gleicher Höhe), prüfen, ob die Linie korrekt blockiert wird (z. B. Rundung der Hexlinie, Höhe der Kisten, Ziel-/Augenhöhe), und dem Nutzer berichten, bevor etwas geändert wird.

**Befund des Koordinators (Code, 15.10.2026; Ursache im konkreten Fall nicht nachgerechnet):** Kistenstapel haben Höhe 1. Die Sichtlinie fällt von Augenhöhe 1,1 (Schütze) auf Zielhöhe 0,8 (Ziel); eine Kiste (Oberkante 1,0) liegt damit im hinteren ~zwei Drittel der Strecke über der Linie und **sperrt die ganze Sicht**, außer direkt neben dem Ziel (Ausnahme „über niedrige Deckung schießen“). Container (2/4), Regale (3), Säulen (5) sperren immer; Fässer und Betonbarrieren (0,8) nie. Der Nutzer hält Kisten nicht für hohe Hindernisse.

**Entschieden (Nutzer):** Der Bodenkampf stellt den Fall nach, misst, wie oft Kisten die Sicht sperren, und macht **2–3 Vorschläge**, wie Kisten die Sichtlinie behandeln sollen (z. B. nur Deckung ohne Sichtsperre; Sperre nur nah am Ziel). Nutzer entscheidet, dann bauen.

