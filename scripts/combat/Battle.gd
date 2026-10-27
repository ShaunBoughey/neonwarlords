class_name Battle
extends RefCounted
## Turn-meter combat engine. Pure logic: the battle scene drives it and animates the event log.
##
## Usage:  b.setup(allies, waves, opts); b.start(); loop { var t = b.next_turn(); if t == null: break;
##         choose (ability, target) for t.actor (or b.ai_choose); b.act(actor, ab_id, target_uid) }
## Every state change appends an event Dictionary to b.events (drain with b.take_events()).

const TM_FULL := 1000.0
## GDD worked example: 1518 armour = 50% mitigation, so mitigation = arm / (arm + 1518).
const ARMOUR_K := 1518.0
## Global damage multiplier: sets fight length (target ~15-40 player turns for an even fight).
## Retuned 2.2 -> 1.6 for ARMOUR_K 1518 (wave 1; BalanceProbe and ClassProbe in review/reports/05_combat.md).
const DAMAGE_SCALE := 1.6
const MAX_MITIGATION := 0.8

var rng := RandomNumberGenerator.new()
var units: Array = []          # every unit ever in the fight (dead ones stay with alive=false)
var waves: Array = []          # remaining enemy waves (arrays of unit dicts)
var wave_no := 1
var wave_total := 1
var reinforcements: Array = [] # Pit Royal: player side units waiting to enter
var opts: Dictionary = {}
var events: Array = []
var result := ""               # "", "win", "loss", "timeout"
var turn_count := 0
var enemy_reinforcements: Array = []
## Overtime (anti-stall): after OVERTIME_AT turns healing is cut and damage rises every
## OVERTIME_STEP turns, so sustain loops (e.g. Issac Vaun's Cash Injection) cannot stall forever.
const OVERTIME_AT := 140
const OVERTIME_STEP := 40
var _overtime := 0

func overtime_level() -> int:
	return 0 if turn_count < OVERTIME_AT else 1 + (turn_count - OVERTIME_AT) / OVERTIME_STEP
var player_turns := 0
var _uid_counter := 0
var _in_assist := false
var _ally_died := false
var _extra_uid := ""          # unit owed an extra turn: acts next, before anyone else over 100% TM
var debuffs_placed_by_player := 0
var debuffs_on_boss := 0       # player debuffs that landed on a boss (Bastion ambitions)

# ================================================================ unit factory
## Build a combat unit from a warlord instance ({tpl, level, rank, rep, ab, nn, gear}).
static func make_unit(w: Dictionary, side: int, enemy_bonus := 0.0, boss_mult := 1.0) -> Dictionary:
	var t: Dictionary = Warlords.get_t(w.tpl)
	var st: Dictionary = Game.compute_stats(w, enemy_bonus)
	var u := {
		"uid": "", "side": side, "tpl": w.tpl, "name": t.name, "cls": t.cls, "syn": t.syn, "align": t.align, "rarity": t.rarity,
		"level": w.level, "rank": w.rank, "rep": w.get("rep", 0), "boss": t.get("boss", false) or boss_mult > 1.0,
		"base": {"hp": st.hp * boss_mult, "arm": st.arm, "fp": st.fp, "spd": st.spd, "cc": st.cc, "cd": st.cd, "hack": st.hack, "fw": st.fw},
		"sets": st.sets, "nn": w.get("nn", {}).duplicate(), "ab_lv": w.get("ab", {}).duplicate(),
		"abilities": t.abilities, "immune": [], "specials": [],
		"owner_uid": w.get("uid", ""),
	}
	for a in t.abilities:
		if a.type == "passive":
			for im in a.get("immune", []):
				u.immune.append(im)
			if a.has("special"):
				u.specials.append(a.special)
	if t.get("boss", false) or boss_mult > 1.0:
		u.boss = true
	return u

# ================================================================ setup
func setup(allies: Array, enemy_waves: Array, o := {}) -> void:
	opts = o
	if o.has("seed"):
		rng.seed = o.seed
	else:
		rng.randomize()
	wave_total = enemy_waves.size()
	waves = enemy_waves.duplicate()
	for u in allies:
		_add_unit(u)
	for u in o.get("reinforcements", []):
		reinforcements.append(u)
	for u in o.get("enemy_reinforcements", []):
		enemy_reinforcements.append(u)
	for u in waves.pop_front():
		_add_unit(u)

func _add_unit(u: Dictionary) -> Dictionary:
	_uid_counter += 1
	u.uid = "u%d" % _uid_counter
	u.max_hp = float(u.base.hp)
	u.hp = u.max_hp
	u.tm = rng.randf_range(0.0, 60.0)
	u.alive = true
	u.buffs = []
	u.debuffs = []
	u.cds = {}
	u.kills = 0
	u.uses = 0
	u.first_attack = true
	u.first_hit = true
	u.dmg_dealt = 0.0
	u.dmg_taken = 0.0
	u.healed = 0.0
	u.special_cd = {}
	u.fp_stacks = 0.0
	u.low_fired = false
	u.countered_turn = -1
	for a in u.abilities:
		if a.type == "active":
			u.cds[a.id] = 0
	units.append(u)
	return u

func take_events() -> Array:
	var e := events
	events = []
	return e

func _ev(d: Dictionary) -> void:
	events.append(d)

func unit(uid: String):
	for u in units:
		if u.uid == uid:
			return u
	return null

func side_units(side: int, alive_only := true) -> Array:
	return units.filter(func(u): return u.side == side and (u.alive or not alive_only))

func foes(u: Dictionary) -> Array:
	return side_units(1 - u.side)

func friends(u: Dictionary) -> Array:
	return side_units(u.side)

# ================================================================ start
func start() -> void:
	for side in [0, 1]:
		_apply_leader(side)
		_apply_formations(side)
	for u in units:
		u.max_hp = float(u.base.hp)
		u.hp = u.max_hp
	_round_start_effects(true)
	_ev({"e": "start"})

func _apply_leader(side: int) -> void:
	var team := side_units(side)
	if team.is_empty():
		return
	var leader: Dictionary = team[0]
	for a in leader.abilities:
		if a.type != "leader":
			continue
		var lvm := 1.0 + Data.ABILITY_LEVEL_BONUS * (int(leader.ab_lv.get(a.id, 1)) - 1)
		var aura: Dictionary = a.aura
		for u in team:
			if aura.syn != "" and u.syn != aura.syn:
				continue
			for st in aura.stats:
				var v: float = aura.stats[st] * lvm
				match st:
					"hpP": u.base.hp *= 1.0 + v / 100.0
					"armP": u.base.arm *= 1.0 + v / 100.0
					"fpP": u.base.fp *= 1.0 + v / 100.0
					"spdP": u.base.spd *= 1.0 + v / 100.0
					_: u.base[st] += v
		_ev({"e": "text", "u": leader.uid, "t": "Leader: " + a.name})

