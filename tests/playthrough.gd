extends Node
## GDD verification + long playthrough bot.
## godot --headless --path . res://tests/Playthrough.tscn -- --nwtest
## Part 1 checks the Equipment rules from the GDD with exact numbers.
## Part 2 plays simulated days like a player and reports progression and problems.

var problems: Array = []
var seeded := false
var prof := {}   # section -> usec (printed at the end)
func _p(k: String, t0: int) -> void:
	prof[k] = int(prof.get(k, 0)) + Time.get_ticks_usec() - t0
var log_lines: Array = []

func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Bot")
	gdd_equipment_checks()
	gdd_progression_checks()
	Game.reset_save()
	# NW_SEED=<n>: repeatable run (account RNG, battle rolls and the clock are all fixed).
	# The account itself is a normal new player's: same starter crew and kit, free-to-play.
	var sd := OS.get_environment("NW_SEED")
	if sd != "":
		seeded = true
		U.rng.seed = int(sd)
		seed(int(sd))
		U.clock_base = 1767600000.0   # Mon 2026-01-05 08:00 UTC
		print("== seed %s" % sd)
	Game.new_game("Bot")
	print("== fresh account, simulated play")
	await play_days(int(OS.get_environment("NW_DAYS")) if OS.get_environment("NW_DAYS") != "" else 21)
	print("\n===== PROBLEMS (%d) =====" % problems.size())
	for p in problems:
		print("  - " + p)
	for k in prof:
		print("   time %s: %.1f s" % [k, prof[k] / 1e6])
	print("PLAYTHROUGH DONE")
	get_tree().quit()

func bad(msg: String) -> void:
	problems.append(msg)
	print("PROBLEM: " + msg)

func expect(cond: bool, msg: String) -> void:
	if not cond:
		bad(msg)

