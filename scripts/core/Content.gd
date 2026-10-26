extends Node
## Encounter building and reward rolling for every game mode.

const NAME_A := ["Neon", "Chrome", "Static", "Null", "Volt", "Rust", "Ghost", "Razor", "Echo", "Glitch", "Hex", "Zero", "Byte", "Nova", "Viper", "Ash", "Cipher", "Riot", "Pulse", "Omega"]
const NAME_B := ["Jackal", "Saint", "Wraith", "Fang", "Dealer", "Kid", "Queen", "Baron", "Monk", "Rider", "Hound", "Prophet", "Shark", "Widow", "Golem", "Fox", "Mantis", "Reaper", "Lynx", "Duke"]

func random_player_name() -> String:
	return "%s%s%d" % [U.pick(NAME_A), U.pick(NAME_B), U.ri(1, 99)]

# ================================================================ unit helpers
## Enemy warlord instance. Enemies get an equipment-equivalent bonus that grows with rank.
func enemy(tpl_id: String, level: int, rank: int, rep := 0) -> Dictionary:
	var t: Dictionary = Warlords.get_t(tpl_id)
	var ab := {}
	for a in t.abilities:
		ab[a.id] = clampi(1 + (rank - 1) / 2, 1, Data.ability_max_level(a))
	return {"tpl": tpl_id, "level": level, "rank": mini(rank, 6), "rep": rep, "ab": ab, "nn": {}, "gear": {}}

func enemy_bonus(level: int, rank: int) -> float:
	var r := float(rank - 1)
	return 0.04 * r + 0.03 * r * r + 0.002 * level

func enemy_unit(tpl_id: String, level: int, rank: int, rep := 0, boss_mult := 1.0, bonus_add := 0.0) -> Dictionary:
	return Battle.make_unit(enemy(tpl_id, level, rank, rep), 1, enemy_bonus(level, rank) + bonus_add, boss_mult)

func player_units(uids: Array) -> Array:
	var out: Array = []
	for u in uids:
		var w = Game.wl(u)
		if w != null:
			out.append(Battle.make_unit(w, 0))
	return out

## Mixed gang of a syndicate: generic members plus recruitable warlords as stages climb.
func gang(syn: String, count: int, level: int, rank: int, rep: int, quality: float, exclude: Array = [], max_modders := 99, bonus_add := 0.0, unique_named := false, max_named := 99) -> Array:
	var pool_generic := ["thug_" + syn, "medic_" + syn, "netrunner_" + syn, "bruiser_" + syn]
	var max_rar := 2 if rank <= 2 else (3 if rank <= 4 else 4)
	var pool_named: Array = Warlords.by_syndicate(syn).filter(func(id): return Data.rarity_idx(Warlords.get_t(id).rarity) <= mini(max_rar, 3) and not exclude.has(id))
	var out: Array = []
	var modders := 0
	var named := 0
	for i in count:
		var id: String
		if U.rf() < quality and not pool_named.is_empty() and named < max_named:
			named += 1
			id = U.pick(pool_named)
			if unique_named:
				pool_named.erase(id)
		else:
			id = pool_generic[i % pool_generic.size()] if i < 4 else U.pick(pool_generic)
		# healer cap: swap extra modders (healers) for a bruiser
		if Warlords.get_t(id).cls == "modder":
			modders += 1
			if modders > max_modders:
				id = "bruiser_" + syn
		out.append(enemy_unit(id, level, rank, rep, 1.0, bonus_add))
	return out

# ================================================================ campaign
func campaign_stage(d: int, loc: int, st: int) -> Dictionary:
	return Data.GDD.campaign[loc].stages[st]

