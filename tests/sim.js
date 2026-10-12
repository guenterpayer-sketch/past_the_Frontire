// Headless-Test: lädt die Spiel-Skripte in Node und lässt KI gegen KI kämpfen.
// Aufruf: node tests/sim.js [Anzahl Kämpfe]
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

globalThis.window = globalThis;
for (const f of ['dice', 'rules', 'tables', 'hex', 'map', 'units', 'combat', 'ai']) {
  vm.runInThisContext(fs.readFileSync(path.join(__dirname, '..', 'js', f + '.js'), 'utf8'), { filename: f + '.js' });
}
const PTF = globalThis.PTF;
const assert = require('assert');

// --- Regel-Checks ---
assert.strictEqual(PTF.Rules.rankBonus(0), -25);
assert.strictEqual(PTF.Rules.rankBonus(10), 50);
assert.strictEqual(PTF.Rules.rankBonus(20), 70);
assert.strictEqual(PTF.Rules.rankBonus(30), 80);
assert.strictEqual(PTF.Rules.attrBonus(50), 0);
assert.strictEqual(PTF.Rules.attrBonus(100), 30);
assert.deepStrictEqual(PTF.Tables.lookupAttack('projektil', 79, 2, 1), { hit: false, threshold: 80 });
// Projektil gegen Mittel: Schwelle 80, Kritische ab 120, je 15 Punkte ein Grad
assert.strictEqual(PTF.Tables.lookupAttack('projektil', 119, 2, 1).severity, null);
assert.strictEqual(PTF.Tables.lookupAttack('projektil', 120, 2, 1).severity, 'A');
assert.strictEqual(PTF.Tables.lookupAttack('projektil', 135, 2, 1).severity, 'B');
assert.strictEqual(PTF.Tables.lookupAttack('projektil', 180, 2, 1).severity, 'E');
assert.strictEqual(PTF.Tables.lookupAttack('projektil', 80, 2, 1).dmg, 2);

// Offener Wurf: Verteilung grob prüfen
PTF.Dice.setSeed(1);
let hi = 0, lo = 0, n = 200000;
for (let i = 0; i < n; i++) { const r = PTF.Dice.openD100(); if (r.total > 100) hi++; if (r.total < 1) lo++; }
console.log(`Offener W100: >100 in ${(hi / n * 100).toFixed(2)}%, <1 in ${(lo / n * 100).toFixed(2)}% (erwartet je ~5%)`);

// --- Kämpfe ---
// Deckungsregeln an einer Mini-Karte prüfen: Ziel bei (2,0), Angreifer weit rechts
{
  const m = new PTF.BattleMap(10, 1);
  for (let q = 0; q < 10; q++) m.add({ q, r: 0, col: q, row: 0, h: 0, terrain: 'boden' });
  const T = q => m.get(q, 0);
  T(3).terrain = 'barriere';
  assert.strictEqual(m.cover(T(2), T(8)).level, 1, 'Barriere = halbe Deckung');
  assert.strictEqual(m.cover(T(2), T(8)).bonus, 30);
  T(3).terrain = 'boden'; T(4).terrain = 'barriere';
  assert.strictEqual(m.cover(T(2), T(8)).level, 1, 'Barriere 2 Felder vor dem Ziel zählt auch');
  assert.strictEqual(m.cover(T(2), T(5)), null, 'bei nur 3 Feldern Abstand zählt nur das Nachbarfeld');
  T(4).terrain = 'boden'; T(3).terrain = 'barriere';
  assert.ok(m.lineOfSight(T(8), T(2)).visible, 'über halbe Deckung hinweg schießen');
  T(3).terrain = 'container'; T(3).h = 2;
  assert.strictEqual(m.cover(T(2), T(8)).level, 2, 'Container = volle Deckung');
  m.losCache.clear();
  assert.ok(!m.lineOfSight(T(8), T(2)).visible, 'in einer Reihe kein Herausschauen möglich');
  T(8).h = 3; m.losCache.clear();
  assert.strictEqual(m.cover(T(2), T(8)).level, 1, 'von oben: volle wird zu halber Deckung');
}

