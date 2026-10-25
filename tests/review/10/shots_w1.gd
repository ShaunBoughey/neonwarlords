extends Node
## Section 10 wave 1: re-shoot owned screens (Pit, Black Market, Syndicate Wars, Squad).

const OUT := "user://shots_10/w1_"
var main

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://shots_10/"))
	for s in ["arena.gd", "black_market.gd", "syndicate_wars.gd", "squad.gd"]:
		var sc: GDScript = load("res://scripts/ui/screens/" + s)
		print("COMPILE ", s, ": ", "ok" if sc != null and sc.can_instantiate() else "FAILED")
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
	Game.S.items.contract.rare = 12
	for i in 12:
		Game.open_contract("rare")
	Game.S.cur.pitCoin = 12000
	Game.S.pit.brawl.points = 1260
	var best: Array = Game.S.roster.duplicate()
	best.sort_custom(func(a, b): return Game.power(a) > Game.power(b))
	Game.S.squads.pit_royal = best.slice(0, 7).map(func(w): return w.uid)
	Game.S.pit.last_def = U.now() - 3600.0 * 16.0
	Game._simulate_pit_defense()
	for mode in ["brawl", "royal"]:
		for view in ["fight", "defence", "leaderboard", "brackets"]:
			main.go("arena", {"mode": mode, "view": view})
			await _frames(5)
			await _shot("arena_%s_%s" % [mode, view])
	main.go("black_market")
	await _frames(5)
	await _shot("bm")
	Game.bm_buy(8)
	main.go("black_market")
	await _frames(5)
	await _shot("bm_after_buy")
	# syndicate wars: some chevrons so milestones are claimable / claimed
	var syn: String = Game.tpl(best[0]).syn
	for st in range(1, 9):
		Game.sw_record(syn, st, 3)
	Game.claim_sw_progress(15)
	main.go("sw")
	await _frames(6)
	await get_tree().create_timer(0.4).timeout
	await _shot("sw_default")
	main.go("sw", {"syn": syn, "stage": 9})
	await _frames(6)
	await _shot("sw_stage9")
	main.go("sw", {"syn": Data.SYNDICATES.keys()[6]})
	await _frames(6)
	await _shot("sw_other_syn")
	_dump_buttons("sw", "sw", {"syn": syn})
	main.start_encounter(Content.build_sw(syn, 3))
	await _frames(6)
	await _shot("squad_sw")
	var ropps := Content.pit_opponents("royal")
	main.start_encounter(Content.build_pit("royal", ropps[0]))
	await _frames(6)
	await _shot("squad_royal")
	main.start_encounter(Content.build_bastion(1))
	await _frames(6)
	await _shot("squad_bastion")
	print("SHOTS DONE")
	get_tree().quit()

func _dump_buttons(tag: String, screen: String, params: Dictionary) -> void:
	main.go(screen, params)
	var out: Array = []
	for b in main.current.find_children("*", "BaseButton", true, false):
		out.append("%s[%d]%s" % [b.get("text") if b.get("text") != null else b.name, b.pressed.get_connections().size(), "(disabled)" if b.disabled else ""])
	print("BUTTONS ", tag, ": ", out)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