func _apply_formations(side: int) -> void:
	# snapshot armour first so two carriers don't compound each other's bonus
	var base_arm := {}
	for u in side_units(side):
		base_arm[u.uid] = float(u.base.arm)
	for u in side_units(side):
		var v := _nn(u, "formations")
		if v > 0.0:
			for o in side_units(side):
				if o != u:
					o.base.arm += base_arm[u.uid] * v / 100.0

## Effects at the start of a combat round (battle start or a new wave).
func _round_start_effects(first: bool) -> void:
	for u in units.filter(func(x): return x.alive):
		if first or u.side == 1:
			_hooks(u, "battle_start", {})
			var fs := _nn(u, "foresight")
			if fs > 0.0 and first:
				for f in friends(u):
					_shield(u, f, u.max_hp * fs / 100.0, 3)
		# set effects fire every round (each wave), like Safeguard
		if _set_active(u, "Jamming"):
			_place_buff(u, u, {"id": "blockDebuffs", "turns": 2, "l": 0}, true)
		if _set_active(u, "Safeguard"):
			for f in friends(u):
				_shield(u, f, u.max_hp * 0.30, 3)
		if not first and u.side == 0:
			_reinforce_fx(u)

func _reinforce_fx(u: Dictionary) -> void:
	for a in u.abilities:
		if a.type == "reinforce":
			_ev({"e": "text", "u": u.uid, "t": a.name})
			_apply_fx(u, a, a.fx, [], {})

# ================================================================ helpers
func _set_active(u: Dictionary, sname: String) -> bool:
	return int(u.sets.get(sname, 0)) >= int(Data.SETS[sname].pieces)

func _nn(u: Dictionary, id: String) -> float:
	var p := int(u.nn.get(id, 0))
	if p <= 0:
		return 0.0
	return float(Data.NN_BY_ID[id].v[p - 1])

func _has_special(u: Dictionary, s: String) -> bool:
	return u.specials.has(s)

func has_debuff(u: Dictionary, id: String) -> bool:
	for d in u.debuffs:
		if d.id == id:
			return true
	return false

func has_buff(u: Dictionary, id: String) -> bool:
	for b in u.buffs:
		if b.id == id:
			return true
	return false

func debuff_count(u: Dictionary, id := "") -> int:
	if id == "":
		return u.debuffs.size()
	return u.debuffs.filter(func(d): return d.id == id).size()

func _buff_sum(u: Dictionary, id: String) -> float:
	var s := 0.0
	for b in u.buffs:
		if b.id == id:
			s += float(b.v)
	return s

func _debuff_sum(u: Dictionary, id: String) -> float:
	var s := 0.0
	for d in u.debuffs:
		if d.id == id:
			s += float(d.v)
	return s

func eff(u: Dictionary, stat: String) -> float:
	var b: float = u.base[stat]
	match stat:
		"spd": return max(1.0, b * (1.0 + (_buff_sum(u, "spdUp") - _debuff_sum(u, "spdDown")) / 100.0))
		"arm":
			# GDD: buffs and passives are separate multipliers
			var m := 1.0 + (_buff_sum(u, "armUp") - _debuff_sum(u, "armDown")) / 100.0
			var pm := 1.0
			if u.tpl == "hammer_of_four":
				for f in friends(u):
					if _has_special(f, "shield_wall"):
						pm += 0.20
			return max(0.0, b * max(0.0, m) * pm)
		"fp": return max(0.0, b * _fp_mod(u))
		"hack": return max(0.0, b + _buff_sum(u, "hackUp") - _debuff_sum(u, "hackDown") - (50.0 if has_debuff(u, "stupefy") else 0.0))
		"fw": return max(0.0, b + _buff_sum(u, "fwUp") - _debuff_sum(u, "fwDown"))
		"cc": return clamp(b + _buff_sum(u, "ccUp") - _debuff_sum(u, "ccDown"), 0.0, 100.0)
		"cd": return max(0.0, b + _buff_sum(u, "cdUp") - _debuff_sum(u, "cdDown"))
	return b

## Firepower buff/debuff factor times the passive stack factor (GDD: separate multipliers).
func _fp_mod(u: Dictionary) -> float:
	return max(0.0, 1.0 + (_buff_sum(u, "fpUp") - _debuff_sum(u, "fpDown")) / 100.0) * (1.0 + u.fp_stacks / 100.0)

func _scaling(u: Dictionary) -> float:
	var fpmod: float = _fp_mod(u)
	# firepower is already buff-adjusted inside eff(); other classes take the firepower buffs as a multiplier
	var c: Dictionary = Data.CLASS_SCALING.get(u.cls, {"fp": 1.0})
	var v: float = eff(u, "fp") * float(c.get("fp", 0.0))
	v += (u.max_hp * float(c.get("hp", 0.0)) + eff(u, "arm") * float(c.get("arm", 0.0)) + eff(u, "hack") * float(c.get("hack", 0.0))) * fpmod
	return v

func ab_level_mult(u: Dictionary, a: Dictionary) -> float:
	return 1.0 + Data.ABILITY_LEVEL_BONUS * (int(u.ab_lv.get(a.id, 1)) - 1)

func get_ability(u: Dictionary, id: String):
	for a in u.abilities:
		if a.id == id:
			return a
	return null

func actives(u: Dictionary) -> Array:
	return u.abilities.filter(func(a): return a.type == "active")

func ability_ready(u: Dictionary, a: Dictionary) -> bool:
	return a.type == "active" and not a.get("auto", false) and int(u.cds.get(a.id, 0)) <= 0

func basic(u: Dictionary) -> Dictionary:
	return actives(u)[0]

# ================================================================ turn flow
## Advance turn meters until someone acts. Returns {actor, forced_target} or null when the battle is over.
func next_turn():
	var guard := 0
	while result == "" and guard < 200:
		guard += 1
		var ready := units.filter(func(u): return u.alive and u.tm >= TM_FULL)
		if ready.is_empty():
			var dt := INF
			for u in units:
				if u.alive:
					dt = min(dt, (TM_FULL - u.tm) / eff(u, "spd"))
			if dt == INF:
				_check_end()
				return null
			for u in units:
				if u.alive:
					u.tm += eff(u, "spd") * dt
			continue
		ready.sort_custom(func(a, b): return a.tm > b.tm)
		var actor: Dictionary = ready[0]
		# GDD: meters pause for extra turns, so the extra-turn unit cannot be pre-empted
		if _extra_uid != "":
			for r in ready:
				if r.uid == _extra_uid:
					actor = r
			_extra_uid = ""
		actor.tm = TM_FULL
		turn_count += 1
		if overtime_level() > _overtime:
			_overtime = overtime_level()
			_ev({"e": "overtime", "lvl": _overtime})
		if actor.side == 0:
			# check the limit before counting, so player_turns never reports limit + 1
			if opts.get("turn_limit", 0) > 0 and player_turns >= int(opts.turn_limit):
				result = "timeout"
				_ev({"e": "end", "result": result})
				return null
			player_turns += 1
		if turn_count > int(opts.get("max_turns", 400)):
			result = "loss"
			_ev({"e": "end", "result": result})
			return null
		_ev({"e": "turn", "u": actor.uid})
		if not _turn_start(actor):
			_end_turn(actor, false)
			continue
		if not actor.alive:
			_end_turn(actor, false)
			continue
		if result != "":
			return null
		# Cormac's Devour fires automatically when an enemy has 5 bleed stacks
		var dev = get_ability(actor, "devour")
		if dev != null:
			for f in foes(actor):
				if debuff_count(f, "bleed") >= 5:
					return {"actor": actor, "forced_ab": "devour", "forced_target": f.uid}
		var enr = _enraged_by(actor)
		if enr != null:
			return {"actor": actor, "forced_ab": basic(actor).id, "forced_target": enr.uid}
		return {"actor": actor}
	return null