func build_campaign(d: int, loc: int, st: int) -> Dictionary:
	var stg := campaign_stage(d, loc, st)
	var lv := int(stg.enemy[d][0])
	var rk := int(stg.enemy[d][1])
	var rp := int(stg.enemy[d][2])
	var syn: String = Data.CAMPAIGN_SYNDICATE[loc]
	var quality := 0.05 + 0.07 * loc + 0.15 * d
	# a stage always fields the same line-up: gang() rolls on U.rng, so seed it here and restore after
	var rng_state: int = U.rng.state
	U.rng.seed = 1000003 * (d + 1) + 1009 * loc + st
	var bonus := campaign_bonus(d, loc, st)
	var max_mod := 1
	var enemies: Array
	if st == 6:
		# Den boss: strongest named warlord of the syndicate
		var named: Array = Warlords.by_syndicate(syn)
		named.sort_custom(func(a, b): return Data.rarity_idx(Warlords.get_t(a).rarity) > Data.rarity_idx(Warlords.get_t(b).rarity))
		# Street Punk den bosses top out at epic; legendary bosses appear on Mob Boss / Warlord difficulty
		var cap := 3 if d == 0 else 4
		var allowed: Array = named.filter(func(id): return Data.rarity_idx(Warlords.get_t(id).rarity) <= cap)
		if allowed.is_empty():
			allowed = named
		# vary bosses: a syndicate's second den uses another named warlord, and Warlord difficulty rotates again
		var occ := 0
		for i in loc:
			if Data.CAMPAIGN_SYNDICATE[i] == syn:
				occ += 1
		var top: Array = allowed.slice(0, mini(3, allowed.size()))
		var pick := (occ * 2 + (1 if d == 2 else 0)) % top.size()
		var boss_id: String = top[pick] if loc >= 2 or d > 0 else allowed[min(2, allowed.size() - 1)]
		# Warlord line-up rules (smooth the climb): no healer bosses from den 4 (revive / heal stalls made
		# random walls) and no legendary bosses before den 6
		if d == 2 and loc >= 3:
			var ok := func(id): return Warlords.get_t(id).cls != "modder" and (loc >= 5 or Warlords.get_t(id).rarity != "legendary")
			if not ok.call(boss_id):
				for alt in allowed:
					if ok.call(alt):
						boss_id = alt
						break
		enemies = [enemy_unit(boss_id, lv, rk, rp, campaign_boss_mult(boss_id), bonus)]
		max_mod = 0 if d == 2 or Warlords.get_t(boss_id).cls == "modder" else 1   # no healer escorts for Warlord bosses
		enemies.append_array(gang(syn, 3, max(1, lv - 2), rk, rp, quality, [boss_id], max_mod, bonus, true, 2))
	else:
		# named warlords build up through a den (1 / 2 / 3); all-named squads were random walls late on
		# Warlord regular stages: no named healers (their self-heal stalls were the remaining walls)
		var no_named: Array = Warlords.by_syndicate(syn).filter(func(id): return Warlords.get_t(id).cls == "modder") if d == 2 else []
		enemies = gang(syn, 4, lv, rk, rp, quality, no_named, max_mod, bonus, true, 1 + st / 2)
	U.rng.state = rng_state
	var loc_name: String = Data.GDD.campaign[loc].name
	return {"mode": "campaign", "d": d, "loc": loc, "st": st, "title": "%s %d-%d" % [loc_name, loc + 1, st + 1], "subtitle": Data.DIFFS[d],
		"waves": [enemies], "energy": Data.CAMPAIGN_ENERGY[d], "chevron_turns": 12 + st, "syn": syn}

## Extra gear-equivalent bonus for campaign enemies (open lever): Mob Boss and Warlord climb
## steadily den by den on top of the GDD enemy levels.
## Tuned with tests/review/07/Wall07.tscn: Street Punk unchanged; Mob Boss wins most dens with an R5
## epic squad and the last dens are ~50/50; Warlord needs R6 (R6 epic wins the early dens, ~50% in the
## middle, dens 9-10 need R6 legendary).
const CAMPAIGN_BONUS := [[0.0, 0.0], [0.0, 0.045], [0.65, 0.04]]   # per difficulty: [base, per den]

func campaign_bonus(d: int, loc: int, st: int) -> float:
	var t := loc + st / 6.0   # 0 at den 1 stage 1, 10 at den 10 boss
	return CAMPAIGN_BONUS[d][0] + CAMPAIGN_BONUS[d][1] * t

## Den boss HP multiplier. Healers heal off their own max HP, so modder bosses get none; legendary
## bosses already carry their kit, so they get less than the 1.8 default.
func campaign_boss_mult(boss_id: String) -> float:
	var t: Dictionary = Warlords.get_t(boss_id)
	if t.cls == "modder":
		return 1.0
	return 1.3   # one boss HP multiplier for every non-healer den boss (epic final boss at 1.8 was a wall)

func campaign_set(loc: int) -> String:
	var s: String = Data.GDD.campaign[loc].set
	if s == "Rotates Daily":
		return Game.corpo_tower_set()
	if s == "Crit Chance": return "Critical Chance"
	if s == "Crit Damage": return "Critical Damage"
	return s

