class_name SpaceAI
extends RefCounted
## Einfache Steuerung für den Raumkampf: Gegner (enemy_orders) und die Crew im Selbstlauf (crew_orders, Test und
## Simulation). Liefert Befehle im Format von SpaceCombat.set_orders.

## Antriebsenergie, die die Crew-KI je Runde einplant (siehe crew_orders)
const ENGINE_SPARE := 2


## Befehle eines Gegnerschiffs für die Phase
static func enemy_orders(c: SpaceCombat, s: SpaceShip, phase: int) -> Dictionary:
	match phase:
		SpaceCombat.Phase.MOVE:
			return move_plan(c, s, c.own, 2 if s.is_fighter() else _pref_range(s))
		SpaceCombat.Phase.FIRE:
			var t := {}
			for slot in s.weapon_slots():
				if c.fire_problem(s, slot, c.own) == "":
					t[slot] = c.own.id
			return {"targets": t}
	return {}


## Befehle der Crew für die Phase (Selbstlauf)
static func crew_orders(c: SpaceCombat, phase: int) -> Dictionary:
	var own := c.own
	var foes := c.active_enemies()
	if foes.is_empty():
		return {}
	var flee := own.hull < own.hull_max / 4 and c.can_jump()
	match phase:
		SpaceCombat.Phase.SHIELDS:
			var e := c.energy_total
			var jump := SpaceCombat.JUMP_ENERGY if flee else 0
			var rest := e - jump
			var sh := rest * 2 / 5
			var eng := mini(2, rest - sh)
			var alloc: Array = []
			var near := _nearest(own, foes)
			var front := own.side_toward(near.pos)
			var pool := mini(own.shield_total() + sh * SpaceCombat.SHIELD_PER_ENERGY, own.shield_max * 6)
			for i in 6:
				var dist := mini(posmod(i - front, 6), posmod(front - i, 6))
				alloc.append([3, 2, 1, 1][dist])
			var weight := 0
			for v in alloc:
				weight += int(v)
			for i in 6:
				alloc[i] = mini(own.shield_max, pool * int(alloc[i]) / weight)
			return {"energy": {"jump": jump, "shields": sh, "engine": eng, "weapons": rest - sh - eng}, "alloc": alloc}
		SpaceCombat.Phase.MOVE:
			return crew_move_plan(c)
		SpaceCombat.Phase.FIRE:
			var t := {}
			for slot in own.weapon_slots():
				var best: SpaceShip = null
				var abwehr: bool = ShipWeapons.data(String(own.slots[slot].key)).art == "abwehr"
				for f in foes:
					if c.fire_problem(own, slot, f) != "":
						continue
					if best == null or _target_score(f, abwehr) > _target_score(best, abwehr):
						best = f
				if best:
					t[SpaceSetup.gun_station(slot)] = best.id
			return {"targets": t}
		SpaceCombat.Phase.TECH:
			var o := {}
			var todo: Array = own.damage.keys()
			todo.sort_custom(func(a, b) -> bool: return own.dmg_level(String(a)) > own.dmg_level(String(b)))
			var tech := {}
			for st in SpaceSetup.BASE_STATIONS + SpaceSetup.EXTRA_TECH:
				if not SpaceSetup.is_tech(st) or not c.tech_active(st):
					continue
				if not todo.is_empty():
					tech[st] = [{"repair": String(todo.pop_front())}]
				elif own.hull < own.hull_max * 7 / 10:
					tech[st] = [{"patch": true}]
			if not tech.is_empty():
				o["technik"] = tech
			var big: SpaceShip = foes[0]
			for f in foes:
				if f.cls > big.cls:
					big = f
			o["computer"] = {"mode": "lock", "target": big.id}
			if flee:
				o["jump"] = true
			return o
	return {}


static func _pref_range(s: SpaceShip) -> int:
	var r := 3
	for slot in s.weapon_slots():
		r = maxi(r, int(ShipWeapons.data(String(s.slots[slot].key)).range) * 2 / 3)
	return r


