extends Node
## Section 13 logic probe (login, jobs, ambitions, safehouse). Run headless:
##   NW_SAVE=13 godot --headless --path . res://tests/review/13/Probe13.tscn -- --nwtest

const AMB_PATTERNS := ["Complete Den (\\d+):7 on (.+)", "Beat Hideout (.+) Stage (\\d+), (\\d+) Times", "Gain (.+) Set (\\w+) with (.+) Primary",
	"Sell (\\d+) Equipments", "Level (\\d+) Equipments to (\\d+)", "Equip (\\d+) Warlords? with a Full Set", "Equip (?:a|(\\d+)) Warlords? with a (.+) Set",
	"Gain (\\d+) (Minor|Major|Grand) (Paragon|Neutral|Renegade|Generic) Deeds", "Raise a (Paragon|Neutral|Renegade) Warlord's Reputation to (\\d)",
	"Recruit (\\d+) Warlords", "Level (\\d+) Warlords to (\\d+)", "Rank (\\d+) Warlords to Rank (\\d)", "Consume (\\d+) Warlords", "Level an (\\w+) Warlord to (\\d+)",
	"Deal (\\d+)m Total Damage in Bastions", "Apply (\\d+) Debuffs to a Bastion Boss", "Enter (\\d+) Bastion Stages", "Survive (\\d+) Turns Inside a Bastion",
	"Enter (\\d+) Pit Brawls/Royals", "Defeat (\\d+) Enemies in The Pit", "Apply (\\d+) Debuffs in The Pit", "Purchase a (?:Level (\\d+) )?Safehouse Upgrade",
	"Complete [Aa]ll Tier (\\d) .+ Ambitions"]

var issues := 0

func _p(s: String) -> void:
	print(s)

func _bad(s: String) -> void:
	issues += 1
	print("ISSUE: ", s)

