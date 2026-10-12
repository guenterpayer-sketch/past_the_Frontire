// Gelände, Kartengenerator, Sichtlinie, Deckung, Wegfindung.
(function (PTF) {
  'use strict';
  const Hex = PTF.Hex;

  const TERRAIN = {
    ebene: { name: 'Staubebene', cost: 1, top: '#c8b48a', side: '#8d7a56' },
    geroell: { name: 'Geröll', cost: 2, top: '#a8a093', side: '#6f685d' },
    wald: { name: 'Kristallflora', cost: 2, top: '#5a9a7a', side: '#3b6650', forest: true },
    wasser: { name: 'Seichtes Wasser', cost: 3, top: '#5a8fbf', side: '#3c6185', water: true },
    ruine: { name: 'Ruinenmauer', cost: Infinity, top: '#9a96a6', side: '#615e6d', obstacle: 'low' },
    fels: { name: 'Felsnadel', cost: Infinity, top: '#7d6f63', side: '#4f463e', obstacle: 'high' },
  };
  const MAX_H = 4;
  const EYE = 1.2, AIM = 0.9; // Augenhöhe Schütze, Zielhöhe auf dem Ziel (in Höhenstufen)
  const ROCK_H = 2.2; // Felsnadel ragt so weit über ihr Feld

  class BattleMap {
    constructor(cols, rows) {
      this.cols = cols;
      this.rows = rows;
      this.tiles = new Map();
      this.list = [];
    }
    get(q, r) { return this.tiles.get(Hex.key(q, r)); }
    at(pos) { return pos && this.tiles.get(Hex.key(pos.q, pos.r)); }
    add(t) { this.tiles.set(Hex.key(t.q, t.r), t); this.list.push(t); }

    // Bewegungskosten von Feld a nach Nachbarfeld b
    stepCost(a, b) {
      const T = TERRAIN[b.terrain];
      if (!isFinite(T.cost)) return Infinity;
      const dh = b.h - a.h;
      if (dh >= 3 || dh <= -3) return Infinity;
      return T.cost + (dh === 1 ? 1 : dh === 2 ? 3 : 0);
    }

    // Dijkstra. blocked(tile) → true: nicht betretbar; passOnly(tile) → true: darf durchquert, aber nicht betreten werden
    reachable(start, mp, blocked, passOnly) {
      const startT = this.at(start);
      const best = new Map([[Hex.key(start.q, start.r), { cost: 0, prev: null, tile: startT }]]);
      const open = [{ tile: startT, cost: 0 }];
      while (open.length) {
        open.sort((x, y) => x.cost - y.cost);
        const cur = open.shift();
        if (cur.cost > best.get(Hex.key(cur.tile.q, cur.tile.r)).cost) continue;
        for (const n of Hex.neighbors(cur.tile.q, cur.tile.r)) {
          const nt = this.get(n.q, n.r);
          if (!nt || (blocked && blocked(nt))) continue;
          const c = cur.cost + this.stepCost(cur.tile, nt);
          if (c > mp) continue;
          const k = Hex.key(nt.q, nt.r);
          const prev = best.get(k);
          if (!prev || c < prev.cost) {
            best.set(k, { cost: c, prev: cur.tile, tile: nt });
            open.push({ tile: nt, cost: c });
          }
        }
      }
      if (passOnly) for (const [k, v] of best) if (passOnly(v.tile)) best.delete(k);
      return best;
    }

    pathTo(reach, tile) {
      const path = [];
      let k = Hex.key(tile.q, tile.r);
      while (reach.has(k)) {
        const e = reach.get(k);
        path.unshift(e.tile);
        if (!e.prev) break;
        k = Hex.key(e.prev.q, e.prev.r);
      }
      return path;
    }

    // Sichtlinie: prüft beide leicht verschobenen Linien, die bessere zählt.
    lineOfSight(a, b) {
      const r1 = this._los(a, b, 1), r2 = this._los(a, b, -1);
      if (r1.visible && r2.visible) return r1.wood <= r2.wood ? r1 : r2;
      return r1.visible ? r1 : r2;
    }
    _los(a, b, nudge) {
      const line = Hex.line(a, b, nudge);
      const n = line.length - 1;
      const h0 = a.h + EYE, h1 = b.h + AIM;
      let wood = 0;
      for (let i = 1; i < n; i++) {
        const x = this.get(line[i].q, line[i].r);
        if (!x) continue;
        const lh = h0 + (h1 - h0) * (i / n);
        const T = TERRAIN[x.terrain];
        if (x.h > lh) return { visible: false, reason: 'Gelände' };
        if (T.obstacle === 'high' && x.h + ROCK_H > lh) return { visible: false, reason: 'Felsnadel' };
        if (T.forest && x.h + 1 > lh) wood++;
      }
      if (wood >= 2) return { visible: false, reason: 'Kristallflora' };
      return { visible: true, wood };
    }

    // Deckung des Ziels gegen einen Angreifer: Mauer, Felsnadel oder Geländekante
    // im Nachbarfeld des Ziels, das zum Angreifer zeigt.
    cover(target, attacker) {
      if (Hex.distance(target, attacker) <= 1) return null;
      let best = null;
      for (const nudge of [1, -1]) {
        const step = Hex.line(target, attacker, nudge)[1];
        const n = this.get(step.q, step.r);
        if (!n) continue;
        const T = TERRAIN[n.terrain];
        let c = null;
        if (T.obstacle === 'low' && attacker.h < n.h + 2) c = 'Ruinenmauer';
        else if (T.obstacle === 'high') c = 'Felsnadel';
        else if (n.h >= target.h + 1 && attacker.h <= n.h + 1) c = 'Geländekante';
        if (c) best = c;
      }
      return best;
    }
  }

  // Wertrauschen: grobes Zufallsgitter, bilinear interpoliert
  function valueNoise(rng, cols, rows, cell) {
    const gw = Math.ceil(cols / cell) + 2, gh = Math.ceil(rows / cell) + 2;
    const g = Array.from({ length: gw * gh }, () => rng());
    return (x, y) => {
      const fx = x / cell, fy = y / cell;
      const ix = Math.floor(fx), iy = Math.floor(fy);
      const tx = fx - ix, ty = fy - iy;
      const sx = tx * tx * (3 - 2 * tx), sy = ty * ty * (3 - 2 * ty);
      const v = (i, j) => g[(iy + j) * gw + (ix + i)];
      const a = v(0, 0) + (v(1, 0) - v(0, 0)) * sx;
      const b = v(0, 1) + (v(1, 1) - v(0, 1)) * sx;
      return a + (b - a) * sy;
    };
  }

  function generate(seed, cols = 16, rows = 12) {
    for (let attempt = 0; attempt < 50; attempt++) {
      const m = tryGenerate(seed + attempt * 7919, cols, rows);
      if (m) { m.seed = seed + attempt * 7919; return m; }
    }
    throw new Error('Keine begehbare Karte gefunden');
  }

  function tryGenerate(seed, cols, rows) {
    const rng = PTF.makeRng(seed);
    const hN1 = valueNoise(rng, cols, rows, 5), hN2 = valueNoise(rng, cols, rows, 2.5);
    const fN = valueNoise(rng, cols, rows, 3);
    const m = new BattleMap(cols, rows);
    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const { q, r } = Hex.fromOffset(col, row);
        const n = hN1(col, row) * 0.75 + hN2(col, row) * 0.25;
        let h = Math.max(0, Math.min(MAX_H, Math.floor((n - 0.2) * 7)));
        let terrain = 'ebene';
        if (n < 0.3) { terrain = 'wasser'; h = 0; }
        else if (fN(col, row) > 0.66) terrain = 'wald';
        else if (rng() < 0.08) terrain = 'geroell';
        else if (h >= 2 && rng() < 0.07) terrain = 'fels';
        m.add({ q, r, col, row, h, terrain });
      }
    }
    // Ruinen: kurze Mauerzüge im Mittelfeld
    const walls = 4 + Math.floor(rng() * 3);
    for (let i = 0; i < walls; i++) {
      const col = 3 + Math.floor(rng() * (cols - 6)), row = 1 + Math.floor(rng() * (rows - 2));
      let { q, r } = Hex.fromOffset(col, row);
      const [dq, dr] = [[1, 0], [0, 1], [1, -1], [-1, 1]][Math.floor(rng() * 4)];
      const len = 2 + Math.floor(rng() * 2);
      for (let j = 0; j < len; j++) {
        const t = m.get(q + dq * j, r + dr * j);
        if (t && t.terrain !== 'wasser') t.terrain = 'ruine';
      }
    }
    // Startzonen freiräumen
    for (const t of m.list) {
      if (t.col <= 1 || t.col >= cols - 2) {
        if (TERRAIN[t.terrain].obstacle || t.terrain === 'wasser') { t.terrain = 'ebene'; t.h = Math.max(t.h, 0); }
      }
    }
    // Erreichbarkeit: jede Startzone muss die andere erreichen
    const from = m.list.find(t => t.col === 0 && t.row === Math.floor(rows / 2));
    const reach = m.reachable(from, Infinity);
    const okEnemy = m.list.filter(t => t.col >= cols - 2).every(t => reach.has(Hex.key(t.q, t.r)));
    const okCrew = m.list.filter(t => t.col <= 1).every(t => reach.has(Hex.key(t.q, t.r)));
    return okEnemy && okCrew ? m : null;
  }

  PTF.TERRAIN = TERRAIN;
  PTF.BattleMap = BattleMap;
  PTF.generateMap = generate;
  PTF.MAP_CONST = { MAX_H, EYE, AIM, ROCK_H };
})(window.PTF = window.PTF || {});
