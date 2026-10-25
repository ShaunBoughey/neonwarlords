extends Node
## Review 01: Warlord Rank / Reputation / Level logic checks + Level, Rank and Rep page screenshots.
## Run windowed: NW_SAVE=01 godot --path . res://tests/review/01/Probe01.tscn -- --nwtest
const OUT := "user://shots_01/"
var main
var fails := 0

func _ok(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
	print(("PASS " if cond else "FAIL ") + what)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	Game.reset_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	main.current._new()
	await _frames(5)
	main.close_modal()
	Game.S.tutorial_done = true
	Game.S.player.level = 30
	Game.take_new_unlocks()
	_logic()
	await _shots()
	print("FAILS: ", fails)
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

# ---------------------------------------------------------------- logic
func _logic() -> void:
	# starting rank by rarity
	var exp_start := {"common": 1, "uncommon": 2, "rare": 3, "epic": 4, "legendary": 5}
	for r in exp_start:
		_ok(Data.RANK_START[r] == exp_start[r], "start rank %s = %d" % [r, exp_start[r]])
	for rk in range(1, 7):
		_ok(Data.max_level(rk) == rk * 10, "max level rank %d = %d" % [rk, rk * 10])
	# xp totals per rank (python from GDD cells: 6790 28138 89922 267164 773915 2220907)
	var tot := []
	for rk in range(1, 7):
		var s := 0
		for lv in range(1, rk * 10):
			s += Data.xp_to_next(lv, rk)
		tot.append(s)
	print("XP totals per rank: ", tot)
	_ok(tot == [6790, 28138, 89922, 267164, 773915, 2220907], "xp totals match GDD cell sums")
	_ok(Data.xp_to_next(1, 1) == 500 and Data.xp_to_next(59, 6) == 202633 and Data.xp_to_next(10, 2) == 1297, "xp spot values")

	# rank up rules
	var a: Dictionary = Game.add_warlord("abbot_mayhem", true)   # rare -> R3
	_ok(a.rank == 3 and Game.max_level(a) == 30, "rare starts R3, cap 30")
	var f1: Dictionary = Game.add_warlord("gristle", true)
	var f2: Dictionary = Game.add_warlord("kellen", true)
	var f3: Dictionary = Game.add_warlord("raider_bjorn", true)
	var lo: Dictionary = Game.add_warlord("nails", true)        # uncommon R2
	_ok(Game.rank_up(a, [f1.uid, f2.uid, f3.uid]) != "", "rank up blocked below max level")
	Game.add_wxp(a, 10000000)
	_ok(a.level == 30 and int(a.xp) == 0, "xp capped at level 30, overflow dropped")
	_ok(Game.rank_up(a, [f1.uid, f2.uid]) != "", "rank up blocked with 2 of 3 fodder")
	_ok(Game.rank_up(a, [f1.uid, f2.uid, lo.uid]) != "", "rank up blocked with lower-rank fodder")
	_ok(Game.rank_up(a, [f1.uid, f2.uid, a.uid]) != "", "rank up blocked with self as fodder")
	f3.locked = true
	_ok(Game.rank_up(a, [f1.uid, f2.uid, f3.uid]) != "", "rank up blocked with locked fodder")
	f3.locked = false
	var n0: int = Game.S.roster.size()
	_ok(Game.rank_up(a, [f1.uid, f2.uid, f3.uid]) == "", "rank up OK with 3 x R3 at LV30")
	_ok(a.rank == 4 and a.level == 30 and Game.max_level(a) == 40 and Game.S.roster.size() == n0 - 3, "now R4 LV30/40, 3 consumed")
	_ok(Data.xp_to_next(30, 4) == 10557, "R4 LV30 next = 10557 (GDD)")
	# firmware substitute
	var b: Dictionary = Game.add_warlord("brother_grin", true)  # common R1
	Game.add_wxp(b, 100000)
	Game.add_item(["firmware", "1"], 1)
	_ok(Game.rank_up(b, [], 1) == "" and b.rank == 2, "R1 -> R2 with 1 x Mk1 firmware (documented deviation)")
	# higher-rank fodder is rejected (GDD: equal rank)
	var c: Dictionary = Game.add_warlord("scrapjaw", true)
	Game.add_wxp(c, 100000)
	var hi: Dictionary = Game.add_warlord("sister_cackle", true)  # R2
	_ok(Game.rank_up(c, [hi.uid]) != "", "R1 rank-up rejects an R2 fodder")
	# R6 can't rank further
	var lg: Dictionary = Game.add_warlord("deacon_chainz", true)
	lg.rank = 6
	lg.level = 60
	_ok(not Game.can_rank_up(lg), "R6 cannot rank up")

	# reputation
	for rar in ["rare", "epic", "legendary"]:
		print("rep table %s: %s" % [rar, str(Data.rep_table(rar))])
	var r: Dictionary = Game.add_warlord("oni_matsuda", true)  # rare paragon R3
	for al in ["paragon", "generic"]:
		for tr in ["minor", "major", "grand"]:
			Game.add_item(["deeds", al, tr], 50)
	var before := Game.item_count(["deeds", "paragon", "minor"])
	var gb := Game.item_count(["deeds", "generic", "minor"])
	_ok(Game.rep_up(r) == "" and r.rep == 1, "rep 0 -> 1")
	_ok(before - Game.item_count(["deeds", "paragon", "minor"]) == 2 and gb - Game.item_count(["deeds", "generic", "minor"]) == 3, "rep 1 cost 2 minor paragon + 3 minor generic")
	Game.rep_up(r)
	Game.rep_up(r)
	_ok(r.rep == 3 and Game.rep_up(r) != "", "rep capped at rank 3")
	r.rank = 6
	Game.rep_up(r)
	Game.rep_up(r)
	var pm := Game.item_count(["deeds", "paragon", "major"])
	Game.rep_up(r)
	_ok(r.rep == 6 and pm - Game.item_count(["deeds", "paragon", "major"]) == 3, "rep 6 for rare costs 3 major")
	_ok(Game.rep_up(r) != "", "rep max 6")
	# neutral alignment uses neutral deeds (GDD wording names Paragon only)
	var nz: Dictionary = Game.add_warlord("lysa_vohn", true)  # epic neutral
	_ok(Game.can_rep_up(nz).begins_with("Not enough Neutral"), "neutral warlord needs Neutral deeds: " + Game.can_rep_up(nz))

	# metabolics
	var m: Dictionary = Game.add_warlord("ratchet", true)  # common neutral
	Game.add_item(["metabolic", "neutral", "minor"], 2)
	Game.add_item(["metabolic", "renegade", "minor"], 2)
	Game.use_metabolic(m, "renegade", "minor")
	var lv_off: int = m.level
	var xp_off := _total_xp(m)
	Game.use_metabolic(m, "neutral", "minor")
	var xp_on := _total_xp(m) - xp_off
	print("metabolic minor: off-align %d XP, on-align %d XP (lv %d -> %d)" % [xp_off, xp_on, lv_off, m.level])
	_ok(xp_off == 1500 and xp_on == 2250, "metabolic minor 1500 / aligned +50% 2250")

	# battle loss gives 20%
	var enc := Content.build_campaign(0, 0, 0)
	var win: Dictionary = Content.campaign_rewards(enc, true)
	var loss: Dictionary = Content.campaign_rewards(enc, false)
	_ok(int(loss.xp) == int(int(win.xp) * 0.2), "campaign loss xp %d = 20%% of %d" % [loss.xp, win.xp])

func _total_xp(w: Dictionary) -> int:
	var s := int(w.xp)
	for lv in range(1, int(w.level)):
		s += Data.xp_to_next(lv, int(w.rank))
	return s

# ---------------------------------------------------------------- shots
func _shots() -> void:
	Game.S.roster.clear()
	var hero: Dictionary = Game.add_warlord("abbot_mayhem", true)  # rare neutral armour R3
	hero.level = 12
	for id in ["gristle", "kellen", "raider_bjorn", "bishop_brick", "talon_kree", "nails", "ratchet", "pix", "scrapjaw"]:
		Game.add_warlord(id, true)
	Game.grant([{"k": "metabolic", "align": "neutral", "tier": "minor", "n": 6}, {"k": "metabolic", "align": "paragon", "tier": "major", "n": 2},
		{"k": "metabolic", "align": "renegade", "tier": "grand", "n": 1}, {"k": "firmware", "lv": 3, "n": 2}, {"k": "firmware", "lv": 1, "n": 4},
		{"k": "deeds", "align": "neutral", "tier": "minor", "n": 9}, {"k": "deeds", "align": "generic", "tier": "minor", "n": 2}])
	main.go("warlord", {"uid": hero.uid})
	await _frames(5)
	await _shot("01_detail_gear")
	# LEVEL
	main.current._go_page("level")
	await _frames(4)
	await _shot("10_level_empty")
	_press(Vector2(1460, 612))  # install with nothing selected
	await _frames(3)
	await _shot("11_level_install_nothing_toast")
	main.current.st.meta = "neutral"
	main.current.st.meta_n = 3
	main.current.rebuild()
	await _frames(4)
	await _shot("12_level_meta_aligned_x3")
	main.current.st.meta = "paragon"
	main.current.st.meta_tier = "major"
	main.current.st.meta_n = 1
	main.current.rebuild()
	await _frames(4)
	await _shot("13_level_meta_offalign_major")
	main.current.st.meta = ""
	main.current._open_fodder("feed")
	await _frames(4)
	await _shot("14_level_feed_drawer")
	for x in Game.S.roster.filter(func(q): return q.uid != hero.uid).slice(0, 6):
		main.current._pick_warlord(x.uid, "feed")
	main.current.st.drawer = ""
	main.current.rebuild()
	await _frames(4)
	await _shot("15_level_feed_6_picked")
	main.current.st.picks = []
	hero.level = 30
	hero.xp = 0
	main.current.rebuild()
	await _frames(4)
	await _shot("16_level_max_for_rank")
	# RANK
	hero.level = 20
	main.current._go_page("rank")
	await _frames(4)
	await _shot("20_rank_not_max_level")
	hero.level = 30
	main.current.rebuild()
	await _frames(4)
	await _shot("21_rank_ready_empty")
	main.current._open_fodder("rank")
	await _frames(4)
	await _shot("22_rank_fodder_drawer")
	var r3: Array = Game.S.roster.filter(func(q): return q.uid != hero.uid and q.rank == 3)
	main.current._pick_warlord(r3[0].uid, "rank")
	main.current._pick_warlord(r3[1].uid, "rank")
	main.current.st.drawer = ""
	main.current.st.fw = 1
	main.current.rebuild()
	await _frames(4)
	await _shot("23_rank_2picks_1firmware")
	_press(Vector2(1462, 682))
	await _frames(3)
	await _shot("24a_rank_confirm")
	main.close_modal()
	Game.rank_up(hero, main.current.st.picks, int(main.current.st.fw))
	main.current.st.picks = []
	main.current.st.fw = 0
	main.current.rebuild()
	await _frames(3)
	await _shot("24_rank_after_rankup")
	print("after rank-up: rank %d level %d roster %d fw3 %d" % [hero.rank, hero.level, Game.S.roster.size(), Game.item_count(["firmware", 3])])
	hero.rank = 6
	hero.level = 60
	main.current.rebuild()
	await _frames(4)
	await _shot("25_rank_max_rank6")
	# REP
	hero.rank = 3
	hero.level = 30
	hero.rep = 0
	main.current._go_page("rep")
	await _frames(4)
	await _shot("30_rep_short_generic")
	Game.add_item(["deeds", "generic", "minor"], 5)
	main.current.rebuild()
	await _frames(4)
	await _shot("31_rep_ready")
	_press(Vector2(1288, 415))
	await _frames(3)
	await _shot("32_rep_after_install")
	hero.rep = 3
	main.current.rebuild()
	await _frames(4)
	await _shot("33_rep_capped_by_rank")
	hero.rank = 6
	hero.rep = 6
	main.current.rebuild()
	await _frames(4)
	await _shot("34_rep_max")
	main.current._toggle_drawer("switch")
	await _frames(4)
	await _shot("35_rep_switch_drawer")
	# epic warlord rep page (major tiers)
	var ep: Dictionary = Game.add_warlord("sigrun", true)
	ep.rep = 2
	main.go("warlord", {"uid": ep.uid, "page": "rep"})
	await _frames(5)
	await _shot("36_rep_epic_rep3_major")
	# wave 1: other armoury pages owned by this file
	ep.nn = {"precision": 2, "munitions": 1}
	Game.add_item(["mf", "1"], 50)
	main.current._go_page("neuronet")
	main.current.st.nn = "siphon"
	main.current.rebuild()
	await _frames(4)
	await _shot("40_nn_layers_locked_siphon")
	main.current._go_page("abilities")
	await _frames(4)
	await _shot("41_abilities")
	var dup1: Dictionary = Game.add_warlord("sigrun", true)
	var dup2: Dictionary = Game.add_warlord("sigrun", true)
	main.current._pick_warlord(dup1.uid, "dup")
	main.current._pick_warlord(dup2.uid, "dup")
	main.current.st.drawer = ""
	main.current.rebuild()
	main.current._learn()
	await _frames(4)
	await _shot("42_abilities_learn_spill_confirm")
	main.close_modal()
	Game.grant([{"k": "gearSet", "rank": 4, "set": "Speed", "r": "epic"}, {"k": "neon", "rank": 5, "n": 6}])
	for it in Game.S.equip:
		if it.owner == "" and it.kind != "implant":
			Game.equip_on(ep, it)
	var gl = Game.eq(ep.gear.get("gloves", ""))
	if gl:
		gl.level = 15
		while gl.subs.size() < 3:
			Game.equip_level_up(gl, true)
	main.current._go_page("upgrade")
	if gl:
		main.current.st.item = gl.uid
	main.current.rebuild()
	await _frames(4)
	await _shot("43_upgrade_neon")
	main.current._go_page("gear")
	main.current._select_slot("weapon")
	await _frames(4)
	await _shot("44_gear_modal_drawer")
	main.current._go_page("implants")
	await _frames(4)
	await _shot("45_implants_hint")
	main.go("inventory")
	await _frames(5)
	await _shot("46_inventory_gear_tabs")
	ItemView.open(main, Game.S.equip[0], func(): pass)
	await _frames(4)
	await _shot("47_item_view")

func _press(pos: Vector2) -> void:
	for b in _buttons(main.current):
		if b.position.distance_to(pos) < 2.0:
			b.pressed.emit()
			return
	print("NO BUTTON AT ", pos)

func _buttons(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is BaseButton:
			out.append(c)
		out.append_array(_buttons(c))
	return out

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
