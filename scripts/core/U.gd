extends Node
## Utilities: random helpers, formatting, time periods and GDD reward-string parsing.

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

# ---------------------------------------------------------------- random
func ri(a: int, b: int) -> int:
	return rng.randi_range(a, b)

func rf() -> float:
	return rng.randf()

func chance(pct: float) -> bool:
	return rng.randf() * 100.0 < pct

func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[rng.randi_range(0, arr.size() - 1)]

func shuffled(arr: Array) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
	return a

## Weighted pick from a Dictionary {key: weight} or Array of [key, weight]. Weights need not sum to 100.
func weighted(w):
	var entries: Array = []
	if w is Dictionary:
		for k in w:
			entries.append([k, float(w[k])])
	else:
		entries = w
	var total := 0.0
	for e in entries:
		total += max(0.0, float(e[1]))
	if entries.is_empty():
		return null
	if total <= 0.0:
		return entries[0][0]
	var x := rng.randf() * total
	for e in entries:
		x -= max(0.0, float(e[1]))
		if x < 0.0:
			return e[0]
	return entries[entries.size() - 1][0]

func uid() -> String:
	return "%x%x" % [Time.get_ticks_usec(), rng.randi()]

func hash_str(s: String) -> int:
	return abs(s.hash())

# ---------------------------------------------------------------- format
func fmt(n) -> String:
	var v := float(n)
	var a: float = abs(v)
	if a >= 1e9:
		return _trim("%.2f" % (v / 1e9)) + "B"
	if a >= 1e6:
		return _trim("%.2f" % (v / 1e6)) + "M"
	if a >= 1e4:
		return _trim("%.1f" % (v / 1e3)) + "K"
	return _thousands(int(v))

func _trim(s: String) -> String:
	if s.contains("."):
		s = s.rstrip("0").rstrip(".")
	return s

