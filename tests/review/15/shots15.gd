extends Node
## Review 15: Shop (Trinium Exchange) + Battle Pass screenshots and button probe.
const OUT := "user://shots_15/"
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
	main.home()
	await _frames(4)
	main.close_modal()
	var secs: Array = ["Featured"] + Data.GDD.shop.keys() + ["Subscriptions"]
	var k := 0
	for s in secs:
		main.go("shop", {"sec": s})
		await _frames(4)
		await _shot("%02d_shop_%s" % [k, String(s).to_lower().replace(" ", "_")])
		_buttons("shop " + s)
		k += 1
	# scroll Packs / Market to bottom
	for s in ["Packs", "Trinium Market"]:
		main.go("shop", {"sec": s})
		await _frames(4)
		for sc in main.current.find_children("*", "ScrollContainer", true, false):
			sc.scroll_vertical = 100000
		await _frames(3)
		await _shot("%02d_shop_%s_bottom" % [k, s.to_lower().replace(" ", "_")])
		k += 1
	# buy a pack -> rewards modal
	main.go("shop", {"sec": "Packs"})
	await _frames(4)
	var b := _find_btn(main.current, "£4.99")
	if b:
		b.pressed.emit()
		await _frames(40)
		await _shot("20_shop_buy_confirm")
		var buy := _find_btn(main, "BUY")
		if buy:
			buy.pressed.emit()
			await _frames(40)
			await _shot("20b_shop_buy_rewards")
	main.close_modal()
	# hit limit on Large Epic (1)
	Game.shop_buy("Packs", 4)
	main.go("shop", {"sec": "Packs"})
	await _frames(4)
	await _shot("21_shop_packs_after_limit")
	# Free IAP off
	Game.S.settings.free_iap = false
	main.go("shop", {"sec": "Featured"})
	await _frames(4)
	await _shot("22_shop_iap_off")
	main.go("shop", {"sec": "Subscriptions"})
	await _frames(4)
	await _shot("23_subs_iap_off")
	Game.S.settings.free_iap = true
	main.go("shop", {"sec": "Subscriptions"})
	await _frames(4)
	var sb := _find_btn(main.current, "£9.99")
	if sb:
		sb.pressed.emit()
		await _frames(4)
	await _shot("24_subs_owned")
	var ob := _find_btn(main.current, "OPEN BATTLE PASS")
	if ob:
		ob.pressed.emit()
		await _frames(4)
		print("OPEN BATTLE PASS -> ", main.current.get_script().resource_path)
	# battle pass
	main.go("battle_pass")
	await _frames(4)
	await _shot("30_bp_fresh")
	_buttons("bp fresh")
	Game.bp_add_merits(20 * 7 + 5)
	for c in Game.bp_challenges(false):
		Game.track(Data.BP_DAILY.filter(func(d): return d.id == c.id)[0].ev, c.target)
	main.go("battle_pass")
	await _frames(4)
	await _shot("31_bp_lv7_claimables")
	_buttons("bp lv7")
	var cl := _find_btn(main.current, "Claim")
	if cl:
		cl.pressed.emit()
		await _frames(4)
		await _shot("32_bp_after_claim")
	main.close_modal()
	Game.bp_buy_premium(true)
	main.go("battle_pass")
	await _frames(4)
	await _shot("33_bp_premium25")
	_buttons("bp premium")
	Game.S.bp.merits = 100 * 20
	main.go("battle_pass")
	await _frames(4)
	await _shot("34_bp_lv100")
	Game.add_cur("credits", 5000000)
	Game.add_cur("pitCoin", 5000)
	Game.safehouse_upgrade("paragon", Data.SAFEHOUSE_NODES.keys()[0])
	Game.S.gang["motd"] = "Bastion stage 2 today - everyone hit it twice."
	for s in ["plaza", "gang", "login_rewards", "safehouse", "missions"]:
		main.close_modal()
		main.go(s)
		await _frames(6)
		await _shot("40_" + s)
		_buttons(s)
	main.close_modal()
	main.go("missions", {"tab": "Monthly"})
	await _frames(4)
	await _shot("41_missions_monthly")
	main.go("shop", {"sec": "Trinium Market"})
	Game.add_cur("heist", 1)
	main.current.rebuild()
	await _frames(4)
	for sc in main.current.find_children("*", "ScrollContainer", true, false):
		sc.scroll_vertical = 100000
	await _frames(3)
	await _shot("42_shop_market_heist_guard")
	main.go("battle_pass")
	await _frames(4)
	var ca := _find_btn(main.current, "CLAIM ALL")
	if ca:
		ca.pressed.emit()
		await _frames(40)
		await _shot("35_bp_claim_all")
	main.close_modal()
	# season gap screen
	main.go("shop")
	await _frames(2)
	print("DONE")
	get_tree().quit()

func _find_type(n: Node, t: String) -> Node:
	for c in n.get_children():
		if c.get_class() == t:
			return c
		var r = _find_type(c, t)
		if r: return r
	return null

func _find_btn(n: Node, prefix: String) -> Button:
	for c in n.get_children():
		if c is Button and String(c.text).begins_with(prefix) and not c.disabled:
			return c
		var r = _find_btn(c, prefix)
		if r: return r
	return null

func _buttons(tag: String) -> void:
	var out: Array = []
	_collect(main, out)
	print("BUTTONS[", tag, "] ", out)

func _collect(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button and c.is_visible_in_tree():
			out.append("%s%s" % [c.text if c.text != "" else ("<" + c.name + ">"), " (disabled)" if c.disabled else ""])
		_collect(c, out)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