func campaign_rewards(enc: Dictionary, won: bool) -> Dictionary:
	var stg := campaign_stage(enc.d, enc.loc, enc.st)
	var rew: Array = stg.rew[enc.d]
	var xp := int(rew[0])
	var res := {"xp": xp if won else int(xp * 0.2), "items": [], "pxp": 0}
	if not won:
		return res
	var list: Array = [{"k": "credits", "n": int(rew[1])}]
	var drops: Array = Data.CAMPAIGN_DROPS[enc.d]
	var out: Array = Game.grant(list)
	for dr in drops:
		if not U.chance(float(dr[2])):
			continue
		match dr[0]:
			"warlord":
				out.append_array(Game.grant([{"k": "warlord", "r": dr[1], "n": 1}]))
			"contract":
				out.append_array(Game.grant([{"k": "contract", "r": "uncommon", "n": int(dr[1])}]))
			"equip":
				var q: Dictionary = Data.CAMPAIGN_EQUIP[enc.d]
				var slot_name: String = String(stg.slot).to_lower()
				var slot: String = slot_name if Data.GEAR_SLOTS.has(slot_name) else U.pick(Data.GEAR_SLOTS)
				var it := Game.gen_equipment("gear", int(U.weighted(q.ranks)), U.weighted(q.rar), campaign_set(enc.loc), slot)
				out.append({"label": Game.equip_name(it), "icon": Data.SLOT_ICON[it.slot], "color": Data.RARITY_COLOR[it.rarity], "equip": it.uid})
	res.items = out
	return res

# ================================================================ hideouts
const HIDEOUTS := {
	"trolls": {"name": "Cardinal Trolls", "boss": "Deacon Chainz", "kind": "gear", "desc": "Deacon Chainz, head of the east side monastery, leads his devoted acolytes in raids on your territory. A spiky tank who ENRAGES and BREAKS while reflecting damage.",
		"tips": ["Resist or block the debuffs", "Cleanse debuffs regularly", "High sustain and HP to take the reflect", "Control or stun lock the Acolytes", "Turn meter control the boss", "Remove buffs from the boss"]},
	"vultures": {"name": "Vultures", "boss": "Cormac the Carrion Leech", "kind": "gear", "desc": "Cormac lacerates your Warlords, opening wounds until his bloodlust drives him to Devour. Healing provokes him.",
		"tips": ["Resist or block the debuffs", "Cleanse BLEED regularly", "Enemy max HP attacks", "Revives and unkillable", "High HP teams", "Heal Block"]},
	"teratek": {"name": "TeraTek Cybernetics", "short": "TeraTek", "boss": "Issac Vaun", "kind": "gear", "desc": "Issac Vaun, CFO of TeraTek, makes opportunist plays while his enforcers punish turn meter control.",
		"tips": ["Resist or block the debuffs", "Cleanse regularly", "Turn meter down + control the minions", "Firewall down and buff removal"]},
	"vikings": {"name": "Quantum Vikings", "boss": "The Hammer of Four", "kind": "gear", "desc": "The Hammer of Four shocks your gang and calls his warband. His four raiders form a shield wall and he revives them.",
		"tips": ["AoE damage to kill minions", "Cleanse SHOCK", "Armour mitigation is strong here", "Block revive skills", "Heal Block", "Minion control"]},
	"synapse": {"name": "Synapse Centre", "boss": "MNEMOSYNE Core", "kind": "mf", "desc": "The only place to acquire Memory Fragments for the Neuronet. MNEMOSYNE is shielded by its drones.",
		"tips": ["Kill the Synapse Drones first", "Cleanse STUPEFY", "Keep buffs refreshed after Cognitive Wipe"]},
	"heist": {"name": "The Heist", "boss": "WARDEN-9 Vault Mech", "kind": "credits", "desc": "Crack the vault for huge Credit payouts. Requires a Heist Plan (5 per day).",
		"tips": ["Burst it below 50% HP to drop its plating", "Speed buffs counter Lockdown"]},
	"chopshop": {"name": "The Chopshop", "boss": "Doc Sawbones", "kind": "implant", "desc": "The primary location for Implants. Doc Sawbones harvests augments and buffs his crew.",
		"tips": ["Strip buffs from his crew", "Bring Heal Block immunity or cleansers", "Burst down the Patchers"]},
	"deeds_paragon": {"name": "Paragon Deeds", "boss": "Saint Lumen", "kind": "deeds", "align": "paragon", "desc": "Earn Paragon Deeds for reputation. Saint Lumen punishes buffed teams.",
		"tips": ["Debuff-light teams", "Burst through Sanctify"]},
	"deeds_neutral": {"name": "Neutral Deeds", "boss": "The Grey Broker", "kind": "deeds", "align": "neutral", "desc": "Earn Neutral Deeds. The Broker takes less damage from buffed attackers.",
		"tips": ["Attack without buffs", "Cleanse Market Crash"]},
	"deeds_renegade": {"name": "Renegade Deeds", "boss": "Red Mara", "kind": "deeds", "align": "renegade", "desc": "Earn Renegade Deeds. Red Mara grows stronger every turn.",
		"tips": ["Kill her fast", "Firepower Down", "Stun immunity helps"]},
	"deeds_generic": {"name": "Generic Deeds", "boss": "The Archivist", "kind": "deeds", "align": "generic", "desc": "Earn Generic Deeds needed for every reputation level.",
		"tips": ["Block Debuffs against BREAK", "Turn meter boosts"]},
}
const HIDEOUT_ORDER := ["trolls", "vultures", "teratek", "vikings", "synapse", "chopshop", "heist", "deeds_paragon", "deeds_neutral", "deeds_renegade", "deeds_generic"]

