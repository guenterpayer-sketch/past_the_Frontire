class_name CombatAI
extends RefCounted
## KI für das Aktivitätssystem: sucht Positionen mit guter Trefferchance, Deckung und Höhe.
## plan_step liefert genau eine nächste Handlung, execute führt sie aus.

## Merkzettel je Figur und Zug: moved, faced, stand_check, toggle_at
var _memo := {}


func _memo_of(c: Combat, u: Combatant) -> Dictionary:
	var stamp := "%d:%d" % [c.round_no, c.turn_idx]
	var m: Dictionary = _memo.get(u, {})
	if m.get("stamp", "") != stamp:
		m = {"stamp": stamp, "moved": false, "faced": false, "stand_check": false, "toggle_at": null}
		_memo[u] = m
	return m


## bester Angriff von einem Feld aus; avail = für den Angriff verfügbare Aktivität
func _best_attack(c: Combat, u: Combatant, from: BattleMap.Tile, weapons: Array[WeaponData], avail: int, extra_mod := 0) -> Dictionary:
	var best := {}
	for w in weapons:
		var pct := mini(100, avail - (Combat.COST.swap if w != u.weapon else 0))
		if pct < Combat.MIN_ATTACK:
			continue
		for t in c.opponents(u):
			var info := c.attack_info(u, t, w, {"from": from, "pct": pct})
			if not info.valid:
				continue
			var chance := clampi(info.chance + extra_mod, 0, 100)
			if chance <= 0:
				continue
			var score := float(chance)
			if t.hp <= 10:
				score += 15
			if not w.splash.is_empty():
				# Rakete nur, wenn mehrere Gegner nah beieinander stehen und keine eigenen Leute
				var others := 0
				var friends := 0
				for v in c.units:
					if v == t or not v.is_ok() or Hex.distance(v.pos, t.pos) > w.splash.size():
						continue
					if v.team == u.team:
						friends += 1
					else:
						others += 1
				if friends:
					continue
				score += others * 30 - 10
			if w.psi:
				score += 5
			if best.is_empty() or score > best.score:
				best = {"score": score, "target": t, "weapon": w, "pct": pct, "info": info}
	return best


## Wie sicher ist ein Feld: Anteil der sichtbaren Gegner, gegen die man Deckung hat
func _safety(c: Combat, u: Combatant, tile: BattleMap.Tile) -> float:
	var seen := 0
	var covered := 0.0
	for e in c.opponents(u):
		var et := c.tile_of(e)
		if Hex.distance(et.pos, tile.pos) > 30:
			continue
		seen += 1
		if not c.map.line_of_sight(et, tile):
			covered += 1
			continue
		var cov := c.map.cover(tile, et)
		if not cov.is_empty():
			covered += cov.level / 2.0
	return covered / seen if seen else 1.0


## Wie viele Gegner können dieses Feld beschießen? (Feuerbereitschaft im Sichtfeld zählt doppelt)
func _exposure(c: Combat, u: Combatant, tile: BattleMap.Tile) -> float:
	var n := 0.0
	for e in c.opponents(u):
		var ranged := c.usable_weapons(e).filter(func(w: WeaponData) -> bool: return not w.melee)
		if ranged.is_empty():
			continue
		var w: WeaponData = ranged[0]
		var et := c.tile_of(e)
		if Hex.distance(et.pos, tile.pos) * BattleMap.HEX_M > w.max_range_m():
			continue
		if not c.map.line_of_sight(et, tile):
			continue
		var cov := c.map.cover(tile, et)
		var k := 1.0 if cov.is_empty() else (0.2 if cov.level == 2 else 0.6)
		n += k * (2.0 if e.has_overwatch() and Hex.sector(e.pos, e.facing, tile.pos) == &"vorne" else 1.0)
	return n


## Wegkosten von jedem Feld zum nächsten Gegner (Dijkstra von allen Gegnern aus, Figuren ignoriert)
func _approach_field(c: Combat, u: Combatant) -> Dictionary:
	var m := c.map
	var best := {}
	var open: Array = []
	for e in c.opponents(u):
		best[e.pos] = 0.0
		open.append([0.0, e.pos])
	while not open.is_empty():
		var bi := 0
		for i in range(1, open.size()):
			if open[i][0] < open[bi][0]:
				bi = i
		var cur: Array = open[bi]
		open.remove_at(bi)
		if cur[0] > best[cur[1]]:
			continue
		var ct := m.tile(cur[1])
		for n in Hex.neighbors(cur[1]):
			var nt := m.tile(n)
			if nt == null:
				continue
			var cost: float = cur[0] + m.step_cost(nt, ct)
			if is_finite(cost) and cost < best.get(n, INF):
				best[n] = cost
				open.append([cost, n])
	return best


