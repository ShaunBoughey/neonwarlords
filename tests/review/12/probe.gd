extends Node
## Section 12 logic probe (headless). NW_SAVE=12 godot --headless --path . res://tests/review/12/Probe.tscn -- --nwtest

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe12")
	# 1. parse every player-level reward row
	var bad := 0
	for row in Data.GDD.playerLevels:
		var parsed: Array = U.parse_rewards(row[2])
		var txt := U.rewards_text(parsed)
		var unk := parsed.filter(func(r): return r.k == "unknown")
		if not unk.is_empty() or parsed.size() < 3:
			bad += 1
		print("LV %d xp=%d | %s => %s" % [row[0], row[1], row[2], txt])
	print("LEVEL ROWS BAD PARSE: ", bad)
	# 2. contract distribution
	for c in ["uncommon", "rare", "epic", "legendary"]:
		var cnt := {}
		var N := 20000
		for i in N:
			var r: String = U.weighted(Data.CONTRACT_RATES[c])
			cnt[r] = int(cnt.get(r, 0)) + 1
		var out := []
		for k in cnt:
			out.append("%s %.2f%%" % [k, 100.0 * cnt[k] / N])
		print("CONTRACT ", c, ": ", ", ".join(out))
	# 3. open_contract actually yields the rolled rarity pool
	Game.S.items.contract.epic = 50
	var rr := {}
	for i in 50:
		var w = Game.open_contract("epic")
		var rar: String = Game.tpl(w).rarity
		rr[rar] = int(rr.get(rar, 0)) + 1
	print("OPEN epic x50: ", rr)
	# 4. caps
	Game.S.cur.heist = 5; Game.add_cur("heist", 3); print("heist after +3 at cap: ", Game.cur("heist"))
	Game.S.cur.bounty = 12; Game.add_cur("bounty", 3); print("bounty after +3 at cap: ", Game.cur("bounty"))
	Game.S.cur.brawl = 10; Game.add_cur("brawl", 10); print("brawl after +10 at cap: ", Game.cur("brawl"))
	# 5. XP: 1 per energy; level-up energy refill; battery side effect
	Game.S.player.level = 1; Game.S.player.xp = 0
	Game.S.cur.energy = 100
	var bat0 := Game.item_count(["battery"])
	Game.spend("energy", 100)
	print("after spending 100 energy: lv=%d xp=%d energy=%d batteries+%d" % [Game.S.player.level, Game.S.player.xp, Game.cur("energy"), Game.item_count(["battery"]) - bat0])
	var mail: Dictionary = Game.S.inbox[0] if Game.S.has("inbox") and Game.S.inbox.size() > 0 else {}
	print("level mail: ", mail.get("title", "?"), " rewards=", U.rewards_text(mail.get("rewards", [])))
	# 6. cap at 100
	Game.S.player.level = 100; Game.S.player.xp = 0
	Game.add_pxp(30000)
	print("lv100 +30000 xp -> level ", Game.S.player.level, " needed now ", Game.pxp_needed())
	Game.add_pxp(99999)
	print("then +99999 -> level ", Game.S.player.level, " xp ", Game.S.player.xp)
	# total xp to 100
	var tot := 0
	for i in 99: tot += int(Data.GDD.playerLevels[i][1])
	print("total XP 1->100: ", tot)
	# 7. pit tiers
	for pts in [0, 99, 100, 199, 200, 590, 600, 1499, 1500, 2999, 3000, 9000]:
		var t := Game.pit_tier(pts)
		print("pit pts %d -> tier %d %s loss=%d" % [pts, t, Game.pit_tier_row(pts)[1], Data.pit_loss(t)])
	print("pit start points: ", Game.S.pit.brawl.points)
	# 8. unlock announcements across levels
	Game.S.player.level = 1
	Game.S.erase("seen_unlocks")
	Game.take_new_unlocks()
	for lv in range(2, 14):
		Game.S.player.level = lv
		var f := Game.take_new_unlocks()
		if not f.is_empty():
			print("LV %d unlocks: %s" % [lv, f])
	# 9. scrap
	print("scrap map: ", Data.SCRAP_FOR)
	get_tree().quit()
