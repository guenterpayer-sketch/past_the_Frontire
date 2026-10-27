class_name SkillTexts
extends RefCounted
## Kurzbeschreibung je Fertigkeit für die Enzyklopädie, mit dem Ort, an dem sie im Spiel wirkt.

const TEXT := {
	&"waffenlos": "Kämpfen mit Fäusten, Tritten und Griffen. Nahkampf ohne Waffe.",
	&"einhand": "Nahkampf mit Waffen für eine Hand, z. B. Vibroklinge. Lässt die andere Hand frei für einen Schild.",
	&"zweihand": "Nahkampf mit schweren Waffen für beide Hände, z. B. Energiehammer.",
	&"pistolen": "Schießen mit Handfeuerwaffen für eine Hand, z. B. Laserpistole.",
	&"gewehre": "Schießen mit Gewehren und Karabinern, z. B. Sturmgewehr, Laserkarabiner.",
	&"schnellfeuer": "Schießen mit schweren Dauerfeuerwaffen wie dem MG; Feuerstoß über mehrere Schuss pro Angriff.",
	&"raketenwerfer": "Schießen mit Raketen- und Granatwerfern; Treffer mit Druckwelle, Mindestabstand beachten.",
	&"geschuetze": "Bedienen fest montierter oder schwerer Geschütze am Boden.",
	&"kampfsinn": "Gespür für die Lage im Gefecht. Erhöht die Initiative und schützt vor Überraschung.",
	&"ausweichen": "Sich Angriffen entziehen. Erhöht die Verteidigung (VW) gegen Nah- und Fernangriffe.",
	&"schild": "Umgang mit einem Schild. Gibt Verteidigung, solange beide Waffen einhändig sind.",
	&"psiAngriff": "Probe für angreifende Psi-Kräfte (Liste Angriff) gegen die Psi-Verteidigung des Ziels.",
	&"psiVerteidigung": "Widerstand gegen Psi-Angriffe (Psi-VW).",
	&"ersteHilfe": "Versorgen im Einsatz: Blutungen stillen, Sterbende stabilisieren.",
	&"zweiteHilfe": "Behandlung nach dem Einsatz. In der Krankenstation des Schiffs würfeln Arzt und Helfer damit die tägliche Heilprobe.",
	&"psiWirken": "Probe für unterstützende Psi-Kräfte (Schutz, Heilung, Wahrnehmung, Stärkung, Teile der Telekinese).",
	&"waffenReparatur": "Waffen im Einsatz instand setzen: eigene Waffe oder die eines Nachbarn, einmal je Stück und Kampf (50 % Aktivität, Mittel). Herausragend +10, Erfolg +5, Patzer −10; höchstens bis −5.",
	&"rsReparatur": "Instandhaltung des Schiffs. Reiseprobe je Reisetag (Hülle) und große Reparatur durch die Crew.",
	&"navigation": "Kurs und Sprünge berechnen. Reiseprobe je Reisetag, Erfolge sparen Treibstoff.",
	&"pilot": "Das Schiff fliegen. Reiseprobe je Reisetag, Erfolge sparen Treibstoff.",
	&"computer": "Schiffssysteme und Rechner bedienen. Reiseprobe je Reisetag, Erfolge sparen Treibstoff.",
	&"strahlGeschuetze": "Raumkampf, Geschützstation: Schießen mit Strahlwaffen des Schiffs (z. B. Laser).",
	&"ballistikGeschuetze": "Raumkampf, Geschützstation: Schießen mit Kanonen und Massebeschleunigern des Schiffs, auch mit Abwehrgeschützen.",
	&"raketen": "Raumkampf, Geschützstation: Abfeuern der Raketen des Schiffs.",
	&"schutzschild": "Raumkampf, Station Schilde: Probe je Runde lädt die Schilde mit der zugeteilten Energie auf; bei Teilerfolg oder besser lassen sie sich auf die Seiten verteilen.",
	&"panzerung": "Raumkampf, Station Technik: Hülle flicken (Mittel). Erfolg 2W6 Hülle zurück, Herausragend +5.",
	&"notReparatur": "Raumkampf, Station Technik: ausgefallene oder beschädigte Systeme unter Beschuss reparieren (Schwer). Erfolg eine Schadensstufe weniger, Herausragend zwei.",
	&"handeln": "Raumhafen, Händler: eine Probe pro Tag und Hafen. Bestimmt Kauf- und Verkaufspreise von Waffen, Rüstungen, Schilden, Munition, Medikits und Handwerksmaterial.",
	&"gassenwissen": "Raumhafen, Händler und Schiffshändler: eine Probe pro Tag und Hafen. Bestimmt, wie groß das Sortiment ist.",
	&"verhandeln": "Raumhafen, Schiffshändler: eine Probe pro Tag und Hafen. Bestimmt die Preise fürs Schiff: Treibstoff, Proviant, Werft, Schiffsmaterial, Ausbau, Schiffswaffen und Schiffsmunition.",
	&"hwRuestung": "Rüstungen in der Werkstatt bauen, zerlegen und reparieren.",
	&"hwWaffen": "Waffen und Munition in der Werkstatt bauen, zerlegen und reparieren.",
	&"kochen": "Versorgung der Crew an Bord: der Koch in der Kombüse würfelt jeden Tag außerhalb des Hafens; das Ergebnis senkt oder erhöht den Proviantverbrauch (Patzer +25 %, Teilerfolg −10 %, Erfolg −20 %, Herausragend −30 %). Ein Herausragend bis zum Training gibt dort +1 freie EP.",
	&"medikamente": "Medikits in der Krankenstation herstellen.",
	&"koerper": "Körperliche Entwicklung: je Rang +5 Trefferpunkte. Nur die Ränge zählen.",
	&"psiPunkte": "Psi-Entwicklung: je Rang +2 Psi-Punkte. Nur die Ränge zählen.",
	&"lSchutz": "Psi-Liste Schutz: Abschirmen, Psi-Schild, Ablenkfeld und mehr. Rang = höchste verfügbare Stufe.",
	&"lHeilung": "Psi-Liste Heilung: Blutung stillen, Wunden schließen bis Am Leben halten. Rang = höchste verfügbare Stufe.",
	&"lAngriff": "Psi-Liste Angriff: Psi-Nadel, Psi-Stoß, Lähmen und mehr. Rang = höchste verfügbare Stufe.",
	&"lWahrnehmung": "Psi-Liste Wahrnehmung: Gefahrensinn, Gedanken orten und mehr. Rang = höchste verfügbare Stufe.",
	&"lTelekinese": "Psi-Liste Telekinese: Stoßen, Entwaffnen und mehr. Rang = höchste verfügbare Stufe.",
	&"lStaerkung": "Psi-Liste Stärkung: Fokus, Wachheit, Zielsicherheit und mehr; kleine Boni, die lange halten. Rang = höchste verfügbare Stufe.",
}


static func text(id: StringName) -> String:
	return TEXT.get(id, "")
