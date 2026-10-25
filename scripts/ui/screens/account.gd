extends Screen

func build() -> void:
	header("ACCOUNT")
	var row := UI.hb(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)
	var p := UI.panel()
	UI.expand(p)
	var v := UI.vb(8)
	p.add_child(v)
	var nh := UI.hb(8)
	var le := LineEdit.new()
	le.text = Game.S.name
	le.max_length = 18
	le.custom_minimum_size.x = 260
	nh.add_child(UI.lbl("Name", 16, UI.DIM))
	nh.add_child(le)
	nh.add_child(UI.btn("Rename", func():
		if le.text.strip_edges() != "":
			Game.S.name = le.text.strip_edges()
			Game.mark()
			Game.say("Renamed"), "primary"))
	v.add_child(nh)
	var p_lv: int = Game.S.player.level
	v.add_child(UI.lbl("Player level %d  •  XP %d / %d" % [p_lv, int(Game.S.player.xp), Game.pxp_needed()], 16))
	v.add_child(UI.lbl("Playing since " + Time.get_datetime_string_from_unix_time(int(Game.S.created)).substr(0, 10), 14, UI.DIM))
	var g := UI.grid(2, 18)
	var stats := [
		["Warlords owned", Game.S.roster.size()], ["Warlords recruited", Game.stat("recruited")], ["Warlords consumed", Game.stat("consumed")],
		["Equipment owned", Game.S.equip.size()], ["Equipment sold", Game.stat("sold")], ["Den battles", Game.stat("ev_den")],
		["Hideout victories", Game.stat("ev_hideout")], ["Pit fights", Game.stat("pit_entries")], ["Pit kills", Game.stat("ev_pitKill")],
		["Bastion damage", U.fmt(Game.stat("bastion_dmg"))], ["Campaign chevrons", "%d / %d / %d" % [Game.campaign_total_stars(0), Game.campaign_total_stars(1), Game.campaign_total_stars(2)]],
		["Syndicate Wars chevrons", Game.sw_total_stars()], ["Credits spent", U.fmt(Game.stat("ev_spendCredits"))],
	]
	for s in stats:
		g.add_child(UI.lbl(s[0], 14, UI.DIM))
		g.add_child(UI.lbl(str(s[1]), 14))
	v.add_child(g)
	row.add_child(p)
	# player level rewards preview
	var lp := UI.panel()
	lp.custom_minimum_size.x = 420
	var lv := UI.vb(4)
	lp.add_child(lv)
	lv.add_child(UI.lbl("Upcoming player level rewards", 15, UI.CYAN))
	lv.add_child(UI.lbl("Earn player XP from Jobs, Ambitions and 1 XP per energy spent. Each level refills energy.", 12, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	var list := UI.vb(4)
	var tbl: Array = Data.GDD.playerLevels
	for i in range(p_lv - 1, mini(tbl.size(), p_lv + 9)):
		var r: Array = tbl[i]
		list.add_child(UI.lbl("Lv %d → %d  (%s XP): %s" % [r[0], int(r[0]) + 1, U.fmt(r[1]), r[2]], 13, UI.YELLOW if i == p_lv - 1 else UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	lv.add_child(UI.scroll(list))
	row.add_child(lp)
