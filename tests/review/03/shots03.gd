extends Node
## Review 03 (equipment): logic probe + screenshots. Windowed:
##   NW_SAVE=03 godot --path . res://tests/review/03/Shots03.tscn -- --nwtest
const OUT := "user://shots_03/"
var main

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + n + ".png")

func _probe() -> void:
	# slot tables, sub rolls, neon, sets
	var bad := 0
	for slot in Data.ALL_SLOTS:
		for i in 60:
			var it := Game.make_equipment(slot, 6, "legendary", "Health")
			if it.subs.size() != 4: bad += 1
			for s in it.subs:
				if s.stat == it.pri.stat: bad += 1
	print("P03 legendary subs/dup errors: ", bad)
	for r in Data.RARITIES:
		print("P03 rarity ", r, " subs=", Game.make_equipment("weapon", 3, r, "Health").subs.size())
	var it := Game.make_equipment("helmet", 4, "common", "Health")
	var log := []
	for l in 20:
		Game.equip_level_up(it, true)
		if (l + 1) % 5 == 0: log.append("%d:%d subs %s" % [l + 1, it.subs.size(), str(it.subs.map(func(s): return [s.stat, s.val, s.rolls]))])
	print("P03 common lvl20: ", "\n".join(log))
	var lg := Game.make_equipment("boots", 5, "legendary", "Speed")
	for l in 20: Game.equip_level_up(lg, true)
	print("P03 legendary lvl20 rolls: ", lg.subs.map(func(s): return [s.stat, s.val, s.rolls]))
	var costs := []
	for rk in range(1, 7):
		var tot := 0
		for l in 20: tot += Data.equip_level_cost(rk, l)
		costs.append("R%d first=%d last=%d total=%d" % [rk, Data.equip_level_cost(rk, 0), Data.equip_level_cost(rk, 19), tot])
	print("P03 costs: ", costs)
	print("P03 primary R6 hp lv0/20: ", Data.primary_value("hp", 6, 0), "/", Data.primary_value("hp", 6, 20), " spd ", Data.primary_value("spd", 6, 0), "/", Data.primary_value("spd", 6, 20))
	# neon checks
	var g := Game.make_equipment("chest", 4, "legendary", "Health")
	var st0: String = g.subs[0].stat
	print("P03 neon r5 on r4: ", Game.neon_can(g, {"rank": 5, "stat": st0}), " | r4: '", Game.neon_can(g, {"rank": 4, "stat": st0}), "'")
	print("P03 NEON_STATS has cc: ", Data.NEON_STATS.has("cc"))
	# set bonuses on a real warlord
	var w: Dictionary = Game.S.roster[0]
	Game.unequip_all(w)
	var base := Game.compute_stats(w)
	for sn in Data.STAT_SETS:
		Game.unequip_all(w)
		for slot in ["weapon", "helmet"]:
			var e := Game.add_equipment(Game.make_equipment(slot, 1, "common", sn))
			Game.equip_on(w, e)
		var s2 := Game.compute_stats(w)
		var gearonly := {}
		for k in ["hp", "arm", "fp", "spd", "cc", "cd", "hack", "fw"]:
			gearonly[k] = s2[k] - base[k]
		print("P03 set ", sn, " delta ", gearonly, " sets ", s2.sets)
	Game.unequip_all(w)
	print("P03 base ", base)

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
	_probe()
	Game.grant_test_kit()
	var w: Dictionary = Game.S.roster[0]
	w.rep = 6
	Game.auto_equip(w)
	main.go("warlord", {"uid": w.uid})
	await _frames(5)
	await _shot("01_gear_page")
	main.current._select_slot("weapon")
	await _frames(4)
	await _shot("02_gear_modal_drawer")
	main.current._go_page("implants")
	await _frames(4)
	await _shot("03_implants")
	main.current._select_slot("organs")
	await _frames(4)
	await _shot("04_implant_modal")
	main.current._go_page("gear")
	main.current._select_slot("boots")
	main.current._go_page("upgrade")
	await _frames(4)
	await _shot("05_upgrade_before")
	var it = Game.eq(main.current.st.item)
	main.current._upgrade(it, 5)
	await _frames(4)
	await _shot("06_upgrade_plus5")
	main.current.st.target = 20
	main.current._upgrade_to(it, 20)
	await _frames(4)
	await _shot("07_upgrade_max")
	main.current._toggle_drawer("equipment")
	await _frames(4)
	await _shot("08_upgrade_drawer")
	main.current._toggle_drawer("equipment")
	# neon graft
	var fit = Game.S.neons.filter(func(ne): return Game.neon_can(it, ne) == "")
	print("P03 fitting neons for boots: ", fit.size())
	main.current.st.neon = 1
	main.current.rebuild()
	await _frames(4)
	await _shot("09_neon_cycle")
	if not fit.is_empty():
		Game.apply_neon(it, fit[0])
		main.current.st.neon = 0
		main.current.rebuild()
		await _frames(4)
		await _shot("10_neon_grafted")
	# item with no fitting neon
	var low := Game.add_equipment(Game.make_equipment("gloves", 1, "common", "Goad"))
	main.current.st.item = low.uid
	main.current.rebuild()
	await _frames(4)
	await _shot("11_upgrade_no_neon")
	main.go("inventory")
	await _frames(4)
	await _shot("12_inventory")
	main.go("inventory", {"tab": "Neons"})
	await _frames(4)
	await _shot("14_inventory_neons")
	main.go("inventory", {"tab": "Implants"})
	await _frames(4)
	await _shot("15_inventory_implants")
	ItemView.open(main, it, func(): pass)
	await _frames(60)
	await _shot("16_item_view")
	main.close_modal()
	main.go("armory")
	await _frames(4)
	await _shot("13_armory_roster")
	get_tree().quit()
