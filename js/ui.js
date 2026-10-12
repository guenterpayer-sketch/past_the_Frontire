// Steuerung und Oberfläche des Prototyps.
(function (PTF) {
  'use strict';
  const { Rules, Hex, WEAPONS, SKILLS, SKILL_GROUPS, ATTRIBUTES, ARMOR, TERRAIN, ATTACK_TABLES, CRIT_TABLES, CRIT_BANDS, FUMBLE_TABLE } = PTF;
  const $ = s => document.querySelector(s);
  const esc = s => String(s).replace(/[&<>"]/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[ch]));
  const fmt = v => (v >= 0 ? '+' + v : String(v));
  const STORE = 'ptf.crew.v1';
  const FREE_XP = 3;

  function loadRoster() {
    try { const s = localStorage.getItem(STORE); if (s) return JSON.parse(s); } catch (e) { /* kein Speicher verfügbar */ }
    return PTF.Units.clone(PTF.CREW_TEMPLATE);
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
      this.endAt = 0; this.lastAi = 0;
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
      this.canvas.addEventListener('contextmenu', e => { e.preventDefault(); this.mode = 'move'; this.dirty = true; });
      window.addEventListener('resize', () => this.renderer.resize());
      document.addEventListener('keydown', e => this.onKey(e));
      $('#btn-new').onclick = () => this.newBattle(Math.floor(Math.random() * 1e6));
      $('#btn-sheet').onclick = () => this.showSheet();
      $('#btn-tables').onclick = () => this.showTables();
      $('#btn-auto').onclick = () => { this.auto = !this.auto; $('#btn-auto').classList.toggle('on', this.auto); this.dirty = true; };
      $('#modal').addEventListener('click', e => { if (e.target.id === 'modal' || e.target.dataset.close !== undefined) this.closeModal(); });
      $('#panel').addEventListener('click', e => this.onPanelClick(e));
      this.newBattle(Math.floor(Math.random() * 1e6));
      requestAnimationFrame(t => this.frame(t));
    },

    newBattle(seed) {
      // Testmodus: Hallengröße pro Mission zufällig
      const size = PTF.MAP_SIZES[Math.floor(Math.random() * PTF.MAP_SIZES.length)];
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
    playerTurn() { const c = this.combat, u = c.current; return u && !this.isAi(u) && !c.result && !this.renderer.busy() && u.actions > 0; },
    weaponOf(u) {
      const usable = this.combat.usableWeapons(u);
      let w = this.weaponSel[u.id];
      if (!w || !usable.includes(w)) w = usable[0] || u.weapons[0];
      return w;
    },

    onEvent(ev) {
      const r = this.renderer;
      switch (ev.type) {
        case 'log': this.addLog(ev.text, ev.cls); break;
        case 'float': r.addFloat(ev.unit, ev.text, ev.color); break;
        case 'move': r.animateMove(ev.unit, ev.path); break;
        case 'attack': {
          const w = ev.weapon;
          r.addShot(ev.unit, ev.target, w.psi ? '#c58bff' : w.melee ? '#ffffff' : w.table === 'strahl' ? '#ff5050' : w.splash ? '#ff9a3c' : '#ffe08a');
          break;
        }
        case 'turn': this.mode = 'move'; r.ensureVisible(ev.unit); break;
        case 'end': { const cc = this.combat; setTimeout(() => { if (this.combat === cc) this.showEnd(); }, 1000); break; }
      }
      this.dirty = true;
    },

    frame(now) {
      this.tick(now);
      if (this.dirty) { this.updatePanel(); this.dirty = false; }
      this.renderer.draw(this.view());
      requestAnimationFrame(t => this.frame(t));
    },

    tick(now) {
      const c = this.combat;
      if (!c || c.result || this.renderer.busy()) return;
      const u = c.current;
      if (!u) return;
      if (u.actions <= 0) {
        if (!this.endAt) this.endAt = now + (this.isAi(u) ? 250 : 400);
        if (now >= this.endAt) { this.endAt = 0; c.endTurn(); }
        return;
      }
      this.endAt = 0;
      if (this.isAi(u) && now - this.lastAi > 420) {
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
      if (this.mode === 'move') {
        if (!this.reachCache || this.reachCache.u !== u || this.reachCache.key !== Hex.key(u.pos.q, u.pos.r) + u.actions) {
          this.reachCache = { u, key: Hex.key(u.pos.q, u.pos.r) + u.actions, reach: c.moveRange(u) };
        }
        v.reach = this.reachCache.reach;
        if (this.hover && !this.hoverUnit && v.reach.has(Hex.key(this.hover.q, this.hover.r))) v.path = this.map.pathTo(v.reach, this.hover);
      }
      if (this.mode === 'aid') v.aidTiles = new Set(c.firstAidTargets(u).map(o => Hex.key(o.pos.q, o.pos.r)));
      if (this.mode === 'psi') v.aidTiles = new Set(c.psiShieldTargets(u).map(o => Hex.key(o.pos.q, o.pos.r)));
      if (!u.hasAttacked && !u.stunnedNow) {
        const w = this.weaponOf(u);
        v.targets = new Set(c.opponents(u).filter(t => c.attackInfo(u, t, w).valid));
      }
      return v;
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
        const s = statusList(o);
        if (s.length) h += `<br><small>${s.join(' · ')}</small>`;
        if (this.playerTurn() && o.team !== u.team) {
          const info = c.attackInfo(u, o, this.weaponOf(u));
          if (!info.valid) h += `<div class="tip-bad">Kein Angriff: ${esc(info.reason)}</div>`;
          else if (u.hasAttacked || u.stunnedNow) h += `<div class="tip-bad">Kein Angriff mehr in diesem Zug</div>`;
          else h += attackBreakdown(info);
        }
      }
      const hm = (t.h * PTF.MAP_CONST.HEX_M).toLocaleString('de-DE');
      let info = `${esc(T.name)} · Höhe ${t.h} (${hm} m) · ${T.walk ? `Kosten ${T.cost}` : 'nicht begehbar'}`;
      if (u && !o && !this.isAi(u)) {
        const d = Hex.distance(u.pos, t) * PTF.MAP_CONST.HEX_M;
        info += ` · ${d.toLocaleString('de-DE')} m entfernt`;
      }
      h += `<div class="tip-tile">${info}</div>`;
      return h;
    },

    onClick(e) {
      if (this.drag && this.drag.moved) return;
      if (!this.playerTurn()) return;
      const c = this.combat, u = c.current, m = this.mouse(e);
      let target = this.renderer.pickUnit(m.x, m.y);
      // im Bewegungsmodus fangen eigene Figuren keinen Klick ab
      if (target && this.mode === 'move' && target.team === u.team) target = null;
      // Gegner, der gerade nicht angreifbar ist: Klick gilt dem Feld darunter
      if (target && this.mode === 'move' && target.team !== u.team &&
          (u.hasAttacked || u.stunnedNow || target.state !== 'ok' || !c.attackInfo(u, target, this.weaponOf(u)).valid)) target = null;
      const tile = target ? this.map.at(target.pos) : this.renderer.pickTile(m.x, m.y, this.preferTiles());
      if (this.mode === 'aid') { if (target && c.doFirstAid(u, target)) this.mode = 'move'; }
      else if (this.mode === 'psi') { if (target && c.doPsiShield(u, target)) this.mode = 'move'; }
      else if (target && target.team !== u.team && target.state === 'ok') c.doAttack(u, target, this.weaponOf(u));
      else if (tile) c.doMove(u, tile);
      $('#tip').hidden = true;
      this.dirty = true;
    },

    onKey(e) {
      if (e.target.tagName === 'SELECT' || e.target.tagName === 'INPUT') return;
      if (e.key === 'Escape') { if (!$('#modal').hidden) this.closeModal(); else this.mode = 'move'; }
      if (e.key === 'Enter' && this.playerTurn()) this.combat.endTurn();
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
      if (!this.playerTurn()) return;
      switch (act) {
        case 'weapon': this.weaponSel[u.id] = b.dataset.w; break;
        case 'move': this.mode = 'move'; break;
        case 'aim': c.doAim(u); break;
        case 'defend': c.doDefend(u); break;
        case 'aid': this.mode = this.mode === 'aid' ? 'move' : 'aid'; break;
        case 'psi': this.mode = this.mode === 'psi' ? 'move' : 'psi'; break;
        case 'end': c.endTurn(); break;
      }
      this.dirty = true;
    },

    // ---------- Panel ----------
    updatePanel() {
      const c = this.combat, u = c.current;
      $('#round').textContent = c.round;
      $('#order').innerHTML = c.order.map((o, i) =>
        `<li class="${o.team} ${o.state !== 'ok' ? 'out' : ''} ${i === c.turnIdx ? 'now' : ''} ${i < c.turnIdx ? 'done' : ''}" title="Initiative ${o.initRoll}">
          <span class="badge" style="background:${o.color}">${o.letter}</span><span>${esc(o.name)}</span><span class="ini">${o.init}</span></li>`).join('');
      if (!u) { $('#unit').innerHTML = ''; return; }
      const ai = this.isAi(u);
      const w = this.weaponOf(u);
      const dodge = Math.max(0, Rules.skillTotal(u, 'ausweichen'));
      const player = this.playerTurn();
      const dis = cond => (!player || !cond ? 'disabled' : '');
      const canAim = !u.aim && !u.hasAttacked && !u.stunnedNow;
      const aidT = c.firstAidTargets(u).length > 0;
      const psiT = c.psiShieldTargets(u).length > 0;
      const status = statusList(u);
      $('#unit').innerHTML = `
        <div class="unit-head ${u.team}">
          <span class="badge big" style="background:${u.color}">${u.letter}</span>
          <div><b>${esc(u.name)}</b><small>${esc(u.role)} · ${u.team === 'crew' ? 'Crew' : 'Gegner'}</small></div>
          ${u.isCrew ? `<button class="mini" data-act="sheet" data-id="${u.id}" title="Charakterbogen">Bogen</button>` : ''}
        </div>
        ${bar('TP', u.hp, u.maxHp, 'hp')}
        ${u.maxPp ? bar('PP', u.pp, u.maxPp, 'pp') : ''}
        <div class="stats">
          <span title="Gesamtbonus der Waffenfertigkeit">AW <b>${Rules.skillTotal(u, WEAPONS[w].skill)}</b></span>
          <span title="½ Ausweichen (+ Rüstung/Schild, ohne Deckung)">VW <b>${(u.defStance ? dodge : Math.floor(dodge / 2)) + (ARMOR[u.armor].db || 0)}</b></span>
          <span title="Bewegungspunkte pro Bewegungsaktion">BP <b>${Rules.movePoints(u)}</b></span>
          <span title="Initiative diese Runde">INI <b>${u.init}</b></span>
        </div>
        <div class="status">${status.map(s => `<span class="chip">${s}</span>`).join('') || '<span class="muted">keine Effekte</span>'}</div>
        <div class="actions-left">Aktionen: ${'●'.repeat(Math.max(0, u.actions))}${'○'.repeat(Math.max(0, 2 - u.actions))}${u.hasAttacked ? ' · Angriff verbraucht' : ''}</div>
        ${ai ? `<div class="ai-note">${u.team === 'enemy' ? 'Gegner' : 'KI'} ist am Zug …</div>` : `
        <div class="weapons">${u.weapons.map(id => {
          const W = WEAPONS[id];
          const extra = W.ammo ? ` (${u.ammo[id]}/${W.ammo})` : W.pp ? ` (${W.pp} PP)` : '';
          const usable = c.usableWeapons(u).includes(id);
          return `<button data-act="weapon" data-w="${id}" class="${id === w ? 'sel' : ''}" ${!usable || !player ? 'disabled' : ''}>${esc(W.name)}${extra}<small>${W.melee ? 'Nahkampf' : `${W.inc} m/Stufe, max ${W.inc * W.stages} m`} · max ${W.max}</small></button>`;
        }).join('')}</div>
        <div class="buttons">
          <button data-act="move" class="${this.mode === 'move' ? 'sel' : ''}" ${dis(true)} title="Feld anklicken. Gegner anklicken = Angriff">Bewegen / Angreifen</button>
          <button data-act="aim" ${dis(canAim)} title="+15 auf den nächsten Angriff">Zielen</button>
          <button data-act="defend" ${dis(!u.defStance)} title="Voller Ausweichen-Bonus bis zum nächsten Zug">Abwehrhaltung</button>
          <button data-act="aid" class="${this.mode === 'aid' ? 'sel' : ''}" ${dis(aidT)} title="Benachbarte Figur behandeln (Erste Hilfe, Mittel)">Erste Hilfe</button>
          ${Rules.skillRank(u, 'psiWirken') > 0 ? `<button data-act="psi" class="${this.mode === 'psi' ? 'sel' : ''}" ${dis(psiT)} title="Psi wirken, 2 PP: +20 VW für bis zu 3 Runden, Reichweite 4">Psi-Schild</button>` : ''}
          <button data-act="end" class="end" ${dis(true)} title="Enter">Zug beenden</button>
        </div>
        <div class="hint">${this.hintText(u)}</div>`}`;
    },

    hintText(u) {
      if (this.mode === 'aid') return 'Grün markierte Figur anklicken. Rechtsklick/Esc bricht ab.';
      if (this.mode === 'psi') return 'Grün markierte Figur für den Psi-Schild anklicken.';
      return 'Blaue Felder: Bewegung. Rot umrandete Gegner: angreifbar (Maus drüber zeigt Chance und Modifikatoren).';
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
  function bar(label, v, max, cls) {
    const f = Math.max(0, Math.min(1, v / max));
    return `<div class="bar ${cls}"><span>${label} ${v}/${max}</span><i style="width:${f * 100}%"></i></div>`;
  }

  function statusList(u) {
    const s = [];
    if (u.bleed) s.push(`Blutung ${u.bleed}`);
    if (u.stun) s.push(`Betäubt ${u.stun}`);
    if (u.malus) s.push(`Wunden ${u.malus}`);
    if (u.prone) s.push('Niedergeworfen');
    if (u.defStance) s.push('Abwehrhaltung');
    if (u.psiShield) s.push(`Psi-Schild ${u.psiShield}`);
    if (u.aim) s.push(`Zielt +${u.aim}`);
    if (u.nextAttackMalus) s.push(`Waffe klemmt ${u.nextAttackMalus}`);
    return s;
  }

  function attackBreakdown(info) {
    const li = m => `<li><span>${esc(m.label)}</span><b>${fmt(m.val)}</b></li>`;
    const sumOb = info.ob.reduce((s, m) => s + m.val, 0), sumDb = info.db.reduce((s, m) => s + m.val, 0);
    const cls = info.chance >= 60 ? 'good' : info.chance >= 35 ? 'mid' : 'bad';
    return `<div class="tip-attack"><div class="chance ${cls}">Trefferchance ≈ ${info.chance}%</div>
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
          <tr><td>Bewegung</td><td>${Rules.movePoints(u)} BP</td></tr>
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