# ============================================================ Part 1: GDD equipment rules
func gdd_equipment_checks() -> void:
	print("== GDD Equipment checks")
	var w: Dictionary = Game.S.roster[0]
	w.rep = 6
	w.rank = 6
	var base := Game.compute_stats(w)
	# GDD: substats already rolled by rarity (Common 0 .. Legendary 4)
	for r in Data.RARITIES:
		var it := Game.make_equipment("chest", 3, r, "Health")
		expect(it.subs.size() == Data.SUBS_BY_RARITY[r], "rarity %s should start with %d substats, got %d" % [r, Data.SUBS_BY_RARITY[r], it.subs.size()])
		for s in it.subs:
			expect(s.stat != it.pri.stat, "substat duplicates primary on %s" % r)
			expect(Data.SLOT_STATS["chest"].sub.has(s.stat), "illegal substat %s on chest" % s.stat)
	# GDD primary stat matrix: every slot only rolls allowed primaries; implants never roll crit chance
	for slot in Data.ALL_SLOTS:
		for i in 30:
			var it2 := Game.make_equipment(slot, 6, "legendary")
			expect(Data.SLOT_STATS[slot].pri.has(it2.pri.stat), "%s rolled illegal primary %s" % [slot, it2.pri.stat])
			if slot in Data.IMPLANT_SLOTS:
				expect(it2.set == "", "implant has a set")
				for s in it2.subs:
					expect(s.stat != "cc", "implant rolled crit chance substat")
	# GDD: substat values match the Equipment Substats Table for the item's rank
	for rank in range(1, 7):
		var it3 := Game.make_equipment("weapon", rank, "legendary", "Firepower")
		for s in it3.subs:
			expect(float(s.val) == float(Data.SUBSTAT[s.stat][rank]), "rank %d %s substat %s != table %s" % [rank, s.stat, s.val, Data.SUBSTAT[s.stat][rank]])
	# GDD: level 0-20 with Credits, extra substat roll every 5 levels
	var lvl := Game.make_equipment("boots", 5, "uncommon", "Speed")
	Game.add_equipment(lvl)
	Game.S.cur.credits = 99999999
	var subs_at := {}
	for i in 20:
		expect(Game.equip_level_up(lvl) == "", "level up failed at %d" % lvl.level)
		subs_at[lvl.level] = lvl.subs.size()
	expect(lvl.level == 20, "equipment should reach +20")
	expect(subs_at[4] == 1 and subs_at[5] == 2 and subs_at[10] == 3 and subs_at[15] == 4, "substat unlocks at 5/10/15 wrong: %s" % str(subs_at))
	var rolls := 0
	for s in lvl.subs:
		rolls += int(s.rolls)
	expect(rolls == 1, "at +20 with 4 subs one existing substat should have been upgraded (rolls=%d)" % rolls)
	expect(Game.equip_level_up(lvl) != "", "should not level past 20")
	# equip every slot and check stats add up exactly
	var expected := {"hp": 0.0, "arm": 0.0, "fp": 0.0, "spd": 0.0, "cc": 0.0, "cd": 0.0, "hack": 0.0, "fw": 0.0}
	var pct := {"hp": 0.0, "arm": 0.0, "fp": 0.0, "spd": 0.0}
	var set_counts := {}
	Game.unequip_all(w)
	for slot in Data.ALL_SLOTS:
		var it4 := Game.add_equipment(Game.make_equipment(slot, 6, "legendary", "Firepower" if slot in ["weapon", "helmet"] else ("Speed" if slot in ["chest", "gloves"] else "")))
		for i in 8:
			Game.equip_level_up(it4)
		expect(Game.equip_on(w, it4) == "", "could not equip %s" % slot)
		var add := func(stat: String, v: float):
			match stat:
				"hpP": pct.hp += v
				"armP": pct.arm += v
				"fpP": pct.fp += v
				_: expected[stat] += v
		add.call(it4.pri.stat, Data.primary_value(it4.pri.stat, it4.rank, it4.level))
		for s in it4.subs:
			add.call(s.stat, float(s.val))
		if it4.set != "":
			set_counts[it4.set] = int(set_counts.get(it4.set, 0)) + 1
	expect(w.gear.size() == 9, "all 9 slots (6 gear + 3 implants at rep 6) should be filled, got %d" % w.gear.size())
	var bare: Dictionary = w.duplicate(true)
	bare.gear = {}
	var b2 := Game.compute_stats(bare)
	var full := Game.compute_stats(w)
	# set bonuses (2-piece stat sets)
	for sn in set_counts:
		var sd: Dictionary = Data.SETS[sn]
		if sd.has("stat"):
			var times := int(set_counts[sn] / sd.pieces)
			for st in sd.stat:
				match st:
					"fpP": pct.fp += sd.stat[st] * times
					"spdP": pct.spd += sd.stat[st] * times
					"hpP": pct.hp += sd.stat[st] * times
					"armP": pct.arm += sd.stat[st] * times
					_: expected[st] += sd.stat[st] * times
	# compute what the GDD formula says: base * (1+%) + flat, relative to the bare warlord
	var bare_base := _uncapped_base(bare)
	for k in ["hp", "arm", "fp", "spd"]:
		var want: float = round(bare_base[k] * (1.0 + (pct[k] + bare_base["p_" + k]) / 100.0) + expected[k] + bare_base["f_" + k])
		expect(abs(float(full[k]) - want) <= 1.0, "%s: got %s, expected %s (equipped stats do not add up)" % [k, full[k], want])
	for k in ["cc", "cd", "hack", "fw"]:
		var want2: float = float(b2[k]) + expected[k]
		if k == "cc":
			want2 = min(100.0, want2)
		expect(abs(float(full[k]) - want2) <= 1.0, "%s: got %s, expected %s" % [k, full[k], want2])
	print("   equipped 9 slots: HP %s->%s  ARM %s->%s  FP %s->%s  SPD %s->%s  CD %s->%s" % [b2.hp, full.hp, b2.arm, full.arm, b2.fp, full.fp, b2.spd, full.spd, b2.cd, full.cd])
	# GDD: Neons apply to equipment of the same or higher rank, matching substat, never crit chance
	var low := Game.add_equipment(Game.make_equipment("helmet", 2, "legendary", "Armour"))
	var n_hi := Game.add_neon(5, low.subs[0].stat if low.subs[0].stat != "cc" else low.subs[1].stat)
	expect(Game.neon_can(low, n_hi) != "", "rank 5 neon must not fit rank 2 gear")
	var hi := Game.add_equipment(Game.make_equipment("helmet", 6, "legendary", "Armour"))
	var target_sub: Dictionary = hi.subs[0] if hi.subs[0].stat != "cc" else hi.subs[1]
	var n_ok := Game.add_neon(5, target_sub.stat)
	var before := float(target_sub.val) + float(target_sub.get("neon", 0))
	expect(Game.apply_neon(hi, n_ok) == "", "neon should graft")
	expect(float(target_sub.val) + float(target_sub.neon) == before + Data.SUBSTAT[target_sub.stat][5], "neon did not add its rank value")
	expect(not Data.NEON_STATS.has("cc"), "neons must not cover crit chance (GDD)")
	# implants locked by reputation (GDD: limbs 2, organs 4, skeleton 6)
	var w2: Dictionary = Game.S.roster[1]
	w2.rep = 1
	var limb := Game.add_equipment(Game.make_equipment("limbs", 3, "rare"))
	expect(Game.equip_on(w2, limb) != "", "limbs should be locked below reputation 2")
	w2.rep = 2
	expect(Game.equip_on(w2, limb) == "", "limbs should unlock at reputation 2")
	# auto equip picks something sensible and never steals from another warlord
	var w3: Dictionary = Game.S.roster[2]
	var owned_by_w: Array = w.gear.values()
	Game.auto_equip(w3)
	for slot in w3.gear:
		expect(not owned_by_w.has(w3.gear[slot]), "auto-equip stole gear from another warlord")
	# selling returns credits and unequips
	var c0 := Game.cur("credits")
	var sell_it: Dictionary = Game.eq(w.gear["boots"])
	Game.sell_equipment(sell_it)
	expect(Game.cur("credits") > c0 and not w.gear.has("boots"), "selling equipped item failed")
	Game.unequip_all(w)
	Game.unequip_all(w2)
	Game.unequip_all(w3)
	print("   equipment checks done")

