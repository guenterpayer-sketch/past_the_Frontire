// Rundenbasierter Bodenkampf im RMSS-Stil: 10-Sekunden-Runden, 100 % Aktivität pro Figur und Runde,
// Reihenfolge nach Initiative, Feuerbereitschaft, Blickrichtung. Reine Spiellogik, ohne Grafik.
(function (PTF) {
  'use strict';
  const { Hex, Rules, Tables, WEAPONS, ARMOR, ATTACK_TABLES, SKILLS, Dice } = PTF;

  const sum = mods => mods.reduce((s, m) => s + m.val, 0);
  const fmt = v => (v >= 0 ? '+' + v : String(v));

  // Gangarten: Hexfelder pro 10 % Aktivität
  const GAITS = {
    gehen: { name: 'Gehen', pace: 1 },
    laufen: { name: 'Laufen', pace: 2, attackMod: -20 },
    sprinten: { name: 'Sprinten', pace: 3, noAttack: true },
  };
  const COST = { aid: 50, psi: 40, reload: 30, stand: 30, swap: 10, crouch: 10, wait: 10 };
  const CROUCH = { db: 15, ob: 10, meleeOb: 10 }; // geduckt: +15 VW gegen Fernkampf, +10 AW im Fernkampf, Nahkämpfer +10 AW
  const MEDKIT_BONUS = 20;
  const MIN_ATTACK = 20, NORMAL_ATTACK = 60, MIN_OVERWATCH = 30, REACTION_MOD = -10;
  const FACING_MOD = { flanke: 15, ruecken: 30 };

  // Modifikator für die in einen Angriff gesteckte Aktivität: 60 % = ±0, darunter −10 je 10 %, darüber +5 je 10 %
  function activityMod(pct) { return pct < NORMAL_ATTACK ? pct - NORMAL_ATTACK : (pct - NORMAL_ATTACK) / 2; }

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
      const place = (units, tiles) => units.forEach((u, i) => { const t = tiles[i]; u.pos = { q: t.q, r: t.r }; });
      place(this.crew(), this.map.crewStart);
      place(this.enemies(), this.map.enemyStart);
    }

    // ---------- Runden und Züge ----------
    start() { this.startRound(); }

    startRound() {
      this.round++;
      this.jumpQueue = [];
      this.log(`— Runde ${this.round} (${(this.round - 1) * 10}–${this.round * 10} s) —`, 'round');
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
      // wartende Figur, die einspringen will, kommt direkt als Nächste
      while (this.jumpQueue.length) {
        const j = this.jumpQueue.shift();
        const idx = this.order.indexOf(j);
        if (j.waiting && j.state === 'ok' && idx > this.turnIdx) {
          this.order.splice(idx, 1);
          this.order.splice(this.turnIdx + 1, 0, j);
          this.emit({ type: 'order' });
          break;
        }
      }
      do { this.turnIdx++; } while (this.turnIdx < this.order.length && this.order[this.turnIdx].state !== 'ok');
      if (this.turnIdx >= this.order.length) { this.startRound(); return; }
      this.beginTurn(this.current);
    }

    beginTurn(u) {
      if (u.waiting) {
        // Einsprung nach dem Abwarten: Zustand vom Zugbeginn bleibt, Abwarten kostet 10 %
        u.waiting = false;
        u.act = u.waitAct - COST.wait;
        this.log(`${u.name} springt ein (−${COST.wait} % fürs Abwarten).`);
        this.emit({ type: 'turn', unit: u });
        return;
      }
      u.acted = false;
      u.act = 100;
      u.hasAttacked = false;
      u.ran = false;
      u.sprinted = false;
      u.moveSpare = 0;
      u.freeHex = Math.max(0, Math.floor(Rules.attrBonus(u.attrs.GEW) / 5) + (ARMOR[u.armor].move || 0));
      u.overwatch = null; // Feuerbereitschaft endet mit dem eigenen nächsten Zug
      u.stunnedNow = u.stun > 0;
      if (u.prone) { u.act -= COST.stand; u.prone = false; this.log(`${u.name} rappelt sich auf (−${COST.stand} %).`); }
      if (u.stunnedNow) { u.act = Math.min(u.act, 50); this.log(`${u.name} ist betäubt: höchstens 50 % Aktivität, kein Angriff.`); }
      this.emit({ type: 'turn', unit: u });
    }

    // Abwarten: Zug nach hinten schieben, nur solange die Figur in dieser Runde noch nichts getan hat
    canWait(u) { return this.active(u) && !u.acted && !u.waiting && u.waitRound !== this.round && u.act >= COST.wait; }

    doWait(u) {
      if (!this.canWait(u)) return false;
      u.waiting = true;
      u.waitRound = this.round;
      u.waitAct = u.act;
      u.reserve = u.act - COST.wait; // wachsam: die noch freie Aktivität zählt als Ausweichreserve
      this.order.splice(this.turnIdx, 1);
      this.order.push(u);
      this.turnIdx--;
      this.log(`${u.name} wartet ab.`);
      this.emit({ type: 'wait', unit: u });
      this.nextTurn();
      return true;
    }

    // wartende Figur springt nach dem laufenden Zug ein
    requestJump(u) {
      if (!u.waiting || u.state !== 'ok' || this.result || this.jumpQueue.includes(u)) return false;
      this.jumpQueue.push(u);
      this.log(`${u.name} springt nach diesem Zug ein.`);
      return true;
    }

    endTurn() {
      const u = this.current;
      if (!u) return;
      // nicht verbrauchte Aktivität bleibt bis zum nächsten eigenen Zug als Ausweichreserve
      u.reserve = u.overwatch ? u.overwatch.pct : Math.max(0, u.act);
      if (u.stun > 0) u.stun--;
      u.act = 0;
      this.emit({ type: 'endturn', unit: u });
      this.nextTurn();
    }

    checkState(u) {
      if (u.state === 'dead') return;
      if (u.hp <= Rules.deathAt(u)) {
        u.state = 'dead';
        u.overwatch = null;
        this.log(`${u.name} ist tot.`, 'death');
        this.emit({ type: 'death', unit: u });
      } else if (u.hp <= 0 && u.state === 'ok') {
        u.state = 'ko';
        u.overwatch = null;
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

    // ---------- Bewegung ----------
    // verfügbare Hexfelder bei dieser Gangart; actLimit begrenzt die dafür verwendbare Aktivität (KI-Planung)
    // Hexfelder je 10 %; geduckt nur Gehen mit halber Geschwindigkeit (1 Hex je 20 %)
    pace(u, gait) { return u.crouched ? (gait === 'gehen' ? 0.5 : 0) : GAITS[gait].pace; }
    freeOf(u) { return u.crouched ? 0 : u.freeHex; }
    moveBudget(u, gait, actLimit = u.act) {
      return this.freeOf(u) + u.moveSpare + Math.floor(Math.floor(Math.max(0, actLimit) / 10) * this.pace(u, gait));
    }
    // Aktivität in %, die eine Strecke mit diesen Wegkosten kostet
    movePct(u, gait, cost) {
      const rest = Math.max(0, cost - this.freeOf(u) - u.moveSpare);
      return Math.ceil(rest / this.pace(u, gait)) * 10;
    }
    // darf die Figur gerade handeln? (am Zug und kampffähig)
    active(u) { return this.current === u && !this.result && u.state === 'ok'; }

    canMove(u, gait) {
      if (!this.active(u)) return false;
      if (gait === 'sprinten' && u.hasAttacked) return false;
      if (!this.pace(u, gait)) return false;
      return this.moveBudget(u, gait) > 0;
    }
    moveRange(u, gait = 'gehen', actLimit) {
      return this.map.reachable(u.pos, this.moveBudget(u, gait, actLimit),
        t => { const o = this.unitAt(t.q, t.r); return o && o !== u && o.team !== u.team; },
        t => { const o = this.unitAt(t.q, t.r); return o && o !== u; });
    }

    doMove(u, tile, gait = 'gehen') {
      if (!this.canMove(u, gait)) return false;
      const reach = this.moveRange(u, gait);
      const k = Hex.key(tile.q, tile.r);
      if (!reach.has(k) || (tile.q === u.pos.q && tile.r === u.pos.r)) return false;
      const path = this.map.pathTo(reach, tile);
      const cost = reach.get(k).cost;
      const pct = this.movePct(u, gait, cost);
      // bezahlen: zuerst Gratis-Felder (GEW), dann Restfelder, dann Aktivität
      let need = cost;
      const free = Math.min(this.freeOf(u), need); u.freeHex -= free; need -= free;
      const spare = Math.min(u.moveSpare, need); u.moveSpare -= spare; need -= spare;
      u.act -= pct;
      u.moveSpare += (pct / 10) * this.pace(u, gait) - need;
      u.acted = true;
      if (gait === 'laufen') u.ran = true;
      if (gait === 'sprinten') u.sprinted = true;
      // Schritt für Schritt gehen: Gegner in Feuerbereitschaft können unterwegs schießen
      const walked = [path[0]];
      for (let i = 1; i < path.length; i++) {
        u.facing = Hex.dirToward(path[i - 1], path[i]);
        u.pos = { q: path[i].q, r: path[i].r };
        walked.push(path[i]);
        this.checkOverwatch(u);
        if (u.state !== 'ok' || this.result) break;
      }
      this.emit({ type: 'move', unit: u, path: walked });
      if (walked.length < path.length) this.log(`${u.name} wird mitten in der Bewegung gestoppt.`);
      return true;
    }

    doFace(u, dir) {
      if (!this.active(u)) return false;
      u.facing = ((dir % 6) + 6) % 6;
      return true;
    }

    // ---------- Angriff ----------
    usableWeapons(u) {
      return u.weapons.filter(w => {
        const W = WEAPONS[w];
        if (W.mag && !(u.loaded[w] > 0)) return false;
        if (W.pp && u.pp < W.pp) return false;
        return true;
      });
    }

    // Ausweichen hängt an der zurückgehaltenen Aktivität: ½ immer, die andere ½ anteilig zur Reserve
    reserveOf(u) { return this.current === u ? Math.max(0, u.act) : (u.reserve || 0); }

    defenseMods(att, def, w, from, to, sense) {
      const mods = [];
      if (w.psi) {
        mods.push({ label: 'Psi-Verteidigung', val: Math.max(0, Rules.skillTotal(def, 'psiVerteidigung')) });
        if (def.psiShield > 0) mods.push({ label: 'Psi-Schild', val: 20 });
        return mods;
      }
      const dodge = Math.max(0, Rules.skillTotal(def, 'ausweichen'));
      const reserve = this.reserveOf(def);
      const normal = Math.floor(dodge / 2) + Math.floor((dodge / 2) * reserve / 100);
      const sector = Hex.sector(to, def.facing, from);
      const surprised = sector !== 'vorne';
      if (def.stun > 0) mods.push({ label: 'Ausweichen (betäubt)', val: 0 });
      else if (surprised && sense) mods.push({ label: 'Ausweichen (überrascht, Kampfsinn gelungen: ½)', val: Math.floor(normal / 2) });
      else if (surprised) mods.push({ label: 'Ausweichen (überrascht)', val: 0 });
      else mods.push({ label: `Ausweichen (½ + Reserve ${reserve} %)`, val: normal });
      const ar = ARMOR[def.armor];
      if (ar.db) mods.push({ label: ar.name, val: ar.db });
      if (def.shield && !surprised) mods.push({ label: 'Schild', val: 10 + Math.max(0, Math.floor(Rules.rankBonus(Rules.skillRank(def, 'schild')) / 2)) });
      if (!w.melee) {
        const cov = this.map.cover(to, from);
        if (cov && cov.level === 1 && def.crouched) mods.push({ label: `Volle Deckung (geduckt hinter ${cov.label})`, val: PTF.MAP_CONST.COVER_BONUS[2] });
        else if (cov) mods.push({ label: `${cov.level === 2 ? 'Volle' : 'Halbe'} Deckung (${cov.label})`, val: cov.bonus });
        if (def.crouched) mods.push({ label: 'geduckt', val: CROUCH.db });
      }
      if (def.psiShield > 0) mods.push({ label: 'Psi-Schild', val: 20 });
      return mods;
    }

    // Vorschau oder Grundlage eines Angriffs.
    // opts: from (hypothetische Position, KI), pct (eingesetzte Aktivität), reaction (Feuerbereitschaft), sense (Kampfsinn gegen Überraschung gelungen)
    attackInfo(att, def, wid, opts = {}) {
      const w = WEAPONS[wid];
      const from = opts.from || this.tileOf(att);
      const pct = opts.pct || NORMAL_ATTACK;
      const to = this.tileOf(def);
      const dist = Hex.distance(from, to);
      const bad = reason => ({ valid: false, reason, weapon: w });
      if (def.state !== 'ok') return bad('Ziel ist kampfunfähig');
      if (w.mag && !(att.loaded[wid] > 0)) return bad('nicht geladen');
      if (w.pp && att.pp < w.pp) return bad(`zu wenig Psi-Punkte (${w.pp} nötig)`);
      const ob = [{ label: SKILLS[w.skill].name, val: Rules.skillTotal(att, w.skill) }];
      const meters = dist * PTF.MAP_CONST.HEX_M;
      if (w.melee) {
        if (dist !== 1) return bad('nicht benachbart');
        const dh = from.h - to.h;
        if (Math.abs(dh) > 1) return bad('Höhenunterschied zu groß');
        if (dh) ob.push({ label: dh > 0 ? 'höher stehend' : 'tiefer stehend', val: dh > 0 ? 10 : -10 });
      } else {
        const stage = Math.max(1, Math.ceil(meters / w.inc));
        if (stage > w.stages) return bad(`außer Reichweite (${meters} m, max. ${w.inc * w.stages} m)`);
        if (w.minRange && meters < w.minRange) return bad(`zu nah (mind. ${w.minRange} m)`);
        const los = this.map.lineOfSight(from, to);
        if (!los.visible) return bad('keine Sichtlinie');
        const dh = from.h - to.h;
        if (dh) ob.push({ label: dh > 0 ? `${dh} Stufe(n) höher` : `${-dh} Stufe(n) tiefer`, val: Math.max(-15, Math.min(15, dh * 5)) });
        if (meters <= Tables.POINT_BLANK_M) ob.push({ label: `Kernschussweite (${meters} m)`, val: 10 });
        else if (stage > 1) ob.push({ label: `Reichweitenstufe ${stage} (${meters} m)`, val: Tables.RANGE_STEP * (stage - 1) });
      }
      const aMod = activityMod(pct);
      if (aMod) ob.push({ label: `Aktivität ${pct} %`, val: aMod });
      if (opts.reaction) ob.push({ label: 'Reaktion (Feuerbereitschaft)', val: REACTION_MOD });
      if (att.ran && !opts.reaction) ob.push({ label: 'gelaufen', val: GAITS.laufen.attackMod });
      const sector = Hex.sector(to, def.facing, from);
      if (FACING_MOD[sector]) ob.push({ label: sector === 'flanke' ? 'Flanke' : 'Rücken', val: FACING_MOD[sector] });
      if (att.crouched && !w.melee) ob.push({ label: 'geduckt (ruhiger Anschlag)', val: CROUCH.ob });
      if (def.crouched && w.melee) ob.push({ label: 'Ziel geduckt', val: CROUCH.meleeOb });
      if (w.ob) ob.push({ label: 'Feuerstoß', val: w.ob });
      if (att.nextAttackMalus) ob.push({ label: 'Waffe klemmt', val: att.nextAttackMalus });
      if (att.malus) ob.push({ label: 'Wunden', val: att.malus });
      const db = this.defenseMods(att, def, w, from, to, opts.sense);
      const net = sum(ob) - sum(db);
      const cls = ARMOR[def.armor].cls;
      const thr = ATTACK_TABLES[w.table].hit[cls];
      // Trefferchance: W100 (ohne Patzerbereich) + net >= thr; der offene Wurf nach oben wird vernachlässigt
      const need = Math.max(thr - net, w.fumble + 1);
      const chance = Math.max(0, Math.min(100, 101 - need));
      return { valid: true, weapon: w, wid, ob, db, net, thr, chance, dist, meters, from, to, pct, sector, surprised: sector !== 'vorne' };
    }

    // Kosten eines Angriffs inkl. Waffenwechsel
    attackCost(u, wid, pct) { return pct + (wid !== u.weapon ? COST.swap : 0); }

    canAttack(u) {
      return this.active(u) && !u.hasAttacked && !u.stunnedNow && !u.sprinted && u.act >= MIN_ATTACK;
    }

    doAttack(u, target, wid, pct = NORMAL_ATTACK) {
      pct = Math.round(pct / 10) * 10;
      if (!this.canAttack(u) || pct < MIN_ATTACK || pct > 100) return false;
      if (this.attackCost(u, wid, pct) > u.act) return false;
      if (!this.attackInfo(u, target, wid, { pct }).valid) return false;
      // wer einen Gegner in Feuerbereitschaft vor sich hat, wird beim Ansetzen beschossen
      this.checkOverwatch(u);
      if (u.state !== 'ok' || this.result) return true;
      const cost = this.attackCost(u, wid, pct);
      if (wid !== u.weapon) { u.weapon = wid; this.log(`${u.name} wechselt zu ${WEAPONS[wid].name} (−${COST.swap} %).`); }
      u.act -= cost;
      u.hasAttacked = true;
      u.acted = true;
      u.facing = Hex.dirToward(u.pos, target.pos);
      const info = this.attackInfo(u, target, wid, { pct, sense: this.senseCheck(u, target) });
      if (!info.valid) return true; // Ziel ist durch die Reaktion kampfunfähig geworden o. Ä.
      this.resolveAttack(u, target, info);
      return true;
    }

    // Überraschung: Ziel, das den Angreifer nicht im Sichtfeld hat, darf Kampfsinn (Mittel) würfeln
    senseCheck(att, def) {
      if (Hex.sector(def.pos, def.facing, att.pos) === 'vorne' || def.stun > 0) return false;
      const m = Rules.maneuver(def, 'kampfsinn', 'mittel', def.malus ? [{ label: 'Wunden', val: def.malus }] : []);
      const ok = m.result.id === 'erfolg' || m.result.id === 'herausragend';
      this.log(`${def.name} wird von ${att.name} überrascht – Kampfsinn: Wurf ${PTF.formatRoll(m.roll)} → ${m.total} = ${m.result.name}${ok ? ' (Ausweichen zählt halb)' : ''}.`, ok ? 'heal' : 'miss');
      return ok;
    }

    resolveAttack(u, target, info, tag = '') {
      const w = info.weapon;
      if (w.pp) u.pp -= w.pp;
      if (w.mag) u.loaded[info.wid]--;
      const roll = Dice.openD100(w.fumble);
      Rules.awardXp(u, w.skill, 1);
      u.nextAttackMalus = 0;
      this.emit({ type: 'attack', unit: u, target, weapon: w });
      if (roll.fumble) { this.resolveFumble(u, roll, w); return; }

      const raw = roll.total + info.net;
      const total = Math.min(raw, w.max);
      const res = Tables.lookupAttack(w.table, total, ARMOR[target.armor].cls, w.dmg);
      const capped = raw > w.max ? ` (max. ${w.max})` : '';
      const head = `${tag}${u.name} → ${target.name} (${w.name}, ${info.pct} %): Wurf ${PTF.formatRoll(roll)} ${fmt(sum(info.ob))} AW − ${sum(info.db)} VW = ${total}${capped}`;
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
    }

    // ---------- Feuerbereitschaft ----------
    canOverwatch(u, wid) {
      return this.canAttack(u) && u.act >= MIN_OVERWATCH && this.attackCost(u, wid, MIN_OVERWATCH) <= u.act &&
        this.usableWeapons(u).includes(wid);
    }

    doOverwatch(u, wid) {
      if (!this.canOverwatch(u, wid)) return false;
      if (wid !== u.weapon) { u.act -= COST.swap; u.weapon = wid; }
      u.overwatch = { wid, pct: Math.min(100, Math.floor(u.act / 10) * 10) };
      u.acted = true;
      this.log(`${u.name} hält ${u.overwatch.pct} % in Feuerbereitschaft (${WEAPONS[wid].name}).`);
      u.act = 0;
      return true;
    }

    // Gegner von mover in Feuerbereitschaft, die ihn im Sichtfeld und in Reichweite haben, schießen (einmal je Runde)
    checkOverwatch(mover) {
      for (const w of this.opponents(mover)) {
        if (!w.overwatch || mover.state !== 'ok' || this.result) continue;
        if (Hex.sector(w.pos, w.facing, mover.pos) !== 'vorne') continue;
        const { wid, pct } = w.overwatch;
        let info = this.attackInfo(w, mover, wid, { pct, reaction: true });
        if (!info.valid) continue;
        w.overwatch = null;
        w.reserve = 0;
        this.emit({ type: 'overwatchFire', unit: w });
        w.facing = Hex.dirToward(w.pos, mover.pos);
        info = this.attackInfo(w, mover, wid, { pct, reaction: true, sense: this.senseCheck(w, mover) });
        if (info.valid) this.resolveAttack(w, mover, info, 'Feuerbereitschaft! ');
      }
    }

    // ---------- Treffer, Kritische, Patzer ----------
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
      if (r.ko && u.state === 'ok') { u.state = 'ko'; u.overwatch = null; fx.push('bewusstlos'); }
      if (r.stun || r.prone) u.overwatch = null;
      this.log(`  Kritisch ${sev} (${crit.table}), Wurf ${crit.roll}${fmt(Tables.SEVERITY_MOD[sev])} = ${crit.total}: ${r.text} ${fx.length ? '[' + fx.join(', ') + ']' : ''}`, 'crit');
      this.emit({ type: 'float', unit: u, text: `Krit ${sev}`, color: '#ffd54f' });
    }

    defenseXp(def, w) {
      if (def.stun > 0) return;
      Rules.awardXp(def, w.psi ? 'psiVerteidigung' : 'ausweichen', 1);
      if (def.shield && !w.psi) Rules.awardXp(def, 'schild', 1);
    }

    // Druckwelle: Ring 1 (1,5 m) und Ring 2 (3 m) mit eigenem Abzug, gleicher Wurf
    resolveSplash(att, target, roll, info, w) {
      const center = this.tileOf(target);
      for (const v of this.units) {
        if (v === target || v.state !== 'ok') continue;
        const d = Hex.distance(v.pos, center);
        if (d < 1 || d > w.splash.length) continue;
        const total = Math.min(roll.total + sum(info.ob) + w.splash[d - 1], w.max);
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
      if (f.row.loseTurn && this.current === u) { u.act = 0; u.freeHex = 0; u.moveSpare = 0; }
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

    // ---------- Ducken ----------
    canCrouch(u) { return this.canDo(u, COST.crouch); }

    doCrouch(u) {
      if (!this.canCrouch(u)) return false;
      u.act -= COST.crouch;
      u.crouched = !u.crouched;
      u.acted = true;
      this.log(`${u.name} ${u.crouched ? 'duckt sich' : 'steht auf'} (−${COST.crouch} %).`);
      this.emit({ type: 'crouch', unit: u });
      return true;
    }

    // ---------- Sonstige Handlungen ----------
    canDo(u, cost) { return this.active(u) && u.act >= cost; }

    reloadable(u) { return u.weapons.filter(w => WEAPONS[w].mag && u.loaded[w] < WEAPONS[w].mag && u.ammo[w] > 0); }

    doReload(u, wid) {
      if (!this.canDo(u, COST.reload) || !this.reloadable(u).includes(wid)) return false;
      u.act -= COST.reload;
      u.acted = true;
      const n = Math.min(WEAPONS[wid].mag - u.loaded[wid], u.ammo[wid]);
      u.loaded[wid] += n; u.ammo[wid] -= n;
      this.emit({ type: 'reload', unit: u });
      this.log(`${u.name} lädt ${WEAPONS[wid].name} nach (−${COST.reload} %, Reserve ${u.ammo[wid]}).`);
      return true;
    }

    firstAidTargets(u) {
      return this.units.filter(o => o.team === u.team && o.state !== 'dead' && Hex.distance(o.pos, u.pos) <= 1 &&
        (o.bleed > 0 || o.state === 'ko' || o.hp < o.maxHp));
    }

    doFirstAid(u, target) {
      if (!this.canDo(u, COST.aid) || !this.firstAidTargets(u).includes(target)) return false;
      u.act -= COST.aid;
      u.acted = true;
      const mods = u.malus ? [{ label: 'Wunden', val: u.malus }] : [];
      if (u.medkit > 0) { mods.push({ label: 'Medikit', val: MEDKIT_BONUS }); u.medkit--; }
      const m = Rules.maneuver(u, 'ersteHilfe', 'leicht', mods);
      let fx;
      switch (m.result.id) {
        case 'herausragend': { const h = Dice.d(10) + Dice.d(10); target.bleed = 0; target.stun = 0; this.heal(target, h); fx = `Blutung gestoppt, +${h} TP, Betäubung aufgehoben`; break; }
        case 'erfolg': { const h = Dice.d(10); target.bleed = 0; this.heal(target, h); fx = `Blutung gestoppt, +${h} TP`; break; }
        case 'teilerfolg': { const h = Dice.d(5); target.bleed = Math.floor(target.bleed / 2); this.heal(target, h); fx = `Blutung halbiert, +${h} TP`; break; }
        case 'fehlschlag': fx = 'keine Wirkung'; break;
        default: { const d = Dice.d(5); target.hp -= d; this.checkState(target); fx = `verschlimmert die Wunde (−${d} TP)`; }
      }
      this.log(`${u.name} leistet Erste Hilfe bei ${target.name} (−${COST.aid} %): Wurf ${PTF.formatRoll(m.roll)} → ${m.total} = ${m.result.name}: ${fx}.`, 'heal');
      return true;
    }

    heal(u, amount) {
      u.hp = Math.min(u.maxHp, u.hp + amount);
      this.emit({ type: 'float', unit: u, text: `+${amount}`, color: '#81c784' });
      if (u.state === 'ko' && u.hp > 0) { u.state = 'ok'; u.reserve = 0; this.log(`${u.name} kommt wieder zu sich.`, 'heal'); }
    }

    psiShieldTargets(u) {
      if (Rules.skillRank(u, 'psiWirken') < 1 || u.pp < 2) return [];
      return this.units.filter(o => o.team === u.team && o.state === 'ok' && Hex.distance(o.pos, u.pos) <= 4);
    }

    doPsiShield(u, target) {
      if (!this.canDo(u, COST.psi) || !this.psiShieldTargets(u).includes(target)) return false;
      u.act -= COST.psi; u.pp -= 2;
      u.acted = true;
      const m = Rules.maneuver(u, 'psiWirken', 'mittel', u.malus ? [{ label: 'Wunden', val: u.malus }] : []);
      const rounds = { herausragend: 3, erfolg: 2, teilerfolg: 1 }[m.result.id] || 0;
      if (rounds) target.psiShield = Math.max(target.psiShield, rounds);
      if (m.result.id === 'patzer') u.stun += 1;
      const fx = rounds ? `Psi-Schild auf ${target.name} für ${rounds} Runde(n)` : m.result.id === 'patzer' ? 'Rückkopplung, betäubt 1' : 'keine Wirkung';
      this.log(`${u.name} wirkt Psi-Schild (−${COST.psi} %): Wurf ${PTF.formatRoll(m.roll)} → ${m.total} = ${m.result.name}: ${fx}.`, 'heal');
      return true;
    }
  }

  PTF.Combat = Combat;
  PTF.COMBAT = { GAITS, COST, CROUCH, MEDKIT_BONUS, MIN_ATTACK, NORMAL_ATTACK, MIN_OVERWATCH, REACTION_MOD, FACING_MOD, activityMod };
})(window.PTF = window.PTF || {});
