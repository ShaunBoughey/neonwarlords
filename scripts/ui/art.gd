class_name Art
extends RefCounted
## Paths and helpers for the supplied UI art (res://assets/ui). Art is authored for 1920x1080.

const ROOT := "res://assets/ui/"
const BACKGROUND := ROOT + "Background.jpg"
const FONT_RG := "res://assets/fonts/Vipnagorgialla Rg.otf"
const FONT_BD := "res://assets/fonts/Vipnagorgialla Bd.otf"

const SYN_SYMBOL := {
	"trolls": "WarlordTitleZoneG/SyndicateG/SyndicateSymbolCardinalTrolls.png",
	"traders": "WarlordTitleZoneG/SyndicateG/SyndicateSymbolFrontierTraders.png",
	"spliced": "WarlordTitleZoneG/SyndicateG/SyndicateSymbolGeneSpliced.png",
	"shogunate": "WarlordTitleZoneG/SyndicateG/SyndicateSymbolNeoShogunate.png",
	"vikings": "WarlordTitleZoneG/SyndicateG/SyndicateSymbolQuantumVikings.png",
	"teratek": "WarlordTitleZoneG/SyndicateG/SyndicateSymbolTeratekCybernetics.png",
	"vultures": "WarlordTitleZoneG/SyndicateG/SyndicateSymbolVultures.png",
}
const SYN_BADGE := {
	"trolls": "WarlordTitleZoneG/SyndicateG/Syndicate CardinalTrolls 85x80.png",
	"traders": "WarlordTitleZoneG/SyndicateG/Syndicate FrontierTraders 85x80.png",
	"spliced": "WarlordTitleZoneG/SyndicateG/Syndicate GeneSpliced 85x80.png",
	"shogunate": "WarlordTitleZoneG/SyndicateG/Syndicate NeoShogunate 85x80.png",
	"vikings": "WarlordTitleZoneG/SyndicateG/Syndicate QuantumVikings 85x80.png",
	"teratek": "WarlordTitleZoneG/SyndicateG/Syndicate TeratekCybernetic 85x80.png",
	"vultures": "WarlordTitleZoneG/SyndicateG/Syndicate Vultures 85x80.png",
}
const CLASS_SYMBOL := {
	"armour": "WarlordTitleZoneG/ClassesG/ClassSymbolArmour.png",
	"firepower": "WarlordTitleZoneG/ClassesG/ClassSymbolFirepower.png",
	"hacker": "WarlordTitleZoneG/ClassesG/ClassSymbolHacker.png",
	"modder": "WarlordTitleZoneG/ClassesG/ClassSymbolModder.png",
}
const CLASS_BADGE := {
	"armour": "WarlordTitleZoneG/ClassesG/Class Armour 85x80.png",
	"firepower": "WarlordTitleZoneG/ClassesG/Class Firepower 85x80.png",
	"hacker": "WarlordTitleZoneG/ClassesG/Class Hacker 85x80.png",
	"modder": "WarlordTitleZoneG/ClassesG/Class Modder 85x80.png",
}
const SLOT_BUTTON := {
	"weapon": "GearScreenG/WeaponSlotButton--normal.png", "helmet": "GearScreenG/HelmetSlotButton--normal.png",
	"chest": "GearScreenG/ChestSlotButton--normal.png", "gloves": "GearScreenG/GlovesSlotButton--normal.png",
	"legs": "GearScreenG/LegsSlotButton--normal.png", "boots": "GearScreenG/BootsSlotButton--normal.png",
	"limbs": "ImplantScreenG/LimbsSlotButton--normal.png", "organs": "ImplantScreenG/OrganSlotButton--normal.png",
	"skeleton": "ImplantScreenG/SkeletonSlotButton--normal.png",
}
const NEON := {
	"hp": "Neon Health", "hpP": "Neon Health _", "arm": "Neon Armour", "armP": "Neon Armour _", "fp": "Neon Firepower",
	"fpP": "Neon Firepower _", "spd": "Neon Speed", "cc": "Neon Crit Chance", "cd": "Neon Crit Damage", "hack": "Neon Hacking", "fw": "Neon Firewall",
}
const NN_FILE := {
	"precision": "Assualt Precision Strike", "blitz": "Assualt Blitz", "munitions": "Assualt Munitions Dump", "forceMeasure": "Assualt Force Measure",
	"essenceShield": "Assualt Esence Shield", "grandChallenge": "Assualt Grand Challenge", "bloodFrenzy": "Assualt Blood Frenzy",
	"accruing": "Assualt Accruing Assault", "openOpp": "Assualt Open Opportunity", "berserker": "Assualt Berserker Rage",
	"pummel": "Assualt Pummel", "siphon": "Assualt Essence Drain", "wrath": "Assualt Warlords Wrath", "fracture": "Assualt Fracture",
	"plating": "Protection Heavy Plating", "fitness": "Protection Fitness Regime", "egocentric": "Protection Egocentric",
	"altruistic": "Protection Altruistic", "guardian": "Protection Guardian Angel", "prepared": "Protection Prepared Defense",
	"parry": "Protection Desperate Parry", "surgeon": "Protection Field Surgeon", "medLearning": "Protection Medical Learning",
	"galvanized": "Protection Galvanized Metals", "whiteKnight": "Protection White Knight", "rapidRescue": "Protection Rapid Rescue",
	"foresight": "Protection Battlefield Foresight", "formations": "Protection Advanced Formations",
	"malware": "Control Maleware Packages", "monitoring": "Control Real Time Monitoring", "adaptive": "Control Adaptive Networks",
	"exploits": "Control System Exploit", "syphonIntel": "Control Siphon Intel", "packetFilter": "Control Packet Filtering",
	"adware": "Control Adware", "personalAds": "Control Personalized Ads", "ddos": "Control DDos", "encrypt": "Control Encrypt Node",
	"pullMeta": "Control Pull Metadata", "ransomware": "Control Ransom Wars", "baitSwitch": "Control Bait and Switch", "breach": "Control Breach",
}

