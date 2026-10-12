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
assert.strictEqual(PTF.Tables.lookupAttack('projektil', 110, 2, 1).severity, 'A');
assert.strictEqual(PTF.Tables.lookupAttack('projektil', 150, 2, 1).severity, 'E');
assert.strictEqual(PTF.Tables.lookupAttack('projektil', 109, 2, 1).severity, null);

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
  assert.ok(m.lineOfSight(T(8), T(2)).visible, 'über halbe Deckung hinweg schießen');
  T(3).terrain = 'container'; T(3).h = 2;
  assert.strictEqual(m.cover(T(2), T(8)).level, 2, 'Container = volle Deckung');
  m.losCache.clear();
  assert.ok(!m.lineOfSight(T(8), T(2)).visible, 'in einer Reihe kein Herausschauen möglich');
  T(8).h = 3; m.losCache.clear();
  assert.strictEqual(m.cover(T(2), T(8)).level, 1, 'von oben: volle wird zu halber Deckung');
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
    else if (!c.result && c.current === u && u.actions <= 0) c.endTurn();
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
