# Planung: Enzyklopädie (16.10.2026)

Entscheidungen des Nutzers (Koordinations-Chat).

## Entscheidungen

- **Inhalt:** Waffen (auch eigene) mit Werten und Angriffstabelle; Kritische Treffer und Patzer; Rüstungen; Psi-Listen mit Kräften; Kurzregeln (Reichweite, Deckung, Aktivität …) und Fertigkeiten.
- **Erreichbar über das Burgermenü**, überall: **Startmenü, Schiff, Kampf, Charakterübersicht/Editor**.
- **Kontext bleibt:** kleine Hilfen am Ort (Tooltips, ⓘ bei Psi-Listen, „Tabellen“ im Kampf) bleiben, öffnen aber die Enzyklopädie an der passenden Stelle; doppelte Anzeigen entfallen.

## Stand im Code (geprüft)

- Burgermenü gibt es heute im **Kampf** (`ui/top_menu.gd`, Bodenkampf) und im **Schiff** (`ui/hub_ui.gd`, Hub). Im Startmenü und in der Charakterübersicht/im Editor ist kein Burgermenü gefunden worden.
- Vorhandene Anzeigen: `TablesDialog` (`ui/tables_dialog.gd`, Bodenkampf: Angriffstabellen, Kritische, Patzer, Psi-Listen), `PsiListView` (`ui/crew/psi_list_view.gd`, Charakter).

## Aufteilung (Vorschlag Koordinator)

1. **Hub baut die Enzyklopädie** als einen gemeinsamen Dialog (`Encyclopedia.open(abschnitt, eintrag)`), nutzt dafür die Inhalte von `TablesDialog` und `PsiListView` bzw. deren Daten (`GameData`, `Equipment`, `PsiLists`, `Rules`, `docs/Skillsystem.md`), und bindet sie im Startmenü und im Schiff an. **Vorher Mockup** vom Nutzer bestätigen lassen. Schnittstelle unter „Schnittstellen“.
2. **Bodenkampf (danach):** Burgermenü im Kampf → Enzyklopädie; „Tabellen“ öffnet die Enzyklopädie an der passenden Stelle (z. B. gewählte Waffe); eigene Doppel-Anzeige entfernen.
3. **Charakter (danach):** Zugang in Charakterübersicht/Editor (Burgermenü oder Knopf, mit dem Nutzer klären); ⓘ bei Psi-Listen öffnet die Enzyklopädie.
