extends Node
## Game state, persistence and every non-combat rule (progression, economy, timers, missions).

signal changed
signal toast(text: String, color: Color)
## Emitted once per player level gained (after the rewards are mailed).
signal player_leveled(level: int, rewards: Array)

const SAVE_PATH := "user://neon_warlords_save.json"
const SAVE_VERSION := 1

var S: Dictionary = {}
var save_path := SAVE_PATH
var _dirty := false
var _tick_acc := 0.0

func _ready() -> void:
	if OS.get_cmdline_user_args().has("--nwtest"):
		# NW_SAVE=<name> gives parallel test runs their own save
		var tag := OS.get_environment("NW_SAVE")
		save_path = "user://test_save.json" if tag == "" else "user://test_save_%s.json" % tag
	if not load_game():
		S = {}

func _process(delta: float) -> void:
	if S.is_empty():
		return
	_tick_acc += delta
	if _tick_acc >= 1.0:
		_tick_acc = 0.0
		tick()
		if _dirty:
			save_game()

func has_save() -> bool:
	return not S.is_empty()

# ================================================================ persistence
func new_game(player_name: String) -> void:
	var t := U.now()
	S = {
		"v": SAVE_VERSION, "created": t, "name": player_name, "tutorial_done": false, "ftue": 0, "seen_unlocks": [],
		"player": {"level": 1, "xp": 0},
		"cur": {"credits": 50000, "trinium": 300, "energy": Data.ENERGY_CAP, "energy_t": t, "pitCoin": 0, "brawl": 10, "royal": 10,
			"heist": Data.HEIST_DAILY, "bounty": Data.BOUNTY_DAILY, "raidTicket": 0},
		"items": {
			"contract": {"uncommon": 5, "rare": 1, "epic": 0, "legendary": 0},
			"scrap": {"uncommon": 0, "rare": 0, "epic": 0, "legendary": 0},
			"stimm": {"uncommon": 0, "rare": 0, "epic": 0, "legendary": 0},
			"firmware": {"1": 0, "2": 0, "3": 0, "4": 0, "5": 0},
			"mf": {"1": 100, "2": 0, "3": 0},
			"deeds": _align_tiers(), "metabolic": _align_tiers(),
			"battery": 1, "xpBoost": 1, "xpBoostMinor": 0,
			"cache": {"Meager Cache": 0, "Substantial Cache": 0, "Sublime Cache": 0, "Exalted Cache": 0},
		},
		"xp_boost_until": 0.0, "xp_minor_until": 0.0,
		"roster": [], "equip": [], "neons": [],
		"squads": {"last": [], "pit_brawl": [], "pit_royal": []},
		"campaign": {"stars": {}, "claimed": [[], [], []]},
		"hideouts": {},
		"sw": {"stars": {}, "claimed": []},
		"pit": {"brawl": _pit_mode(), "royal": _pit_mode(), "week": U.week_id(), "last_def": t},
		"bm": {},
		"plaza": {"hour": -1, "items": [], "bought": []},
		"safehouse": {"paragon": {}, "neutral": {}, "renegade": {}},
		"stocks": {"stored": 0.0, "t": t, "cap_bonus": 0},
		"login": {"day": -1, "progress": 0, "claimed": false},
		"jobs": {"day": U.day_id(), "week": U.week_id(), "month": U.month_id(), "c": {"daily": {}, "weekly": {}, "monthly": {}}, "claimed": {"daily": [], "weekly": [], "monthly": []}},
		"amb": {"claimed": {}},
		"bp": {"season": -1, "merits": 0, "premium": false, "claimed_free": [], "claimed_paid": [], "day": -1, "week": -1, "daily": [], "weekly": [], "dc": {}, "wc": {}, "dclaimed": [], "wclaimed": [], "dbonus": false, "wbonus": false},
		"stats": {},
		"gang": {},
		"inbox": [],
		"day": U.day_id(), "week": U.week_id(),
		"shop_bought": {},
		"settings": {"speed": 1, "auto": false, "free_iap": true, "music": true},
		"campaign_rot": U.day_id(),
	}
	# starter gang: the ragtag crew from the mission statement
	for id in ["brother_grin", "scrapjaw", "intern7", "kage9", "abbot_mayhem"]:
		add_warlord(id, true)
	S.squads.last = S.roster.map(func(w): return w.uid).slice(0, Data.TEAM_SIZE)
	S.squads.pit_brawl = S.squads.last.duplicate()
	S.squads.pit_royal = S.squads.last.duplicate()
	var welcome := {"id": U.uid(), "title": "Welcome to the City, Warlord", "body": "Your ragtag crew needs gear. Fight through the gangs of the city, recruit companions and climb the Pit.", "rewards": [{"k": "credits", "n": 100000}, {"k": "contract", "r": "rare", "n": 2}, {"k": "gearSet", "rank": 2, "set": "Health", "r": "uncommon"}], "claimed": false, "t": t}
	S.inbox.append(welcome)
	grant_starter_kit()
	# dev builds: show off the first finished model on every new account (not in tests or release builds)
	if OS.is_debug_build() and not OS.get_cmdline_user_args().has("--nwtest"):
		add_warlord("deacon_chainz")
	_init_gang()
	tick()
	save_game()

## Every new account: enough loot to try gear, implants, neons, upgrades, reputation, neuronet and abilities.
func grant_starter_kit() -> void:
	var r := func(set_name: String, rank: int, rar: String) -> void:
		for slot in Data.GEAR_SLOTS:
			add_equipment(make_equipment(slot, rank, rar, set_name))
	r.call("Speed", 3, "rare")
	r.call("Firepower", 3, "rare")
	r.call("Health", 2, "uncommon")
	for slot in Data.IMPLANT_SLOTS:
		add_equipment(make_equipment(slot, 3, "rare"))
	for i in 8:
		add_neon(U.ri(2, 3))
	add_item(["stimm", "rare"], 3)
	add_item(["firmware", "1"], 2)
	add_item(["mf", "1"], 400)
	add_item(["mf", "2"], 150)
	for al in ["paragon", "neutral", "renegade", "generic"]:
		add_item(["deeds", al, "minor"], 10)
		add_item(["metabolic", al, "minor"], 3)
	add_item(["contract", "rare"], 2)
	for e in S.equip:
		e.new = false

## Settings > Developer: a big pile of everything for testing every system.
func grant_test_kit() -> Array:
	var shown: Array = []
	add_cur("credits", 5000000)
	add_cur("trinium", 5000)
	add_cur("pitCoin", 20000)
	add_cur("energy", 500)
	add_cur("heist", 5)
	add_cur("bounty", 12)
	add_cur("raidTicket", 3)
	var sets := ["Speed", "Firepower", "Critical Damage", "Energy Drain", "Stitcher", "Ripper", "Armour", "Hacking"]
	var i := 0
	for sn in sets:
		var rank := 4 + (i % 3)
		var rar: String = ["rare", "epic", "legendary"][i % 3]
		for slot in Data.GEAR_SLOTS:
			add_equipment(make_equipment(slot, rank, rar, sn))
		i += 1
	for k in 2:
		for slot in Data.IMPLANT_SLOTS:
			add_equipment(make_equipment(slot, 5 + k, ["epic", "legendary"][k]))
	for n in 24:
		add_neon(U.ri(4, 6))
	add_item(["stimm", "rare"], 5)
	add_item(["stimm", "epic"], 3)
	add_item(["stimm", "legendary"], 2)
	for lv in range(1, 6):
		add_item(["firmware", lv], 3)
	add_item(["mf", "1"], 1500)
	add_item(["mf", "2"], 900)
	add_item(["mf", "3"], 600)
	for al in ["paragon", "neutral", "renegade", "generic"]:
		add_item(["deeds", al, "minor"], 30)
		add_item(["deeds", al, "major"], 15)
		add_item(["deeds", al, "grand"], 8)
		add_item(["metabolic", al, "minor"], 10)
		add_item(["metabolic", al, "major"], 5)
		add_item(["metabolic", al, "grand"], 2)
	add_item(["contract", "rare"], 10)
	add_item(["contract", "epic"], 3)
	add_item(["contract", "legendary"], 1)
	add_item(["xpBoost"], 3)
	add_item(["battery"], 5)
	for id in ["redd_skullfire", "raiden_x"]:
		var w := add_warlord(id)
		w.level = 30
	for k in 8:
		add_warlord(U.pick(Warlords.by_rarity("common")))
	shown.append({"label": "5M Credits, 5000 Trinium, 20K Pit Coin, 500 Energy", "icon": "¢", "color": Color.WHITE})
	shown.append({"label": "8 full gear sets (R4-R6), 6 implants, 24 neons", "icon": "⚔", "color": Data.RARITY_COLOR.legendary})
	shown.append({"label": "Stimms, Firmware Mk1-5, Memory Fragments, Deeds, Metabolics", "icon": "✚", "color": Data.RARITY_COLOR.epic})
	shown.append({"label": "14 contracts, 2 legendary + 8 common Warlords", "icon": "☻", "color": Data.RARITY_COLOR.rare})
	mark()
	return shown

func _align_tiers() -> Dictionary:
	var d := {}
	for a in ["paragon", "neutral", "renegade", "generic"]:
		d[a] = {"minor": 0, "major": 0, "grand": 0}
	return d

func _pit_mode() -> Dictionary:
	return {"points": 100, "wins": 0, "losses": 0, "opps": [], "opps_t": 0.0, "log": []}

func save_game() -> void:
	if S.is_empty():
		return
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(S))
	_dirty = false

func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var f := FileAccess.open(save_path, FileAccess.READ)
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY or int(d.get("v", 0)) != SAVE_VERSION:
		return false
	S = d
	_fix_types()
	return true

## JSON turns every number into a float; restore ints where code relies on them.
func _fix_types() -> void:
	for w in S.roster:
		for k in ["level", "xp", "rank", "rep"]:
			w[k] = int(w[k])
		for k in w.ab:
			w.ab[k] = int(w.ab[k])
		for k in w.nn:
			w.nn[k] = int(w.nn[k])
			# skills capped at 1 point (GDD): refund any extra point
			if Data.NN_BY_ID.has(k) and w.nn[k] > int(Data.NN_BY_ID[k].max):
				var cost: Array = Data.NN_COST[Data.NN_BY_ID[k].layer]
				add_item(["mf", cost[0]], cost[1] * (w.nn[k] - int(Data.NN_BY_ID[k].max)))
				w.nn[k] = int(Data.NN_BY_ID[k].max)
		if Warlords.T.has(w.tpl):
			for a in tpl(w).abilities:
				if w.ab.has(a.id):
					w.ab[a.id] = mini(int(w.ab[a.id]), Data.ability_max_level(a))
	for e in S.equip:
		for k in ["rank", "level"]:
			e[k] = int(e[k])
	for n in S.neons:
		n.rank = int(n.rank)
	S.player.level = int(S.player.level)
	if not S.stocks.has("cap_bonus"):
		S.stocks.cap_bonus = 0
	if not S.gang.is_empty() and not S.gang.has("motd"):
		S.gang.motd = ""
	if S.player.level > Data.GDD.playerLevels.size():
		S.player.level = Data.GDD.playerLevels.size()
		S.player.maxed = true
		S.player.xp = 0

