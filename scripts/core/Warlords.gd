extends Node
## Warlord templates and abilities.
##
## Ability format (read by Battle.gd):
##  active:    {type:"active", cd, tgt:"enemy|all_enemies|ally|all_allies|self", mult, hits, fx:[...],
##              ignore_arm, vs:{debuff, mult}, below:{pct, mult}, random_targets, special, auto}
##  passive:   {type:"passive", stats:{...}, immune:[...], hooks:[{on, chance, fx, special}], special}
##  leader:    {type:"leader", aura:{stats:{...}, syn:""}}
##  reinforce: {type:"reinforce", fx:[...]}
## Effect format: {t:"debuff|buff|tm|heal|shield|cleanse|strip|call|extra_turn|revive|cd_reduce", ...}
##  debuff/buff: id, l (0 small / 1 large), turns, chance, to ("target","all_enemies","self","all_allies","lowest_ally","random_enemy")
##  tm: v (percent, negative removes), to     heal/shield: pct, of ("caster"|"target"), to, turns (shield)
##  cleanse/strip: n, to      call: n (syndicate allies), syn (bool)     revive: pct
##  any effect may carry "if": "crit" | "kill" | "has:<debuff>" | "debuffs>=N"

var T: Dictionary = {}       # id -> template
var RECRUITABLE: Array = []  # ids that can be pulled from contracts

func _ready() -> void:
	_build()
	for id in T:
		var t: Dictionary = T[id]
		if not t.get("enemy_only", false):
			RECRUITABLE.append(id)
		t["base"] = _base_stats(t)

func get_t(id: String) -> Dictionary:
	return T[id]

func by_rarity(r: String) -> Array:
	return RECRUITABLE.filter(func(id): return T[id].rarity == r)

func by_syndicate(s: String) -> Array:
	return RECRUITABLE.filter(func(id): return T[id].syn == s)

## Deterministic base stats inside the GDD class/rarity ranges.
func _base_stats(t: Dictionary) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash(t.id)
	var rng: Array = Data.BASE_RANGES[t.cls][t.rarity]
	var b := {
		"hp": r.randi_range(rng[0][0], rng[0][1]),
		"arm": r.randi_range(rng[1][0], rng[1][1]),
		"fp": r.randi_range(rng[2][0], rng[2][1]),
		"spd": r.randi_range(90, 110),
		"cc": Data.BASE_CC, "cd": Data.BASE_CD,
		"hack": 0, "fw": Data.BASE_FW,
	}
	if t.cls == "hacker":
		b.hack = r.randi_range(Data.HACKER_BASE_HACK[0], Data.HACKER_BASE_HACK[1])
	if t.has("spd"):
		b.spd = t.spd
	return b

# ---------------------------------------------------------------- builders
func _a(id: String, name: String, desc: String, mult: float, tgt := "enemy", cd := 0, fx := [], extra := {}) -> Dictionary:
	var d := {"id": id, "name": name, "desc": desc, "type": "active", "mult": mult, "tgt": tgt, "cd": cd, "fx": fx, "hits": 1}
	d.merge(extra, true)
	return d

func _p(id: String, name: String, desc: String, extra := {}) -> Dictionary:
	var d := {"id": id, "name": name, "desc": desc, "type": "passive"}
	d.merge(extra, true)
	return d

func _l(id: String, name: String, desc: String, stats: Dictionary, syn := "") -> Dictionary:
	return {"id": id, "name": name, "desc": desc, "type": "leader", "aura": {"stats": stats, "syn": syn}}

func _r(id: String, name: String, desc: String, fx: Array) -> Dictionary:
	return {"id": id, "name": name, "desc": desc, "type": "reinforce", "fx": fx}

func _db(id: String, turns: int, chance := 100.0, large := 0, to := "target", extra := {}) -> Dictionary:
	var d := {"t": "debuff", "id": id, "turns": turns, "chance": chance, "l": large, "to": to}
	d.merge(extra, true)
	return d

func _bf(id: String, turns: int, to := "self", large := 0, extra := {}) -> Dictionary:
	var d := {"t": "buff", "id": id, "turns": turns, "l": large, "to": to}
	d.merge(extra, true)
	return d

func _w(id: String, name: String, rarity: String, cls: String, syn: String, align: String, abilities: Array, extra := {}) -> void:
	var d := {"id": id, "name": name, "rarity": rarity, "cls": cls, "syn": syn, "align": align, "abilities": abilities}
	d.merge(extra, true)
	T[id] = d

const IMMUNE_BOSS := ["stun", "shock", "stupefy", "cdIncrease", "enraged"]
const IMMUNE_BOSS_TM := ["stun", "shock", "stupefy", "cdIncrease", "enraged", "tm"]

