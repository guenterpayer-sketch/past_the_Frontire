// Steuerung und Oberfläche des Prototyps.
(function (PTF) {
  'use strict';
  const { Rules, Hex, WEAPONS, SKILLS, SKILL_GROUPS, ATTRIBUTES, ARMOR, TERRAIN, ATTACK_TABLES, CRIT_TABLES, CRIT_BANDS, FUMBLE_TABLE } = PTF;
  const $ = s => document.querySelector(s);
  const esc = s => String(s).replace(/[&<>"]/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[ch]));
  const fmt = v => (v >= 0 ? '+' + v : String(v));
  const STORE = 'ptf.crew.v1';
  const DIR_NAMES = ['O', 'NO', 'NW', 'W', 'SW', 'SO'];
  const FREE_XP = 3;

  function loadRoster() {
    const fresh = PTF.Units.clone(PTF.CREW_TEMPLATE);
    try {
      const s = localStorage.getItem(STORE);
      if (!s) return fresh;
      // gespeicherte Fertigkeiten behalten, Ausrüstung kommt immer aus der aktuellen Vorlage
      const saved = JSON.parse(s);
      return fresh.map(t => { const o = saved.find(x => x.id === t.id); if (o) t.skills = o.skills; return t; });
    } catch (e) { return fresh; }
  }
  function saveRoster(r) { try { localStorage.setItem(STORE, JSON.stringify(r)); } catch (e) { /* ignorieren */ } }

  const App = {
    init() {
      this.roster = loadRoster();
      this.canvas = $('#map');
      this.renderer = new PTF.Renderer(this.canvas);
      this.mode = 'move';
      this.auto = false;
      this.weaponSel = {};
      this.gait = 'gehen';
      this.pct = PTF.COMBAT.NORMAL_ATTACK;
      this.lastAi = 0;
      this.canvas.addEventListener('mousemove', e => this.onHover(e));
      this.canvas.addEventListener('mouseleave', () => { this.hover = null; this.hoverUnit = null; $('#tip').hidden = true; });
      this.canvas.addEventListener('click', e => this.onClick(e));
      this.canvas.addEventListener('wheel', e => { e.preventDefault(); const m = this.mouse(e); this.renderer.zoomAt(m.x, m.y, e.deltaY < 0 ? 1.15 : 1 / 1.15); }, { passive: false });
      // Ziehen mit gedrückter Maustaste verschiebt die Kamera
      this.canvas.addEventListener('mousedown', e => { this.drag = { x: e.clientX, y: e.clientY, moved: false }; });
      window.addEventListener('mouseup', () => { setTimeout(() => { this.drag = null; }, 0); });
      window.addEventListener('mousemove', e => {
        if (!this.drag || !(e.buttons & 1)) return;
        const dx = e.clientX - this.drag.x, dy = e.clientY - this.drag.y;
        if (!this.drag.moved && Math.hypot(dx, dy) < 6) return;
        this.drag.moved = true;
        this.renderer.panBy(dx, dy);
        this.drag.x = e.clientX; this.drag.y = e.clientY;
      });
      this.canvas.addEventListener('contextmenu', e => this.onRightClick(e));
      // Touch (Handy/Tablet): ziehen = verschieben, zwei Finger = zoomen, Tippen = Vorschau, 2. Tippen = ausführen, lange drücken = drehen
      this.canvas.addEventListener('touchstart', e => this.onTouchStart(e), { passive: false });
      this.canvas.addEventListener('touchmove', e => this.onTouchMove(e), { passive: false });
      this.canvas.addEventListener('touchend', e => this.onTouchEnd(e), { passive: false });
      this.canvas.addEventListener('touchcancel', e => this.onTouchEnd(e), { passive: false });
      window.addEventListener('resize', () => this.renderer.resize());
      document.addEventListener('keydown', e => this.onKey(e));
      $('#btn-new').onclick = () => this.newBattle(Math.floor(Math.random() * 1e6));
      const snd = () => { $('#btn-sound').textContent = `Ton: ${PTF.Sound.on ? 'an' : 'aus'}`; $('#btn-sound').classList.toggle('on', PTF.Sound.on); };
      $('#btn-sound').onclick = () => { PTF.Sound.toggle(); snd(); };
      snd();
      document.addEventListener('pointerdown', () => PTF.Sound.ensure(), { once: true });
      $('#btn-sheet').onclick = () => this.showSheet();
      $('#btn-tables').onclick = () => this.showTables();
      $('#btn-auto').onclick = () => { this.auto = !this.auto; $('#btn-auto').classList.toggle('on', this.auto); this.dirty = true; };
      $('#modal').addEventListener('click', e => { if (e.target.id === 'modal' || e.target.dataset.close !== undefined) this.closeModal(); });
      $('#panel').addEventListener('click', e => this.onPanelClick(e));
      PTF.DiceView.init($('#stage'));
      PTF.Dice.onRoll = roll => PTF.DiceView.push(roll);
      const dic = () => { $('#btn-dice').textContent = `Würfel: ${PTF.DiceView.on ? 'an' : 'aus'}`; $('#btn-dice').classList.toggle('on', PTF.DiceView.on); };
      $('#btn-dice').onclick = () => { PTF.DiceView.toggle(); dic(); };
      dic();
      this.newBattle(Math.floor(Math.random() * 1e6));
      requestAnimationFrame(t => this.frame(t));
    },

    newBattle(seed) {
      // Testmodus: Hallengröße pro Mission zufällig
      const size = PTF.MAP_SIZES[Math.floor(Math.random() * PTF.MAP_SIZES.length)];
      PTF.DiceView.queue = [];
      PTF.DiceView.clear();
      this.map = PTF.generateMap(seed, size.id);
      const m = PTF.MAP_CONST.HEX_M;
      $('#hall').textContent = `Lagerhalle ${size.name}, ca. ${Math.round(size.cols * m)}×${Math.round(size.rows * m * 0.866)} m`;
      this.freeLeft = {};
      this.reachCache = null;
      $('#log').innerHTML = '';
      this.combat = new PTF.Combat(this.map, this.roster, PTF.ENEMY_TEMPLATE, ev => this.onEvent(ev));
      this.renderer.combat = this.combat;
      this.renderer.setMap(this.map);
      this.closeModal();
      this.addLog(`Karte ${this.map.seed} (${size.name}): 6 Crewmitglieder gegen 6 Söldner der Roten Sonne in einer Lagerhalle.`, 'round');
      this.combat.start();
    },

    isAi(u) { return !!u && (u.team === 'enemy' || this.auto); },
    busy() { return this.renderer.busy() || PTF.DiceView.busy(); },
    playerTurn() { const c = this.combat, u = c.current; return u && !this.isAi(u) && !c.result && !this.busy() && u.state === 'ok'; },
    weaponOf(u) {
      const usable = this.combat.usableWeapons(u);
      let w = this.weaponSel[u.id] || u.weapon;
      if (!usable.includes(w)) w = usable[0] || u.weapons[0];
      return w;
    },
    // Aktivität für den Angriff: gewählter Wert, begrenzt durch das, was noch übrig ist (inkl. Waffenwechsel)
    maxAttackPct(u, wid) { return Math.min(100, Math.floor((u.act - (wid !== u.weapon ? PTF.COMBAT.COST.swap : 0)) / 10) * 10); },
    attackPct(u, wid) { return Math.max(PTF.COMBAT.MIN_ATTACK, Math.min(this.pct, this.maxAttackPct(u, wid))); },

    onEvent(ev) {
      // Treffer, Schaden und Log erst, wenn die Würfel liegen
      if ((ev.type === 'log' || ev.type === 'float' || ev.type === 'death') && PTF.DiceView.rolling) { PTF.DiceView.after(() => this.onEvent(ev)); return; }
      const r = this.renderer;
      switch (ev.type) {
        case 'log': this.addLog(ev.text, ev.cls); if (ev.cls === 'round') PTF.Sound.play('runde'); break;
        case 'float': {
          r.addFloat(ev.unit, ev.text, ev.color);
          const t = ev.text;
          if (t === 'daneben') PTF.Sound.play('daneben', 0.12);
          else if (t === 'Patzer') PTF.Sound.play('patzer');
          else if (t.startsWith('Krit')) PTF.Sound.play('krit', 0.18);
          else if (t.startsWith('+')) PTF.Sound.play('heilen');
          else if (t.startsWith('−') && ev.color !== '#ff6b6b') { PTF.Sound.play('treffer', 0.12); setTimeout(() => { r.addSparks(ev.unit, true); r.shake(2, 150); }, 120); }
          break;
        }
        case 'move': r.animateMove(ev.unit, ev.path); for (let i = 1; i < ev.path.length; i++) PTF.Sound.play('schritt', (i - 1) * 0.11); break;
        case 'death': PTF.Sound.play('tod', 0.2); break;
        case 'crouch': PTF.Sound.play('ducken'); break;
        case 'reload': PTF.Sound.play('nachladen'); break;
        case 'overwatchFire': PTF.Sound.play('alarm'); break;
        case 'attack': {
          const w = ev.weapon;
          PTF.Sound.play(PTF.Sound.weapon(w));
          if (w.splash) setTimeout(() => r.addExplosion(ev.target), 280);
          else if (!w.melee && !w.psi) setTimeout(() => r.addSparks(ev.target, false), 150);
          r.addShot(ev.unit, ev.target, w.psi ? '#c58bff' : w.melee ? '#ffffff' : w.table === 'strahl' ? '#ff5050' : w.splash ? '#ff9a3c' : '#ffe08a');
          break;
        }
        case 'turn': this.mode = 'move'; this.gait = 'gehen'; this.pct = PTF.COMBAT.NORMAL_ATTACK; r.ensureVisible(ev.unit); break;
        case 'end': { const cc = this.combat; setTimeout(() => { if (this.combat === cc) this.showEnd(); }, 1000); break; }
      }
      this.dirty = true;
    },

    frame(now) {
      // Ende einer Animation (Bewegung, Schuss) ändert, was der Spieler tun darf: Panel neu zeichnen
      const busy = this.busy();
      if (busy !== this.wasBusy) { this.wasBusy = busy; this.dirty = true; }
      this.tick(now);
      if (this.dirty) { this.updatePanel(); this.dirty = false; }
      this.renderer.draw(this.view());
      requestAnimationFrame(t => this.frame(t));
    },

    // KI-Züge ausführen; Spielerzüge enden nur per „Zug beenden“ (damit man sich am Ende noch drehen kann)
    tick(now) {
      const c = this.combat;
      if (!c || c.result || this.busy()) return;
      const u = c.current;
      if (!u) return;
      if (u.state !== 'ok') { c.endTurn(); this.dirty = true; return; }
      if (this.isAi(u) && now - this.lastAi > 380) {
        this.lastAi = now;
        const step = PTF.AI.planStep(c, u);
        if (step.type === 'end' || !PTF.AI.execute(c, u, step)) c.endTurn();
        this.dirty = true;
      }
    },

    view() {
      const c = this.combat, u = c.current;
      const v = { current: u, hover: this.hover };
      if (!this.playerTurn()) return v;
      if (this.mode === 'move' && c.canMove(u, this.gait)) {
        const key = [u.pos.q, u.pos.r, u.act, u.freeHex, u.moveSpare, this.gait].join('|');
        if (!this.reachCache || this.reachCache.u !== u || this.reachCache.key !== key) {
          this.reachCache = { u, key, reach: c.moveRange(u, this.gait) };
        }
        v.reach = this.reachCache.reach;
        if (this.hover && !this.hoverUnit && v.reach.has(Hex.key(this.hover.q, this.hover.r))) {
          v.path = this.map.pathTo(v.reach, this.hover);
          if (v.path.length > 1) v.preview = this.previewFor(u, this.hover, v.path, v.reach);
        }
      } else if (this.mode === 'move') this.reachCache = null;
      if (this.showRange) v.range = this.rangeFor(u, this.weaponOf(u));
      if (this.mode === 'aid') v.aidTiles = new Set(c.firstAidTargets(u).map(o => Hex.key(o.pos.q, o.pos.r)));
      if (this.mode === 'psi') v.aidTiles = new Set(c.psiShieldTargets(u).map(o => Hex.key(o.pos.q, o.pos.r)));
      if (c.canAttack(u)) {
        const w = this.weaponOf(u);
        if (this.maxAttackPct(u, w) >= PTF.COMBAT.MIN_ATTACK) {
          const pct = this.attackPct(u, w);
          v.targets = new Set(c.opponents(u).filter(t => c.attackInfo(u, t, w, { pct }).valid));
        }
      }
      return v;
    },

    // Vorschau für ein Zielfeld: wen kann ich von dort treffen, wer kann mich dort treffen?
    previewFor(u, tile, path, reach) {
      const c = this.combat, CB = PTF.COMBAT;
      const key = [u.id, tile.q, tile.r, u.act, u.freeHex, u.moveSpare, this.gait, this.weaponOf(u), c.round].join('|');
      if (this.previewCache && this.previewCache.key === key) return this.previewCache.val;
      const cost = reach.get(Hex.key(tile.q, tile.r)).cost;
      const left = u.act - c.movePct(u, this.gait, cost);
      const facing = Hex.dirToward(path[path.length - 2], path[path.length - 1]);
      const hit = new Map(), threat = new Map();
      if (!u.hasAttacked && !u.stunnedNow && this.gait !== 'sprinten') {
        const runMod = this.gait === 'laufen' && !u.ran ? CB.GAITS.laufen.attackMod : 0;
        for (const w of c.usableWeapons(u)) {
          const pct = Math.min(100, Math.floor((left - (w !== u.weapon ? CB.COST.swap : 0)) / 10) * 10);
          if (pct < CB.MIN_ATTACK) continue;
          for (const t of c.opponents(u)) {
            const info = c.attackInfo(u, t, w, { from: tile, pct });
            if (!info.valid) continue;
            const ch = Math.max(0, Math.min(100, info.chance + runMod));
            if (!hit.has(t) || ch > hit.get(t)) hit.set(t, ch);
          }
        }
      }
      for (const e of c.opponents(u)) {
        for (const w of c.usableWeapons(e)) {
          const info = c.attackInfo(e, u, w, { to: tile, defFacing: facing, pct: CB.NORMAL_ATTACK, preview: true });
          if (info.valid && (!threat.has(e) || info.chance > threat.get(e))) threat.set(e, info.chance);
        }
      }
      const val = { tile, hit, threat, left };
      this.previewCache = { key, val };
      return val;
    },

    // Reichweitenstufen der gewählten Waffe auf alle sichtbaren Felder (vom aktuellen Standort)
    rangeFor(u, wid) {
      const W = WEAPONS[wid];
      const key = [u.id, u.pos.q, u.pos.r, wid].join('|');
      if (this.rangeCache && this.rangeCache.key === key) return this.rangeCache.val;
      const val = new Map();
      if (!W.melee) {
        const from = this.combat.tileOf(u);
        for (const t of this.map.list) {
          if (!this.map.walkable(t) || t === from) continue;
          const m = Hex.distance(from, t) * PTF.MAP_CONST.HEX_M;
          const stage = Math.max(1, Math.ceil(m / W.inc));
          if (stage > W.stages || (W.minRange && m < W.minRange)) continue;
          if (this.map.lineOfSight(from, t).visible) val.set(Hex.key(t.q, t.r), stage);
        }
      }
      this.rangeCache = { key, val };
      return val;
    },

    preferTiles() {
      return this.playerTurn() && this.mode === 'move' && this.reachCache && this.reachCache.u === this.combat.current ? this.reachCache.reach : null;
    },

    mouse(e) { const r = this.canvas.getBoundingClientRect(); return { x: e.clientX - r.left, y: e.clientY - r.top }; },

    onHover(e) {
      const m = this.mouse(e);
      this.hoverUnit = this.renderer.pickUnit(m.x, m.y);
      this.hover = this.hoverUnit ? this.map.at(this.hoverUnit.pos) : this.renderer.pickTile(m.x, m.y, this.preferTiles());
      const tip = $('#tip');
      const html = this.tipHtml();
      if (!html) { tip.hidden = true; return; }
      tip.innerHTML = html;
      tip.hidden = false;
      const stage = $('#stage').getBoundingClientRect();
      const x = Math.min(m.x + 16, stage.width - tip.offsetWidth - 8);
      const y = Math.min(m.y + 16, stage.height - tip.offsetHeight - 8);
      tip.style.left = Math.max(8, x) + 'px';
      tip.style.top = Math.max(8, y) + 'px';
    },

    tipHtml() {
      const t = this.hover, o = this.hoverUnit, c = this.combat, u = c.current;
      if (!t) return '';
      const T = TERRAIN[t.terrain];
      let h = '';
      if (o) {
        const st = o.state === 'ok' ? '' : o.state === 'ko' ? ' – bewusstlos' : ' – tot';
        h += `<b>${esc(o.name)}</b> <small>${esc(o.role)}${st}</small><br>TP ${o.hp}/${o.maxHp}${o.maxPp ? ` · PP ${o.pp}/${o.maxPp}` : ''} · ${esc(ARMOR[o.armor].name)}`;
        if (o !== u && o.state === 'ok') h += `<br><small>Ausweichreserve ${o.reserve || 0} %</small>`;
        const s = statusList(o);
        if (s.length) h += `<br><small>${s.join(' · ')}</small>`;
        if (this.playerTurn() && o.team !== u.team) {
          const w = this.weaponOf(u);
          const info = c.attackInfo(u, o, w, { pct: this.attackPct(u, w) });
          if (!info.valid) h += `<div class="tip-bad">Kein Angriff: ${esc(info.reason)}</div>`;
          else if (!c.canAttack(u)) h += `<div class="tip-bad">Kein Angriff mehr in dieser Runde${u.sprinted ? ' (gesprintet)' : ''}</div>`;
          else if (this.maxAttackPct(u, w) < PTF.COMBAT.MIN_ATTACK) h += `<div class="tip-bad">Zu wenig Aktivität für einen Angriff (mind. ${PTF.COMBAT.MIN_ATTACK} %)</div>`;
          else h += attackBreakdown(info);
        }
      }
      const hm = (t.h * PTF.MAP_CONST.HEX_M).toLocaleString('de-DE');
      let info = `${esc(T.name)} · Höhe ${t.h} (${hm} m) · ${T.walk ? `Kosten ${T.cost}` : 'nicht begehbar'}`;
      if (u && !o && !this.isAi(u)) {
        const d = Hex.distance(u.pos, t) * PTF.MAP_CONST.HEX_M;
        info += ` · ${d.toLocaleString('de-DE')} m entfernt`;
        const reach = this.preferTiles();
        const e = reach && reach.get(Hex.key(t.q, t.r));
        if (e && e.cost > 0) {
          const pct = c.movePct(u, this.gait, e.cost);
          info += `<br><b>${PTF.COMBAT.GAITS[this.gait].name}:</b> ${e.cost} Hex-Kosten = <b>${pct} %</b> Aktivität (bleiben ${u.act - pct} %)`;
          const path = this.map.pathTo(reach, t);
          const pv = path.length > 1 ? this.previewFor(u, t, path, reach) : null;
          if (pv) {
            const list = m => [...m].sort((a, b) => b[1] - a[1]).map(([o, ch]) => `${esc(o.name)} ${ch} %`).join(', ');
            info += `<div class="pv-hit">Von hier treffbar: ${pv.hit.size ? list(pv.hit) : '<i>niemand</i>'}</div>`;
            info += `<div class="pv-threat">Gefahr dort: ${pv.threat.size ? list(pv.threat) : '<i>niemand sieht das Feld</i>'}</div>`;
          }
        }
      }
      h += `<div class="tip-tile">${info}</div>`;
      return h;
    },

    onClick(e) {
      if (this.drag && this.drag.moved) return;
      if (!this.playerTurn()) return;
      const c = this.combat, u = c.current, m = this.mouse(e);
      let target = this.renderer.pickUnit(m.x, m.y);
      const w = this.weaponOf(u);
      // im Bewegungsmodus fangen eigene Figuren keinen Klick ab
      if (target && this.mode === 'move' && target.team === u.team) target = null;
      // Gegner, der gerade nicht angreifbar ist: Klick gilt dem Feld darunter
      if (target && this.mode === 'move' && target.team !== u.team &&
          (!c.canAttack(u) || target.state !== 'ok' || this.maxAttackPct(u, w) < PTF.COMBAT.MIN_ATTACK ||
           !c.attackInfo(u, target, w, { pct: this.attackPct(u, w) }).valid)) target = null;
      const tile = target ? this.map.at(target.pos) : this.renderer.pickTile(m.x, m.y, this.preferTiles());
      if (this.mode === 'face') { if (tile) c.doFace(u, Hex.dirToward(u.pos, tile)); this.mode = 'move'; }
      else if (this.mode === 'aid') { if (target && c.doFirstAid(u, target)) this.mode = 'move'; }
      else if (this.mode === 'psi') { if (target && c.doPsiShield(u, target)) this.mode = 'move'; }
      else if (target && target.team !== u.team) c.doAttack(u, target, w, this.attackPct(u, w));
      else if (tile) c.doMove(u, tile, this.gait);
      $('#tip').hidden = true;
      this.dirty = true;
    },

    // ---------- Touch ----------
    onTouchStart(e) {
      e.preventDefault();
      this.touchUsed = true;
      PTF.Sound.ensure();
      const ts = e.touches;
      clearTimeout(this.longTimer);
      if (ts.length === 1) {
        const t = ts[0];
        this.touch = { x: t.clientX, y: t.clientY, moved: false, long: false };
        const pt = { clientX: t.clientX, clientY: t.clientY, preventDefault() {} };
        this.longTimer = setTimeout(() => {
          if (!this.touch || this.touch.moved) return;
          this.touch.long = true;
          this.onRightClick(pt);
          if (navigator.vibrate) navigator.vibrate(20);
        }, 550);
      } else if (ts.length === 2) {
        if (this.touch) this.touch.moved = true;
        this.pinch = this.pinchState(ts);
      }
    },

    pinchState(ts) {
      const r = this.canvas.getBoundingClientRect();
      const [a, b] = [ts[0], ts[1]];
      return { d: Math.hypot(a.clientX - b.clientX, a.clientY - b.clientY), x: (a.clientX + b.clientX) / 2 - r.left, y: (a.clientY + b.clientY) / 2 - r.top };
    },

    onTouchMove(e) {
      e.preventDefault();
      const ts = e.touches;
      if (ts.length === 2 && this.pinch) {
        const p = this.pinchState(ts);
        if (this.pinch.d > 0) this.renderer.zoomAt(p.x, p.y, p.d / this.pinch.d);
        this.renderer.panBy(p.x - this.pinch.x, p.y - this.pinch.y);
        this.pinch = p;
        return;
      }
      if (ts.length === 1 && this.touch) {
        const t = ts[0], dx = t.clientX - this.touch.x, dy = t.clientY - this.touch.y;
        if (!this.touch.moved && Math.hypot(dx, dy) < 10) return;
        this.touch.moved = true;
        clearTimeout(this.longTimer);
        this.renderer.panBy(dx, dy);
        this.touch.x = t.clientX; this.touch.y = t.clientY;
      }
    },

    onTouchEnd(e) {
      e.preventDefault();
      clearTimeout(this.longTimer);
      if (e.touches.length === 1) {
        // von zwei auf einen Finger: weiter verschieben, aber kein Tippen mehr
        this.pinch = null;
        const t = e.touches[0];
        this.touch = { x: t.clientX, y: t.clientY, moved: true, long: false };
        return;
      }
      if (e.touches.length > 0) return;
      const t = this.touch;
      this.touch = null; this.pinch = null;
      const ct = e.changedTouches[0];
      if (t && !t.moved && !t.long && ct) this.onTap({ clientX: ct.clientX, clientY: ct.clientY, preventDefault() {} });
    },

    // erstes Tippen: Vorschau/Tooltip wie beim Überfahren mit der Maus; zweites Tippen auf dasselbe Ziel: ausführen
    onTap(ev) {
      this.onHover(ev);
      const key = this.hoverUnit ? 'u:' + this.hoverUnit.id : this.hover ? Hex.key(this.hover.q, this.hover.r) : null;
      if (key && key === this.tapKey) {
        this.tapKey = null;
        $('#tip').hidden = true;
        this.onClick(ev);
      } else {
        this.tapKey = key;
      }
      this.dirty = true;
    },

    // Rechtsklick: Figur in Richtung des Feldes drehen (kostenlos)
    onRightClick(e) {
      e.preventDefault();
      if (!this.playerTurn()) return;
      const m = this.mouse(e), u = this.combat.current;
      const tile = this.renderer.pickTile(m.x, m.y);
      if (tile && (tile.q !== u.pos.q || tile.r !== u.pos.r)) this.combat.doFace(u, Hex.dirToward(u.pos, tile));
      this.dirty = true;
    },

    onKey(e) {
      if (e.target.tagName === 'SELECT' || e.target.tagName === 'INPUT') return;
      if (e.key === 'Escape') { if (!$('#modal').hidden) this.closeModal(); else this.mode = 'move'; }
      if (e.key === 'Enter' && this.playerTurn()) this.combat.endTurn();
      if (e.key === 'r' || e.key === 'R') this.showRange = !this.showRange;
      if (e.key === 'g' || e.key === 'G') this.renderer.showGrid = !this.renderer.showGrid;
      const pan = { ArrowLeft: [60, 0], ArrowRight: [-60, 0], ArrowUp: [0, 60], ArrowDown: [0, -60], a: [60, 0], d: [-60, 0], w: [0, 60], s: [0, -60] }[e.key];
      if (pan) { e.preventDefault(); this.renderer.panBy(pan[0], pan[1]); }
      if (e.key === '+') this.renderer.zoomAt(this.renderer.w / 2, this.renderer.h / 2, 1.2);
      if (e.key === '-') this.renderer.zoomAt(this.renderer.w / 2, this.renderer.h / 2, 1 / 1.2);
      this.dirty = true;
    },

    onPanelClick(e) {
      const b = e.target.closest('[data-act]');
      if (!b || b.disabled) return;
      const c = this.combat, u = c.current, act = b.dataset.act;
      if (act === 'sheet') return this.showSheet(b.dataset.id);
      if (act === 'grid') { this.renderer.showGrid = !this.renderer.showGrid; this.dirty = true; return; }
      if (act === 'jump') { const j = c.units.find(o => o.id === b.dataset.id); if (j && !this.isAi(j)) c.requestJump(j); this.dirty = true; return; }
      if (!this.playerTurn()) return;
      switch (act) {
        case 'weapon': this.weaponSel[u.id] = b.dataset.w; break;
        case 'gait': this.gait = b.dataset.g; this.mode = 'move'; break;
        case 'pct': this.pct = Number(b.dataset.p); break;
        case 'overwatch': c.doOverwatch(u, this.weaponOf(u)); break;
        case 'reload': c.doReload(u, b.dataset.w); break;
        case 'aid': this.mode = this.mode === 'aid' ? 'move' : 'aid'; break;
        case 'psi': this.mode = this.mode === 'psi' ? 'move' : 'psi'; break;
        case 'face': this.mode = this.mode === 'face' ? 'move' : 'face'; break;
        case 'end': c.endTurn(); break;
        case 'crouch': c.doCrouch(u); break;
        case 'range': this.showRange = !this.showRange; break;
        case 'grid': this.renderer.showGrid = !this.renderer.showGrid; break;
        case 'wait': c.doWait(u); break;
      }
      this.dirty = true;
    },

    // ---------- Panel ----------
    updatePanel() {
      const c = this.combat, u = c.current, CB = PTF.COMBAT;
      $('#round').textContent = c.round;
      $('#order').innerHTML = c.order.map((o, i) =>
        `<li class="${o.team} ${o.state !== 'ok' ? 'out' : ''} ${i === c.turnIdx ? 'now' : ''} ${i < c.turnIdx ? 'done' : ''}" title="Initiative ${o.initRoll}">
          <span class="badge" style="background:${o.color}">${o.letter}</span><span>${esc(o.name)}${o.overwatch ? ' ◎' : ''}${o.crouched ? ' ▾' : ''}</span>${o.waiting ? (c.jumpQueue.includes(o) ? '<span class="wait">springt ein</span>' : !this.isAi(o) ? `<button class="mini jump" data-act="jump" data-id="${o.id}" title="Nach dem laufenden Zug einspringen">einspringen</button>` : '<span class="wait">wartet</span>') : ''}<span class="ini">${o.init}</span></li>`).join('');
      if (!u) { $('#unit').innerHTML = ''; return; }
      const ai = this.isAi(u);
      const w = this.weaponOf(u);
      const player = this.playerTurn();
      const dis = cond => (!player || !cond ? 'disabled' : '');
      const dodge = Math.max(0, Rules.skillTotal(u, 'ausweichen'));
      const vw = Math.floor(dodge / 2) + Math.floor((dodge / 2) * Math.max(0, u.act) / 100) + (ARMOR[u.armor].db || 0);
      const canAtk = c.canAttack(u) && this.maxAttackPct(u, w) >= CB.MIN_ATTACK;
      const pct = this.attackPct(u, w);
      const status = statusList(u);
      const reload = c.reloadable(u);
      const freeMove = u.freeHex + u.moveSpare;
      $('#unit').innerHTML = `
        <div class="unit-head ${u.team}">
          <span class="badge big" style="background:${u.color}">${u.letter}</span>
          <div><b>${esc(u.name)}</b><small>${esc(u.role)} · ${u.team === 'crew' ? 'Crew' : 'Gegner'}</small></div>
          ${u.isCrew ? `<button class="mini" data-act="sheet" data-id="${u.id}" title="Charakterbogen">Bogen</button>` : ''}
        </div>
        ${bar('TP', u.hp, u.maxHp, 'hp')}
        ${u.maxPp ? bar('PP', u.pp, u.maxPp, 'pp') : ''}
        ${bar(`Aktivität ${Math.max(0, u.act)} %${freeMove ? ` + ${freeMove} Hex frei` : ''}`, Math.max(0, u.act), 100, 'act', true)}
        <div class="stats">
          <span title="Gesamtbonus der Waffenfertigkeit">AW <b>${Rules.skillTotal(u, WEAPONS[w].skill)}</b></span>
          <span title="Ausweichen ½ + ½ × übrige Aktivität, + Rüstung (ohne Deckung/Schild)">VW <b>${vw}</b></span>
          <span title="Initiative diese Runde">INI <b>${u.init}</b></span>
          <span title="Blickrichtung (Rechtsklick dreht)">Blick <b>${DIR_NAMES[u.facing]}</b></span>
        </div>
        <div class="status">${status.map(s => `<span class="chip">${s}</span>`).join('') || '<span class="muted">keine Effekte</span>'}</div>
        ${ai ? `<div class="ai-note">${u.team === 'enemy' ? 'Gegner' : 'KI'} ist am Zug …</div>` : `
        <div class="sub">Waffe <small>(Wechsel beim Angriff −${CB.COST.swap} %)</small></div>
        <div class="weapons">${u.weapons.map(id => {
          const W = WEAPONS[id];
          const extra = W.mag ? ` (${u.loaded[id]}/${W.mag}, Reserve ${u.ammo[id]})` : W.pp ? ` (${W.pp} PP)` : '';
          const usable = c.usableWeapons(u).includes(id);
          return `<button data-act="weapon" data-w="${id}" class="${id === w ? 'sel' : ''}" ${!usable || !player ? 'disabled' : ''}>${esc(W.name)}${extra}${id === u.weapon ? ' ✓' : ''}<small>${W.melee ? 'Nahkampf' : `${W.inc} m/Stufe, max ${W.inc * W.stages} m`}</small></button>`;
        }).join('')}</div>
        <div class="sub">Gangart</div>
        <div class="seg">${Object.entries(CB.GAITS).map(([id, g]) => `<button data-act="gait" data-g="${id}" class="${this.gait === id ? 'sel' : ''}" ${dis(c.canMove(u, id))} title="${g.pace} Hex je 10 %${g.attackMod ? `, danach Angriff ${g.attackMod}` : ''}${g.noAttack ? ', kein Angriff in dieser Runde' : ''}${u.crouched ? ' – geduckt nur Gehen mit 1 Hex je 20 %' : ''}">${g.name}<small>${u.crouched ? (id === 'gehen' ? '1 Hex/20 %' : 'geduckt –') : `${g.pace} Hex/10 %`}</small></button>`).join('')}</div>
        <div class="sub">Angriff mit <b>${pct} %</b> Aktivität (${fmt(CB.activityMod(pct))})</div>
        <div class="seg pct">${[20, 30, 40, 50, 60, 70, 80, 90, 100].map(p => `<button data-act="pct" data-p="${p}" class="${pct === p && canAtk ? 'sel' : ''}" ${dis(canAtk && p <= this.maxAttackPct(u, w))}>${p}<small>${fmt(CB.activityMod(p))}</small></button>`).join('')}</div>
        <div class="buttons">
          <button data-act="crouch" class="${u.crouched ? 'sel' : ''}" ${dis(c.canCrouch(u))} title="Geduckt: +${CB.CROUCH.db} VW gegen Fernkampf, +${CB.CROUCH.ob} AW im Fernkampf, halbe Deckung zählt als volle. Nur Gehen mit halber Geschwindigkeit. Nahkämpfer bekommen +${CB.CROUCH.meleeOb} gegen Geduckte.">${u.crouched ? 'Aufstehen' : 'Ducken'} (${CB.COST.crouch} %)</button>
          <button data-act="wait" ${dis(c.canWait(u))} title="Zug nach hinten schieben. Über die Initiative-Liste („einspringen“) nach jedem anderen Zug einsetzen; sonst am Rundenende. Kostet ${CB.COST.wait} %, nur bevor die Figur etwas getan hat.">Abwarten (${CB.COST.wait} %)</button>
          <button data-act="overwatch" ${dis(c.canOverwatch(u, w))} title="Restliche Aktivität (mind. ${CB.MIN_OVERWATCH} %) zurückhalten: Schuss auf den ersten Gegner, der im Sichtfeld handelt. ${CB.REACTION_MOD} Reaktion. Beendet den Zug.">Feuerbereitschaft</button>
          ${reload.map(id => `<button data-act="reload" data-w="${id}" ${dis(c.canDo(u, CB.COST.reload))}>Nachladen (${CB.COST.reload} %)</button>`).join('')}
          <button data-act="aid" class="${this.mode === 'aid' ? 'sel' : ''}" ${dis(c.canDo(u, CB.COST.aid) && c.firstAidTargets(u).length)} title="Benachbarte Figur behandeln (Erste Hilfe, Mittel)">Erste Hilfe (${CB.COST.aid} %)</button>
          ${Rules.skillRank(u, 'psiWirken') > 0 ? `<button data-act="psi" class="${this.mode === 'psi' ? 'sel' : ''}" ${dis(c.canDo(u, CB.COST.psi) && c.psiShieldTargets(u).length)} title="Psi wirken, 2 PP: +20 VW für bis zu 3 Runden, Reichweite 4">Psi-Schild (${CB.COST.psi} %)</button>` : ''}
          <button data-act="range" class="${this.showRange ? 'sel' : ''}" ${dis(true)} title="Taste R. Zeigt, welche Felder die gewählte Waffe von hier sieht – Punktfarbe = Reichweitenstufe: grün ±0, gelb −20, orange −40, rot −60.">Reichweite (R)</button>
          <button data-act="grid" class="${this.renderer.showGrid ? 'sel' : ''}" title="Taste G: Hexraster ein-/ausblenden">Raster (G)</button>
          <button data-act="face" class="${this.mode === 'face' ? 'sel' : ''}" ${dis(true)} title="Feld anklicken, in dessen Richtung die Figur schauen soll (kostenlos). Alternativ: Rechtsklick auf ein Feld.">Ausrichten</button>
          <button data-act="end" class="end ${u.act < 10 && !freeMove ? 'pulse' : ''}" ${dis(true)} title="Enter. Übrige Aktivität zählt bis zum nächsten Zug als Ausweichen.">Zug beenden${u.act > 0 ? ` (${u.act} % → Ausweichen)` : ''}</button>
        </div>
        <div class="hint">${this.hintText(u)}</div>`}`;
    },

    hintText(u) {
      if (this.mode === 'aid') return 'Grün markierte Figur anklicken. Esc bricht ab.';
      if (this.mode === 'psi') return 'Grün markierte Figur für den Psi-Schild anklicken.';
      if (this.mode === 'face') return 'Feld anklicken, in dessen Richtung die Figur schauen soll.';
      if (this.touchUsed) return 'Handy: ziehen = Karte verschieben, zwei Finger = zoomen. Feld/Gegner antippen = Vorschau, nochmal antippen = ausführen. Lange drücken = Figur in diese Richtung drehen.';
      return 'Maus über ein blaues Feld: grüne Linien = von dort treffbar, rote Linien = wer dich dort treffen kann (mit Chance). Blaue Felder: Bewegung (Kosten im Tooltip). Rot umrandet: angreifbar. Rechtsklick: Figur drehen. Sichtfeld 180° nach vorne – Angriffe von der Seite (+15) oder hinten (+30) überraschen.';
    },

    addLog(text, cls = '') {
      const log = $('#log');
      const div = document.createElement('div');
      div.className = 'l ' + cls;
      div.textContent = text;
      log.appendChild(div);
      while (log.childNodes.length > 400) log.removeChild(log.firstChild);
      log.scrollTop = log.scrollHeight;
    },

    // ---------- Modals ----------
    openModal(html, wide) {
      $('#modal-body').innerHTML = html;
      $('#modal-box').classList.toggle('wide', !!wide);
      $('#modal').hidden = false;
    },
    closeModal() { $('#modal').hidden = true; },

    crewUnit(id) { return this.combat.crew().find(u => u.id === id); },

    showSheet(id) {
      const list = this.combat.crew();
      id = id || (this.combat.current && this.combat.current.isCrew ? this.combat.current.id : list[0].id);
      const u = this.crewUnit(id);
      const tabs = list.map(o => `<button data-sheet="${o.id}" class="${o.id === id ? 'sel' : ''}">${esc(o.name)}</button>`).join('');
      this.openModal(`<div class="tabs">${tabs}</div>${sheetHtml(u)}<div class="modal-foot"><button data-close>Schließen</button></div>`, true);
      $('#modal-body').querySelectorAll('[data-sheet]').forEach(b => (b.onclick = () => this.showSheet(b.dataset.sheet)));
    },

    showTables(wid) {
      wid = wid || 'sturmgewehr';
      const opts = Object.entries(WEAPONS).map(([id, w]) => `<option value="${id}" ${id === wid ? 'selected' : ''}>${esc(w.name)}</option>`).join('');
      this.openModal(`<h2>Tabellen</h2>
        <label>Waffe: <select id="tbl-w">${opts}</select></label>
        ${attackTableHtml(wid)}
        <h3>Kritische Treffer</h3>
        <p class="muted">W100 (geschlossen) + Grad: A −20, B −10, C ±0, D +10, E +20</p>
        ${critTablesHtml()}
        <h3>Patzer (W100)</h3>
        <table class="tbl"><tr><th>Wurf</th><th>Folge</th></tr>${FUMBLE_TABLE.map((f, i) => `<tr><td>${i ? FUMBLE_TABLE[i - 1].upTo + 1 : 1}–${f.upTo}</td><td>${esc(f.text)}</td></tr>`).join('')}</table>
        <div class="modal-foot"><button data-close>Schließen</button></div>`, true);
      $('#tbl-w').onchange = e => this.showTables(e.target.value);
    },

    showEnd() {
      const c = this.combat;
      const win = c.result === 'sieg';
      this.freeLeft = this.freeLeft || {};
      for (const u of c.crew()) if (this.freeLeft[u.id] === undefined) this.freeLeft[u.id] = FREE_XP;
      const rows = c.crew().map(u => {
        const gains = Object.entries(u.xpLog).sort((a, b) => b[1] - a[1]);
        const st = u.state === 'ok' ? 'kampffähig' : u.state === 'ko' ? 'bewusstlos' : 'tot';
        const skillRows = gains.map(([sid, n]) => skillXpRow(u, sid, n)).join('');
        const freeOpts = SKILL_GROUPS.map(g => `<optgroup label="${esc(g.name)}">${g.skills.map(s => `<option value="${s.id}">${esc(s.name)}</option>`).join('')}</optgroup>`).join('');
        return `<div class="xp-card">
          <div class="unit-head crew"><span class="badge" style="background:${u.color}">${u.letter}</span><div><b>${esc(u.name)}</b><small>${esc(u.role)} · ${st} · ${u.kills} Gegner ausgeschaltet</small></div></div>
          <table class="tbl small"><tr><th>Fertigkeit</th><th>+EP</th><th>EP / Kosten</th><th>Rang</th><th></th></tr>${skillRows || '<tr><td colspan="5" class="muted">keine Fertigkeit benutzt</td></tr>'}</table>
          <div class="free">Freier Pool: <b>${this.freeLeft[u.id]}</b> EP
            <select data-free-sel="${u.id}" ${this.freeLeft[u.id] ? '' : 'disabled'}>${freeOpts}</select>
            <button data-free="${u.id}" ${this.freeLeft[u.id] ? '' : 'disabled'}>vergeben</button></div>
        </div>`;
      }).join('');
      this.openModal(`<h2 class="${win ? 'win' : 'lose'}">${win ? 'Sieg!' : 'Niederlage'}</h2>
        <p>Runde ${c.round}. Erfahrung gab es nur für Fertigkeiten, die benutzt wurden. Ränge kosten 10 + 2 × aktueller Rang.</p>
        <p class="muted">Prototyp: Tote und Bewusstlose stehen im nächsten Kampf wieder voll bereit (Regeln für Heilung, Tod und Ersatz sind noch offen).</p>
        <div class="xp-grid">${rows}</div>
        <div class="modal-foot">
          <button id="btn-reset" class="danger">Crew zurücksetzen</button>
          <button id="btn-next" class="primary">Fortschritt speichern & nächster Kampf</button>
        </div>`, true);
      const body = $('#modal-body');
      body.querySelectorAll('[data-rank]').forEach(b => (b.onclick = () => {
        Rules.rankUp(this.crewUnit(b.dataset.unit), b.dataset.rank);
        this.syncRoster(); this.showEnd();
      }));
      body.querySelectorAll('[data-free]').forEach(b => (b.onclick = () => {
        const u = this.crewUnit(b.dataset.free);
        const sid = body.querySelector(`[data-free-sel="${u.id}"]`).value;
        Rules.ensureSkill(u, sid).xp += this.freeLeft[u.id];
        u.xpLog[sid] = (u.xpLog[sid] || 0) + this.freeLeft[u.id];
        this.freeLeft[u.id] = 0;
        this.syncRoster(); this.showEnd();
      }));
      $('#btn-next').onclick = () => { this.syncRoster(); this.freeLeft = {}; this.newBattle(Math.floor(Math.random() * 1e6)); };
      $('#btn-reset').onclick = () => {
        if (!confirm('Alle Fortschritte der Crew verwerfen?')) return;
        this.roster = PTF.Units.clone(PTF.CREW_TEMPLATE); saveRoster(this.roster); this.freeLeft = {};
        this.newBattle(Math.floor(Math.random() * 1e6));
      };
    },

    syncRoster() {
      for (const u of this.combat.crew()) {
        const r = this.roster.find(x => x.id === u.id);
        if (r) r.skills = PTF.Units.clone(u.skills);
      }
      saveRoster(this.roster);
    },
  };

  // ---------- HTML-Bausteine ----------
  function bar(label, v, max, cls, plain) {
    const f = Math.max(0, Math.min(1, v / max));
    return `<div class="bar ${cls}"><span>${label}${plain ? '' : ` ${v}/${max}`}</span><i style="width:${f * 100}%"></i></div>`;
  }

  function statusList(u) {
    const s = [];
    if (u.bleed) s.push(`Blutung ${u.bleed}`);
    if (u.stun) s.push(`Betäubt ${u.stun}`);
    if (u.malus) s.push(`Wunden ${u.malus}`);
    if (u.prone) s.push('Niedergeworfen');
    if (u.overwatch) s.push(`Feuerbereitschaft ${u.overwatch.pct} %`);
    if (u.crouched) s.push('geduckt');
    if (u.waiting) s.push('wartet ab');
    if (u.medkit) s.push(`Medikit ${u.medkit}×`);
    if (u.ran) s.push('gelaufen (Angriff −20)');
    if (u.sprinted) s.push('gesprintet (kein Angriff)');
    if (u.psiShield) s.push(`Psi-Schild ${u.psiShield}`);
    if (u.nextAttackMalus) s.push(`Waffe klemmt ${u.nextAttackMalus}`);
    return s;
  }

  function attackBreakdown(info) {
    const li = m => `<li><span>${esc(m.label)}</span><b>${fmt(m.val)}</b></li>`;
    const sumOb = info.ob.reduce((s, m) => s + m.val, 0), sumDb = info.db.reduce((s, m) => s + m.val, 0);
    const cls = info.chance >= 60 ? 'good' : info.chance >= 35 ? 'mid' : 'bad';
    const surprise = info.surprised && !info.weapon.psi ? `<div class="tip-warn">Überraschung (${info.sector === 'flanke' ? 'Flanke' : 'Rücken'}): Ziel weicht nicht aus, kein Schild. Eine gelungene Kampfsinn-Probe des Ziels halbiert das Ausweichen.</div>` : '';
    return `<div class="tip-attack"><div class="chance ${cls}">Trefferchance ≈ ${info.chance}% <small>(${info.pct} % Aktivität)</small></div>${surprise}
      <small>W100 offen ${fmt(info.net)} ≥ ${info.thr} (${esc(ATTACK_TABLES[info.weapon.table].name)}) · Patzer 01–${String(info.weapon.fumble).padStart(2, '0')}</small>
      <div class="cols"><ul><li class="h"><span>Angriff</span><b>${sumOb}</b></li>${info.ob.map(li).join('')}</ul>
      <ul><li class="h"><span>Verteidigung</span><b>${sumDb}</b></li>${info.db.map(li).join('')}</ul></div></div>`;
  }

  function skillXpRow(u, sid, gained) {
    const s = Rules.ensureSkill(u, sid);
    const cost = Rules.rankCost(s.rank);
    const can = s.xp >= cost;
    return `<tr><td>${esc(SKILLS[sid].name)}</td><td>+${gained}</td><td>${s.xp} / ${cost}</td><td>${s.rank}</td>
      <td>${can ? `<button class="mini primary" data-unit="${u.id}" data-rank="${sid}">Rang ${s.rank + 1}</button>` : ''}</td></tr>`;
  }

  function sheetHtml(u) {
    const attrs = ATTRIBUTES.map(a => `<tr><td>${a.name}</td><td>${u.attrs[a.id]}</td><td>${fmt(Rules.attrBonus(u.attrs[a.id]))}</td></tr>`).join('');
    const groups = SKILL_GROUPS.map(g => `<div class="skill-group"><h4>${esc(g.name)}</h4><table class="tbl small">
      <tr><th>Fertigkeit</th><th>Eig.</th><th>Rang</th><th>Rangb.</th><th>Eig.b.</th><th>Gesamt</th><th>EP</th></tr>
      ${g.skills.map(s => {
        const r = Rules.skillRank(u, s.id), xp = (u.skills[s.id] && u.skills[s.id].xp) || 0;
        const ab = Rules.attrBonus(u.attrs[s.attrs[0]]) + Rules.attrBonus(u.attrs[s.attrs[1]]);
        const short = s.attrs.map(a => ATTRIBUTES.find(x => x.id === a).short).join('+');
        return `<tr class="${r ? '' : 'muted'}"><td>${esc(s.name)}</td><td>${short}</td><td>${r}</td><td>${fmt(Rules.rankBonus(r))}</td><td>${fmt(ab)}</td><td><b>${fmt(Rules.skillTotal(u, s.id))}</b></td><td>${xp}/${Rules.rankCost(r)}</td></tr>`;
      }).join('')}</table></div>`).join('');
    const weapons = u.weapons.map(w => WEAPONS[w].name).join(', ');
    return `<div class="sheet">
      <div class="sheet-side">
        <h2>${esc(u.name)}</h2><p class="muted">${esc(u.role)}</p>
        <table class="tbl small"><tr><th>Eigenschaft</th><th>Wert</th><th>Bonus</th></tr>${attrs}</table>
        <h4>Abgeleitete Werte</h4>
        <table class="tbl small">
          <tr><td>Trefferpunkte</td><td>${u.maxHp} (tot bei ${Rules.deathAt(u)})</td></tr>
          <tr><td>Psi-Punkte</td><td>${u.maxPp}</td></tr>
          <tr><td>Bewegung</td><td>Gehen 1 Hex je 10 % Aktivität (15 m/Runde) + ${Math.max(0, Math.floor(Rules.attrBonus(u.attrs.GEW) / 5) + (ARMOR[u.armor].move || 0))} Hex frei</td></tr>
          <tr><td>Initiative</td><td>2W10 ${fmt(Rules.initiativeBonus(u))}</td></tr>
          <tr><td>Rüstung</td><td>${esc(ARMOR[u.armor].name)}</td></tr>
          <tr><td>Waffen</td><td>${esc(weapons)}${u.shield ? ', Schild' : ''}</td></tr>
        </table>
      </div>
      <div class="sheet-skills">${groups}</div></div>`;
  }

  function attackTableHtml(wid) {
    const w = WEAPONS[wid];
    let rows = '';
    for (let total = 50; total <= 155; total += 5) {
      const over = total > w.max;
      rows += `<tr class="${over ? 'muted' : ''}"><td>${total}${over ? '*' : ''}</td>` + [0, 1, 2, 3].map(cls => {
        const r = PTF.Tables.lookupAttack(w.table, Math.min(total, w.max), cls, w.dmg);
        return `<td>${r.hit ? r.dmg + (r.severity ? ' ' + r.severity : '') : '–'}</td>`;
      }).join('') + '</tr>';
    }
    const range = w.melee ? 'Nahkampf (benachbart)' : `Reichweite ${w.inc} m je Stufe, ${w.stages} Stufen (max. ${w.inc * w.stages} m), je Stufe ab der 2. ${PTF.Tables.RANGE_STEP}, bis ${PTF.Tables.POINT_BLANK_M} m +10${w.minRange ? `, Mindestabstand ${w.minRange} m` : ''}`;
    return `<p class="muted">${range}.<br>Tabelle ${esc(ATTACK_TABLES[w.table].name)}, Fertigkeit ${esc(SKILLS[w.skill].name)}, Schadensfaktor ${w.dmg}, Maximalergebnis ${w.max} (*: wird auf ${w.max} begrenzt), Patzer 01–${String(w.fumble).padStart(2, '0')}. Eintrag: TP und Kritischer Grad.</p>
      <table class="tbl small center"><tr><th>Ergebnis</th>${PTF.ARMOR_CLASSES.map(a => `<th>${a}</th>`).join('')}</tr>${rows}</table>`;
  }

  function critTablesHtml() {
    const bands = ['01–20', '21–40', '41–60', '61–80', '81–95', '96–110', '111+'];
    return `<div class="crit-grid">${Object.values(CRIT_TABLES).map(t => `<div><h4>${esc(t.name)}</h4><table class="tbl small">${t.rows.map((r, i) => {
      const fx = [];
      if (r.kill) fx.push('tot');
      if (r.dmg) fx.push(`+${r.dmg} TP`);
      if (r.bleed) fx.push(`Blutung ${r.bleed}`);
      if (r.stun) fx.push(`betäubt ${r.stun}`);
      if (r.malus) fx.push(`${r.malus}`);
      if (r.prone) fx.push('niedergeworfen');
      if (r.ko) fx.push('bewusstlos');
      return `<tr><td>${bands[i]}</td><td>${esc(r.text)}<br><small>${fx.join(', ')}</small></td></tr>`;
    }).join('')}</table></div>`).join('')}</div>`;
  }

  PTF.App = App;
  window.addEventListener('DOMContentLoaded', () => App.init());
})(window.PTF = window.PTF || {});
