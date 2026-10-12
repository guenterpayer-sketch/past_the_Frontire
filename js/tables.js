// Rüstung, Waffen, Angriffstabellen, Kritische Treffer, Patzer. Siehe docs/Skillsystem.md Abschnitt 5.
(function (PTF) {
  'use strict';

  // cls = Spalte in den Angriffstabellen
  const ARMOR = {
    keine: { name: 'Keine', cls: 0, db: 0 },
    leicht: { name: 'Flexanzug (leicht)', cls: 1, db: 0 },
    mittel: { name: 'Kampfpanzer (mittel)', cls: 2, db: -5 },
    schwer: { name: 'Servo-Rüstung (schwer)', cls: 3, db: -10, move: -1 },
  };
  const ARMOR_CLASSES = ['Keine', 'Leicht', 'Mittel', 'Schwer'];
  const ARMOR_DMG = [1, 0.9, 0.8, 0.65];
  const SEVERITIES = ['A', 'B', 'C', 'D', 'E'];
  const SEVERITY_MOD = { A: -20, B: -10, C: 0, D: 10, E: 20 };

  const ATTACK_TABLES = {
    wucht: { name: 'Wucht', hit: [65, 70, 80, 90], crit: 'wucht' },
    klinge: { name: 'Klinge', hit: [65, 70, 75, 85], crit: 'schnitt' },
    strahl: { name: 'Strahl', hit: [70, 75, 80, 85], crit: 'hitze' },
    projektil: { name: 'Projektil', hit: [70, 75, 80, 90], crit: 'durchschlag' },
    explosion: { name: 'Explosion', hit: [60, 60, 65, 70], crit: 'explosion' },
    psi: { name: 'Psi', hit: [70, 70, 70, 70], crit: 'psi', ignoresArmor: true },
  };
  const CRIT_GAP = 30; // ab Schwelle + 30 beginnt der kritische Bereich
  const CRIT_STEP = 10; // alle 10 Punkte ein Grad mehr

  // Ergebnis auf einer Angriffstabelle nachschlagen
  function lookupAttack(tableId, total, armorCls, dmgMult) {
    const t = ATTACK_TABLES[tableId];
    const thr = t.hit[armorCls];
    if (total < thr) return { hit: false, threshold: thr };
    const armorF = t.ignoresArmor ? 1 : ARMOR_DMG[armorCls];
    const dmg = Math.max(1, Math.round((3 + (total - thr) / 5) * dmgMult * armorF));
    let severity = null;
    const critStart = thr + CRIT_GAP;
    if (total >= critStart) severity = SEVERITIES[Math.min(4, Math.floor((total - critStart) / CRIT_STEP))];
    return { hit: true, threshold: thr, dmg, severity, critType: t.crit };
  }

  const WEAPONS = {
    faeuste: { name: 'Fäuste', skill: 'waffenlos', table: 'wucht', melee: true, range: 1, max: 110, fumble: 2, dmg: 0.5 },
    vibroklinge: { name: 'Vibroklinge', skill: 'einhand', table: 'klinge', melee: true, range: 1, max: 150, fumble: 3, dmg: 1.1 },
    energiehammer: { name: 'Energiehammer', skill: 'zweihand', table: 'wucht', melee: true, range: 1, max: 150, fumble: 5, dmg: 1.4 },
    laserpistole: { name: 'Laserpistole', skill: 'pistolen', table: 'strahl', range: 6, max: 130, fumble: 2, dmg: 0.8 },
    sturmgewehr: { name: 'Sturmgewehr', skill: 'gewehre', table: 'projektil', range: 10, max: 150, fumble: 3, dmg: 1.0 },
    mg: { name: 'Schweres MG (Feuerstoß)', skill: 'schnellfeuer', table: 'projektil', range: 8, max: 150, fumble: 5, dmg: 1.1, ob: 15 },
    raketenwerfer: { name: 'Raketenwerfer', skill: 'raketenwerfer', table: 'explosion', range: 9, minRange: 2, max: 150, fumble: 5, dmg: 1.4, ammo: 2, splash: -30 },
    psiStoss: { name: 'Psi-Stoß', skill: 'psiAngriff', table: 'psi', range: 7, max: 140, fumble: 4, dmg: 1.0, pp: 2, psi: true },
  };

  // Kritische Treffer: 7 Stufen (≤20, 21–40, 41–60, 61–80, 81–95, 96–110, 111+)
  // Felder: dmg, bleed, stun (Runden), malus, prone, ko (bewusstlos), kill
  const CRIT_TABLES = {
    durchschlag: { name: 'Durchschlag', rows: [
      { text: 'Streifschuss.', dmg: 2 },
      { text: 'Treffer in den Oberschenkel.', dmg: 4, bleed: 1 },
      { text: 'Schuss durch die Schulter.', dmg: 5, bleed: 1, malus: -10 },
      { text: 'Treffer in den Bauch.', dmg: 7, bleed: 2, stun: 1 },
      { text: 'Durchschuss der Lunge.', dmg: 9, bleed: 3, stun: 2, malus: -20 },
      { text: 'Treffer am Hals, das Ziel bricht zusammen.', dmg: 12, bleed: 4, stun: 3, prone: true },
      { text: 'Kopfschuss.', kill: true },
    ] },
    hitze: { name: 'Hitze', rows: [
      { text: 'Verbrennung an der Hand.', dmg: 2 },
      { text: 'Der Ärmel fängt Feuer.', dmg: 3, malus: -5 },
      { text: 'Der Strahl schmilzt die Brustplatte an.', dmg: 5, stun: 1 },
      { text: 'Tiefe Brandwunde am Bein.', dmg: 7, malus: -15, prone: true },
      { text: 'Der Strahl brennt durch den Torso.', dmg: 10, bleed: 1, stun: 2, malus: -20 },
      { text: 'Gesicht verbrannt, das Ziel ist geblendet.', dmg: 12, stun: 3, malus: -30 },
      { text: 'Der Strahl durchbohrt das Herz.', kill: true },
    ] },
    wucht: { name: 'Wucht', rows: [
      { text: 'Harter Stoß.', dmg: 2 },
      { text: 'Schlag gegen die Rippen.', dmg: 3, stun: 1 },
      { text: 'Schlag gegen das Knie, das Ziel stürzt.', dmg: 4, prone: true },
      { text: 'Rippen brechen.', dmg: 6, malus: -10, stun: 1 },
      { text: 'Schlag an den Kopf.', dmg: 8, stun: 2, prone: true },
      { text: 'Schädelbruch.', dmg: 10, stun: 4, malus: -25 },
      { text: 'Genick gebrochen.', kill: true },
    ] },
    schnitt: { name: 'Schnitt', rows: [
      { text: 'Kratzer.', dmg: 1, bleed: 1 },
      { text: 'Schnitt am Unterarm.', dmg: 3, bleed: 1 },
      { text: 'Tiefer Schnitt in den Oberschenkel.', dmg: 4, bleed: 2, malus: -10 },
      { text: 'Die Klinge fährt in die Seite.', dmg: 6, bleed: 3, stun: 1 },
      { text: 'Sehne durchtrennt.', dmg: 8, bleed: 3, malus: -25, prone: true },
      { text: 'Arterie durchtrennt.', dmg: 10, bleed: 6, stun: 2 },
      { text: 'Kehle durchtrennt.', kill: true },
    ] },
    explosion: { name: 'Explosion', rows: [
      { text: 'Splitter.', dmg: 3 },
      { text: 'Die Druckwelle wirft das Ziel um.', dmg: 4, prone: true },
      { text: 'Splitter im Arm.', dmg: 6, bleed: 1, malus: -5 },
      { text: 'Volle Druckwelle.', dmg: 8, stun: 2, prone: true },
      { text: 'Schwere Splitterwunden.', dmg: 10, bleed: 3, stun: 2 },
      { text: 'Bein zerfetzt.', dmg: 14, bleed: 5, malus: -40, prone: true },
      { text: 'Mitten in der Explosion.', kill: true },
    ] },
    psi: { name: 'Psi', rows: [
      { text: 'Stechender Kopfschmerz.', dmg: 1, malus: -5 },
      { text: 'Nasenbluten.', dmg: 2, bleed: 1 },
      { text: 'Ein Gedankenstoß lässt das Ziel taumeln.', dmg: 3, stun: 1 },
      { text: 'Panikwelle.', dmg: 4, stun: 2, malus: -10 },
      { text: 'Psychischer Schock.', dmg: 6, stun: 3, malus: -15 },
      { text: 'Der Verstand bricht zusammen.', dmg: 8, ko: true },
      { text: 'Hirnblutung.', kill: true },
    ] },
  };
  const CRIT_BANDS = [20, 40, 60, 80, 95, 110];

  function rollCrit(type, severity) {
    const roll = PTF.Dice.d100();
    const total = roll + SEVERITY_MOD[severity];
    let idx = CRIT_BANDS.findIndex(b => total <= b);
    if (idx < 0) idx = CRIT_BANDS.length;
    return { roll, total, row: CRIT_TABLES[type].rows[idx], table: CRIT_TABLES[type].name };
  }

  const FUMBLE_TABLE = [
    { upTo: 40, text: 'Zögern – der Rest des Zuges ist verloren.', loseTurn: true },
    { upTo: 70, text: 'Die Waffe klemmt / überhitzt – nächster Angriff −20.', nextMalus: -20 },
    { upTo: 90, text: 'Ins Stolpern geraten – niedergeworfen.', prone: true },
    { upTo: 100, text: 'Querschläger / Rückkopplung – 1W10 Schaden am Angreifer.', selfDmg: true },
  ];
  function rollFumble() {
    const roll = PTF.Dice.d100();
    return { roll, row: FUMBLE_TABLE.find(f => roll <= f.upTo) };
  }

  PTF.ARMOR = ARMOR;
  PTF.ARMOR_CLASSES = ARMOR_CLASSES;
  PTF.ATTACK_TABLES = ATTACK_TABLES;
  PTF.WEAPONS = WEAPONS;
  PTF.CRIT_TABLES = CRIT_TABLES;
  PTF.CRIT_BANDS = CRIT_BANDS;
  PTF.FUMBLE_TABLE = FUMBLE_TABLE;
  PTF.Tables = { lookupAttack, rollCrit, rollFumble, CRIT_GAP, CRIT_STEP, SEVERITIES, SEVERITY_MOD };
})(window.PTF = window.PTF || {});
