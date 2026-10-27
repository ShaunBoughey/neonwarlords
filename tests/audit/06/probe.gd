extends Node
## Audit 06 probe: SW / Pit / caches / Black Market / Stocks / Bastion data and rules.

func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Probe")
	print("== SW rows")
	for r in Data.GDD.syndicateWars:
		print("SW ", r.stage, " tok ", r.tokens, " ranks ", r.ranks)
	print("NEON_STATS ", Data.NEON_STATS.size())
	print("== swProgress")
	for r in Data.GDD.swProgress:
		print("SWP ", r[0], " | ", r[1], " -> ", U.parse_rewards(String(r[1])))
	print("== pitTiers")
	for r in Data.GDD.pitTiers:
		print("PT ", r, " -> weekly ", U.parse_rewards(String(r[3])))
	print("== caches")
	for c in Data.GDD.caches:
		for row in Data.GDD.caches[c]:
			print("C ", c, " | ", row, " -> ", U.parse_rewards(String(row[0])))
	print("== blackMarket")
	for r in Data.GDD.blackMarket:
		print("BM ", r, " -> ", U.parse_rewards(String(r[0])))
	print("STOCKS ", Data.STOCKS, " lvl ", Game.stocks_level(), " cap ", Game.stocks_cap())
	print("cur ", Game.S.cur)
	# cache open sample
	Game.add_item(["cache", "Exalted Cache"], 1)
	var got := Game.open_cache("Exalted Cache")
	print("EXALTED open count ", got.size(), " meta ", got.map(func(x): return x.get("label", "")))
	# Monte Carlo SW stage 1 neon ranks
	var cnt := {}
	for i in 2000:
		var res := Content.sw_rewards({"stage": 1}, true)
		var n: Dictionary = Game.S.neons[-1]
		cnt[n.rank] = int(cnt.get(n.rank, 0)) + 1
	print("SW1 rank counts ", cnt)
	var st := {}
	for n in Game.S.neons:
		st[n.stat] = int(st.get(n.stat, 0)) + 1
	print("neon stats ", st)
	# BM daily/weekly
	Game.add_cur("pitCoin", 100000)
	var i := 0
	print("BM buy credits x3 ", Game.bm_buy(1).size(), Game.bm_buy(1).size(), Game.bm_buy(1).size(), " rare stimm x2 ", Game.bm_buy(2).size(), "/", Game.bm_buy(2).size())
	# pit record
	var opps := Content.pit_opponents("brawl")
	print("opps ", opps.size(), " team ", opps[0].team.size(), " royal ", Content.pit_opponents("royal")[0].team.size())
	var p0 := int(Game.S.pit.brawl.points)
	var rw := Game.pit_record("brawl", true, opps[0])
	print("pit win pts ", p0, "->", Game.S.pit.brawl.points, " rewards ", rw)
	Game.pit_record("brawl", false, opps[1])
	print("pit loss pts ", Game.S.pit.brawl.points)
	# daily reset
	Game.S.cur.bounty = 3
	Game.S.cur.brawl = 2
	Game.S.day = -5
	Game.tick()
	print("after daily bounty ", Game.S.cur.bounty, " brawl ", Game.S.cur.brawl)
	# weekly
	var mail_before: int = Game.S.get("mail", []).size()
	Game.S.week = -5
	Game.tick()
	print("weekly mails ", Game.S.get("mail", []).size() - mail_before, " pts after week ", Game.S.pit.brawl.points)
	# bastion
	print("bastion ", Game.S.gang.bastion)
	print("PROBE DONE")
	get_tree().quit(0)
