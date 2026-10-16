class_name SkillTexts
extends RefCounted
## Kurzbeschreibung je Fertigkeit für die Enzyklopädie. „Noch ohne Wirkung“ = im Spiel bisher nicht benutzt.

const SOON := " (Im Spiel noch ohne Wirkung.)"

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
	&"psiWirken": "Probe für unterstützende Psi-Kräfte (Schutz, Heilung, Wahrnehmung, Teile der Telekinese).",
	&"waffenReparatur": "Instandsetzen von Waffen und Ausrüstung." + SOON,
	&"rsReparatur": "Instandhaltung des Schiffs. Reiseprobe je Reisetag (Hülle) und große Reparatur durch die Crew.",
	&"navigation": "Kurs und Sprünge berechnen. Reiseprobe je Reisetag, Erfolge sparen Treibstoff.",
	&"pilot": "Das Schiff fliegen. Reiseprobe je Reisetag, Erfolge sparen Treibstoff.",
	&"computer": "Schiffssysteme und Rechner bedienen. Reiseprobe je Reisetag, Erfolge sparen Treibstoff.",
	&"strahlGeschuetze": "Strahlwaffen des Schiffs im Raumkampf." + SOON,
	&"ballistikGeschuetze": "Kanonen und Massebeschleuniger des Schiffs im Raumkampf." + SOON,
	&"raketen": "Raketen des Schiffs im Raumkampf." + SOON,
	&"schutzschild": "Schutzschild des Schiffs im Raumkampf steuern." + SOON,
	&"panzerung": "Schadenskontrolle und Panzerung im Raumkampf." + SOON,
	&"notReparatur": "Schnelle Reparaturen unter Beschuss im Raumkampf." + SOON,
	&"handeln": "Feilschen um Preise beim Kaufen und Verkaufen." + SOON,
	&"gassenwissen": "Kontakte, Gerüchte und Wege abseits des Offiziellen." + SOON,
	&"verhandeln": "Verträge und Bedingungen aushandeln." + SOON,
	&"hwRuestung": "Rüstungen in der Werkstatt bauen, zerlegen und reparieren.",
	&"hwWaffen": "Waffen und Munition in der Werkstatt bauen, zerlegen und reparieren.",
	&"kochen": "Versorgung der Crew an Bord." + SOON,
	&"medikamente": "Medikits in der Krankenstation herstellen.",
	&"koerper": "Körperliche Entwicklung: je Rang +5 Trefferpunkte. Nur die Ränge zählen.",
	&"psiPunkte": "Psi-Entwicklung: je Rang +2 Psi-Punkte. Nur die Ränge zählen.",
	&"lSchutz": "Psi-Liste Schutz: Abschirmen, Psi-Schild, Ablenkfeld und mehr. Rang = höchste verfügbare Stufe.",
	&"lHeilung": "Psi-Liste Heilung: Blutung stillen, Wunden schließen bis Am Leben halten. Rang = höchste verfügbare Stufe.",
	&"lAngriff": "Psi-Liste Angriff: Psi-Nadel, Psi-Stoß, Lähmen und mehr. Rang = höchste verfügbare Stufe.",
	&"lWahrnehmung": "Psi-Liste Wahrnehmung: Gefahrensinn, Gedanken orten und mehr. Rang = höchste verfügbare Stufe.",
	&"lTelekinese": "Psi-Liste Telekinese: Stoßen, Entwaffnen und mehr. Rang = höchste verfügbare Stufe.",
}


static func text(id: StringName) -> String:
	return TEXT.get(id, "")
