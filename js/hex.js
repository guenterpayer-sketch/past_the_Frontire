// Hex-Mathematik: axiale Koordinaten (q, r), Spitze oben, Karte im "odd-r"-Versatz.
(function (PTF) {
  'use strict';

  const DIRS = [[1, 0], [1, -1], [0, -1], [-1, 0], [-1, 1], [0, 1]];

  const Hex = {
    key(q, r) { return q + ',' + r; },
    fromOffset(col, row) { return { q: col - (row - (row & 1)) / 2, r: row }; },
    distance(a, b) {
      const dq = a.q - b.q, dr = a.r - b.r;
      return (Math.abs(dq) + Math.abs(dr) + Math.abs(dq + dr)) / 2;
    },
    neighbors(q, r) { return DIRS.map(([dq, dr]) => ({ q: q + dq, r: r + dr })); },
    round(fq, fr) {
      const fs = -fq - fr;
      let q = Math.round(fq), r = Math.round(fr), s = Math.round(fs);
      const dq = Math.abs(q - fq), dr = Math.abs(r - fr), ds = Math.abs(s - fs);
      if (dq > dr && dq > ds) q = -r - s;
      else if (dr > ds) r = -q - s;
      return { q, r };
    },
    // Hexfelder auf der Linie a→b inkl. Endpunkte. nudge verschiebt die Linie minimal,
    // damit Linien entlang von Hexkanten eindeutig werden (+1 / −1).
    line(a, b, nudge = 1) {
      const n = Hex.distance(a, b);
      const e = 1e-6 * nudge;
      const out = [];
      for (let i = 0; i <= n; i++) {
        const t = n === 0 ? 0 : i / n;
        out.push(Hex.round(a.q + e + (b.q - a.q) * t, a.r + e + (b.r - a.r) * t));
      }
      return out;
    },
  };

  PTF.Hex = Hex;
})(window.PTF = window.PTF || {});