## Base numbers before gear (level/rank/rep scaled + passives + neuronet), split into pct/flat parts.
func _uncapped_base(w: Dictionary) -> Dictionary:
	var t: Dictionary = Warlords.get_t(w.tpl)
	var b: Dictionary = t.base
	var sc: Array = Data.SCALING[t.cls][t.rarity]
	var lf := func(p: float) -> float: return 1.0 + p / 100.0 * (float(w.level) - 1.0) / 59.0
	var rf := func(p: float) -> float: return 1.0 + p / 100.0 * (float(w.rank) - 1.0) / 5.0
	var rep := 1.0 + float(w.rep) * float(sc[6]) / 100.0
	var out := {"hp": b.hp * lf.call(sc[0]) * rf.call(sc[3]) * rep, "arm": b.arm * lf.call(sc[1]) * rf.call(sc[4]) * rep, "fp": b.fp * lf.call(sc[2]) * rf.call(sc[5]) * rep, "spd": float(b.spd),
		"p_hp": 0.0, "p_arm": 0.0, "p_fp": 0.0, "p_spd": 0.0, "f_hp": 0.0, "f_arm": 0.0, "f_fp": 0.0, "f_spd": 0.0}
	for a in t.abilities:
		if a.type == "passive" and a.has("stats"):
			for st in a.stats:
				var v: float = a.stats[st]
				match st:
					"hpP": out.p_hp += v
					"armP": out.p_arm += v
					"fpP": out.p_fp += v
					"spdP": out.p_spd += v
					"hp", "arm", "fp", "spd": out["f_" + st] += v
	return out