func reset_save() -> void:
	S = {}
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func mark() -> void:
	_dirty = true
	changed.emit()

func say(text: String, color := Color("#29e3ff")) -> void:
	toast.emit(text, color)

# ================================================================ timers / resets
func tick() -> void:
	var t := U.now()
	var c: Dictionary = S.cur
	# energy regen
	if c.energy < Data.ENERGY_CAP:
		var gained := int((t - c.energy_t) / Data.ENERGY_REGEN_SECS)
		if gained > 0:
			c.energy = min(Data.ENERGY_CAP, c.energy + gained)
			c.energy_t += gained * Data.ENERGY_REGEN_SECS
			_dirty = true
	else:
		c.energy_t = t
	# daily reset
	var day := U.day_id()
	if day != int(S.day):
		S.day = day
		# daily refresh tops up to the cap (5 plans, 12 tokens); rewards and purchases may overflow it
		c.heist = max(int(c.heist), Data.HEIST_DAILY)
		c.bounty = max(int(c.bounty), Data.BOUNTY_DAILY)
		c.brawl = max(c.brawl, Data.PIT_CAP)
		c.royal = max(c.royal, Data.PIT_CAP)
		_daily_gang()
		_dirty = true
	# weekly pit rewards
	var wk := U.week_id()
	if wk != int(S.week):
		_weekly_pit_rewards()
		S.week = wk
		_dirty = true
	_check_job_periods()
	_check_bp()
	_check_login()
	# trinium stocks accumulate
	var lv := stocks_level()
	if lv > 0:
		var st: Dictionary = S.stocks
		var per_sec: float = Data.STOCKS[lv].daily / 86400.0
		st.stored = min(float(stocks_cap()), st.stored + (t - st.t) * per_sec)
	S.stocks.t = t
	_simulate_pit_defense()
	changed.emit()

# ================================================================ currencies
# ---------------------------------------------------------------- feature unlocks
func feature_level(id: String) -> int:
	return int(Data.FEATURE_UNLOCK.get(id, 0))

func feature_ok(id: String) -> bool:
	return S.is_empty() or int(S.player.level) >= feature_level(id)

## Features unlocked since the player last saw the announcement (marks them seen).
func take_new_unlocks() -> Array:
	if S.is_empty():
		return []
	if not S.has("seen_unlocks"):
		S.seen_unlocks = Data.FEATURE_INFO.keys().filter(func(k): return feature_ok(k))
		return []
	var out: Array = []
	for k in Data.FEATURE_INFO:
		if feature_ok(k) and not S.seen_unlocks.has(k):
			S.seen_unlocks.append(k)
			out.append(k)
	if not out.is_empty():
		mark()
	return out

func cur(k: String) -> int:
	return int(S.cur.get(k, 0))

func can_afford(k: String, n: int) -> bool:
	return cur(k) >= n

func spend(k: String, n: int) -> bool:
	if cur(k) < n:
		return false
	S.cur[k] = cur(k) - n
	if k == "energy":
		add_pxp(n)
		if cur("energy") < Data.ENERGY_CAP and S.cur.energy_t < U.now() - Data.ENERGY_REGEN_SECS:
			S.cur.energy_t = U.now()
	if k == "credits":
		track("spendCredits", n)
	mark()
	return true

## Caps (energy 160, heist 5, bounty 12, invites 10) only stop regen and the daily refresh (see tick);
## rewards and purchases may overflow them, RAID-style (user decision).
func add_cur(k: String, n: int) -> void:
	S.cur[k] = cur(k) + n
	mark()

func item_count(path: Array) -> int:
	var d = S.items
	for p in path:
		d = d.get(str(p), 0) if d is Dictionary else 0
	return int(d)

func add_item(path: Array, n: int) -> void:
	var d: Dictionary = S.items
	for i in range(path.size() - 1):
		d = d[str(path[i])]
	var key := str(path[path.size() - 1])
	d[key] = int(d.get(key, 0)) + n
	mark()

func xp_mult() -> float:
	var m := 1.0
	if S.xp_boost_until > U.now():
		m += 1.0
	if S.xp_minor_until > U.now():
		m += 0.1
	return m

func use_xp_boost(minor := false) -> bool:
	var key := "xpBoostMinor" if minor else "xpBoost"
	if item_count([key]) <= 0:
		return false
	add_item([key], -1)
	var field := "xp_minor_until" if minor else "xp_boost_until"
	S[field] = max(float(S[field]), U.now()) + 86400.0
	say("XP Boost active for 24h")
	return true

func use_battery() -> bool:
	if item_count(["battery"]) <= 0:
		return false
	add_item(["battery"], -1)
	S.cur.energy = cur("energy") + 100
	say("+100 Energy", Color("#ffd42a"))
	mark()
	return true

# ================================================================ player level
## XP still needed for the next level-up row; 0 once the player is maxed.
func pxp_needed() -> int:
	if S.player.get("maxed", false):
		return 0
	var lv: int = S.player.level
	var tbl: Array = Data.GDD.playerLevels
	if lv > tbl.size():
		return 0
	return int(tbl[lv - 1][1])

## Reaching level L+1 grants row L. The GDD table has 100 levels: row 100's XP is a final
## "max level" milestone that grants its rewards while the level stays at 100 (S.player.maxed).
func add_pxp(n: int) -> void:
	var p: Dictionary = S.player
	if p.get("maxed", false):
		return
	var top: int = Data.GDD.playerLevels.size()
	p.xp = int(p.xp) + n
	while not p.get("maxed", false) and pxp_needed() > 0 and p.xp >= pxp_needed():
		p.xp -= pxp_needed()
		var row: Array = Data.GDD.playerLevels[p.level - 1]
		if p.level >= top:
			p.maxed = true
			p.xp = 0
		else:
			p.level += 1
		S.cur.energy = max(cur("energy"), Data.ENERGY_CAP)
		# the row's "1x Energy" is this full refill, not an extra battery
		var rewards := U.parse_rewards(row[2]).filter(func(r): return r.k != "battery")
		if S.get("double_rewards", false):
			rewards = rewards + rewards.duplicate(true)
		var title := "Max Player Level" if p.get("maxed", false) else "Player Level %d" % p.level
		send_mail(title, "You reached %s. Energy refilled (1x Energy)!%s" % [title.to_lower()," (Double Rewards)" if S.get("double_rewards", false) else ""], rewards)
		say("MAX PLAYER LEVEL!" if p.get("maxed", false) else "PLAYER LEVEL UP! %d" % p.level, Color("#ffb627"))
		player_leveled.emit(int(p.level), rewards)
	mark()

## Stocks level 1-3: level 1 from the start, then one level per claimed tier-completion ambition.
func stocks_level() -> int:
	var lv := 1
	for i in range(2, Data.STOCK_LEVEL_AMBITION.size()):
		if _tier_ambition_claimed(Data.STOCK_LEVEL_AMBITION[i][0], int(Data.STOCK_LEVEL_AMBITION[i][1])):
			lv = i
		else:
			break
	return lv

## What unlocks stocks level i, for display.
func stocks_level_req(i: int) -> String:
	var req = Data.STOCK_LEVEL_AMBITION[i]
	if req == null:
		return "unlocked from the start"
	return "unlocked by Complete All Tier %d %s Ambitions" % [int(req[1]), req[0]]

## Stocks cap for the current level plus any bought cap upgrades (S.stocks.cap_bonus).
func stocks_cap() -> int:
	return int(Data.STOCKS[stocks_level()].cap) + int(S.stocks.get("cap_bonus", 0))

## Buy one Stocks cap upgrade (+STOCKS_CAP_STEP, at most STOCKS_CAP_BUYS times). Payment is the caller's.
## Returns an error text, or "".
func buy_stocks_cap() -> String:
	var bonus := int(S.stocks.get("cap_bonus", 0))
	if bonus >= Data.STOCKS_CAP_STEP * Data.STOCKS_CAP_BUYS:
		return "The Stocks vault is fully upgraded."
	S.stocks.cap_bonus = bonus + Data.STOCKS_CAP_STEP
	say("Stocks cap +%d" % Data.STOCKS_CAP_STEP, Color("#ffd42a"))
	mark()
	return ""

func _tier_ambition_claimed(cat: String, tier: int) -> bool:
	var claimed: Array = S.amb.claimed.get(cat, [])
	for row in Data.GDD.ambitions.get(cat, []):
		if int(row[0]) == tier and String(row[2]).to_lower().begins_with("complete all tier"):
			return claimed.has("%d-%d" % [int(row[0]), int(row[1])])
	return false

func collect_stocks() -> int:
	var n := int(floor(S.stocks.stored))
	if n <= 0:
		return 0
	S.stocks.stored -= n
	add_cur("trinium", n)
	say("+%d Trinium" % n, Color("#29e3ff"))
	return n

# ================================================================ inbox
func send_mail(title: String, body: String, rewards: Array) -> void:
	S.inbox.push_front({"id": U.uid(), "title": title, "body": body, "rewards": rewards, "claimed": rewards.is_empty(), "t": U.now()})
	if S.inbox.size() > 60:
		S.inbox.resize(60)
	mark()

func claim_mail(m: Dictionary) -> Array:
	if m.claimed:
		return []
	m.claimed = true
	return grant(m.rewards)

func unclaimed_mail() -> int:
	return S.inbox.filter(func(m): return not m.claimed).size()

# ================================================================ warlords
func add_warlord(tpl_id: String, silent := false) -> Dictionary:
	var t: Dictionary = Warlords.get_t(tpl_id)
	var ab := {}
	for a in t.abilities:
		ab[a.id] = 1
	var w := {"uid": U.uid(), "tpl": tpl_id, "level": 1, "xp": 0, "rank": Data.RANK_START[t.rarity], "rep": 0,
		"ab": ab, "nn": {}, "gear": {}, "locked": false, "new": not silent, "t": U.now()}
	S.roster.append(w)
	stat_add("recruited", 1)
	mark()
	return w

func wl(uid: String):
	for w in S.roster:
		if w.uid == uid:
			return w
	return null

func tpl(w: Dictionary) -> Dictionary:
	return Warlords.get_t(w.tpl)

func max_level(w: Dictionary) -> int:
	return Data.max_level(w.rank)