func _enraged_by(u: Dictionary):
	for d in u.debuffs:
		if d.id == "enraged":
			var src = unit(d.src)
			if src != null and src.alive:
				return src
	return null

## Returns false if the actor loses this turn (stun, shock, death by DoT...).
func _turn_start(u: Dictionary) -> bool:
	for k in u.cds:
		u.cds[k] = max(0, int(u.cds[k]) - 1)
	for k in u.special_cd:
		u.special_cd[k] = max(0, int(u.special_cd[k]) - 1)
	# damage over time
	for d in u.debuffs.duplicate():
		if not u.alive:
			break
		if d.id == "poison":
			_raw_damage(unit(d.src), u, u.max_hp * float(d.v) / 100.0, "poison")
		elif d.id == "bleed":
			_raw_damage(unit(d.src), u, max(1.0, float(d.get("hit", 0.0)) * float(d.v) / 100.0), "bleed")
	if not u.alive:
		return false
	var ch := _buff_sum(u, "contHeal")
	if ch > 0.0:
		_heal(u, u, u.max_hp * ch / 100.0, false)
	if _set_active(u, "Stitcher"):
		for f in friends(u):
			_heal(u, f, u.max_hp * 0.10, false)
	_hooks(u, "turn_start", {})
	if _has_special(u, "rampage"):
		u.fp_stacks = min(100.0, u.fp_stacks + 10.0)
	if _has_special(u, "mass") or _has_special(u, "prayer"):
		if int(u.special_cd.get("minion", 0)) <= 0:
			for f in friends(u):
				if f.tpl == "deacon_chainz":
					if _has_special(u, "mass"):
						_place_buff(u, f, {"id": "armUp", "turns": 2, "l": 1}, true)
					else:
						_place_buff(u, f, {"id": "contHeal", "turns": 2, "l": 0}, true)
					u.special_cd["minion"] = 3
	if _has_special(u, "ragnarok") and int(u.special_cd.get("ragnarok", 0)) <= 0:
		var dead := side_units(u.side, false).filter(func(x): return not x.alive and x.tpl == "raider" and not has_debuff(x, "blockRevive"))
		if not dead.is_empty() and not opts.get("no_revive", false):
			_revive(u, dead[0], 30.0)
			u.special_cd["ragnarok"] = 3
			var tg = _ai_target(u, get_ability(u, "thunder_god"))
			if tg != null:
				_ev({"e": "text", "u": u.uid, "t": "Ragnarok!"})
				_assist(u, get_ability(u, "thunder_god"), tg)
	if result != "":
		return false
	# crowd control
	if has_debuff(u, "stun"):
		_ev({"e": "skip", "u": u.uid, "why": "Stunned"})
		return false
	if has_debuff(u, "shock") and rng.randf() * 100.0 < _debuff_sum(u, "shock"):
		_ev({"e": "skip", "u": u.uid, "why": "Shocked"})
		return false
	if has_debuff(u, "stupefy") and rng.randf() * 100.0 < 35.0:
		_ev({"e": "skip", "u": u.uid, "why": "Stupefied"})
		return false
	return true

func _end_turn(u: Dictionary, extra: bool) -> void:
	u.tm = TM_FULL if extra and u.alive else 0.0
	_extra_uid = u.uid if extra and u.alive else ""
	_tick_effects(u)
	_check_end()

func _tick_effects(u: Dictionary) -> void:
	for b in u.buffs.duplicate():
		b.turns -= 1
		if b.turns <= 0:
			u.buffs.erase(b)
			_ev({"e": "expire", "u": u.uid, "id": b.id})
			var src = unit(b.get("src", ""))
			if src and src.alive and rng.randf() * 100.0 < _nn(src, "packetFilter"):
				_tm(src, src, 10.0, true)
	for d in u.debuffs.duplicate():
		d.turns -= 1
		if d.turns <= 0:
			u.debuffs.erase(d)
			_ev({"e": "expire", "u": u.uid, "id": d.id})
			var src2 = unit(d.get("src", ""))
			if src2 and src2.alive and rng.randf() * 100.0 < _nn(src2, "exploits"):
				_tm(src2, src2, 10.0, true)

func _check_end() -> void:
	if result != "":
		return
	if side_units(0).is_empty() and reinforcements.is_empty():
		result = "loss"
		_ev({"e": "end", "result": result})
		return
	if side_units(1).is_empty():
		if waves.is_empty():
			result = "win"
			_ev({"e": "end", "result": result})
		else:
			wave_no += 1
			var nw: Array = waves.pop_front()
			for u in nw:
				_add_unit(u)
				u.max_hp = float(u.base.hp)
				u.hp = u.max_hp
			_apply_leader(1)
			for u in nw:
				u.max_hp = float(u.base.hp)
				u.hp = u.max_hp
			_ev({"e": "wave", "n": wave_no, "units": nw.map(func(x): return x.uid)})
			_round_start_effects(false)

# ================================================================ acting
func act(actor: Dictionary, ab_id: String, target_uid: String) -> void:
	var a = get_ability(actor, ab_id)
	if a == null:
		a = basic(actor)
	var target = unit(target_uid)
	actor.uses += 1
	actor.cds[a.id] = int(a.get("cd", 0))
	var extra := _use_ability(actor, a, target, false)
	_end_turn(actor, extra)

