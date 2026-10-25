extends Screen

func build() -> void:
	show_nav = true
	bg_tint = Color("#0E2238")
	var h := header("Battle")
	var xb := UI.btn("XP BOOST  •  %d" % (Game.item_count(["xpBoost"]) + Game.item_count(["xpBoostMinor"])), func(): _boosts(), "green", 0, 14)
	h.add_child(xb)
	var row := UI.hb(18)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)
	var cs := Game.campaign_total_stars(0) + Game.campaign_total_stars(1) + Game.campaign_total_stars(2)
	var den := 0
	for i in 10:
		if Game.campaign_unlocked(0, i, 0):
			den = i
	_card(row, Color("#0F4C6E"), Color("#5FEBFF"), "PvE • Story", UI.CYAN, "Campaign", "Gear & Warlords",
		"Den %d • %s" % [den + 1, Data.GDD.campaign[den].name], "%d / 630" % cs, UI.CYAN, -1, 0, cs / 630.0, false, func(): main.go("campaign"))
	_card(row, Color("#6E0F2A"), Color("#FF5A7A"), "PvE • Bosses", UI.RED, "Hideouts", "High-rank gear, implants, deeds",
		"Heist plans", "%d / %d" % [Game.cur("heist"), Data.HEIST_DAILY], UI.GOLD, Game.cur("heist"), Data.HEIST_DAILY, -1.0, false, func(): main.go("hideouts"))
	_card(row, Color("#3E1270"), Color("#C77DFF"), "PvE • Faction", UI.PURPLE, "Syndicate Wars", "The only source of Neons",
		"Bounty tokens", "%d / %d" % [Game.cur("bounty"), Data.BOUNTY_DAILY], UI.CYAN, -1, 0, float(Game.cur("bounty")) / Data.BOUNTY_DAILY, Game.cur("bounty") > 0, func(): main.go("sw"))
	var pts := int(Game.S.pit.brawl.points)
	_card(row, Color("#6E4A0F"), Color("#FFD36A"), "PvP • Arena", UI.GOLD, "The Pit", "Brawls & Royals • Pit Coin",
		String(Game.pit_tier_row(pts)[1]), "%d pts" % pts, UI.GOLD, -1, 0, clampf(pts / 500.0, 0, 1), false, func(): main.go("arena"))
	var ent := int(Game.S.gang.bastion.entries)
	_card(row, Color("#0F5E46"), Color("#5CFFC0"), "Gang • Raid", UI.GREEN, "Bastion", "Raid TeraTek with your gang",
		"Entries today", "%d / 3" % ent, UI.GREEN, ent, 3, -1.0, false, func(): main.go("gang"))

func _card(parent: Control, scene: Color, rim: Color, tag: String, tag_col: Color, title: String, sub: String, sl: String, sr: String,
		scol: Color, mcur: int, mtot: int, ratio: float, dot: bool, cb: Callable) -> void:
	var c := KeyArtCard.new()
	c.scene_col = scene
	c.rim = rim
	c.tag_text = tag
	c.tag_col = tag_col
	c.heading = title
	c.sub = sub
	c.status_l = sl
	c.status_r = sr
	c.status_col = scol
	c.meter_cur = mcur
	c.meter_total = mtot
	c.meter_ratio = ratio
	c.dot = dot
	c.custom_minimum_size = Vector2(218, 452 + tall_extra() * 0.7)   # tablets: taller key-art cards, still centred
	var feature: String = {"Hideouts": "hideouts", "Syndicate Wars": "sw", "The Pit": "arena", "Bastion": "gang"}.get(title, "")
	if feature != "" and not Game.feature_ok(feature):
		c.lock_text = "Unlocks at\nPlayer Lv %d" % Game.feature_level(feature)
	if title == "Campaign":
		c.set_meta("coach", "campaign")
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.pressed.connect(cb)
	parent.add_child(c)

func _boosts() -> void:
	var v := UI.vb(10)
	v.add_child(UI.lbl("100% XP Boost doubles Warlord XP for 24 hours. 10% boosts add +10% for 24 hours. Energy Batteries give +100 Energy.", 14, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	if Game.S.xp_boost_until > U.now():
		v.add_child(UI.lbl("100% boost active: " + U.dur(Game.S.xp_boost_until - U.now()), 14, UI.GREEN))
	var h := UI.hb()
	h.add_child(UI.btn("Use 100%% Boost (%d)" % Game.item_count(["xpBoost"]), func():
		err("" if Game.use_xp_boost(false) else "No boosts")
		main.close_modal()
		rebuild(), "green"))
	h.add_child(UI.btn("Use 10%% Boost (%d)" % Game.item_count(["xpBoostMinor"]), func():
		err("" if Game.use_xp_boost(true) else "No boosts")
		main.close_modal()
		rebuild(), "green"))
	h.add_child(UI.btn("Use Battery (%d)" % Game.item_count(["battery"]), func():
		err("" if Game.use_battery() else "No batteries")
		main.close_modal()
		rebuild(), "gold"))
	v.add_child(h)
	main.modal("Boosts", v)