## Hideout enemy level per stage (the GDD gives none). Stages 1-10 climb gently, 11-15 by 8 a stage,
## 16-20 by 16 (stage 20 = level 161). Tuned with HideoutProbe: stage 10 for R5, stage 15 for R6,
## stage 20 ~50% for a maxed R6 legendary+20 squad and under 15% for R6 epic+16.
func hideout_level(stage: int) -> Array:
	var lv := 4 * stage + 1
	if stage > 10:
		lv = 41 + 8 * (stage - 10) if stage <= 15 else 81 + 16 * (stage - 15)
	return [lv, clampi(1 + stage / 3, 1, 6), clampi(stage / 3, 0, 6)]

func hideout_cost(id: String, stage: int) -> Dictionary:
	var kind: String = HIDEOUTS[id].kind
	if kind == "credits":
		return {"heist": 1}
	if kind == "mf":
		return {"energy": int(Data.GDD.synapse[stage - 1].energy)}
	if kind == "deeds":
		return {"energy": int(Data.GDD.deeds[stage - 1].energy)}
	if kind == "implant":
		return {"energy": int(Data.GDD.chopshop[stage - 1].energy)}
	return {"energy": int(Data.GDD.hideoutGear[stage - 1].energy)}

## "Bring It On" per gear hideout boss. Trolls and TeraTek bosses are not listed as Turn Meter immune in the GDD.
const HIDEOUT_BOSS_IMMUNE := {
	"trolls": ["stun", "shock", "stupefy", "cdIncrease", "enraged"],
	"vultures": ["stun", "shock", "stupefy", "cdIncrease", "enraged", "tm"],
	"teratek": ["stun", "shock", "stupefy", "cdIncrease", "enraged"],
	"vikings": ["stun", "shock", "stupefy", "cdIncrease", "enraged", "tm"],
}
const BRING_IT_ON_TEXT := {
	"trolls": "Bring It On: Immune to STUN, SHOCK, STUPEFY, COOLDOWN INCREASE and ENRAGED.",
	"vultures": "Bring It On: Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.",
	"teratek": "Bring It On: Immune to STUN, SHOCK, STUPEFY, COOLDOWN INCREASE and ENRAGED.",
	"vikings": "Bring It On: Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.",
}