func _rw(text: String) -> String:
	var r := U.parse_rewards(text)
	var pieces := text.split(",").size()
	var labels := U.rewards_text(r)
	for x in r:
		if x.k == "unknown":
			_bad("unparsed reward piece in '%s' -> %s" % [text, x.text])
	if r.size() != pieces:
		_bad("piece count %d != parsed %d for '%s'" % [pieces, r.size(), text])
	return labels

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe13")
	Game.S.tutorial_done = true
	_p("=== LOGIN (%d days)" % Data.GDD.login.size())
	for i in Data.GDD.login.size():
		_p("day %d: %s -> %s" % [i + 1, Data.GDD.login[i], _rw(Data.GDD.login[i])])
	_p("=== JOBS")
	for per in ["daily", "weekly", "monthly"]:
		for i in Data.GDD.jobs[per].size():
			var row: Array = Data.GDD.jobs[per][i]
			_p("%s %d: %s [%s %d] -> %s" % [per, i, row[0], Data.JOB_DEFS[per][i][0], Data.JOB_DEFS[per][i][1], _rw(row[1])])
	_p("=== AMBITIONS")
	for cat in Data.GDD.ambitions:
		for row in Data.GDD.ambitions[cat]:
			var hit := ""
			for pat in AMB_PATTERNS:
				if RegEx.create_from_string(pat).search(row[2]):
					hit = pat
					break
			if hit == "":
				_bad("ambition has no progress rule: %s / %s" % [cat, row[2]])
			var m := RegEx.create_from_string("Beat Hideout (.+) Stage").search(row[2])
			if m:
				var hid: String = Game._hideout_id_from_name(m.get_string(1))
				if not Content.HIDEOUTS.has(hid):
					_bad("hideout id %s unknown for %s" % [hid, row[2]])
			m = RegEx.create_from_string("Gain (.+) Set (\\w+) with (.+) Primary").search(row[2])
			if m:
				var sn := m.get_string(1).replace("HP", "Health").replace("Crit ", "Critical ")
				var pri: String = Game._stat_from_name(m.get_string(3))
				var slot := m.get_string(2).to_lower()
				if not Data.SETS.has(sn) or not Data.SLOT_STATS.has(slot) or not Data.SLOT_STATS[slot].pri.has(pri):
					_bad("equipment ambition impossible: %s (set %s slot %s pri %s)" % [row[2], sn, slot, pri])
			m = RegEx.create_from_string("Complete Den (\\d+):7 on (.+)").search(row[2])
			if m and Data.DIFFS.find(m.get_string(2)) < 0:
				_bad("difficulty unknown: " + row[2])
			m = RegEx.create_from_string("Level an (\\w+) Warlord").search(row[2])
			if m:
				var cls := m.get_string(1).to_lower()
				var any := false
				for t in Warlords.ALL if "ALL" in Warlords else []:
					if t.cls == cls: any = true
				if not Data.CLASS_SCALING.has(cls):
					_bad("class unknown: " + row[2])
			_p("%s %d-%d: %s -> %s" % [cat, row[0], row[1], row[2], _rw(row[3])])
	# ---- functional: jobs
	_p("=== JOBS FUNCTIONAL")
	for ev in ["pitBrawl", "den", "plazaBuy", "recruit", "equip8", "warlordLevel", "hideoutEquip"]:
		Game.track(ev, 20)
	var dl: Array = Game.jobs_list("daily")
	var claimable := dl.filter(func(j): return j.cur >= j.target).size()
	_p("daily claimable after events: %d/8 (expect 7)" % claimable)
	var px0 := int(Game.S.player.get("xp", 0))
	for i in 7:
		Game.claim_job("daily", i)
	dl = Game.jobs_list("daily")
	_p("daily 'all' job cur %d/%d" % [dl[7].cur, dl[7].target])
	var got: Array = Game.claim_job("daily", 7)
	_p("all-daily claim rewards: %s" % str(got.map(func(x): return x.get("label", ""))))
	var wl: Array = Game.jobs_list("weekly")
	_p("weekly dailyAll progress %d/%d" % [wl[0].cur, wl[0].target])
	# ---- functional: safehouse
	_p("=== SAFEHOUSE")
	Game.S.cur.pitCoin = 100000
	var w: Dictionary = Game.S.roster[0]
	var al: String = Game.tpl(w).align
	var before: Dictionary = Game.compute_stats(w)
	var pc0 := int(Game.S.cur.pitCoin)
	for i in 10:
		var e: String = Game.safehouse_upgrade(al, "hpP")
		if e != "": _bad("upgrade failed: " + e)
	for i in 10:
		Game.safehouse_upgrade(al, "hack")
	var spent: int = pc0 - int(Game.S.cur.pitCoin)
	_p("spent %d (expect %d)" % [spent, 2 * (100 + 225 + 350 + 475 + 600 + 725 + 850 + 975 + 1100 + 1250)])
	_p("11th upgrade: '%s'" % Game.safehouse_upgrade(al, "hpP"))
	var after: Dictionary = Game.compute_stats(w)
	_p("hp %s -> %s, hack %s -> %s (align %s)" % [before.hp, after.hp, before.hack, after.hack, al])
	Game.S.cur.pitCoin = 50
	_p("poor upgrade: '%s'" % Game.safehouse_upgrade(al, "fpP"))
	# ---- functional: login
	_p("=== LOGIN FUNCTIONAL")
	var r0: int = Game.S.roster.size()
	for d in 33:
		Game.S.login.claimed = false
		var res: Array = Game.claim_login()
		if d == 30 or d == 31 or d == 0:
			_p("claim %d (idx now %d): %s" % [d + 1, Game.login_index(), str(res.map(func(x): return x.get("label", "")))])
	_p("double claim same day -> %s" % str(Game.claim_login()))
	_p("roster grew by %d over 33 claims" % (Game.S.roster.size() - r0))
	# ---- ambitions functional: tier gating and 'complete all'
	_p("=== AMBITIONS FUNCTIONAL")
	for cat in Data.GDD.ambitions:
		var lst: Array = Game.ambitions_list(cat)
		_p("%s visible rows %d, tiers %s" % [cat, lst.size(), str(lst.map(func(a): return a.tier).reduce(func(acc, t): return acc if acc.has(t) else acc + [t], []))])
	print("ISSUES: ", issues)
	Game.reset_save()
	get_tree().quit()