func gdd_progression_checks() -> void:
	print("== GDD progression checks")
	# XP table: rank 1 level 1->2 needs 500, +10% per level and per rank (GDD Warlord Level)
	expect(Data.xp_to_next(1, 1) == 500 and Data.xp_to_next(2, 1) == 550 and Data.xp_to_next(1, 2) == 550 and Data.xp_to_next(9, 1) == 1072, "XP table does not match GDD")
	# contract odds (GDD Contracts): uncommon 90/9/1
	var counts := {}
	Game.S.items.contract.uncommon = 2000
	var n0: int = Game.S.roster.size()
	for i in 2000:
		var nw = Game.open_contract("uncommon")
		var r: String = Game.tpl(nw).rarity
		counts[r] = int(counts.get(r, 0)) + 1
	print("   2000 uncommon contracts: %s" % str(counts))
	expect(abs(int(counts.get("common", 0)) - 1800) < 120, "uncommon contract common rate off GDD 90%")
	# break them all back down -> scrap -> contracts (10 scrap = 1 contract)
	var c_before := Game.item_count(["contract", "uncommon"])
	for w in Game.S.roster.duplicate().slice(n0):
		Game.break_down(w)
	expect(Game.item_count(["contract", "uncommon"]) > c_before, "scrap did not assemble contracts")
	# rank up rule (GDD): consume N rank-N warlords, must be max level
	var w: Dictionary = Game.add_warlord("brother_grin", true)
	expect(Game.rank_up(w, []) != "", "rank up without max level should fail")
	w.level = 10
	var fod: Array = []
	for i in 1:
		fod.append(Game.add_warlord("brother_grin", true).uid)
	expect(Game.rank_up(w, fod) == "" and w.rank == 2, "rank 1->2 with one rank-1 warlord should work")
	w.level = 20
	expect(Game.rank_up(w, [Game.add_warlord("scrapjaw", true).uid, Game.add_warlord("scrapjaw", true).uid]) != "", "rank 2 fodder must be rank 2")
	# reputation capped at rank (GDD)
	for a in ["paragon", "neutral", "renegade", "generic"]:
		for tr in ["minor", "major", "grand"]:
			Game.S.items.deeds[a][tr] = 99
	Game.rep_up(w)
	Game.rep_up(w)
	expect(w.rep == 2 and Game.rep_up(w) != "", "reputation should cap at rank (2)")
	# neuronet: 4 points per layer, one of two per career, layer gating
	Game.S.items.mf["1"] = 10000
	Game.S.items.mf["2"] = 10000
	expect(Game.nn_add(w, "munitions") != "", "layer 2 must require 2 points in layer 1")
	Game.nn_add(w, "precision")
	Game.nn_add(w, "precision")
	expect(Game.nn_add(w, "blitz") != "", "only 1 of 2 skills per career per layer")
	Game.nn_add(w, "plating")
	Game.nn_add(w, "plating")
	expect(Game.nn_add(w, "malware") != "", "layer cap of 4 points")
	expect(Game.nn_add(w, "munitions") == "", "layer 2 should unlock after 2 points in layer 1")
	print("   progression checks done")

# ============================================================ Part 2: simulated play
var day_stats: Array = []

## Picked like a player: strongest first, but no duplicate warlords and at least one damage dealer.
func squad() -> Array:
	var best: Array = Game.S.roster.duplicate()
	best.sort_custom(func(a, b): return Game.power(a) > Game.power(b))
	var picked: Array = []
	var tpls := {}
	for w in best:
		if picked.size() >= Data.TEAM_SIZE:
			break
		if tpls.has(w.tpl):
			continue
		tpls[w.tpl] = true
		picked.append(w)
	var dps := func(w): return Game.tpl(w).cls in ["firepower", "hacker"]
	if not picked.any(dps):
		for w in best:
			if dps.call(w) and not tpls.has(w.tpl):
				picked[picked.size() - 1] = w
				break
	return picked.map(func(x): return x.uid)

