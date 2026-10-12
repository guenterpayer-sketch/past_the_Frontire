// Rundenbasierter Bodenkampf. Reine Spiellogik, ohne Grafik.
(function (PTF) {
  'use strict';
  const { Hex, Rules, Tables, WEAPONS, ARMOR, ATTACK_TABLES, TERRAIN, SKILLS, Dice } = PTF;

  const sum = mods => mods.reduce((s, m) => s + m.val, 0);
  const fmt = v => (v >= 0 ? '+' + v : String(v));

  class Combat {
    constructor(map, crewDefs, enemyDefs, onEvent) {
      this.map = map;
      this.onEvent = onEvent || (() => {});
      this.units = [
        ...crewDefs.map(d => PTF.Units.prepareForBattle(d, 'crew')),
        ...enemyDefs.map(d => PTF.Units.prepareForBattle(d, 'enemy')),
      ];
      this.round = 0;
      this.order = [];
      this.turnIdx = -1;
      this.result = null; // 'sieg' | 'niederlage'
      this.deploy();
    }

    log(text, cls) { this.onEvent({ type: 'log', text, cls }); }
    emit(ev) { this.onEvent(ev); }

    get current() { return this.order[this.turnIdx] || null; }
    crew() { return this.units.filter(u => u.team === 'crew'); }
    enemies() { return this.units.filter(u => u.team === 'enemy'); }
    opponents(u) { return this.units.filter(o => o.team !== u.team && o.state === 'ok'); }
    unitAt(q, r) { return this.units.find(u => u.state !== 'dead' && u.pos.q === q && u.pos.r === r) || null; }
    tileOf(u) { return this.map.at(u.pos); }

    deploy() {
      const m = this.map;
      const place = (units, cols) => {
        const mid = (m.rows - 1) / 2;
        const tiles = m.list.filter(t => cols.includes(t.col)).sort((a, b) => Math.abs(a.row - mid) - Math.abs(b.row - mid) || a.col - b.col);
        units.forEach((u, i) => { const t = tiles[i]; u.pos = { q: t.q, r: t.r }; });
      };
      place(this.crew(), [1, 0]);
      place(this.enemies(), [m.cols - 2, m.cols - 1]);
    }

    // ---------- Runden und Züge ----------
    start() { this.startRound(); }

    startRound() {
      this.round++;
      this.log(`— Runde ${this.round} —`, 'round');
      for (const u of this.units) {
        if (u.state === 'dead') continue;
        if (this.round > 1 && u.state === 'ok') Rules.awardXp(u, 'kampfsinn', 1);
        if (u.psiShield > 0) u.psiShield--;
        if (u.bleed > 0) {
          u.hp -= u.bleed;
          this.log(`${u.name} blutet (−${u.bleed} TP).`, 'dmg');
          this.emit({ type: 'float', unit: u, text: `−${u.bleed}`, color: '#ff6b6b' });
          this.checkState(u);
        }
      }
      if (this.checkEnd()) return;
      const ready = this.units.filter(u => u.state === 'ok');
      for (const u of ready) {
        const a = Dice.d(10), b = Dice.d(10);
        u.init = a + b + Rules.initiativeBonus(u);
        u.initRoll = `${a}+${b}${fmt(Rules.initiativeBonus(u))}`;
      }
      this.order = ready.sort((x, y) => y.init - x.init || (x.team === 'crew' ? -1 : 1));
      this.turnIdx = -1;
      this.emit({ type: 'order' });
      this.nextTurn();
    }

    nextTurn() {
      if (this.checkEnd()) return;
      do { this.turnIdx++; } while (this.turnIdx < this.order.length && this.order[this.turnIdx].state !== 'ok');
      if (this.turnIdx >= this.order.length) { this.startRound(); return; }
      this.beginTurn(this.current);
    }

    beginTurn(u) {
      u.actions = 2;
      u.hasAttacked = false;
      u.aim = 0;
      u.defStance = false;
      u.stunnedNow = u.stun > 0;
      if (u.prone) { u.actions--; u.prone = false; this.log(`${u.name} rappelt sich auf (−1 Aktion).`); }
      if (u.stunnedNow) { u.actions = Math.min(u.actions, 1); this.log(`${u.name} ist betäubt: nur 1 Aktion, kein Angriff.`); }
      this.emit({ type: 'turn', unit: u });
    }

    endTurn() {
      const u = this.current;
      if (!u) return;
      if (u.stun > 0) u.stun--;
      u.actions = 0;
      this.emit({ type: 'endturn', unit: u });
      this.nextTurn();
    }

    checkState(u) {
      if (u.state === 'dead') return;
      if (u.hp <= Rules.deathAt(u)) {
        u.state = 'dead';
        this.log(`${u.name} ist tot.`, 'death');
        this.emit({ type: 'death', unit: u });
      } else if (u.hp <= 0 && u.state === 'ok') {
        u.state = 'ko';
        this.log(`${u.name} bricht bewusstlos zusammen.`, 'death');
      }
    }

    checkEnd() {
      if (this.result) return true;
      if (this.enemies().every(u => u.state !== 'ok')) this.result = 'sieg';
      else if (this.crew().every(u => u.state !== 'ok')) this.result = 'niederlage';
      if (this.result) { this.emit({ type: 'end', result: this.result }); return true; }
      return false;
    }

    // ---------- Abfragen ----------
    moveRange(u) {
      const mp = Rules.movePoints(u);
      return this.map.reachable(u.pos, mp,
        t => { const o = this.unitAt(t.q, t.r); return o && o !== u && o.team !== u.team; },
        t => { const o = this.unitAt(t.q, t.r); return o && o !== u; });
    }

    usableWeapons(u) { return u.weapons.filter(w => (!WEAPONS[w].ammo || u.ammo[w] > 0) && (!WEAPONS[w].pp || u.pp >= WEAPONS[w].pp)); }

    defenseMods(att, def, w, from, to) {
      const mods = [];
      if (w.psi) {
        mods.push({ label: 'Psi-Verteidigung', val: Math.max(0, Rules.skillTotal(def, 'psiVerteidigung')) });
        if (def.psiShield > 0) mods.push({ label: 'Psi-Schild', val: 20 });
        return mods;
      }
      const dodge = Math.max(0, Rules.skillTotal(def, 'ausweichen'));
      if (def.stun > 0) mods.push({ label: 'Ausweichen (betäubt)', val: 0 });
      else if (def.defStance) mods.push({ label: 'Ausweichen (Abwehrhaltung)', val: dodge });
      else mods.push({ label: 'Ausweichen ½', val: Math.floor(dodge / 2) });
      const ar = ARMOR[def.armor];
      if (ar.db) mods.push({ label: ar.name, val: ar.db });
      if (def.shield) mods.push({ label: 'Schild', val: 10 + Math.max(0, Math.floor(Rules.rankBonus(Rules.skillRank(def, 'schild')) / 2)) });
      if (!w.melee) {
        const cov = this.map.cover(to, from);
        if (cov) mods.push({ label: 'Deckung: ' + cov, val: 20 });
        if (TERRAIN[to.terrain].forest) mods.push({ label: 'Kristallflora', val: 10 });
      }
      if (TERRAIN[to.terrain].water) mods.push({ label: 'steht im Wasser', val: -10 });
      if (def.psiShield > 0) mods.push({ label: 'Psi-Schild', val: 20 });
      return mods;
    }

    // Vorschau oder Grundlage eines Angriffs. from: hypothetische Position des Angreifers (für KI)
    attackInfo(att, def, wid, from) {
      const w = WEAPONS[wid];
      from = from || this.tileOf(att);
      const to = this.tileOf(def);
      const dist = Hex.distance(from, to);
      const bad = reason => ({ valid: false, reason, weapon: w });
      if (def.state !== 'ok') return bad('Ziel ist kampfunfähig');
      if (w.ammo && !(att.ammo[wid] > 0)) return bad('keine Munition');
      if (w.pp && att.pp < w.pp) return bad(`zu wenig Psi-Punkte (${w.pp} nötig)`);
      const ob = [{ label: SKILLS[w.skill].name, val: Rules.skillTotal(att, w.skill) }];
      let los = { visible: true, wood: 0 };
      if (w.melee) {
        if (dist !== 1) return bad('nicht benachbart');
        const dh = from.h - to.h;
        if (Math.abs(dh) > 1) return bad('Höhenunterschied zu groß');
        if (dh) ob.push({ label: dh > 0 ? 'höher stehend' : 'tiefer stehend', val: dh > 0 ? 10 : -10 });
      } else {
        if (dist > Math.floor(w.range * 1.5)) return bad('außer Reichweite');
        if (w.minRange && dist < w.minRange) return bad('zu nah');
        los = this.map.lineOfSight(from, to);
        if (!los.visible) return bad('keine Sicht (' + los.reason + ')');
        const dh = from.h - to.h;
        if (dh) ob.push({ label: dh > 0 ? `${dh} Stufe(n) höher` : `${-dh} Stufe(n) tiefer`, val: Math.max(-15, Math.min(15, dh * 5)) });
        if (dist <= w.range / 2) ob.push({ label: 'kurze Distanz', val: 10 });
        else if (dist > w.range) ob.push({ label: 'weite Distanz', val: -25 });
        if (los.wood) ob.push({ label: 'Kristallflora in der Schusslinie', val: -10 * los.wood });
      }
      if (w.ob) ob.push({ label: 'Feuerstoß', val: w.ob });
      if (att.aim) ob.push({ label: 'Zielen', val: att.aim });
      if (att.nextAttackMalus) ob.push({ label: 'Waffe klemmt', val: att.nextAttackMalus });
      if (att.malus) ob.push({ label: 'Wunden', val: att.malus });
      const db = this.defenseMods(att, def, w, from, to);
      const net = sum(ob) - sum(db);
      const cls = ARMOR[def.armor].cls;
      const thr = ATTACK_TABLES[w.table].hit[cls];
      // Trefferchance: W100 (ohne Patzerbereich) + net >= thr; der offene Wurf nach oben wird vernachlässigt
      const need = Math.max(thr - net, w.fumble + 1);
      const chance = Math.max(0, Math.min(100, 101 - need));
      return { valid: true, weapon: w, wid, ob, db, net, thr, chance, dist, from, to };
    }

    // ---------- Aktionen ----------
    canAct(u) { return this.current === u && u.actions > 0 && !this.result; }

    doMove(u, tile) {
      if (!this.canAct(u)) return false;
      const reach = this.moveRange(u);
      const k = Hex.key(tile.q, tile.r);
      if (!reach.has(k) || (tile.q === u.pos.q && tile.r === u.pos.r)) return false;
      const path = this.map.pathTo(reach, tile);
      u.pos = { q: tile.q, r: tile.r };
      u.actions--;
      this.emit({ type: 'move', unit: u, path });
      return true;
    }

    doAim(u) {
      if (!this.canAct(u) || u.aim || u.hasAttacked || u.stunnedNow) return false;
      u.aim = 15; u.actions--;
      this.log(`${u.name} zielt (+15 auf den nächsten Angriff).`);
      return true;
    }

    doDefend(u) {
      if (!this.canAct(u) || u.defStance) return false;
      u.defStance = true; u.actions--;
      this.log(`${u.name} geht in Abwehrhaltung (voller Ausweichen-Bonus).`);
      return true;
    }

    doAttack(u, target, wid) {
      if (!this.canAct(u) || u.hasAttacked || u.stunnedNow) return false;
      const info = this.attackInfo(u, target, wid);
      if (!info.valid) return false;
      const w = info.weapon;
      u.actions--; u.hasAttacked = true;
      if (w.pp) u.pp -= w.pp;
      if (w.ammo) u.ammo[wid]--;
      const roll = Dice.openD100(w.fumble);
      Rules.awardXp(u, w.skill, 1);
      u.aim = 0;
      u.nextAttackMalus = 0;
      this.emit({ type: 'attack', unit: u, target, weapon: w });
      if (roll.fumble) { this.resolveFumble(u, roll, w); return true; }

      const raw = roll.total + info.net;
      const total = Math.min(raw, w.max);
      const res = Tables.lookupAttack(w.table, total, ARMOR[target.armor].cls, w.dmg);
      const capped = raw > w.max ? ` (max. ${w.max})` : '';
      const head = `${u.name} → ${target.name} (${w.name}): Wurf ${PTF.formatRoll(roll)} ${fmt(sum(info.ob))} AW − ${sum(info.db)} VW = ${total}${capped}`;
      if (!res.hit) {
        this.log(`${head} → daneben (Schwelle ${res.threshold}).`, 'miss');
        this.emit({ type: 'float', unit: target, text: 'daneben', color: '#cfd8dc' });
        this.defenseXp(target, w);
      } else {
        this.log(`${head} → Treffer: ${res.dmg} TP${res.severity ? `, Kritischer ${res.severity}` : ''}.`, 'hit');
        Rules.awardXp(u, w.skill, 1);
        const hardMods = sum(info.ob.slice(1)) - sum(info.db);
        if (hardMods <= -20) Rules.awardXp(u, w.skill, 2);
        this.applyHit(u, target, res);
        if (res.severity) Rules.awardXp(u, w.skill, 1);
      }
      if (w.splash) this.resolveSplash(u, target, roll, info, w);
      this.checkEnd();
      return true;
    }

    applyHit(att, target, res) {
      target.hp -= res.dmg;
      this.emit({ type: 'float', unit: target, text: `−${res.dmg}`, color: '#ff8a65' });
      if (res.severity) this.applyCrit(target, Tables.rollCrit(res.critType, res.severity), res.severity);
      const before = target.state;
      this.checkState(target);
      if (before === 'ok' && target.state !== 'ok') att.kills++;
    }

    applyCrit(u, crit, sev) {
      const r = crit.row;
      const fx = [];
      if (r.kill) { u.hp = Math.min(u.hp, Rules.deathAt(u)); fx.push('tödlich'); }
      if (r.dmg) { u.hp -= r.dmg; fx.push(`+${r.dmg} TP`); }
      if (r.bleed) { u.bleed += r.bleed; fx.push(`blutet ${r.bleed}`); }
      if (r.stun) { u.stun += r.stun; fx.push(`betäubt ${r.stun}`); }
      if (r.malus) { u.malus += r.malus; fx.push(`${r.malus} auf alles`); }
      if (r.prone) { u.prone = true; fx.push('niedergeworfen'); }
      if (r.ko && u.state === 'ok') { u.state = 'ko'; fx.push('bewusstlos'); }
      this.log(`  Kritisch ${sev} (${crit.table}), Wurf ${crit.roll}${fmt(Tables.SEVERITY_MOD[sev])} = ${crit.total}: ${r.text} ${fx.length ? '[' + fx.join(', ') + ']' : ''}`, 'crit');
      this.emit({ type: 'float', unit: u, text: `Krit ${sev}`, color: '#ffd54f' });
    }

    defenseXp(def, w) {
      if (def.stun > 0) return;
      Rules.awardXp(def, w.psi ? 'psiVerteidigung' : 'ausweichen', 1);
      if (def.shield && !w.psi) Rules.awardXp(def, 'schild', 1);
    }

    resolveSplash(att, target, roll, info, w) {
      const center = this.tileOf(target);
      for (const n of Hex.neighbors(center.q, center.r)) {
        const v = this.unitAt(n.q, n.r);
        if (!v || v.state !== 'ok') continue;
        const total = Math.min(roll.total + sum(info.ob) + w.splash, w.max);
        const res = Tables.lookupAttack(w.table, total, ARMOR[v.armor].cls, w.dmg);
        if (!res.hit) { this.log(`  Druckwelle verfehlt ${v.name} (${total}).`, 'miss'); continue; }
        this.log(`  Druckwelle trifft ${v.name} (${total}): ${res.dmg} TP${res.severity ? `, Kritischer ${res.severity}` : ''}.`, 'hit');
        this.applyHit(att, v, res);
      }
    }

    resolveFumble(u, roll, w) {
      const f = Tables.rollFumble();
      this.log(`${u.name} (${w.name}): Wurf ${roll.first} – PATZER! Patzerwurf ${f.roll}: ${f.row.text}`, 'fumble');
      this.emit({ type: 'float', unit: u, text: 'Patzer', color: '#ff5252' });
      if (f.row.loseTurn) u.actions = 0;
      if (f.row.nextMalus) u.nextAttackMalus = f.row.nextMalus;
      if (f.row.prone) u.prone = true;
      if (f.row.selfDmg) {
        const d = Dice.d(10);
        u.hp -= d;
        this.log(`  ${u.name} erleidet ${d} TP.`, 'dmg');
        this.checkState(u);
      }
      this.checkEnd();
    }

    firstAidTargets(u) {
      return this.units.filter(o => o.team === u.team && o.state !== 'dead' && Hex.distance(o.pos, u.pos) <= 1 &&
        (o.bleed > 0 || o.state === 'ko' || o.hp < o.maxHp));
    }

    doFirstAid(u, target) {
      if (!this.canAct(u) || !this.firstAidTargets(u).includes(target)) return false;
      u.actions--;
      const mods = u.malus ? [{ label: 'Wunden', val: u.malus }] : [];
      const m = Rules.maneuver(u, 'ersteHilfe', 'mittel', mods);
      let fx;
      switch (m.result.id) {
        case 'herausragend': { const h = Dice.d(10) + Dice.d(10); target.bleed = 0; target.stun = 0; this.heal(target, h); fx = `Blutung gestoppt, +${h} TP, Betäubung aufgehoben`; break; }
        case 'erfolg': { const h = Dice.d(10); target.bleed = 0; this.heal(target, h); fx = `Blutung gestoppt, +${h} TP`; break; }
        case 'teilerfolg': { const h = Dice.d(5); target.bleed = Math.floor(target.bleed / 2); this.heal(target, h); fx = `Blutung halbiert, +${h} TP`; break; }
        case 'fehlschlag': fx = 'keine Wirkung'; break;
        default: { const d = Dice.d(5); target.hp -= d; this.checkState(target); fx = `verschlimmert die Wunde (−${d} TP)`; }
      }
      this.log(`${u.name} leistet Erste Hilfe bei ${target.name}: Wurf ${PTF.formatRoll(m.roll)} → ${m.total} = ${m.result.name}: ${fx}.`, 'heal');
      return true;
    }

    heal(u, amount) {
      u.hp = Math.min(u.maxHp, u.hp + amount);
      this.emit({ type: 'float', unit: u, text: `+${amount}`, color: '#81c784' });
      if (u.state === 'ko' && u.hp > 0) { u.state = 'ok'; this.log(`${u.name} kommt wieder zu sich.`, 'heal'); }
    }

    psiShieldTargets(u) {
      if (Rules.skillRank(u, 'psiWirken') < 1 || u.pp < 2) return [];
      return this.units.filter(o => o.team === u.team && o.state === 'ok' && Hex.distance(o.pos, u.pos) <= 4);
    }

    doPsiShield(u, target) {
      if (!this.canAct(u) || !this.psiShieldTargets(u).includes(target)) return false;
      u.actions--; u.pp -= 2;
      const m = Rules.maneuver(u, 'psiWirken', 'mittel', u.malus ? [{ label: 'Wunden', val: u.malus }] : []);
      const rounds = { herausragend: 3, erfolg: 2, teilerfolg: 1 }[m.result.id] || 0;
      if (rounds) target.psiShield = Math.max(target.psiShield, rounds);
      if (m.result.id === 'patzer') u.stun += 1;
      const fx = rounds ? `Psi-Schild auf ${target.name} für ${rounds} Runde(n)` : m.result.id === 'patzer' ? 'Rückkopplung, betäubt 1' : 'keine Wirkung';
      this.log(`${u.name} wirkt Psi-Schild: Wurf ${PTF.formatRoll(m.roll)} → ${m.total} = ${m.result.name}: ${fx}.`, 'heal');
      return true;
    }
  }

  PTF.Combat = Combat;
})(window.PTF = window.PTF || {});
