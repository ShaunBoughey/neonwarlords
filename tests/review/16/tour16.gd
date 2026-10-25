extends Node
## Section 16 review: full screen tour + shell/touch/text audit. Windowed:
##   NW_SAVE=16 NW_TAG=std godot --path . res://tests/review/16/Tour16.tscn -- --nwtest

var OUT := "user://shots_16/"
var main
var vp_rect: Rect2

func _ready() -> void:
	var tag := OS.get_environment("NW_TAG")
	if tag == "":
		tag = "std"
	OUT = "user://shots_16/%s/" % tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	print("VIEWPORT ", get_viewport().get_visible_rect().size, " window ", DisplayServer.window_get_size())
	Game.reset_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	vp_rect = get_viewport().get_visible_rect()
	await _shot("01_login")
	_audit("login")
	main.current._new()
	await _frames(8)
	await _shot("02_city_ftue_start")
	_audit("city_ftue")
	main.coach.finish()
	Game.S.tutorial_done = true
	Game.S.player.level = 40
	Game.take_new_unlocks()
	Game.S.items.contract.rare = 12
	for i in 12:
		Game.open_contract("rare")
	Game.grant([{"k": "gearSet", "rank": 4, "set": "Speed", "r": "epic"}, {"k": "implantSet", "rank": 4}, {"k": "neon", "rank": 4, "n": 6}])
	main.home()
	await _frames(6)
	main.close_modal()
	await _frames(4)
	await _shot("03_city")
	_audit("city")
	Game.add_pxp(Game.pxp_needed())
	await _frames(4)
	main._announce_unlocks()
	await _frames(6)
	await _shot("04_levelup_card")
	_audit("levelup")
	main.close_modal()
	await _frames(2)
	for s in ["fight", "campaign", "hideouts", "sw", "arena", "armory", "inventory", "recruit", "plaza", "black_market", "safehouse", "missions", "battle_pass", "shop", "login_rewards", "gang", "settings", "inbox", "account", "events"]:
		main.go(s)
		await _frames(5)
		main.close_modal()
		await _frames(2)
		await _shot("10_" + s)
		_audit(s)
	main.go("campaign", {"d": 0, "loc": 0})
	await _frames(4)
	await _shot("11_campaign_stages")
	_audit("campaign_stages")
	main.go("hideout", {"id": "vikings"})
	await _frames(4)
	await _shot("12_hideout_vikings")
	_audit("hideout")
	var w: Dictionary = Game.S.roster[0]
	main.go("warlord", {"uid": w.uid})
	await _frames(4)
	await _shot("20_warlord")
	_audit("warlord")
	main.go("squad", {"enc": Content.build_campaign(0, 0, 0)})
	await _frames(4)
	await _shot("30_squad")
	_audit("squad")
	Game.S.settings.auto = false
	main.current._start()
	await get_tree().create_timer(3.0).timeout
	await _shot("31_battle")
	_audit("battle")
	Game.S.settings.auto = true
	Game.S.settings.speed = 3
	main.current._toggle_auto()
	main.current._toggle_auto()
	var t := 0.0
	while not main.current.finished and t < 90.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
	await _frames(10)
	await _shot("33_result")
	_audit("result")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _audit(scr: String) -> void:
	var small := []
	var dead := []
	var tiny_text := []
	var off := []
	var emoji := []
	_walk(main, small, dead, tiny_text, off, emoji)
	print("AUDIT %s small=%d dead=%d tinytext=%d offscreen=%d emoji=%d" % [scr, small.size(), dead.size(), tiny_text.size(), off.size(), emoji.size()])
	for x in small.slice(0, 12): print("  SMALL ", x)
	for x in dead.slice(0, 8): print("  DEAD ", x)
	for x in tiny_text.slice(0, 8): print("  TINY ", x)
	for x in off.slice(0, 8): print("  OFF ", x)
	for x in emoji: print("  EMOJI ", x)

func _walk(n: Node, small: Array, dead: Array, tiny: Array, off: Array, emoji: Array) -> void:
	if n is CanvasItem and not n.is_visible_in_tree():
		return
	if n is Control:
		var c: Control = n
		var r := c.get_global_rect()
		var txt := ""
		if c is Label or c is Button or c is LineEdit:
			txt = c.text
		if (c is BaseButton or c is LineEdit) and c.mouse_filter != Control.MOUSE_FILTER_IGNORE and r.size.x > 1:
			if min(r.size.x, r.size.y) < 44.0 and vp_rect.intersects(r):
				small.append("%s '%s' %dx%d @%d,%d" % [c.get_class(), txt.left(20), r.size.x, r.size.y, r.position.x, r.position.y])
			if c is BaseButton and not c.disabled and c.get_signal_connection_list("pressed").is_empty() and c.get_signal_connection_list("toggled").is_empty() and c.get_signal_connection_list("button_down").is_empty() and c.get_signal_connection_list("gui_input").is_empty():
				dead.append("%s '%s' %s" % [c.get_class(), txt.left(20), c.get_path()])
		if txt != "" and (c is Label or c is Button):
			var fs := c.get_theme_font_size("font_size")
			if fs < 14:
				tiny.append("%d '%s'" % [fs, txt.left(30)])
			if r.size.x > 1 and not vp_rect.encloses(r.grow(-1)) and vp_rect.intersects(r):
				off.append("'%s' %s" % [txt.left(30), r])
			for i in txt.length():
				var cp := txt.unicode_at(i)
				if cp >= 0x1F000 or (cp >= 0x2600 and cp <= 0x27BF and cp != 0x2605 and cp != 0x2606):
					emoji.append("'%s'" % txt.left(30))
					break
	for ch in n.get_children():
		_walk(ch, small, dead, tiny, off, emoji)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