// Blickrichtung: Ziel schaut nach Osten (Richtung 0)
{
  const H = PTF.Hex, o = { q: 0, r: 0 };
  assert.strictEqual(H.sector(o, 0, { q: 3, r: 0 }), 'vorne');
  assert.strictEqual(H.sector(o, 0, { q: 0, r: 3 }), 'vorne', 'Südost liegt 60° neben Osten');
  assert.strictEqual(H.sector(o, 0, { q: -3, r: 3 }), 'flanke', 'Südwest liegt 120° neben Osten');
  assert.strictEqual(H.sector(o, 0, { q: -3, r: 0 }), 'ruecken');
  for (let d = 0; d < 6; d++) {
    const [dq, dr] = [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]][d];
    assert.strictEqual(H.dirToward(o, { q: dq, r: dr }), d, 'dirToward ' + d);
  }
  const m = PTF.COMBAT.activityMod;
  assert.deepStrictEqual([20, 50, 60, 70, 100].map(m), [-40, -10, 0, 5, 20]);
}

// Abwarten und Einspringen, Ducken
{
  PTF.Dice.setSeed(7);
  const c = new PTF.Combat(PTF.generateMap(4711, 'mittel'), PTF.CREW_TEMPLATE, PTF.ENEMY_TEMPLATE, () => {});
  c.start();
  const first = c.current, second = c.order[c.turnIdx + 1];
  assert.ok(c.doWait(first), 'Abwarten möglich');
  assert.strictEqual(c.current, second, 'nach dem Abwarten ist der Nächste dran');
  assert.strictEqual(c.order[c.order.length - 1], first, 'Wartender steht am Ende');
  assert.ok(c.requestJump(first));
  c.endTurn();
  assert.strictEqual(c.current, first, 'Einsprung direkt nach dem laufenden Zug');
  assert.strictEqual(first.act, 90, 'Abwarten kostet 10 %');
  assert.ok(!c.canWait(first), 'nur einmal pro Runde');
  const g = PTF.COMBAT;
  const budget = c.moveBudget(first, 'gehen');
  assert.ok(c.doCrouch(first) && first.crouched && first.act === 80);
  assert.strictEqual(c.moveBudget(first, 'gehen'), Math.floor(8 * 0.5), 'geduckt: 1 Hex je 20 %, keine Gratis-Felder');
  assert.ok(!c.canMove(first, 'laufen'), 'geduckt nicht laufen');
  assert.ok(budget > c.moveBudget(first, 'gehen'));
}

// Gestoppte Bewegung kostet nur den gelaufenen Teil
{
  const m = new PTF.BattleMap(12, 1);
  for (let q = 0; q < 12; q++) m.add({ q, r: 0, col: q, row: 0, h: 0, terrain: 'boden' });
  m.crewStart = [m.get(0, 0), m.get(1, 0), m.get(2, 0), m.get(3, 0), m.get(4, 0), m.get(5, 0)];
  m.enemyStart = [m.get(11, 0), m.get(10, 0), m.get(9, 0), m.get(8, 0), m.get(7, 0), m.get(6, 0)];
  const c = new PTF.Combat(m, PTF.CREW_TEMPLATE.slice(0, 1), PTF.ENEMY_TEMPLATE.slice(0, 1), () => {});
  c.start();
  const [a, e] = [c.crew()[0], c.enemies()[0]];
  e.pos = { q: 11, r: 0 }; a.pos = { q: 0, r: 0 }; a.freeHex = 0;
  if (c.current !== a) { c.order = [a, e]; c.turnIdx = 0; c.beginTurn(a); a.freeHex = 0; }
  // Gegner in Feuerbereitschaft; der Schuss legt die Figur garantiert um
  e.overwatch = { wid: 'sturmgewehr', pct: 100 }; e.facing = 3;
  const orig = c.resolveAttack;
  c.resolveAttack = function (att, tgt, info, tag) { tgt.hp = -1; this.checkState(tgt); };
  c.doMove(a, m.get(6, 0), 'gehen');
  c.resolveAttack = orig;
  assert.strictEqual(a.pos.q, 1, 'nach dem ersten Feld gestoppt');
  assert.strictEqual(a.act, 90, 'nur 1 Feld (10 %) bezahlt statt 6 Felder');
}

