# Zusammenführung der Module – Verlauf und offene Punkte

Stand: 19.10.2026. Ältere Verläufe: `docs/module/archiv/Zusammenfuehrung_bis_2026-10-16.md`, `docs/module/archiv/Zusammenfuehrung_bis_2026-10-19.md`.

## Arbeitsweise mit Branches

- **`main`** ist der gemeinsame Hauptbranch, gepflegt vom Koordinations-Chat (`docs/module/koordination.md`). Jedes Modul arbeitet auf seinem eigenen Branch und meldet einen fertigen Zwischenstand; der Koordinator führt nur konfliktfreie Branches mit grünen Tests zusammen.
- Danach holt jeder Modul-Chat `main` in seinen Branch (`git merge origin/main`), damit alle mit dem gleichen Stand weiterarbeiten.

| Branch | Modul | Stand |
|---|---|---|
| `claude/confident-edison-6mxzke` | Bodenkampf | in `main` (`204d874`), nichts offen |
| `claude/elegant-gauss-hq5bus` | Charakter-Modul und Charakter-Editor | in `main` (`9228e24`), nichts offen |
| `claude/happy-lamport-u4fvya` | Hub (Startmenü, Schiff, Sternenkarte, Spielstände) | in `main` (`465c9a5`), nichts offen |
| `claude/raumkampf-modul` | Raumkampf (Mutterschiff, Jäger) | in `main` (`49e14ad`), nichts offen |
| `claude/inspiring-hypatia-5l2tq8` | Export (Android, Windows) | in `main` (`5aed945`), nichts offen |
| `claude/zen-sagan-9yn0le` | Story/Kampagne | in `main` (`94a8cc3`), nichts offen |

## Verlauf

| Datum | Commit in `main` | Branch (Commit) | Ergebnis |
|---|---|---|---|
| 21.10.2026 | (dieser Merge) | Bodenkampf `claude/confident-edison-6mxzke` (`8a41542`) | Klick auf einen Gegner unter dem Infokasten greift an. Version 0.5. |
| 20.10.2026 | (dieser Merge) | Hub `claude/happy-lamport-u4fvya` (`efa8a0b`) | Absturz behoben: Szenenfenster nach Szenenwechsel (`get_tree()` null). Tests rules/hub/story OK (Koordinator). |
| 20.10.2026 | (dieser Merge) | Hub `claude/happy-lamport-u4fvya` (`f51c434`) | Auftrag 9: Handel an Stationen wie im Hafen (+20 %), Titel mit Station. Version 0.4. |
| 20.10.2026 | (dieser Merge) | Hub `claude/happy-lamport-u4fvya` (`07b2f98`) | Auftrag 8: Story-Fenster erst nach allen anderen Fenstern, Auto-Spielstand (Slot 0). Version 0.3. Hinweis: `--autotest-touch` gehört dem Bodenkampf, Hub-Test heißt `--autotest-hub-touch`. |