## Execute an ability. Returns true if the actor earned an extra turn.
func _use_ability(u: Dictionary, a: Dictionary, target, assist: bool) -> bool:
	var targets := _resolve_targets(u, a, target)
	_ev({"e": "ability", "u": u.uid, "ab": a.name, "id": a.id, "targets": targets.map(func(x): return x.uid), "assist": assist})
	var ctx := {"crit": false, "kill": false, "primary": target, "hit": {}}
	# effects flagged "pre" happen before damage (buffs on self, strips...)
	var pre: Array = a.get("fx", []).filter(func(f): return f.get("pre", false))
	var post: Array = a.get("fx", []).filter(func(f): return not f.get("pre", false))
	if not pre.is_empty():
		_apply_fx(u, a, pre, targets, ctx)
	if float(a.get("mult", 0.0)) > 0.0:
		var hits := int(a.get("hits", 1))
		for h in hits:
			if a.get("random_targets", false):
				var live := foes(u)
				if live.is_empty():
					break
				var t1: Dictionary = live[rng.randi_range(0, live.size() - 1)]
				_attack(u, t1, a, ctx)
				_apply_fx(u, a, post, [t1], ctx)
			else:
				for t in targets:
					if t.alive:
						_attack(u, t, a, ctx)
				if hits > 1:
					_apply_fx(u, a, post.filter(func(f): return f.t == "debuff"), targets, ctx)
		if hits > 1 and not a.get("random_targets", false):
			_apply_fx(u, a, post.filter(func(f): return f.t != "debuff"), targets, ctx)
		elif hits == 1:
			_apply_fx(u, a, post, targets, ctx)
	else:
		_apply_fx(u, a, post, targets, ctx)
	_special_after(u, a, target, ctx)
	if float(a.get("mult", 0.0)) > 0.0:
		u.first_attack = false   # Blitz: only a damaging skill uses up the first attack
	return ctx.get("extra_turn", false)

func _resolve_targets(u: Dictionary, a: Dictionary, target) -> Array:
	match a.get("tgt", "enemy"):
		"all_enemies": return foes(u)
		"all_allies": return friends(u)
		"self": return [u]
		"ally":
			if target != null and target.alive and target.side == u.side:
				return [target]
			return [u]
		_:
			if target != null and target.alive and target.side != u.side:
				return [target]
			var f := foes(u)
			return [] if f.is_empty() else [f[0]]

func _assist(u: Dictionary, a: Dictionary, target: Dictionary) -> void:
	if a == null or target == null or not target.alive or not u.alive:
		return
	var was := _in_assist
	_in_assist = true
	_use_ability(u, a, target, true)
	_in_assist = was

# ================================================================ damage
func _attack(src: Dictionary, tgt: Dictionary, a: Dictionary, ctx: Dictionary, counter := false) -> float:
	if not tgt.alive or not src.alive:
		return 0.0
	var mult: float = float(a.get("mult", 1.0))
	var dmg := _scaling(src) * mult * ab_level_mult(src, a) * DAMAGE_SCALE
	var bonus := 0.0
	# neuronet assault bonuses
	if src.first_attack:
		bonus += _nn(src, "blitz")
	if tgt.hp > src.hp:
		bonus += _nn(src, "grandChallenge")
	bonus += min(_nn(src, "bloodFrenzy") * src.kills, _nn(src, "bloodFrenzy") * 3.0)
	bonus += min(_nn(src, "accruing") * max(0, src.uses - 1), _nn(src, "accruing") * 3.0)
	if not tgt.debuffs.is_empty():
		bonus += _nn(src, "openOpp")
	bonus += min(_nn(src, "berserker") * src.debuffs.size(), _nn(src, "berserker") * 3.0)
	var hp_pct: float = tgt.hp / tgt.max_hp * 100.0
	if hp_pct <= 50.0:
		bonus += _nn(src, "pummel")
		if _has_special(src, "predator"):
			bonus += 15.0
	if _has_special(src, "conductive") and has_debuff(tgt, "shock"):
		bonus += 15.0
	dmg *= 1.0 + bonus / 100.0
	# ability conditionals
	if a.has("vs"):
		var vs: Dictionary = a.vs
		var hit := false
		if vs.has("debuff") and has_debuff(tgt, vs.debuff): hit = true
		if vs.get("debuffed", false) and not tgt.debuffs.is_empty(): hit = true
		if vs.get("buffed", false) and not tgt.buffs.is_empty(): hit = true
		if hit:
			dmg *= float(vs.mult)
	if a.has("below") and hp_pct <= float(a.below.pct):
		dmg *= float(a.below.mult)
	# crit
	var crit := rng.randf() * 100.0 < eff(src, "cc")
	if crit:
		dmg *= 1.0 + eff(src, "cd") / 100.0 + float(a.get("crit_bonus", 0)) / 100.0
		ctx.crit = true
	# mark & break
	for d in tgt.debuffs.duplicate():
		if d.id == "mark":
			dmg *= float(d.v)
			tgt.debuffs.erase(d)
			_ev({"e": "expire", "u": tgt.uid, "id": "mark"})
			break
	dmg *= 1.0 + _debuff_sum(tgt, "break") / 100.0
	# armour mitigation (GDD): mitigation % from total armour, then armour penetration is taken
	# off that percentage, e.g. 5437 x (1 - (50% - 5%)) = 2990. The game's "ignore X% armour"
	# effects (Fracture, Ripper, Celestial Strike/Smite, Devour, ability ignore_arm) are the
	# penetration sources, so they all go through this one step.
	var ignore: float = float(a.get("ignore_arm", 0))
	if a.get("special", "") == "celestial_enraged" or a.get("special", "") == "celestial_break":
		var primary := "enraged" if a.special == "celestial_enraged" else "break"
		var other := "break" if primary == "enraged" else "enraged"
		if has_debuff(tgt, primary):
			ignore = 100.0 if has_debuff(tgt, other) else 50.0
	if _set_active(src, "Ripper"):
		ignore += 25.0
	if rng.randf() * 100.0 < _nn(src, "fracture"):
		ignore += 30.0
	var pen: float = clampf(ignore + float(src.get("pen", 0.0)), 0.0, 100.0)
	var arm: float = eff(tgt, "arm")
	var mit: float = maxf(0.0, min(MAX_MITIGATION, arm / (arm + ARMOUR_K)) - pen / 100.0)
	dmg *= 1.0 - mit
	dmg *= 1.0 - _buff_sum(tgt, "bolster") / 100.0
	if tgt.first_hit:
		dmg *= 1.0 - _nn(tgt, "prepared") / 100.0
		tgt.first_hit = false
	if _has_special(tgt, "drone_shield") and friends(tgt).any(func(x): return x.tpl == "synapse_drone"):
		dmg *= 0.5
	if _has_special(tgt, "vault_plating") and tgt.hp > tgt.max_hp * 0.5:
		dmg *= 0.75
	if _has_special(tgt, "neutral_ground") and not src.buffs.is_empty():
		dmg *= 0.7
	dmg *= rng.randf_range(0.95, 1.05)
	if rng.randf() * 100.0 < _nn(src, "wrath"):
		dmg *= 1.5
	dmg = max(1.0, round(dmg))
	var shocked_before := has_debuff(tgt, "shock")
	var dealt := _deal(src, tgt, dmg, crit, counter)
	ctx.hit[tgt.uid] = float(ctx.hit.get(tgt.uid, 0.0)) + dealt
	# on-hit effects for the attacker
	var steal := float(a.get("lifesteal", 0)) + _buff_sum(src, "vampire")
	if _set_active(src, "Energy Drain"):
		steal += 30.0
	if src.hp <= src.max_hp * 0.3:
		steal += _nn(src, "siphon")
	if steal > 0.0 and dealt > 0.0:
		_heal(src, src, dealt * steal / 100.0, false)
	for sname in src.sets:
		var sd: Dictionary = Data.SETS[sname]
		if sd.get("effect", "") == "onHit" and _set_active(src, sname) and tgt.alive:
			_place_debuff(src, tgt, {"id": sd.debuff, "turns": 1 if sd.debuff in ["stun", "enraged", "shock"] else 2, "chance": sd.val, "l": 0}, ctx)
	if a.get("special", "") == "hammer_time" and shocked_before:
		for f in friends(src):
			if f.tpl == "hammer_of_four":
				_heal(src, f, f.max_hp * 0.10, false)
	if a.get("special", "") == "random_debuff" and tgt.alive and rng.randf() < 0.4:
		_place_debuff(src, tgt, {"id": ["armDown", "fpDown", "spdDown", "poison", "healBlock"][rng.randi_range(0, 4)], "turns": 2, "chance": 100, "l": 0}, ctx)
	if not tgt.alive:
		ctx.kill = true
		return dealt
	# reactions of the target
	var refl := _buff_sum(tgt, "reflect") + (30.0 if _set_active(tgt, "Pain Mirror") else 0.0)
	if refl > 0.0 and dealt > 0.0 and src.alive:
		_raw_damage(tgt, src, dealt * refl / 100.0, "reflect")
	_hooks(tgt, "hit_taken", {"src": src})
	if not counter and not _in_assist and src.alive and tgt.alive and tgt.countered_turn != turn_count:
		var cchance := _buff_sum(tgt, "counter")
		if _set_active(tgt, "Strike Back"):
			cchance += 50.0
		if crit:
			cchance += _nn(tgt, "parry")
		if rng.randf() * 100.0 < cchance:
			tgt.countered_turn = turn_count
			_ev({"e": "text", "u": tgt.uid, "t": "Counter!"})
			_ev({"e": "ability", "u": tgt.uid, "ab": basic(tgt).name, "id": basic(tgt).id, "targets": [src.uid], "assist": true})
			_attack(tgt, src, basic(tgt), {"crit": false, "kill": false, "hit": {}}, true)
	if crit and not counter and src.alive:
		for f in friends(tgt):
			if f != tgt and f.countered_turn != turn_count and rng.randf() * 100.0 < _nn(f, "whiteKnight"):
				f.countered_turn = turn_count
				_ev({"e": "text", "u": f.uid, "t": "White Knight!"})
				_attack(f, src, basic(f), {"crit": false, "kill": false, "hit": {}}, true)
				break
	return dealt

