// Skillsystem: Eigenschaften, Fertigkeiten, Proben, Erfahrung. Regeln siehe docs/Skillsystem.md
(function (PTF) {
  'use strict';

  const ATTRIBUTES = [
    { id: 'STA', short: 'STÄ', name: 'Stärke' },
    { id: 'GEW', short: 'GEW', name: 'Gewandtheit' },
    { id: 'KOO', short: 'KOO', name: 'Koordination' },
    { id: 'KON', short: 'KON', name: 'Konstitution' },
    { id: 'INT', short: 'INT', name: 'Intelligenz' },
    { id: 'EMP', short: 'EMP', name: 'Empathie' },
    { id: 'MEN', short: 'MEN', name: 'Mentale Stärke' },
  ];

  const SKILL_GROUPS = [
    { id: 'kampf', name: 'Fähigkeiten Kampf', skills: [
      ['waffenlos', 'Waffenloser Kampf', 'STA', 'GEW'],
      ['einhand', 'Einhand-Waffen', 'STA', 'GEW'],
      ['zweihand', 'Zweihand-Waffen', 'STA', 'KON'],
      ['pistolen', 'Pistolen', 'KOO', 'GEW'],
      ['gewehre', 'Gewehre', 'KOO', 'MEN'],
      ['schnellfeuer', 'Schnellfeuerwaffen', 'KOO', 'STA'],
      ['raketenwerfer', 'Raketenwerfer', 'KOO', 'INT'],
      ['geschuetze', 'Geschütze', 'KOO', 'INT'],
      ['kampfsinn', 'Kampfsinn', 'INT', 'GEW'],
      ['ausweichen', 'Ausweichen', 'GEW', 'KOO'],
      ['schild', 'Schild', 'STA', 'KOO'],
      ['psiAngriff', 'Psi-Angriffe', 'MEN', 'EMP'],
      ['psiVerteidigung', 'Psi-Verteidigung', 'MEN', 'INT'],
    ] },
    { id: 'allgemein', name: 'Fähigkeiten', skills: [
      ['ersteHilfe', 'Erste Hilfe', 'INT', 'KOO'],
      ['zweiteHilfe', 'Zweite Hilfe', 'INT', 'EMP'],
      ['psiWirken', 'Psi wirken', 'MEN', 'EMP'],
      ['waffenReparatur', 'Waffen-Reparatur', 'INT', 'KOO'],
    ] },
    { id: 'rsTechnik', name: 'Raumschiff-Technik', skills: [
      ['rsReparatur', 'Reparatur', 'INT', 'KOO'],
      ['navigation', 'Navigation', 'INT', 'MEN'],
      ['pilot', 'Pilot', 'GEW', 'KOO'],
      ['computer', 'Computer', 'INT', 'MEN'],
    ] },
    { id: 'rsKampf', name: 'Raumschiff-Kampf', skills: [
      ['strahlGeschuetze', 'Strahl-Geschütze', 'KOO', 'INT'],
      ['ballistikGeschuetze', 'Ballistische Geschütze', 'KOO', 'INT'],
      ['raketen', 'Raketen', 'INT', 'KOO'],
      ['schutzschild', 'Schutzschild', 'INT', 'MEN'],
      ['panzerung', 'Panzerung', 'INT', 'KON'],
      ['notReparatur', 'Not-Reparatur', 'KOO', 'MEN'],
    ] },
    { id: 'sozial', name: 'Handel & Soziales', skills: [
      ['handeln', 'Handeln', 'EMP', 'INT'],
      ['gassenwissen', 'Gassenwissen', 'EMP', 'INT'],
      ['verhandeln', 'Verhandeln', 'EMP', 'MEN'],
    ] },
    { id: 'handwerk', name: 'Handwerk', skills: [
      ['hwRuestung', 'Rüstung', 'KOO', 'INT'],
      ['hwWaffen', 'Waffen', 'KOO', 'INT'],
      ['kochen', 'Kochen', 'EMP', 'KOO'],
      ['medikamente', 'Medikamente herstellen', 'INT', 'KOO'],
    ] },
  ];

  const SKILLS = {};
  for (const g of SKILL_GROUPS) {
    g.skills = g.skills.map(([id, name, a1, a2]) => {
      const s = { id, name, attrs: [a1, a2], group: g.id };
      SKILLS[id] = s;
      return s;
    });
  }

  const DIFFICULTY = {
    routine: { name: 'Routine', mod: 30, xp: 0 },
    leicht: { name: 'Leicht', mod: 20, xp: 1 },
    einfach: { name: 'Einfach', mod: 10, xp: 1 },
    mittel: { name: 'Mittel', mod: 0, xp: 2 },
    schwer: { name: 'Schwer', mod: -10, xp: 3 },
    sehrSchwer: { name: 'Sehr schwer', mod: -20, xp: 4 },
    extrem: { name: 'Extrem schwer', mod: -30, xp: 5 },
    wahnsinnig: { name: 'Wahnsinnig', mod: -50, xp: 7 },
    absurd: { name: 'Absurd', mod: -70, xp: 10 },
  };

  function attrBonus(v) {
    if (v <= 5) return -15;
    if (v <= 15) return -10;
    if (v <= 30) return -5;
    if (v <= 70) return 0;
    if (v <= 80) return 5;
    if (v <= 90) return 10;
    if (v <= 95) return 15;
    if (v <= 98) return 20;
    if (v === 99) return 25;
    return 30;
  }

  function rankBonus(r) {
    if (r <= 0) return -25;
    if (r <= 10) return 5 * r;
    if (r <= 20) return 50 + 2 * (r - 10);
    if (r <= 30) return 70 + (r - 20);
    return 80 + Math.floor((r - 30) / 2);
  }

  function skillRank(ch, id) { return (ch.skills[id] && ch.skills[id].rank) || 0; }

  function skillTotal(ch, id) {
    const s = SKILLS[id];
    return rankBonus(skillRank(ch, id)) + attrBonus(ch.attrs[s.attrs[0]]) + attrBonus(ch.attrs[s.attrs[1]]);
  }

  function rankCost(rank) { return 10 + 2 * rank; }

  function ensureSkill(ch, id) {
    if (!ch.skills[id]) ch.skills[id] = { rank: 0, xp: 0 };
    return ch.skills[id];
  }

  // Erfahrung nur für benutzte Fertigkeiten. Gesammelt wird pro Kampf in ch.xpLog.
  function awardXp(ch, id, amount) {
    if (!amount || amount <= 0 || !ch.isCrew) return;
    ensureSkill(ch, id).xp += amount;
    ch.xpLog = ch.xpLog || {};
    ch.xpLog[id] = (ch.xpLog[id] || 0) + amount;
  }

  function canRankUp(ch, id) { const s = ensureSkill(ch, id); return s.xp >= rankCost(s.rank); }

  function rankUp(ch, id) {
    const s = ensureSkill(ch, id);
    const cost = rankCost(s.rank);
    if (s.xp < cost) return false;
    s.xp -= cost;
    s.rank += 1;
    return true;
  }

  function maneuverResult(total) {
    if (total <= -26) return { id: 'patzer', name: 'Patzer' };
    if (total <= 75) return { id: 'fehlschlag', name: 'Fehlschlag' };
    if (total <= 100) return { id: 'teilerfolg', name: 'Teilerfolg' };
    if (total <= 175) return { id: 'erfolg', name: 'Erfolg' };
    return { id: 'herausragend', name: 'Herausragender Erfolg' };
  }

  // Probe: offener W100 + Gesamtbonus + Schwierigkeit + Modifikatoren
  function maneuver(ch, skillId, diffId, extraMods = []) {
    PTF.Dice.context = `${ch.name}: ${SKILLS[skillId].name}`;
    const diff = DIFFICULTY[diffId];
    const roll = PTF.Dice.openD100();
    const bonus = skillTotal(ch, skillId);
    const mods = [{ label: SKILLS[skillId].name, val: bonus }, { label: diff.name, val: diff.mod }, ...extraMods];
    const total = roll.total + mods.reduce((s, m) => s + m.val, 0);
    const result = maneuverResult(total);
    let xp = 0;
    if (result.id === 'erfolg' || result.id === 'herausragend') xp = diff.xp;
    else if (result.id !== 'patzer') xp = Math.floor(diff.xp / 2);
    awardXp(ch, skillId, xp);
    return { roll, mods, total, result, xp };
  }

  // Abgeleitete Werte
  function maxHp(ch) { return 15 + Math.floor(ch.attrs.KON / 3); }
  function deathAt(ch) { return -Math.floor(ch.attrs.KON / 5); }
  function hasPsi(ch) { return skillRank(ch, 'psiAngriff') > 0 || skillRank(ch, 'psiWirken') > 0; }
  function maxPp(ch) { return hasPsi(ch) ? Math.floor(ch.attrs.MEN / 10) + Math.floor(skillRank(ch, 'psiWirken') / 2) : 0; }
  function movePoints(ch) {
    const armor = PTF.ARMOR[ch.armor];
    return Math.max(2, 4 + Math.floor(attrBonus(ch.attrs.GEW) / 5) + (armor.move || 0));
  }
  function initiativeBonus(ch) { return attrBonus(ch.attrs.GEW) + Math.floor(skillTotal(ch, 'kampfsinn') / 5); }

  PTF.ATTRIBUTES = ATTRIBUTES;
  PTF.SKILL_GROUPS = SKILL_GROUPS;
  PTF.SKILLS = SKILLS;
  PTF.DIFFICULTY = DIFFICULTY;
  PTF.Rules = {
    attrBonus, rankBonus, skillRank, skillTotal, rankCost, ensureSkill, awardXp, canRankUp, rankUp,
    maneuver, maneuverResult, maxHp, deathAt, maxPp, hasPsi, movePoints, initiativeBonus,
  };
})(window.PTF = window.PTF || {});
