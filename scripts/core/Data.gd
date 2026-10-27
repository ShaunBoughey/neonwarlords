extends Node
## Static design data from the GDD. Large tables are generated into res://data/gdd.json.

var GDD: Dictionary = {}

func _ready() -> void:
	var f := FileAccess.open("res://data/gdd.json", FileAccess.READ)
	GDD = JSON.parse_string(f.get_as_text())
	_index_neuronet()

# ---------------------------------------------------------------- general
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary"]
const RARITY_COLOR := {"common": Color("#9aa4b1"), "uncommon": Color("#38e07b"), "rare": Color("#2fa8ff"), "epic": Color("#b45cff"), "legendary": Color("#ffb627")}
const CLASSES := ["armour", "firepower", "modder", "hacker"]
const CLASS_INFO := {
	"armour": {"name": "Armour", "role": "Tank", "icon": "⛨", "desc": "Damage scales with Armour. Focuses on taking punishment."},
	"firepower": {"name": "Firepower", "role": "DPS", "icon": "✸", "desc": "High ability multipliers, damage scales with Firepower."},
	"modder": {"name": "Modder", "role": "Buffer", "icon": "✚", "desc": "Damage scales with Health. Supports, speeds up and strengthens the gang."},
	"hacker": {"name": "Hacker", "role": "Debuffer", "icon": "⌬", "desc": "Damage scales with Hacking. Hinders the enemy with debuffs."},
}
const ALIGNMENTS := ["paragon", "neutral", "renegade"]
const ALIGN_COLOR := {"paragon": Color("#4fd1ff"), "neutral": Color("#c9c9d6"), "renegade": Color("#ff4f7b"), "generic": Color("#e8d36a")}
const SYNDICATES := {
	"trolls": {"name": "Cardinal Trolls", "desc": "A rough and ready slum syndicate who is in it just for fun. Manic and ferocious themes.", "sign": "Papal Tiara with a Troll Face", "icon": "♛", "color": Color("#ff5a36")},
	"vultures": {"name": "Vultures", "desc": "Lower slum syndicate who preys on the augmented to steal the augments by force. Dark and gruesome themes.", "sign": "Cybernetic Talon", "icon": "▼", "color": Color("#9b5cff")},
	"teratek": {"name": "Teratek Cybernetics", "desc": "A corporation focused on the manufacturing and selling of augments. Suits and cyborgs theme.", "sign": "Cybernetic Illuminati Eye", "icon": "◬", "color": Color("#29e3ff")},
	"vikings": {"name": "Quantum Vikings", "desc": "A stimm junkie syndicate based on their neo misconception of vikings. Vikings and muscles theme.", "sign": "Helmet with Lightning Beard", "icon": "ᛉ", "color": Color("#ffd42a")},
	"shogunate": {"name": "Neo Shogunate", "desc": "Cyber ninjas.", "sign": "Samurai Helmet", "icon": "⛩", "color": Color("#ff2e88")},
	"spliced": {"name": "Gene Spliced", "desc": "Anthropomorphic hybrids.", "sign": "Ramshead", "icon": "♈", "color": Color("#47ff8a")},
	"traders": {"name": "Frontier Traders", "desc": "Corporation of space pirates.", "sign": "Cyborg Skull and Crossbones", "icon": "☠", "color": Color("#ff9d2e")},
}
const STATS := {
	"hp": {"name": "Health", "short": "HP", "pct": false}, "hpP": {"name": "Health %", "short": "HP%", "pct": true},
	"arm": {"name": "Armour", "short": "ARM", "pct": false}, "armP": {"name": "Armour %", "short": "ARM%", "pct": true},
	"fp": {"name": "Firepower", "short": "FP", "pct": false}, "fpP": {"name": "Firepower %", "short": "FP%", "pct": true},
	"spd": {"name": "Speed", "short": "SPD", "pct": false},
	"cc": {"name": "Crit Chance", "short": "C.RATE", "pct": true}, "cd": {"name": "Crit Damage", "short": "C.DMG", "pct": true},
	"hack": {"name": "Hacking", "short": "HACK", "pct": false}, "fw": {"name": "Firewall", "short": "FW", "pct": false},
}
const GEAR_SLOTS := ["weapon", "helmet", "chest", "gloves", "legs", "boots"]
const IMPLANT_SLOTS := ["limbs", "organs", "skeleton"]
const ALL_SLOTS := ["weapon", "helmet", "chest", "gloves", "legs", "boots", "limbs", "organs", "skeleton"]
const SLOT_ICON := {"weapon": "⚔", "helmet": "⛑", "chest": "▣", "gloves": "✋", "legs": "∏", "boots": "▙", "limbs": "⚙", "organs": "♥", "skeleton": "☠"}
const DIFFS := ["Street Punk", "Mob Boss", "Warlord"]
const ENERGY_CAP := 160
const ENERGY_REGEN_SECS := 180.0
const MAX_RANK := 6
const TEAM_SIZE := 4

func max_level(rank: int) -> int:
	return rank * 10

## XP to go from level L to L+1 at a given rank (GDD: 500 base, +10% cumulative per level and per rank).
func xp_to_next(level: int, rank: int) -> int:
	return int(round(500.0 * pow(1.1, level + rank - 2)))

func rarity_idx(r: String) -> int:
	return RARITIES.find(r)