func _build() -> void:
	# ============================================================ CARDINAL TROLLS
	_w("brother_grin", "Brother Grin", "common", "firepower", "trolls", "renegade", [
		_a("knuckles", "Blessed Knuckles", "Attack 1 enemy. 20% chance to place BREAK for 2 turns.", 1.0, "enemy", 0, [_db("break", 2, 20)]),
		_a("moshpit", "Mosh Pit", "Attack all enemies.", 0.9, "all_enemies", 3),
	], {"lore": "Found religion in a riot. Kept the riot."})
	_w("sister_cackle", "Sister Cackle", "uncommon", "hacker", "trolls", "renegade", [
		_a("gospel_glitch", "Gospel Glitch", "Attack 1 enemy. 50% chance to place ARMOUR DOWN for 1 turn.", 1.0, "enemy", 0, [_db("armDown", 1, 50)]),
		_a("psalm_spite", "Psalm of Spite", "Attack all enemies. 50% chance to place ENRAGED for 1 turn.", 0.8, "all_enemies", 3, [_db("enraged", 1, 50)]),
		_p("hymn_havoc", "Hymn of Havoc", "Increase Critical Chance by 10%.", {"stats": {"cc": 10}}),
	])
	_w("abbot_mayhem", "Abbot Mayhem", "rare", "armour", "trolls", "neutral", [
		_a("censer_smash", "Censer Smash", "Attack 1 enemy. 25% chance to place BREAK for 2 turns.", 1.1, "enemy", 0, [_db("break", 2, 25)]),
		_a("sanctuary", "Sanctuary", "Place a 50% ARMOUR UP on all allies for 2 turns and a 50% COUNTER on self for 2 turns.", 0.0, "all_allies", 4, [_bf("armUp", 2, "all_allies", 1), _bf("counter", 2, "self", 0)]),
		_p("thick_skulled", "Thick Skulled", "Increase Armour by 15%.", {"stats": {"armP": 15}}),
		_l("congregation_wall", "Congregation Wall", "Cardinal Trolls allies gain 20% Armour.", {"armP": 20}, "trolls"),
	])
	_w("pontiff_ruckus", "Pontiff Ruckus", "epic", "modder", "trolls", "paragon", [
		_a("benediction", "Benediction Blast", "Attack 1 enemy, then heal the weakest ally by 10% of this Warlord's Max HP.", 1.0, "enemy", 0, [{"t": "heal", "pct": 10, "of": "caster", "to": "lowest_ally"}]),
		_a("holy_rave", "Holy Rave", "Place a 50% FIREPOWER UP and 15% SPEED UP on all allies for 2 turns.", 0.0, "all_allies", 3, [_bf("fpUp", 2, "all_allies", 1), _bf("spdUp", 2, "all_allies", 0)]),
		_a("last_rites", "Last Rites", "Heal all allies by 20% of this Warlord's Max HP and remove 1 debuff from each.", 0.0, "all_allies", 5, [{"t": "heal", "pct": 20, "of": "caster", "to": "all_allies"}, {"t": "cleanse", "n": 1, "to": "all_allies"}]),
		_p("fervor", "Fervor", "When an ally dies, all allies gain 20% Turn Meter.", {"hooks": [{"on": "ally_death", "fx": [{"t": "tm", "v": 20, "to": "all_allies"}]}]}),
		_l("faithful", "The Faithful", "All allies gain 15% Health.", {"hpP": 15}),
	])
	_w("deacon_chainz", "Deacon Chainz", "legendary", "armour", "trolls", "renegade", [
		_a("not_so_fast", "Not So Fast", "Attack 1 enemy and remove 10% Turn Meter, 20% if they have ENRAGED or BREAK, 40% if they have both.", 1.2, "enemy", 0, [], {"special": "not_so_fast"}),
		_a("holy_torment", "Holy Torment", "Attack all enemies and place ENRAGED for 1 turn.", 0.9, "all_enemies", 3, [_db("enraged", 1)], {"vfx": "chain"}),
		_a("holy_fracture", "Holy Fracture", "Attack all enemies and place a 25% BREAK for 2 turns.", 0.9, "all_enemies", 4, [_db("break", 2, 100, 1)], {"vfx": "holy"}),
		_p("divine_retribution", "Divine Retribution", "Receive a stack of 30% REFLECT for 2 turns each time ENRAGED is placed on an opponent.", {"special": "divine_retribution"}),
		_l("congregation", "Congregation", "Cardinal Trolls allies gain 20% Firepower.", {"fpP": 20}, "trolls"),
		_r("late_mass", "Late Mass", "On entering, place ENRAGED on all enemies for 1 turn.", [_db("enraged", 1, 100, 0, "all_enemies")]),
	], {"lore": "Head of the east side monastery. It's about time he atoned for his sins."})

	# ============================================================ VULTURES
	_w("scrapjaw", "Scrapjaw", "common", "firepower", "vultures", "renegade", [
		_a("rusty_hook", "Rusty Hook", "Attack 1 enemy. 25% chance to place BLEED for 2 turns.", 1.0, "enemy", 0, [_db("bleed", 2, 25)]),
		_a("gut_rip", "Gut Rip", "Attack 1 enemy 2 times.", 0.8, "enemy", 3, [], {"hits": 2}),
	])
	_w("nails", "Nails", "uncommon", "hacker", "vultures", "renegade", [
		_a("shiv", "Shiv", "Attack 1 enemy. 50% chance to place HEAL BLOCK for 2 turns.", 1.0, "enemy", 0, [_db("healBlock", 2, 50)]),
		_a("carrion_swarm", "Carrion Swarm", "Attack all enemies. 40% chance to place POISON for 2 turns.", 0.7, "all_enemies", 4, [_db("poison", 2, 40)]),
		_p("scavenger", "Scavenger", "Increase Hacking by 15.", {"stats": {"hack": 15}}),
	])
	_w("gristle", "Gristle", "rare", "armour", "vultures", "neutral", [
		_a("bone_crusher", "Bone Crusher", "Attack 1 enemy. 30% chance to place SPEED DOWN for 2 turns.", 1.1, "enemy", 0, [_db("spdDown", 2, 30)]),
		_a("gorge", "Gorge", "Heal self by 25% Max HP and place a 25% BOLSTER on self for 2 turns.", 0.0, "self", 4, [{"t": "heal", "pct": 25, "of": "caster", "to": "self"}, _bf("bolster", 2, "self", 1)]),
		_p("harvested_plating", "Harvested Plating", "When hit, 20% chance to gain a 50% COUNTER for 1 turn.", {"hooks": [{"on": "hit_taken", "chance": 20, "fx": [_bf("counter", 1, "self", 0)]}]}),
		_l("flock", "The Flock", "Vultures allies gain 15% Health.", {"hpP": 15}, "vultures"),
	])
	_w("madame_marrow", "Madame Marrow", "epic", "modder", "vultures", "renegade", [
		_a("leech_kiss", "Leech Kiss", "Attack 1 enemy and heal self by 50% of the damage dealt.", 1.0, "enemy", 0, [], {"lifesteal": 50}),
		_a("blood_rite", "Blood Rite", "Place a 15% VAMPIRE and 25% FIREPOWER UP on all allies for 2 turns.", 0.0, "all_allies", 3, [_bf("vampire", 2, "all_allies", 0), _bf("fpUp", 2, "all_allies", 0)]),
		_a("transfusion", "Transfusion", "Heal all allies by 20% of this Warlord's Max HP and remove 1 debuff from each.", 0.0, "all_allies", 5, [{"t": "heal", "pct": 20, "of": "caster", "to": "all_allies"}, {"t": "cleanse", "n": 1, "to": "all_allies"}]),
		_p("morbid_feast", "Morbid Feast", "Whenever an enemy dies, heal all allies by 10% of their Max HP.", {"hooks": [{"on": "enemy_death", "fx": [{"t": "heal", "pct": 10, "of": "target", "to": "all_allies"}]}]}),
		_l("marrow_court", "Marrow Court", "All allies gain 15% Critical Damage.", {"cd": 15}),
	])
	_w("cormac", "Cormac the Carrion Leech", "legendary", "firepower", "vultures", "renegade", [
		_a("open_wounds", "Open Wounds", "Attack 1 enemy, doubling all stacks of BLEED on the target.", 1.1, "enemy", 0, [], {"special": "open_wounds"}),
		_a("lacerate", "Lacerate", "Attack all enemies 3 times. Places 1 stack of 5% BLEED for 2 turns with each hit.", 0.45, "all_enemies", 4, [_db("bleed", 2, 100, 1)], {"hits": 3}),
		_a("devour", "Devour", "(Automatic) When an enemy has 5 stacks of BLEED: attack it, ignoring 100% Armour, remove all BLEED and heal by 25% Max HP.", 1.8, "enemy", 0, [], {"special": "devour", "auto": true, "ignore_arm": 100}),
		_p("tear_stitches", "Tear Stitches", "Uses Open Wounds on a random target whenever an opponent heals. 1 turn cooldown.", {"special": "tear_stitches"}),
		_l("carrion_call", "Carrion Call", "Vultures allies gain 20% Critical Damage.", {"cd": 20}, "vultures"),
		_r("fresh_meat", "Fresh Meat", "On entering, place BLEED on all enemies for 2 turns.", [_db("bleed", 2, 100, 0, "all_enemies")]),
	], {"lore": "A high ranking Vulture known for his love of bleeding enemies dry."})

	# ============================================================ TERATEK CYBERNETICS
	_w("intern7", "Intern 7", "common", "modder", "teratek", "neutral", [
		_a("stapler", "Stapler Shot", "Attack 1 enemy.", 1.0),
		_a("coffee_run", "Coffee Run", "Grant an ally 25% Turn Meter and 15% SPEED UP for 2 turns.", 0.0, "ally", 3, [{"t": "tm", "v": 25, "to": "target"}, _bf("spdUp", 2, "target", 0)]),
	])
	_w("auditor_kase", "Auditor Kase", "uncommon", "hacker", "teratek", "paragon", [
		_a("audit", "Audit", "Attack 1 enemy. 40% chance to place ARMOUR DOWN for 2 turns.", 1.0, "enemy", 0, [_db("armDown", 2, 40)]),
		_a("freeze_assets", "Freeze Assets", "Remove 10% Turn Meter from all enemies and 50% chance to place SPEED DOWN for 2 turns.", 0.5, "all_enemies", 4, [{"t": "tm", "v": -10, "to": "target"}, _db("spdDown", 2, 50)]),
		_p("compliance", "Compliance", "Increase Firewall by 20.", {"stats": {"fw": 20}}),
	])
	_w("kellen", "Enforcer Kellen", "rare", "armour", "teratek", "neutral", [
		_a("opportunist", "Opportunist", "Attack all enemies. Place ARMOUR DOWN for 1 turn.", 0.6, "all_enemies", 0, [_db("armDown", 1)]),
		_a("bodyguard", "Bodyguard Protocol", "Place 50% ARMOUR UP and 15% BOLSTER on all allies for 2 turns.", 0.0, "all_allies", 4, [_bf("armUp", 2, "all_allies", 1), _bf("bolster", 2, "all_allies", 0)]),
		_p("capitalist_k", "Capitalist", "Gain Turn Meter equal to double any Turn Meter removed from allies.", {"special": "capitalist"}),
		_l("security", "Corporate Security", "Teratek allies gain 20% Armour.", {"armP": 20}, "teratek"),
	])
	_w("ried", "Enforcer Ried", "rare", "firepower", "teratek", "renegade", [
		_a("schemer", "Schemer", "Attack all enemies. Place FIREPOWER DOWN for 1 turn.", 0.6, "all_enemies", 0, [_db("fpDown", 1)]),
		_a("hostile_bid", "Hostile Bid", "Attack 1 enemy. Deals 50% more damage if the target is debuffed.", 2.0, "enemy", 3, [], {"vs": {"debuffed": true, "mult": 1.5}}),
		_p("capitalist_r", "Capitalist", "Gain Turn Meter equal to double any Turn Meter removed from allies.", {"special": "capitalist"}),
		_l("shareholders", "Shareholders", "Teratek allies gain 15% Firepower.", {"fpP": 15}, "teratek"),
	])
	_w("lysa_vohn", "Dr. Lysa Vohn", "epic", "hacker", "teratek", "neutral", [
		_a("neural_spike", "Neural Spike", "Attack 1 enemy. 40% chance to place STUPEFY for 1 turn.", 1.0, "enemy", 0, [_db("stupefy", 1, 40)]),
		_a("firmware_lock", "Firmware Lock", "Increase all enemy cooldowns by 1 and 60% chance to place 40 HACKING DOWN for 2 turns.", 0.0, "all_enemies", 4, [_db("cdIncrease", 1), _db("hackDown", 2, 60)]),
		_a("system_purge", "System Purge", "Remove 2 buffs from all enemies, then attack all enemies.", 1.0, "all_enemies", 5, [{"t": "strip", "n": 2, "to": "target", "pre": true}]),
		_p("overclocked", "Overclocked", "Increase Hacking by 20.", {"stats": {"hack": 20}}),
		_l("network", "Secure Network", "All allies gain 20 Firewall.", {"fw": 20}),
	])
	_w("issac_vaun", "Issac Vaun", "legendary", "hacker", "teratek", "neutral", [
		_a("bribe", "Bribe", "Attack 1 enemy. 50% chance to place STUPEFY for 1 turn.", 1.1, "enemy", 0, [_db("stupefy", 1, 50)]),
		_a("hostile_takeover", "Hostile Takeover", "Place FIREWALL UP on all allies and FIREWALL DOWN on all enemies for 2 turns. Place BLOCK BUFFS on all enemies for 1 turn.", 0.0, "all_enemies", 4, [_bf("fwUp", 2, "all_allies", 1), _db("fwDown", 2, 100, 1), _db("blockBuffs", 1)]),
		_a("power_play", "Power Play", "Attack all enemies 2 times. 25% chance to place STUN for 1 turn.", 0.55, "all_enemies", 4, [_db("stun", 1, 25)], {"hits": 2}),
		_p("cash_injection", "Cash Injection", "Heals all allies by 10% of their Max HP each turn.", {"hooks": [{"on": "turn_start", "fx": [{"t": "heal", "pct": 10, "of": "target", "to": "all_allies"}]}]}),
		_l("board", "Board of Directors", "Teratek allies gain 20% Health.", {"hpP": 20}, "teratek"),
		_r("golden_parachute", "Golden Parachute", "On entering, place an OVERSHIELD of 15% Max HP on all allies for 2 turns.", [{"t": "shield", "pct": 15, "of": "target", "to": "all_allies", "turns": 2}]),
	], {"lore": "Chief financial officer of TeraTek Cybernetics. Excels at opportunist plays."})

	# ============================================================ QUANTUM VIKINGS
	_w("ragnar_volt", "Ragnar Volt", "common", "firepower", "vikings", "renegade", [
		_a("axe_zap", "Axe Zap", "Attack 1 enemy. 20% chance to place SHOCK for 1 turn.", 1.0, "enemy", 0, [_db("shock", 1, 20)]),
		_a("berserk_dose", "Berserk Dose", "Place a 50% FIREPOWER UP on self for 2 turns, then attack 1 enemy.", 1.4, "enemy", 3, [_bf("fpUp", 2, "self", 1, {"pre": true})]),
	])
	_w("freya_static", "Freya Static", "uncommon", "modder", "vikings", "neutral", [
		_a("spark_slap", "Spark Slap", "Attack 1 enemy.", 1.0),
		_a("stimm_share", "Stimm Share", "Heal all allies by 10% of this Warlord's Max HP and place 15% SPEED UP for 2 turns.", 0.0, "all_allies", 3, [{"t": "heal", "pct": 10, "of": "caster", "to": "all_allies"}, _bf("spdUp", 2, "all_allies", 0)]),
		_p("adrenal", "Adrenal Gland", "Increase Speed by 8%.", {"stats": {"spdP": 8}}),
	])
	_w("raider_bjorn", "Raider Bjorn", "rare", "armour", "vikings", "neutral", [
		_a("hammer_time_b", "Hammer Time", "Attack 1 enemy. If the target was SHOCKED, heal the weakest ally by 10% of their Max HP.", 1.1, "enemy", 0, [{"t": "heal", "pct": 10, "of": "target", "to": "lowest_ally", "if": "has:shock"}]),
		_a("shield_wall_b", "Shield Wall", "Place a 50% ARMOUR UP on all allies for 2 turns.", 0.0, "all_allies", 4, [_bf("armUp", 2, "all_allies", 1)]),
		_p("fours_chosen_b", "Four's Chosen", "Immune to SHOCK.", {"immune": ["shock"]}),
		_l("warband", "Warband", "Quantum Vikings allies gain 20% Health.", {"hpP": 20}, "vikings"),
	])
	_w("sigrun", "Sigrun Thunderwife", "epic", "hacker", "vikings", "paragon", [
		_a("ion_spear", "Ion Spear", "Attack 1 enemy. 40% chance to place a 50% SHOCK for 1 turn.", 1.0, "enemy", 0, [_db("shock", 1, 40, 1)]),
		_a("storm_call", "Storm Call", "Attack all enemies, remove 15% Turn Meter and 50% chance to place SPEED DOWN for 2 turns.", 0.8, "all_enemies", 4, [{"t": "tm", "v": -15, "to": "target"}, _db("spdDown", 2, 50)]),
		_a("overload", "Overload", "Attack all enemies. Deals double damage to SHOCKED enemies.", 1.2, "all_enemies", 5, [], {"vs": {"debuff": "shock", "mult": 2.0}}),
		_p("conductive", "Conductive", "Deal 15% more damage to SHOCKED enemies.", {"special": "conductive"}),
		_l("thunder_bond", "Thunder Bond", "All allies gain 8% Speed.", {"spdP": 8}),
	])
	_w("hammer_of_four", "The Hammer of Four", "legendary", "armour", "vikings", "renegade", [
		_a("thunder_god", "Thunder God", "Attack all enemies. 50% chance to place a 50% SHOCK for 1 turn.", 0.8, "all_enemies", 0, [_db("shock", 1, 50, 1)]),
		_a("to_valhalla", "To Valhalla", "Attack 1 enemy, then call all allies to attack that target with their basic attack.", 1.3, "enemy", 3, [{"t": "call", "n": 4, "syn": false}]),
		_p("ragnarok", "Ragnarok", "At the start of this Warlord's turn, revive 1 ally at 30% HP then use Thunder God. 3 turn cooldown.", {"special": "ragnarok"}),
		_l("hall_of_four", "Hall of Four", "Quantum Vikings allies gain 20% Armour.", {"armP": 20}, "vikings"),
		_r("fours_lightning", "Four's Lightning", "On entering, 50% chance to place SHOCK on all enemies for 1 turn.", [_db("shock", 1, 50, 0, "all_enemies")]),
	], {"lore": "Homage to the Viking god 'Four'. Roams with his raider bodyguards."})

	# ============================================================ NEO SHOGUNATE
	_w("kage9", "Kage Unit 9", "common", "firepower", "shogunate", "paragon", [
		_a("shuriken", "Shuriken Burst", "Attack 1 enemy 2 times.", 0.55, "enemy", 0, [], {"hits": 2}),
		_a("smoke_step", "Smoke Step", "Attack 1 enemy, then place 15% SPEED UP on self for 2 turns.", 1.5, "enemy", 3, [_bf("spdUp", 2, "self", 0)]),
	])
	_w("ronin_haze", "Ronin Haze", "uncommon", "firepower", "shogunate", "neutral", [
		_a("mono_edge", "Mono Edge", "Attack 1 enemy. 30% chance to place BLEED for 2 turns.", 1.0, "enemy", 0, [_db("bleed", 2, 30)]),
		_a("iaido", "Iaido", "Attack 1 enemy. If this kills the target, take an extra turn.", 2.0, "enemy", 3, [{"t": "extra_turn", "if": "kill"}]),
		_p("ronin_code", "Ronin Code", "Increase Critical Damage by 15%.", {"stats": {"cd": 15}}),
	])
	_w("oni_matsuda", "Oni Matsuda", "rare", "armour", "shogunate", "paragon", [
		_a("tetsubo", "Tetsubo", "Attack 1 enemy. 15% chance to place STUN for 1 turn.", 1.1, "enemy", 0, [_db("stun", 1, 15)]),
		_a("iron_vow", "Iron Vow", "Place a 50% ARMOUR UP and 50% COUNTER on self for 2 turns.", 0.0, "self", 4, [_bf("armUp", 2, "self", 1), _bf("counter", 2, "self", 0)]),
		_p("bushido", "Bushido", "Gain 20% Turn Meter whenever an ally drops below 25% HP.", {"hooks": [{"on": "ally_low", "fx": [{"t": "tm", "v": 20, "to": "self"}]}]}),
		_l("daimyo", "Daimyo", "Neo Shogunate allies gain 15% Critical Chance.", {"cc": 15}, "shogunate"),
	])
	_w("yumeko", "Lady Yumeko", "epic", "hacker", "shogunate", "paragon", [
		_a("ghost_code", "Ghost Code", "Attack 1 enemy. 50% chance to place MARK TARGET for 2 turns.", 1.0, "enemy", 0, [_db("mark", 2, 50)]),
		_a("ninja_protocol", "Ninja Protocol", "Place BLOCK DEBUFFS for 1 turn and 15% SPEED UP for 2 turns on all allies.", 0.0, "all_allies", 4, [_bf("blockDebuffs", 1, "all_allies"), _bf("spdUp", 2, "all_allies", 0)]),
		_a("death_blossom", "Death Blossom", "Attack all enemies 3 times. Each hit has a 30% chance to place BLEED for 2 turns.", 0.45, "all_enemies", 5, [_db("bleed", 2, 30)], {"hits": 3}),
		_p("silent_steps", "Silent Steps", "Start each battle with 25% Turn Meter.", {"hooks": [{"on": "battle_start", "fx": [{"t": "tm", "v": 25, "to": "self"}]}]}),
		_l("shadow_court", "Shadow Court", "All allies gain 12% Critical Chance.", {"cc": 12}),
	])
	_w("raiden_x", "Shogun Raiden-X", "legendary", "firepower", "shogunate", "paragon", [
		_a("plasma_katana", "Plasma Katana", "Attack 1 enemy. 40% chance to place a 25% BREAK for 2 turns.", 1.1, "enemy", 0, [_db("break", 2, 40, 1)]),
		_a("thousand_cuts", "Thousand Cuts", "Attack random enemies 5 times.", 0.5, "all_enemies", 3, [], {"hits": 5, "random_targets": true}),
		_a("final_edict", "Final Edict", "Attack 1 enemy, ignoring 50% Armour. Deals double damage to enemies at 50% HP or less.", 3.0, "enemy", 5, [], {"ignore_arm": 50, "below": {"pct": 50, "mult": 2.0}}),
		_p("blade_discipline", "Blade Discipline", "Increase Critical Damage by 20%.", {"stats": {"cd": 20}}),
		_l("shogun_decree", "Shogun's Decree", "Neo Shogunate allies gain 20% Firepower.", {"fpP": 20}, "shogunate"),
		_r("vanguard", "Vanguard", "On entering, all allies gain 25% Turn Meter.", [{"t": "tm", "v": 25, "to": "all_allies"}]),
	], {"lore": "Rules the neon rooftops with a plasma blade and a thousand silent soldiers."})

	# ============================================================ GENE SPLICED
	_w("ratchet", "Ratchet", "common", "hacker", "spliced", "neutral", [
		_a("gnaw", "Gnaw", "Attack 1 enemy. 30% chance to place POISON for 2 turns.", 1.0, "enemy", 0, [_db("poison", 2, 30)]),
		_a("plague_squeak", "Plague Squeak", "Attack all enemies. 30% chance to place POISON for 2 turns.", 0.7, "all_enemies", 3, [_db("poison", 2, 30)]),
	])
	_w("mama_hogg", "Mama Hogg", "uncommon", "armour", "spliced", "neutral", [
		_a("tusk_charge", "Tusk Charge", "Attack 1 enemy and remove 10% Turn Meter.", 1.0, "enemy", 0, [{"t": "tm", "v": -10, "to": "target"}]),
		_a("wallow", "Wallow", "Heal self by 20% Max HP and place a 25% ARMOUR UP on self for 2 turns.", 0.0, "self", 3, [{"t": "heal", "pct": 20, "of": "caster", "to": "self"}, _bf("armUp", 2, "self", 0)]),
		_p("thick_hide_h", "Thick Hide", "Increase Health by 10%.", {"stats": {"hpP": 10}}),
	])
	_w("talon_kree", "Talon Kree", "rare", "firepower", "spliced", "renegade", [
		_a("dive", "Dive", "Attack 1 enemy. 25% more damage on a critical hit.", 1.1, "enemy", 0, [], {"crit_bonus": 25}),
		_a("rend", "Rend", "Attack 1 enemy 2 times. Each hit places a 5% BLEED for 2 turns.", 0.9, "enemy", 3, [_db("bleed", 2, 100, 1)], {"hits": 2}),
		_p("predator", "Predator", "Deal 15% more damage to enemies at 50% HP or less.", {"special": "predator"}),
		_l("pack", "The Pack", "Gene Spliced allies gain 10% Speed.", {"spdP": 10}, "spliced"),
	])
	_w("dr_mandrill", "Doctor Mandrill", "epic", "modder", "spliced", "paragon", [
		_a("serum_dart", "Serum Dart", "Attack 1 enemy, then heal the weakest ally by 15% of this Warlord's Max HP.", 1.0, "enemy", 0, [{"t": "heal", "pct": 15, "of": "caster", "to": "lowest_ally"}]),
		_a("gene_boost", "Gene Boost", "Place 50% FIREPOWER UP and 15% CRIT CHANCE UP on all allies for 2 turns.", 0.0, "all_allies", 3, [_bf("fpUp", 2, "all_allies", 1), _bf("ccUp", 2, "all_allies", 0)]),
		_a("mutation", "Mutation", "Revive a fallen ally at 30% HP. If none, heal all allies by 20% Max HP.", 0.0, "all_allies", 5, [{"t": "revive", "pct": 30}]),
		_p("adaptive_genome", "Adaptive Genome", "Immune to POISON.", {"immune": ["poison"]}),
		_l("lab", "The Lab", "All allies gain 15% Health.", {"hpP": 15}),
	])
	_w("alpha_ramsgate", "Alpha Ramsgate", "legendary", "armour", "spliced", "neutral", [
		_a("ram_horns", "Ram Horns", "Attack 1 enemy. 20% chance to place STUN for 1 turn.", 1.1, "enemy", 0, [_db("stun", 1, 20)]),
		_a("herd_call", "Herd Call", "Attack 1 enemy and call 2 Gene Spliced allies to attack. Place 25% ARMOUR UP on all allies for 2 turns.", 1.0, "enemy", 4, [{"t": "call", "n": 2, "syn": true}, _bf("armUp", 2, "all_allies", 0)]),
		_a("stampede", "Stampede", "Attack all enemies and remove 20% Turn Meter.", 1.4, "all_enemies", 5, [{"t": "tm", "v": -20, "to": "target"}]),
		_p("ram_hide", "Ram Hide", "Increase Armour by 20%.", {"stats": {"armP": 20}}),
		_l("herd", "The Herd", "Gene Spliced allies gain 20% Armour.", {"armP": 20}, "spliced"),
		_r("headbutt", "Headbutt", "On entering, place 50% ARMOUR UP on all allies for 2 turns.", [_bf("armUp", 2, "all_allies", 1)]),
	], {"lore": "The ramshead alpha of the spliced. Gentle with the herd, merciless with the rest."})

	# ============================================================ FRONTIER TRADERS
	_w("quill", "Deckhand Quill", "common", "firepower", "traders", "renegade", [
		_a("blaster", "Blaster", "Attack 1 enemy.", 1.0),
		_a("plunder", "Plunder", "Remove 1 buff from the target, then attack it.", 1.6, "enemy", 3, [{"t": "strip", "n": 1, "to": "target", "pre": true}]),
	])
	_w("pix", "Navigator Pix", "uncommon", "modder", "traders", "neutral", [
		_a("pistol", "Pistol Whip", "Attack 1 enemy.", 1.0),
		_a("hyperlane", "Hyperlane", "Grant all allies 15% Turn Meter.", 0.0, "all_allies", 3, [{"t": "tm", "v": 15, "to": "all_allies"}]),
		_p("star_charts", "Star Charts", "Increase Speed by 6%.", {"stats": {"spdP": 6}}),
	])
	_w("bosun_krug", "Bosun Krug", "rare", "armour", "traders", "renegade", [
		_a("anchor", "Anchor Swing", "Attack 1 enemy. 30% chance to place SPEED DOWN for 2 turns.", 1.1, "enemy", 0, [_db("spdDown", 2, 30)]),
		_a("batten", "Batten Down", "Place 15% BOLSTER on all allies for 2 turns and an OVERSHIELD of 10% of this Warlord's Max HP.", 0.0, "all_allies", 4, [_bf("bolster", 2, "all_allies", 0), {"t": "shield", "pct": 10, "of": "caster", "to": "all_allies", "turns": 2}]),
		_p("salty", "Salty", "Increase Firewall by 30.", {"stats": {"fw": 30}}),
		_l("crew", "The Crew", "Frontier Traders allies gain 20% Health.", {"hpP": 20}, "traders"),
	])
	_w("venn", "Quartermaster Venn", "epic", "hacker", "traders", "neutral", [
		_a("ledger_leech", "Ledger Leech", "Attack 1 enemy and remove 1 buff.", 1.0, "enemy", 0, [{"t": "strip", "n": 1, "to": "target"}]),
		_a("black_flag", "Black Flag", "Attack all enemies. 50% chance to place FIREPOWER DOWN and 50% chance to place HACKING DOWN for 2 turns.", 0.8, "all_enemies", 4, [_db("fpDown", 2, 50), _db("hackDown", 2, 50)]),
		_a("ransom", "Ransom", "Attack 1 enemy. If the target has 2 or more debuffs, place STUN for 1 turn.", 2.5, "enemy", 5, [_db("stun", 1, 100, 0, "target", {"if": "debuffs>=2", "pre": true})]),
		_p("smuggler", "Smuggler", "Start each battle with BLOCK DEBUFFS for 1 turn.", {"hooks": [{"on": "battle_start", "fx": [_bf("blockDebuffs", 1, "self")]}]}),
		_l("contraband", "Contraband", "All allies gain 20 Hacking.", {"hack": 20}),
	])
	_w("redd_skullfire", "Captain Redd Skullfire", "legendary", "firepower", "traders", "renegade", [
		_a("plasma_cutlass", "Plasma Cutlass", "Attack 1 enemy 2 times. 30% chance to place BLEED for 2 turns.", 0.6, "enemy", 0, [_db("bleed", 2, 30)], {"hits": 2}),
		_a("broadside", "Broadside", "Attack all enemies. 40% chance to place a 50% ARMOUR DOWN for 2 turns.", 1.1, "all_enemies", 4, [_db("armDown", 2, 40, 1)]),
		_a("call_crew", "Call the Crew", "Attack 1 enemy and call 2 Frontier Traders allies to attack. Place 50% FIREPOWER UP on all allies for 2 turns.", 1.2, "enemy", 5, [{"t": "call", "n": 2, "syn": true}, _bf("fpUp", 2, "all_allies", 1)]),
		_p("pirates_luck", "Pirate's Luck", "Increase Critical Chance by 15% and Critical Damage by 20%.", {"stats": {"cc": 15, "cd": 20}}),
		_l("jolly_roger", "Jolly Roger", "Frontier Traders allies gain 20% Firepower.", {"fpP": 20}, "traders"),
		_r("boarding_party", "Boarding Party", "On entering, remove 20% Turn Meter from all enemies.", [{"t": "tm", "v": -20, "to": "all_enemies"}]),
	], {"lore": "Space pirate, corporate raider, and the loudest voice on any frequency."})

	_build_enemies()