## Apply already-mitigated damage, handling overshield, Guardian Angel and death.
func _deal(src, tgt: Dictionary, dmg: float, crit: bool, _counter := false) -> float:
	# guardian angel redirects part of the damage to the guardian
	for g in friends(tgt):
		if g != tgt and _nn(g, "guardian") > 0.0:
			var part: float = round(dmg * _nn(g, "guardian") / 100.0)
			dmg -= part
			_absorb_and_apply(src, g, part, false)
			break
	return _absorb_and_apply(src, tgt, dmg, crit)

func _absorb_and_apply(src, tgt: Dictionary, dmg: float, crit: bool) -> float:
	if not tgt.alive or dmg <= 0.0:
		return 0.0
	if _overtime > 0:
		dmg = round(dmg * (1.0 + 0.2 * _overtime))
	var rest := dmg
	for b in tgt.buffs.duplicate():
		if b.id == "overshield" and rest > 0.0:
			var take: float = min(rest, float(b.shield))
			b.shield = float(b.shield) - take
			rest -= take
			if b.shield <= 0.0:
				tgt.buffs.erase(b)
	var before: float = tgt.hp
	tgt.hp -= rest
	if tgt.hp < 1.0 and has_buff(tgt, "unkillable"):
		tgt.hp = 1.0
	var dealt: float = before - max(0.0, tgt.hp) + (dmg - rest)
	tgt.dmg_taken += dealt
	if src != null:
		src.dmg_dealt += dealt
	_ev({"e": "dmg", "u": tgt.uid, "v": int(dmg), "crit": crit, "hp": max(0.0, tgt.hp), "src": src.uid if src != null else ""})
	if tgt.hp <= 0.0:
		_die(tgt, src)
	elif tgt.hp < tgt.max_hp * 0.25 and not tgt.low_fired:
		tgt.low_fired = true
		for f in friends(tgt):
			if f != tgt:
				var rr := _nn(f, "rapidRescue")
				if rr > 0.0:
					_tm(f, f, rr, true)
				_hooks(f, "ally_low", {"ally": tgt})
	return dealt

## Damage that ignores armour (DoTs, reflect).
func _raw_damage(src, tgt: Dictionary, dmg: float, kind: String) -> void:
	if not tgt.alive:
		return
	_ev({"e": "text", "u": tgt.uid, "t": kind})
	_absorb_and_apply(src, tgt, round(dmg), false)

func _die(u: Dictionary, killer) -> void:
	u.hp = 0.0
	u.alive = false
	u.tm = 0.0
	u.buffs = []
	var kept: Array = u.debuffs.filter(func(d): return d.id == "blockRevive")
	u.debuffs = kept
	_ev({"e": "death", "u": u.uid})
	if u.side == 0:
		_ally_died = true
	if killer != null and killer.alive:
		killer.kills += 1
		var es := _nn(killer, "essenceShield")
		if es > 0.0:
			_shield(killer, killer, killer.max_hp * es / 100.0, 2)
		_hooks(killer, "kill", {"victim": u})
	for f in side_units(u.side):
		_hooks(f, "ally_death", {"ally": u})
	for e in side_units(1 - u.side):
		_hooks(e, "enemy_death", {"victim": u})
	if _has_special(u, "backup"):
		for f in friends(u):
			if f.tpl == "mnemosyne":
				_heal(u, f, f.max_hp * 0.10, false)
	# Pit Royal reinforcements take the fallen slot (either side)
	if u.side == 1 and not enemy_reinforcements.is_empty():
		var er: Dictionary = enemy_reinforcements.pop_front()
		_add_unit(er)
		er.max_hp = float(er.base.hp)
		er.hp = er.max_hp
		_ev({"e": "spawn", "u": er.uid, "replaces": u.uid})
		_reinforce_fx(er)
	if u.side == 0 and not reinforcements.is_empty():
		var r: Dictionary = reinforcements.pop_front()
		_add_unit(r)
		r.max_hp = float(r.base.hp)
		r.hp = r.max_hp
		_ev({"e": "spawn", "u": r.uid, "replaces": u.uid})
		_reinforce_fx(r)
	_check_end()

func _revive(src: Dictionary, u: Dictionary, pct: float) -> void:
	if opts.get("no_revive", false) or has_debuff(u, "blockRevive"):
		return
	u.alive = true
	u.hp = u.max_hp * pct / 100.0
	u.tm = 0.0
	u.debuffs = []
	u.low_fired = false
	_ev({"e": "revive", "u": u.uid, "hp": u.hp})