## Am Zugende zum nächsten (möglichst sichtbaren) Gegner drehen
func _face_step(c: Combat, u: Combatant) -> Dictionary:
	var here := c.tile_of(u)
	var best_d := INF
	var best_e: Combatant = null
	for e in c.opponents(u):
		var d := Hex.distance(e.pos, u.pos) - (100.0 if c.map.line_of_sight(here, c.tile_of(e)) else 0.0)
		if d < best_d:
			best_d = d
			best_e = e
	if best_e == null:
		return {"type": &"end"}
	return {"type": &"face", "dir": Hex.dir_toward(u.pos, best_e.pos)}


## Erste Hilfe: benachbart sofort, sonst hinlaufen, wenn danach noch 50 % übrig sind
func _first_aid_step(c: Combat, u: Combatant, avail: int, memo: Dictionary) -> Dictionary:
	var cost: int = Combat.COST.aid
	if avail < cost or (Rules.skill_rank(u, &"ersteHilfe") < 1 and u.medkit <= 0):
		return {}
	var needs := c.units.filter(func(o: Combatant) -> bool:
		return o != u and o.team == u.team and not o.is_dead() and (o.is_down() or o.bleed >= 2) and not o.stabilized)
	if needs.is_empty():
		return {}
	var near := c.first_aid_targets(u).filter(func(o: Combatant) -> bool: return needs.has(o))
	if not near.is_empty():
		near.sort_custom(func(a: Combatant, b: Combatant) -> bool: return a.is_down() and not b.is_down())
		return {"type": &"aid", "target": near[0]}
	if memo.moved or not c.can_move(u, &"gehen"):
		return {}
	var best := {}
	var reach := c.move_range(u, &"gehen", avail - cost)
	for p in reach.dest:
		var mc: float = reach.dest[p].cost
		if avail - c.move_pct(u, &"gehen", mc) < cost:
			continue
		for o in needs:
			if Hex.distance(p, o.pos) != 1:
				continue
			var score := (20.0 if o.is_down() else 0.0) + _safety(c, u, reach.dest[p].tile) * 10 - mc
			if best.is_empty() or score > best.score:
				best = {"score": score, "tile": p}
	return {"type": &"move", "tile": best.tile, "gait": &"gehen"} if not best.is_empty() else {}