## Credit ledger: where credits come from / go, by activity (printed every 10 days).
var ledger := {}

func _book(cat: String, delta: int) -> void:
	ledger[cat] = int(ledger.get(cat, 0)) + delta

var day_battles := {}
var day_energy := 0
## Playtime model for "hours to finish the campaign" (RAID ~60h): every battle costs a fixed
## overhead (team select, loading, results) plus each action at the fastest battle speed.
const SECS_PER_BATTLE := 10.0
const SECS_PER_ACTION := 0.75
var play_secs := {}          # mode -> seconds of estimated playtime
var last_turns := 0
var diff_done_at := {}       # difficulty index -> [day, campaign hours]

func fight(enc: Dictionary) -> String:
	var c0 := Game.cur("credits")
	var e0 := Game.cur("energy")
	var r := _fight(enc)
	if r != "nopay":
		play_secs[String(enc.get("mode", "?"))] = float(play_secs.get(String(enc.get("mode", "?")), 0.0)) + SECS_PER_BATTLE + last_turns * 2 * SECS_PER_ACTION
	var cat: String = String(enc.get("mode", "?"))
	if cat == "hideout":
		cat = "heist" if enc.get("id", "") == "heist" else "hideout"
	_book(cat, Game.cur("credits") - c0)
	if r != "nopay":
		day_battles[cat] = int(day_battles.get(cat, 0)) + 1
		day_energy += int(Content.enc_cost(enc).get("energy", 0))
	return r

func _fight(enc: Dictionary) -> String:
	var team := squad()
	if Game.pay(Content.enc_cost(enc)) != "":
		return "nopay"
	var b := Battle.new()
	var waves: Array = []
	for wv in enc.waves:
		var arr: Array = []
		for u in wv:
			arr.append(u.duplicate(true))
		waves.append(arr)
	b.setup(Content.player_units(team), waves, {"turn_limit": enc.get("turn_limit", 0), "reinforcements": Content.player_units(team.slice(0, 0)), "enemy_reinforcements": enc.get("enemy_reinf", []).map(func(u): return u.duplicate(true)), "no_revive": enc.get("royal", false)}.merged({"seed": U.rng.randi()} if seeded else {}))
	var t0 := Time.get_ticks_usec()
	b.simulate()
	_p("simulate", t0)
	last_turns = b.player_turns
	if b.result == "":
		bad("battle ended without a result: %s" % enc.title)
	var t1 := Time.get_ticks_usec()
	Content.finish(enc, b, team)
	_p("finish", t1)
	return b.result

func manage(full := false, daily := false) -> void:
	var c0 := Game.cur("credits")
	var t0 := Time.get_ticks_usec()
	_manage(full, daily)
	_p("manage", t0)
	_book("claims+upgrades+plaza+sell (net)", Game.cur("credits") - c0)

## Played like a person: claims, contracts and the Plaza at the start of a session (full); between
## battles only the squad gets attention; rank-up fodder is built only once a squad member is capped
## at its rank; the bag is cleared once a day (daily).
func _manage(full: bool, daily: bool) -> void:
	var t := Time.get_ticks_usec()
	if full:
		_claim_all()
	_p(" claims", t); t = Time.get_ticks_usec()
	_squad_care(full)
	_p(" squad", t); t = Time.get_ticks_usec()
	if full:
		_plaza()
	if daily:
		_sell()
	_p(" plaza+sell", t)

