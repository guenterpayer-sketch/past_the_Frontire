// Würfel: seedbarer Zufallsgenerator und offener W100 im Rolemaster-Stil.
(function (PTF) {
  'use strict';

  // Mulberry32 – kleiner, seedbarer PRNG
  function makeRng(seed) {
    let a = seed >>> 0;
    return function () {
      a = (a + 0x6d2b79f5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  const Dice = {
    rng: Math.random,
    setSeed(seed) { this.rng = makeRng(seed); },
    d(n) { return 1 + Math.floor(this.rng() * n); },
    // W10 mit den Seiten 0–9
    d10() { return Math.floor(this.rng() * 10); },
    // W100 wie in Rolemaster: ein W10 für die Zehner, einer für die Einer; 00 = 100
    d100() {
      const t = this.d10(), o = this.d10(), v = t * 10 + o || 100;
      if (this.pairs) this.pairs.push({ t, o, v });
      return v;
    },
    context: '',     // wer würfelt wofür (für die Würfelanzeige)
    onRoll: null,    // Rückruf für die Würfelanimation

    // Offener W100: 96–00 weiter würfeln und addieren, 01–05 erneut würfeln und abziehen
    // (auch der Abzug ist bei 96–00 offen). fumble > 0: unmodifizierter Wurf <= fumble ist ein Patzer.
    openD100(fumble = 0) {
      this.pairs = [];
      const res = this._open(fumble);
      res.dice = this.pairs;
      this.pairs = null;
      if (this.onRoll) this.onRoll({ ...res, label: this.context });
      return res;
    },
    _open(fumble) {
      const first = this.d100();
      const rolls = [first];
      let total = first;
      if (fumble > 0 && first <= fumble) return { first, rolls, total, fumble: true };
      if (first >= 96) {
        let r;
        do { r = this.d100(); rolls.push(r); total += r; } while (r >= 96);
      } else if (first <= 5) {
        let r;
        do { r = this.d100(); rolls.push(-r); total -= r; } while (r >= 96);
      }
      return { first, rolls, total, fumble: false };
    },
  };

  function formatRoll(roll) {
    if (roll.rolls.length === 1) return String(roll.first);
    return '(' + roll.rolls.map((r, i) => (i === 0 ? r : r < 0 ? `−${-r}` : `+${r}`)).join('') + `=${roll.total}, offen)`;
  }

  PTF.makeRng = makeRng;
  PTF.Dice = Dice;
  PTF.formatRoll = formatRoll;
})(window.PTF = window.PTF || {});