func plan_step(c: Combat, u: Combatant) -> Dictionary:
	if c.current != u or c.result != &"" or not u.is_ok():
		return {"type": &"end"}
	var memo := _memo_of(c, u)
	# Ducken/Aufstehen höchstens einmal je Bewegungsabschnitt (kein Hin und Her ohne Ortswechsel)
	var can_toggle := func() -> bool: return c.can_crouch(u) and memo.toggle_at != memo.moved
	if u.stunned_now:
		return _finish(c, u, memo)

	var here := c.tile_of(u)
	var weapons := c.usable_weapons(u)
	var avail := u.act / 10 * 10
	var melee := u.weapons[0].melee

	# Erste Hilfe für bewusstlose oder stark blutende Kameraden
	var aid := _first_aid_step(c, u, avail, memo)
	if not aid.is_empty():
		return aid

	# geduckt zu Zugbeginn: aufstehen, außer es gibt von hier einen guten Schuss
	if u.crouched and not memo.stand_check:
		memo.stand_check = true
		var h := _best_attack(c, u, here, weapons, avail) if c.can_attack(u) else {}
		if (h.is_empty() or melee) and can_toggle.call():
			return {"type": &"crouch"}

	# Nachladen, wenn der Angriff erledigt ist oder genug Aktivität für Laden + Angriff bleibt
	var rl := c.reloadable(u)
	if not rl.is_empty() and u.act >= 30 and (u.has_attacked or u.act >= 90):
		return {"type": &"reload", "weapon": rl[0]}

	if c.can_attack(u) and not weapons.is_empty():
		var options: Array = []
		var h := _best_attack(c, u, here, weapons, avail)
		if not h.is_empty():
			h.tile = here
			h.score += _safety(c, u, here) * 60 + here.h * 5
			options.append(h)
		if not memo.moved:
			for gait in ([&"gehen", &"laufen"] if melee else [&"gehen"]):
				if not c.can_move(u, gait):
					continue
				var run_mod: int = Combat.GAITS[gait].attack_mod
				var reach := c.move_range(u, gait, avail - Combat.MIN_ATTACK)
				var ws: Array[WeaponData] = weapons
				if melee:
					ws = weapons.filter(func(w: WeaponData) -> bool: return w == u.weapons[0])
				for p in reach.dest:
					var e: Dictionary = reach.dest[p]
					if e.tile == here:
						continue
					var left := avail - c.move_pct(u, gait, e.cost)
					if left < Combat.MIN_ATTACK:
						continue
					var a := _best_attack(c, u, e.tile, ws, left, run_mod)
					if not a.is_empty():
						a.tile = e.tile
						a.gait = gait
						a.score += _safety(c, u, e.tile) * 60 + e.tile.h * 5 - e.cost * 0.2
						options.append(a)
		options.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score > b.score)
		if not options.is_empty():
			var best: Dictionary = options[0]
			if best.tile == here:
				# vor dem Schuss ducken: +10 AW und +15 VW, kostet 10 %
				if not melee and not u.crouched and not best.weapon.melee and can_toggle.call() and avail - 10 >= Combat.MIN_ATTACK + 20:
					return {"type": &"crouch"}
				return {"type": &"attack", "target": best.target, "weapon": best.weapon, "pct": best.pct}
			return {"type": &"move", "tile": best.tile.pos, "gait": best.gait}

	# kein Angriff möglich: vorrücken (Nahkämpfer sprinten), danach Feuerbereitschaft
	if not memo.moved:
		var dist := _approach_field(c, u)
		var gait: StringName = &"sprinten" if melee and not u.has_attacked else &"laufen"
		var limit := avail if melee else avail - Combat.MIN_OVERWATCH
		if c.can_move(u, gait) and limit >= 0:
			var best_score := -INF
			var best_tile: BattleMap.Tile = null
			var reach := c.move_range(u, gait, limit)
			for p in reach.dest:
				var t: BattleMap.Tile = reach.dest[p].tile
				var cost: float = reach.dest[p].cost
				var dt: float = dist.get(p, 99.0)
				var score: float
				if melee:
					score = -dt * 3 + _safety(c, u, t) * 40 - _exposure(c, u, t) * 14 - cost * 0.1
				else:
					score = -dt * 4 + _safety(c, u, t) * 10 + t.h - cost * 0.1
				if score > best_score:
					best_score = score
					best_tile = t
			if best_tile and best_tile != here and dist.get(best_tile.pos, 99.0) < dist.get(here.pos, 99.0) + 1:
				return {"type": &"move", "tile": best_tile.pos, "gait": gait}
	var ranged := weapons.filter(func(w: WeaponData) -> bool: return not w.melee)
	# vor Feuerbereitschaft oder Zugende ducken (schwerer zu treffen)
	if not melee and not u.crouched and can_toggle.call() and u.act >= 10 + Combat.MIN_OVERWATCH:
		return {"type": &"crouch"}
	if not ranged.is_empty() and c.can_overwatch(u, ranged[0]):
		return {"type": &"overwatch", "weapon": ranged[0]}
	if not melee and not u.crouched and can_toggle.call():
		return {"type": &"crouch"}
	return _finish(c, u, memo)


func _finish(c: Combat, u: Combatant, memo: Dictionary) -> Dictionary:
	return {"type": &"end"} if memo.faced else _face_step(c, u)


func execute(c: Combat, u: Combatant, step: Dictionary) -> bool:
	var memo := _memo_of(c, u)
	match step.type:
		&"move":
			var ok := c.do_move(u, step.tile, step.get("gait", &"gehen"))
			if ok:
				memo.moved = true
			return ok
		&"attack":
			return c.do_attack(u, step.target, step.weapon, step.pct)
		&"overwatch":
			return c.do_overwatch(u, step.weapon)
		&"reload":
			return c.do_reload(u, step.weapon)
		&"crouch":
			memo.toggle_at = memo.moved
			return c.do_crouch(u)
		&"aid":
			return c.do_first_aid(u, step.target)
		&"face":
			memo.faced = true
			return c.do_face(u, step.dir)
	return false


## Ein KI-Schritt für die aktuelle Figur; beendet den Zug, wenn nichts mehr zu tun ist
func act(c: Combat) -> void:
	var u := c.current
	if u == null:
		return
	var step := plan_step(c, u)
	if step.type == &"end" or not execute(c, u, step):
		c.end_turn()
