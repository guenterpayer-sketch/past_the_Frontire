// Isometrische Hex-Darstellung auf Canvas: Höhenstufen als Säulen, einfache Formen für Gelände und Figuren.
(function (PTF) {
  'use strict';
  const { Hex, TERRAIN, MAP_CONST } = PTF;

  const R = 30;          // Hex-Radius in Pixeln (vor Skalierung)
  const SQ = 0.6;        // vertikale Stauchung (Iso-Blick)
  const HS = 14;         // Pixel pro Höhenstufe
  const BASE = 10;       // Sockeldicke
  const S3 = Math.sqrt(3);
  const ANG = [-90, -30, 30, 90, 150, 210].map(a => (a * Math.PI) / 180);

  function shade(hex, f) {
    const n = parseInt(hex.slice(1), 16);
    const ch = s => Math.max(0, Math.min(255, Math.round(((n >> s) & 255) * f)));
    return `rgb(${ch(16)},${ch(8)},${ch(0)})`;
  }

  class Renderer {
    constructor(canvas) {
      this.canvas = canvas;
      this.ctx = canvas.getContext('2d');
      this.floats = [];
      this.shots = [];
      this.scale = 1; this.ox = 0; this.oy = 0;
    }

    setMap(map) { this.map = map; this.rows = []; for (let r = 0; r < map.rows; r++) this.rows.push(map.list.filter(t => t.row === r)); this.resize(); }

    resize() {
      const c = this.canvas, dpr = window.devicePixelRatio || 1;
      const w = c.clientWidth, h = c.clientHeight;
      c.width = Math.round(w * dpr); c.height = Math.round(h * dpr);
      this.dpr = dpr;
      if (!this.map) return;
      let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
      for (const t of this.map.list) {
        const p = this.basePos(t);
        x0 = Math.min(x0, p.x - R); x1 = Math.max(x1, p.x + R);
        y0 = Math.min(y0, p.y - t.h * HS - R * SQ - (MAP_CONST.ROCK_H + 1) * HS);
        y1 = Math.max(y1, p.y + R * SQ + BASE);
      }
      const pad = 16;
      this.scale = Math.min((w - pad * 2) / (x1 - x0), (h - pad * 2) / (y1 - y0));
      this.ox = (w - (x1 - x0) * this.scale) / 2 - x0 * this.scale;
      this.oy = (h - (y1 - y0) * this.scale) / 2 - y0 * this.scale;
    }

    basePos(t) { return { x: R * S3 * (t.q + t.r / 2), y: R * 1.5 * SQ * t.r }; }
    topPos(t) { const p = this.basePos(t); return { x: p.x, y: p.y - t.h * HS }; }
    hexPts(cx, cy, dy = 0) { return ANG.map(a => [cx + R * Math.cos(a), cy + R * SQ * Math.sin(a) + dy]); }

    toScreen(p) { return { x: p.x * this.scale + this.ox, y: p.y * this.scale + this.oy }; }
    toWorld(x, y) { return { x: (x - this.ox) / this.scale, y: (y - this.oy) / this.scale }; }

    // ---- Picking ----
    silhouette(t) {
      const c = this.topPos(t), d = t.h * HS + BASE;
      const T = this.hexPts(c.x, c.y), B = this.hexPts(c.x, c.y, d);
      return [T[0], T[1], B[2], B[3], B[4], T[5]];
    }
    pickTile(mx, my) {
      const p = this.toWorld(mx, my);
      for (let r = this.rows.length - 1; r >= 0; r--) {
        for (const t of this.rows[r]) if (inPoly(p.x, p.y, this.silhouette(t))) return t;
      }
      return null;
    }

    pickUnit(mx, my) {
      if (!this.combat) return null;
      const p = this.toWorld(mx, my);
      const list = this.combat.units.filter(u => u.state !== 'dead').map(u => ({ u, q: this.unitPos(u) })).sort((a, b) => b.q.row - a.q.row);
      for (const { u, q } of list) if (Math.abs(p.x - q.x) <= 12 && p.y >= q.y - 32 && p.y <= q.y + 5) return u;
      return null;
    }

    // ---- Animationen ----
    addFloat(unit, text, color) { this.floats.push({ unit, text, color, t0: performance.now() }); }
    addShot(from, to, color) { this.shots.push({ from, to, color, t0: performance.now() }); }
    animateMove(unit, path) { unit.anim = { path, t0: performance.now(), step: 140 }; }
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
          const hop = Math.sin(k * Math.PI) * (path[i + 1].h !== path[i].h ? 10 : 3);
          return { x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k - hop, row: Math.max(path[i].row, path[i + 1].row) };
        }
      }
      const t = this.map.at(u.pos);
      return { ...this.topPos(t), row: t.row };
    }

    // ---- Zeichnen ----
    draw(view) {
      const ctx = this.ctx, now = performance.now();
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.fillStyle = '#0b0f1a';
      ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
      this.drawStars(ctx);
      ctx.setTransform(this.dpr * this.scale, 0, 0, this.dpr * this.scale, this.dpr * this.ox, this.dpr * this.oy);

      const units = this.combat ? this.combat.units : [];
      const placed = units.map(u => ({ u, p: this.unitPos(u) }));
      for (let r = 0; r < this.rows.length; r++) {
        for (const t of this.rows[r]) this.drawTile(ctx, t, view);
        placed.filter(x => x.p.row === r).sort((a, b) => (a.u.state === 'ok') - (b.u.state === 'ok'))
          .forEach(x => this.drawUnit(ctx, x.u, x.p, view, now));
      }
      if (view.path && view.path.length > 1) this.drawPath(ctx, view.path);
      this.drawShots(ctx, now);
      this.drawFloats(ctx, now);
    }

    drawStars(ctx) {
      if (!this.stars) {
        const rng = PTF.makeRng(7);
        this.stars = Array.from({ length: 120 }, () => [rng(), rng(), rng()]);
      }
      const w = this.canvas.width, h = this.canvas.height;
      for (const [x, y, b] of this.stars) { ctx.fillStyle = `rgba(200,210,255,${0.15 + b * 0.5})`; ctx.fillRect(x * w, y * h, 1.5, 1.5); }
    }

    drawTile(ctx, t, view) {
      const T = TERRAIN[t.terrain];
      const c = this.topPos(t);
      const d = t.h * HS + BASE;
      const top = this.hexPts(c.x, c.y), bot = this.hexPts(c.x, c.y, d);
      const light = 0.85 + t.h * 0.06;
      // Seitenflächen (nur die beiden vorderen sind sichtbar)
      poly(ctx, [top[2], top[3], bot[3], bot[2]], shade(T.side, 0.95));
      poly(ctx, [top[3], top[4], bot[4], bot[3]], shade(T.side, 0.75));
      // Höhenlinien an den Seiten
      ctx.strokeStyle = 'rgba(0,0,0,0.18)'; ctx.lineWidth = 1;
      for (let k = 1; k <= t.h; k++) {
        ctx.beginPath(); ctx.moveTo(top[2][0], top[2][1] + k * HS); ctx.lineTo(top[3][0], top[3][1] + k * HS); ctx.lineTo(top[4][0], top[4][1] + k * HS); ctx.stroke();
      }
      poly(ctx, top, shade(T.top, light), 'rgba(0,0,0,0.28)');

      // Hervorhebungen
      const k = Hex.key(t.q, t.r);
      let hl = null;
      if (view.reach && view.reach.has(k)) hl = 'rgba(80,165,255,0.42)';
      if (view.aidTiles && view.aidTiles.has(k)) hl = 'rgba(120,230,140,0.35)';
      if (view.hover === t) hl = 'rgba(255,255,255,0.28)';
      if (hl) poly(ctx, this.hexPts(c.x, c.y), hl);
      if (view.hover === t) { ctx.strokeStyle = '#fff'; ctx.lineWidth = 1.5; strokePoly(ctx, top); }

      // Geländedetails
      if (T.water) {
        ctx.strokeStyle = 'rgba(255,255,255,0.35)'; ctx.lineWidth = 1;
        for (const dy of [-4, 4]) { ctx.beginPath(); ctx.moveTo(c.x - 10, c.y + dy); ctx.quadraticCurveTo(c.x - 5, c.y + dy - 3, c.x, c.y + dy); ctx.quadraticCurveTo(c.x + 5, c.y + dy + 3, c.x + 10, c.y + dy); ctx.stroke(); }
      } else if (t.terrain === 'geroell') {
        ctx.fillStyle = 'rgba(60,55,50,0.55)';
        for (const [dx, dy, s] of [[-9, -2, 3], [6, -5, 2.5], [2, 5, 3.5], [-3, 8, 2], [11, 3, 2]]) { ctx.beginPath(); ctx.ellipse(c.x + dx, c.y + dy, s, s * 0.7, 0, 0, 7); ctx.fill(); }
      } else if (T.forest) {
        for (const [dx, dy, hgt] of [[-9, 2, 18], [4, -4, 22], [9, 6, 15], [-2, 8, 13]]) crystal(ctx, c.x + dx, c.y + dy, hgt);
      } else if (t.terrain === 'ruine') {
        const wh = 0.9 * HS;
        const inner = this.hexPts(c.x, c.y).map(([x, y]) => [c.x + (x - c.x) * 0.72, c.y + (y - c.y) * 0.72]);
        const raised = inner.map(([x, y]) => [x, y - wh]);
        poly(ctx, [raised[2], raised[3], inner[3], inner[2]], '#6e6a7b');
        poly(ctx, [raised[3], raised[4], inner[4], inner[3]], '#57536a');
        poly(ctx, raised, '#a9a5b6', 'rgba(0,0,0,0.3)');
        ctx.strokeStyle = 'rgba(0,0,0,0.25)';
        ctx.beginPath(); ctx.moveTo(raised[0][0], raised[0][1] + 4); ctx.lineTo(raised[3][0], raised[3][1] - 2); ctx.stroke();
      } else if (T.obstacle === 'high') {
        const hgt = MAP_CONST.ROCK_H * HS;
        ctx.beginPath();
        ctx.moveTo(c.x - 14, c.y + 3); ctx.lineTo(c.x - 4, c.y - hgt); ctx.lineTo(c.x + 2, c.y - hgt + 5); ctx.lineTo(c.x + 14, c.y + 2); ctx.closePath();
        ctx.fillStyle = '#6b5d51'; ctx.fill();
        ctx.beginPath(); ctx.moveTo(c.x - 4, c.y - hgt); ctx.lineTo(c.x + 2, c.y - hgt + 5); ctx.lineTo(c.x + 14, c.y + 2); ctx.lineTo(c.x + 2, c.y + 6); ctx.closePath();
        ctx.fillStyle = '#54483e'; ctx.fill();
      }
    }

    drawUnit(ctx, u, p, view, now) {
      const x = p.x, y = p.y;
      const enemy = u.team === 'enemy';
      if (u.state === 'dead') {
        ctx.strokeStyle = 'rgba(30,30,30,0.8)'; ctx.lineWidth = 3;
        ctx.beginPath(); ctx.moveTo(x - 7, y - 5); ctx.lineTo(x + 7, y + 5); ctx.moveTo(x + 7, y - 5); ctx.lineTo(x - 7, y + 5); ctx.stroke();
        return;
      }
      // Schatten
      ctx.fillStyle = 'rgba(0,0,0,0.35)';
      ctx.beginPath(); ctx.ellipse(x, y + 1, 12, 6, 0, 0, 7); ctx.fill();
      if (u.state === 'ko') {
        ctx.fillStyle = '#777'; ctx.strokeStyle = enemy ? '#ff5d5d' : '#5db7ff'; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.ellipse(x, y - 3, 13, 6, -0.15, 0, 7); ctx.fill(); ctx.stroke();
        text(ctx, 'z', x + 12, y - 12, '#ddd', 9);
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
      const bodyH = 26, w = 18, by = y - bodyH;
      // Körper
      ctx.fillStyle = enemy ? '#4a1414' : '#122a44';
      roundRect(ctx, x - w / 2, by, w, bodyH, 7); ctx.fill();
      ctx.fillStyle = u.color;
      roundRect(ctx, x - w / 2 + 2, by + 2, w - 4, bodyH - 4, 6); ctx.fill();
      ctx.strokeStyle = enemy ? '#ff5d5d' : '#5db7ff'; ctx.lineWidth = 2;
      roundRect(ctx, x - w / 2, by, w, bodyH, 7); ctx.stroke();
      if (u.shield) { ctx.fillStyle = '#9fb3c8'; ctx.beginPath(); ctx.ellipse(x - w / 2 - 1, by + 15, 4, 8, 0, 0, 7); ctx.fill(); }
      text(ctx, u.letter, x, by + 14, '#111', 12, 'bold');
      if (u.psiShield > 0) { ctx.strokeStyle = 'rgba(190,140,255,0.8)'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.ellipse(x, by + 12, 15, 18, 0, 0, 7); ctx.stroke(); }
      // Lebensbalken
      const f = Math.max(0, u.hp / u.maxHp);
      ctx.fillStyle = 'rgba(0,0,0,0.7)'; ctx.fillRect(x - 13, by - 8, 26, 4);
      ctx.fillStyle = f > 0.5 ? '#6fdc6f' : f > 0.25 ? '#ffd24a' : '#ff5a5a'; ctx.fillRect(x - 13, by - 8, 26 * f, 4);
      // Status-Symbole
      let sx = x - 13;
      const icon = (c, s) => { text(ctx, s, sx + 3, by - 13, c, 8, 'bold'); sx += 8; };
      if (u.bleed) icon('#ff4d4d', '♦');
      if (u.stun) icon('#ffd54f', '★');
      if (u.prone) icon('#bbb', '↓');
      if (u.defStance) icon('#7fc8ff', '◆');
    }

    drawPath(ctx, path) {
      ctx.strokeStyle = 'rgba(255,230,120,0.9)'; ctx.lineWidth = 2; ctx.setLineDash([4, 3]);
      ctx.beginPath();
      path.forEach((t, i) => { const p = this.topPos(t); i ? ctx.lineTo(p.x, p.y) : ctx.moveTo(p.x, p.y); });
      ctx.stroke(); ctx.setLineDash([]);
    }

    drawShots(ctx, now) {
      this.shots = this.shots.filter(s => now - s.t0 < 260);
      for (const s of this.shots) {
        const f = (now - s.t0) / 260;
        const a = this.unitPos(s.from), b = this.unitPos(s.to);
        const ay = a.y - 16, byy = b.y - 14;
        ctx.strokeStyle = s.color; ctx.lineWidth = 2.5; ctx.globalAlpha = 1 - f;
        ctx.beginPath(); ctx.moveTo(a.x, ay); ctx.lineTo(a.x + (b.x - a.x) * Math.min(1, f * 2), ay + (byy - ay) * Math.min(1, f * 2)); ctx.stroke();
        ctx.globalAlpha = 1;
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
        text(ctx, f.text, p.x, p.y - 44 - k * 22 - n * 11, f.color, 11, 'bold', true);
        ctx.globalAlpha = 1;
      }
    }
  }

  function poly(ctx, pts, fill, stroke) {
    ctx.beginPath(); pts.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.closePath();
    if (fill) { ctx.fillStyle = fill; ctx.fill(); }
    if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = 1; ctx.stroke(); }
  }
  function strokePoly(ctx, pts) { ctx.beginPath(); pts.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.closePath(); ctx.stroke(); }
  function crystal(ctx, x, y, h) {
    ctx.beginPath(); ctx.moveTo(x - 4, y); ctx.lineTo(x, y - h); ctx.lineTo(x + 4, y); ctx.closePath();
    ctx.fillStyle = '#7fe0b8'; ctx.fill();
    ctx.beginPath(); ctx.moveTo(x, y - h); ctx.lineTo(x + 4, y); ctx.lineTo(x, y + 1); ctx.closePath();
    ctx.fillStyle = '#3f9c7a'; ctx.fill();
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