static var _cache := {}

static func tex(rel: String) -> Texture2D:
	var p := rel if rel.begins_with("res://") else ROOT + rel
	if not _cache.has(p):
		_cache[p] = load(p) if ResourceLoader.exists(p) else null
	return _cache[p]

static func has(rel: String) -> bool:
	return tex(rel) != null

static func deed(align: String, tier: String) -> String:
	return "RepScreenG/New Assets/%s %s Deed 56x83.png" % [U.cap(align), U.cap(tier)]

static func deed_big(align: String, tier: String) -> String:
	if align == "generic":
		return "RepScreenG/OwnedCoinsG/" + ("Gold Deed 212x312.png" if tier != "major" else "Silver Deed 212x312.png")
	return "Deed Icons 212x312/%s %s Deed 212x312.png" % [U.cap(align), U.cap(tier)]

static func neon_small(stat: String) -> String:
	return "UI - Neons Small/%s 41x40.png" % NEON.get(stat, "Neon Health")

static func neon_big(stat: String) -> String:
	return "UI - Neons/%s 625x615.png" % NEON.get(stat, "Neon Health")

static func nn_icon(id: String) -> String:
	return "MF and NN Icons/NN Icon 359x410 %s.png" % NN_FILE.get(id, "Assualt Blitz")

static func mf_icon(tier: int) -> String:
	return "NeuroNetScreenG/Tier%dMFIcon.png" % tier

static func warlord_border(rarity: String) -> String:
	return "UI - Selection Borders/UI - Warlord Select %s 188x248.png" % U.cap(rarity)

static func equip_border(rarity: String) -> String:
	return "UI - Selection Borders/UI - Equipment Select %s 190x230.png" % U.cap(rarity)

static func stimm(r: String) -> String:
	return "AbilityScreenG/OwnedStimmsG/Stimm%sButton--normal.png" % U.cap(r)

static func firmware(lv: int) -> String:
	return "RankScreenG/FirmwareMK%dButton--normal.png" % lv

static func metabolic(align: String) -> String:
	var a := "neutral" if align == "generic" else align
	return "LevelScreenG/%sMetabolicsButton--normal.png" % U.cap(a)

## TextureRect sized to the texture (times scale), placed at pos.
static func rect(rel: String, pos := Vector2.ZERO, scale := 1.0, size := Vector2.ZERO) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(rel)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	var s := size
	if s == Vector2.ZERO and r.texture:
		s = r.texture.get_size() * scale
	r.position = pos
	r.size = s
	r.custom_minimum_size = s
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## Image fitted inside a box, keeping aspect.
static func icon(rel: String, size: Vector2) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex(rel)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = size
	r.size = size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## TextureButton using "<base>--normal.png" and "--pressed.png" when present.
static func button(base: String, cb: Callable, pos := Vector2.ZERO, scale := 1.0, toggled := false) -> TextureButton:
	var b := TextureButton.new()
	var normal := base if base.ends_with(".png") else base + "--normal.png"
	var pressed := normal.replace("--normal.png", "--pressed.png")
	b.texture_normal = tex(normal)
	if has(pressed):
		b.texture_pressed = tex(pressed)
		b.texture_hover = tex(pressed)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.focus_mode = Control.FOCUS_NONE
	var s: Vector2 = b.texture_normal.get_size() * scale if b.texture_normal else Vector2(64, 64)
	b.position = pos
	b.size = s
	b.custom_minimum_size = s
	if toggled and b.texture_pressed:
		b.texture_normal = b.texture_pressed
	if cb.is_valid():
		b.pressed.connect(cb)
	return b

static var _fonts := {}

static func font(bold := false) -> Font:
	var p := FONT_BD if bold else FONT_RG
	if not _fonts.has(p):
		_fonts[p] = load(p) if ResourceLoader.exists(p) else null
	return _fonts[p]
