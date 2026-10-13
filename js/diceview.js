// Würfelanzeige: zwei W10 (rot = Zehner, weiß = Einer) rollen über die Karte.
// Zeigt jeden offenen W100 (Angriffe, Proben) mit allen Nachwürfen.
(function (PTF) {
  'use strict';
  const KEY = 'ptf.dice';
  const TUMBLE = 520;      // ms, erster Wurf
  const TUMBLE_NEXT = 380; // ms, jeder Nachwurf
  const HOLD = 900;        // ms, Ergebnis stehen lassen
  const FADE = 250;
  const MAX_QUEUE = 3;

  const el = (tag, cls, text) => { const e = document.createElement(tag); if (cls) e.className = cls; if (text !== undefined) e.textContent = text; return e; };
  const tensText = t => `${t}0`.padStart(2, '0');

  const DiceView = {
    on: (() => { try { return localStorage.getItem(KEY) !== 'aus'; } catch (e) { return true; } })(),
    queue: [],
    rolling: false,
    showing: false,
    root: null,
    waiters: [],

    init(stage) {
      this.root = el('div');
      this.root.id = 'dice';
      stage.appendChild(this.root);
      this.reduced = !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches);
    },

    toggle() {
      this.on = !this.on;
      try { localStorage.setItem(KEY, this.on ? 'an' : 'aus'); } catch (e) { /* ignorieren */ }
      if (!this.on) { this.queue = []; this.clear(); }
      return this.on;
    },

    // Solange die Würfel rollen, wartet der Kampf (KI-Zug, Spieler-Panel)
    busy() { return this.on && (this.rolling || this.queue.length > 0); },

    push(roll) {
      if (!this.on || !this.root || !roll.dice || !roll.dice.length) return;
      this.queue.push(roll);
      while (this.queue.length > MAX_QUEUE) this.queue.shift();
      if (!this.rolling) this.next();
    },

    // Ergebnis-Anzeigen (Schaden, Log) erst zeigen, wenn die Würfel liegen
    after(fn) { if (this.rolling) this.waiters.push(fn); else fn(); },
    flush() { const w = this.waiters; this.waiters = []; w.forEach(fn => fn()); },

    // Klick auf die Würfel blendet sie aus
    dismiss(card) {
      if (this.rolling || !card.isConnected) return;
      card.classList.add('out');
      this.timer = setTimeout(() => { if (card.isConnected) { this.root.innerHTML = ''; this.showing = false; } }, FADE);
    },

    clear() {
      clearTimeout(this.timer);
      clearInterval(this.spin);
      this.rolling = false;
      this.showing = false;
      if (this.root) this.root.innerHTML = '';
      this.flush();
    },

    next() {
      const roll = this.queue.shift();
      if (!roll) { this.rolling = false; return; }
      clearTimeout(this.timer);
      this.rolling = true;
      this.showing = true;
      this.root.innerHTML = '';
      const card = el('div', 'dice-card');
      card.title = 'Klicken zum Ausblenden';
      card.addEventListener('click', () => this.dismiss(card));
      if (roll.label) card.appendChild(el('div', 'dice-label', roll.label));
      const rows = el('div', 'dice-rows');
      card.appendChild(rows);
      const sum = el('div', 'dice-sum');
      card.appendChild(sum);
      this.root.appendChild(card);
      PTF.Sound.play('wuerfel');
      this.rollPair(roll, 0, rows, () => this.finish(roll, card, sum));
    },

    // Ein Würfelpaar rollen lassen, danach das nächste (offene Nachwürfe)
    rollPair(roll, i, rows, done) {
      const p = roll.dice[i];
      const row = el('div', 'dice-row');
      const sign = i === 0 ? '' : roll.rolls[i] < 0 ? '−' : '+';
      row.appendChild(el('span', 'dice-sign', sign));
      const tens = el('div', 'd10 tens'), ones = el('div', 'd10 ones');
      const tt = el('span', null, '00'), ot = el('span', null, '0');
      tens.appendChild(tt); ones.appendChild(ot);
      row.appendChild(tens); row.appendChild(ones);
      const val = el('span', 'dice-val', '');
      row.appendChild(val);
      rows.appendChild(row);
      if (i > 0) PTF.Sound.play('wuerfel');

      const settle = () => {
        clearInterval(this.spin);
        tens.classList.remove('roll'); ones.classList.remove('roll');
        tt.textContent = tensText(p.t);
        ot.textContent = String(p.o);
        val.textContent = `= ${p.v}`;
        if (p.v >= 96) row.classList.add('hi');
        else if (p.v <= 5 && i === 0) row.classList.add('lo');
        if (i + 1 < roll.dice.length) this.timer = setTimeout(() => this.rollPair(roll, i + 1, rows, done), 220);
        else done();
      };
      if (this.reduced) { settle(); return; }
      tens.classList.add('roll'); ones.classList.add('roll');
      ones.style.animationDelay = '40ms';
      this.spin = setInterval(() => {
        tt.textContent = tensText(Math.floor(Math.random() * 10));
        ot.textContent = String(Math.floor(Math.random() * 10));
      }, 55);
      this.timer = setTimeout(settle, i === 0 ? TUMBLE : TUMBLE_NEXT);
    },

    finish(roll, card, sum) {
      if (roll.fumble) { sum.textContent = 'Patzer!'; sum.classList.add('fumble'); }
      else if (roll.dice.length > 1) {
        sum.textContent = `Offener Wurf: ${roll.total}`;
        sum.classList.add(roll.total > roll.first ? 'up' : 'down');
      } else sum.textContent = `Wurf: ${roll.total}`;
      // Der Kampf darf weiterlaufen. Die Würfel bleiben liegen, bis man sie anklickt
      // oder der nächste Wurf sie ersetzt.
      this.rolling = this.queue.length > 0;
      if (!this.rolling) this.flush();
      else this.timer = setTimeout(() => this.next(), HOLD / 2);
    },
  };

  PTF.DiceView = DiceView;
})(window.PTF = window.PTF || {});