func build_hideout(id: String, stage: int) -> Dictionary:
	var l := hideout_level(stage)
	var lv: int = l[0]
	var rk: int = l[1]
	var rp: int = l[2]
	var boss_m := 2.5 + stage * 0.15 + 0.6 * maxi(0, stage - 15)   # boss HP x; steepens over stages 16-20
	var wave1: Array
	var wave2: Array
	match id:
		"trolls":
			wave1 = gang("trolls", 4, lv, rk, rp, 0.3)
			wave2 = [enemy_unit("deacon_chainz", lv, rk, rp, boss_m), enemy_unit("bishop_brick", lv, rk, rp), enemy_unit("bishop_clyde", lv, rk, rp)]
		"vultures":
			wave1 = gang("vultures", 4, lv, rk, rp, 0.3)
			wave2 = [enemy_unit("cormac", lv, rk, rp, boss_m), enemy_unit("thug_vultures", lv, rk, rp), enemy_unit("thug_vultures", lv, rk, rp)]
		"teratek":
			wave1 = gang("teratek", 4, lv, rk, rp, 0.3)
			wave2 = [enemy_unit("issac_vaun", lv, rk, rp, boss_m), enemy_unit("kellen", lv, rk, rp), enemy_unit("ried", lv, rk, rp)]
		"vikings":
			wave1 = gang("vikings", 3, lv, rk, rp, 0.3)
			wave2 = [enemy_unit("hammer_of_four", lv, rk, rp, boss_m)]
			for i in 4:
				wave2.append(enemy_unit("raider", lv, rk, rp))
		"synapse":
			wave1 = gang("teratek", 4, lv, rk, rp, 0.2)
			wave2 = [enemy_unit("mnemosyne", lv, rk, rp, boss_m), enemy_unit("synapse_drone", lv, rk, rp), enemy_unit("synapse_drone", lv, rk, rp)]
		"chopshop":
			wave1 = gang("vultures", 4, lv, rk, rp, 0.2)
			wave2 = [enemy_unit("doc_sawbones", lv, rk, rp, boss_m), enemy_unit("medic_vultures", lv, rk, rp), enemy_unit("bruiser_vultures", lv, rk, rp)]
		"heist":
			wave1 = gang("teratek", 4, lv, rk, rp, 0.2)
			wave2 = [enemy_unit("warden9", lv, rk, rp, boss_m), enemy_unit("netrunner_teratek", lv, rk, rp), enemy_unit("netrunner_teratek", lv, rk, rp)]
		_:
			var boss: String = {"deeds_paragon": "saint_lumen", "deeds_neutral": "broker_grey", "deeds_renegade": "red_mara", "deeds_generic": "archivist"}[id]
			var syn: String = Warlords.get_t(boss).syn
			wave1 = gang(syn, 4, lv, rk, rp, 0.25)
			wave2 = [enemy_unit(boss, lv, rk, rp, boss_m), enemy_unit("bruiser_" + syn, lv, rk, rp), enemy_unit("medic_" + syn, lv, rk, rp)]
	# GDD "Bring It On" (boss passive): applied to the hideout boss only, so recruited copies stay normal
	if HIDEOUT_BOSS_IMMUNE.has(id):
		wave2[0].immune.append_array(HIDEOUT_BOSS_IMMUNE[id])
	var h: Dictionary = HIDEOUTS[id]
	return {"mode": "hideout", "id": id, "stage": stage, "title": "%s - Stage %d" % [h.name, stage], "subtitle": "Boss: " + h.boss,
		"waves": [wave1, wave2], "cost": hideout_cost(id, stage), "chevron_turns": 30}

func _rank_weights(d: Dictionary) -> Dictionary:
	var w := {}
	for k in d:
		w[int(k)] = float(d[k])
	return w

func hideout_rewards(enc: Dictionary, won: bool) -> Dictionary:
	var stage: int = enc.stage
	var xp := 3000 + 1500 * stage
	var res := {"xp": xp if won else int(xp * 0.2), "items": []}
	if not won:
		return res
	var id: String = enc.id
	var kind: String = HIDEOUTS[id].kind
	var out: Array = []
	match kind:
		"gear", "implant":
			var row: Dictionary = (Data.GDD.chopshop if kind == "implant" else Data.GDD.hideoutGear)[stage - 1]
			out.append_array(Game.grant([{"k": "credits", "n": int(row.credits)}]))
			var rank := int(U.weighted(_rank_weights(row.ranks)))
			var rar: String = U.weighted(row.rar)
			var it: Dictionary
			if kind == "implant":
				it = Game.gen_equipment("implant", rank, rar, "", U.weighted(row.slots))
			else:
				it = Game.gen_equipment("gear", rank, rar, U.pick(Data.HIDEOUT_SETS[id]))
			out.append({"label": Game.equip_name(it), "icon": Data.SLOT_ICON[it.slot], "color": Data.RARITY_COLOR[it.rarity], "equip": it.uid})
			Game.track("hideoutEquip", 1)
		"mf":
			var srow: Dictionary = Data.GDD.synapse[stage - 1]
			var list: Array = []
			for r in srow.rows:
				var tier := int(String(r[0]).split(" ")[1])
				var amt := _range_roll(String(r[1]))
				if amt > 0:
					list.append({"k": "mf", "tier": tier, "n": amt})
			out.append_array(Game.grant(list))
		"credits":
			var hrow: Dictionary = Data.GDD.heist[stage - 1]
			var pickrow = U.weighted(hrow.rows.map(func(r): return [r[0], float(r[1])]))
			out.append_array(Game.grant(U.parse_rewards(String(pickrow))))
		"deeds":
			var align: String = HIDEOUTS[id].align
			var drow: Dictionary = Data.GDD.deeds[stage - 1]
			var list2: Array = []
			var tier_re := RegEx.create_from_string("^(\\d+)(?:-(\\d+))? (Minor|Major|Grand)$")
			# the Minor / Major / Grand chances sum to 100%: exactly one tier drops per win (GDD)
			var tier_rows: Array = drow.rows.filter(func(r): return tier_re.search(String(r[0])) != null and float(String(r[1]).replace("%", "")) > 0.0)
			if not tier_rows.is_empty():
				var pick = U.weighted(tier_rows.map(func(r): return [r, float(String(r[1]).replace("%", ""))]))
				var m := tier_re.search(String(pick[0]))
				var lo := int(m.get_string(1))
				var hi := int(m.get_string(2)) if m.get_string(2) != "" else lo
				list2.append({"k": "deeds", "align": align, "tier": m.get_string(3).to_lower(), "n": U.ri(lo, hi)})
			for r in drow.rows:
				var text := String(r[0])
				if text.begins_with("N/A") or tier_re.search(text) != null:
					continue
				if U.chance(float(String(r[1]).replace("%", ""))):
					list2.append_array(U.parse_rewards(text))
			out.append_array(Game.grant(list2))
	Game.track("hideout", 1)
	Game.hideout_record_win(id, stage)
	res.items = out
	return res

