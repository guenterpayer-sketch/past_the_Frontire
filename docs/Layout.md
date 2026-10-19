# Layoutregeln für Fenster und Oberflächen

Gilt für alle Module (Wunsch des Nutzers 19.10.2026). Ziel: Neue Fenster sehen aus wie die vorhandenen und wirken nicht wie ein Fremdkörper. Grundlage sind die Muster, die in den vorhandenen Fenstern stehen (gesammelt vom Story-Chat, im Code geprüft vom Koordinator).

## Vor dem Bauen

1. Screenshots vorhandener Fenster ansehen (`godot --path godot -- --autotest-hub`, Bilder in `PTF_OUT`) und das neue Fenster daneben vergleichen. Es reicht nicht, nur die Farben aus `UiTheme` zu übernehmen.
2. Bei größeren Oberflächen erst ein Mockup zeigen, dann bauen (`CLAUDE.md`).
3. Vorhandene Bausteine nehmen statt eigener: `Modal`, `UiTheme.label`, `UiTheme.button`, `UiTheme.box`, `UiTheme.badge`, `Modal.rich`.

## Farben (`ui/ui_theme.gd`)

| Zweck | Konstante |
|---|---|
| Hintergrund / Fenster / Karte | `BG` / `PANEL` / `PANEL2` |
| Rahmen | `LINE` |
| Text / Erklärtext | `TEXT` / `MUTED` |
| Titel, Hauptaktion, Hervorhebung | `ACCENT` (gold) |
| Crew / Gegner | `CREW` / `ENEMY` |
| gut / schlecht / Rückzug | `GOOD` / `BAD` / `RETREAT` |

Keine eigenen Farbwerte im Modulcode, außer für Hover-Töne wie in vorhandenem Code.

## Fenster

- **Dialoge sind ein `Modal`:** abgedunkelter Hintergrund, Panel `PANEL` mit Rahmen `LINE`, Radius 10, Innenabstand 16.
- **Größe:** groß und fest über `max_size`. Die Standardgröße ist 1180 × 860. Große Arbeitsfenster bekommen 1300–1520 × 820–860 (Briefing, Enzyklopädie, Werkstatt). Kleine Abfragen bekommen etwa 640–760 × 320–620. Die Größe richtet sich nicht nach dem Inhalt.
- **Titel:** golden, 20 px, links in der Titelleiste (`Modal.open(titel)`). Darunter eine graue Erklärzeile (13 px, `MUTED`), die in einem Satz sagt, was das Fenster tut.
- **Fußleiste:** rechts ausgerichtet. Die Hauptaktion hat goldene Schrift (`font_color` = `ACCENT`), daneben steht „Schließen“ (`Modal.add_close()`).
- **Lange Inhalte** scrollen senkrecht, das übernimmt der Inhaltsbereich des `Modal`. Waagerecht scrollt nichts.

## Schrift

| Element | Größe | Farbe |
|---|---|---|
| Fenstertitel | 20 | `ACCENT` |
| Kartentitel, wichtige Zeilen | 15–16 | `TEXT` (Hervorhebung `ACCENT`) |
| Fließtext | 14 | `TEXT` |
| Erklärtext, Beschreibungen | 13 | `MUTED` |
| Abschnittsüberschrift | 13, GROSSBUCHSTABEN | `MUTED` |
| Kleinangaben (Werte, Fußnoten) | 11–12 | `MUTED` |

## Bausteine

- **Auswahl als Karte** (Vorbild: Feindkontakt, `hub_ui.gd` `_choice_box`): `PanelContainer` mit `UiTheme.box(PANEL2, LINE, 8, 12)`. Darin der Titel (16), eine graue Beschreibung (13, `MUTED`) und ein Knopf mit goldener Schrift.
- **Crewmitglieder:** farbiges Buchstabenkästchen (`UiTheme.badge`) vor dem Namen.
- **Seitenleiste mit Reitern** (Vorbild: Enzyklopädie): gerahmte Reiter, die Anzahl steht in Klammern („Waffen (68)“).
- **Tabellen** als BBCode über `Modal.rich`.
- **Keine gerahmten Etiketten** um einzelne Werte oder Wörter. Rahmen gibt es nur bei Karten, Reitern und Knöpfen.
- **Abstände:** die Theme-Standards (6 in Boxen, 4 im Raster). Abschnitte trennt eine Überschrift, keine Linie.

## UI-Größe

- Alle Fenster müssen mit der Einstellung „UI-Größe“ (75–125 %, `ui/ui_scale.gd`) lesbar bleiben. Keine festen Pixelpositionen außerhalb der Container.
