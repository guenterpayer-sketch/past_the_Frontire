// Einfache Gegner-KI: sucht Positionen mit guter Trefferchance, Deckung und Höhe.
// Liefert pro Aufruf genau eine nächste Aktion.
(function (PTF) {
  'use strict';
  const { Hex, WEAPONS, TERRAIN } = PTF;

  function bestAttack(c, u, from, weapons) {
    let best = null;
    for (const t of c.opponents(u)) {
      for (const wid of weapons) {
        const info = c.attackInfo(u, t, wid, from);
        if (!info.valid || info.chance <= 0) continue;
        let score = info.chance;
        if (t.hp <= 10) score += 15;
        if (WEAPONS[wid].splash) {
          // Rakete nur, wenn mehrere Gegner nah beieinander stehen und keine eigenen Leute
          let others = 0, friends = 0;
          for (const n of Hex.neighbors(t.pos.q, t.pos.r)) {
            const v = c.unitAt(n.q, n.r);
            if (v && v.state === 'ok') v.team === u.team ? friends++ : others++;
          }
          if (friends) continue;
          score += others * 30 - 10;
        }
        if (WEAPONS[wid].psi) score += 5;
        if (!best || score > best.score) best = { score, target: t, wid, info };
      }
    }
    return best;
  }

  // Wie sicher ist ein Feld: Anteil der sichtbaren Gegner, gegen die man Deckung hat
  function safety(c, u, tile) {
    let seen = 0, covered = 0;
    for (const e of c.opponents(u)) {
      const et = c.tileOf(e);
      if (Hex.distance(et, tile) > 14) continue;
      if (!c.map.lineOfSight(et, tile).visible) { covered++; seen++; continue; }
      seen++;
      if (c.map.cover(tile, et) || TERRAIN[tile.terrain].forest) covered++;
    }
    return seen ? covered / seen : 1;
  }

  // Wegkosten von jedem Feld zum nächsten Gegner (Dijkstra von allen Gegnern aus, Einheiten ignoriert)
  function approachField(c, u) {
    const m = c.map, best = new Map(), open = [];
    for (const e of c.opponents(u)) { const t = c.tileOf(e); best.set(Hex.key(t.q, t.r), 0); open.push({ t, cost: 0 }); }
    while (open.length) {
      open.sort((a, b) => a.cost - b.cost);
      const cur = open.shift();
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

  function planStep(c, u) {
    if (u.actions <= 0) return { type: 'end' };
    const here = c.tileOf(u);
    const weapons = c.usableWeapons(u);
    const melee = WEAPONS[weapons[0]] && WEAPONS[weapons[0]].melee;

    if (u.hasAttacked || u.stunnedNow) return { type: 'defend' };

    const dist = approachField(c, u);
    if (melee) {
      const now = bestAttack(c, u, here, [weapons[0]]);
      if (now) return { type: 'attack', target: now.target, wid: now.wid };
      const reach = c.moveRange(u);
      let best = null;
      for (const { tile, cost } of reach.values()) {
        const hit = u.actions >= 2 ? bestAttack(c, u, tile, [weapons[0]]) : null;
        const score = hit ? 1000 + hit.score + tile.h * 5 - cost : -dist(tile) * 10 + safety(c, u, tile) * 8 - cost * 0.1;
        if (!best || score > best.score) best = { score, tile };
      }
      if (best && best.score >= 1000) return { type: 'move', tile: best.tile };
      // Nahkampf nicht erreichbar: mit Zweitwaffe schießen, sonst annähern
      const ranged = weapons.filter(w => !WEAPONS[w].melee);
      const shot = ranged.length ? bestAttack(c, u, here, ranged) : null;
      if (shot && shot.info.chance >= 25) return { type: 'attack', target: shot.target, wid: shot.wid };
      if (best && best.tile !== here) return { type: 'move', tile: best.tile };
      return shot ? { type: 'attack', target: shot.target, wid: shot.wid } : { type: 'defend' };
    }

    const now = bestAttack(c, u, here, weapons);
    if (u.actions === 1) {
      if (now) return { type: 'attack', target: now.target, wid: now.wid };
      // kein Ziel: weiter annähern, solange es Gegner gibt, die außer Sicht sind
      let best = null;
      for (const { tile, cost } of c.moveRange(u).values()) {
        const score = -dist(tile) * 4 + safety(c, u, tile) * 10 + tile.h - cost * 0.2;
        if (!best || score > best.score) best = { score, tile };
      }
      return best && best.tile !== here ? { type: 'move', tile: best.tile } : { type: 'defend' };
    }

    // 2 Aktionen: entweder bewegen + schießen oder zielen + schießen
    const reach = c.moveRange(u);
    let bestTile = null;
    for (const { tile, cost } of reach.values()) {
      const a = bestAttack(c, u, tile, weapons);
      const score = (a ? a.score : -50 - dist(tile) * 5) + safety(c, u, tile) * 25 + tile.h * 3 - cost * 0.2;
      if (!bestTile || score > bestTile.score) bestTile = { score, tile, a };
    }
    const hereScore = now ? now.score + 15 + safety(c, u, here) * 25 + here.h * 3 : -Infinity; // +15: Zielen
    if (now && hereScore >= bestTile.score) {
      return u.aim || now.info.chance >= 95 ? { type: 'attack', target: now.target, wid: now.wid } : { type: 'aim' };
    }
    if (bestTile && bestTile.tile !== here) return { type: 'move', tile: bestTile.tile };
    return now ? { type: 'attack', target: now.target, wid: now.wid } : { type: 'defend' };
  }

  function execute(c, u, step) {
    switch (step.type) {
      case 'move': return c.doMove(u, step.tile);
      case 'attack': return c.doAttack(u, step.target, step.wid);
      case 'aim': return c.doAim(u);
      case 'defend': return c.doDefend(u);
      default: return false;
    }
  }

  PTF.AI = { planStep, execute };
})(window.PTF = window.PTF || {});