func add_wxp(w: Dictionary, amount: int) -> int:
	var cap := max_level(w)
	var gained_levels := 0
	if w.level >= cap:
		return 0
	w.xp = int(w.xp) + amount
	while w.level < cap and w.xp >= Data.xp_to_next(w.level, w.rank):
		w.xp -= Data.xp_to_next(w.level, w.rank)
		w.level += 1
		gained_levels += 1
	if w.level >= cap:
		w.xp = 0
	if gained_levels > 0:
		track("warlordLevel", gained_levels)
	mark()
	return gained_levels

func can_rank_up(w: Dictionary) -> bool:
	return w.rank < Data.MAX_RANK and w.level >= max_level(w)

## Consume `fodder` (uids of Warlords at the same rank) plus `firmware` Mk-N chips (N = current rank)
## to raise the rank. Each chip stands in for one Warlord (Rank screen design).
func rank_up(w: Dictionary, fodder: Array, firmware := 0) -> String:
	if not can_rank_up(w):
		return "Warlord must be max level for their rank."
	if fodder.size() + firmware != w.rank:
		return "Requires %d x Rank %d Warlords or Mk %d Firmware." % [w.rank, w.rank, w.rank]
	if firmware > 0 and (w.rank > 5 or item_count(["firmware", w.rank]) < firmware):
		return "Not enough Mk %d Firmware." % w.rank
	for u in fodder:
		var f = wl(u)
		if f == null or f.uid == w.uid or f.rank != w.rank or f.locked or in_any_squad(u):
			return "Invalid fodder selected."
	for u in fodder:
		_remove_warlord(u)
	if firmware > 0:
		add_item(["firmware", w.rank], -firmware)
	w.rank += 1
	stat_add("consumed", fodder.size())
	track("rankUp", 1)
	if w.rank >= 3: track("rankTo3", 1)
	if w.rank >= 4: track("rankUp4", 1)
	if w.rank >= 5:
		track("rankTo5", 1)
		track("rankUp5", 1)
	mark()
	return ""

func feed_xp_value(f: Dictionary) -> int:
	var ri := Data.rarity_idx(tpl(f).rarity)
	return 400 * (1 + ri) * (1 + ri) * int(f.level)

## Level screen: consume up to 6 Warlords for XP. Their gear returns to the inventory.
func feed_xp(w: Dictionary, fodder: Array) -> String:
	if w.level >= max_level(w):
		return "Warlord is max level for their rank."
	var total := 0
	for u in fodder:
		var f = wl(u)
		if f == null or f.uid == w.uid or f.locked or in_any_squad(u):
			return "Invalid Warlord selected."
		total += feed_xp_value(f)
	for u in fodder:
		_remove_warlord(u)
	stat_add("consumed", fodder.size())
	add_wxp(w, total)
	say("+%s XP" % U.fmt(total), Color("#9b5cff"))
	return ""

func _remove_warlord(uid: String) -> void:
	var w = wl(uid)
	if w == null:
		return
	for slot in w.gear.keys():
		var it = eq(w.gear[slot])
		if it:
			it.owner = ""
	S.roster.erase(w)
	for k in S.squads:
		S.squads[k].erase(uid)

func in_any_squad(uid: String) -> bool:
	return S.squads.pit_brawl.has(uid) or S.squads.pit_royal.has(uid)

## Feed a duplicate (same template) to raise abilities by 3 levels (the chosen ability first).
func feed_duplicate(w: Dictionary, dup_uid: String, ability_id := "") -> String:
	var d = wl(dup_uid)
	if d == null or d.tpl != w.tpl or d.uid == w.uid:
		return "Requires a duplicate of the same Warlord."
	if d.locked or in_any_squad(dup_uid):
		return "That duplicate is locked or defending in the Pit."
	var levels := 0
	for i in 3:
		var options: Array = []
		for a in tpl(w).abilities:
			if w.ab[a.id] < Data.ability_max_level(a):
				options.append(a.id)
		if options.is_empty():
			break
		var pickid = ability_id if options.has(ability_id) else U.pick(options)
		w.ab[pickid] += 1
		levels += 1
	if levels == 0:
		return "All abilities are already maxed."
	_remove_warlord(dup_uid)
	stat_add("consumed", 1)
	mark()
	return ""

func use_stimm(w: Dictionary, ability_id: String, stimm_r: String) -> String:
	var t := tpl(w)
	if Data.rarity_idx(stimm_r) < Data.rarity_idx(t.rarity):
		return "Requires a %s or higher Stimm." % U.cap(t.rarity)
	if item_count(["stimm", stimm_r]) <= 0:
		return "No %s Stimm." % U.cap(stimm_r)
	var ab = null
	for a in t.abilities:
		if a.id == ability_id:
			ab = a
	if ab == null or w.ab[ability_id] >= Data.ability_max_level(ab):
		return "Ability is max level."
	add_item(["stimm", stimm_r], -1)
	w.ab[ability_id] += 1
	mark()
	return ""

func rep_cost(w: Dictionary) -> Array:
	var t := tpl(w)
	if w.rep >= 6:
		return []
	return Data.rep_table(t.rarity)[w.rep]

func can_rep_up(w: Dictionary) -> String:
	if w.rep >= w.rank:
		return "Reputation is capped at the Warlord's rank (%d)." % w.rank
	if w.rep >= 6:
		return "Max reputation."
	var cost := rep_cost(w)
	var align: String = tpl(w).align
	for tier in cost[0]:
		if item_count(["deeds", align, tier]) < cost[0][tier]:
			return "Not enough %s %s Deeds." % [U.cap(align), U.cap(tier)]
	for tier in cost[1]:
		if item_count(["deeds", "generic", tier]) < cost[1][tier]:
			return "Not enough Generic %s Deeds." % U.cap(tier)
	return ""

func rep_up(w: Dictionary) -> String:
	var err := can_rep_up(w)
	if err != "":
		return err
	var cost := rep_cost(w)
	var align: String = tpl(w).align
	for tier in cost[0]:
		add_item(["deeds", align, tier], -cost[0][tier])
	for tier in cost[1]:
		add_item(["deeds", "generic", tier], -cost[1][tier])
	w.rep += 1
	track("repUp", 1)
	mark()
	return ""

func use_metabolic(w: Dictionary, align: String, tier: String) -> String:
	if item_count(["metabolic", align, tier]) <= 0:
		return "No metabolics of that type."
	if w.level >= max_level(w):
		return "Warlord is max level for their rank."
	add_item(["metabolic", align, tier], -1)
	var xp: float = Data.METABOLIC_XP[tier]
	if align == tpl(w).align:
		xp *= 1.0 + Data.METABOLIC_ALIGN_BONUS
	add_wxp(w, int(xp))
	return ""

# ---------------- neuronet
func nn_layer_points(w: Dictionary, layer: int) -> int:
	var n := 0
	for id in w.nn:
		if Data.NN_BY_ID[id].layer == layer:
			n += int(w.nn[id])
	return n

func nn_can(w: Dictionary, skill_id: String) -> String:
	var sk: Dictionary = Data.NN_BY_ID[skill_id]
	var layer: int = sk.layer
	if int(w.nn.get(skill_id, 0)) >= int(sk.get("max", 2)):
		return "Skill is maxed."
	if layer > 1 and nn_layer_points(w, layer - 1) < 2:
		return "Spend 2 points in synapse layer %d first." % (layer - 1)
	if nn_layer_points(w, layer) >= Data.NN_POINTS_PER_LAYER:
		return "This synapse layer is full (4 points)."
	var pair: Array = Data.NEURONET[sk.career][layer - 1]
	for other in pair:
		if other.id != skill_id and int(w.nn.get(other.id, 0)) > 0:
			return "Only 1 of the 2 skills per career can be chosen in each layer."
	var cost: Array = Data.NN_COST[layer]
	if item_count(["mf", cost[0]]) < cost[1]:
		return "Requires %d x Tier %d Memory Fragments." % [cost[1], cost[0]]
	return ""

func nn_add(w: Dictionary, skill_id: String) -> String:
	var err := nn_can(w, skill_id)
	if err != "":
		return err
	var cost: Array = Data.NN_COST[Data.NN_BY_ID[skill_id].layer]
	add_item(["mf", cost[0]], -cost[1])
	w.nn[skill_id] = int(w.nn.get(skill_id, 0)) + 1
	mark()
	return ""

const NN_RESET_COST := 100

func nn_reset(w: Dictionary) -> String:
	if w.nn.is_empty():
		return "Nothing to reset."
	if not spend("trinium", NN_RESET_COST):
		return "Requires %d Trinium." % NN_RESET_COST
	for id in w.nn:
		var cost: Array = Data.NN_COST[Data.NN_BY_ID[id].layer]
		add_item(["mf", cost[0]], cost[1] * int(w.nn[id]))
	w.nn = {}
	mark()
	return ""