func _build_enemies() -> void:
	# --- Cardinal Trolls hideout minions
	_w("bishop_brick", "Acolyte Bishop Brick", "rare", "firepower", "trolls", "renegade", [
		_a("celestial_strike", "Celestial Strike", "Attack 1 enemy. Ignores 50% Armour on ENRAGED targets, 100% if also BROKEN.", 1.2, "enemy", 0, [], {"special": "celestial_enraged"}),
		_p("mass", "Mass", "Every 3 turns place a 50% ARMOUR UP on Deacon Chainz for 2 turns.", {"special": "mass"}),
	], {"enemy_only": true})
	_w("bishop_clyde", "Acolyte Bishop Clyde", "rare", "firepower", "trolls", "renegade", [
		_a("celestial_smite", "Celestial Smite", "Attack 1 enemy. Ignores 50% Armour on BROKEN targets, 100% if also ENRAGED.", 1.2, "enemy", 0, [], {"special": "celestial_break"}),
		_p("prayer", "Prayer", "Every 3 turns place a 10% CONTINUOUS HEAL on Deacon Chainz for 2 turns.", {"special": "prayer"}),
	], {"enemy_only": true})
	# --- Bastion side minion
	_w("teratek_drone", "TeraTek Security Drone", "uncommon", "armour", "teratek", "neutral", [
		_a("taser_burst", "Taser Burst", "Attack 1 enemy. 25% chance to place SPEED DOWN for 2 turns.", 1.0, "enemy", 0, [_db("spdDown", 2, 25)]),
		_p("overwatch", "Overwatch", "When hit, 20% chance to gain a 25% COUNTER for 1 turn.", {"hooks": [{"on": "hit_taken", "chance": 20, "fx": [_bf("counter", 1, "self", 0)]}]}),
	], {"enemy_only": true})
	# --- Vikings raiders
	_w("raider", "Raider", "uncommon", "armour", "vikings", "renegade", [
		_a("hammer_time", "Hammer Time", "Attack 1 enemy. If the target was SHOCKED heal The Hammer of Four by 10%.", 1.0, "enemy", 0, [], {"special": "hammer_time"}),
		_p("shield_wall", "Shield Wall", "Provides 20% Armour to The Hammer of Four.", {"special": "shield_wall"}),
		_p("fours_chosen", "Four's Chosen", "Immune to SHOCK.", {"immune": ["shock"]}),
	], {"enemy_only": true})
	# --- generic gang members for waves
	for s in Data.SYNDICATES:
		_w("thug_" + s, Data.SYNDICATES[s].name + " Thug", "common", "firepower", s, "renegade", [
			_a("thug_hit", "Street Brawl", "Attack 1 enemy.", 1.0),
			_a("thug_rush", "Gang Rush", "Attack 1 enemy 2 times.", 0.7, "enemy", 3, [], {"hits": 2}),
		], {"enemy_only": true})
		_w("medic_" + s, Data.SYNDICATES[s].name + " Patcher", "common", "modder", s, "neutral", [
			_a("med_hit", "Jab", "Attack 1 enemy.", 0.9),
			_a("med_patch", "Patch Up", "Heal all allies by 12% of this Warlord's Max HP.", 0.0, "all_allies", 3, [{"t": "heal", "pct": 12, "of": "caster", "to": "all_allies"}]),
		], {"enemy_only": true})
		_w("netrunner_" + s, Data.SYNDICATES[s].name + " Netrunner", "common", "hacker", s, "neutral", [
			_a("net_hit", "Packet Spike", "Attack 1 enemy. 30% chance to place SPEED DOWN for 1 turn.", 1.0, "enemy", 0, [_db("spdDown", 1, 30)]),
			_a("net_virus", "Virus", "Attack all enemies. 30% chance to place ARMOUR DOWN for 2 turns.", 0.6, "all_enemies", 3, [_db("armDown", 2, 30)]),
		], {"enemy_only": true})
		_w("bruiser_" + s, Data.SYNDICATES[s].name + " Bruiser", "common", "armour", s, "neutral", [
			_a("bru_hit", "Haymaker", "Attack 1 enemy. 20% chance to place a 15% BREAK for 1 turn.", 1.0, "enemy", 0, [_db("break", 1, 20)]),
			_a("bru_guard", "Brace", "Place a 25% ARMOUR UP on all allies for 2 turns.", 0.0, "all_allies", 3, [_bf("armUp", 2, "all_allies", 0)]),
		], {"enemy_only": true})

	# --- Synapse Centre: memory fragments
	_w("mnemosyne", "MNEMOSYNE Core", "legendary", "hacker", "teratek", "neutral", [
		_a("memory_leak", "Memory Leak", "Attack 1 enemy. 50% chance to place STUPEFY for 1 turn.", 1.1, "enemy", 0, [_db("stupefy", 1, 50)]),
		_a("cognitive_wipe", "Cognitive Wipe", "Attack all enemies, remove all buffs and increase cooldowns by 1.", 0.9, "all_enemies", 3, [{"t": "strip", "n": 9, "to": "target", "pre": true}, _db("cdIncrease", 1)]),
		_p("recompile", "Recompile", "While any Synapse Drone lives, takes 50% less damage.", {"special": "drone_shield"}),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
	_w("synapse_drone", "Synapse Drone", "rare", "hacker", "teratek", "neutral", [
		_a("data_pulse", "Data Pulse", "Attack 1 enemy. 40% chance to place HACKING DOWN for 2 turns.", 1.0, "enemy", 0, [_db("hackDown", 2, 40)]),
		_p("backup", "Backup", "When killed, restores MNEMOSYNE by 10% Max HP.", {"special": "backup"}),
	], {"enemy_only": true})
	# --- Chopshop: implants
	_w("doc_sawbones", "Doc Sawbones", "legendary", "modder", "vultures", "renegade", [
		_a("bone_saw", "Bone Saw", "Attack 1 enemy. Places a 5% BLEED for 2 turns.", 1.1, "enemy", 0, [_db("bleed", 2, 100, 1)]),
		_a("harvest", "Harvest", "Attack 1 enemy. Heals self by 100% of the damage dealt. Places HEAL BLOCK for 2 turns.", 1.4, "enemy", 3, [_db("healBlock", 2)], {"lifesteal": 100}),
		_a("augment_crew", "Augment Crew", "Place 50% FIREPOWER UP and 50% ARMOUR UP on all allies for 2 turns.", 0.0, "all_allies", 4, [_bf("fpUp", 2, "all_allies", 1), _bf("armUp", 2, "all_allies", 1)]),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
	# --- Heist: credits
	_w("warden9", "WARDEN-9 Vault Mech", "legendary", "armour", "teratek", "neutral", [
		_a("lockdown", "Lockdown", "Attack 1 enemy and remove 30% Turn Meter.", 1.1, "enemy", 0, [{"t": "tm", "v": -30, "to": "target"}]),
		_a("alarm", "Silent Alarm", "Attack all enemies. Place SPEED DOWN for 2 turns.", 0.9, "all_enemies", 3, [_db("spdDown", 2, 100, 1)]),
		_p("vault_plating", "Vault Plating", "Gains 25% BOLSTER while above 50% HP.", {"special": "vault_plating"}),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
	# --- Deeds hideouts
	_w("saint_lumen", "Saint Lumen", "legendary", "modder", "shogunate", "paragon", [
		_a("halo_strike", "Halo Strike", "Attack 1 enemy and heal all allies by 5% of their Max HP.", 1.0, "enemy", 0, [{"t": "heal", "pct": 5, "of": "target", "to": "all_allies"}]),
		_a("sanctify", "Sanctify", "Remove all debuffs from allies and place BLOCK DEBUFFS for 1 turn.", 0.0, "all_allies", 4, [{"t": "cleanse", "n": 9, "to": "all_allies"}, _bf("blockDebuffs", 1, "all_allies")]),
		_a("judgement", "Judgement", "Attack all enemies. Deals 50% more damage to enemies with buffs.", 1.2, "all_enemies", 4, [], {"vs": {"buffed": true, "mult": 1.5}}),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
	_w("broker_grey", "The Grey Broker", "legendary", "hacker", "traders", "neutral", [
		_a("hedge", "Hedge", "Attack 1 enemy and steal 15% Turn Meter.", 1.1, "enemy", 0, [{"t": "tm", "v": -15, "to": "target"}, {"t": "tm", "v": 15, "to": "self"}]),
		_a("market_crash", "Market Crash", "Attack all enemies. Place FIREPOWER DOWN and ARMOUR DOWN for 2 turns.", 0.9, "all_enemies", 4, [_db("fpDown", 2, 100, 1), _db("armDown", 2, 100, 0)]),
		_p("neutral_ground", "Neutral Ground", "Takes 30% less damage from buffed enemies.", {"special": "neutral_ground"}),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
	_w("red_mara", "Red Mara", "legendary", "firepower", "vultures", "renegade", [
		_a("hellfire", "Hellfire", "Attack 1 enemy 2 times. Places POISON for 2 turns.", 0.7, "enemy", 0, [_db("poison", 2, 100, 1)], {"hits": 2}),
		_a("anarchy", "Anarchy", "Attack all enemies. 50% chance to place STUN for 1 turn.", 1.0, "all_enemies", 4, [_db("stun", 1, 50)]),
		_p("rampage", "Rampage", "Gain 10% Firepower every turn (max 100%).", {"special": "rampage"}),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
	_w("archivist", "The Archivist", "legendary", "armour", "spliced", "neutral", [
		_a("tome_slam", "Tome Slam", "Attack 1 enemy. Places a 25% BREAK for 2 turns.", 1.1, "enemy", 0, [_db("break", 2, 100, 1)]),
		_a("redact", "Redact", "Attack all enemies. Removes 2 buffs and 20% Turn Meter.", 0.9, "all_enemies", 4, [{"t": "strip", "n": 2, "to": "target", "pre": true}, {"t": "tm", "v": -20, "to": "target"}]),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
	# --- Bastion: Assault on Teratek Cybernetics
	_w("atrium_sentinel", "Atrium Sentinel", "legendary", "armour", "teratek", "neutral", [
		_a("sweep", "Security Sweep", "Attack all enemies. Places ARMOUR DOWN for 2 turns.", 0.8, "all_enemies", 0, [_db("armDown", 2, 100, 0)]),
		_a("overclock_shield", "Overclock Shield", "Places a 25% BOLSTER on self for 2 turns and attacks 1 enemy.", 1.5, "enemy", 3, [_bf("bolster", 2, "self", 1, {"pre": true})]),
		_p("security_grid", "Security Grid", "Increase Armour by 20%.", {"stats": {"armP": 20}}),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
	_w("foundry_titan", "Foundry Titan", "legendary", "firepower", "teratek", "neutral", [
		_a("molten_fist", "Molten Fist", "Attack 1 enemy. Places a 5% POISON (burn) for 3 turns.", 1.2, "enemy", 0, [_db("poison", 3, 100, 1)]),
		_a("slag_wave", "Slag Wave", "Attack all enemies 2 times.", 0.6, "all_enemies", 3, [], {"hits": 2}),
		_p("forge_heart", "Forge Heart", "Gain 10% Firepower every turn (max 100%).", {"special": "rampage"}),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
	_w("hydra_ceo", "HYDRA, Teratek Board AI", "legendary", "hacker", "teratek", "neutral", [
		_a("hydra_bite", "Hydra Bite", "Attack 1 enemy 3 times. Each hit has a 40% chance to place a random debuff.", 0.5, "enemy", 0, [], {"hits": 3, "special": "random_debuff"}),
		_a("hostile_merger", "Hostile Merger", "Attack all enemies. Places BLOCK BUFFS and HEAL BLOCK for 2 turns.", 1.0, "all_enemies", 4, [_db("blockBuffs", 2), _db("healBlock", 2)]),
		_p("regrow", "Regrow", "At the start of its turn, 33% chance to heal 10% Max HP and remove all debuffs.", {"hooks": [{"on": "turn_start", "chance": 33, "fx": [{"t": "heal", "pct": 10, "of": "caster", "to": "self"}, {"t": "cleanse", "n": 9, "to": "self"}]}]}),
		_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, Turn Meter manipulation, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS_TM}),
	], {"enemy_only": true, "boss": true})
