extends Screen
## Gang (clan) and Bastion: Assault on TeraTek Cybernetics.

func build() -> void:
	show_nav = true
	var g: Dictionary = Game.S.gang
	var b: Dictionary = g.bastion
	header("GANG: " + String(g.name).to_upper(), UI.RED)
	var row := UI.hb(16)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(row)
	# ---- bastion
	var bp := UI.panel(UI.RED.darkened(0.2))
	UI.expand(bp)
	var bv := UI.vb(8)
	bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bsc := UI.scroll(bv)
	bsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var outer := UI.vb(8)
	outer.add_child(bsc)
	bp.add_child(outer)
	var stage := int(b.stage)
	var info: Dictionary = Content.BASTION_STAGES[stage - 1]
	var bh := UI.hb(8)
	var bt := UI.lbl("BASTION: ASSAULT ON TERATEK CYBERNETICS", 20, UI.RED)
	UI.expand(bt)
	bh.add_child(bt)
	bh.add_child(UI.lbl("Next stage and rewards in " + U.dur(U.secs_to_next_day()), 13, UI.SOFT))
	bv.add_child(bh)
	bv.add_child(UI.lbl("A gang-wide raid lasting 3 days, one stage per day. Rewards are based on the damage you deal and arrive in your inbox at the daily reset.", 13, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	var stages := UI.hb(8)
	for i in 3:
		var s: Dictionary = Content.BASTION_STAGES[i]
		var sp := UI.panel(UI.YELLOW if i + 1 == stage else Color("#333"))
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sv := UI.vb(2)
		var pt := UI.portrait(s.boss, 56)
		pt.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		sv.add_child(pt)
		sv.add_child(UI.lbl("Stage %d" % (i + 1), 12, UI.DIM))
		sv.add_child(UI.lbl(s.name, 14, UI.YELLOW if i + 1 == stage else UI.TEXT))
		sp.add_child(sv)
		stages.add_child(sp)
	bv.add_child(stages)
	var boss: Dictionary = Warlords.get_t(info.boss)
	bv.add_child(UI.lbl("Today: %s - %s" % [info.name, boss.name], 17, UI.YELLOW))
	for a in boss.abilities:
		var ar := UI.hb(8)
		ar.add_child(UI.tag(String(a.type), UI.RED if a.type == "active" else UI.PURPLE))
		var al := UI.lbl("%s: %s" % [a.name, a.desc], 13, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true)
		UI.expand(al)
		ar.add_child(al)
		bv.add_child(ar)
	var gang_total := int(b.gang_dmg) + int(b.my_dmg)
	if b.has("boss_hp") and int(b.boss_hp) > 0:
		var hp_left: int = max(0, int(b.boss_hp) - gang_total)
		bv.add_child(UI.lbl("Boss HP: %s / %s" % [U.fmt(hp_left), U.fmt(int(b.boss_hp))], 15, UI.RED))
		bv.add_child(UI.bar(hp_left, int(b.boss_hp), UI.RED, 12))
		if b.get("defeated", false):
			bv.add_child(UI.tag("Defeated - you can still attack for rewards", UI.GREEN))
	bv.add_child(UI.lbl("Your damage today: %s   •   Gang damage: %s" % [U.fmt(b.my_dmg), U.fmt(gang_total)], 15))
	var tiers := UI.flow(6)
	var tier_rows: Array = Content.call("bastion_tiers", stage) if Content.has_method("bastion_tiers") else Content.BASTION_TIERS
	for tr in tier_rows:
		var reached := int(b.my_dmg) >= int(tr[0])
		var c := UI.chip("", "%s: %s" % [U.fmt(tr[0]), tr[1]], UI.GREEN if reached else UI.DIM, 13)
		if reached:
			c.add_theme_stylebox_override("panel", UI._sb(Color(UI.GREEN, 0.15), UI.GREEN, 1, 8, 8))
			var row2: HBoxContainer = c.get_child(0)
			var ic := Icon.make("check", UI.GREEN, 16)
			row2.add_child(ic)
			row2.move_child(ic, 0)
		tiers.add_child(c)
	bv.add_child(tiers)
	var eh := UI.hb(10)
	eh.add_child(UI.lbl("Entries: %d / %d  •  Raid Boss Tickets: %d" % [int(b.entries), Data.BASTION_ENTRIES, Game.cur("raidTicket")], 15, UI.CYAN))
	eh.add_child(UI.spacer())
	var fb := UI.btn("ATTACK (%d turns)" % Content.BASTION_TURNS, func(): main.start_encounter(Content.build_bastion(stage)), "magenta", 240, 18)
	fb.disabled = Game.can_pay({"bastion": 1}) != ""
	eh.add_child(fb)
	outer.add_child(eh)
	row.add_child(bp)
	# ---- members
	var mp := UI.panel()
	mp.custom_minimum_size.x = 330
	var mv := UI.vb(4)
	mp.add_child(mv)
	var mh0 := UI.hb(6)
	mh0.add_child(UI.lbl("Members (%d)" % (g.members.size() + 1), 16, UI.CYAN))
	mh0.add_child(UI.spacer())
	mh0.add_child(UI.btn("RENAME", func(): _rename(), "ghost", 0, 13))
	mh0.add_child(UI.btn("MESSAGE", func(): _motd(), "ghost", 0, 13))
	mv.add_child(mh0)
	var me := UI.hb()
	me.add_child(UI.lbl("★ " + Game.S.name, 14, UI.MAGENTA))
	me.add_child(UI.spacer())
	me.add_child(UI.lbl("Leader • " + U.fmt(Game.team_power(Game.S.squads.last)), 13, UI.YELLOW))
	mv.add_child(me)
	var list := UI.vb(2)
	for m in g.members:
		var mh := UI.hb()
		mh.add_child(UI.lbl(m.name, 13))
		mh.add_child(UI.spacer())
		mh.add_child(UI.lbl(U.fmt(m.power), 12, UI.DIM))
		list.add_child(mh)
	var msc := UI.scroll(list)
	msc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mv.add_child(msc)
	var chat := UI.panel(UI.PURPLE.darkened(0.4), Color("#0b0c20"))
	var cv := UI.vb(2)
	var motd := String(g.get("motd", ""))
	if motd != "":
		cv.add_child(UI.lbl("Leader: " + motd, 14, UI.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, true))
	var r := RandomNumberGenerator.new()
	r.seed = U.day_id()
	var lines := ["Bastion is up, hit it hard!", "Anyone got a spare Stitcher set?", "Hammer of Four stage 20 is brutal", "Pit reset soon - push your bracket", "Who's farming Synapse today?", "gg on that Heist payout"]
	var speakers: Array = g.members.duplicate()
	for arr in [lines, speakers]:
		for i in range(arr.size() - 1, 0, -1):
			var j := r.randi_range(0, i)
			var tmp = arr[i]
			arr[i] = arr[j]
			arr[j] = tmp
	for i in min(3, speakers.size()):
		cv.add_child(UI.lbl("%s: %s" % [speakers[i].name, lines[i]], 13, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	chat.add_child(cv)
	mv.add_child(UI.lbl("Gang chat (offline)", 13, UI.PURPLE))
	mv.add_child(chat)
	row.add_child(mp)

func _rename() -> void:
	var v := UI.vb(8)
	var le := LineEdit.new()
	le.text = Game.S.gang.name
	le.max_length = 20
	v.add_child(le)
	v.add_child(UI.btn("Save", func():
		if le.text.strip_edges() != "":
			Game.S.gang.name = le.text.strip_edges()
			Game.mark()
		main.close_modal()
		rebuild(), "primary"))
	main.modal("Rename Gang", v)

## Leader's pinned gang message (stored in S.gang.motd).
func _motd() -> void:
	var v := UI.vb(8)
	var le := LineEdit.new()
	le.text = String(Game.S.gang.get("motd", ""))
	le.max_length = 120
	le.placeholder_text = "Message pinned to the top of gang chat"
	v.add_child(le)
	v.add_child(UI.btn("SAVE", func():
		Game.S.gang["motd"] = le.text.strip_edges()
		Game.mark()
		main.close_modal()
		rebuild(), "primary"))
	main.modal("Gang Message", v)