func _thousands(n: int) -> String:
	var s := str(abs(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out

func cap(s: String) -> String:
	if s.is_empty():
		return s
	return s.substr(0, 1).to_upper() + s.substr(1)

func dur(sec: float) -> String:
	if sec <= 0:
		return "now"
	var s := int(sec)
	var d := s / 86400
	var h := (s % 86400) / 3600
	var m := (s % 3600) / 60
	if d > 0:
		return "%dd %dh" % [d, h]
	if h > 0:
		return "%dh %dm" % [h, m]
	return "%dm %ds" % [m, s % 60]

# ---------------------------------------------------------------- time
## Seconds added to the clock (used by the playthrough simulation to fast-forward days).
var time_offset := 0.0
## Tests: >= 0 freezes the wall clock at this unix time (seeded bot runs are then repeatable).
var clock_base := -1.0

func now() -> float:
	return (clock_base if clock_base >= 0.0 else Time.get_unix_time_from_system()) + time_offset

func day_id(t: float = -1.0) -> int:
	if t < 0:
		t = now()
	return int(floor(t / 86400.0))

## Weeks start on Monday (unix day 0 was a Thursday).
func week_id(t: float = -1.0) -> int:
	return int(floor((day_id(t) + 3) / 7.0))

func month_id(t: float = -1.0) -> int:
	if t < 0:
		t = now()
	var d := Time.get_datetime_dict_from_unix_time(int(t))
	return int(d.year) * 12 + int(d.month) - 1

func hour_id(t: float = -1.0) -> int:
	if t < 0:
		t = now()
	return int(floor(t / 3600.0))

func secs_to_next_day() -> float:
	return 86400.0 - fmod(now(), 86400.0)

func secs_to_next_week() -> float:
	var day_in_week := (day_id() + 3) % 7
	return (6 - day_in_week) * 86400.0 + secs_to_next_day()

## Seconds until the 1st of next month, 00:00 (same basis as month_id).
func secs_to_next_month() -> float:
	var d := Time.get_datetime_dict_from_unix_time(int(now()))
	var y := int(d.year) + (1 if int(d.month) == 12 else 0)
	var mo := 1 if int(d.month) == 12 else int(d.month) + 1
	var t := Time.get_unix_time_from_datetime_dict({"year": y, "month": mo, "day": 1, "hour": 0, "minute": 0, "second": 0})
	return max(0.0, float(t) - now())

# ---------------------------------------------------------------- rewards
## Reward objects are Dictionaries with key "k" (kind) plus kind-specific fields:
##  credits/trinium/pitCoin/pxp/energy/battery/heist/brawl/royal/xpBoost/xpBoostMinor/raidTicket/merits {n}
##  contract/stimm/warlord {r, n}   firmware {lv, n}   deeds/metabolic {align, tier, n}
##  gear/implant {rank, r, n}       gearSet {rank, set?, r?}   implantSet {rank, r?}   neon {rank, n}
##  mf {tier, n}   cache {name, n}  ranges use {min, max} instead of n.
var _re_cache := {}

func _re(p: String) -> RegEx:
	if not _re_cache.has(p):
		_re_cache[p] = RegEx.create_from_string("(?i)^" + p + "$")
	return _re_cache[p]

func _m(p: String, s: String) -> RegExMatch:
	return _re(p).search(s)

func _amount(s: String) -> int:
	s = s.replace(",", "").strip_edges()
	var mult := 1.0
	if s.ends_with("k") or s.ends_with("K"):
		mult = 1e3
		s = s.substr(0, s.length() - 1)
	elif s.ends_with("m") or s.ends_with("M"):
		mult = 1e6
		s = s.substr(0, s.length() - 1)
	return int(round(float(s.strip_edges()) * mult))

const RAR_ABBR := {"uc": "uncommon", "u": "uncommon", "r": "rare", "e": "epic", "l": "legendary"}

func parse_one(raw: String):
	var s := raw.strip_edges().trim_suffix(".").strip_edges()
	if s.is_empty():
		return null
	var n := 1
	var m := _m("(\\d+)\\s*x\\s+(.*)", s)
	if m == null:
		m = _m("(\\d+)x((?:UC|R|E|L) Contracts?)", s)
	if m:
		n = int(m.get_string(1))
		s = m.get_string(2)
	m = _m("([\\d.,]+\\s*[km]?)\\s*-\\s*([\\d.,]+\\s*[km]?)\\s*Credits", s)
	if m:
		var hi := m.get_string(2)
		var lo := m.get_string(1)
		if not (lo.to_lower().ends_with("k") or lo.to_lower().ends_with("m")):
			lo += hi.substr(hi.length() - 1)
		return {"k": "credits", "min": _amount(lo), "max": _amount(hi)}
	m = _m("([\\d.,]+\\s*[km]?)\\s*Credits", s)
	if m: return {"k": "credits", "n": _amount(m.get_string(1)) * n}
	m = _m("(\\d+)\\s+Trinium", s)
	if m: return {"k": "trinium", "n": int(m.get_string(1)) * n}
	m = _m("(\\d+)\\s+Pit Coin", s)
	if m: return {"k": "pitCoin", "n": int(m.get_string(1)) * n}
	m = _m("(\\d+)\\s+XP", s)
	if m: return {"k": "pxp", "n": int(m.get_string(1)) * n}
	m = _m("(\\d+)\\s+Energy", s)
	if m: return {"k": "energy", "n": int(m.get_string(1)) * n}
	if _m("Energy( Battery)?", s): return {"k": "battery", "n": n}
	m = _m("(\\d+)\\s+Heist Plans?", s)
	if m: return {"k": "heist", "n": int(m.get_string(1))}
	if _m("Heist Plans?", s): return {"k": "heist", "n": n}
	m = _m("(?:(\\d+)\\s*x?\\s*)?Pit Brawl Invites", s)
	if m: return {"k": "brawl", "n": (int(m.get_string(1)) if m.get_string(1) != "" else 1) * n}
	m = _m("(?:(\\d+)\\s*x?\\s*)?Pit Royal Invites", s)
	if m: return {"k": "royal", "n": (int(m.get_string(1)) if m.get_string(1) != "" else 1) * n}
	if _m("(100% )?XP Boost", s): return {"k": "xpBoost", "n": n}
	if _m("10% XP Boost", s): return {"k": "xpBoostMinor", "n": n}
	m = _m("(\\d+)?\\s*x?\\s*(UC|R|E|L)\\s+Contracts?", s)
	if m: return {"k": "contract", "r": RAR_ABBR[m.get_string(2).to_lower()], "n": (int(m.get_string(1)) if m.get_string(1) != "" else 1) * n}
	m = _m("(?:(\\d+)\\s+)?(Uncommon|Rare|Epic|Legendary)\\s+Contracts?", s)
	if m: return {"k": "contract", "r": m.get_string(2).to_lower(), "n": (int(m.get_string(1)) if m.get_string(1) != "" else 1) * n}
	m = _m("(\\d+)\\s*-\\s*(\\d+)x\\s+(Rare|Epic|Legendary) Contracts", s)
	if m: return {"k": "contract", "r": m.get_string(3).to_lower(), "min": int(m.get_string(1)), "max": int(m.get_string(2))}
	m = _m("(\\d+)\\s*-\\s*(\\d+)x\\s+(Rare|Epic|Legendary) Stimm", s)
	if m: return {"k": "stimm", "r": m.get_string(3).to_lower(), "min": int(m.get_string(1)), "max": int(m.get_string(2))}
	m = _m("(Uncommon|Rare|Epic|Legendary) Stimm", s)
	if m: return {"k": "stimm", "r": m.get_string(1).to_lower(), "n": n}
	m = _m("(?:(\\d+)\\s+)?(?:Lvl|Rank|Level)\\s*(\\d)\\s+Firmware", s)
	if m: return {"k": "firmware", "lv": int(m.get_string(2)), "n": (int(m.get_string(1)) if m.get_string(1) != "" else 1) * n}
	m = _m("Firmware lvl (\\d)", s)
	if m: return {"k": "firmware", "lv": int(m.get_string(1)), "n": n}
	if _m("\\d*L Warlord", s): return {"k": "warlord", "r": "legendary", "n": n}
	m = _m("(?:Set |Specified )?(Common|Uncommon|Rare|Epic|Legendary) Warlord", s)
	if m: return {"k": "warlord", "r": m.get_string(1).to_lower(), "n": n}
	m = _m("Generic (Minor|Major|Grand) Deeds", s)
	if m: return {"k": "deeds", "align": "generic", "tier": m.get_string(1).to_lower(), "n": n}
	m = _m("(\\d+)\\s+(Paragon|Neutral|Renegade|Generic)?\\s*(Minor|Major|Grand)\\s*(?:Deeds)?", s)
	if m: return {"k": "deeds", "align": (m.get_string(2).to_lower() if m.get_string(2) != "" else "generic"), "tier": m.get_string(3).to_lower(), "n": int(m.get_string(1))}
	m = _m("Rank (\\d) (Common|Uncommon|Rare|Epic|Legendary) (Equipment|Implants?)", s)
	if m: return {"k": ("implant" if m.get_string(3).to_lower().begins_with("implant") else "gear"), "rank": int(m.get_string(1)), "r": m.get_string(2).to_lower(), "n": n}
	m = _m("(Common|Uncommon|Rare|Epic|Legendary) T(\\d) (Gear Piece|Implant)", s)
	if m: return {"k": ("implant" if m.get_string(3).to_lower() == "implant" else "gear"), "rank": int(m.get_string(2)), "r": m.get_string(1).to_lower(), "n": n}
	m = _m("Tier (\\d) Memory Fragments", s)
	if m: return {"k": "mf", "tier": int(m.get_string(1)), "n": n}
	m = _m("(?:Full )?Set of Rank (\\d) (Legendary )?(Equipment|Implants|Neons)", s)
	if m:
		var kind := m.get_string(3).to_lower()
		if kind == "neons":
			return {"k": "neon", "rank": int(m.get_string(1)), "n": 6 * n}
		return {"k": ("gearSet" if kind == "equipment" else "implantSet"), "rank": int(m.get_string(1)), "r": ("legendary" if m.get_string(2) != "" else ""), "n": n}
	m = _m("Gear Set: Rank (\\d) (.+)", s)
	if m:
		var set_name := m.get_string(2).strip_edges()
		if set_name == "Crit Chance": set_name = "Critical Chance"
		if set_name == "Crit Damage": set_name = "Critical Damage"
		return {"k": "gearSet", "rank": int(m.get_string(1)), "set": set_name, "n": n}
	m = _m("(\\d+)\\s+Assorted Rank (\\d) Neons", s)
	if m: return {"k": "neon", "rank": int(m.get_string(2)), "n": int(m.get_string(1))}
	m = _m("(Meager|Substantial|Sublime|Exalted) Cache", s)
	if m: return {"k": "cache", "name": cap(m.get_string(1).to_lower()) + " Cache", "n": n}
	if _m("Raid Boss Ticket", s): return {"k": "raidTicket", "n": n}
	m = _m("(\\d+)\\s+Merits", s)
	if m: return {"k": "merits", "n": int(m.get_string(1))}
	return {"k": "unknown", "text": raw.strip_edges()}

## Parse a GDD reward line (comma / full-stop separated) into reward Dictionaries.
func parse_rewards(text: String) -> Array:
	if text.strip_edges() == "" or text == "N/A":
		return []
	var commas := RegEx.create_from_string("(\\d),(\\d{3})")
	var s := commas.sub(commas.sub(text, "$1$2", true), "$1$2", true)
	var bundle := _m("(\\d+) (Rare|Epic|Uncommon), (\\d+) (Rare|Epic|Legendary), (\\d+) (Legendary|Epic) Contracts(.*)", s)
	if bundle:
		s = "%s %s Contracts, %s %s Contracts, %s %s Contracts%s" % [bundle.get_string(1), bundle.get_string(2), bundle.get_string(3), bundle.get_string(4), bundle.get_string(5), bundle.get_string(6), bundle.get_string(7)]
	var parts: Array = []
	for chunk in s.split(","):
		for piece in RegEx.create_from_string("\\.\\s+").sub(chunk, "|", true).split("|"):
			var p: String = piece.strip_edges()
			if p != "":
				parts.append(p)
	var out: Array = []
	for p in parts:
		var r = parse_one(p)
		if r != null:
			out.append(r)
	return out

func rarity_name(r: String) -> String:
	return cap(r)

func reward_label(r: Dictionary) -> String:
	var n = r.get("n", 1)
	var ns := str(n)
	if r.has("min") and r.k != "credits":
		ns = "%d-%d" % [r.min, r.max]
	match r.k:
		"credits":
			if r.has("min"):
				return "%s-%s Credits" % [fmt(r.min), fmt(r.max)]
			return fmt(n) + " Credits"
		"trinium": return ns + " Trinium"
		"pitCoin": return ns + " Pit Coin"
		"pxp": return ns + " Player XP"
		"energy": return ns + " Energy"
		"battery": return ns + "x Energy Battery"
		"heist": return ns + "x Heist Plan"
		"brawl": return ns + "x Brawl Invite"
		"royal": return ns + "x Royal Invite"
		"xpBoost": return ns + "x 100% XP Boost"
		"xpBoostMinor": return ns + "x 10% XP Boost"
		"contract": return ns + "x " + cap(r.r) + " Contract"
		"stimm": return ns + "x " + cap(r.r) + " Stimm"
		"firmware": return ns + "x Mk %d Firmware" % r.lv
		"warlord": return ns + "x " + cap(r.r) + " Warlord"
		"deeds": return ns + "x " + cap(r.align) + " " + cap(r.tier) + " Deeds"
		"metabolic": return ns + "x " + cap(r.align) + " " + cap(r.tier) + " Metabolic"
		"gear": return ns + "x Rank %d %sEquipment" % [r.rank, (cap(r.r) + " ") if r.get("r", "") != "" else ""]
		"implant": return ns + "x Rank %d %sImplant" % [r.rank, (cap(r.r) + " ") if r.get("r", "") != "" else ""]
		"mf": return ns + "x Tier %d Memory Fragments" % r.tier
		"gearSet": return "Set of Rank %d %s%sEquipment" % [r.rank, (cap(r.r) + " ") if String(r.get("r", "")) != "" else "", (r.set + " ") if r.get("set", "") != "" else ""]
		"implantSet": return "Set of Rank %d %sImplants" % [r.rank, (cap(r.r) + " ") if String(r.get("r", "")) != "" else ""]
		"neon": return ns + "x Rank %d Neon" % r.rank
		"cache": return ns + "x " + r.name
		"raidTicket": return ns + "x Raid Boss Ticket"
		"merits": return ns + " Merits"
		"unknown": return r.text
	return str(r)

## Plain-text fallback glyphs (no emoji-presentation codepoints). UI art goes through UI.reward_node.
const REWARD_ICON := {
	"credits": "¢", "trinium": "◆", "pitCoin": "◉", "pxp": "★", "energy": "ϟ", "battery": "ϟ", "heist": "▤",
	"brawl": "▭", "royal": "▭", "xpBoost": "⇮", "xpBoostMinor": "⇮", "contract": "▣", "stimm": "✚", "firmware": "▥",
	"warlord": "☻", "deeds": "▦", "metabolic": "⬡", "gear": "◈", "implant": "◎", "mf": "✺", "gearSet": "◈",
	"implantSet": "◎", "neon": "✦", "cache": "▩", "raidTicket": "▧", "merits": "✪", "unknown": "?",
}

func reward_icon(r: Dictionary) -> String:
	return REWARD_ICON.get(r.k, "?")

func rewards_text(list: Array) -> String:
	var parts: Array = []
	for r in list:
		parts.append(reward_label(r))
	return ", ".join(parts)
