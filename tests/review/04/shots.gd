extends Node
## Review 04 screenshots: warlord stats panel, stat breakdown, roster screen and its filters.
const OUT := "user://shots_04/"
var main

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
	Game.S.player.level = 12
	Game.take_new_unlocks()
	for id in ["deacon_chainz", "issac_vaun", "pontiff_ruckus", "raiden_x", "oni_matsuda", "sigrun", "ratchet", "pix", "talon_kree", "nails"]:
		Game.add_warlord(id, true)
	Game.grant([{"k": "gearSet", "rank": 4, "set": "Speed", "r": "epic"}, {"k": "gearSet", "rank": 4, "set": "Armour", "r": "rare"}, {"k": "implantSet", "rank": 4}])
	main.go("armory")
	await _frames(5)
	await _shot("01_roster_all")
	main.go("armory", {"syn": "teratek", "rar": "all", "sort": "Power"})
	await _frames(4)
	await _shot("02_roster_teratek")
	main.go("armory", {"syn": "all", "rar": "legendary", "sort": "Rarity"})
	await _frames(4)
	await _shot("03_roster_legendary")
	main.go("armory", {"syn": "spliced", "rar": "epic", "sort": "Name"})
	await _frames(4)
	await _shot("04_roster_empty")
	var w: Dictionary = Game.S.roster.filter(func(x): return x.tpl == "deacon_chainz")[0]
	for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
		for it in Game.S.equip:
			if it.slot == slot and it.owner == "":
				Game.equip_on(w, it)
				break
	main.go("warlord", {"uid": w.uid})
	await _frames(5)
	await _shot("10_warlord_gear_stats")
	main.current._go_page("implants")
	await _frames(4)
	await _shot("11_warlord_implants_stats")
	main.current._go_page("upgrade")
	await _frames(4)
	await _shot("12_warlord_upgrade_stats")
	main.current._go_page("gear")
	main.current._stat_breakdown()
	await _frames(4)
	await _shot("13_stat_breakdown")
	main.close_modal()
	var h: Dictionary = Game.S.roster.filter(func(x): return x.tpl == "issac_vaun")[0]
	main.go("warlord", {"uid": h.uid})
	await _frames(5)
	await _shot("14_warlord_hacker_noGear")
	main.current._stat_breakdown()
	await _frames(4)
	await _shot("15_hacker_breakdown")
	main.close_modal()
	var lw: Dictionary = Game.S.roster.filter(func(x): return x.tpl == "raiden_x")[0]
	main.go("warlord", {"uid": lw.uid})
	await _frames(5)
	await _shot("16_warlord_raiden")
	print("SHOTS DONE")
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