func _range_roll(s: String) -> int:
	if s.contains("-"):
		var p := s.split("-")
		return U.ri(int(p[0]), int(p[1]))
	return int(s)

# ================================================================ syndicate wars
func build_sw(syn: String, stage: int) -> Dictionary:
	var lv := 3 * stage + 2
	var rk := clampi(1 + stage / 4, 1, 6)
	var rp := clampi(stage / 4, 0, 6)
	var foe_syn: String = Data.SYNDICATES.keys()[(Data.SYNDICATES.keys().find(syn) + stage) % Data.SYNDICATES.size()]
	if foe_syn == syn:
		foe_syn = Data.SYNDICATES.keys()[(Data.SYNDICATES.keys().find(syn) + 1) % Data.SYNDICATES.size()]
	var enemies := gang(foe_syn, 4, lv, rk, rp, 0.3 + stage * 0.03)
	var row: Dictionary = Data.GDD.syndicateWars[stage - 1]
	return {"mode": "sw", "syn": syn, "stage": stage, "title": "Syndicate Wars - %s %d" % [Data.SYNDICATES[syn].name, stage],
		"subtitle": "vs " + Data.SYNDICATES[foe_syn].name, "waves": [enemies], "cost": {"bounty": int(row.tokens)}, "chevron_turns": 14, "lock_syn": syn}

func sw_rewards(enc: Dictionary, won: bool) -> Dictionary:
	var xp := 2000 + 1000 * int(enc.stage)
	var res := {"xp": xp if won else int(xp * 0.2), "items": []}
	if won:
		var row: Dictionary = Data.GDD.syndicateWars[enc.stage - 1]
		var rank := int(U.weighted(_rank_weights(row.ranks)))
		res.items = Game.grant([{"k": "neon", "rank": rank, "n": 1}])
	return res

# ================================================================ pit
func pit_opponents(mode: String) -> Array:
	var p: Dictionary = Game.S.pit[mode]
	if not p.opps.is_empty() and U.now() - float(p.opps_t) < 3600.0:
		return p.opps
	var best: Array = Game.S.roster.duplicate()
	best.sort_custom(func(a, b): return Game.power(a) > Game.power(b))
	var size := 7 if mode == "royal" else 4
	var avg_lv := 0
	var avg_rk := 0
	var n := mini(5, best.size())
	for i in n:
		avg_lv += best[i].level
		avg_rk += best[i].rank
	avg_lv = max(1, avg_lv / max(1, n))
	avg_rk = clampi(avg_rk / max(1, n), 1, 6)
	var tier := Game.pit_tier(int(p.points))
	var my_avg := 0.0
	for i in n:
		my_avg += Game.power(best[i])
	my_avg /= max(1, n)
	var opps: Array = []
	for i in 10:
		var lv := clampi(avg_lv + U.ri(-4, 3) + tier / 3, 1, 60)
		var rk := clampi(avg_rk + (1 if U.rf() < 0.15 else 0) - (1 if U.rf() < 0.2 else 0), 1, 6)
		lv = min(lv, rk * 10)
		var team: Array = []
		var pool: Array = U.shuffled(Warlords.RECRUITABLE)
		for j in size:
			team.append({"tpl": pool[j], "level": lv, "rank": rk, "rep": clampi(rk - 2, 0, 6)})
		var pts := int(p.points) + U.ri(-60, 80)
		var opp := {"id": U.uid(), "name": random_player_name(), "points": max(0, pts), "team": team, "level": lv, "rank": rk, "k": 1.0}
		# geared like a real player: scale the squad to a target strength around yours, harder in higher brackets
		var target: float = my_avg * (0.8 + 0.035 * i + 0.012 * tier) * (0.95 + 0.1 * U.rf())
		var raw := _opp_power(opp) / float(size)
		opp.k = clampf(target / max(1.0, raw), 0.5, 4.0)
		opp.power = int(_opp_power(opp) * (4.0 / float(size)) if size > 4 else _opp_power(opp))
		opps.append(opp)
	opps.sort_custom(func(a, b): return a.power < b.power)
	p.opps = opps
	p.opps_t = U.now()
	Game.mark()
	return opps