# ---------------- stats
## Full out-of-combat stats for a warlord instance (player-owned or an enemy dict
## of the same shape). Leader auras and buffs are applied by the battle.
func compute_stats(w: Dictionary, enemy_bonus := 0.0) -> Dictionary:
	var t: Dictionary = Warlords.get_t(w.tpl)
	var b: Dictionary = t.base
	var sc: Array = Data.SCALING[t.cls][t.rarity]
	var lvl_f := func(pct: float) -> float: return 1.0 + pct / 100.0 * (float(w.level) - 1.0) / 59.0
	var rank_f := func(pct: float) -> float: return 1.0 + pct / 100.0 * (float(w.rank) - 1.0) / 5.0
	var rep_f: float = 1.0 + float(w.rep) * float(sc[6]) / 100.0
	var base := {
		"hp": b.hp * lvl_f.call(sc[0]) * rank_f.call(sc[3]) * rep_f,
		"arm": b.arm * lvl_f.call(sc[1]) * rank_f.call(sc[4]) * rep_f,
		"fp": b.fp * lvl_f.call(sc[2]) * rank_f.call(sc[5]) * rep_f,
		"spd": float(b.spd), "cc": float(b.cc), "cd": float(b.cd), "hack": float(b.hack), "fw": float(b.fw),
	}
	if enemy_bonus > 0.0:
		for k in ["hp", "arm", "fp"]:
			base[k] *= 1.0 + enemy_bonus
		base.spd += 4.0 * (w.rank - 1)
		base.hack += 8.0 * (w.rank - 1)
		base.fw += 6.0 * (w.rank - 1)
	var flat := {"hp": 0.0, "arm": 0.0, "fp": 0.0, "spd": 0.0, "cc": 0.0, "cd": 0.0, "hack": 0.0, "fw": 0.0}
	var pct := {"hp": 0.0, "arm": 0.0, "fp": 0.0, "spd": 0.0}
	var sets := {}
	var add_stat := func(stat: String, v: float) -> void:
		match stat:
			"hpP": pct.hp += v
			"armP": pct.arm += v
			"fpP": pct.fp += v
			"spdP": pct.spd += v
			_: flat[stat] += v
	for slot in w.get("gear", {}):
		var it = eq(w.gear[slot])
		if it == null:
			continue
		add_stat.call(it.pri.stat, Data.primary_value(it.pri.stat, it.rank, it.level))
		for s in it.subs:
			add_stat.call(s.stat, float(s.val) + float(s.get("neon", 0)))
		if it.get("set", "") != "":
			sets[it.set] = int(sets.get(it.set, 0)) + 1
	for sname in sets:
		var sd: Dictionary = Data.SETS[sname]
		if sd.has("stat"):
			var times := int(sets[sname] / sd.pieces)
			for st in sd.stat:
				add_stat.call(st, sd.stat[st] * times)
	# passive stat abilities
	for a in t.abilities:
		if a.type == "passive" and a.has("stats"):
			var lvm := 1.0 + Data.ABILITY_LEVEL_BONUS * (int(w.ab.get(a.id, 1)) - 1)
			for st in a.stats:
				add_stat.call(st, a.stats[st] * lvm)
	# neuronet stat skills
	var nn: Dictionary = w.get("nn", {})
	var nv := func(id: String) -> float:
		var p := int(nn.get(id, 0))
		return 0.0 if p == 0 else float(Data.NN_BY_ID[id].v[p - 1])
	add_stat.call("cc", nv.call("precision"))
	add_stat.call("fpP", nv.call("munitions"))
	add_stat.call("cd", nv.call("forceMeasure"))
	add_stat.call("armP", nv.call("plating") + nv.call("galvanized"))
	add_stat.call("hpP", nv.call("fitness"))
	add_stat.call("hack", nv.call("malware") + nv.call("ransomware"))
	add_stat.call("fw", nv.call("monitoring") + nv.call("encrypt"))
	# safehouse (player warlords only)
	if enemy_bonus <= 0.0 and S.has("safehouse"):
		var sh: Dictionary = S.safehouse.get(t.align, {})
		for node in sh:
			var lv := int(sh[node])
			if lv <= 0:
				continue
			if node in ["hack", "fw"]:
				add_stat.call(node, Data.SAFEHOUSE_FLAT[lv])
			else:
				add_stat.call(node, Data.SAFEHOUSE_PCT[lv])
	var out := {
		"hp": round(base.hp * (1.0 + pct.hp / 100.0) + flat.hp),
		"arm": round(base.arm * (1.0 + pct.arm / 100.0) + flat.arm),
		"fp": round(base.fp * (1.0 + pct.fp / 100.0) + flat.fp),
		"spd": round(base.spd * (1.0 + pct.spd / 100.0) + flat.spd),
		"cc": min(100.0, base.cc + flat.cc), "cd": base.cd + flat.cd,
		"hack": round(base.hack + flat.hack), "fw": round(base.fw + flat.fw),
		"sets": sets,
	}
	return out

func power(w: Dictionary) -> int:
	var s := compute_stats(w)
	var abl := 0
	for k in w.ab:
		abl += int(w.ab[k])
	# reputation is already in the stats; ability levels raise damage, so they scale power a little
	return int(Data.stat_power(tpl(w).cls, s) * (1.0 + 0.01 * abl))

func team_power(uids: Array) -> int:
	var p := 0
	for u in uids:
		var w = wl(u)
		if w:
			p += power(w)
	return p

# ================================================================ equipment
func eq(uid) -> Variant:
	if uid == null or str(uid) == "":
		return null
	for e in S.equip:
		if e.uid == uid:
			return e
	return null

func make_equipment(slot: String, rank: int, rarity: String, set_name := "") -> Dictionary:
	var implant := slot in Data.IMPLANT_SLOTS
	var ss: Dictionary = Data.SLOT_STATS[slot]
	var pri: String = U.pick(ss.pri)
	if not implant and set_name == "":
		set_name = U.pick(Data.SETS.keys())
	var it := {"uid": U.uid(), "kind": "implant" if implant else "gear", "slot": slot, "set": "" if implant else set_name,
		"rank": rank, "rarity": rarity, "level": 0, "pri": {"stat": pri}, "subs": [], "owner": "", "locked": false, "new": true}
	for i in Data.SUBS_BY_RARITY[rarity]:
		_add_sub(it)
	return it

func _add_sub(it: Dictionary) -> void:
	var used := [it.pri.stat]
	for s in it.subs:
		used.append(s.stat)
	var opts: Array = Data.SLOT_STATS[it.slot].sub.filter(func(s): return not used.has(s))
	if opts.is_empty():
		return
	var st: String = U.pick(opts)
	it.subs.append({"stat": st, "val": Data.SUBSTAT[st][it.rank], "rolls": 0, "neon": 0})

func add_equipment(it: Dictionary) -> Dictionary:
	S.equip.append(it)
	_check_equipment_ambitions(it)
	mark()
	return it

func gen_equipment(kind: String, rank: int, rarity: String, set_name := "", slot := "") -> Dictionary:
	if slot == "":
		slot = U.pick(Data.IMPLANT_SLOTS if kind == "implant" else Data.GEAR_SLOTS)
	return add_equipment(make_equipment(slot, rank, rarity, set_name))

func equip_level_up(it: Dictionary, free := false) -> String:
	if it.level >= Data.MAX_EQUIP_LEVEL:
		return "Max level."
	var cost := Data.equip_level_cost(it.rank, it.level)
	if not free and not spend("credits", cost):
		return "Requires %s Credits." % U.fmt(cost)
	it.level += 1
	if it.level % 5 == 0:
		if it.subs.size() < 4:
			_add_sub(it)
		elif not it.subs.is_empty():
			var s: Dictionary = U.pick(it.subs)
			s.val = float(s.val) + Data.SUBSTAT[s.stat][it.rank]
			s.rolls = int(s.rolls) + 1
	for thr in [4, 8, 12, 16]:
		if it.level == thr:
			track("equip%d" % thr, 1)
			stat_add("equip_to_%d" % thr, 1)
	mark()
	return ""

func apply_firmware(it: Dictionary, lv: int) -> String:
	if item_count(["firmware", lv]) <= 0:
		return "No Lvl %d Firmware." % lv
	if it.level >= Data.MAX_EQUIP_LEVEL:
		return "Equipment is max level."
	add_item(["firmware", lv], -1)
	for i in lv:
		if it.level < Data.MAX_EQUIP_LEVEL:
			equip_level_up(it, true)
	return ""

func equip_sell_value(it: Dictionary) -> int:
	var v: int = 1000 * int(it.rank) * (1 + Data.rarity_idx(it.rarity))
	for l in it.level:
		v += Data.equip_level_cost(it.rank, l) / 2
	return v

func sell_equipment(it: Dictionary) -> String:
	if it.locked:
		return "Item is locked."
	if it.owner != "":
		unequip(it)
	S.equip.erase(it)
	add_cur("credits", equip_sell_value(it))
	stat_add("sold", 1)
	return ""

func equip_on(w: Dictionary, it: Dictionary) -> String:
	if it.kind == "implant" and w.rep < Data.IMPLANT_UNLOCK[it.slot]:
		return "%s implant slot unlocks at Reputation %d." % [U.cap(it.slot), Data.IMPLANT_UNLOCK[it.slot]]
	if it.owner != "":
		unequip(it)
	var old = eq(w.gear.get(it.slot, ""))
	if old:
		old.owner = ""
	w.gear[it.slot] = it.uid
	it.owner = w.uid
	it.new = false
	mark()
	return ""

## Stat weights per class for gear scoring (what each role cares about).
const CLASS_WEIGHTS := {
	"armour": {"arm": 3.0, "hp": 0.25, "fp": 0.6, "spd": 6.0, "cc": 1.0, "cd": 0.8, "hack": 0.3, "fw": 0.6},
	"firepower": {"fp": 3.0, "hp": 0.2, "arm": 0.8, "spd": 6.0, "cc": 3.0, "cd": 2.0, "hack": 0.2, "fw": 0.4},
	"modder": {"hp": 0.4, "arm": 1.0, "fp": 0.8, "spd": 8.0, "cc": 0.8, "cd": 0.6, "hack": 0.3, "fw": 0.8},
	"hacker": {"hack": 2.2, "fp": 1.6, "hp": 0.2, "arm": 0.8, "spd": 7.0, "cc": 1.5, "cd": 1.0, "fw": 0.5},
}

## Weighted value of a stat block for a warlord's class.
func stat_score(w: Dictionary, s: Dictionary) -> float:
	var wts: Dictionary = CLASS_WEIGHTS[tpl(w).cls]
	var v := 0.0
	for k in wts:
		v += float(s.get(k, 0)) * wts[k]
	return v

## Stats this warlord would have with `it` equipped (nothing is changed).
func stats_with(w: Dictionary, it) -> Dictionary:
	var sim: Dictionary = w.duplicate(true)
	if it != null:
		sim.gear[it.slot] = it.uid
	return compute_stats(sim)

## Stat changes from equipping `it` on `w`: {stat: delta}.
func equip_delta(w: Dictionary, it: Dictionary) -> Dictionary:
	var now_s := compute_stats(w)
	var then_s := stats_with(w, it)
	var d := {}
	for k in ["hp", "arm", "fp", "spd", "cc", "cd", "hack", "fw"]:
		var diff: float = float(then_s[k]) - float(now_s[k])
		if abs(diff) > 0.01:
			d[k] = diff
	return d

## Equip the best available piece in every unlocked slot (unequipped items or items already on this warlord).
## Greedy per slot on the class-weighted score of the resulting full stats, so set bonuses count.
func auto_equip(w: Dictionary) -> int:
	var changed := 0
	for pass_i in 2:   # second pass lets set bonuses settle
		for slot in Data.ALL_SLOTS:
			if slot in Data.IMPLANT_SLOTS and w.rep < Data.IMPLANT_UNLOCK[slot]:
				continue
			var cur = eq(w.gear.get(slot, ""))
			var best = cur
			var best_score := stat_score(w, compute_stats(w))
			for it in S.equip:
				if it.slot != slot or (it.owner != "" and it.owner != w.uid) or it == cur:
					continue
				var sc := stat_score(w, stats_with(w, it))
				if sc > best_score + 0.01:
					best_score = sc
					best = it
			if best != null and best != cur:
				equip_on(w, best)
				changed += 1
	return changed

func unequip_all(w: Dictionary) -> void:
	for slot in w.gear.keys():
		var it = eq(w.gear[slot])
		if it:
			unequip(it)

func neon_sell_value(n: Dictionary) -> int:
	return 1500 * int(n.rank) * int(n.rank)

func sell_neon(n: Dictionary) -> void:
	S.neons.erase(n)
	add_cur("credits", neon_sell_value(n))

func unequip(it: Dictionary) -> void:
	var w = wl(it.owner)
	if w:
		w.gear.erase(it.slot)
	it.owner = ""
	mark()