// Weg durch eine eigene Figur: Ziel direkt dahinter muss erreicht werden (früher: Kosten weg, Figur blieb stehen)
{
  const m = new PTF.BattleMap(8, 1);
  for (let q = 0; q < 8; q++) m.add({ q, r: 0, col: q, row: 0, h: 0, terrain: 'boden' });
  m.crewStart = [0, 1, 2, 3, 4, 5].map(q => m.get(q, 0));
  m.enemyStart = [7, 6, 5, 4, 3, 2].map(q => m.get(q, 0));
  const c = new PTF.Combat(m, PTF.CREW_TEMPLATE.slice(0, 2), PTF.ENEMY_TEMPLATE.slice(0, 1), () => {});
  c.start();
  const [a, b] = c.crew();
  a.pos = { q: 0, r: 0 }; b.pos = { q: 1, r: 0 }; c.enemies()[0].pos = { q: 7, r: 0 };
  c.order = [a, b, c.enemies()[0]]; c.turnIdx = 0; c.beginTurn(a);
  const reach = c.moveRange(a, 'gehen');
  assert.ok(!reach.has('1,0'), 'Feld der eigenen Figur ist kein Ziel');
  assert.ok(reach.has('2,0'), 'Feld dahinter ist erreichbar');
  assert.deepStrictEqual(m.pathTo(reach, m.get(2, 0)).map(t => t.q), [0, 1, 2], 'Weg führt durch die eigene Figur');
  const act = a.act;
  assert.ok(c.doMove(a, m.get(2, 0), 'gehen'));
  assert.strictEqual(a.pos.q, 2, 'Figur ist angekommen');
  assert.ok(a.act <= act);
}

const fights = Number(process.argv[2] || 200);
const stats = { sieg: 0, niederlage: 0, rounds: [], stuck: 0, crewDead: 0, crewKo: 0 };
const t0 = Date.now();
for (let i = 0; i < fights; i++) {
  PTF.Dice.setSeed(1000 + i);
  const map = PTF.generateMap(5000 + i, PTF.MAP_SIZES[i % 3].id);
  const c = new PTF.Combat(map, PTF.CREW_TEMPLATE, PTF.ENEMY_TEMPLATE, () => {});
  c.start();
  let steps = 0;
  while (!c.result && steps < 5000) {
    const u = c.current;
    const step = PTF.AI.planStep(c, u);
    if (step.type === 'end' || !PTF.AI.execute(c, u, step)) c.endTurn();
    steps++;
    if (c.round > 60) break;
  }
  if (!c.result) { stats.stuck++; continue; }
  stats[c.result]++;
  stats.rounds.push(c.round);
  for (const u of c.crew()) { if (u.state === 'dead') stats.crewDead++; if (u.state === 'ko') stats.crewKo++; }
  if (i === 0) {
    const xp = c.crew().map(u => `${u.name}: ${JSON.stringify(u.xpLog)}`).join('\n  ');
    console.log('Beispiel-EP nach Kampf 1:\n  ' + xp);
  }
}
const avg = stats.rounds.reduce((a, b) => a + b, 0) / Math.max(1, stats.rounds.length);
console.log(`Kämpfe: ${fights} | Crew-Siege: ${stats.sieg} | Niederlagen: ${stats.niederlage} | hängengeblieben: ${stats.stuck}`);
console.log(`Laufzeit: ${((Date.now() - t0) / fights).toFixed(0)} ms pro Kampf`);
console.log(`Ø Runden: ${avg.toFixed(1)} | Ø tote Crew: ${(stats.crewDead / fights).toFixed(2)} | Ø bewusstlose Crew: ${(stats.crewKo / fights).toFixed(2)}`);
assert.strictEqual(stats.stuck, 0, 'Kämpfe ohne Ende');
console.log('OK');