func _opp_power(opp: Dictionary) -> float:
	var s := 0.0
	for m in opp.team:
		s += Data.stat_power(Warlords.get_t(m.tpl).cls, _pit_unit(m, float(opp.get("k", 1.0)), 1).base)
	return s

## One Pit opponent unit: enemy template at its level/rank, stats scaled by the opponent's gear factor k.
func _pit_unit(m: Dictionary, k: float, side: int) -> Dictionary:
	var u := Battle.make_unit(enemy(m.tpl, m.level, m.rank, m.rep), side, enemy_bonus(m.level, m.rank))
	for st in ["hp", "arm", "fp", "hack"]:
		u.base[st] = float(u.base[st]) * k
	return u

func build_pit(mode: String, opp: Dictionary) -> Dictionary:
	var k := float(opp.get("k", 1.0))
	var units: Array = []
	for m in opp.team.slice(0, 4):
		units.append(_pit_unit(m, k, 1))
	var reinf: Array = []
	if mode == "royal":
		for m in opp.team.slice(4, 7):
			reinf.append(_pit_unit(m, k, 1))
	return {"mode": "pit", "pit_mode": mode, "opp": opp, "title": "Pit %s vs %s" % [U.cap("brawl" if mode == "brawl" else "royal"), opp.name],
		"subtitle": "%d points" % opp.points, "waves": [units], "enemy_reinf": reinf, "cost": {mode: 1}, "royal": mode == "royal", "chevron_turns": 99}

# ================================================================ bastion
const BASTION_STAGES := [
	{"name": "The Atrium", "boss": "atrium_sentinel", "syn": "teratek"},
	{"name": "The Foundry", "boss": "foundry_titan", "syn": "teratek"},
	{"name": "Head of the Hydra", "boss": "hydra_ceo", "syn": "teratek"},
]
## Turn cap per Bastion entry (open lever, the GDD gives none). Long enough for the "Survive 45 Turns" ambition.
const BASTION_TURNS := 50

func build_bastion(stage: int) -> Dictionary:
	var info: Dictionary = BASTION_STAGES[stage - 1]
	var lv := 30 + stage * 15
	var rk := clampi(3 + stage, 1, 6)
	var boss := enemy_unit(info.boss, lv, rk, 3, 60.0)
	var adds := [enemy_unit("teratek_drone", lv - 10, rk - 1, 1), enemy_unit("teratek_drone", lv - 10, rk - 1, 1), enemy_unit("teratek_drone", lv - 10, rk - 1, 1)]
	return {"mode": "bastion", "stage": stage, "title": "Bastion - " + info.name, "subtitle": "Deal as much damage as you can in %d turns" % BASTION_TURNS,
		"waves": [[boss] + adds], "cost": {"bastion": 1}, "turn_limit": BASTION_TURNS, "chevron_turns": 99}

## Daily damage tiers, one table per stage (open lever: the GDD tables are blank). Sized so the top
## tier needs about 3 good entries from an endgame squad (~35K per entry at Lv 60 R6); stage 3 pays most.
const BASTION_TIERS := [
	[[3000, "50K Credits"], [8000, "1x Rare Contract, 100K Credits"], [18000, "50 Trinium, 1x Lvl 3 Firmware"], [35000, "1x Epic Stimm, 250K Credits"], [60000, "1x Epic Contract, 100 Trinium"], [100000, "1x Legendary Stimm, 500K Credits"]],
	[[4000, "75K Credits"], [10000, "1x Rare Contract, 150K Credits"], [22000, "75 Trinium, 1x Lvl 3 Firmware"], [42000, "1x Epic Stimm, 350K Credits"], [72000, "1x Epic Contract, 150 Trinium"], [120000, "1x Legendary Stimm, 750K Credits"]],
	[[5000, "100K Credits"], [12000, "2x Rare Contract, 200K Credits"], [26000, "100 Trinium, 1x Lvl 3 Firmware"], [50000, "1x Epic Stimm, 500K Credits"], [85000, "1x Epic Contract, 200 Trinium"], [140000, "1x Legendary Stimm, 1M Credits"]],
]

func bastion_tiers(stage: int) -> Array:
	return BASTION_TIERS[clampi(stage, 1, BASTION_TIERS.size()) - 1]