func _claim_all() -> void:
	for r in ["uncommon", "rare", "epic", "legendary"]:
		while Game.item_count(["contract", r]) > 0:
			Game.open_contract(r)
	for m in Game.S.inbox:
		Game.claim_mail(m)
	Game.claim_login()
	Game.collect_stocks()
	for p in ["daily", "weekly", "monthly"]:
		for j in Game.jobs_list(p):
			Game.claim_job(p, j.i)
	for cat in Data.GDD.ambitions:
		for a in Game.ambitions_list(cat):
			Game.claim_ambition(cat, a)
	for d in 3:
		for row in Data.GDD.campaignProgress:
			Game.claim_campaign_progress(d, int(row[0]))
	for row in Data.GDD.swProgress:
		Game.claim_sw_progress(int(row[0]))
	for weekly in [false, true]:
		for c in Game.bp_challenges(weekly):
			Game.bp_claim_challenge(weekly, c.id)
	for lv in range(1, Game.bp_level() + 1):
		Game.bp_claim(lv, false)
	for c in Game.S.items.cache.keys():
		while Game.item_count(["cache", c]) > 0:
			Game.open_cache(c)

func _squad_care(regear: bool) -> void:
	var team := squad()
	var capped := false
	for u in team:
		var w = Game.wl(u)
		if regear:   # Auto Equip when a session starts, not after every fight
			Game.auto_equip(w)
		# upgrade equipped gear with up to 40% of credits
		for slot in w.gear:
			var it = Game.eq(w.gear[slot])
			while it and it.level < Data.MAX_EQUIP_LEVEL and Game.cur("credits") > Data.equip_level_cost(it.rank, it.level) * 2.5:
				if Game.equip_level_up(it) != "":
					break
		# neons
		for n in Game.S.neons.duplicate():
			for slot in w.gear:
				var it2 = Game.eq(w.gear[slot])
				if it2 and Game.neon_can(it2, n) == "":
					Game.apply_neon(it2, n)
					break
		# metabolics
		for al in ["paragon", "neutral", "renegade", "generic"]:
			for tr in ["grand", "major", "minor"]:
				while Game.item_count(["metabolic", al, tr]) > 0 and w.level < Game.max_level(w):
					Game.use_metabolic(w, al, tr)
		# reputation
		while Game.can_rep_up(w) == "":
			Game.rep_up(w)
		# rank up with spare warlords / firmware
		if Game.can_rank_up(w):
			var spare: Array = Game.S.roster.filter(func(x): return x.rank == w.rank and not team.has(x.uid) and not x.locked and not Game.in_any_squad(x.uid)).map(func(x): return x.uid)
			var fw: int = mini(Game.item_count(["firmware", w.rank]) if w.rank <= 5 else 0, w.rank)
			var need: int = w.rank - fw
			if spare.size() >= need:
				Game.rank_up(w, spare.slice(0, need), fw)
		# neuronet: buy whatever is affordable in order
		for li in 7:
			for car in Data.NN_CAREERS:
				var sk: Dictionary = Data.NEURONET[car][li][0]
				while Game.nn_can(w, sk.id) == "":
					Game.nn_add(w, sk.id)
		if w.rank < 6 and w.level >= Game.max_level(w) and not Game.can_rank_up(w):
			capped = true
	# feed leftover commons for XP to the weakest squad member
	var weakest = Game.wl(team[team.size() - 1])
	var food: Array = Game.S.roster.filter(func(x): return Game.tpl(x).rarity == "common" and not team.has(x.uid) and x.level == 1).map(func(x): return x.uid).slice(0, 6)
	if not food.is_empty() and weakest.level < Game.max_level(weakest):
		Game.feed_xp(weakest, food)
	# rank-up fodder is farmed continuously, like RAID players farm "food" (gating it on a capped
	# squad member starved rank-ups: bots were still R5 at day 45)
	# build rank-up fodder: level spare warlords with metabolics-free feeding and rank them up (RAID-style "food")
	var spares: Array = Game.S.roster.filter(func(x): return not team.has(x.uid) and not x.locked)
	spares.sort_custom(func(a, b): return a.rank * 100 + a.level > b.rank * 100 + b.level)
	for f in spares.slice(0, 6):
		if f.rank >= 5 or Game.wl(f.uid) == null:
			continue
		var commons: Array = Game.S.roster.filter(func(x): return x.uid != f.uid and not team.has(x.uid) and x.rank == 1 and x.level == 1 and Game.tpl(x).rarity == "common").map(func(x): return x.uid)
		if f.level < Game.max_level(f) and commons.size() >= 2:
			Game.feed_xp(f, commons.slice(0, mini(6, commons.size())))
		for al in ["generic", "neutral", "paragon", "renegade"]:
			for tr in ["minor", "major"]:
				while Game.item_count(["metabolic", al, tr]) > 0 and f.level < Game.max_level(f):
					Game.use_metabolic(f, al, tr)
		if Game.can_rank_up(f):
			var same: Array = Game.S.roster.filter(func(x): return x.uid != f.uid and x.rank == f.rank and not team.has(x.uid) and not spares.slice(0, 6).has(x)).map(func(x): return x.uid)
			if same.size() >= f.rank:
				Game.rank_up(f, same.slice(0, f.rank))
	_set_squads(team)

