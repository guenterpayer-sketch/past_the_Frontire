// Einfache Gegner-KI für das Aktivitätssystem: sucht Positionen mit guter Trefferchance, Deckung und Höhe.
// Liefert pro Aufruf genau eine nächste Handlung.
(function (PTF) {
  'use strict';
  const { Hex, WEAPONS } = PTF;
  const { MIN_ATTACK, MIN_OVERWATCH, GAITS } = PTF.COMBAT;

  // bester Angriff von einem Feld aus; avail = für den Angriff verfügbare Aktivität
  function bestAttack(c, u, from, weapons, avail, extraMod = 0) {
    let best = null;
    for (const wid of weapons) {
      const pct = Math.min(100, avail - (wid !== u.weapon ? 10 : 0));
      if (pct < MIN_ATTACK) continue;
      for (const t of c.opponents(u)) {
        const info = c.attackInfo(u, t, wid, { from, pct });
        if (!info.valid) continue;
        const chance = Math.max(0, Math.min(100, info.chance + extraMod));
        if (chance <= 0) continue;
        let score = chance;
        if (t.hp <= 10) score += 15;
        if (WEAPONS[wid].splash) {
          // Rakete nur, wenn mehrere Gegner nah beieinander stehen und keine eigenen Leute
          let others = 0, friends = 0;
          for (const v of c.units) {
            if (v === t || v.state !== 'ok' || Hex.distance(v.pos, t.pos) > WEAPONS[wid].splash.length) continue;
            v.team === u.team ? friends++ : others++;
          }
          if (friends) continue;
          score += others * 30 - 10;
        }
        if (WEAPONS[wid].psi) score += 5;
        if (!best || score > best.score) best = { score, target: t, wid, pct, info };
      }
    }
    return best;
  }

  // Wie sicher ist ein Feld: Anteil der sichtbaren Gegner, gegen die man Deckung hat
  function safety(c, u, tile) {
    let seen = 0, covered = 0;
    for (const e of c.opponents(u)) {
      const et = c.tileOf(e);
      if (Hex.distance(et, tile) > 30) continue;
      seen++;
      if (!c.map.lineOfSight(et, tile).visible) { covered++; continue; }
      const cov = c.map.cover(tile, et);
      if (cov) covered += cov.level / 2;
    }
    return seen ? covered / seen : 1;
  }

  // Wegkosten von jedem Feld zum nächsten Gegner (Dijkstra von allen Gegnern aus, Einheiten ignoriert)
  function approachField(c, u) {
    const m = c.map, best = new Map(), open = [];
    for (const e of c.opponents(u)) { const t = c.tileOf(e); best.set(Hex.key(t.q, t.r), 0); open.push({ t, cost: 0 }); }
    while (open.length) {
      let bi = 0;
      for (let i = 1; i < open.length; i++) if (open[i].cost < open[bi].cost) bi = i;
      const cur = open.splice(bi, 1)[0];
      if (cur.cost > best.get(Hex.key(cur.t.q, cur.t.r))) continue;
      for (const n of Hex.neighbors(cur.t.q, cur.t.r)) {
        const nt = m.get(n.q, n.r);
        if (!nt) continue;
        const cost = cur.cost + m.stepCost(nt, cur.t);
        const k = Hex.key(nt.q, nt.r);
        if (isFinite(cost) && cost < (best.has(k) ? best.get(k) : Infinity)) { best.set(k, cost); open.push({ t: nt, cost }); }
      }
    }
    return t => { const v = best.get(Hex.key(t.q, t.r)); return v === undefined ? 99 : v; };
  }

  // Am Zugende zum nächsten (möglichst sichtbaren) Gegner drehen
  function faceStep(c, u) {
    const here = c.tileOf(u);
    let best = null;
    for (const e of c.opponents(u)) {
      const d = Hex.distance(e.pos, u.pos) - (c.map.lineOfSight(here, c.tileOf(e)).visible ? 100 : 0);
      if (!best || d < best.d) best = { d, e };
    }
    if (!best) return { type: 'end' };
    return { type: 'face', dir: Hex.dirToward(u.pos, best.e.pos) };
  }

  // Erste Hilfe: benachbart sofort, sonst hinlaufen, wenn danach noch 50 % übrig sind
  function firstAidStep(c, u, avail) {
    const cost = PTF.COMBAT.COST.aid;
    if (avail < cost || (PTF.Rules.skillRank(u, 'ersteHilfe') < 1 && !(u.medkit > 0))) return null;
    const needs = c.units.filter(o => o !== u && o.team === u.team && o.state !== 'dead' && (o.state === 'ko' || o.bleed >= 2));
    if (!needs.length) return null;
    const near = c.firstAidTargets(u).filter(o => needs.includes(o));
    if (near.length) return { type: 'aid', target: near.sort((a, b) => (a.state === 'ko' ? -1 : 0) - (b.state === 'ko' ? -1 : 0))[0] };
    if (u._moved || !c.canMove(u, 'gehen')) return null;
    let best = null;
    for (const { tile, cost: mc } of c.moveRange(u, 'gehen', avail - cost).values()) {
      if (avail - c.movePct(u, 'gehen', mc) < cost) continue;
      for (const o of needs) {
        if (Hex.distance(tile, o.pos) !== 1) continue;
        const score = (o.state === 'ko' ? 20 : 0) + safety(c, u, tile) * 10 - mc;
        if (!best || score > best.score) best = { score, tile };
      }
    }
    return best ? { type: 'move', tile: best.tile, gait: 'gehen' } : null;
  }

  function planStep(c, u) {
    if (c.current !== u || c.result || u.state !== 'ok') return { type: 'end' };
    const stamp = c.round + ':' + c.turnIdx;
    if (u._stamp !== stamp) { u._stamp = stamp; u._moved = false; u._faced = false; u._standCheck = false; }
    const finish = () => (u._faced ? { type: 'end' } : faceStep(c, u));
    if (u.stunnedNow) return finish();

    const here = c.tileOf(u);
    const weapons = c.usableWeapons(u);
    const avail = Math.floor(u.act / 10) * 10;

    const melee = WEAPONS[u.weapons[0]].melee;

    // Erste Hilfe für bewusstlose oder stark blutende Kameraden
    const aid = firstAidStep(c, u, avail);
    if (aid) return aid;

    // geduckt zu Zugbeginn: aufstehen, außer es gibt von hier einen guten Schuss
    if (u.crouched && !u._standCheck) {
      u._standCheck = true;
      const h = c.canAttack(u) ? bestAttack(c, u, here, weapons, avail) : null;
      if ((!h || h.info.chance < 40 || melee) && c.canCrouch(u)) return { type: 'crouch' };
    }

    // Nachladen, wenn der Angriff schon erledigt ist oder genug Aktivität für Laden + Angriff bleibt
    const rl = c.reloadable(u);
    if (rl.length && u.act >= 30 && (u.hasAttacked || u.act >= 90)) return { type: 'reload', wid: rl[0] };

    if (c.canAttack(u) && weapons.length) {
      const options = [];
      const h = bestAttack(c, u, here, weapons, avail);
      if (h) options.push({ ...h, tile: here, score: h.score + safety(c, u, here) * 60 + here.h * 3 });
      if (!u._moved) {
        for (const gait of melee ? ['gehen', 'laufen'] : ['gehen']) {
          if (!c.canMove(u, gait)) continue;
          const runMod = GAITS[gait].attackMod || 0;
          for (const { tile, cost } of c.moveRange(u, gait, avail - MIN_ATTACK).values()) {
            if (tile === here) continue;
            const left = avail - c.movePct(u, gait, cost);
            if (left < MIN_ATTACK) continue;
            const a = bestAttack(c, u, tile, melee ? [u.weapons[0]].filter(w => weapons.includes(w)) : weapons, left, runMod);
            if (a) options.push({ ...a, tile, gait, score: a.score + safety(c, u, tile) * 60 + tile.h * 3 - cost * 0.2 });
          }
        }
      }
      options.sort((a, b) => b.score - a.score);
      const best = options[0];
      if (best && best.tile === here) {
        // vor dem Schuss ducken: +10 AW und +15 VW, kostet 10 %
        if (!melee && !u.crouched && !WEAPONS[best.wid].melee && c.canCrouch(u) && avail - 10 >= MIN_ATTACK + 20) return { type: 'crouch' };
        return { type: 'attack', target: best.target, wid: best.wid, pct: best.pct };
      }
      if (best) return { type: 'move', tile: best.tile, gait: best.gait };
    }

    // kein Angriff möglich: vorrücken (Nahkämpfer sprinten), danach Feuerbereitschaft
    if (!u._moved) {
      const dist = approachField(c, u);
      const gait = melee && !u.hasAttacked ? 'sprinten' : 'laufen';
      const limit = melee ? avail : avail - MIN_OVERWATCH;
      if (c.canMove(u, gait) && limit >= 0) {
        let best = null;
        for (const { tile, cost } of c.moveRange(u, gait, limit).values()) {
          const score = -dist(tile) * 4 + safety(c, u, tile) * 10 + tile.h - cost * 0.1;
          if (!best || score > best.score) best = { score, tile };
        }
        if (best && best.tile !== here && dist(best.tile) < dist(here) + 1) return { type: 'move', tile: best.tile, gait };
      }
    }
    const ranged = weapons.filter(w => !WEAPONS[w].melee);
    // vor Feuerbereitschaft oder Zugende ducken (schwerer zu treffen)
    if (!melee && !u.crouched && c.canCrouch(u) && u.act >= 10 + MIN_OVERWATCH) return { type: 'crouch' };
    if (ranged.length && c.canOverwatch(u, ranged[0])) return { type: 'overwatch', wid: ranged[0] };
    if (!melee && !u.crouched && c.canCrouch(u)) return { type: 'crouch' };
    return finish();
  }

  function execute(c, u, step) {
    switch (step.type) {
      case 'move': { const ok = c.doMove(u, step.tile, step.gait || 'gehen'); if (ok) u._moved = true; return ok; }
      case 'attack': return c.doAttack(u, step.target, step.wid, step.pct);
      case 'overwatch': return c.doOverwatch(u, step.wid);
      case 'reload': return c.doReload(u, step.wid);
      case 'crouch': return c.doCrouch(u);
      case 'aid': return c.doFirstAid(u, step.target);
      case 'face': u._faced = true; return c.doFace(u, step.dir);
      default: return false;
    }
  }

  PTF.AI = { planStep, execute };
})(window.PTF = window.PTF || {});