# ================================================================ healing / shields / tm
func _heal(src: Dictionary, tgt: Dictionary, amount: float, from_ability: bool) -> void:
	if not tgt.alive or amount <= 0.0:
		return
	if has_debuff(tgt, "healBlock"):
		_ev({"e": "text", "u": tgt.uid, "t": "Heal blocked"})
		return
	if _overtime > 0:
		amount *= max(0.0, 0.5 - 0.25 * (_overtime - 1))
		if amount <= 0.0:
			return
	var m := 1.0 + _nn(tgt, "egocentric") / 100.0
	if src != null:
		m += _nn(src, "altruistic") / 100.0
		if from_ability:
			m += _nn(src, "surgeon") / 100.0
	var v: float = min(tgt.max_hp - tgt.hp, round(amount * m))
	if v <= 0.0:
		return
	tgt.hp += v
	if tgt.hp >= tgt.max_hp * 0.25:
		tgt.low_fired = false   # Rapid Rescue can fire again the next time they drop below 25%
	if src != null:
		src.healed += v
	_ev({"e": "heal", "u": tgt.uid, "v": int(v), "hp": tgt.hp})
	# opponents react to healing
	for o in side_units(1 - tgt.side):
		var ml := _nn(o, "medLearning")
		if ml > 0.0:
			var hv: float = min(o.max_hp - o.hp, round(v * ml / 100.0))
			if hv > 0.0 and not has_debuff(o, "healBlock"):
				o.hp += hv
				_ev({"e": "heal", "u": o.uid, "v": int(hv), "hp": o.hp})
		if _has_special(o, "tear_stitches") and int(o.special_cd.get("tear", 0)) <= 0 and not _in_assist:
			o.special_cd["tear"] = 1
			var targets := foes(o)
			if not targets.is_empty():
				_ev({"e": "text", "u": o.uid, "t": "Tear Stitches!"})
				_assist(o, get_ability(o, "open_wounds"), targets[rng.randi_range(0, targets.size() - 1)])

func _shield(src: Dictionary, tgt: Dictionary, amount: float, turns: int) -> void:
	if not tgt.alive or has_debuff(tgt, "blockBuffs"):
		return
	var m := 1.0 + _nn(tgt, "egocentric") / 100.0 + _nn(src, "altruistic") / 100.0
	var v: float = round(amount * m)
	for b in tgt.buffs:
		if b.id == "overshield":
			b.shield = max(float(b.shield), v)
			b.turns = max(int(b.turns), turns)
			_ev({"e": "buff", "u": tgt.uid, "id": "overshield"})
			return
	tgt.buffs.append({"id": "overshield", "v": 0, "shield": v, "turns": turns, "src": src.uid})
	_ev({"e": "buff", "u": tgt.uid, "id": "overshield"})

func total_shield(u: Dictionary) -> float:
	var s := 0.0
	for b in u.buffs:
		if b.id == "overshield":
			s += float(b.shield)
	return s

## Change turn meter by v percent. Negative changes on enemies use the hacking check.
func _tm(src: Dictionary, tgt: Dictionary, v: float, friendly: bool) -> void:
	if not tgt.alive:
		return
	if v < 0.0 and not friendly:
		if tgt.immune.has("tm"):
			_ev({"e": "text", "u": tgt.uid, "t": "Immune"})
			return
		if has_buff(tgt, "blockDebuffs"):   # Reduce Turn Meter is a debuff (GDD list)
			_ev({"e": "block", "u": tgt.uid})
			return
		if not _hack_check(src, tgt):
			_ev({"e": "resist", "u": tgt.uid})
			return
	var before: float = tgt.tm
	tgt.tm = clamp(tgt.tm + TM_FULL * v / 100.0, 0.0, TM_FULL * 1.5)
	_ev({"e": "tm", "u": tgt.uid, "v": v})
	if v < 0.0:
		var removed: float = before - tgt.tm
		for f in friends(tgt):
			if f != tgt and _has_special(f, "capitalist") and removed > 0.0:
				f.tm = min(TM_FULL * 1.5, f.tm + removed * 2.0)
				_ev({"e": "tm", "u": f.uid, "v": removed * 2.0 / TM_FULL * 100.0})

## GDD (literal, user decision): the debuff lands only if the attacker's Hacking >= the target's Firewall. No roll.
func _hack_check(src: Dictionary, tgt: Dictionary) -> bool:
	return eff(src, "hack") >= eff(tgt, "fw")

# ================================================================ buffs / debuffs
func _place_debuff(src: Dictionary, tgt: Dictionary, e: Dictionary, ctx: Dictionary, spreading := false) -> void:
	if not tgt.alive:
		return
	var id: String = e.id
	var def: Dictionary = Data.DEBUFFS[id]
	var chance := float(e.get("chance", 100)) + _nn(src, "breach")
	if rng.randf() * 100.0 >= chance:
		return
	if tgt.immune.has(id) or (id == "cdIncrease" and tgt.immune.has("cdIncrease")):
		_ev({"e": "text", "u": tgt.uid, "t": "Immune"})
		return
	# GDD order: chance > Hacking vs Firewall > Block Debuffs > already has > refresh/stack > place
	if not def.get("noCheck", false) and not _hack_check(src, tgt):
		_ev({"e": "resist", "u": tgt.uid})
		_debuff_blocked_heals(src, tgt)
		return
	if has_buff(tgt, "blockDebuffs"):
		_ev({"e": "block", "u": tgt.uid})
		_debuff_blocked_heals(src, tgt)
		return
	if not spreading and rng.randf() * 100.0 < _nn(tgt, "baitSwitch") and src.alive:
		_ev({"e": "text", "u": tgt.uid, "t": "Deflected"})
		tgt = src
		# the deflected debuff still respects the attacker's own immunities and Block Debuffs
		if tgt.immune.has(id):
			_ev({"e": "text", "u": tgt.uid, "t": "Immune"})
			return
		if has_buff(tgt, "blockDebuffs"):
			_ev({"e": "block", "u": tgt.uid})
			return
	var turns := int(e.get("turns", 1))
	if rng.randf() * 100.0 < _nn(src, "adware"):
		turns += 1
	var v: float = def.val[int(e.get("l", 0))]
	if id == "cdIncrease":
		# small: +1 turn; large (GDD "Full Cooldown"): every skill back to its full cooldown
		for k in tgt.cds:
			if int(e.get("l", 0)) == 1:
				var ab = get_ability(tgt, k)
				tgt.cds[k] = max(int(tgt.cds[k]), int(ab.get("cd", 0)) if ab != null else 0)
			elif int(tgt.cds[k]) > 0 or k != basic(tgt).id:
				tgt.cds[k] = int(tgt.cds[k]) + 1
		_ev({"e": "debuff", "u": tgt.uid, "id": id})
		return
	if def.get("stack", false):
		var stacks := debuff_count(tgt, id)
		if stacks >= 10:
			return
		var hit := float(ctx.get("hit", {}).get(tgt.uid, 0.0)) if ctx.has("hit") else 0.0
		if spreading and hit <= 0.0:
			hit = float(ctx.get("spread_hit", 0.0))  # DDoS copy: same basis as the original Bleed
		tgt.debuffs.append({"id": id, "v": v, "turns": turns, "src": src.uid, "hit": hit})
	else:
		var found := false
		for d in tgt.debuffs:
			if d.id == id:
				d.turns = max(int(d.turns), turns)
				d.v = max(float(d.v), v)
				d.src = src.uid
				found = true
		if not found:
			tgt.debuffs.append({"id": id, "v": v, "turns": turns, "src": src.uid})
	_ev({"e": "debuff", "u": tgt.uid, "id": id})
	if src.side == 0:
		debuffs_placed_by_player += 1
		if tgt.boss:
			debuffs_on_boss += 1
	if id == "enraged" and _has_special(src, "divine_retribution"):
		_place_buff(src, src, {"id": "reflect", "turns": 2, "l": 1}, true)
	if not spreading and rng.randf() * 100.0 < _nn(src, "ddos"):
		_ev({"e": "text", "u": src.uid, "t": "DDoS"})
		ctx["spread_hit"] = float(ctx.get("hit", {}).get(tgt.uid, 0.0)) if ctx.has("hit") else 0.0
		for o in foes(src):
			if o != tgt:
				_place_debuff(src, o, e, ctx, true)