func neon_can(it: Dictionary, neon: Dictionary) -> String:
	if it.rank < neon.rank:
		return "Neons only fit equipment of the same or higher rank."
	for s in it.subs:
		if s.stat == neon.stat:
			if int(s.get("neon", 0)) > 0:
				return "That substat already has a Neon."
			return ""
	return "Equipment has no %s substat." % Data.STATS[neon.stat].name

func apply_neon(it: Dictionary, neon: Dictionary) -> String:
	var err := neon_can(it, neon)
	if err != "":
		return err
	for s in it.subs:
		if s.stat == neon.stat:
			s.neon = Data.SUBSTAT[neon.stat][neon.rank]
	S.neons.erase(neon)
	mark()
	return ""

func add_neon(rank: int, stat := "") -> Dictionary:
	if stat == "":
		stat = U.pick(Data.NEON_STATS)
	var n := {"uid": U.uid(), "rank": rank, "stat": stat}
	S.neons.append(n)
	return n

func _check_equipment_ambitions(it: Dictionary) -> void:
	var key := "%s|%s|%s" % [it.set, it.slot, it.pri.stat]
	var seen: Dictionary = S.stats.get("eq_seen", {})
	seen[key] = true
	S.stats["eq_seen"] = seen

# ================================================================ contracts
func open_contract(r: String) -> Variant:
	if item_count(["contract", r]) <= 0:
		return null
	add_item(["contract", r], -1)
	var rar: String = U.weighted(Data.CONTRACT_RATES[r])
	var w := add_warlord(U.pick(Warlords.by_rarity(rar)))
	track("recruit", 1)
	return w

func break_down(w: Dictionary) -> String:
	if w.locked:
		return "Warlord is locked."
	if in_any_squad(w.uid):
		return "Warlord is assigned to a Pit defence gang."
	if S.roster.size() <= 5:
		return "You need at least 5 Warlords."
	var t := tpl(w)
	var sr: String = Data.SCRAP_FOR[t.rarity]
	var n := U.ri(1, 2)
	_remove_warlord(w.uid)
	add_item(["scrap", sr], n)
	stat_add("consumed", 1)
	var made := 0
	while item_count(["scrap", sr]) >= Data.SCRAP_TO_CONTRACT:
		add_item(["scrap", sr], -Data.SCRAP_TO_CONTRACT)
		add_item(["contract", sr], 1)
		made += 1
	say("+%d %s scrap%s" % [n, U.cap(sr), (" — assembled %d contract!" % made) if made > 0 else ""])
	return ""

# ================================================================ rewards
## Grant a list of reward dictionaries. Returns display entries {label, icon, color, ref}.
func grant(list: Array) -> Array:
	var out: Array = []
	for r0 in list:
		var r: Dictionary = r0.duplicate(true)
		var n := int(r.get("n", 1))
		if r.has("min"):
			n = U.ri(int(r.min), int(r.max))
			if r.k == "credits":
				n = int(round(U.ri(int(r.min) / 1000, int(r.max) / 1000) * 1000))
			r.n = n
			r.erase("min")
			r.erase("max")
		var col := Color.WHITE
		match r.k:
			"credits", "trinium", "pitCoin", "heist", "brawl", "royal", "raidTicket", "energy":
				var k: String = r.k
				add_cur(k, n)
			"pxp": add_pxp(n)
			"battery": add_item(["battery"], n)
			"xpBoost": add_item(["xpBoost"], n)
			"xpBoostMinor": add_item(["xpBoostMinor"], n)
			"contract":
				add_item(["contract", r.r], n)
				col = Data.RARITY_COLOR[r.r]
			"stimm":
				add_item(["stimm", r.r], n)
				col = Data.RARITY_COLOR[r.r]
			"firmware": add_item(["firmware", r.lv], n)
			"mf": add_item(["mf", r.tier], n)
			"deeds":
				add_item(["deeds", r.align, r.tier], n)
				stat_add("deeds_%s_%s" % [r.align, r.tier], n)
				col = Data.ALIGN_COLOR[r.align]
			"metabolic": add_item(["metabolic", r.align, r.tier], n)
			"merits": bp_add_merits(n)
			"cache": add_item(["cache", r.name], n)
			"warlord":
				for i in n:
					var w := add_warlord(U.pick(Warlords.by_rarity(r.r)))
					out.append({"label": tpl(w).name, "icon": "☻", "color": Data.RARITY_COLOR[r.r], "warlord": w.uid})
				continue
			"gear", "implant":
				for i in n:
					var rar: String = r.get("r", "")
					if rar == "": rar = U.pick(["rare", "epic"])
					var it := gen_equipment(r.k, int(r.rank), rar, r.get("set", ""), r.get("slot", ""))
					out.append({"label": equip_name(it), "icon": Data.SLOT_ICON[it.slot], "color": Data.RARITY_COLOR[rar], "equip": it.uid})
				continue
			"gearSet":
				var set_name: String = r.get("set", "")
				if set_name == "": set_name = U.pick(Data.SETS.keys())
				var rar2: String = r.get("r", "")
				for slot in Data.GEAR_SLOTS:
					var rr: String = rar2 if rar2 != "" else U.weighted({"rare": 50, "epic": 40, "legendary": 10})
					var it2 := add_equipment(make_equipment(slot, int(r.rank), rr, set_name))
					out.append({"label": equip_name(it2), "icon": Data.SLOT_ICON[slot], "color": Data.RARITY_COLOR[rr], "equip": it2.uid})
				continue
			"implantSet":
				var rar3: String = r.get("r", "")
				for slot in Data.IMPLANT_SLOTS:
					var rr3: String = rar3 if rar3 != "" else U.weighted({"rare": 50, "epic": 40, "legendary": 10})
					var it3 := add_equipment(make_equipment(slot, int(r.rank), rr3))
					out.append({"label": equip_name(it3), "icon": Data.SLOT_ICON[slot], "color": Data.RARITY_COLOR[rr3], "equip": it3.uid})
				continue
			"neon":
				for i in n:
					var ne := add_neon(int(r.rank), r.get("stat", ""))
					out.append({"label": "Rank %d %s Neon" % [ne.rank, Data.STATS[ne.stat].name], "icon": "✦", "color": Color("#ff2e88")})
				continue
			"unknown":
				pass
		out.append({"label": U.reward_label(r), "icon": U.reward_icon(r), "color": col})
	mark()
	return out

func equip_name(it: Dictionary) -> String:
	if it.kind == "implant":
		return "R%d %s %s Implant" % [it.rank, U.cap(it.rarity), U.cap(it.slot)]
	return "R%d %s %s" % [it.rank, it.set, U.cap(it.slot)]

func open_cache(cname: String) -> Array:
	if item_count(["cache", cname]) <= 0:
		return []
	add_item(["cache", cname], -1)
	var rewards: Array = []
	for row in Data.GDD.caches[cname]:
		var text: String = row[0]
		var ch := float(row[1])
		if ch < 1.5:
			ch *= 100.0
		if not U.chance(ch):
			continue
		var m := RegEx.create_from_string("6x Random Set, Rank (\\d)(?:-(\\d))?, (\\w+)(?:-(\\w+))? Equipment").search(text)
		if m:
			var lo := int(m.get_string(1))
			var hi := int(m.get_string(2)) if m.get_string(2) != "" else lo
			var rlo := Data.rarity_idx(m.get_string(3).to_lower())
			var rhi := Data.rarity_idx(m.get_string(4).to_lower()) if m.get_string(4) != "" else rlo
			var set_name: String = U.pick(Data.SETS.keys())
			var res: Array = []
			for slot in Data.GEAR_SLOTS:
				var it := add_equipment(make_equipment(slot, U.ri(lo, hi), Data.RARITIES[U.ri(rlo, rhi)], set_name))
				res.append({"label": equip_name(it), "icon": Data.SLOT_ICON[slot], "color": Data.RARITY_COLOR[it.rarity], "equip": it.uid})
			rewards.append_array(res)
			continue
		var parsed := U.parse_rewards(text.replace("Contracts", "Contracts").replace("1x Meager", "1x Meager"))
		rewards.append_array(grant(parsed))
	return rewards

# ================================================================ tracking: counters, jobs, ambitions
func stat_add(key: String, n: int) -> void:
	S.stats[key] = int(S.stats.get(key, 0)) + n

func stat(key: String) -> int:
	return int(S.stats.get(key, 0))

func track(ev: String, n := 1) -> void:
	for p in ["daily", "weekly", "monthly"]:
		S.jobs.c[p][ev] = int(S.jobs.c[p].get(ev, 0)) + n
	if S.bp.season >= 0:
		S.bp.dc[ev] = int(S.bp.dc.get(ev, 0)) + n
		S.bp.wc[ev] = int(S.bp.wc.get(ev, 0)) + n
	stat_add("ev_" + ev, n)

func _check_job_periods() -> void:
	var j: Dictionary = S.jobs
	if int(j.day) != U.day_id():
		j.day = U.day_id()
		j.c.daily = {}
		j.claimed.daily = []
	if int(j.week) != U.week_id():
		j.week = U.week_id()
		j.c.weekly = {}
		j.claimed.weekly = []
	if int(j.month) != U.month_id():
		j.month = U.month_id()
		j.c.monthly = {}
		j.claimed.monthly = []

func jobs_list(period: String) -> Array:
	var out: Array = []
	var defs: Array = Data.JOB_DEFS[period]
	var gdd: Array = Data.GDD.jobs[period]
	for i in defs.size():
		var ev: String = defs[i][0]
		var target: int = defs[i][1]
		var cur_v := 0
		if ev.begins_with("all"):
			cur_v = S.jobs.claimed[period].filter(func(x): return int(x) != defs.size() - 1).size()
		else:
			cur_v = int(S.jobs.c[period].get(ev, 0))
		out.append({"i": i, "text": gdd[i][0], "rewards": U.parse_rewards(gdd[i][1]), "cur": min(cur_v, target), "target": target,
			"claimed": S.jobs.claimed[period].has(i) or S.jobs.claimed[period].has(float(i))})
	return out

func claim_job(period: String, i: int) -> Array:
	var job: Dictionary = jobs_list(period)[i]
	if job.claimed or job.cur < job.target:
		return []
	S.jobs.claimed[period].append(i)
	if i == Data.JOB_DEFS[period].size() - 1 and period == "daily":
		track("dailyAll", 1)
	return grant(job.rewards)

func jobs_claimable() -> int:
	var n := 0
	for p in ["daily", "weekly", "monthly"]:
		for j in jobs_list(p):
			if not j.claimed and j.cur >= j.target:
				n += 1
	return n