func bastion_rewards(stage: int, dmg: int) -> Array:
	var out: Array = []
	for tr in bastion_tiers(stage):
		if dmg >= int(tr[0]):
			out.append_array(U.parse_rewards(tr[1]))
	return out

# ================================================================ chevrons
## 1: win, 2: no warlord lost, 3: won within the turn target.
func chevrons(b: Battle, enc: Dictionary) -> int:
	if b.result != "win":
		return 0
	var n := 1
	if not b.ally_died():
		n += 1
	if b.player_turns <= int(enc.get("chevron_turns", 99)):
		n += 1
	return n

# ================================================================ encounter lifecycle
func enc_cost(enc: Dictionary) -> Dictionary:
	if enc.has("cost"):
		return enc.cost
	return {"energy": int(enc.get("energy", 0))}

func rebuild(enc: Dictionary) -> Dictionary:
	match enc.mode:
		"campaign": return build_campaign(enc.d, enc.loc, enc.st)
		"hideout": return build_hideout(enc.id, enc.stage)
		"sw": return build_sw(enc.syn, enc.stage)
		"bastion": return build_bastion(enc.stage)
		"pit": return build_pit(enc.pit_mode, enc.opp)
	return enc

## The following encounter, or {} if none / locked.
func next_enc(enc: Dictionary) -> Dictionary:
	match enc.mode:
		"campaign":
			var loc: int = enc.loc
			var st: int = enc.st + 1
			if st > 6:
				st = 0
				loc += 1
			if loc > 9:
				return {}
			if Game.campaign_unlocked(enc.d, loc, st):
				return build_campaign(enc.d, loc, st)
		"hideout":
			if enc.stage < 20 and int(Game.hideout_state(enc.id).max) >= enc.stage:
				return build_hideout(enc.id, enc.stage + 1)
		"sw":
			if enc.stage < 20 and Game.sw_stars(enc.syn, enc.stage) > 0:
				return build_sw(enc.syn, enc.stage + 1)
	return {}

## Apply the outcome of a finished battle. Returns a summary for the result screen.
func finish(enc: Dictionary, b: Battle, team: Array) -> Dictionary:
	var won := b.result == "win"
	var stars := chevrons(b, enc)
	var res := {"xp": 0, "items": []}
	match enc.mode:
		"campaign":
			res = campaign_rewards(enc, won)
			Game.track("den", 1)
			if won:
				Game.campaign_record(enc.d, enc.loc, enc.st, stars)
		"hideout":
			res = hideout_rewards(enc, won)
		"sw":
			res = sw_rewards(enc, won)
			if won:
				Game.sw_record(enc.syn, enc.stage, stars)
		"pit":
			res = {"xp": 2500 if won else 500, "items": Game.pit_record(enc.pit_mode, won, enc.opp)}
			var kills := b.side_units(1, false).filter(func(u): return not u.alive).size()
			Game.track("pitKill", kills)
			Game.stat_add("pit_debuffs", b.debuffs_placed_by_player)
		"bastion":
			var dmg := int(b.damage_to_side(1))
			Game.bastion_record(dmg, b.player_turns, b.debuffs_on_boss)
			res = {"xp": 3000, "items": [], "damage": dmg}
			won = true
	# warlord XP split equally across the squad (GDD)
	var xp_total := int(res.xp * Game.xp_mult())
	var per: int = xp_total / maxi(1, team.size())
	var levels := {}
	for uid in team:
		var w = Game.wl(uid)
		if w:
			levels[uid] = Game.add_wxp(w, per)
	Game.save_game()
	var contrib: Array = []
	for u in b.side_units(0, false):
		contrib.append({"tpl": u.tpl, "uid": u.owner_uid, "dealt": int(u.dmg_dealt), "taken": int(u.dmg_taken), "healed": int(u.healed), "alive": u.alive})
	return {"won": won, "result": b.result, "stars": stars, "xp_each": per, "levels": levels, "items": res.items, "contrib": contrib,
		"damage": res.get("damage", 0), "pxp": int(enc_cost(enc).get("energy", 0))}

## Rough enemy power (same scale as Game.power) for the squad screen's difficulty read-out.
func enc_power(enc: Dictionary) -> int:
	var waves: Array = enc.get("waves", [])
	var best := 0.0
	for wv in waves:
		var s := 0.0
		for u in wv:
			s += Data.stat_power(String(u.cls), u.base)
		best = max(best, s)
	return int(best * 4.0 / max(4.0, float(waves[0].size()) if not waves.is_empty() else 4.0))
