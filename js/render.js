// Isometrische Hex-Darstellung auf Canvas: Höhenstufen als Säulen, einfache Formen für Hallenobjekte und Figuren.
// Kamera mit Zoom und Verschieben; verdeckte Figuren werden als Umriss gezeigt.
(function (PTF) {
  'use strict';
  const { Hex, TERRAIN } = PTF;

  const R = 30;          // Hex-Radius in Pixeln (vor Skalierung) – entspricht 1,5 m Feldbreite
  const SQ = 0.6;        // vertikale Stauchung (Iso-Blick)
  const HS = 22;         // Pixel pro Höhenstufe (1,5 m)
  const BASE = 6;        // Sockeldicke
  const MIN_SCALE = 0.62; // kleiner wird beim Einpassen nicht gezoomt (Lesbarkeit)
  const S3 = Math.sqrt(3);
  const ANG = [-90, -30, 30, 90, 150, 210].map(a => (a * Math.PI) / 180);

  const RANGE_COLORS = [null, '#6fdc6f', '#ffd24a', '#ff9a3c', '#ff5a5a'];

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
      this.zoom = 1;
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
      this.resize();
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
      // Mittelpunkt so begrenzen, dass die Halle nicht aus dem Bild geschoben wird
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
    // Kamera nur bewegen, wenn die Figur nahe am Rand oder außerhalb ist
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

    // ---- Picking ----
    silhouette(t) {
      const c = this.topPos(t), d = t.h * HS + BASE;
      const T = this.hexPts(c.x, c.y), B = this.hexPts(c.x, c.y, d);
      return [T[0], T[1], B[2], B[3], B[4], T[5]];
    }
    // prefer: Set von Feld-Schlüsseln (z. B. erreichbare Felder), deren Oberfläche Vorrang vor Verdeckern hat
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
      for (const { u, q } of list) if (Math.abs(p.x - q.x) <= 12 && p.y >= q.y - 34 && p.y <= q.y + 5) return u;
      return null;
    }

    // ---- Animationen ----
    addFloat(unit, text, color) { this.floats.push({ unit, text, color, t0: performance.now() }); }
    addShot(from, to, color) { this.shots.push({ from, to, color, t0: performance.now() }); }
    animateMove(unit, path) { unit.anim = { path, t0: performance.now(), step: 110 }; }
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
      ctx.setTransform(this.dpr * this.scale, 0, 0, this.dpr * this.scale, this.dpr * this.ox, this.dpr * this.oy);

      const units = this.combat ? this.combat.units : [];
      const placed = units.map(u => ({ u, p: this.unitPos(u) }));
      for (let r = 0; r < this.rows.length; r++) {
        for (const t of this.rows[r]) this.drawTile(ctx, t, view);
        placed.filter(x => x.p.row === r).sort((a, b) => (a.u.state === 'ok') - (b.u.state === 'ok'))
          .forEach(x => this.drawUnit(ctx, x.u, x.p, view, now));
      }
      // Umrisse aller Figuren obenauf, damit verdeckte sichtbar bleiben
      for (const { u, p } of placed) if (u.state === 'ok') this.drawGhost(ctx, u, p, view);
      if (view.path && view.path.length > 1) this.drawPath(ctx, view.path);
      if (view.preview) this.drawPreview(ctx, view.preview, placed);
      this.drawShots(ctx, now);
      this.drawFloats(ctx, now);
    }

    drawTile(ctx, t, view) {
      const T = TERRAIN[t.terrain];
      const c = this.topPos(t);
      const d = t.h * HS + BASE;
      const top = this.hexPts(c.x, c.y), bot = this.hexPts(c.x, c.y, d);
      const topCol = t.color || T.top;
      const sideCol = t.color || T.side, sideF = t.color ? 0.72 : 1;
      const light = 0.9 + t.h * 0.04;
      const wallTall = T.kind === 'wall' && t.row === 0;

      if (T.kind !== 'wall' || !wallTall) {
        poly(ctx, [top[2], top[3], bot[3], bot[2]], shade(sideCol, 0.95 * sideF));
        poly(ctx, [top[3], top[4], bot[4], bot[3]], shade(sideCol, 0.75 * sideF));
        poly(ctx, top, shade(topCol, light), 'rgba(0,0,0,0.22)');
      }
      // Oberflächen und Seiten je nach Objekt
      switch (T.kind) {
        case 'crate': this.crateDetail(ctx, top, bot); break;
        case 'container': ribs(ctx, top, bot, 7, 'rgba(0,0,0,0.25)'); ctx.strokeStyle = 'rgba(255,255,255,0.15)'; strokePoly(ctx, this.hexPts(c.x, c.y, 0, 0.8)); break;
        case 'shelf': shelves(ctx, top, bot, t.h); break;
        case 'gallery': grating(ctx, top); struts(ctx, top, bot); break;
        case 'stairs': steps(ctx, c); break;
        case 'ladder': this.ladder(ctx, t, c); break;
        case 'barrel': barrel(ctx, c.x - 7, c.y + 2, '#c9a227'); barrel(ctx, c.x + 6, c.y - 3, '#3b6ea8'); break;
        case 'barrier': prism(ctx, this.hexPts(c.x, c.y, 0, 0.7), 0.8 * HS, '#a3a3a8'); break;
        case 'pillar': prism(ctx, this.hexPts(c.x, c.y, 0, 0.35), 4 * HS, '#6d7580'); break;
        case 'wall': if (wallTall) prism(ctx, top, 3 * HS, '#4a4f58'); else { poly(ctx, top, '#3a3f48'); prism(ctx, this.hexPts(c.x, c.y, 0, 0.9), 0.4 * HS, '#4a4f58'); } break;
      }

      // Hervorhebungen
      const k = Hex.key(t.q, t.r);
      let hl = null;
      if (view.reach && view.reach.has(k)) hl = 'rgba(80,165,255,0.40)';
      if (view.aidTiles && view.aidTiles.has(k)) hl = 'rgba(120,230,140,0.40)';
      if (view.hover === t) hl = 'rgba(255,255,255,0.28)';
      if (hl) poly(ctx, this.hexPts(c.x, c.y), hl);
      if (view.range && view.range.has(k)) {
        ctx.fillStyle = RANGE_COLORS[view.range.get(k)] || '#ff5a5a';
        ctx.beginPath(); ctx.ellipse(c.x, c.y, 5, 5 * SQ, 0, 0, 7); ctx.fill();
        ctx.strokeStyle = 'rgba(0,0,0,0.5)'; ctx.lineWidth = 1; ctx.stroke();
      }
      if (view.hover === t) { ctx.strokeStyle = '#fff'; ctx.lineWidth = 1.5; strokePoly(ctx, top); }
    }

    crateDetail(ctx, top, bot) {
      ctx.strokeStyle = 'rgba(60,35,10,0.55)'; ctx.lineWidth = 1;
      ctx.beginPath(); ctx.moveTo(top[0][0], top[0][1]); ctx.lineTo(top[3][0], top[3][1]);
      ctx.moveTo(top[5][0], top[5][1]); ctx.lineTo(top[2][0], top[2][1]); ctx.stroke();
      ribs(ctx, top, bot, 3, 'rgba(60,35,10,0.45)');
    }

    ladder(ctx, t, c) {
      let up = 0;
      for (const n of Hex.neighbors(t.q, t.r)) { const x = this.map.get(n.q, n.r); if (x && TERRAIN[x.terrain].walk) up = Math.max(up, x.h - t.h); }
      const hgt = Math.max(1, up) * HS;
      ctx.strokeStyle = '#e8c23a'; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.moveTo(c.x - 5, c.y + 2); ctx.lineTo(c.x - 5, c.y - hgt); ctx.moveTo(c.x + 5, c.y + 2); ctx.lineTo(c.x + 5, c.y - hgt); ctx.stroke();
      ctx.lineWidth = 1.3;
      for (let y = c.y - 4; y > c.y - hgt; y -= 6) { ctx.beginPath(); ctx.moveTo(c.x - 5, y); ctx.lineTo(c.x + 5, y); ctx.stroke(); }
    }

    drawUnit(ctx, u, p, view, now) {
      const x = p.x, y = p.y;
      const enemy = u.team === 'enemy';
      if (u.state === 'dead') {
        ctx.strokeStyle = 'rgba(30,30,30,0.85)'; ctx.lineWidth = 3;
        ctx.beginPath(); ctx.moveTo(x - 7, y - 5); ctx.lineTo(x + 7, y + 5); ctx.moveTo(x + 7, y - 5); ctx.lineTo(x - 7, y + 5); ctx.stroke();
        return;
      }
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
      // Blickrichtung: Pfeil am Boden, Sichtfeld 180° als heller Halbkreis
      const ang = (Hex.dirAngle(u.facing) * Math.PI) / 180;
      const cx = Math.cos(ang), cy = Math.sin(ang);
      const pt = (along, side) => [x + cx * along - cy * side, y + 1 + (cy * along + cx * side) * SQ];
      ctx.fillStyle = enemy ? 'rgba(255,93,93,0.18)' : 'rgba(93,183,255,0.18)';
      ctx.beginPath(); ctx.ellipse(x, y + 1, 20, 20 * SQ, 0, ang - Math.PI / 2, ang + Math.PI / 2); ctx.lineTo(x, y + 1); ctx.fill();
      ctx.fillStyle = enemy ? '#ff7070' : '#7cc4ff';
      ctx.beginPath();
      ctx.moveTo(...pt(23, 0)); ctx.lineTo(...pt(13, -6)); ctx.lineTo(...pt(13, 6));
      ctx.closePath(); ctx.fill();
      const bodyH = u.crouched ? 19 : 28, w = 18, by = y - bodyH;
      ctx.fillStyle = enemy ? '#4a1414' : '#122a44';
      roundRect(ctx, x - w / 2, by, w, bodyH, 7); ctx.fill();
      ctx.fillStyle = u.color;
      roundRect(ctx, x - w / 2 + 2, by + 2, w - 4, bodyH - 4, 6); ctx.fill();
      ctx.strokeStyle = enemy ? '#ff5d5d' : '#5db7ff'; ctx.lineWidth = 2;
      roundRect(ctx, x - w / 2, by, w, bodyH, 7); ctx.stroke();
      if (u.shield) { ctx.fillStyle = '#9fb3c8'; ctx.beginPath(); ctx.ellipse(x - w / 2 - 1, by + 16, 4, 8, 0, 0, 7); ctx.fill(); }
      text(ctx, u.letter, x, by + bodyH / 2 + 1, '#111', 12, 'bold');
      if (u.psiShield > 0) { ctx.strokeStyle = 'rgba(190,140,255,0.8)'; ctx.lineWidth = 1.5; ctx.beginPath(); ctx.ellipse(x, by + 13, 15, 19, 0, 0, 7); ctx.stroke(); }
      this.drawBars(ctx, u, x, by);
    }

    drawBars(ctx, u, x, by) {
      const f = Math.max(0, u.hp / u.maxHp);
      ctx.fillStyle = 'rgba(0,0,0,0.7)'; ctx.fillRect(x - 13, by - 8, 26, 4);
      ctx.fillStyle = f > 0.5 ? '#6fdc6f' : f > 0.25 ? '#ffd24a' : '#ff5a5a'; ctx.fillRect(x - 13, by - 8, 26 * f, 4);
      let sx = x - 13;
      const icon = (c, s) => { text(ctx, s, sx + 3, by - 13, c, 8, 'bold'); sx += 8; };
      if (u.bleed) icon('#ff4d4d', '♦');
      if (u.stun) icon('#ffd54f', '★');
      if (u.prone) icon('#bbb', '↓');
      if (u.overwatch) icon('#ffd34d', '◎');
    }

    // halbtransparente Figur über allem: zeigt Figuren hinter Containern und Regalen.
    // Bei sichtbaren Figuren liegt sie deckungsgleich auf der echten Figur und fällt nicht auf.
    drawGhost(ctx, u, p, view) {
      const enemy = u.team === 'enemy';
      const w = 18, bodyH = u.crouched ? 19 : 28, x = p.x, by = p.y - bodyH;
      const edge = view.targets && view.targets.has(u) ? '#ff3030' : view.current === u ? '#ffd34d' : enemy ? '#ff5d5d' : '#5db7ff';
      ctx.save();
      ctx.globalAlpha = 0.5;
      ctx.fillStyle = u.color;
      roundRect(ctx, x - w / 2, by, w, bodyH, 7); ctx.fill();
      ctx.globalAlpha = 0.95;
      ctx.strokeStyle = edge; ctx.lineWidth = 2.5;
      roundRect(ctx, x - w / 2, by, w, bodyH, 7); ctx.stroke();
      ctx.restore();
      text(ctx, u.letter, x, by + bodyH / 2 + 1, '#111', 12, 'bold');
      this.drawBars(ctx, u, x, by);
    }

    // Linien und Chancen vom Zielfeld zu treffbaren Gegnern (grün) und Bedrohungen (rot)
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
          ctx.fillRect(p.x - w / 2, p.y - 54 - dy, w, 13);
          text(ctx, label, p.x, p.y - 47.5 - dy, color, 10, 'bold');
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
    }

    drawShots(ctx, now) {
      this.shots = this.shots.filter(s => now - s.t0 < 260);
      for (const s of this.shots) {
        const f = (now - s.t0) / 260;
        const a = this.unitPos(s.from), b = this.unitPos(s.to);
        const ay = a.y - 18, byy = b.y - 15;
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
        text(ctx, f.text, p.x, p.y - 46 - k * 22 - n * 11, f.color, 11, 'bold', true);
        ctx.globalAlpha = 1;
      }
    }
  }

  // ---- Zeichenhilfen ----
  function poly(ctx, pts, fill, stroke) {
    ctx.beginPath(); pts.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.closePath();
    if (fill) { ctx.fillStyle = fill; ctx.fill(); }
    if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = 1; ctx.stroke(); }
  }
  function strokePoly(ctx, pts) { ctx.beginPath(); pts.forEach(([x, y], i) => (i ? ctx.lineTo(x, y) : ctx.moveTo(x, y))); ctx.closePath(); ctx.stroke(); }
  // Prisma auf einer Grundfläche (Barriere, Säule, Wand)
  function prism(ctx, base, hgt, color) {
    const up = base.map(([x, y]) => [x, y - hgt]);
    poly(ctx, [up[2], up[3], base[3], base[2]], shade(color, 0.8));
    poly(ctx, [up[3], up[4], base[4], base[3]], shade(color, 0.62));
    poly(ctx, up, shade(color, 1.05), 'rgba(0,0,0,0.3)');
  }
  // senkrechte Rippen auf den beiden sichtbaren Seitenflächen
  function ribs(ctx, top, bot, n, color) {
    ctx.strokeStyle = color; ctx.lineWidth = 1;
    for (const [a, b] of [[2, 3], [3, 4]]) {
      for (let i = 1; i < n; i++) {
        const k = i / n;
        const x = top[a][0] + (top[b][0] - top[a][0]) * k;
        const y0 = top[a][1] + (top[b][1] - top[a][1]) * k;
        const y1 = bot[a][1] + (bot[b][1] - bot[a][1]) * k;
        ctx.beginPath(); ctx.moveTo(x, y0); ctx.lineTo(x, y1); ctx.stroke();
      }
    }
  }
  // Regalböden und bunte Kartons auf den Seitenflächen
  function shelves(ctx, top, bot, h) {
    const levels = h * 2;
    for (const [a, b] of [[2, 3], [3, 4]]) {
      for (let i = 0; i < levels; i++) {
        const y = i * (HS / 2);
        ctx.strokeStyle = 'rgba(230,140,40,0.75)'; ctx.lineWidth = 1.5;
        ctx.beginPath(); ctx.moveTo(top[a][0], top[a][1] + y); ctx.lineTo(top[b][0], top[b][1] + y); ctx.stroke();
        for (let j = 0; j < 3; j++) {
          if ((i * 3 + j + a) % 4 === 0) continue;
          const k0 = 0.12 + j * 0.3, k1 = k0 + 0.2;
          const x0 = top[a][0] + (top[b][0] - top[a][0]) * k0, x1 = top[a][0] + (top[b][0] - top[a][0]) * k1;
          const yb0 = top[a][1] + (top[b][1] - top[a][1]) * k0 + y + HS / 2 - 1, yb1 = top[a][1] + (top[b][1] - top[a][1]) * k1 + y + HS / 2 - 1;
          poly(ctx, [[x0, yb0], [x1, yb1], [x1, yb1 - 6], [x0, yb0 - 6]], (i + j) % 2 ? '#a07d50' : '#8a6a40');
        }
      }
    }
  }
  function grating(ctx, top) {
    ctx.strokeStyle = 'rgba(0,0,0,0.22)'; ctx.lineWidth = 1;
    for (let k = 0.2; k < 1; k += 0.2) {
      ctx.beginPath();
      ctx.moveTo(top[5][0] + (top[0][0] - top[5][0]) * k * 2, top[5][1] + (top[0][1] - top[5][1]) * k * 2);
      ctx.lineTo(top[4][0] + (top[2][0] - top[4][0]) * k, top[4][1] + (top[2][1] - top[4][1]) * k);
      ctx.stroke();
    }
  }
  function struts(ctx, top, bot) {
    ctx.strokeStyle = 'rgba(20,20,25,0.5)'; ctx.lineWidth = 2;
    for (const i of [2, 3, 4]) { ctx.beginPath(); ctx.moveTo(top[i][0], top[i][1] + 4); ctx.lineTo(bot[i][0], bot[i][1]); ctx.stroke(); }
    ctx.strokeStyle = 'rgba(220,190,60,0.6)'; ctx.lineWidth = 1.5;
    ctx.beginPath(); ctx.moveTo(top[2][0], top[2][1] + 3); ctx.lineTo(top[3][0], top[3][1] + 3); ctx.lineTo(top[4][0], top[4][1] + 3); ctx.stroke();
  }
  function steps(ctx, c) {
    ctx.strokeStyle = 'rgba(0,0,0,0.35)'; ctx.lineWidth = 1.5;
    for (const dy of [-7, -1, 5]) { ctx.beginPath(); ctx.moveTo(c.x - 16, c.y + dy); ctx.lineTo(c.x + 16, c.y + dy); ctx.stroke(); }
  }
  function barrel(ctx, x, y, color) {
    const h = 0.8 * HS, rx = 6, ry = 3;
    ctx.fillStyle = shade(color, 0.75); ctx.fillRect(x - rx, y - h, rx * 2, h);
    ctx.beginPath(); ctx.ellipse(x, y, rx, ry, 0, 0, Math.PI); ctx.fill();
    ctx.fillStyle = color; ctx.beginPath(); ctx.ellipse(x, y - h, rx, ry, 0, 0, 7); ctx.fill();
    ctx.strokeStyle = 'rgba(0,0,0,0.3)'; ctx.beginPath(); ctx.moveTo(x - rx, y - h / 2); ctx.lineTo(x + rx, y - h / 2); ctx.stroke();
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