## Ambition progress from its GDD description: returns [current, target].
func ambition_progress(cat: String, desc: String) -> Array:
	var m: RegExMatch
	m = RegEx.create_from_string("Complete Den (\\d+):7 on (.+)").search(desc)
	if m:
		var d := Data.DIFFS.find(m.get_string(2).strip_edges())
		return [1 if campaign_stars(d, int(m.get_string(1)) - 1, 6) > 0 else 0, 1]
	m = RegEx.create_from_string("Beat Hideout (.+) Stage (\\d+), (\\d+) Times").search(desc)
	if m:
		var hid := _hideout_id_from_name(m.get_string(1))
		return [hideout_wins_at_or_above(hid, int(m.get_string(2))), int(m.get_string(3))]
	m = RegEx.create_from_string("Gain (.+) Set (\\w+) with (.+) Primary").search(desc)
	if m:
		var set_name := m.get_string(1).replace("HP", "Health").replace("Crit ", "Critical ")
		var pri := _stat_from_name(m.get_string(3))
		var key := "%s|%s|%s" % [set_name, m.get_string(2).to_lower(), pri]
		return [1 if S.stats.get("eq_seen", {}).has(key) else 0, 1]
	m = RegEx.create_from_string("Sell (\\d+) Equipments").search(desc)
	if m: return [stat("sold"), int(m.get_string(1))]
	m = RegEx.create_from_string("Level (\\d+) Equipments to (\\d+)").search(desc)
	if m: return [stat("equip_to_%s" % m.get_string(2)), int(m.get_string(1))]
	m = RegEx.create_from_string("Equip (\\d+) Warlords? with a Full Set").search(desc)
	if m: return [_count_full_set(), int(m.get_string(1))]
	m = RegEx.create_from_string("Equip (?:a|(\\d+)) Warlords? with a (.+) Set").search(desc)
	if m:
		var target := int(m.get_string(1)) if m.get_string(1) != "" else 1
		var set2 := m.get_string(2).replace("HP", "Health").replace("Crit ", "Critical ")
		return [_count_with_set(set2), target]
	m = RegEx.create_from_string("Gain (\\d+) (Minor|Major|Grand) (Paragon|Neutral|Renegade|Generic) Deeds").search(desc)
	if m: return [stat("deeds_%s_%s" % [m.get_string(3).to_lower(), m.get_string(2).to_lower()]), int(m.get_string(1))]
	m = RegEx.create_from_string("Raise a (Paragon|Neutral|Renegade) Warlord's Reputation to (\\d)").search(desc)
	if m:
		var al := m.get_string(1).to_lower()
		var best := 0
		for w in S.roster:
			if tpl(w).align == al:
				best = max(best, w.rep)
		return [min(best, int(m.get_string(2))), int(m.get_string(2))]
	m = RegEx.create_from_string("Recruit (\\d+) Warlords").search(desc)
	if m: return [stat("recruited"), int(m.get_string(1))]
	m = RegEx.create_from_string("Level (\\d+) Warlords to (\\d+)").search(desc)
	if m: return [S.roster.filter(func(w): return w.level >= int(m.get_string(2))).size(), int(m.get_string(1))]
	m = RegEx.create_from_string("Rank (\\d+) Warlords to Rank (\\d)").search(desc)
	if m: return [S.roster.filter(func(w): return w.rank >= int(m.get_string(2))).size(), int(m.get_string(1))]
	m = RegEx.create_from_string("Consume (\\d+) Warlords").search(desc)
	if m: return [stat("consumed"), int(m.get_string(1))]
	m = RegEx.create_from_string("Level an (\\w+) Warlord to (\\d+)").search(desc)
	if m:
		var cls := m.get_string(1).to_lower()
		var best2 := 0
		for w in S.roster:
			if tpl(w).cls == cls:
				best2 = max(best2, w.level)
		return [min(best2, int(m.get_string(2))), int(m.get_string(2))]
	m = RegEx.create_from_string("Deal (\\d+)m Total Damage in Bastions").search(desc)
	if m: return [stat("bastion_dmg") / 1000000, int(m.get_string(1))]
	m = RegEx.create_from_string("Apply (\\d+) Debuffs to a Bastion Boss").search(desc)
	if m: return [stat("bastion_debuffs"), int(m.get_string(1))]
	m = RegEx.create_from_string("Enter (\\d+) Bastion Stages").search(desc)
	if m: return [stat("bastion_entries"), int(m.get_string(1))]
	m = RegEx.create_from_string("Survive (\\d+) Turns Inside a Bastion").search(desc)
	if m: return [stat("bastion_turns_best"), int(m.get_string(1))]
	m = RegEx.create_from_string("Enter (\\d+) Pit Brawls/Royals").search(desc)
	if m: return [stat("pit_entries"), int(m.get_string(1))]
	m = RegEx.create_from_string("Defeat (\\d+) Enemies in The Pit").search(desc)
	if m: return [stat("ev_pitKill"), int(m.get_string(1))]
	m = RegEx.create_from_string("Apply (\\d+) Debuffs in The Pit").search(desc)
	if m: return [stat("pit_debuffs"), int(m.get_string(1))]
	m = RegEx.create_from_string("Purchase a (?:Level (\\d+) )?Safehouse Upgrade").search(desc)
	if m:
		var need := int(m.get_string(1)) if m.get_string(1) != "" else 1
		return [1 if safehouse_max_level() >= need else 0, 1]
	m = RegEx.create_from_string("Complete All Tier (\\d) .+ Ambitions").search(desc)
	if m: return [0, 1]  # resolved in ambitions_list
	return [0, 1]

func _stat_from_name(n: String) -> String:
	n = n.strip_edges()
	var map := {"HP%": "hpP", "Armour%": "armP", "Firepower%": "fpP", "Speed": "spd", "Hacking": "hack", "Firewall": "fw", "Crit Chance%": "cc", "Crit Damage%": "cd"}
	return map.get(n, n)

func _count_with_set(set_name: String) -> int:
	var c := 0
	for w in S.roster:
		var sets: Dictionary = compute_stats(w).sets
		if int(sets.get(set_name, 0)) >= int(Data.SETS[set_name].pieces):
			c += 1
	return c

func _count_full_set() -> int:
	var c := 0
	for w in S.roster:
		var sets: Dictionary = compute_stats(w).sets
		var covered := 0
		for sn in sets:
			covered += int(sets[sn] / Data.SETS[sn].pieces) * int(Data.SETS[sn].pieces)
		if covered >= 6:
			c += 1
	return c

func ambitions_list(cat: String) -> Array:
	var rows: Array = Data.GDD.ambitions[cat]
	var out: Array = []
	var claimed: Array = S.amb.claimed.get(cat, [])
	var tier_done := {}
	for row in rows:
		var key := "%d-%d" % [int(row[0]), int(row[1])]
		var is_claimed := claimed.has(key)
		var prog := ambition_progress(cat, row[2])
		if String(row[2]).begins_with("Complete All Tier") or String(row[2]).begins_with("Complete all Tier"):
			var tier := int(row[0])
			var total := 0
			var got := 0
			for r2 in rows:
				if int(r2[0]) == tier and r2 != row:
					total += 1
					if claimed.has("%d-%d" % [int(r2[0]), int(r2[1])]):
						got += 1
			prog = [got, total]
		out.append({"key": key, "tier": int(row[0]), "text": row[2], "rewards": U.parse_rewards(row[3]), "cur": min(prog[0], prog[1]), "target": prog[1], "claimed": is_claimed})
		if not tier_done.has(int(row[0])):
			tier_done[int(row[0])] = true
		if not is_claimed:
			tier_done[int(row[0])] = false
	# tier gating: tier N+1 visible once tier N fully claimed
	var visible_tier := 1
	while tier_done.get(visible_tier, false):
		visible_tier += 1
	return out.filter(func(a): return a.tier <= visible_tier)

func claim_ambition(cat: String, a: Dictionary) -> Array:
	if a.claimed or a.cur < a.target:
		return []
	if not S.amb.claimed.has(cat):
		S.amb.claimed[cat] = []
	S.amb.claimed[cat].append(a.key)
	return grant(a.rewards)

func ambitions_claimable() -> int:
	var n := 0
	for cat in Data.GDD.ambitions:
		for a in ambitions_list(cat):
			if not a.claimed and a.cur >= a.target:
				n += 1
	return n

# ================================================================ campaign
func campaign_key(d: int, loc: int, st: int) -> String:
	return "%d-%d-%d" % [d, loc, st]

func campaign_stars(d: int, loc: int, st: int) -> int:
	return int(S.campaign.stars.get(campaign_key(d, loc, st), 0))

func campaign_unlocked(d: int, loc: int, st: int) -> bool:
	if d > 0 and campaign_stars(d - 1, 9, 6) == 0:
		return false
	if loc == 0 and st == 0:
		return true
	var pl := loc
	var ps := st - 1
	if ps < 0:
		pl -= 1
		ps = 6
	return campaign_stars(d, pl, ps) > 0

func campaign_total_stars(d: int) -> int:
	var n := 0
	for k in S.campaign.stars:
		if k.begins_with("%d-" % d):
			n += int(S.campaign.stars[k])
	return n

func campaign_record(d: int, loc: int, st: int, stars: int) -> void:
	var k := campaign_key(d, loc, st)
	S.campaign.stars[k] = max(int(S.campaign.stars.get(k, 0)), stars)
	mark()

func claim_campaign_progress(d: int, threshold: int) -> Array:
	var claimed: Array = S.campaign.claimed[d]
	if claimed.has(threshold) or claimed.has(float(threshold)) or campaign_total_stars(d) < threshold:
		return []
	claimed.append(threshold)
	for row in Data.GDD.campaignProgress:
		if int(row[0]) == threshold:
			return grant(U.parse_rewards(row[1 + d]))
	return []

func corpo_tower_set() -> String:
	var opts := Data.SETS.keys()
	return opts[U.day_id() % opts.size()]

# ================================================================ hideouts / syndicate wars
func hideout_state(id: String) -> Dictionary:
	if not S.hideouts.has(id):
		S.hideouts[id] = {"max": 0, "wins": {}}
	return S.hideouts[id]

func hideout_record_win(id: String, stage: int) -> void:
	var h := hideout_state(id)
	h.max = max(int(h.max), stage)
	h.wins[str(stage)] = int(h.wins.get(str(stage), 0)) + 1
	mark()

func hideout_wins_at_or_above(id: String, stage: int) -> int:
	if not S.hideouts.has(id):
		return 0
	var n := 0
	for k in S.hideouts[id].wins:
		if int(k) >= stage:
			n += int(S.hideouts[id].wins[k])
	return n