# ---------------------------------------------------------------- warlord progression
const RANK_START := {"common": 1, "uncommon": 2, "rare": 3, "epic": 4, "legendary": 5}
# Reputation: per rep level [alignment deeds, generic deeds] as {tier: count}
const REP_LOW := [[{"minor": 2}, {"minor": 3}], [{"minor": 3}, {"minor": 3}], [{"minor": 4}, {"minor": 4}], [{"minor": 5}, {"minor": 4}], [{"major": 2}, {"major": 2}], [{"major": 3}, {"major": 3}]]
const REP_EPIC := [[{"minor": 5}, {"minor": 5}], [{"minor": 7}, {"minor": 5}], [{"major": 3}, {"major": 3}], [{"major": 3}, {"major": 4}], [{"grand": 1}, {"grand": 2}], [{"grand": 3}, {"grand": 2}]]
const REP_LEG := [[{"major": 1}, {"major": 1}], [{"major": 2}, {"major": 2}], [{"major": 3}, {"major": 2}], [{"grand": 2}, {"grand": 2}], [{"grand": 4}, {"grand": 3}], [{"grand": 6}, {"grand": 4}]]

func rep_table(rarity: String) -> Array:
	if rarity == "epic": return REP_EPIC
	if rarity == "legendary": return REP_LEG
	return REP_LOW

const IMPLANT_UNLOCK := {"limbs": 2, "organs": 4, "skeleton": 6}

# [hp range, armour range, firepower range] by class and rarity
const BASE_RANGES := {
	"armour": {"common": [[800, 1200], [60, 75], [60, 70]], "uncommon": [[800, 1200], [60, 75], [60, 70]], "rare": [[1100, 1400], [60, 80], [60, 75]], "epic": [[1100, 1400], [60, 80], [60, 75]], "legendary": [[1100, 1400], [70, 80], [60, 75]]},
	"firepower": {"common": [[800, 1200], [60, 70], [60, 75]], "uncommon": [[800, 1200], [60, 70], [60, 75]], "rare": [[800, 1300], [60, 75], [60, 80]], "epic": [[800, 1400], [60, 75], [60, 80]], "legendary": [[800, 1400], [60, 75], [70, 80]]},
	"modder": {"common": [[900, 1200], [60, 70], [60, 65]], "uncommon": [[900, 1200], [60, 70], [60, 65]], "rare": [[900, 1300], [60, 75], [60, 70]], "epic": [[1100, 1400], [60, 75], [60, 70]], "legendary": [[1100, 1400], [60, 75], [60, 70]]},
	"hacker": {"common": [[900, 1200], [60, 70], [60, 70]], "uncommon": [[900, 1200], [60, 70], [60, 70]], "rare": [[1000, 1300], [60, 75], [60, 75]], "epic": [[1100, 1400], [60, 75], [60, 75]], "legendary": [[1100, 1400], [60, 75], [60, 75]]},
}
# Scaling totals (%): [hp per level, arm per level, fp per level, hp per rank, arm per rank, fp per rank, % per rep]
const SCALING := {
	"armour": {"common": [70, 75, 70, 45, 55, 45, 1], "uncommon": [70, 75, 70, 45, 55, 45, 1], "rare": [70, 80, 70, 45, 55, 45, 2], "epic": [75, 80, 70, 50, 55, 45, 2], "legendary": [75, 80, 70, 50, 55, 45, 3]},
	"firepower": {"common": [70, 70, 75, 45, 45, 55, 1], "uncommon": [70, 70, 75, 45, 45, 55, 1], "rare": [70, 70, 80, 45, 45, 55, 2], "epic": [70, 70, 80, 45, 45, 55, 2], "legendary": [70, 70, 80, 45, 45, 55, 3]},
	"modder": {"common": [75, 70, 70, 55, 45, 45, 1], "uncommon": [75, 70, 70, 55, 45, 45, 1], "rare": [80, 70, 70, 55, 45, 45, 2], "epic": [80, 75, 70, 55, 50, 45, 2], "legendary": [80, 75, 70, 55, 50, 45, 3]},
	"hacker": {"common": [70, 70, 70, 45, 45, 45, 1], "uncommon": [70, 70, 70, 45, 45, 45, 1], "rare": [70, 70, 70, 45, 45, 45, 2], "epic": [75, 70, 75, 50, 45, 50, 2], "legendary": [75, 70, 75, 50, 45, 50, 3]},
}
const BASE_CC := 10.0
const BASE_CD := 50.0
const BASE_FW := 30.0
const HACKER_BASE_HACK := [0, 0]  # GDD literal: Hackers have no base Hacking (user decision)