func _set_squads(team: Array) -> void:
	Game.S.squads.last = team
	Game.S.squads.pit_brawl = team
	Game.S.squads.pit_royal = team + Game.S.roster.filter(func(x): return not team.has(x.uid)).map(func(x): return x.uid).slice(0, 3)

func _plaza() -> void:
	# Plaza: spend credits above a reserve on progression items
	var items := Game.plaza_items()
	var pc0 := Game.cur("credits")
	for i in items.size():
		var it: Dictionary = items[i]
		var k: String = it.r.k
		if Game.cur("credits") - int(it.cost) < 2000000:
			continue
		if k in ["firmware", "metabolic", "mf", "contract", "deeds", "stimm"] or (k in ["gear", "implant"] and int(it.r.rank) >= 5):
			Game.plaza_buy(i)
	_book("  of which plaza", Game.cur("credits") - pc0)

func _sell() -> void:
	# sell gear like a real player: junk always, and outgrown pieces once the inventory passes ~300
	var sc0 := Game.cur("credits")
	for it in Game.S.equip.duplicate():
		if it.owner != "" or it.get("locked", false) or it.level > 0:
			continue
		if it.rarity in ["common", "uncommon"]:
			Game.sell_equipment(it)
		elif Game.S.equip.size() > 300 and not (it.rarity == "legendary" and int(it.rank) >= 6):
			Game.sell_equipment(it)
	_book("  of which selling", Game.cur("credits") - sc0)

func next_campaign() -> Dictionary:
	for d in 3:
		for loc in 10:
			for st in 7:
				if Game.campaign_stars(d, loc, st) == 0:
					return {"d": d, "loc": loc, "st": st} if Game.campaign_unlocked(d, loc, st) else {}
	return {}