## Adaptive Networks (target) and Syphon Intel (attacker) fire whenever this debuff is stopped,
## by a Hacking vs Firewall resist or by Block Debuffs.
func _debuff_blocked_heals(src: Dictionary, tgt: Dictionary) -> void:
	var ad := _nn(tgt, "adaptive")
	if ad > 0.0: _heal(tgt, tgt, tgt.max_hp * ad / 100.0, false)
	var si := _nn(src, "syphonIntel")
	if si > 0.0: _heal(src, src, src.max_hp * si / 100.0, false)

func _place_buff(src: Dictionary, tgt: Dictionary, e: Dictionary, quiet := false, spreading := false) -> void:
	if not tgt.alive:
		return
	# GDD order: chance > Block Buffs > already has > refresh > place
	if not spreading and e.has("chance") and rng.randf() * 100.0 >= float(e.chance):
		return
	if has_debuff(tgt, "blockBuffs"):
		_ev({"e": "text", "u": tgt.uid, "t": "Buff blocked"})
		return
	var id: String = e.id
	var def: Dictionary = Data.BUFFS[id]
	var turns := int(e.get("turns", 1))
	if rng.randf() * 100.0 < _nn(src, "personalAds"):
		turns += 1
	var v: float = def.val[int(e.get("l", 0))]
	if def.get("stack", false):
		tgt.buffs.append({"id": id, "v": v, "turns": turns, "src": src.uid})
	else:
		var found := false
		for b in tgt.buffs:
			if b.id == id:
				b.turns = max(int(b.turns), turns)
				b.v = max(float(b.v), v)
				found = true
		if not found:
			tgt.buffs.append({"id": id, "v": v, "turns": turns, "src": src.uid})
	_ev({"e": "buff", "u": tgt.uid, "id": id})
	if not spreading and not quiet and rng.randf() * 100.0 < _nn(src, "pullMeta"):
		for f in friends(src):
			if f != tgt:
				_place_buff(src, f, e, true, true)

# ================================================================ effects
func _fx_targets(u: Dictionary, f: Dictionary, targets: Array, ctx: Dictionary) -> Array:
	var to: String = f.get("to", "target" if f.t in ["debuff", "strip", "tm"] else "self")
	match to:
		"self": return [u]
		"all_allies": return friends(u)
		"all_enemies": return foes(u)
		"lowest_ally":
			var fr := friends(u)
			fr.sort_custom(func(a, b): return a.hp / a.max_hp < b.hp / b.max_hp)
			return [] if fr.is_empty() else [fr[0]]
		"random_enemy":
			var fo := foes(u)
			return [] if fo.is_empty() else [fo[rng.randi_range(0, fo.size() - 1)]]
		_: return targets

func _cond_ok(f: Dictionary, t: Dictionary, ctx: Dictionary) -> bool:
	var c: String = f.get("if", "")
	if c == "":
		return true
	if c == "crit": return ctx.get("crit", false)
	if c == "kill": return ctx.get("kill", false)
	if c.begins_with("has:"): return has_debuff(t, c.substr(4))
	if c.begins_with("debuffs>="): return t.debuffs.size() >= int(c.substr(9))
	return true

func _apply_fx(u: Dictionary, a: Dictionary, fx: Array, targets: Array, ctx: Dictionary) -> void:
	var lvm := ab_level_mult(u, a)
	for f in fx:
		if not u.alive and f.t != "heal":
			continue
		var tl := _fx_targets(u, f, targets, ctx)
		match f.t:
			"debuff":
				for t in tl:
					if _cond_ok(f, t, ctx) and t.side != u.side:
						var e2: Dictionary = f.duplicate()
						e2.chance = min(100.0, float(f.get("chance", 100)) * lvm)
						_place_debuff(u, t, e2, ctx)
			"buff":
				for t in tl:
					if _cond_ok(f, t, ctx):
						_place_buff(u, t, f)
			"tm":
				for t in tl:
					if _cond_ok(f, t, ctx):
						_tm(u, t, float(f.v) * (lvm if float(f.v) > 0 else 1.0), t.side == u.side)
			"heal":
				var cond_target = ctx.get("primary")
				for t in tl:
					var check_t = cond_target if cond_target != null else t
					if not _cond_ok(f, check_t, ctx):
						continue
					var basis: float = u.max_hp if f.get("of", "caster") == "caster" else t.max_hp
					_heal(u, t, basis * float(f.pct) / 100.0 * lvm, true)
			"shield":
				for t in tl:
					var basis2: float = u.max_hp if f.get("of", "caster") == "caster" else t.max_hp
					_shield(u, t, basis2 * float(f.pct) / 100.0 * lvm, int(f.get("turns", 2)))
			"cleanse":
				for t in tl:
					for i in int(f.get("n", 1)):
						if t.debuffs.is_empty():
							break
						var d = t.debuffs.pop_back()
						_ev({"e": "expire", "u": t.uid, "id": d.id})
			"strip":
				for t in tl:
					if t.side == u.side:
						continue
					for i in int(f.get("n", 1)):
						if t.buffs.is_empty():
							break
						var b = t.buffs.pop_back()
						_ev({"e": "expire", "u": t.uid, "id": b.id})
			"call":
				var tgt = ctx.get("primary")
				if tgt == null or not tgt.alive:
					var fo := foes(u)
					tgt = null if fo.is_empty() else fo[0]
				if tgt == null:
					continue
				var callers := friends(u).filter(func(x): return x != u and (not f.get("syn", false) or x.syn == u.syn))
				var n := int(f.get("n", 2))
				for c in callers.slice(0, n):
					if tgt.alive:
						_assist(c, basic(c), tgt)
			"extra_turn":
				if _cond_ok(f, u, ctx):
					ctx.extra_turn = true
					_ev({"e": "text", "u": u.uid, "t": "Extra turn!"})
			"revive":
				var dead := side_units(u.side, false).filter(func(x): return not x.alive)
				if dead.is_empty() or opts.get("no_revive", false):
					for t in friends(u):
						_heal(u, t, t.max_hp * 0.20, true)
				else:
					_revive(u, dead[0], float(f.pct))
			"cd_reduce":
				# GDD Cooldown buff: small = -1 turn, large ("reset": true) = all skills ready
				for t in tl:
					for k in t.cds:
						t.cds[k] = 0 if f.get("reset", false) else max(0, int(t.cds[k]) - 1)