static func _nearest(s: SpaceShip, foes: Array[SpaceShip]) -> SpaceShip:
	var best: SpaceShip = foes[0]
	for f in foes:
		if Hex.distance(s.pos, f.pos) < Hex.distance(s.pos, best.pos):
			best = f
	return best


static func _target_score(f: SpaceShip, abwehr: bool) -> float:
	var s := 1.0 - float(f.hull) / maxf(1.0, f.hull_max)
	if abwehr and f.is_fighter():
		s += 2.0
	return s


## Mögliche Bewegungspläne: Tempo ±1, Drehungen (eine Richtung) an einer Stelle des Wegs
static func candidates(c: SpaceCombat, s: SpaceShip, max_turns: int) -> Array:
	var out: Array = []
	for spd in range(maxi(0, s.speed - 1), mini(c.max_speed_of(s), s.speed + 1) + 1):
		for dir in ["L", "R"]:
			for n in range(0, max_turns + 1):
				for at in range(0, spd + 1):
					if n == 0 and (dir == "R" or at > 0):
						continue
					var steps: Array = []
					for i in spd + 1:
						if i == at:
							for k in n:
								steps.append(dir)
						if i < spd:
							steps.append("F")
					out.append(steps)
	return out


## Bewegungsplan der Crew: so viele Waffen wie möglich feuerbereit gegen die geschätzten Gegnerpositionen
## (wie der Ziel-Check der Oberfläche), dann nicht zu nah und nicht zu weit
static func crew_move_plan(c: SpaceCombat) -> Dictionary:
	var own := c.own
	var foes := c.active_enemies()
	var pred := c.predict_enemies()
	var best := {"speed": own.speed, "steps": []}
	var best_score := -INF
	var spare := ENGINE_SPARE
	for steps in candidates(c, own, own.turns):
		if steps.count("F") > SpaceCombat.ENGINE_FREE + spare:
			continue
		var pv := c.plan_path(own, steps)
		var pf := c.preview_fire(pv.end, pv.facing, pred)
		var score := 0.0
		for slot in pf:
			var w := ShipWeapons.data(String(own.slots[slot].key))
			for row in pf[slot]:
				if row.why == "":
					score += float(w.dmg) * int(w.shots)
					break
		var near := 99
		for f in foes:
			var p: Vector2i = pred.get(f.id, {}).get("pos", f.pos)
			near = mini(near, Hex.distance(pv.end, p))
		if near < 2:
			score -= 1.0
		score -= absf(near - 4) * 0.15
		# keine Waffe frei: lieber annähern und in Bewegung bleiben als stehen (kein Patt hinter Asteroiden)
		if score <= 0.0:
			score -= near * 0.5 + (1.0 if steps.count("F") == 0 else 0.0)
		if pv.blocked:
			score -= 3.0
		if score > best_score:
			best_score = score
			best = {"speed": steps.count("F"), "steps": steps}
	return best


## Bewegungsplan: alle Tempi (±1) und Drehfolgen durchprobieren, bester Abstand und Bug zum Ziel
static func move_plan(c: SpaceCombat, s: SpaceShip, target: SpaceShip, want_range: int) -> Dictionary:
	var best := {"speed": s.speed, "steps": []}
	var best_score := INF
	for steps in candidates(c, s, s.turns + 1):
		var pv := c.plan_path(s, steps)
		var end: Vector2i = pv.end
		var ghost := SpaceShip.new()
		ghost.pos = end
		ghost.facing = pv.facing
		var score := absf(Hex.distance(end, target.pos) - want_range) * 2.0 + absf(ghost.bearing(target.pos)) / 60.0
		if pv.blocked:
			score += 5.0
		if not c.has_los(end, target.pos):
			score += 3.0
		if score < best_score:
			best_score = score
			best = {"speed": steps.count("F"), "steps": steps}
	return best