func play_days(days: int) -> void:
	var losses_in_row := 0
	var hid_rot := 0   # rotates through every hideout across sessions (guard % n starved index 0)
	for day in days:
		for session in 3:
			U.time_offset += 8 * 3600.0
			Game.tick()
			manage(true, session == 0)
			# energy: push campaign; if walled, farm the best hideout we can win
			var guard := 0
			while Game.cur("energy") >= 4 and guard < 40:   # a human session is time-limited (~40 battles)
				guard += 1
				var nx := next_campaign()
				var res := ""
				if not nx.is_empty() and losses_in_row < 3:
					res = fight(Content.build_campaign(nx.d, nx.loc, nx.st))
					losses_in_row = 0 if res == "win" else losses_in_row + 1
				else:
					var aligns: Array = squad().map(func(u): return "deeds_" + Game.tpl(Game.wl(u)).align)
					var pool: Array = ["trolls", "vultures", "teratek", "vikings", "synapse", "chopshop", "deeds_generic"] + aligns + aligns
					hid_rot += 1
					var id: String = pool[hid_rot % pool.size()]
					var stg: int = clampi(int(Game.hideout_state(id).max) + (1 if losses_in_row < 6 else 0), 1, 20)
					res = fight(Content.build_hideout(id, stg))
					if res == "win":
						losses_in_row = max(0, losses_in_row - 1)
					else:
						losses_in_row += 1
						if losses_in_row > 12:
							losses_in_row = 0   # try the campaign again later
				if res == "nopay":
					break
				# like a player: sort the squad out after a loss and every few battles, not after every win
				if res != "win" or guard % 5 == 0:
					manage()
			while Game.cur("heist") > 0:
				if fight(Content.build_hideout("heist", clampi(int(Game.hideout_state("heist").max) + 1, 1, 20))) == "nopay":
					break
			var syn: String = Game.tpl(Game.wl(squad()[0])).syn
			var sw_guard := 0
			while Game.cur("bounty") > 0 and sw_guard < 12:
				sw_guard += 1
				var st2 := 1
				while st2 < 20 and Game.sw_stars(syn, st2) > 0:
					st2 += 1
				if fight(Content.build_sw(syn, st2)) == "nopay":
					break
			while Game.cur("brawl") > 0:
				var opps := Content.pit_opponents("brawl")
				if opps.is_empty():
					break
				if fight(Content.build_pit("brawl", opps[0])) == "nopay":
					break
			if int(Game.S.gang.bastion.entries) > 0:
				fight(Content.build_bastion(int(Game.S.gang.bastion.stage)))
		_report_day(day)
		var total := 0
		for k in day_battles:
			total += int(day_battles[k])
		print("   battles today: %d %s  energy spent: %d" % [total, str(day_battles), day_energy])
		day_battles = {}
		day_energy = 0
		if (day + 1) % 10 == 0:
			var parts: Array = []
			for k in ledger:
				parts.append("%s %s/day" % [k, U.fmt(int(ledger[k] / float(day + 1)))])
			print("   credits ledger (avg/day): " + ", ".join(parts))

func _report_day(day: int) -> void:
	var team := squad()
	var nx := next_campaign()
	var where := "campaign done" if nx.is_empty() else "%s %d:%d" % [Data.DIFFS[nx.d], nx.loc + 1, nx.st + 1]
	var camp_h: float = float(play_secs.get("campaign", 0.0)) / 3600.0
	var all_h: float = 0.0
	for k in play_secs:
		all_h += float(play_secs[k]) / 3600.0
	for dd in 3:
		if not diff_done_at.has(dd) and (nx.is_empty() or int(nx.d) > dd):
			diff_done_at[dd] = [day + 1, camp_h]
			print("   %s difficulty done: day %d, %.1f h of campaign play" % [Data.DIFFS[dd], day + 1, camp_h])
	print("   playtime so far: %.1f h total, %.1f h campaign" % [all_h, camp_h])
	var lv_text := ", ".join(team.map(func(u): var w = Game.wl(u); return "%s L%d R%d rep%d" % [Game.tpl(w).name.split(" ")[0], w.level, w.rank, w.rep]))
	var equipped := 0
	var avg_lvl := 0.0
	for u in team:
		var w = Game.wl(u)
		equipped += w.gear.size()
		for s in w.gear:
			avg_lvl += float(Game.eq(w.gear[s]).level)
	avg_lvl /= max(1, equipped)
	var line := "day %2d | P-lv %d | power %s | next %s | credits %s | gear %d (sq %d slots, avg +%.1f) | roster %d | pit %d | hideout max T%d V%d | %s" % [day + 1, Game.S.player.level, U.fmt(Game.team_power(team)), where, U.fmt(Game.cur("credits")), Game.S.equip.size(), equipped, avg_lvl, Game.S.roster.size(), int(Game.S.pit.brawl.points), int(Game.hideout_state("trolls").max), int(Game.hideout_state("vikings").max), lv_text]
	print(line)
	if Game.S.equip.size() > 600:
		bad("inventory bloat: %d items on day %d" % [Game.S.equip.size(), day + 1])