# ---------------------------------------------------------------- equipment
const SLOT_STATS := {
	"weapon": {"pri": ["hp", "hpP", "arm", "armP", "fp", "fpP", "cc", "cd"], "sub": ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd", "cc", "cd", "hack", "fw"]},
	"helmet": {"pri": ["arm"], "sub": ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd", "cc", "cd", "hack", "fw"]},
	"chest": {"pri": ["hp", "hpP", "arm", "armP", "fp", "fpP", "hack", "fw"], "sub": ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd", "cc", "cd", "hack", "fw"]},
	"gloves": {"pri": ["fp"], "sub": ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd", "cc", "cd", "hack", "fw"]},
	"legs": {"pri": ["hp"], "sub": ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd", "cc", "cd", "hack", "fw"]},
	"boots": {"pri": ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd"], "sub": ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd", "cc", "cd", "hack", "fw"]},
	"limbs": {"pri": ["hp", "arm", "fp", "hack"], "sub": ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd", "cd", "hack", "fw"]},
	"organs": {"pri": ["hp", "arm", "fp", "cd"], "sub": ["hp", "hpP", "arm", "armP", "fp", "fpP", "cd", "hack", "fw"]},
	"skeleton": {"pri": ["hp", "arm", "fp", "fw"], "sub": ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd", "cd", "hack", "fw"]},
}
const PRIMARY := {
	"hp": [0, 250, 275, 300, 350, 450, 600], "hpP": [0, 1, 2, 4, 6, 8, 10], "arm": [0, 6, 8, 12, 18, 25, 35], "armP": [0, 1, 2, 4, 6, 8, 10],
	"fp": [0, 6, 8, 12, 18, 25, 35], "fpP": [0, 1, 2, 4, 6, 8, 10], "cc": [0, 1, 2, 4, 6, 8, 10], "cd": [0, 1, 2, 4, 6, 8, 10],
	"hack": [0, 1, 3, 5, 8, 12, 17], "fw": [0, 1, 3, 5, 8, 12, 17], "spd": [0, 1, 2, 3, 4, 5, 6],
}
const SUBSTAT := {
	"hp": [0, 75, 100, 150, 200, 300, 500], "hpP": [0, 1, 2, 3, 5, 7, 10], "arm": [0, 10, 12, 16, 20, 24, 30], "armP": [0, 1, 2, 3, 5, 7, 10],
	"fp": [0, 10, 12, 16, 20, 24, 30], "fpP": [0, 1, 2, 3, 5, 7, 10], "cc": [0, 1, 2, 3, 5, 7, 10], "cd": [0, 1, 2, 3, 5, 7, 10],
	"hack": [0, 10, 12, 16, 20, 24, 30], "fw": [0, 10, 12, 16, 20, 24, 30], "spd": [0, 1, 2, 3, 4, 5, 6],
}
const PRIMARY_GROWTH := 0.15
const SUBS_BY_RARITY := {"common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4}
const MAX_EQUIP_LEVEL := 20
const EQUIP_LEVEL_COST := [0, 300, 500, 800, 1200, 1800, 2600]
const NEON_STATS := ["hp", "hpP", "arm", "armP", "fp", "fpP", "spd", "cd", "hack", "fw"]

func equip_level_cost(rank: int, level: int) -> int:
	return int(round(EQUIP_LEVEL_COST[rank] * pow(level + 1, 1.5) / 10.0)) * 10

func primary_value(stat: String, rank: int, level: int) -> float:
	var v: float = PRIMARY[stat][rank] * (1.0 + PRIMARY_GROWTH * level)
	return round(v) if not STATS[stat].pct else snappedf(v, 0.1)

# Equipment sets. "stat" sets stack per activation; "effect" sets trigger in combat.
const SETS := {
	"Health": {"pieces": 2, "stat": {"hpP": 20}, "desc": "Increase Base HP by 20%"},
	"Armour": {"pieces": 2, "stat": {"armP": 20}, "desc": "Increase Base Armour by 20%"},
	"Firepower": {"pieces": 2, "stat": {"fpP": 20}, "desc": "Increase Base Firepower by 20%"},
	"Speed": {"pieces": 2, "stat": {"spdP": 10}, "desc": "Increase Base Speed by 10%"},
	"Hacking": {"pieces": 2, "stat": {"hack": 20}, "desc": "Increase Base Hacking by 20"},
	"Firewall": {"pieces": 2, "stat": {"fw": 20}, "desc": "Increase Base Firewall by 20"},
	"Critical Chance": {"pieces": 2, "stat": {"cc": 15}, "desc": "Increase Critical Chance by 15%"},
	"Critical Damage": {"pieces": 2, "stat": {"cd": 30}, "desc": "Increase Critical Damage by 30%"},
	"Energy Drain": {"pieces": 4, "effect": "lifesteal", "val": 30, "desc": "Heal by 30% of Damage Dealt"},
	"Pain Mirror": {"pieces": 4, "effect": "reflect", "val": 30, "desc": "Reflect 30% of damage back at the attacker"},
	"Jamming": {"pieces": 4, "effect": "jamming", "val": 2, "desc": "Blocks debuffs on this Warlord for 2 turns"},
	"Strike Back": {"pieces": 4, "effect": "counter", "val": 50, "desc": "50% chance to counter when hit"},
	"Plague": {"pieces": 4, "effect": "onHit", "debuff": "poison", "val": 40, "desc": "40% Chance to apply Poison"},
	"Sanguine": {"pieces": 4, "effect": "onHit", "debuff": "bleed", "val": 40, "desc": "40% Chance to apply Bleed"},
	"Discharge": {"pieces": 4, "effect": "onHit", "debuff": "shock", "val": 30, "desc": "30% Chance to apply Shock"},
	"Trauma": {"pieces": 4, "effect": "onHit", "debuff": "stun", "val": 20, "desc": "20% Chance to apply Stun"},
	"Safeguard": {"pieces": 4, "effect": "safeguard", "val": 30, "desc": "3 turn Overshield of 30% of this Warlord's HP on the team at the start of the round"},
	"Goad": {"pieces": 4, "effect": "onHit", "debuff": "enraged", "val": 20, "desc": "20% Chance to apply Enraged"},
	"Stitcher": {"pieces": 4, "effect": "stitcher", "val": 10, "desc": "Each turn heal each ally by 10% of this Warlord's HP"},
	"Ripper": {"pieces": 4, "effect": "ripper", "val": 25, "desc": "Ignore 25% of Armour"},
}
const STAT_SETS := ["Health", "Armour", "Firepower", "Speed", "Hacking", "Firewall", "Critical Chance", "Critical Damage"]
const HIDEOUT_SETS := {
	"trolls": ["Firepower", "Critical Chance", "Strike Back", "Goad", "Ripper"],
	"vultures": ["Health", "Critical Damage", "Pain Mirror", "Plague", "Discharge"],
	"teratek": ["Armour", "Hacking", "Energy Drain", "Safeguard", "Stitcher"],
	"vikings": ["Firewall", "Speed", "Trauma", "Jamming", "Sanguine"],
}

# ---------------------------------------------------------------- buffs / debuffs (values [small, large])
const BUFFS := {
	"spdUp": {"name": "Speed Up", "icon": "»", "val": [15, 30], "desc": "Speed +x%"},
	"armUp": {"name": "Armour Up", "icon": "⛨", "val": [25, 50], "desc": "Armour +x%"},
	"fpUp": {"name": "Firepower Up", "icon": "▲", "val": [25, 50], "desc": "Firepower +x%"},
	"hackUp": {"name": "Hacking Up", "icon": "⌬", "val": [40, 70], "desc": "Hacking +x"},
	"fwUp": {"name": "Firewall Up", "icon": "▦", "val": [40, 70], "desc": "Firewall +x"},
	"ccUp": {"name": "Crit Chance Up", "icon": "✧", "val": [15, 30], "desc": "Crit chance +x%"},
	"cdUp": {"name": "Crit Damage Up", "icon": "✹", "val": [25, 50], "desc": "Crit damage +x%"},
	"blockDebuffs": {"name": "Block Debuffs", "icon": "⊘", "val": [0, 0], "desc": "Blocks all debuffs"},
	"contHeal": {"name": "Continuous Heal", "icon": "✚", "val": [10, 20], "desc": "Heal x% max HP each turn"},
	"bolster": {"name": "Bolster", "icon": "▣", "val": [15, 25], "desc": "Damage taken -x%"},
	"reflect": {"name": "Reflect", "icon": "↺", "val": [15, 30], "desc": "Reflect x% of damage", "stack": true},
	"overshield": {"name": "Overshield", "icon": "◍", "val": [10, 30], "desc": "Absorbs damage"},
	"vampire": {"name": "Vampire", "icon": "♥", "val": [15, 30], "desc": "Heal x% of damage dealt"},
	"counter": {"name": "Counter", "icon": "⤺", "val": [50, 100], "desc": "x% chance to counter"},
	"unkillable": {"name": "Unkillable", "icon": "∞", "val": [0, 0], "desc": "HP cannot drop below 1"},
}
const DEBUFFS := {
	"spdDown": {"name": "Speed Down", "icon": "«", "val": [15, 30], "desc": "Speed -x%"},
	"armDown": {"name": "Armour Down", "icon": "⛨", "val": [25, 50], "desc": "Armour -x%"},
	"fpDown": {"name": "Firepower Down", "icon": "▼", "val": [25, 50], "desc": "Firepower -x%"},
	"fwDown": {"name": "Firewall Down", "icon": "▦", "val": [40, 70], "desc": "Firewall -x (unresistable)", "noCheck": true},
	"hackDown": {"name": "Hacking Down", "icon": "⌬", "val": [40, 70], "desc": "Hacking -x"},
	"ccDown": {"name": "Crit Chance Down", "icon": "✧", "val": [15, 30], "desc": "Crit chance -x%"},
	"cdDown": {"name": "Crit Damage Down", "icon": "✹", "val": [25, 50], "desc": "Crit damage -x%"},
	"poison": {"name": "Poison", "icon": "☣", "val": [2.5, 5], "desc": "Lose x% max HP each turn", "stack": true},
	"bleed": {"name": "Bleed", "icon": "♦", "val": [2.5, 5], "desc": "Lose x% of the hit's damage each turn", "stack": true},
	"shock": {"name": "Shock", "icon": "ϟ", "val": [25, 50], "desc": "x% chance to miss turn"},
	"stun": {"name": "Stun", "icon": "✶", "val": [0, 0], "desc": "Misses next turn"},
	"break": {"name": "Break", "icon": "✕", "val": [15, 25], "desc": "Takes x% more damage"},
	"mark": {"name": "Mark Target", "icon": "◎", "val": [2, 3], "desc": "Next hit deals x times damage"},
	"enraged": {"name": "Enraged", "icon": "☠", "val": [0, 0], "desc": "Basic attacks the enrager only"},
	"blockBuffs": {"name": "Block Buffs", "icon": "⊗", "val": [0, 0], "desc": "Cannot receive buffs"},
	"cdIncrease": {"name": "Cooldown Increase", "icon": "⧗", "val": [1, 99], "desc": "Cooldowns increased"},
	"healBlock": {"name": "Heal Block", "icon": "✖", "val": [0, 0], "desc": "Cannot be healed"},
	"stupefy": {"name": "Stupefy", "icon": "≋", "val": [35, 35], "desc": "35% to miss turn, Hacking -50"},
	"blockRevive": {"name": "Block Revive", "icon": "†", "val": [0, 0], "desc": "Cannot be revived"},
}

# ---------------------------------------------------------------- neuronet
const NN_COST := [null, [1, 50], [1, 100], [2, 150], [2, 200], [3, 250], [3, 300], [3, 350]]  # layer -> [fragment tier, cost per point]
const NN_POINTS_PER_LAYER := 4
const NN_CAREERS := ["assault", "protection", "control"]
const NEURONET := {
	"assault": [
		[{"id": "precision", "name": "Precision Strike", "desc": "Increase Critical Chance by 5/10%.", "v": [5, 10]}, {"id": "blitz", "name": "Blitz", "desc": "First attack deals 5/10% more damage.", "v": [5, 10]}],
		[{"id": "munitions", "name": "Munitions Dump", "desc": "Increase Firepower by 5/10%.", "v": [5, 10]}, {"id": "forceMeasure", "name": "Force Measure", "desc": "Increase Critical Damage by 10/20%.", "v": [10, 20]}],
		[{"id": "essenceShield", "name": "Essence Shield", "desc": "Gain OVERSHIELD equal to 5/10% Max HP on Kill.", "v": [5, 10]}, {"id": "grandChallenge", "name": "Grand Challenge", "desc": "Deal 5/10% more damage to a target with higher HP.", "v": [5, 10]}],
		[{"id": "bloodFrenzy", "name": "Blood Frenzy", "desc": "Damage +3/6% on each kill to a max of 9/18%.", "v": [3, 6]}, {"id": "accruing", "name": "Accruing Assault", "desc": "Each skill use stacks 2/4% more damage to a max of 6/12%.", "v": [2, 4]}],
		[{"id": "openOpp", "name": "Open Opportunity", "desc": "Increase damage by 5/10% against debuffed Warlords.", "v": [5, 10]}, {"id": "berserker", "name": "Berserker Rage", "desc": "Damage +10/20% per debuff on this Warlord to a max of 30/60%.", "v": [10, 20]}],
		[{"id": "pummel", "name": "Pummel", "desc": "Deal 5/10% more damage to Warlords with 50% or less HP.", "v": [5, 10]}, {"id": "siphon", "name": "Siphon Essence", "desc": "Heal by 10% of damage dealt when at 30% HP or less.", "v": [10], "max": 1}],
		[{"id": "wrath", "name": "Warlord's Wrath", "desc": "65% chance to deal extra damage equal to 50% of the damage dealt.", "v": [65], "max": 1}, {"id": "fracture", "name": "Fracture", "desc": "50% chance to ignore 30% Armour when attacking.", "v": [50], "max": 1}],
	],
	"protection": [
		[{"id": "plating", "name": "Heavy Plating", "desc": "Increase Armour by 5/10%.", "v": [5, 10]}, {"id": "fitness", "name": "Fitness Regime", "desc": "Increase Health by 5/10%.", "v": [5, 10]}],
		[{"id": "egocentric", "name": "Egocentric", "desc": "Healing and OVERSHIELD received +5/15%.", "v": [5, 15]}, {"id": "altruistic", "name": "Altruistic", "desc": "Healing and OVERSHIELD given +5/15%.", "v": [5, 15]}],
		[{"id": "guardian", "name": "Guardian Angel", "desc": "Absorbs 5/10% of damage dealt to all allied Warlords.", "v": [5, 10]}, {"id": "prepared", "name": "Prepared Defense", "desc": "First hit on this Warlord deals 10/20% less damage.", "v": [10, 20]}],
		[{"id": "parry", "name": "Desperate Parry", "desc": "15/25% chance to COUNTERATTACK when hit by a Critical.", "v": [15, 25]}, {"id": "surgeon", "name": "Field Surgeon", "desc": "Healing abilities used by this Warlord +50/100%.", "v": [50, 100]}],
		[{"id": "medLearning", "name": "Medical Learning", "desc": "Heal by 5/10% of any value an enemy heals by.", "v": [5, 10]}, {"id": "galvanized", "name": "Galvanized Metals", "desc": "Increase Armour by 10/20%.", "v": [10, 20]}],
		[{"id": "whiteKnight", "name": "White Knight", "desc": "15/25% chance to COUNTERATTACK when an ally is hit by a Critical.", "v": [15, 25]}, {"id": "rapidRescue", "name": "Rapid Rescue", "desc": "Gain 15/25% turn meter when an ally drops below 25% HP.", "v": [15, 25]}],
		[{"id": "foresight", "name": "Battlefield Foresight", "desc": "OVERSHIELD the gang at combat start equal to 5/10% of this Warlord's Max HP.", "v": [5, 10]}, {"id": "formations", "name": "Advanced Formations", "desc": "Allies gain 5/10% of this Warlord's Armour.", "v": [5, 10]}],
	],
	"control": [
		[{"id": "malware", "name": "Malware Packages", "desc": "Increase Hacking by 5/15.", "v": [5, 15]}, {"id": "monitoring", "name": "Real Time Monitoring", "desc": "Increase Firewall by 10/20.", "v": [10, 20]}],
		[{"id": "adaptive", "name": "Adaptive Networks", "desc": "Heal 5/10% Max HP when this Warlord blocks a debuff.", "v": [5, 10]}, {"id": "exploits", "name": "System Exploits", "desc": "20/40% chance to gain 10% TM when a debuff you created expires.", "v": [20, 40]}],
		[{"id": "syphonIntel", "name": "Syphon Intel", "desc": "Heal 5/10% Max HP when an enemy blocks your debuff.", "v": [5, 10]}, {"id": "packetFilter", "name": "Packet Filtering", "desc": "20/40% chance to gain 10% TM when a buff you created expires.", "v": [20, 40]}],
		[{"id": "adware", "name": "Adware", "desc": "35% chance that each debuff created lasts an extra turn.", "v": [35], "max": 1}, {"id": "personalAds", "name": "Personal Advertisements", "desc": "35% chance that each buff created lasts an extra turn.", "v": [35], "max": 1}],
		[{"id": "ddos", "name": "DDoS", "desc": "10/20% chance to spread a created debuff to all enemies.", "v": [10, 20]}, {"id": "encrypt", "name": "Encrypt NeuroNet", "desc": "Increase Firewall by 30/60.", "v": [30, 60]}],
		[{"id": "pullMeta", "name": "Pull Metadata", "desc": "10/20% chance to spread a created buff to all allies.", "v": [10, 20]}, {"id": "ransomware", "name": "Ransomware", "desc": "Increase Hacking by 25/50.", "v": [25, 50]}],
		[{"id": "baitSwitch", "name": "Bait and Switch", "desc": "15/25% chance to deflect an incoming debuff to the attacker.", "v": [15, 25]}, {"id": "breach", "name": "Breach", "desc": "Increase the chance to place all debuffs by 5/10%.", "v": [5, 10]}],
	],
}
var NN_BY_ID := {}

func _index_neuronet() -> void:
	for car in NN_CAREERS:
		var layers: Array = NEURONET[car]
		for li in layers.size():
			for sk in layers[li]:
				var d: Dictionary = sk.duplicate()
				d["max"] = int(sk.get("max", 2))
				d["career"] = car
				d["layer"] = li + 1
				NN_BY_ID[sk.id] = d

# ---------------------------------------------------------------- economy
const CONTRACT_RATES := {
	"uncommon": {"common": 90.0, "uncommon": 9.0, "rare": 1.0},
	"rare": {"rare": 92.0, "epic": 7.5, "legendary": 0.5},
	"epic": {"epic": 92.0, "legendary": 8.0},
	"legendary": {"legendary": 100.0},
}
const SCRAP_TO_CONTRACT := 10
const SCRAP_FOR := {"common": "uncommon", "uncommon": "uncommon", "rare": "rare", "epic": "epic", "legendary": "legendary"}
const METABOLIC_XP := {"minor": 1500, "major": 8000, "grand": 40000}
const METABOLIC_ALIGN_BONUS := 0.5
const ABILITY_MAX_LEVEL := {"active": 5, "passive": 3, "leader": 3, "reinforce": 3}
const ABILITY_LEVEL_BONUS := 0.05

## Max level of an ability: 1 when leveling would change nothing in battle (pure buffs, immunities,
## specials and 100%-chance effects), else ABILITY_MAX_LEVEL by type. Mirrors Battle.ab_level_mult use.
func ability_max_level(a: Dictionary) -> int:
	return ABILITY_MAX_LEVEL.get(a.type, 1) if ability_scales(a) else 1

func ability_scales(a: Dictionary) -> bool:
	if a.type == "leader":
		return true
	if a.type == "passive" and a.has("stats"):
		return true
	if a.type != "passive" and float(a.get("mult", 0)) > 0.0:
		return true
	var fxs: Array = a.get("fx", []).duplicate()
	for h in a.get("hooks", []):
		fxs.append_array(h.get("fx", []))
	for f in fxs:
		if f.t in ["heal", "shield"]:
			return true
		if f.t == "tm" and float(f.get("v", 0)) > 0:
			return true
		if f.t == "debuff" and float(f.get("chance", 100)) < 100:
			return true
	return false
const SAFEHOUSE_COST := [0, 100, 225, 350, 475, 600, 725, 850, 975, 1100, 1250]
const SAFEHOUSE_PCT := [0, 1, 2, 3, 4, 6, 8, 10, 14, 16, 20]
const SAFEHOUSE_FLAT := [0, 2, 4, 6, 8, 12, 16, 20, 28, 32, 40]
const SAFEHOUSE_NODES := {"hpP": "Health", "armP": "Armour", "fpP": "Firepower", "cd": "Crit Damage", "hack": "Hacking", "fw": "Firewall"}
const STOCKS := [null, {"daily": 22, "cap": 40}, {"daily": 44, "cap": 60}, {"daily": 66, "cap": 75}]
const STOCK_LEVEL_AT := [0, 1, 20, 40]  # legacy (player level); levels now come from STOCK_LEVEL_AMBITION
## GDD: "Additional Stocks levels are gained through player progression missions". Level 1 is free;
## level N needs the "Complete All Tier <value> <category> Ambitions" ambition claimed (open lever).
## Stocks cap upgrade (GDD: "additional caps being a microtransaction"); size and count are open levers.
const STOCKS_CAP_STEP := 25
const STOCKS_CAP_BUYS := 4
const STOCK_LEVEL_AMBITION := [null, null, ["Campaign", 1], ["Campaign", 2]]
const PIT_CAP := 10
const HEIST_DAILY := 5
const BOUNTY_DAILY := 12
const BASTION_ENTRIES := 3

func pit_loss(tier: int) -> int:
	if tier <= 4: return 10
	if tier <= 8: return 15
	if tier <= 12: return 20
	return 25

# ---------------------------------------------------------------- battle pass
const BP_DAILY := [
	{"id": "pitKill10", "text": "Kill 10 Warlords in the Pit", "ev": "pitKill", "n": 10},
	{"id": "rank4", "text": "Rank up a Warlord to Rank 4+", "ev": "rankUp4", "n": 1},
	{"id": "rankAny", "text": "Rank up a Warlord", "ev": "rankUp", "n": 1},
	{"id": "equip16", "text": "Level an Equipment to 16", "ev": "equip16", "n": 1},
	{"id": "equip12x3", "text": "Level 3 Equipments to 12", "ev": "equip12", "n": 3},
	{"id": "hideEq3", "text": "Acquire 3 Equipment from Hideouts", "ev": "hideoutEquip", "n": 3},
	{"id": "contracts10", "text": "Open 10 Contracts", "ev": "recruit", "n": 10},
	{"id": "dens10", "text": "Complete 10 Dens", "ev": "den", "n": 10},
	{"id": "hideouts5", "text": "Complete 5 Hideouts", "ev": "hideout", "n": 5},
	{"id": "spend100k", "text": "Spend 100K Credits", "ev": "spendCredits", "n": 100000},
]
const BP_WEEKLY := [
	{"id": "pitKill25", "text": "Kill 25 Warlords in the Pit", "ev": "pitKill", "n": 25},
	{"id": "rank5", "text": "Rank up a Warlord to Rank 5+", "ev": "rankUp5", "n": 1},
	{"id": "rankAnyW", "text": "Rank up a Warlord", "ev": "rankUp", "n": 1},
	{"id": "equip16x2", "text": "Level 2 Equipment to 16", "ev": "equip16", "n": 2},
	{"id": "hideEq10", "text": "Acquire 10 Equipment from Hideouts", "ev": "hideoutEquip", "n": 10},
	{"id": "contracts25", "text": "Open 25 Contracts", "ev": "recruit", "n": 25},
	{"id": "dens50", "text": "Complete 50 Dens", "ev": "den", "n": 50},
	{"id": "hideouts25", "text": "Complete 25 Hideouts", "ev": "hideout", "n": 25},
	{"id": "spend500k", "text": "Spend 500K Credits", "ev": "spendCredits", "n": 500000},
]
const BP_DAILY_MERITS := 15
const BP_DAILY_BONUS := 25
const BP_WEEKLY_MERITS := 20
const BP_WEEKLY_BONUS := 20
const BP_MERITS_PER_LEVEL := 20
const BP_SEASON_DAYS := 70
const BP_GAP_DAYS := 14

# ---------------------------------------------------------------- jobs (event, target) in GDD order
const JOB_DEFS := {
	"daily": [["pitBrawl", 3], ["den", 10], ["plazaBuy", 1], ["recruit", 3], ["equip8", 3], ["warlordLevel", 1], ["hideoutEquip", 3], ["allDaily", 7]],
	"weekly": [["dailyAll", 5], ["pitBrawl", 20], ["repUp", 1], ["hideoutEquip", 15], ["rankTo3", 1], ["equip12", 3], ["allWeekly", 6]],
	"monthly": [["dailyAll", 30], ["pitBrawl", 150], ["den", 400], ["rankTo5", 1], ["equip16", 3], ["hideoutEquip", 100], ["allMonthly", 6]],
}

# ---------------------------------------------------------------- plaza (hourly credit market)
## Ability damage scaling per class (shared by the battle engine and the power score so they agree).
## Tuned with tests/ClassProbe.tscn: damage x effective HP within ~15% across classes at R6.
const CLASS_SCALING := {
	"armour": {"arm": 0.78},
	"firepower": {"fp": 1.08},
	"modder": {"hp": 0.037},
	"hacker": {"fp": 0.72, "hack": 1.2},
}

func class_damage(cls: String, hp: float, arm: float, fp: float, hack: float) -> float:
	var c: Dictionary = CLASS_SCALING.get(cls, {"fp": 1.0})
	return hp * c.get("hp", 0.0) + arm * c.get("arm", 0.0) + fp * c.get("fp", 0.0) + hack * c.get("hack", 0.0)

## Combat power: geometric mean of offence (class damage x crit x speed) and defence (effective HP).
func stat_power(cls: String, s: Dictionary) -> float:
	var hp: float = float(s.hp)
	var arm: float = float(s.arm)
	var off: float = class_damage(cls, hp, arm, float(s.fp), float(s.hack))
	off *= 1.0 + min(float(s.cc), 100.0) / 100.0 * float(s.cd) / 100.0
	off *= float(s.spd) / 100.0
	var mit: float = min(0.8, arm / (arm + 500.0))
	var ehp: float = hp / (1.0 - mit)
	return sqrt(max(1.0, off * ehp)) * 0.65

## Gradual feature unlocks by Player Level (the GDD leaves this open; paced from playthrough data).
const FEATURE_UNLOCK := {"battle_pass": 3, "plaza": 4, "black_market": 4, "hideouts": 5, "hideout": 5, "events": 6,
	"sw": 8, "arena": 10, "safehouse": 10, "gang": 12}
const FEATURE_INFO := {
	"battle_pass": ["Battle Pass", "Seasonal challenges with a free and a premium reward track."],
	"plaza": ["The Plaza", "A credit market with new stock every hour."],
	"black_market": ["Black Market", "Spend Pit Coin on stimms, firmware, gear and contracts."],
	"hideouts": ["Hideouts", "Boss lairs that drop high-rank gear, implants, memory fragments and deeds."],
	"events": ["Events", "Limited-time goals with bonus rewards."],
	"sw": ["Syndicate Wars", "Single-syndicate squads fight for Neons, the only place they drop."],
	"arena": ["The Pit", "Fight other players' defence squads for Pit Coin and bracket rewards."],
	"safehouse": ["Safehouse", "Permanent stat boosts for every Warlord of an alignment."],
	"gang": ["Gangs & Bastion", "Join a gang and raid the TeraTek Bastion together."],
}

# share of a win's XP given on a loss (warlord XP and player XP, GDD: 20%)
const LOSS_XP_FACTOR := 0.2

# player-facing explanation of reward kinds whose shop/GDD row text doesn't say what they do (keyed by reward "k")
const REWARD_INFO := {
	"raidTicket": "+1 Gang Bastion (raid boss) entry after the daily entries are used.",
}

const PLAZA_POOL := [
	{"r": {"k": "gear", "rank": 3, "r": "rare", "n": 1}, "cost": 40000},
	{"r": {"k": "gear", "rank": 4, "r": "rare", "n": 1}, "cost": 90000},
	{"r": {"k": "gear", "rank": 4, "r": "epic", "n": 1}, "cost": 160000},
	{"r": {"k": "gear", "rank": 5, "r": "epic", "n": 1}, "cost": 320000},
	{"r": {"k": "implant", "rank": 3, "r": "rare", "n": 1}, "cost": 60000},
	{"r": {"k": "implant", "rank": 4, "r": "epic", "n": 1}, "cost": 220000},
	# endgame stock (GDD: credits buy gear from shops) - the late-game credit sink
	{"r": {"k": "gear", "rank": 5, "r": "legendary", "n": 1}, "cost": 900000},
	{"r": {"k": "gear", "rank": 6, "r": "epic", "n": 1}, "cost": 650000},
	{"r": {"k": "gear", "rank": 6, "r": "legendary", "n": 1}, "cost": 1600000},
	{"r": {"k": "implant", "rank": 5, "r": "epic", "n": 1}, "cost": 500000},
	{"r": {"k": "implant", "rank": 6, "r": "legendary", "n": 1}, "cost": 1800000},
	{"r": {"k": "metabolic", "align": "neutral", "tier": "minor", "n": 3}, "cost": 15000},
	{"r": {"k": "metabolic", "align": "paragon", "tier": "minor", "n": 3}, "cost": 15000},
	{"r": {"k": "metabolic", "align": "renegade", "tier": "minor", "n": 3}, "cost": 15000},
	{"r": {"k": "metabolic", "align": "paragon", "tier": "major", "n": 2}, "cost": 40000},
	{"r": {"k": "metabolic", "align": "neutral", "tier": "major", "n": 2}, "cost": 40000},
	{"r": {"k": "metabolic", "align": "renegade", "tier": "major", "n": 2}, "cost": 40000},
	{"r": {"k": "metabolic", "align": "paragon", "tier": "grand", "n": 1}, "cost": 120000},
	{"r": {"k": "metabolic", "align": "neutral", "tier": "grand", "n": 1}, "cost": 120000},
	{"r": {"k": "metabolic", "align": "renegade", "tier": "grand", "n": 1}, "cost": 120000},
	{"r": {"k": "deeds", "align": "generic", "tier": "minor", "n": 5}, "cost": 25000},
	{"r": {"k": "deeds", "align": "paragon", "tier": "minor", "n": 5}, "cost": 25000},
	{"r": {"k": "deeds", "align": "neutral", "tier": "minor", "n": 5}, "cost": 25000},
	{"r": {"k": "deeds", "align": "renegade", "tier": "minor", "n": 5}, "cost": 25000},
	{"r": {"k": "mf", "tier": 1, "n": 50}, "cost": 30000},
	{"r": {"k": "mf", "tier": 2, "n": 30}, "cost": 80000},
	{"r": {"k": "stimm", "r": "rare", "n": 1}, "cost": 90000},
	{"r": {"k": "firmware", "lv": 1, "n": 1}, "cost": 30000},
	{"r": {"k": "contract", "r": "uncommon", "n": 1}, "cost": 20000},
]

# ---------------------------------------------------------------- campaign
const CAMPAIGN_SYNDICATE := ["trolls", "vultures", "traders", "vikings", "spliced", "trolls", "shogunate", "vultures", "shogunate", "teratek"]
const CAMPAIGN_ENERGY := [4, 6, 8]
# additional drops per difficulty: [kind, rarity/amount, chance]
const CAMPAIGN_DROPS := [
	[["warlord", "common", 15.0], ["warlord", "uncommon", 5.0], ["equip", "", 75.0], ["contract", 1, 5.0]],
	[["warlord", "uncommon", 17.5], ["warlord", "rare", 2.5], ["equip", "", 75.0], ["contract", 2, 5.0]],
	[["warlord", "uncommon", 15.0], ["warlord", "rare", 5.0], ["equip", "", 75.0], ["contract", 3, 5.0]],
]
# campaign equipment quality per difficulty: rank weights, rarity weights ("lower quality and rank" than hideouts)
const CAMPAIGN_EQUIP := [
	{"ranks": {1: 40, 2: 40, 3: 20}, "rar": {"common": 30, "uncommon": 50, "rare": 20}},
	{"ranks": {3: 50, 4: 40, 5: 10}, "rar": {"uncommon": 30, "rare": 55, "epic": 15}},
	{"ranks": {4: 45, 5: 45, 6: 10}, "rar": {"rare": 55, "epic": 40, "legendary": 5}},
]
