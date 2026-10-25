extends Node
## Section 02 screenshots: Neuronet + Abilities pages.  Windowed run, NW_SAVE=02.
const OUT := "user://shots_02/"
var main

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	Game.reset_save()
	Game.new_game("Rev02")
	Game.S.tutorial_done = true
	Game.S.player.level = 30
	Game.take_new_unlocks()
	var w := Game.add_warlord("deacon_chainz", true)
	var dup := Game.add_warlord("deacon_chainz", true)
	var dup2 := Game.add_warlord("deacon_chainz", true)
	var ep := Game.add_warlord("pontiff_ruckus", true)
	var cm := Game.add_warlord("brother_grin", true)
	Game.grant([{"k": "mf", "tier": 1, "n": 2000}, {"k": "mf", "tier": 2, "n": 2000}, {"k": "mf", "tier": 3, "n": 3000}, {"k": "stimm", "r": "legendary", "n": 3}, {"k": "stimm", "r": "epic", "n": 2}])
	for id in ["precision", "precision", "plating", "plating", "munitions", "munitions", "forceMeasure"]:
		var e := Game.nn_add(w, id)
		if e != "": print("nn_add ", id, ": ", e)
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	main.go("warlord", {"uid": w.uid})
	await _frames(4)
	var s = main.current
	s._go_page("neuronet")
	await _frames(4)
	await _shot("01_nn_assault_noselect")
	s.st.nn = "precision"; s.rebuild(); await _frames(4)
	await _shot("02_nn_assault_selected_maxed")
	s.st.nn = "forceMeasure"; s.rebuild(); await _frames(4)
	await _shot("03_nn_assault_blocked_pair")
	s.st.nn = "essenceShield"; s.rebuild(); await _frames(4)
	var sc := _find(s.canvas, "ScrollContainer")
	if sc: sc.scroll_vertical = 330
	await _frames(3)
	await _shot("04_nn_assault_layer3_ready")
	if sc: sc.scroll_vertical = 100000
	await _frames(3)
	await _shot("05_nn_assault_bottom")
	s.st.career = "protection"; s.st.nn = "egocentric"; s.rebuild(); await _frames(4)
	await _shot("06_nn_protection")
	s.st.career = "control"; s.st.nn = "malware"; s.rebuild(); await _frames(4)
	await _shot("07_nn_control_layerfull")
	s.st.nn = "wrath"; s.st.career = "assault"; s.rebuild(); await _frames(4)
	await _shot("08_nn_wrath_locked")
	# abilities
	s._go_page("abilities"); await _frames(4)
	await _shot("10_ab_default")
	for aid in ["holy_fracture", "divine_retribution", "congregation", "late_mass"]:
		s.st.ability = aid; s.rebuild(); await _frames(4)
		await _shot("11_ab_" + aid)
	s.st.ability = "holy_torment"
	s._open_fodder("dup"); await _frames(4)
	await _shot("12_ab_dup_drawer")
	s._pick_warlord(dup.uid, "dup"); s._pick_warlord(dup2.uid, "dup")
	s.st.drawer = ""; s.st.stimm = "legendary"; s.rebuild(); await _frames(4)
	await _shot("13_ab_dup_and_stimm_selected")
	s._learn(); await _frames(6)
	await _shot("14_ab_after_learn")
	main.go("warlord", {"uid": ep.uid, "page": "abilities"}); await _frames(4)
	main.current._go_page("abilities"); await _frames(4)
	await _shot("15_ab_epic_5abilities")
	main.go("warlord", {"uid": cm.uid}); await _frames(4)
	main.current._go_page("abilities"); await _frames(4)
	await _shot("16_ab_common_2abilities")
	main.current._go_page("neuronet"); await _frames(4)
	await _shot("17_nn_common_empty")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	print("ab after learn: ", w.ab)
	get_tree().quit()

func _find(n: Node, cls: String) -> Node:
	for c in n.get_children():
		if c.get_class() == cls: return c
		var r = _find(c, cls)
		if r: return r
	return null

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
