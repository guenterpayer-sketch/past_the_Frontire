// Soundeffekte, synthetisch erzeugt mit der Web Audio API (keine Audiodateien nötig).
(function (PTF) {
  'use strict';
  const KEY = 'ptf.sound';

  const Sound = {
    ctx: null,
    on: (() => { try { return localStorage.getItem(KEY) !== 'aus'; } catch (e) { return true; } })(),

    toggle() {
      this.on = !this.on;
      try { localStorage.setItem(KEY, this.on ? 'an' : 'aus'); } catch (e) { /* ignorieren */ }
      return this.on;
    },

    // AudioContext erst nach einer Nutzeraktion anlegen (Browser-Vorgabe)
    ensure() {
      if (!this.ctx) {
        const AC = window.AudioContext || window.webkitAudioContext;
        if (!AC) return null;
        this.ctx = new AC();
        this.master = this.ctx.createGain();
        this.master.gain.value = 0.35;
        this.master.connect(this.ctx.destination);
        const len = this.ctx.sampleRate;
        this.noiseBuf = this.ctx.createBuffer(1, len, len);
        const d = this.noiseBuf.getChannelData(0);
        for (let i = 0; i < len; i++) d[i] = Math.random() * 2 - 1;
      }
      if (this.ctx.state === 'suspended') this.ctx.resume();
      return this.ctx;
    },

    // Rauschen durch einen Filter, mit abfallender Lautstärke
    noise(t0, dur, { type = 'bandpass', freq = 1000, freqEnd, q = 1, gain = 0.6 } = {}) {
      const c = this.ctx, src = c.createBufferSource(), f = c.createBiquadFilter(), g = c.createGain();
      src.buffer = this.noiseBuf;
      f.type = type; f.Q.value = q;
      f.frequency.setValueAtTime(freq, t0);
      if (freqEnd) f.frequency.exponentialRampToValueAtTime(freqEnd, t0 + dur);
      g.gain.setValueAtTime(gain, t0);
      g.gain.exponentialRampToValueAtTime(0.001, t0 + dur);
      src.connect(f); f.connect(g); g.connect(this.master);
      src.start(t0, Math.random() * 0.5); src.stop(t0 + dur + 0.05);
    },

    // Ton mit Frequenzverlauf
    tone(t0, dur, f0, f1, { type = 'sine', gain = 0.3 } = {}) {
      const c = this.ctx, o = c.createOscillator(), g = c.createGain();
      o.type = type;
      o.frequency.setValueAtTime(f0, t0);
      if (f1 && f1 !== f0) o.frequency.exponentialRampToValueAtTime(f1, t0 + dur);
      g.gain.setValueAtTime(0.0001, t0);
      g.gain.exponentialRampToValueAtTime(gain, t0 + 0.01);
      g.gain.exponentialRampToValueAtTime(0.001, t0 + dur);
      o.connect(g); g.connect(this.master);
      o.start(t0); o.stop(t0 + dur + 0.05);
    },

    play(name, delay = 0) {
      if (!this.on || !this.ensure()) return;
      const t = this.ctx.currentTime + delay;
      switch (name) {
        case 'gewehr':
          this.noise(t, 0.12, { freq: 1800, q: 0.7, gain: 0.8 });
          this.tone(t, 0.12, 140, 50, { type: 'triangle', gain: 0.5 });
          break;
        case 'mg':
          for (let i = 0; i < 4; i++) { this.noise(t + i * 0.07, 0.07, { freq: 1500, q: 0.8, gain: 0.7 }); this.tone(t + i * 0.07, 0.06, 120, 60, { type: 'triangle', gain: 0.35 }); }
          break;
        case 'laser':
          this.tone(t, 0.18, 1600, 280, { type: 'sawtooth', gain: 0.18 });
          this.tone(t, 0.18, 1200, 200, { type: 'square', gain: 0.08 });
          break;
        case 'psi':
          this.tone(t, 0.5, 220, 660, { type: 'sine', gain: 0.25 });
          this.tone(t + 0.05, 0.45, 330, 110, { type: 'triangle', gain: 0.15 });
          break;
        case 'rakete':
          this.noise(t, 0.3, { type: 'bandpass', freq: 400, freqEnd: 2500, q: 2, gain: 0.5 });
          this.play('explosion', delay + 0.28);
          break;
        case 'explosion':
          this.noise(t, 0.8, { type: 'lowpass', freq: 900, freqEnd: 120, q: 0.5, gain: 1 });
          this.tone(t, 0.7, 90, 30, { type: 'sine', gain: 0.6 });
          break;
        case 'nahkampf':
          this.noise(t, 0.12, { type: 'highpass', freq: 2500, freqEnd: 900, q: 0.5, gain: 0.4 });
          this.tone(t + 0.08, 0.1, 160, 70, { type: 'triangle', gain: 0.4 });
          break;
        case 'treffer':
          this.tone(t, 0.12, 180, 70, { type: 'triangle', gain: 0.45 });
          this.noise(t, 0.06, { type: 'lowpass', freq: 800, gain: 0.4 });
          break;
        case 'daneben':
          this.tone(t, 0.16, 2400, 900, { type: 'sine', gain: 0.07 });
          break;
        case 'krit':
          this.tone(t, 0.25, 880, 880, { type: 'triangle', gain: 0.2 });
          this.tone(t + 0.06, 0.3, 1320, 1320, { type: 'triangle', gain: 0.15 });
          break;
        case 'tod':
          this.tone(t, 0.7, 300, 55, { type: 'triangle', gain: 0.35 });
          break;
        case 'heilen':
          [523, 659, 784].forEach((f, i) => this.tone(t + i * 0.08, 0.25, f, f, { type: 'sine', gain: 0.18 }));
          break;
        case 'patzer':
          this.tone(t, 0.3, 110, 90, { type: 'square', gain: 0.12 });
          break;
        case 'schritt':
          this.noise(t, 0.04, { type: 'lowpass', freq: 700, gain: 0.25 });
          break;
        case 'ducken':
          this.noise(t, 0.1, { type: 'bandpass', freq: 600, freqEnd: 300, q: 1, gain: 0.3 });
          break;
        case 'wuerfel':
          // klackernde Würfel: kurze, hohe Klicks in unregelmäßigem Abstand
          for (let i = 0, dt = 0; i < 6; i++, dt += 0.045 + Math.random() * 0.05) this.noise(t + dt, 0.025, { type: 'bandpass', freq: 3000 + Math.random() * 2000, q: 4, gain: 0.35 - i * 0.04 });
          break;
        case 'alarm':
          this.tone(t, 0.08, 950, 950, { type: 'square', gain: 0.1 });
          this.tone(t + 0.1, 0.08, 700, 700, { type: 'square', gain: 0.1 });
          break;
        case 'runde':
          this.tone(t, 0.6, 220, 218, { type: 'sine', gain: 0.15 });
          this.tone(t, 0.6, 330, 328, { type: 'sine', gain: 0.07 });
          break;
        case 'nachladen':
          this.noise(t, 0.05, { type: 'highpass', freq: 3000, gain: 0.3 });
          this.noise(t + 0.15, 0.06, { type: 'highpass', freq: 2200, gain: 0.35 });
          break;
      }
    },

    // passenden Waffensound wählen
    weapon(w) {
      if (w.psi) return 'psi';
      if (w.melee) return 'nahkampf';
      if (w.splash) return 'rakete';
      if (w.table === 'strahl') return 'laser';
      if (w.ob) return 'mg';
      return 'gewehr';
    },
  };

  PTF.Sound = Sound;
})(window.PTF = window.PTF || {});
