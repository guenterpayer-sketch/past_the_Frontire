// Isometrische Darstellung auf Canvas. Das Hexraster ist nur noch die Spielmechanik:
// Container, Regale, Galerie und Wände werden als durchgehende Körper gezeichnet, der Boden als Betonfläche.
// Kamera mit Zoom und Verschieben; verdeckte Figuren erscheinen halbtransparent; Effekte für Schüsse und Treffer.
(function (PTF) {
  'use strict';
  const { Hex, TERRAIN } = PTF;

  const R = 30;          // Hex-Radius in Pixeln (vor Skalierung) – entspricht 1,5 m Feldbreite
  const SQ = 0.6;        // vertikale Stauchung (Iso-Blick)
  const HS = 22;         // Pixel pro Höhenstufe (1,5 m)
  const BASE = 6;        // Sockeldicke (nur für das Picking)
  const MIN_SCALE = 0.62; // kleiner wird beim Einpassen nicht gezoomt (Lesbarkeit)
  const S3 = Math.sqrt(3);
  const ANG = [-90, -30, 30, 90, 150, 210].map(a => (a * Math.PI) / 180);
  const RANGE_COLORS = [null, '#6fdc6f', '#ffd24a', '#ff9a3c', '#ff5a5a'];
  const FLOOR = '#7b8189';

  function shade(hex, f) {
    const n = parseInt(hex.slice(1), 16);
    const ch = s => Math.max(0, Math.min(255, Math.round(((n >> s) & 255) * f)));
    return `rgb(${ch(16)},${ch(8)},${ch(0)})`;
  }
  // Bodenpunkt (x, z) in Höhe h → Bildschirm (Weltkoordinaten vor Kamera)
  const P = (x, z, h = 0) => [x, z * SQ - h * HS];

  class Renderer {
    constructor(canvas) {
      this.canvas = canvas;
      this.ctx = canvas.getContext('2d');
      this.floats = [];
      this.shots = [];
      this.fx = [];
      this.scale = 1; this.ox = 0; this.oy = 0;
      this.zoom = 1;
      this.showGrid = false;
      this.shakeUntil = 0; this.shakeAmp = 0;
    }

    setMap(map) {
      this.map = map;
      this.rows = [];
      for (let r = 0; r < map.rows; r++) this.rows.push(map.list.filter(t => t.row === r));
      let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
      for (const t of map.list) {
        const p = this.basePos(t);
        x0 = Math.min(x0, p.x - R); x1 = Math.max(x1, p.x + R);
        y0 = Math.min(y0, p.y - (t.h + 4) * HS - R * SQ);
        y1 = Math.max(y1, p.y + R * SQ + BASE);
      }
      this.bounds = { x0, x1, y0, y1 };
      this.center = { x: (x0 + x1) / 2, y: (y0 + y1) / 2 };
      this.zoom = 0;
      this.buildObjects();
      this.buildDecals();
      this.resize();
    }

    // ---------- Objekte aus zusammengehörigen Feldern ----------
    ground(t) { return { x: R * S3 * (t.q + t.r / 2), z: R * 1.5 * t.r }; }

    buildObjects() {
      const groups = new Map();
      for (const t of this.map.list) {
        if (!t.obj) continue;
        if (!groups.has(t.obj)) groups.set(t.obj, []);
        groups.get(t.obj).push(t);
      }
      this.objects = [];
      this.objOfTile = new Map();
      for (const [id, tiles] of groups) {
        const kind = TERRAIN[tiles[0].terrain].kind;
        const pts = tiles.map(t => this.ground(t));
        const xs = pts.map(p => p.x), zs = pts.map(p => p.z);
        const vertical = new Set(tiles.map(t => t.row)).size > 1 && new Set(tiles.map(t => t.col)).size <= 2 && tiles.length > 2;
        // Rand je nach Objekt: Kisten und Barrieren etwas schmaler, damit sie wie Einzelteile wirken
        const padX = { crate: 0.72, barrier: vertical ? 0.42 : 0.85 }[kind] || (vertical ? 0.6 : 0.87);
        const padZ = { crate: 0.62, barrier: vertical ? 0.75 : 0.4 }[kind] || 0.75;
        const o = {
          id, kind, tiles, vertical,
          x0: Math.min(...xs) - R * padX, x1: Math.max(...xs) + R * padX,
          z0: Math.min(...zs) - R * padZ, z1: Math.max(...zs) + R * padZ,
          h: Math.max(...tiles.map(t => t.h)) || (kind === 'barrier' ? 0.8 : kind === 'wall' ? 3.5 : 1),
          row: Math.max(...tiles.map(t => t.row)),
          color: tiles[0].color,
          front: tiles.every(t => t.row === this.map.rows - 1),
        };
        if (kind === 'wall' && o.front) o.h = 0.4;
        if (kind === 'wall' && tiles.every(t => t.row === 0)) o.h = 3.5;
        this.objects.push(o);
        for (const t of tiles) this.objOfTile.set(t, o);
      }
      this.objByRow = new Map();
      for (const o of this.objects) {
        if (!this.objByRow.has(o.row)) this.objByRow.set(o.row, []);
        this.objByRow.get(o.row).push(o);
      }
    }

    // Flecken, Markierungen und Lichtpunkte auf dem Boden (fest pro Karte)
    buildDecals() {
      const rng = PTF.makeRng((this.map.seed || 1) * 31 + 7);
      const floor = this.map.list.filter(t => t.h === 0 && TERRAIN[t.terrain].walk);
      this.stains = [];
      for (let i = 0; i < floor.length / 9; i++) {
        const t = floor[Math.floor(rng() * floor.length)], g = this.ground(t);
        this.stains.push({ x: g.x + (rng() - 0.5) * R, z: g.z + (rng() - 0.5) * R, rx: R * (0.3 + rng() * 0.9), rz: R * (0.2 + rng() * 0.6), a: 0.05 + rng() * 0.1, oil: rng() < 0.3 });
      }
      // Lichtkegel der Hallenbeleuchtung im Raster
      const b = this.map.list.map(t => this.ground(t));
      const minX = Math.min(...b.map(p => p.x)), maxX = Math.max(...b.map(p => p.x));
      const minZ = Math.min(...b.map(p => p.z)), maxZ = Math.max(...b.map(p => p.z));
      this.lights = [];
      for (let x = minX + R * 6; x < maxX - R * 2; x += R * 11) for (let z = minZ + R * 7; z < maxZ - R * 2; z += R * 10) this.lights.push({ x, z });
      // gelbe Sicherheitslinien vor der Galerie und an den Treppen
      this.lanes = [];
      const z3 = R * 1.5 * 3 - R * 0.75;
      this.lanes.push({ x0: minX + R * 2, x1: maxX - R * 2, z: z3 });
    }

    resize() {
      const c = this.canvas, dpr = window.devicePixelRatio || 1;
      const w = c.clientWidth, h = c.clientHeight;
      c.width = Math.round(w * dpr); c.height = Math.round(h * dpr);
      this.dpr = dpr; this.w = w; this.h = h;
      if (!this.map) return;
      const b = this.bounds, pad = 12;
      this.fit = Math.min((w - pad * 2) / (b.x1 - b.x0), (h - pad * 2) / (b.y1 - b.y0));
      if (!this.zoom) this.zoom = Math.max(1, MIN_SCALE / this.fit);
      this.applyCamera();
    }

    applyCamera() {
      const b = this.bounds;
      this.scale = this.fit * this.zoom;
      const hw = this.w / 2 / this.scale, hh = this.h / 2 / this.scale;
      const cx = (b.x1 - b.x0) / 2 > hw ? Math.min(Math.max(this.center.x, b.x0 + hw), b.x1 - hw) : (b.x0 + b.x1) / 2;
      const cy = (b.y1 - b.y0) / 2 > hh ? Math.min(Math.max(this.center.y, b.y0 + hh), b.y1 - hh) : (b.y0 + b.y1) / 2;
      this.center = { x: cx, y: cy };
      this.ox = this.w / 2 - cx * this.scale;
      this.oy = this.h / 2 - cy * this.scale;
    }

    zoomAt(sx, sy, factor) {
      const before = this.toWorld(sx, sy);
      this.zoom = Math.min(4, Math.max(1, this.zoom * factor));
      this.scale = this.fit * this.zoom;
      this.center = { x: before.x - (sx - this.w / 2) / this.scale, y: before.y - (sy - this.h / 2) / this.scale };
      this.applyCamera();
    }
    panBy(dx, dy) { this.center = { x: this.center.x - dx / this.scale, y: this.center.y - dy / this.scale }; this.applyCamera(); }
    centerOn(p) { this.center = { x: p.x, y: p.y }; this.applyCamera(); }
    ensureVisible(u) {
      const p = this.toScreen(this.unitPos(u));
      const m = 80;
      if (p.x < m || p.y < m || p.x > this.w - m || p.y > this.h - m) this.centerOn(this.unitPos(u));
    }

    basePos(t) { return { x: R * S3 * (t.q + t.r / 2), y: R * 1.5 * SQ * t.r }; }
    topPos(t) { const p = this.basePos(t); return { x: p.x, y: p.y - t.h * HS }; }
    hexPts(cx, cy, dy = 0, k = 1) { return ANG.map(a => [cx + R * k * Math.cos(a), cy + R * k * SQ * Math.sin(a) + dy]); }

    toScreen(p) { return { x: p.x * this.scale + this.ox, y: p.y * this.scale + this.oy }; }
    toWorld(x, y) { return { x: (x - this.ox) / this.scale, y: (y - this.oy) / this.scale }; }

    // ---------- Picking (weiter über die Hexfelder) ----------
    silhouette(t) {
      const c = this.topPos(t), d = t.h * HS + BASE;
      const T = this.hexPts(c.x, c.y), B = this.hexPts(c.x, c.y, d);
      return [T[0], T[1], B[2], B[3], B[4], T[5]];
    }
    pickTile(mx, my, prefer) {
      const p = this.toWorld(mx, my);
      if (prefer) {
        for (let r = this.rows.length - 1; r >= 0; r--) {
          for (const t of this.rows[r]) {
            if (!prefer.has(Hex.key(t.q, t.r))) continue;
            const c = this.topPos(t);
            if (inPoly(p.x, p.y, this.hexPts(c.x, c.y))) return t;
          }
        }
      }
      for (let r = this.rows.length - 1; r >= 0; r--) {
        for (const t of this.rows[r]) if (inPoly(p.x, p.y, this.silhouette(t))) return t;
      }
      return null;
    }
    pickUnit(mx, my) {
      if (!this.combat) return null;
      const p = this.toWorld(mx, my);
      const list = this.combat.units.filter(u => u.state !== 'dead').map(u => ({ u, q: this.unitPos(u) })).sort((a, b) => b.q.row - a.q.row);
      for (const { u, q } of list) if (Math.abs(p.x - q.x) <= 12 && p.y >= q.y - 36 && p.y <= q.y + 5) return u;
      return null;
    }

    // ---------- Animationen und Effekte ----------
    addFloat(unit, text, color) { this.floats.push({ unit, text, color, t0: performance.now() }); }
    addShot(from, to, color) { this.shots.push({ from, to, color, t0: performance.now() }); this.addFlash(from, to); }
    animateMove(unit, path) { unit.anim = { path, t0: performance.now(), step: 110 }; }
    addFlash(unit, toward) { this.fx.push({ type: 'flash', unit, toward, t0: performance.now(), dur: 120 }); }
    addSparks(unit, blood) {
      const p = this.unitPos(unit), parts = [];
      for (let i = 0; i < (blood ? 10 : 8); i++) {
        const a = Math.random() * Math.PI * 2, v = 20 + Math.random() * 40;
        parts.push({ vx: Math.cos(a) * v, vy: -Math.abs(Math.sin(a)) * v - 10, c: blood ? (i % 2 ? '#8b1a1a' : '#c0392b') : (i % 2 ? '#ffd54f' : '#fff3c4') });
      }
      this.fx.push({ type: 'sparks', x: p.x, y: p.y - 16, parts, t0: performance.now(), dur: blood ? 600 : 350 });
    }
    addExplosion(unit) {
      const p = this.unitPos(unit), smoke = [];
      for (let i = 0; i < 10; i++) smoke.push({ dx: (Math.random() - 0.5) * 40, dy: -Math.random() * 30, r: 6 + Math.random() * 10 });
      this.fx.push({ type: 'boom', x: p.x, y: p.y - 6, smoke, t0: performance.now(), dur: 900 });
      this.shake(5, 300);
    }
    shake(amp, ms) { this.shakeAmp = Math.max(this.shakeAmp, amp); this.shakeUntil = performance.now() + ms; }
    busy() {
      const now = performance.now();
      return this.shots.some(s => now - s.t0 < 260) || (this.combat && this.combat.units.some(u => u.anim));
    }

    unitPos(u) {
      const now = performance.now();
      if (u.anim) {
        const { path, t0, step } = u.anim;
        const f = (now - t0) / step;
        if (f >= path.length - 1) { u.anim = null; }
        else {
          const i = Math.floor(f), k = f - i;
          const a = this.topPos(path[i]), b = this.topPos(path[i + 1]);
          const hop = Math.sin(k * Math.PI) * (path[i + 1].h !== path[i].h ? 8 : 2);
          return { x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k - hop, row: this.drawRow(path[k < 0.5 ? i : i + 1]) };
        }
      }
      const t = this.map.at(u.pos);
      return { ...this.topPos(t), row: this.drawRow(t) };
    }
    // Figuren auf Objekten werden mit dem Objekt (in dessen vorderster Reihe) gezeichnet
    drawRow(t) { const o = this.objOfTile && this.objOfTile.get(t); return o && t.h > 0 ? o.row : t.row; }

    // ---------- Zeichnen ----------
    draw(view) {
      const ctx = this.ctx, now = performance.now();
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.fillStyle = '#0b0f1a';
      ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
      let sx = 0, sy = 0;
      if (now < this.shakeUntil) { const k = (this.shakeUntil - now) / 300; sx = (Math.random() - 0.5) * this.shakeAmp * k; sy = (Math.random() - 0.5) * this.shakeAmp * k; }
      else this.shakeAmp = 0;
      ctx.setTransform(this.dpr * this.scale, 0, 0, this.dpr * this.scale, this.dpr * (this.ox + sx), this.dpr * (this.oy + sy));

      this.drawFloor(ctx, view);
      const units = this.combat ? this.combat.units : [];
      const placed = units.map(u => ({ u, p: this.unitPos(u) }));
      for (let r = 0; r < this.rows.length; r++) {
        // Einzelteile auf Bodenhöhe dieser Reihe (Fässer, Säulen, Leitern, Treppenstufen)
        for (const t of this.rows[r]) this.drawProp(ctx, t, view);
        for (const o of this.objByRow.get(r) || []) this.drawObject(ctx, o, view);
        placed.filter(x => x.p.row === r).sort((a, b) => (a.u.state === 'ok') - (b.u.state === 'ok'))
          .forEach(x => this.drawUnit(ctx, x.u, x.p, view, now));
      }
      for (const { u, p } of placed) if (u.state === 'ok') this.drawGhost(ctx, u, p, view);
      if (view.path && view.path.length > 1) this.drawPath(ctx, view.path);
      if (view.preview) this.drawPreview(ctx, view.preview, placed);
      this.drawShots(ctx, now);
      this.drawFx(ctx, now);
      this.drawFloats(ctx, now);
      this.drawVignette(ctx);
    }

    // Boden: durchgehender Beton, Flecken, Linien, Licht; Hervorhebungen auf Bodenfeldern
    drawFloor(ctx, view) {
      for (const t of this.map.list) {
        const c = this.basePos(t);
        poly(ctx, this.hexPts(c.x, c.y, 0, 1.03), t.h === 0 && TERRAIN[t.terrain].kind !== 'wall' ? FLOOR : '#3a3e46');
      }
      ctx.save();
      for (const s of this.stains) {
        ctx.fillStyle = s.oil ? `rgba(20,24,30,${s.a + 0.05})` : `rgba(40,44,50,${s.a})`;
        ctx.beginPath(); ctx.ellipse(s.x, s.z * SQ, s.rx, s.rz * SQ, 0, 0, 7); ctx.fill();
      }
      // Fugen im Beton (große Platten, unabhängig vom Hexraster)
      ctx.strokeStyle = 'rgba(0,0,0,0.12)'; ctx.lineWidth = 1;
      const b = this.bounds;
      for (let x = Math.floor(b.x0 / (R * 4)) * R * 4; x < b.x1; x += R * 4) { ctx.beginPath(); ctx.moveTo(x, b.y0); ctx.lineTo(x, b.y1); ctx.stroke(); }
      for (let z = 0; z * SQ < b.y1; z += R * 4) { ctx.beginPath(); ctx.moveTo(b.x0, z * SQ); ctx.lineTo(b.x1, z * SQ); ctx.stroke(); }
      // gelbe Sicherheitslinien
      for (const l of this.lanes) {
        ctx.strokeStyle = 'rgba(232,194,58,0.7)'; ctx.lineWidth = 3; ctx.setLineDash([R * 0.8, R * 0.4]);
        ctx.beginPath(); ctx.moveTo(...P(l.x0, l.z)); ctx.lineTo(...P(l.x1, l.z)); ctx.stroke();
      }
      ctx.setLineDash([]);
      // Lichtkegel
      ctx.globalCompositeOperation = 'lighter';
      for (const L of this.lights) {
        const [x, y] = P(L.x, L.z);
        const g = ctx.createRadialGradient(x, y, 0, x, y, R * 5);
        g.addColorStop(0, 'rgba(255,240,200,0.10)'); g.addColorStop(1, 'rgba(255,240,200,0)');
        ctx.fillStyle = g;
        ctx.beginPath(); ctx.ellipse(x, y, R * 5, R * 5 * SQ, 0, 0, 7); ctx.fill();
      }
      ctx.restore();
      // Gefahrenstreifen am Fuß der Treppen und Leitern
      for (const t of this.map.list) {
        const k = TERRAIN[t.terrain].kind;
        if (k !== 'ladder') continue;
        const c = this.basePos(t);
        hazard(ctx, this.hexPts(c.x, c.y, 0, 0.7));
      }
      for (const t of this.map.list) if (t.h === 0 && !this.objOfTile.get(t)) this.drawTileMarks(ctx, t, view);
    }

    // Hervorhebungen (Bewegung, Hover, Erste Hilfe, Reichweite, Raster) auf einem Feld
    drawTileMarks(ctx, t, view) {
      const c = this.topPos(t);
      const k = Hex.key(t.q, t.r);
      const walk = TERRAIN[t.terrain].walk;
      if (this.showGrid && walk) { ctx.strokeStyle = 'rgba(255,255,255,0.13)'; ctx.lineWidth = 1; strokePoly(ctx, this.hexPts(c.x, c.y, 0, 0.98)); }
      let hl = null;
      if (view.reach && view.reach.has(k)) hl = 'rgba(80,165,255,0.32)';
      if (view.aidTiles && view.aidTiles.has(k)) hl = 'rgba(120,230,140,0.40)';
      if (view.hover === t) hl = 'rgba(255,255,255,0.25)';
      if (hl) { poly(ctx, this.hexPts(c.x, c.y, 0, 0.94), hl); if (view.reach && view.reach.has(k)) { ctx.strokeStyle = 'rgba(120,190,255,0.35)'; ctx.lineWidth = 1; strokePoly(ctx, this.hexPts(c.x, c.y, 0, 0.94)); } }
      if (view.hover === t) { ctx.strokeStyle = '#fff'; ctx.lineWidth = 1.5; strokePoly(ctx, this.hexPts(c.x, c.y, 0, 0.94)); }
      if (view.range && view.range.has(k)) {
        ctx.fillStyle = RANGE_COLORS[view.range.get(k)] || '#ff5a5a';
        ctx.beginPath(); ctx.ellipse(c.x, c.y, 5, 5 * SQ, 0, 0, 7); ctx.fill();
        ctx.strokeStyle = 'rgba(0,0,0,0.5)'; ctx.lineWidth = 1; ctx.stroke();
      }
    }

    // Einzelteile, die nicht zu einem Objekt gehören
    drawProp(ctx, t, view) {
      const kind = TERRAIN[t.terrain].kind;
      const c = this.topPos(t);
      if (kind === 'barrel') {
        barrel(ctx, c.x - 7, c.y + 3, '#c9a227', true); barrel(ctx, c.x + 6, c.y - 3, '#3b6ea8', false);
      } else if (kind === 'pillar') {
        const g = this.ground(t);
        box(ctx, g.x - R * 0.28, g.x + R * 0.28, g.z - R * 0.28, g.z + R * 0.28, 0, 4.5, '#7b838e', '#5a616b');
        ctx.fillStyle = '#e8c23a'; // Warnanstrich unten
        const [x0, y0] = P(g.x - R * 0.28, g.z + R * 0.28, 0.5), [x1] = P(g.x + R * 0.28, 0);
        for (let i = 0; i < 4; i++) { ctx.fillStyle = i % 2 ? '#222' : '#e8c23a'; ctx.fillRect(x0 + (x1 - x0) * i / 4, y0, (x1 - x0) / 4, 0.5 * HS); }
      } else if (kind === 'stairs') {
        const g = this.ground(t);
        const steps = t.h * 2;
        for (let i = 0; i < steps; i++) {
          const h1 = (i + 1) / 2;
          const zA = g.z + R * 0.75 - (i / steps) * R * 1.5, zB = g.z - R * 0.75;
          box(ctx, g.x - R * 0.88, g.x + R * 0.88, zB, zA, 0, h1, '#8a939d', '#5b636c');
        }
        ctx.strokeStyle = '#e8c23a'; ctx.lineWidth = 1.5; // Handlauf
        ctx.beginPath(); ctx.moveTo(...P(g.x + R * 0.86, g.z + R * 0.75, 1)); ctx.lineTo(...P(g.x + R * 0.86, g.z - R * 0.75, t.h + 0.6)); ctx.stroke();
      } else if (kind === 'ladder') {
        let up = 0;
        for (const n of Hex.neighbors(t.q, t.r)) { const x = this.map.get(n.q, n.r); if (x && TERRAIN[x.terrain].walk) up = Math.max(up, x.h - t.h); }
        const hgt = Math.max(1, up) * HS;
        ctx.strokeStyle = '#e8c23a'; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(c.x - 5, c.y + 2); ctx.lineTo(c.x - 5, c.y - hgt); ctx.moveTo(c.x + 5, c.y + 2); ctx.lineTo(c.x + 5, c.y - hgt); ctx.stroke();
        ctx.lineWidth = 1.3;
        for (let y = c.y - 4; y > c.y - hgt; y -= 6) { ctx.beginPath(); ctx.moveTo(c.x - 5, y); ctx.lineTo(c.x + 5, y); ctx.stroke(); }
      }
      if (t.h > 0 && !this.objOfTile.get(t)) this.drawTileMarks(ctx, t, view);
    }

    drawObject(ctx, o, view) {
      const { x0, x1, z0, z1, h } = o;
      switch (o.kind) {
        case 'container': {
          const col = o.color || '#9a4a3a';
          box(ctx, x0, x1, z0, z1, 0, h, shade(col, 1.05), shade(col, 0.8));
          // Wellblech, Naht bei Doppelstapel, Tür und Beschriftung auf der Vorderseite
          ctx.strokeStyle = 'rgba(0,0,0,0.22)'; ctx.lineWidth = 1;
          for (let x = x0 + 4; x < x1 - 2; x += 5) { ctx.beginPath(); ctx.moveTo(...P(x, z1, h - 0.05)); ctx.lineTo(...P(x, z1, 0.05)); ctx.stroke(); }
          if (h > 2) { ctx.strokeStyle = 'rgba(0,0,0,0.55)'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(...P(x0, z1, 2)); ctx.lineTo(...P(x1, z1, 2)); ctx.stroke(); }
          for (let lvl = 0; lvl < h; lvl += 2) {
            const dx = x1 - R * 0.9;
            ctx.strokeStyle = 'rgba(0,0,0,0.5)'; ctx.lineWidth = 1.2;
            ctx.beginPath(); ctx.moveTo(...P(dx, z1, lvl + 1.8)); ctx.lineTo(...P(dx, z1, lvl + 0.1)); ctx.stroke();
            ctx.beginPath(); ctx.moveTo(...P(dx + R * 0.45, z1, lvl + 1.8)); ctx.lineTo(...P(dx + R * 0.45, z1, lvl + 0.1)); ctx.stroke();
            ctx.fillStyle = 'rgba(255,255,255,0.75)'; ctx.font = 'bold 7px system-ui, sans-serif'; ctx.textAlign = 'left';
            ctx.fillText(`PTF-${(o.id * 37) % 900 + 100}`, ...P(x0 + 6, z1, lvl + 1.4));
          }
          ctx.strokeStyle = 'rgba(255,255,255,0.12)'; strokePoly(ctx, [P(x0 + 3, z0 + 3, h), P(x1 - 3, z0 + 3, h), P(x1 - 3, z1 - 3, h), P(x0 + 3, z1 - 3, h)]);
          break;
        }
        case 'shelf': {
          box(ctx, x0, x1, z0, z1, 0, h, '#3d4652', '#2a313a');
          // Böden, Paletten und Kartons, Pfosten
          for (let lvl = 0; lvl < h; lvl += 0.75) {
            for (let x = x0 + 3; x < x1 - 8; x += 11) {
              if (((x * 7 + lvl * 13) | 0) % 5 === 0) continue;
              const hh = 0.35 + (((x * 3 + lvl * 5) | 0) % 3) * 0.08;
              ctx.fillStyle = ((x + lvl * 10) | 0) % 2 ? '#a07d50' : '#8a6a40';
              ctx.fillRect(P(x, z1, lvl + hh + 0.08)[0], P(x, z1, lvl + hh + 0.08)[1], 9, hh * HS);
            }
            ctx.strokeStyle = '#d9822b'; ctx.lineWidth = 2;
            ctx.beginPath(); ctx.moveTo(...P(x0, z1, lvl + 0.05)); ctx.lineTo(...P(x1, z1, lvl + 0.05)); ctx.stroke();
          }
          ctx.strokeStyle = '#4f7fb8'; ctx.lineWidth = 2.5;
          for (let x = x0 + 1; x <= x1; x += Math.max(R * 1.4, (x1 - x0) / Math.max(1, Math.round((x1 - x0) / (R * 1.6))))) {
            ctx.beginPath(); ctx.moveTo(...P(x, z1, h)); ctx.lineTo(...P(x, z1, 0)); ctx.stroke();
          }
          grating(ctx, x0, x1, z0, z1, h);
          break;
        }
        case 'gallery': {
          box(ctx, x0, x1, z0, z1, 0, h, '#626c78', '#262b33');
          // Stützen und Streben unter dem Laufsteg
          ctx.strokeStyle = '#4a525d'; ctx.lineWidth = 3;
          const step = R * 2.5;
          if (!o.vertical) {
            for (let x = x0 + 6; x < x1; x += step) { ctx.beginPath(); ctx.moveTo(...P(x, z1, h - 0.1)); ctx.lineTo(...P(x, z1, 0)); ctx.stroke(); }
            ctx.lineWidth = 1.5; ctx.strokeStyle = 'rgba(90,100,112,0.8)';
            for (let x = x0 + 6; x + step < x1; x += step) { ctx.beginPath(); ctx.moveTo(...P(x, z1, h - 0.2)); ctx.lineTo(...P(x + step, z1, 0.3)); ctx.stroke(); }
          }
          grating(ctx, x0, x1, z0, z1, h);
          // Geländer an der Vorderkante (bzw. an der Innenseite der seitlichen Galerie)
          ctx.strokeStyle = '#e8c23a'; ctx.lineWidth = 2;
          const rail = o.vertical ? [[x0, z0], [x0, z1], [x1, z1]] : [[x0, z1], [x1, z1]];
          ctx.beginPath(); rail.forEach(([x, z], i) => (i ? ctx.lineTo(...P(x, z, h + 0.6)) : ctx.moveTo(...P(x, z, h + 0.6)))); ctx.stroke();
          ctx.lineWidth = 1.2;
          const postLine = (xa, za, xb, zb) => {
            const len = Math.hypot(xb - xa, zb - za), n = Math.max(1, Math.round(len / (R * 0.9)));
            for (let i = 0; i <= n; i++) { const x = xa + (xb - xa) * i / n, z = za + (zb - za) * i / n; ctx.beginPath(); ctx.moveTo(...P(x, z, h)); ctx.lineTo(...P(x, z, h + 0.6)); ctx.stroke(); }
          };
          for (let i = 1; i < rail.length; i++) postLine(rail[i - 1][0], rail[i - 1][1], rail[i][0], rail[i][1]);
          break;
        }
        case 'crate': {
          box(ctx, x0, x1, z0, z1, 0, h, '#b98d58', '#8d6638');
          ctx.strokeStyle = 'rgba(60,35,10,0.55)'; ctx.lineWidth = 1;
          const fx0 = P(x0, z1, h), fx1 = P(x1, z1, 0);
          ctx.strokeRect(fx0[0] + 2, fx0[1] + 2, fx1[0] - fx0[0] - 4, fx1[1] - fx0[1] - 4);
          ctx.beginPath(); ctx.moveTo(fx0[0] + 2, fx0[1] + 2); ctx.lineTo(fx1[0] - 2, fx1[1] - 2); ctx.stroke();
          for (let x = x0 + R * 1.73; x < x1 - 4; x += R * 1.73) { ctx.strokeStyle = 'rgba(60,35,10,0.7)'; ctx.beginPath(); ctx.moveTo(...P(x, z1, h)); ctx.lineTo(...P(x, z1, 0)); ctx.stroke(); }
          break;
        }
        case 'barrier':
          box(ctx, x0, x1, z0, z1, 0, h, '#b5b5ba', '#8e8e94');
          ctx.fillStyle = 'rgba(200,60,40,0.7)';
          for (let x = x0 + 4; x < x1 - 4; x += 12) { const a = P(x, z1, h * 0.7); ctx.fillRect(a[0], a[1], 6, 3); }
          break;
        case 'wall': {
          box(ctx, x0, x1, z0, z1, 0, h, '#454a54', '#30343c');
          if (h > 1) {
            // Fensterband und Paneele
            ctx.fillStyle = 'rgba(140,180,220,0.18)';
            for (let x = x0 + 10; x < x1 - 30; x += R * 3) { const a = P(x, z1, h - 0.4); ctx.fillRect(a[0], a[1], R * 1.8, 0.3 * HS); }
            ctx.strokeStyle = 'rgba(0,0,0,0.25)'; ctx.lineWidth = 1;
            for (let x = x0 + R * 1.5; x < x1; x += R * 1.5) { ctx.beginPath(); ctx.moveTo(...P(x, z1, h)); ctx.lineTo(...P(x, z1, 0)); ctx.stroke(); }
          }
          break;
        }
      }
      for (const t of o.tiles) if (TERRAIN[t.terrain].walk) this.drawTileMarks(ctx, t, view);
    }

    // ---------- Figuren ----------
    drawUnit(ctx, u, p, view, now) {
      const x = p.x, y = p.y;
      const enemy = u.team === 'enemy';
      const team = enemy ? '#ff5d5d' : '#5db7ff';
      if (u.state === 'dead') {
        ctx.fillStyle = 'rgba(90,10,10,0.45)'; ctx.beginPath(); ctx.ellipse(x, y + 1, 13, 6, 0, 0, 7); ctx.fill();
        this.lying(ctx, x, y, u, '#555');
        return;
      }
      ctx.fillStyle = 'rgba(0,0,0,0.35)';
      ctx.beginPath(); ctx.ellipse(x, y + 1, 12, 6, 0, 0, 7); ctx.fill();
      if (u.state === 'ko') {
        this.lying(ctx, x, y, u, '#888');
        text(ctx, 'z', x + 13, y - 12, '#ddd', 9);
        return;
      }
      if (view.current === u) {
        const pulse = 0.5 + 0.5 * Math.sin(now / 200);
        ctx.strokeStyle = `rgba(255,220,80,${0.5 + pulse * 0.5})`; ctx.lineWidth = 2.5;
        ctx.beginPath(); ctx.ellipse(x, y + 1, 15 + pulse * 2, 8 + pulse, 0, 0, 7); ctx.stroke();
      }
      if (view.targets && view.targets.has(u)) {
        ctx.strokeStyle = '#ff4040'; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.ellipse(x, y + 1, 16, 8.5, 0, 0, 7); ctx.stroke();
      }
      // Blickrichtung: Sichtfeld als heller Halbkreis, Pfeil am Boden
      const ang = (Hex.dirAngle(u.facing) * Math.PI) / 180;
      const cx = Math.cos(ang), cy = Math.sin(ang);
      const pt = (along, side) => [x + cx * along - cy * side, y + 1 + (cy * along + cx * side) * SQ];
      ctx.fillStyle = enemy ? 'rgba(255,93,93,0.16)' : 'rgba(93,183,255,0.16)';
      ctx.beginPath(); ctx.ellipse(x, y + 1, 20, 20 * SQ, 0, ang - Math.PI / 2, ang + Math.PI / 2); ctx.lineTo(x, y + 1); ctx.fill();
      ctx.fillStyle = team;
      ctx.beginPath(); ctx.moveTo(...pt(23, 0)); ctx.lineTo(...pt(14, -5)); ctx.lineTo(...pt(14, 5)); ctx.closePath(); ctx.fill();
      ctx.strokeStyle = team; ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.ellipse(x, y + 1, 11, 5.5, 0, 0, 7); ctx.stroke();

      const top = this.figure(ctx, x, y, u, 1);
      if (u.psiShield > 0) { ctx.strokeStyle = 'rgba(190,140,255,0.8)'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.ellipse(x, (y + top) / 2, 15, (y - top) / 2 + 6, 0, 0, 7); ctx.stroke(); }
      this.drawBars(ctx, u, x, top - 4);
    }

    // Figur: Beine, Rumpf in Teamfarbe mit Abzeichen, Kopf/Helm, Waffe in Blickrichtung. Gibt die Oberkante zurück.
    figure(ctx, x, y, u, alpha) {
      const enemy = u.team === 'enemy';
      const crouch = u.crouched;
      const legH = crouch ? 5 : 10, torsoH = crouch ? 10 : 12;
      const torsoY = y - legH - torsoH, headY = torsoY - 5;
      const ang = (Hex.dirAngle(u.facing) * Math.PI) / 180;
      const fx = Math.cos(ang), fy = Math.sin(ang) * SQ;
      const behind = fy < -0.1; // Waffe zeigt nach hinten: hinter dem Körper zeichnen
      ctx.save();
      ctx.globalAlpha *= alpha;
      const weapon = () => {
        const W = PTF.WEAPONS[u.weapon] || {};
        const len = W.melee ? 13 : W.splash ? 18 : W.psi ? 0 : W.inc >= 20 ? 16 : 11;
        if (!len) { ctx.fillStyle = 'rgba(190,140,255,0.9)'; ctx.beginPath(); ctx.arc(x + fx * 9, torsoY + 6 + fy * 9, 2.5, 0, 7); ctx.fill(); return; }
        const sx = x + fx * 3, sy = torsoY + 6 + fy * 3;
        ctx.strokeStyle = W.melee ? '#b8f0ff' : '#1a1d22'; ctx.lineWidth = W.splash ? 4 : 3;
        ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(sx + fx * len, sy + fy * len); ctx.stroke();
      };
      if (behind) weapon();
      // Beine
      ctx.strokeStyle = '#1b1f27'; ctx.lineWidth = 3.5; ctx.lineCap = 'round';
      ctx.beginPath(); ctx.moveTo(x - 3, y - 1); ctx.lineTo(x - 3 + (crouch ? -2 : 0), y - legH); ctx.moveTo(x + 3, y - 1); ctx.lineTo(x + 3 + (crouch ? 2 : 0), y - legH); ctx.stroke();
      ctx.lineCap = 'butt';
      // Rumpf
      ctx.fillStyle = enemy ? '#4a1818' : '#16304d';
      roundRect(ctx, x - 7, torsoY, 14, torsoH + 1, 4); ctx.fill();
      ctx.fillStyle = u.color;
      roundRect(ctx, x - 5, torsoY + 2, 10, torsoH - 3, 3); ctx.fill();
      if (u.shield) { ctx.fillStyle = '#9fb3c8'; ctx.strokeStyle = '#5e7186'; ctx.lineWidth = 1; ctx.beginPath(); ctx.ellipse(x - 8 + fx * 3, torsoY + 7, 4, 7, 0, 0, 7); ctx.fill(); ctx.stroke(); }
      text(ctx, u.letter, x, torsoY + torsoH / 2 + 1, '#111', 8, 'bold');
      // Kopf mit Helm und Visier in Blickrichtung
      ctx.fillStyle = enemy ? '#7a2a2a' : '#2b4f75';
      ctx.beginPath(); ctx.arc(x, headY, 5, 0, 7); ctx.fill();
      ctx.fillStyle = enemy ? '#ff9a7a' : '#9fe3ff';
      ctx.beginPath(); ctx.ellipse(x + fx * 2.5, headY + fy * 2 + 0.5, 3, 1.6, 0, 0, 7); ctx.fill();
      if (!behind) weapon();
      ctx.restore();
      return headY - 5;
    }

    lying(ctx, x, y, u, color) {
      const enemy = u.team === 'enemy';
      ctx.fillStyle = color; ctx.strokeStyle = enemy ? '#ff5d5d' : '#5db7ff'; ctx.lineWidth = 1.5;
      roundRect(ctx, x - 12, y - 7, 20, 7, 3); ctx.fill(); ctx.stroke();
      ctx.fillStyle = enemy ? '#7a2a2a' : '#2b4f75'; ctx.beginPath(); ctx.arc(x + 11, y - 4, 4, 0, 7); ctx.fill();
    }

    drawBars(ctx, u, x, by) {
      const f = Math.max(0, u.hp / u.maxHp);
      ctx.fillStyle = 'rgba(0,0,0,0.7)'; ctx.fillRect(x - 13, by - 4, 26, 4);
      ctx.fillStyle = f > 0.5 ? '#6fdc6f' : f > 0.25 ? '#ffd24a' : '#ff5a5a'; ctx.fillRect(x - 13, by - 4, 26 * f, 4);
      let sx = x - 13;
      const icon = (c, s) => { text(ctx, s, sx + 3, by - 9, c, 8, 'bold'); sx += 8; };
      if (u.bleed) icon('#ff4d4d', '♦');
      if (u.stun) icon('#ffd54f', '★');
      if (u.prone) icon('#bbb', '↓');
      if (u.overwatch) icon('#ffd34d', '◎');
    }

    // halbtransparente Figur über allem: zeigt Figuren hinter Containern und Regalen
    drawGhost(ctx, u, p, view) {
      const edge = view.targets && view.targets.has(u) ? '#ff3030' : view.current === u ? '#ffd34d' : u.team === 'enemy' ? '#ff5d5d' : '#5db7ff';
      const top = this.figure(ctx, p.x, p.y, u, 0.45);
      ctx.save(); ctx.globalAlpha = 0.8; ctx.strokeStyle = edge; ctx.lineWidth = 1.5; ctx.setLineDash([3, 2]);
      roundRect(ctx, p.x - 9, top, 18, p.y - top + 1, 6); ctx.stroke(); ctx.restore();
      this.drawBars(ctx, u, p.x, top - 4);
    }

    // ---------- Overlays ----------
    drawPreview(ctx, pv, placed) {
      const at = this.topPos(pv.tile);
      const pos = new Map(placed.map(x => [x.u, x.p]));
      const draw = (map, color, prefix, dy) => {
        for (const [o, ch] of map) {
          const p = pos.get(o); if (!p) continue;
          ctx.strokeStyle = color; ctx.lineWidth = 1.5; ctx.setLineDash([5, 4]); ctx.globalAlpha = 0.8;
          ctx.beginPath(); ctx.moveTo(at.x, at.y - 18); ctx.lineTo(p.x, p.y - 16); ctx.stroke();
          ctx.setLineDash([]); ctx.globalAlpha = 1;
          const label = `${prefix} ${ch}%`;
          ctx.font = 'bold 10px system-ui, sans-serif';
          const w = ctx.measureText(label).width + 8;
          ctx.fillStyle = 'rgba(10,14,24,0.85)';
          ctx.fillRect(p.x - w / 2, p.y - 58 - dy, w, 13);
          text(ctx, label, p.x, p.y - 51.5 - dy, color, 10, 'bold');
        }
      };
      draw(pv.threat, '#ff6b6b', '⚠', 0);
      draw(pv.hit, '#6fdc6f', '◎', 15);
    }

    drawPath(ctx, path) {
      ctx.strokeStyle = 'rgba(255,230,120,0.95)'; ctx.lineWidth = 2; ctx.setLineDash([4, 3]);
      ctx.beginPath();
      path.forEach((t, i) => { const p = this.topPos(t); i ? ctx.lineTo(p.x, p.y) : ctx.moveTo(p.x, p.y); });
      ctx.stroke(); ctx.setLineDash([]);
      const end = this.topPos(path[path.length - 1]);
      ctx.fillStyle = 'rgba(255,230,120,0.95)'; ctx.beginPath(); ctx.ellipse(end.x, end.y, 4, 2.5, 0, 0, 7); ctx.fill();
    }

    drawShots(ctx, now) {
      this.shots = this.shots.filter(s => now - s.t0 < 260);
      for (const s of this.shots) {
        const f = (now - s.t0) / 260;
        const a = this.unitPos(s.from), b = this.unitPos(s.to);
        const ay = a.y - 20, byy = b.y - 16;
        ctx.strokeStyle = s.color; ctx.lineWidth = 2.5; ctx.globalAlpha = 1 - f;
        ctx.shadowColor = s.color; ctx.shadowBlur = 6;
        ctx.beginPath(); ctx.moveTo(a.x, ay); ctx.lineTo(a.x + (b.x - a.x) * Math.min(1, f * 2), ay + (byy - ay) * Math.min(1, f * 2)); ctx.stroke();
        ctx.shadowBlur = 0; ctx.globalAlpha = 1;
      }
    }

    drawFx(ctx, now) {
      this.fx = this.fx.filter(e => now - e.t0 < e.dur);
      for (const e of this.fx) {
        const k = (now - e.t0) / e.dur, t = (now - e.t0) / 1000;
        if (e.type === 'flash') {
          const p = this.unitPos(e.unit), q = e.toward ? this.unitPos(e.toward) : p;
          const d = Math.hypot(q.x - p.x, q.y - p.y) || 1;
          const x = p.x + (q.x - p.x) / d * 14, y = p.y - 18 + (q.y - p.y) / d * 8;
          const g = ctx.createRadialGradient(x, y, 0, x, y, 10 * (1 - k) + 2);
          g.addColorStop(0, 'rgba(255,255,220,1)'); g.addColorStop(1, 'rgba(255,170,40,0)');
          ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, 10 * (1 - k) + 2, 0, 7); ctx.fill();
        } else if (e.type === 'sparks') {
          for (const s of e.parts) {
            ctx.globalAlpha = 1 - k; ctx.fillStyle = s.c;
            ctx.fillRect(e.x + s.vx * t - 1, e.y + s.vy * t + 60 * t * t - 1, 2.2, 2.2);
          }
          ctx.globalAlpha = 1;
        } else if (e.type === 'boom') {
          const r = 6 + 34 * Math.min(1, k * 2.5);
          ctx.globalAlpha = Math.max(0, 1 - k * 1.6);
          const g = ctx.createRadialGradient(e.x, e.y, 0, e.x, e.y, r);
          g.addColorStop(0, 'rgba(255,250,210,1)'); g.addColorStop(0.4, 'rgba(255,160,40,0.9)'); g.addColorStop(1, 'rgba(200,60,20,0)');
          ctx.fillStyle = g; ctx.beginPath(); ctx.ellipse(e.x, e.y, r, r * 0.75, 0, 0, 7); ctx.fill();
          ctx.globalAlpha = Math.max(0, 0.6 * (1 - k));
          for (const s of e.smoke) { ctx.fillStyle = '#3a3a3a'; ctx.beginPath(); ctx.arc(e.x + s.dx * k, e.y + s.dy * k - 20 * k, s.r * (0.5 + k), 0, 7); ctx.fill(); }
          ctx.globalAlpha = 1;
        }
      }
    }

    drawFloats(ctx, now) {
      this.floats = this.floats.filter(f => now - f.t0 < 1400);
      const stack = new Map();
      for (const f of this.floats) {
        const p = this.unitPos(f.unit);
        const n = stack.get(f.unit) || 0; stack.set(f.unit, n + 1);
        const k = (now - f.t0) / 1400;
        ctx.globalAlpha = 1 - k * k;
        text(ctx, f.text, p.x, p.y - 50 - k * 22 - n * 11, f.color, 11, 'bold', true);
        ctx.globalAlpha = 1;
      }
    }

    drawVignette(ctx) {
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      const w = this.canvas.width, h = this.canvas.height;
      const g = ctx.createRadialGradient(w / 2, h / 2, Math.min(w, h) * 0.35, w / 2, h / 2, Math.max(w, h) * 0.75);
      g.addColorStop(0, 'rgba(0,0,0,0)'); g.addColorStop(1, 'rgba(0,0,0,0.45)');
      ctx.fillStyle = g; ctx.fillRect(0, 0, w, h);
    }
  }

  // ---------- Zeichenhilfen ----------
  // Quader über dem Bodenrechteck [x0,x1]×[z0,z1] von Höhe h0 bis h1: Vorderseite und Oberseite
  function box(ctx, x0, x1, z0, z1, h0, h1, top, front) {
    poly(ctx, [P(x0, z1, h1), P(x1, z1, h1), P(x1, z1, h0), P(x0, z1, h0)], front);
    // leichte Schattierung nach unten
    const a = P(x0, z1, h1), b = P(x0, z1, h0);
    const g = ctx.createLinearGradient(a[0], a[1], b[0], b[1]);
    g.addColorStop(0, 'rgba(255,255,255,0.06)'); g.addColorStop(1, 'rgba(0,0,0,0.25)');
    poly(ctx, [P(x0, z1, h1), P(x1, z1, h1), P(x1, z1, h0), P(x0, z1, h0)], g);
    poly(ctx, [P(x0, z0, h1), P(x1, z0, h1), P(x1, z1, h1), P(x0, z1, h1)], top, 'rgba(0,0,0,0.3)');
  }
  function grating(ctx, x0, x1, z0, z1, h) {
    ctx.strokeStyle = 'rgba(0,0,0,0.18)'; ctx.lineWidth = 1;
    for (let x = x0 + 4; x < x1; x += 6) { ctx.beginPath(); ctx.moveTo(...P(x, z0, h)); ctx.lineTo(...P(x, z1, h)); ctx.stroke(); }
  }
  function hazard(ctx, pts) {
    ctx.save();
    ctx.beginPath(); pts.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.closePath(); ctx.clip();
    const xs = pts.map(p => p[0]), ys = pts.map(p => p[1]);
    const minX = Math.min(...xs), maxX = Math.max(...xs), minY = Math.min(...ys), maxY = Math.max(...ys);
    ctx.fillStyle = 'rgba(232,194,58,0.55)'; ctx.fillRect(minX, minY, maxX - minX, maxY - minY);
    ctx.strokeStyle = 'rgba(20,20,20,0.6)'; ctx.lineWidth = 3;
    for (let x = minX - 40; x < maxX; x += 8) { ctx.beginPath(); ctx.moveTo(x, maxY); ctx.lineTo(x + 20, minY); ctx.stroke(); }
    ctx.restore();
  }
  function poly(ctx, pts, fill, stroke) {
    ctx.beginPath(); pts.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.closePath();
    if (fill) { ctx.fillStyle = fill; ctx.fill(); }
    if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = 1; ctx.stroke(); }
  }
  function strokePoly(ctx, pts) { ctx.beginPath(); pts.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.closePath(); ctx.stroke(); }
  function barrel(ctx, x, y, color, warn) {
    const h = 0.8 * HS, rx = 6, ry = 3;
    ctx.fillStyle = shade(color, 0.75); ctx.fillRect(x - rx, y - h, rx * 2, h);
    ctx.beginPath(); ctx.ellipse(x, y, rx, ry, 0, 0, Math.PI); ctx.fill();
    ctx.fillStyle = 'rgba(0,0,0,0.25)'; ctx.fillRect(x - rx, y - h * 0.35, rx * 2, 1.5); ctx.fillRect(x - rx, y - h * 0.7, rx * 2, 1.5);
    ctx.fillStyle = color; ctx.beginPath(); ctx.ellipse(x, y - h, rx, ry, 0, 0, 7); ctx.fill();
    if (warn) { ctx.fillStyle = '#111'; ctx.beginPath(); ctx.moveTo(x, y - h * 0.62); ctx.lineTo(x - 3, y - h * 0.2); ctx.lineTo(x + 3, y - h * 0.2); ctx.closePath(); ctx.fill(); }
  }
  function roundRect(ctx, x, y, w, h, r) {
    ctx.beginPath(); ctx.moveTo(x + r, y); ctx.arcTo(x + w, y, x + w, y + h, r); ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r); ctx.arcTo(x, y, x + w, y, r); ctx.closePath();
  }
  function text(ctx, s, x, y, color, size, weight = '', outline = false) {
    ctx.font = `${weight} ${size}px system-ui, sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
    if (outline) { ctx.strokeStyle = 'rgba(0,0,0,0.85)'; ctx.lineWidth = 3; ctx.strokeText(s, x, y); }
    ctx.fillStyle = color; ctx.fillText(s, x, y);
  }
  function inPoly(x, y, pts) {
    let inside = false;
    for (let i = 0, j = pts.length - 1; i < pts.length; j = i++) {
      const [xi, yi] = pts[i], [xj, yj] = pts[j];
      if ((yi > y) !== (yj > y) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) inside = !inside;
    }
    return inside;
  }

  PTF.Renderer = Renderer;
})(window.PTF = window.PTF || {});
