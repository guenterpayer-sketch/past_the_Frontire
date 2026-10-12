// Gelände, Lagerhallen-Generator, Sichtlinie, Deckung, Wegfindung.
// Maßstab: 1 Hexfeld = 1,5 m, 1 Höhenstufe = 1,5 m.
(function (PTF) {
  'use strict';
  const Hex = PTF.Hex;

  const HEX_M = 1.5;
  // walk: begehbar; obj: Höhe eines Hindernisses über dem Feld (in Höhenstufen)
  const TERRAIN = {
    boden: { name: 'Hallenboden', walk: true, cost: 1, top: '#8b9199', side: '#5d636b' },
    kiste: { name: 'Kistenstapel', walk: true, cost: 1, top: '#b08650', side: '#7a5a33', kind: 'crate' },
    container: { name: 'Container', walk: true, cost: 1, top: '#9a4a3a', side: '#6a3328', kind: 'container' },
    regal: { name: 'Hochregal', walk: true, cost: 2, top: '#5a6676', side: '#39424e', kind: 'shelf' },
    galerie: { name: 'Galerie (Laufsteg)', walk: true, cost: 1, top: '#6f7a86', side: '#434b55', kind: 'gallery' },
    treppe: { name: 'Treppe', walk: true, cost: 1, top: '#7f8994', side: '#4c545e', kind: 'stairs' },
    leiter: { name: 'Leiter', walk: true, cost: 1, ladder: true, top: '#8b9199', side: '#5d636b', kind: 'ladder' },
    fass: { name: 'Fässer', walk: false, obj: 0.8, top: '#8b9199', side: '#5d636b', kind: 'barrel' },
    barriere: { name: 'Betonbarriere', walk: false, obj: 0.8, top: '#8b9199', side: '#5d636b', kind: 'barrier' },
    saeule: { name: 'Stahlsäule', walk: false, obj: 5, top: '#8b9199', side: '#5d636b', kind: 'pillar' },
    wand: { name: 'Hallenwand', walk: false, obj: 5, top: '#4a4f58', side: '#33373e', kind: 'wall' },
  };
  const EYE = 1.1, AIM = 0.8; // Augen- und Zielhöhe einer Figur (in Höhenstufen)
  const FULL = 1.8, HALF = 0.8; // ab dieser Höhe über dem Ziel: volle / halbe Deckung
  const COVER_BONUS = [0, 30, 50]; // VW-Bonus: keine / halbe / volle Deckung

  const SIZES = [
    // Breite = Spalten × 1,5 m, Tiefe = Reihen × 1,3 m (Reihenabstand im Hexraster)
    { id: 'klein', name: 'klein', cols: 20, rows: 16 },
    { id: 'mittel', name: 'mittel', cols: 30, rows: 23 },
    { id: 'gross', name: 'groß', cols: 40, rows: 31 },
  ];

  class BattleMap {
    constructor(cols, rows) {
      this.cols = cols;
      this.rows = rows;
      this.tiles = new Map();
      this.list = [];
      this.losCache = new Map();
    }
    get(q, r) { return this.tiles.get(Hex.key(q, r)); }
    at(pos) { return pos && this.tiles.get(Hex.key(pos.q, pos.r)); }
    off(col, row) { const { q, r } = Hex.fromOffset(col, row); return this.get(q, r); }
    add(t) { this.tiles.set(Hex.key(t.q, t.r), t); this.list.push(t); }
    blockTop(t) { return t.h + (TERRAIN[t.terrain].obj || 0); }
    walkable(t) { return !!t && TERRAIN[t.terrain].walk; }

    // Bewegungskosten von Feld a nach Nachbarfeld b
    stepCost(a, b) {
      const T = TERRAIN[b.terrain];
      if (!T.walk) return Infinity;
      const dh = b.h - a.h;
      if (dh === 0) return T.cost;
      if (dh === 1) return T.cost + 1;            // hochsteigen
      if (dh === -1) return T.cost;
      if (TERRAIN[a.terrain].ladder || T.ladder) return T.cost + Math.abs(dh); // Leiter
      if (dh === -2) return T.cost + 1;           // herunterspringen (3 m)
      return Infinity;
    }

    // Dijkstra. blocked(tile): nicht betretbar; passOnly(tile): durchqueren ja, stehen bleiben nein
    reachable(start, mp, blocked, passOnly) {
      const startT = this.at(start);
      const best = new Map([[Hex.key(start.q, start.r), { cost: 0, prev: null, tile: startT }]]);
      const open = [{ tile: startT, cost: 0 }];
      while (open.length) {
        let bi = 0;
        for (let i = 1; i < open.length; i++) if (open[i].cost < open[bi].cost) bi = i;
        const cur = open.splice(bi, 1)[0];
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
      if (passOnly) for (const [k, v] of best) if (v.cost > 0 && passOnly(v.tile)) best.delete(k);
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

    // Wer neben voller Deckung steht, kann seitlich herausschauen ("um die Ecke schießen")
    peekTiles(t) {
      const ns = Hex.neighbors(t.q, t.r).map(n => this.get(n.q, n.r)).filter(Boolean);
      if (!ns.some(n => this.blockTop(n) - t.h >= FULL)) return [t];
      return [t, ...ns.filter(n => this.walkable(n) && n.h === t.h)];
    }

    // Sichtlinie zwischen zwei Feldern (statisch, daher zwischengespeichert)
    lineOfSight(a, b) {
      const key = Hex.key(a.q, a.r) + '|' + Hex.key(b.q, b.r);
      let res = this.losCache.get(key);
      if (res) return res;
      res = { visible: false, reason: 'Sicht blockiert' };
      if (this._clear(a, b)) res = { visible: true, peek: false };
      else {
        outer: for (const x of this.peekTiles(a)) {
          for (const y of this.peekTiles(b)) {
            if ((x !== a || y !== b) && this._clear(x, y)) { res = { visible: true, peek: true }; break outer; }
          }
        }
      }
      this.losCache.set(key, res);
      return res;
    }
    _clear(x, y) { return this._line(x, y, 1) || this._line(x, y, -1); }
    _line(x, y, nudge) {
      const line = Hex.line(x, y, nudge);
      const n = line.length - 1;
      const h0 = x.h + EYE, h1 = y.h + AIM;
      for (let i = 1; i < n; i++) {
        const t = this.get(line[i].q, line[i].r);
        if (!t) continue;
        const top = this.blockTop(t);
        if (top <= h0 + (h1 - h0) * (i / n)) continue;
        // niedrige Deckung direkt neben Schütze oder Ziel: darüber schießt man hinweg
        if (i === 1 && top - x.h < FULL) continue;
        if (i === n - 1 && top - y.h < FULL) continue;
        return false;
      }
      return true;
    }

    // Deckung des Ziels gegen einen Angreifer: Hindernis in einem der beiden Felder vor dem Ziel
    // in Schussrichtung (das zweite nur, wenn der Angreifer mindestens 4 Felder entfernt ist).
    // Wer mindestens 1 Stufe über der Deckung steht, senkt sie um eine Stufe.
    cover(target, attacker) {
      const dist = Hex.distance(target, attacker);
      if (dist <= 1) return null;
      let best = null;
      for (const nudge of [1, -1]) {
        const line = Hex.line(target, attacker, nudge);
        for (let i = 1; i <= (dist >= 4 ? 2 : 1); i++) {
          const n = this.get(line[i].q, line[i].r);
          if (!n) continue;
          const top = this.blockTop(n);
          const diff = top - target.h;
          if (diff < HALF) continue;
          let level = diff >= FULL ? 2 : 1;
          if (attacker.h >= top + 1) level--;
          if (level > 0 && (!best || level > best.level)) best = { level, label: TERRAIN[n.terrain].name, bonus: COVER_BONUS[level] };
        }
      }
      return best;
    }
  }

  // ---------- Lagerhallen-Generator ----------
  const CONTAINER_COLORS = ['#9a4a3a', '#3f6f9a', '#4f7f4a', '#b07a2a', '#6a5a8a', '#8a8a8a'];

  function generate(seed, sizeId) {
    const size = SIZES.find(s => s.id === sizeId) || SIZES[1];
    for (let attempt = 0; attempt < 60; attempt++) {
      const s = seed + attempt * 7919;
      const m = tryGenerate(s, size);
      if (m) { m.seed = s; m.size = size; return m; }
    }
    throw new Error('Keine begehbare Halle gefunden');
  }

  function tryGenerate(seed, size) {
    const rng = PTF.makeRng(seed);
    const ri = (a, b) => a + Math.floor(rng() * (b - a + 1));
    const { cols, rows } = size;
    const m = new BattleMap(cols, rows);
    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const { q, r } = Hex.fromOffset(col, row);
        const edge = row === 0 || row === rows - 1 || col === 0 || col === cols - 1;
        m.add({ q, r, col, row, h: 0, terrain: edge ? 'wand' : 'boden' });
      }
    }
    // Rolltore links (Eingang der Crew) und rechts
    const mid = Math.floor(rows / 2);
    for (let row = mid - 2; row <= mid + 1; row++) m.off(0, row).terrain = 'boden';
    for (let row = mid - 1; row <= mid; row++) m.off(cols - 1, row).terrain = 'boden';

    const crewZone = t => t.col <= 3;
    const enemyZone = t => t.col >= cols - 5;
    const free = t => t && t.terrain === 'boden' && !t.res && t.col > 0 && t.col < cols - 1;
    const set = (t, terrain, h, extra) => { t.terrain = terrain; t.h = h; t.res = true; Object.assign(t, extra || {}); };
    const ringFree = tiles => tiles.every(t => Hex.neighbors(t.q, t.r).every(n => {
      const x = m.get(n.q, n.r);
      return !x || tiles.includes(x) || x.terrain === 'boden' || x.terrain === 'wand';
    }));

    // 1. Galerie an der Rückwand (Reihen 1–2), bei mittel/groß auch an der rechten Wand
    for (let col = 1; col < cols - 1; col++) for (const row of [1, 2]) set(m.off(col, row), 'galerie', 3);
    const stairsAt = [Math.floor(cols * 0.3), Math.floor(cols * 0.7)];
    for (const c of stairsAt) { set(m.off(c, 3), 'treppe', 2); set(m.off(c + 1, 3), 'treppe', 1); }
    for (const c of [ri(5, Math.floor(cols / 2) - 2), ri(Math.floor(cols / 2) + 2, cols - 4)]) {
      const t = m.off(c, 3);
      if (free(t)) set(t, 'leiter', 0);
    }
    if (size.id !== 'klein') {
      for (let row = 3; row < rows - 1; row++) for (const col of [cols - 3, cols - 2]) set(m.off(col, row), 'galerie', 3);
      const sr = ri(Math.floor(rows / 2), rows - 4);
      if (free(m.off(cols - 4, sr)) && free(m.off(cols - 4, sr + 1))) { set(m.off(cols - 4, sr), 'treppe', 2); set(m.off(cols - 4, sr + 1), 'treppe', 1); }
      const lr = ri(5, Math.floor(rows / 2) - 1);
      if (free(m.off(cols - 4, lr))) set(m.off(cols - 4, lr), 'leiter', 0);
      // rechtes Rolltor schließen, dort steht jetzt die Galerie
      for (let row = mid - 1; row <= mid; row++) { const t = m.off(cols - 1, row); t.terrain = 'wand'; }
    }

    // 2. Hochregale: parallele Reihen mit Gängen, je eine Leiter am Ende
    const shelfRows = size.id === 'klein' ? 2 : size.id === 'mittel' ? 3 : 5;
    const leftHalf = rng() < 0.5;
    const sx0 = leftHalf ? 6 : Math.floor(cols / 2) + 1, sx1 = leftHalf ? Math.floor(cols / 2) - 1 : cols - 7;
    let sr = ri(5, 6);
    for (let i = 0; i < shelfRows && sr < rows - 3; i++, sr += 3) {
      const len = Math.min(ri(4, 7), sx1 - sx0);
      if (len < 3) break;
      const c0 = ri(sx0, sx1 - len);
      const tiles = [];
      for (let c = c0; c < c0 + len; c++) tiles.push(m.off(c, sr));
      if (!tiles.every(free)) continue;
      tiles.forEach(t => set(t, 'regal', 3));
      const lad = m.off(rng() < 0.5 ? c0 - 1 : c0 + len, sr);
      if (free(lad)) set(lad, 'leiter', 0);
    }

    // 3. Container (3 Felder lang, 1–2 breit), teils doppelt gestapelt
    const nCont = size.id === 'klein' ? 3 : size.id === 'mittel' ? 6 : 11;
    for (let i = 0, tries = 0; i < nCont && tries < 200; tries++) {
      const wide = rng() < 0.4;
      const c0 = ri(5, cols - 9), r0 = ri(4, rows - 3 - (wide ? 1 : 0));
      const tiles = [];
      for (let dr = 0; dr <= (wide ? 1 : 0); dr++) for (let c = c0; c < c0 + 3; c++) tiles.push(m.off(c, r0 + dr));
      if (!tiles.every(t => free(t) && !crewZone(t)) || !ringFree(tiles)) continue;
      const h = rng() < 0.25 ? 4 : 2;
      const color = CONTAINER_COLORS[ri(0, CONTAINER_COLORS.length - 1)];
      tiles.forEach(t => set(t, 'container', h, { color }));
      // Aufstieg: Leiter oder Kiste an einem Ende
      const endT = m.off(rng() < 0.5 ? c0 - 1 : c0 + 3, r0);
      if (free(endT)) { if (h === 4 || rng() < 0.5) set(endT, 'leiter', 0); else set(endT, 'kiste', 1); }
      i++;
    }

    // 4. Kleinzeug: Kistenstapel, Fässer, Betonbarrieren, Säulen
    const area = cols * rows;
    const scatter = (terrain, h, count, len) => {
      for (let i = 0, tries = 0; i < count && tries < count * 20; tries++) {
        const c0 = ri(2, cols - 3), r0 = ri(4, rows - 2);
        const dir = [[1, 0], [0, 1]][ri(0, 1)];
        const tiles = [];
        for (let k = 0; k < len; k++) tiles.push(m.off(c0 + dir[0] * k, r0 + dir[1] * k));
        if (!tiles.every(free)) continue;
        tiles.forEach(t => set(t, terrain, h));
        i++;
      }
    };
    scatter('kiste', 1, Math.round(area / 40), 1);
    scatter('kiste', 1, Math.round(area / 90), 2);
    scatter('fass', 0, Math.round(area / 80), 1);
    scatter('barriere', 0, Math.round(area / 110), 3);
    for (let c = 7; c < cols - 5; c += 7) {
      for (let r = 6; r < rows - 2; r += 6) { const t = m.off(c, r); if (free(t)) set(t, 'saeule', 0); }
    }

    // Erreichbarkeit: jedes Bodenfeld muss vom Eingang aus erreichbar sein
    const start = m.off(1, mid);
    if (!m.walkable(start)) return null;
    const reach = m.reachable(start, Infinity);
    if (!m.list.every(t => !m.walkable(t) || t.h > 0 || reach.has(Hex.key(t.q, t.r)))) return null;

    // Startfelder
    const midRow = (rows - 1) / 2;
    m.crewStart = m.list.filter(t => crewZone(t) && t.col >= 1 && m.walkable(t) && t.h === 0)
      .sort((a, b) => Math.abs(a.row - midRow) - Math.abs(b.row - midRow) || a.col - b.col);
    const enemyTiles = m.list.filter(t => enemyZone(t) && m.walkable(t) && t.col < cols - 1 && reach.has(Hex.key(t.q, t.r)));
    const high = enemyTiles.filter(t => t.h > 0).sort(() => rng() - 0.5);
    const low = enemyTiles.filter(t => t.h === 0).sort(() => rng() - 0.5);
    m.enemyStart = [...high.slice(0, 2), ...low, ...high.slice(2)];
    if (m.crewStart.length < 6 || m.enemyStart.length < 6) return null;
    return m;
  }

  PTF.TERRAIN = TERRAIN;
  PTF.BattleMap = BattleMap;
  PTF.MAP_SIZES = SIZES;
  PTF.generateMap = generate;
  PTF.MAP_CONST = { HEX_M, EYE, AIM, FULL, HALF };
})(window.PTF = window.PTF || {});