func _hideout_id_from_name(n: String) -> String:
	n = n.to_lower()
	if n.contains("troll"): return "trolls"
	if n.contains("vulture"): return "vultures"
	if n.contains("tera"): return "teratek"
	if n.contains("viking"): return "vikings"
	if n.contains("synapse"): return "synapse"
	if n.contains("heist"): return "heist"
	if n.contains("chop"): return "chopshop"
	if n.contains("paragon"): return "deeds_paragon"
	if n.contains("neutral"): return "deeds_neutral"
	if n.contains("renegade"): return "deeds_renegade"
	return "deeds_generic"

func sw_stars(syn: String, stage: int) -> int:
	return int(S.sw.stars.get("%s-%d" % [syn, stage], 0))

func sw_record(syn: String, stage: int, stars: int) -> void:
	var k := "%s-%d" % [syn, stage]
	S.sw.stars[k] = max(int(S.sw.stars.get(k, 0)), stars)
	mark()

func sw_total_stars() -> int:
	var n := 0
	for k in S.sw.stars:
		n += int(S.sw.stars[k])
	return n

func claim_sw_progress(threshold: int) -> Array:
	if S.sw.claimed.has(threshold) or S.sw.claimed.has(float(threshold)) or sw_total_stars() < threshold:
		return []
	S.sw.claimed.append(threshold)
	for row in Data.GDD.swProgress:
		if int(row[0]) == threshold:
			return grant(U.parse_rewards(row[1]))
	return []

# ================================================================ pit
func pit_tier(points: int) -> int:
	var tier := 1
	for row in Data.GDD.pitTiers:
		if points >= int(row[2]):
			tier = int(row[0])
	return tier

func pit_tier_row(points: int) -> Array:
	return Data.GDD.pitTiers[pit_tier(points) - 1]

func pit_record(mode: String, won: bool, opp: Dictionary) -> Array:
	var p: Dictionary = S.pit[mode]
	var row := pit_tier_row(int(p.points))
	var rewards: Array = []
	stat_add("pit_entries", 1)
	if mode == "brawl":
		track("pitBrawl", 1)
	if won:
		p.wins = int(p.wins) + 1
		p.points = int(p.points) + 10
		var m := RegEx.create_from_string("(\\d+)k Credits, (\\d+) Pit Coin").search(row[4])
		rewards = [{"k": "credits", "n": int(m.get_string(1)) * 1000}, {"k": "pitCoin", "n": int(m.get_string(2))}]
		p.log.push_front({"t": U.now(), "txt": "Beat %s (+10 pts)" % opp.name, "win": true})
	else:
		# GDD: ranking is only lost when your *defence* is beaten; a failed attack just costs the invite
		p.losses = int(p.losses) + 1
		p.log.push_front({"t": U.now(), "txt": "Lost to %s (no points lost)" % opp.name, "win": false})
	if p.log.size() > 30:
		p.log.resize(30)
	p.opps = p.opps.filter(func(o): return o.id != opp.id)
	mark()
	return grant(rewards)

func _simulate_pit_defense() -> void:
	var pit: Dictionary = S.pit
	var t := U.now()
	var hours := (t - float(pit.last_def)) / 3600.0
	if hours < 4.0:
		return
	var attacks: int = mini(4, int(hours / 4.0))
	pit.last_def = t
	for mode in ["brawl", "royal"]:
		var p: Dictionary = pit[mode]
		# Royal defends with 4 starters + 3 reinforcements
		var defenders: Array = S.squads["pit_" + mode].filter(func(u): return wl(u) != null).slice(0, 7 if mode == "royal" else 4)
		if defenders.is_empty():
			continue
		for i in attacks:
			if not U.chance(35):
				continue
			var tier := pit_tier(int(p.points))
			var name := Content.random_player_name()
			if not _defence_battle(mode, defenders, tier):
				var loss := Data.pit_loss(tier)
				p.points = max(0, int(p.points) - loss)
				p.log.push_front({"t": t, "txt": "Defence lost vs %s (-%d pts)" % [name, loss], "win": false})
			else:
				p.log.push_front({"t": t, "txt": "Defence held vs %s" % name, "win": true})
		if p.log.size() > 30:
			p.log.resize(30)
	_dirty = true

## An attacker from the player's bracket fights the defence squad (the defenders play as side 1).
## Attackers are generated like Pit opponents, a little stronger in higher brackets. Returns true if the defence held.
func _defence_battle(mode: String, defenders: Array, tier: int) -> bool:
	# borrow an attacker from the bracket without replacing the opponent list the player sees
	var p: Dictionary = S.pit[mode]
	var shown: Array = p.opps
	var shown_t = p.get("opps_t", 0.0)
	var opps: Array = Content.pit_opponents(mode)
	p.opps = shown
	p.opps_t = shown_t
	if opps.is_empty():
		return true
	var opp: Dictionary = opps[U.ri(0, opps.size() - 1)]
	var k := float(opp.get("k", 1.0)) * (0.82 + 0.015 * tier)
	var attackers: Array = []
	for m in opp.team.slice(0, 4):
		attackers.append(Content._pit_unit(m, k, 0))
	var defs: Array = Content.player_units(defenders.slice(0, 4))
	for u in defs:
		u.side = 1
	var opts := {"turn_limit": 0}
	if mode == "royal":
		var att_reinf: Array = []
		for m in opp.team.slice(4, 7):
			att_reinf.append(Content._pit_unit(m, k, 0))
		var def_reinf: Array = Content.player_units(defenders.slice(4, 7))
		for u in def_reinf:
			u.side = 1
		opts.merge({"reinforcements": att_reinf, "enemy_reinforcements": def_reinf, "no_revive": true})
	opts["seed"] = U.rng.randi()   # off-screen sim rolls on the account RNG (repeatable in seeded tests)
	var b := Battle.new()
	b.setup(attackers, [defs], opts)
	b.simulate()
	return b.result != "win"

func _weekly_pit_rewards() -> void:
	for mode in ["brawl", "royal"]:
		var row := pit_tier_row(int(S.pit[mode].points))
		send_mail("Pit %s weekly rewards" % U.cap(mode), "Bracket: %s. Spend Pit Coin in the Black Market and Safehouse." % row[1], U.parse_rewards(row[3]))

# ================================================================ black market / plaza / safehouse / shop
func bm_period_key(reset: String) -> String:
	if reset == "Daily": return "d%d" % U.day_id()
	if reset == "Weekly": return "w%d" % U.week_id()
	return "always"

func bm_can_buy(i: int) -> String:
	var row: Array = Data.GDD.blackMarket[i]
	var key := bm_period_key(row[2])
	if key != "always" and S.bm.get(str(i), "") == key:
		return "Sold out until reset."
	if cur("pitCoin") < int(row[1]):
		return "Not enough Pit Coin."
	return ""

func bm_buy(i: int) -> Array:
	if bm_can_buy(i) != "":
		return []
	var row: Array = Data.GDD.blackMarket[i]
	spend("pitCoin", int(row[1]))
	var key := bm_period_key(row[2])
	if key != "always":
		S.bm[str(i)] = key
	return grant(U.parse_rewards(row[0]))

func plaza_items() -> Array:
	var h := U.hour_id()
	if int(S.plaza.hour) != h:
		S.plaza.hour = h
		var r := RandomNumberGenerator.new()
		r.seed = h
		var pool := Data.PLAZA_POOL.duplicate()
		var items: Array = []
		for i in 6:
			var idx := r.randi_range(0, pool.size() - 1)
			var item: Dictionary = pool[idx].duplicate(true)
			pool.remove_at(idx)
			# gear/implants: the slot and set are fixed when the stock rolls, so the card shows what you buy
			if item.r.k in ["gear", "implant"]:
				var slots: Array = Data.IMPLANT_SLOTS if item.r.k == "implant" else Data.GEAR_SLOTS
				item.r.slot = slots[r.randi_range(0, slots.size() - 1)]
				if item.r.k == "gear":
					var sets: Array = Data.SETS.keys()
					item.r.set = sets[r.randi_range(0, sets.size() - 1)]
			items.append(item)
		S.plaza.items = items
		S.plaza.bought = []
	return S.plaza.items

## `hour` is the stock hour the screen showed; a stale screen can't buy from the new stock.
func plaza_buy(i: int, hour: int = -1) -> Array:
	if hour >= 0 and hour != U.hour_id():
		say("The Plaza restocked", Color("#ffd42a"))
		return []
	var items := plaza_items()
	if S.plaza.bought.has(i) or S.plaza.bought.has(float(i)):
		return []
	var it: Dictionary = items[i]
	if not spend("credits", int(it.cost)):
		say("Not enough credits", Color.RED)
		return []
	S.plaza.bought.append(i)
	track("plazaBuy", 1)
	return grant([it.r])

func safehouse_level(align: String, node: String) -> int:
	return int(S.safehouse[align].get(node, 0))

func safehouse_upgrade(align: String, node: String) -> String:
	var lv := safehouse_level(align, node)
	if lv >= 10:
		return "Max level."
	var cost: int = Data.SAFEHOUSE_COST[lv + 1]
	if not spend("pitCoin", cost):
		return "Requires %d Pit Coin." % cost
	S.safehouse[align][node] = lv + 1
	mark()
	return ""

func safehouse_max_level() -> int:
	var m := 0
	for a in S.safehouse:
		for n in S.safehouse[a]:
			m = max(m, int(S.safehouse[a][n]))
	return m

## Purchase-limit key: Trinium Market limits (the Pit refills) reset daily; pack limits are lifetime.
func shop_limit_key(section: String, i: int) -> String:
	if section == "Trinium Market":
		return "%s|%d|d%d" % [section, i, U.day_id()]
	return "%s|%d" % [section, i]

## How many of a shop row were bought within its limit period.
func shop_bought_count(section: String, i: int) -> int:
	return int(S.shop_bought.get(shop_limit_key(section, i), 0))

func shop_buy(section: String, i: int) -> Array:
	var row: Array = Data.GDD.shop[section][i]
	var key := shop_limit_key(section, i)
	var limit = row[3]
	var bought := int(S.shop_bought.get(key, 0))
	if typeof(limit) != TYPE_STRING and bought >= int(limit):
		say("Purchase limit reached", Color.RED)
		return []
	var cost: String = row[2]
	if cost.ends_with("Trinium"):
		if not spend("trinium", int(cost.split(" ")[0])):
			say("Not enough Trinium", Color.RED)
			return []
	elif not S.settings.free_iap:
		say("Real-money purchases are not connected in this build.", Color.RED)
		return []
	S.shop_bought[key] = bought + 1
	var desc: String = row[1]
	var rewards: Array
	if section == "Trinium Market" and desc.contains("Minor"):
		var al: String = row[0].split(" ")[0].to_lower()
		rewards = [{"k": "deeds", "align": al, "tier": "minor", "n": 30}, {"k": "deeds", "align": al, "tier": "major", "n": 20}, {"k": "deeds", "align": al, "tier": "grand", "n": 10}]
	else:
		rewards = U.parse_rewards(desc)
	return grant(rewards)

