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
| 27.10.2026 | (dieser Merge) | Bodenkampf `claude/confident-edison-6mxzke` (`2ff16dd`) | Psi-Liste „Stärkung“ im Kampf (9 Kräfte, 110 % Aktivität, TP-Puffer, STÄ/GEW-Bonus, `Combatant.injury_malus`), KI nutzt sie. Noch nicht lernbar (Charakter). Version 0.17. |
| 27.10.2026 | (dieser Merge) | Charakter `claude/elegant-gauss-hq5bus` (`a8afa01`) | Nur Doku: Psi-Liste „Stärkung“ (Skillsystem 6.1), Anfrage an Bodenkampf. Auftrag an Bodenkampf eingetragen. |
| 25.10.2026 | (dieser Merge) | Charakter `claude/elegant-gauss-hq5bus` (`bb43695`) | Waffenkammer bleibt in fester Breite, lange Namen und Spalten brechen um. Tests rules/hub OK (Koordinator). Version 0.16. |
| 24.10.2026 | (dieser Merge) | Bodenkampf `claude/confident-edison-6mxzke` (`7462c15`) | Schildträger mit einhändigen Waffen, Schild als Beute (30 %). Tests rules/hub/sim OK (Koordinator). Version 0.15. |
| 24.10.2026 | (dieser Merge) | Hub `claude/happy-lamport-u4fvya` (`caebb88`) | Auftrag 11: Preise Scharfschützengewehr und Elite-Ausrüstung, Schild immer im Sortiment, in der Werkstatt baubar, als Beute ins Lager. Tests rules/hub OK (Koordinator). Version 0.14. |
| 24.10.2026 | (dieser Merge) | Bodenkampf `claude/confident-edison-6mxzke` (`86cf0e8`) | Balancing-Paket: neue Gegnertypen, Budget 55/75/100, bis 12 Gegner, Mitwachsen mit dem Trupp, Elite/Leutnant/Hauptmann/Boss mit Elite-Ausrüstung, Elite-Beute 12 %. `Mission.generate(seed, diff, faction, diff_factor, elite)`. Tests story/space OK (Koordinator), rules/hub/sim laut Modul. Version 0.13. Offen: Preise in `Stock.PRICES`. |
| 24.10.2026 | (diese Merges) | Raumkampf (`cbc3faa`), Hub (`44c0514`) | Raum: Schwierigkeitsgrad (beides halb). Hub Auftrag 10: Elite/Boss-Wurf, Kopfgeld-Aufträge, Schwierigkeitsgrad beim neuen Spiel und in den Einstellungen, Elite-Beute verkaufbar. Konflikt nur in `godot/README.md` (Doku, beide Stände übernommen). Tests rules/hub/story/space/sim OK (Koordinator). Version 0.12. Offen: Bodenkampf baut `Mission.elite`, Faktor, Elite-Ausrüstung. |
| 24.10.2026 | (dieser Merge) | Story `claude/zen-sagan-9yn0le` (`c5863dd`) | Boss am Ende der Ketten (Finale/Hinterhalt immer, Schritte/Ereignisse 30 %, Zoll nie); `Story.pending_mission()` liefert `elite`/`boss_name`. Version 0.11. |
| 24.10.2026 | (dieser Merge) | Raumkampf `claude/raumkampf-modul` (`98c1769`) | Elite-/Boss-Beute (20 %/30 % beim Entern), normales Entern höchstens 1 Waffe; Boss-Kreuzer + 2 Jäger (`setup.enemy.boss`, `boss_name`). Version 0.10. |
| 24.10.2026 | (dieser Merge) | Raumkampf `claude/raumkampf-modul` (`9494c15`) | Elite-Gegner (★, Schnittstelle `setup.enemy.elite`), moderate Anpassung an die Crew, Stationstreffer 25 %. Version 0.9. Offen: Hub würfelt Elite und zeigt sie im Angebot/Kontakt. |
| 24.10.2026 | (dieser Merge) | Raumkampf `claude/raumkampf-modul` (`c0538b2`, `ace57e4`) | Gegner-Info aus eigenen Treffern, „Scannen“ an der Computer-Station, Tooltip über dem Gegnerschiff. Version 0.8. Offen: auf Touch kein Mouseover. |
| 23.10.2026 | (dieser Merge) | Bodenkampf (`1f2374f`), Story (`e2ceaa5`, `2c9ec4d`, `7fc4daa`) | Seitenleiste bleibt im Bild; Story nimmt Bild der Vorlage für alte Spielstände, Test für Bildfelder, überarbeitete Prompts (+ `docs/Story_Bilder_Prompts.docx`). Tests rules/hub/story OK (Koordinator). Version 0.7. |
| 21.10.2026 | (dieser Merge) | Story `claude/zen-sagan-9yn0le` (`45adbd4`) | Bild für jede Szene (41 image-Felder). Tests story/rules OK (Koordinator). Version 0.6. |
| 21.10.2026 | (dieser Merge) | Bodenkampf `claude/confident-edison-6mxzke` (`8a41542`) | Klick auf einen Gegner unter dem Infokasten greift an. Version 0.5. |
| 20.10.2026 | (dieser Merge) | Hub `claude/happy-lamport-u4fvya` (`efa8a0b`) | Absturz behoben: Szenenfenster nach Szenenwechsel (`get_tree()` null). Tests rules/hub/story OK (Koordinator). |
| 20.10.2026 | (dieser Merge) | Hub `claude/happy-lamport-u4fvya` (`f51c434`) | Auftrag 9: Handel an Stationen wie im Hafen (+20 %), Titel mit Station. Version 0.4. |
| 20.10.2026 | (dieser Merge) | Hub `claude/happy-lamport-u4fvya` (`07b2f98`) | Auftrag 8: Story-Fenster erst nach allen anderen Fenstern, Auto-Spielstand (Slot 0). Version 0.3. Hinweis: `--autotest-touch` gehört dem Bodenkampf, Hub-Test heißt `--autotest-hub-touch`. |