func _special_after(u: Dictionary, a: Dictionary, target, ctx: Dictionary) -> void:
	match a.get("special", ""):
		"not_so_fast":
			if target != null and target.alive:
				var v := 10.0
				var e1 := has_debuff(target, "enraged")
				var b1 := has_debuff(target, "break")
				if e1 and b1: v = 40.0
				elif e1 or b1: v = 20.0
				_tm(u, target, -v, false)
		"open_wounds":
			if target != null and target.alive:
				var bleeds: Array = target.debuffs.filter(func(d): return d.id == "bleed")
				for d in bleeds:
					if debuff_count(target, "bleed") < 10:
						target.debuffs.append(d.duplicate())
				if not bleeds.is_empty():
					_ev({"e": "debuff", "u": target.uid, "id": "bleed"})
		"devour":
			if target != null:
				target.debuffs = target.debuffs.filter(func(d): return d.id != "bleed")
				_ev({"e": "expire", "u": target.uid, "id": "bleed"})
			_heal(u, u, u.max_hp * 0.25, true)

# ================================================================ passive hooks
func _hooks(u: Dictionary, on: String, info: Dictionary) -> void:
	if not u.alive:
		return
	for a in u.abilities:
		if a.type != "passive":
			continue
		for h in a.get("hooks", []):
			if h.on != on:
				continue
			if h.has("chance") and rng.randf() * 100.0 >= float(h.chance):
				continue
			var ctx := {"primary": info.get("ally", info.get("src", null))}
			var targets: Array = []
			if info.has("src") and info.src != null:
				targets = [info.src]
			_apply_fx(u, a, h.fx, targets, ctx)

# ================================================================ AI
func ai_choose(u: Dictionary) -> Dictionary:
	var acts := actives(u).filter(func(a): return ability_ready(u, a))
	acts.reverse()   # prefer the strongest (later) abilities
	var chosen = null
	for a in acts:
		if _ai_useful(u, a):
			chosen = a
			break
	if chosen == null:
		chosen = basic(u)
	var tg = _ai_target(u, chosen)
	return {"ab": chosen.id, "target": tg.uid if tg != null else ""}

func _ai_useful(u: Dictionary, a: Dictionary) -> bool:
	var fx: Array = a.get("fx", [])
	var heals := fx.any(func(f): return f.t == "heal")
	var revives := fx.any(func(f): return f.t == "revive")
	if float(a.get("mult", 0)) <= 0.0:
		if revives:
			return side_units(u.side, false).any(func(x): return not x.alive) or friends(u).any(func(x): return x.hp < x.max_hp * 0.6)
		if heals:
			return friends(u).any(func(x): return x.hp < x.max_hp * 0.7)
		# buff-only abilities: use if the main buff is not already up on most allies
		for f in fx:
			if f.t == "buff":
				var tl := _fx_targets(u, f, friends(u), {})
				return tl.any(func(x): return not has_buff(x, f.id))
		return true
	return true

func _ai_target(u: Dictionary, a):
	if a == null:
		return null
	match a.get("tgt", "enemy"):
		"ally":
			var fr := friends(u)
			fr.sort_custom(func(x, y): return x.hp / x.max_hp < y.hp / y.max_hp)
			return fr[0] if not fr.is_empty() else u
		"self", "all_allies":
			return u
		_:
			var fo := foes(u)
			if fo.is_empty():
				return null
			if rng.randf() < 0.15:
				return fo[rng.randi_range(0, fo.size() - 1)]
			var best = fo[0]
			var best_s := -INF
			for t in fo:
				var s := _ai_score(u, a, t)
				if s > best_s:
					best_s = s
					best = t
			return best

## Target priority: finish kills, then healers, then the most damaged (by %), avoiding wasted debuffs.
func _ai_score(u: Dictionary, a: Dictionary, t: Dictionary) -> float:
	var s: float = 1.0 - float(t.hp) / max(1.0, float(t.max_hp))
	var mult := float(a.get("mult", 0.0)) * float(a.get("hits", 1))
	if mult > 0.0:
		var arm: float = eff(t, "arm")
		var est: float = _scaling(u) * mult * DAMAGE_SCALE * (1.0 - min(MAX_MITIGATION, arm / (arm + ARMOUR_K)))
		if est >= t.hp:
			s += 1.5
		s += 0.3 * (1.0 - min(MAX_MITIGATION, arm / (arm + ARMOUR_K)))
	for ab in t.abilities:
		if ab.get("type", "") == "active" and ab.get("fx", []).any(func(f): return f.t in ["heal", "revive"]):
			s += 0.6
			break
	for f in a.get("fx", []):
		if f.t == "debuff":
			if t.immune.has(f.id) or has_debuff(t, f.id):
				s -= 0.5
	return s

# ================================================================ helpers for the UI / content
func ally_died() -> bool:
	return _ally_died

func damage_to_side(side: int) -> float:
	var s := 0.0
	for u in units:
		if u.side == side:
			s += u.dmg_taken
	return s

## Run the whole fight with AI on both sides (tests, auto-resolve).
func simulate() -> String:
	start()
	var guard := 0
	while result == "" and guard < 2000:
		guard += 1
		var t = next_turn()
		if t == null:
			break
		var actor: Dictionary = t.actor
		if t.has("forced_ab"):
			act(actor, t.forced_ab, t.forced_target)
		else:
			var c := ai_choose(actor)
			act(actor, c.ab, c.target)
	return result

## Predict the next n actors from current turn meters (no state change).
func predict(n: int, current_uid := "") -> Array:
	var sim: Array = []
	for u in units:
		if u.alive:
			sim.append({"uid": u.uid, "tm": 0.0 if u.uid == current_uid else u.tm, "spd": eff(u, "spd")})
	var out: Array = []
	if sim.is_empty():
		return out
	for k in n:
		var dt := INF
		for s in sim:
			dt = min(dt, max(0.0, TM_FULL - s.tm) / s.spd)
		for s in sim:
			s.tm += s.spd * dt
		sim.sort_custom(func(a, b): return a.tm > b.tm)
		out.append(sim[0].uid)
		sim[0].tm = 0.0
	return out
