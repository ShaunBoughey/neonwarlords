extends Node
## Wave 1 checks for owner E. NW_SAVE=12 godot --headless --path . res://tests/review/12/Wave1.tscn -- --nwtest
var lv_events := []

func _ready() -> void:
	Game.reset_save()
	Game.new_game("W1")
	Game.player_leveled.connect(func(l, r): lv_events.append([l, r.size()]))
	# level cap + signal + no battery
	Game.S.player.level = 99
	Game.S.player.xp = 0
	Game.add_pxp(29000 + 30000 + 5000)
	print("CAP level=%d maxed=%s xp=%d needed=%d events=%s" % [Game.S.player.level, Game.S.player.get("maxed"), Game.S.player.xp, Game.pxp_needed(), lv_events])
	print("MAIL0 ", Game.S.inbox[0].title, " | ", U.rewards_text(Game.S.inbox[0].rewards))
	print("MAIL1 ", Game.S.inbox[1].title, " | ", U.rewards_text(Game.S.inbox[1].rewards))
	# bp reroll
	Game.S.bp.season = 1
	Game.S.bp.weekly = ["pitKill25", "rank5", "rankAnyW", "equip16x2"]
	print("REROLL1 '%s' -> %s" % [Game.bp_reroll_weekly("rank5"), Game.S.bp.weekly])
	print("REROLL2 '%s'" % Game.bp_reroll_weekly("pitKill25"))
	# plaza
	Game.S.cur.credits = 99999999
	var items := Game.plaza_items()
	print("PLAZA items: ", items.map(func(i): return [i.r.k, i.r.get("slot", ""), i.r.get("set", "")]))
	print("PLAZA stale buy -> ", Game.plaza_buy(0, U.hour_id() - 1))
	var gi := -1
	for i in items.size():
		if items[i].r.k == "gear": gi = i
	if gi >= 0:
		var got := Game.plaza_buy(gi, U.hour_id())
		var it = Game.eq(got[0].equip)
		print("PLAZA gear bought slot=%s set=%s expected %s/%s" % [it.slot, it.set, items[gi].r.slot, items[gi].r.set])
	# neuronet + abilities
	print("NN siphon max=", Data.NN_BY_ID.siphon.max, " pummel max=", Data.NN_BY_ID.pummel.max, " v=", Data.NN_BY_ID.siphon.v)
	var w: Dictionary = Game.S.roster[0]
	w.nn = {"siphon": 1}
	Game.S.items.mf["1"] = 9999
	print("NN add siphon again: ", Game.nn_add(w, "siphon"))
	var no := 0
	var tot := 0
	for id in Warlords.T:
		var t: Dictionary = Warlords.T[id]
		if t.get("enemy_only", false): continue
		for a in t.abilities:
			tot += 1
			if Data.ability_max_level(a) == 1: no += 1
	print("ABILITIES max-level-1: %d of %d" % [no, tot])
	# stocks
	print("STOCKS lv=%d cap=%d req2='%s'" % [Game.stocks_level(), Game.stocks_cap(), Game.stocks_level_req(2)])
	Game.S.stocks.cap_bonus = 25
	print("STOCKS cap with bonus=", Game.stocks_cap())
	Game.S.stocks.cap_bonus = 0
	var errs := []
	for i in 5: errs.append(Game.buy_stocks_cap())
	print("STOCKS buys=%s bonus=%d cap=%d" % [errs, Game.S.stocks.cap_bonus, Game.stocks_cap()])
	# gang
	var b: Dictionary = Game.S.gang.bastion
	print("GANG motd='%s' boss_hp=%d gang_dmg=%d defeated=%s member0=%s" % [Game.S.gang.motd, b.boss_hp, b.gang_dmg, b.defeated, Game.S.gang.members[0]])
	Game.bastion_record(int(b.boss_hp), 10, 0)
	print("GANG after big hit defeated=", b.defeated)
	Game.S.day = -1
	Game.tick()
	print("GANG next day defeated=%s gang_dmg=%d" % [b.defeated, b.gang_dmg])
	# royal defence
	Game.S.squads.pit_royal = Game.S.roster.slice(0, 7).map(func(x): return x.uid)
	var before: Array = Game.S.pit.royal.opps.duplicate()
	var held := Game._defence_battle("royal", Game.S.squads.pit_royal, 1)
	print("ROYAL defence held=%s opps unchanged=%s" % [held, before == Game.S.pit.royal.opps])
	print("COST ", Game.cost_text({"energy": 4}))
	print("GLOVES pri ", Data.SLOT_STATS.gloves.pri)
	get_tree().quit()
