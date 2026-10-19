// Crew (6) und Gegner (6). Ränge pro Fertigkeit; nicht genannte Fertigkeiten haben Rang 0.
(function (PTF) {
  'use strict';

  function sk(obj) {
    const out = {};
    for (const [id, rank] of Object.entries(obj)) out[id] = { rank, xp: 0 };
    return out;
  }

  const CREW = [
    { id: 'vela', name: 'Vela Marrow', letter: 'V', role: 'Sturmangriff', color: '#e0b84a',
      attrs: { STA: 75, GEW: 72, KOO: 88, KON: 80, INT: 55, EMP: 40, MEN: 72 },
      skills: sk({ gewehre: 9, pistolen: 4, waffenlos: 4, einhand: 2, schnellfeuer: 3, raketenwerfer: 2, kampfsinn: 6, ausweichen: 5, ersteHilfe: 2, ballistikGeschuetze: 3, gassenwissen: 2 }),
      weapons: ['sturmgewehr', 'faeuste'], armor: 'mittel' },
    { id: 'ikko', name: 'Ikko Brandt', letter: 'I', role: 'Pilot & Navigation', color: '#5fc0e8',
      attrs: { STA: 45, GEW: 92, KOO: 84, KON: 55, INT: 78, EMP: 60, MEN: 66 },
      skills: sk({ pistolen: 8, ausweichen: 8, kampfsinn: 5, waffenlos: 2, pilot: 10, navigation: 7, computer: 4, strahlGeschuetze: 5, verhandeln: 2 }),
      weapons: ['laserkarabiner', 'laserpistole'], armor: 'leicht' },
    { id: 'rhea', name: 'Rhea Okafor', letter: 'R', role: 'Medizin', color: '#f2f2f2',
      attrs: { STA: 40, GEW: 66, KOO: 82, KON: 60, INT: 90, EMP: 85, MEN: 60 },
      skills: sk({ pistolen: 6, ausweichen: 5, kampfsinn: 3, ersteHilfe: 10, zweiteHilfe: 8, medikamente: 6, kochen: 4, handeln: 2, computer: 2 }),
      weapons: ['laserkarabiner', 'laserpistole'], armor: 'leicht' },
    { id: 'sol', name: 'Sol Achterberg', letter: 'S', role: 'Technik & schwere Waffen', color: '#e8874a',
      attrs: { STA: 88, GEW: 50, KOO: 74, KON: 86, INT: 82, EMP: 45, MEN: 58 },
      skills: sk({ schnellfeuer: 8, raketenwerfer: 4, geschuetze: 5, waffenlos: 3, kampfsinn: 4, ausweichen: 2, waffenReparatur: 7, rsReparatur: 8, notReparatur: 6, panzerung: 4, hwWaffen: 4, hwRuestung: 3 }),
      weapons: ['mg', 'faeuste'], armor: 'mittel' },
    { id: 'nyx', name: 'Nyx Haldane', letter: 'N', role: 'Psi', color: '#b07ae8',
      attrs: { STA: 35, GEW: 70, KOO: 60, KON: 50, INT: 74, EMP: 92, MEN: 96 },
      skills: sk({ psiAngriff: 9, psiVerteidigung: 8, psiWirken: 8, pistolen: 3, ausweichen: 5, kampfsinn: 4, ersteHilfe: 3, verhandeln: 5, schutzschild: 4 }),
      weapons: ['psiStoss', 'laserpistole'], armor: 'leicht' },
    { id: 'corvin', name: 'Corvin Rask', letter: 'C', role: 'Nahkampf & Schild', color: '#e85a5a',
      attrs: { STA: 92, GEW: 80, KOO: 70, KON: 90, INT: 48, EMP: 50, MEN: 70 },
      skills: sk({ einhand: 9, schild: 7, waffenlos: 6, zweihand: 4, pistolen: 3, ausweichen: 6, kampfsinn: 6, psiVerteidigung: 2, gassenwissen: 4, handeln: 2 }),
      weapons: ['vibroklinge', 'laserpistole'], armor: 'mittel', shield: true },
  ];

  const ENEMIES = [
    { id: 'e1', name: 'Plünderer', letter: 'P', role: 'Söldner', color: '#c0392b',
      attrs: { STA: 65, GEW: 65, KOO: 78, KON: 70, INT: 45, EMP: 30, MEN: 55 },
      skills: sk({ gewehre: 7, ausweichen: 4, kampfsinn: 3, ersteHilfe: 5 }), weapons: ['sturmgewehr'], armor: 'leicht' },
    { id: 'e2', name: 'Plünderer', letter: 'P', role: 'Söldner', color: '#c0392b',
      attrs: { STA: 70, GEW: 60, KOO: 74, KON: 72, INT: 40, EMP: 30, MEN: 60 },
      skills: sk({ gewehre: 7, ausweichen: 4, kampfsinn: 3, ersteHilfe: 3 }), weapons: ['sturmgewehr'], armor: 'leicht' },
    { id: 'e3', name: 'Brecher', letter: 'B', role: 'Schwerer Schütze', color: '#922b21',
      attrs: { STA: 90, GEW: 45, KOO: 70, KON: 92, INT: 40, EMP: 25, MEN: 60 },
      skills: sk({ schnellfeuer: 8, ausweichen: 1, kampfsinn: 3 }), weapons: ['mg'], armor: 'schwer' },
    { id: 'e4', name: 'Funke', letter: 'F', role: 'Raketenschütze', color: '#d35400',
      attrs: { STA: 60, GEW: 62, KOO: 80, KON: 60, INT: 65, EMP: 35, MEN: 55 },
      skills: sk({ raketenwerfer: 7, pistolen: 5, ausweichen: 4, kampfsinn: 3 }), weapons: ['raketenwerfer', 'laserpistole'], armor: 'leicht' },
    { id: 'e5', name: 'Klingentänzer', letter: 'K', role: 'Nahkampf', color: '#a93226',
      attrs: { STA: 82, GEW: 88, KOO: 70, KON: 75, INT: 45, EMP: 40, MEN: 60 },
      skills: sk({ einhand: 9, ausweichen: 7, kampfsinn: 5 }), weapons: ['vibroklinge'], armor: 'leicht' },
    { id: 'e6', name: 'Hexer', letter: 'H', role: 'Psi', color: '#7d3c98',
      attrs: { STA: 40, GEW: 60, KOO: 55, KON: 55, INT: 70, EMP: 80, MEN: 90 },
      skills: sk({ psiAngriff: 8, psiVerteidigung: 7, psiWirken: 4, pistolen: 3, ausweichen: 3, kampfsinn: 3 }), weapons: ['psiStoss', 'laserpistole'], armor: 'keine' },
  ];

  function clone(o) { return JSON.parse(JSON.stringify(o)); }

  // Kampfwerte für einen neuen Kampf setzen
  function prepareForBattle(def, team) {
    const u = clone(def);
    u.team = team;
    u.isCrew = team === 'crew';
    u.maxHp = PTF.Rules.maxHp(u);
    u.hp = u.maxHp;
    u.maxPp = PTF.Rules.maxPp(u);
    u.pp = u.maxPp;
    u.bleed = 0; u.stun = 0; u.malus = 0; u.prone = false; u.state = 'ok';
    u.nextAttackMalus = 0; u.psiShield = 0;
    u.ammo = {}; // Reserve
    u.loaded = {}; // geladen
    for (const w of u.weapons) {
      const W = PTF.WEAPONS[w];
      if (W.mag) { u.loaded[w] = W.mag; u.ammo[w] = W.ammo - W.mag; }
    }
    u.facing = team === 'crew' ? 0 : 3; // Blickrichtung: Crew nach Osten, Gegner nach Westen
    u.reserve = 50; // vor dem ersten eigenen Zug: halbe Aktivität als Ausweichreserve
    u.act = 0;
    u.overwatch = null;
    u.crouched = false;
    u.waiting = false;
    u.medkit = team === 'crew' ? 3 : 0; // Medikit: +20 auf Erste Hilfe, 3 Anwendungen
    u.weapon = u.weapons[0];
    u.xpLog = {};
    u.kills = 0;
    return u;
  }

  PTF.CREW_TEMPLATE = CREW;
  PTF.ENEMY_TEMPLATE = ENEMIES;
  PTF.Units = { prepareForBattle, clone };
})(window.PTF = window.PTF || {});