# ================================================================ login rewards
func _check_login() -> void:
	var day := U.day_id()
	if int(S.login.day) != day:
		S.login.day = day
		S.login.claimed = false
		_dirty = true

func login_index() -> int:
	return int(S.login.progress) % Data.GDD.login.size()

func claim_login() -> Array:
	if S.login.claimed:
		return []
	var text: String = Data.GDD.login[login_index()]
	S.login.claimed = true
	S.login.progress = int(S.login.progress) + 1
	return grant(U.parse_rewards(text))

# ================================================================ battle pass
func bp_season_info() -> Dictionary:
	var cycle := Data.BP_SEASON_DAYS + Data.BP_GAP_DAYS
	var epoch := 20398  # 2025-11-06, season 1 start
	var d := U.day_id() - epoch
	var season := int(floor(d / float(cycle)))
	var into := d - season * cycle
	var active := into < Data.BP_SEASON_DAYS
	return {"season": season + 1, "active": active, "days_left": (Data.BP_SEASON_DAYS - into) if active else (cycle - into), "week": int(into / 7)}

func _check_bp() -> void:
	var info := bp_season_info()
	var bp: Dictionary = S.bp
	if not info.active:
		bp.season = -1
		return
	if int(bp.season) != int(info.season):
		bp.season = info.season
		bp.merits = 0
		bp.premium = false
		bp.claimed_free = []
		bp.claimed_paid = []
	if int(bp.day) != U.day_id():
		bp.day = U.day_id()
		var r := RandomNumberGenerator.new()
		r.seed = U.day_id() * 7919
		var ids: Array = Data.BP_DAILY.map(func(c): return c.id)
		bp.daily = _seeded_pick(ids, 5, r)
		bp.dc = {}
		bp.dclaimed = []
		bp.dbonus = false
	if int(bp.week) != U.week_id():
		bp.week = U.week_id()
		var r2 := RandomNumberGenerator.new()
		r2.seed = U.week_id() * 104729
		var ids2: Array = Data.BP_WEEKLY.map(func(c): return c.id)
		bp.weekly = _seeded_pick(ids2, 4, r2)
		bp.wc = {}
		bp.wclaimed = []
		bp.wbonus = false

func _seeded_pick(ids: Array, n: int, r: RandomNumberGenerator) -> Array:
	var pool := ids.duplicate()
	var out: Array = []
	for i in n:
		var idx := r.randi_range(0, pool.size() - 1)
		out.append(pool[idx])
		pool.remove_at(idx)
	return out

func bp_level() -> int:
	return min(100, int(S.bp.merits) / Data.BP_MERITS_PER_LEVEL)

func bp_add_merits(n: int) -> void:
	S.bp.merits = int(S.bp.merits) + n
	mark()

func bp_challenges(weekly: bool) -> Array:
	var pool: Array = Data.BP_WEEKLY if weekly else Data.BP_DAILY
	var ids: Array = S.bp.weekly if weekly else S.bp.daily
	var counters: Dictionary = S.bp.wc if weekly else S.bp.dc
	var claimed: Array = S.bp.wclaimed if weekly else S.bp.dclaimed
	var out: Array = []
	for c in pool:
		if ids.has(c.id):
			out.append({"id": c.id, "text": c.text, "cur": min(int(counters.get(c.ev, 0)), c.n), "target": c.n, "claimed": claimed.has(c.id)})
	return out

func bp_claim_challenge(weekly: bool, id: String) -> void:
	var list := bp_challenges(weekly)
	for c in list:
		if c.id == id and not c.claimed and c.cur >= c.target:
			(S.bp.wclaimed if weekly else S.bp.dclaimed).append(id)
			bp_add_merits(Data.BP_WEEKLY_MERITS if weekly else Data.BP_DAILY_MERITS)
	list = bp_challenges(weekly)
	var all_done := list.all(func(c): return c.claimed)
	var bonus_key := "wbonus" if weekly else "dbonus"
	if all_done and not S.bp[bonus_key]:
		S.bp[bonus_key] = true
		bp_add_merits(Data.BP_WEEKLY_BONUS if weekly else Data.BP_DAILY_BONUS)
		say("All challenges complete! Bonus merits")

## GDD: players can reset one weekly challenge per week. Returns an error text, or "".
func bp_reroll_weekly(id: String) -> String:
	if int(S.bp.get("wreroll", -1)) == U.week_id():
		return "You already reset a weekly challenge this week."
	if not S.bp.weekly.has(id):
		return "That challenge isn't active."
	if S.bp.wclaimed.has(id):
		return "That challenge is already claimed."
	var pool: Array = Data.BP_WEEKLY.map(func(c): return c.id).filter(func(c): return not S.bp.weekly.has(c))
	if pool.is_empty():
		return "No other weekly challenge available."
	S.bp.weekly[S.bp.weekly.find(id)] = U.pick(pool)
	S.bp.wreroll = U.week_id()
	mark()
	return ""

func bp_claim(level: int, paid: bool) -> Array:
	if level > bp_level():
		return []
	if paid and not S.bp.premium:
		return []
	var arr: Array = S.bp.claimed_paid if paid else S.bp.claimed_free
	if arr.has(level) or arr.has(float(level)):
		return []
	var row: Array = Data.GDD.battlePass[level - 1]
	var text: String = row[2] if paid else row[1]
	if text == "":
		return []
	arr.append(level)
	return grant(U.parse_rewards(text))

## GDD Monetization: "Player Progress Double Rewards - gives extra rewards on each of the player levels".
func buy_double_rewards() -> String:
	if S.get("double_rewards", false):
		return "Already owned."
	if not S.settings.free_iap:
		return "Real-money purchases are not connected in this build."
	S["double_rewards"] = true
	mark()
	return ""

func bp_buy_premium(plus25: bool) -> String:
	if not S.settings.free_iap:
		return "Real-money purchases are not connected in this build."
	S.bp.premium = true
	if plus25:
		S.bp.merits = max(int(S.bp.merits), 25 * Data.BP_MERITS_PER_LEVEL)
	mark()
	return ""

# ================================================================ gang & bastion
func _init_gang() -> void:
	var members: Array = []
	var base := _gang_power_base()
	for i in 14:
		var k := 0.6 + U.rf() * 1.9
		members.append({"name": Content.random_player_name(), "k": k, "power": int(base * k)})
	S.gang = {"name": "Neon Jackals", "members": members, "bastion": {}, "motd": ""}
	_new_bastion_cycle()
	_npc_bastion_dmg()

## NPC gang members are scaled from the player's own squad power (the GDD gives no numbers).
func _gang_power_base() -> int:
	return max(1000, team_power(S.squads.get("last", [])))

func _new_bastion_cycle() -> void:
	S.gang.bastion = {"cycle": int(U.day_id() / 3), "stage": (U.day_id() % 3) + 1, "my_dmg": 0, "gang_dmg": 0, "entries": Data.BASTION_ENTRIES, "day": U.day_id(),
		"boss_hp": 0, "defeated": false}

## Gang-wide boss pool for the day: about 1.2x what all 15 members (14 NPCs + you) are expected to deal.
func _bastion_boss_hp() -> int:
	var total := float(_gang_power_base()) * 40.0
	for m in S.gang.members:
		total += float(m.power) * 40.0
	return int(total * 1.2)

## NPC gang members chip away at the Bastion boss during the day.
func _npc_bastion_dmg() -> void:
	var b: Dictionary = S.gang.bastion
	b.boss_hp = _bastion_boss_hp()
	for m in S.gang.members:
		b.gang_dmg = int(b.gang_dmg) + int(m.power * U.ri(20, 60))
	_check_bastion_defeated()

func _check_bastion_defeated() -> void:
	var b: Dictionary = S.gang.bastion
	if not b.get("defeated", false) and int(b.get("boss_hp", 0)) > 0 and int(b.gang_dmg) + int(b.my_dmg) >= int(b.boss_hp):
		b.defeated = true
		say("Bastion boss defeated by your gang!", Color("#ffd42a"))

func _daily_gang() -> void:
	if S.gang.is_empty():
		_init_gang()
		return
	var b: Dictionary = S.gang.bastion
	# reward yesterday's stage
	if int(b.get("my_dmg", 0)) > 0:
		send_mail("Bastion stage %d rewards" % int(b.stage), "Damage dealt: %s" % U.fmt(b.my_dmg), Content.bastion_rewards(int(b.stage), int(b.my_dmg)))
	var stage := (U.day_id() % 3) + 1
	b.stage = stage
	b.my_dmg = 0
	b.gang_dmg = 0
	b.defeated = false
	b.entries = Data.BASTION_ENTRIES
	b.day = U.day_id()
	if not S.gang.has("motd"):
		S.gang.motd = ""
	# members grow with the player (never shrink)
	var base := _gang_power_base()
	for m in S.gang.members:
		if not m.has("k"):
			m.k = 0.6 + U.rf() * 1.9
		m.power = max(int(m.power), int(base * float(m.k)))
	_npc_bastion_dmg()

func bastion_record(dmg: int, turns: int, debuffs: int) -> void:
	var b: Dictionary = S.gang.bastion
	b.my_dmg = int(b.my_dmg) + dmg
	_check_bastion_defeated()
	stat_add("bastion_dmg", dmg)
	stat_add("bastion_entries", 1)
	stat_add("bastion_debuffs", debuffs)
	S.stats["bastion_turns_best"] = max(stat("bastion_turns_best"), turns)
	mark()

# ================================================================ encounter costs
func cost_text(cost: Dictionary) -> String:
	var parts: Array = []
	for k in cost:
		match k:
			"energy": parts.append("%d Energy" % cost[k])
			"heist": parts.append("%d Heist Plan" % cost[k])
			"bounty": parts.append("%d Bounty Token" % cost[k])
			"brawl": parts.append("%d Brawl Invite" % cost[k])
			"royal": parts.append("%d Royal Invite" % cost[k])
			"bastion": parts.append("1 Bastion Entry")
	return ", ".join(parts)

func can_pay(cost: Dictionary) -> String:
	for k in cost:
		if k == "bastion":
			if int(S.gang.bastion.entries) <= 0 and cur("raidTicket") <= 0:
				return "No Bastion entries left today (Raid Boss Tickets add more)."
		elif cur(k) < int(cost[k]):
			return "Not enough: " + cost_text({k: cost[k]})
	return ""

func pay(cost: Dictionary) -> String:
	var e := can_pay(cost)
	if e != "":
		return e
	for k in cost:
		if k == "bastion":
			if int(S.gang.bastion.entries) > 0:
				S.gang.bastion.entries = int(S.gang.bastion.entries) - 1
			else:
				S.cur.raidTicket = cur("raidTicket") - 1
		else:
			spend(k, int(cost[k]))
	mark()
	return ""
