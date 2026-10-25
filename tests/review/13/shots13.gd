extends Node
## Review 13: Missions (jobs + ambitions), Login Rewards and Safehouse screenshots and button probe.
## Run windowed: NW_SAVE=13 godot --path . res://tests/review/13/Shots13.tscn -- --nwtest
const OUT := "user://shots_13/"
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
	await _frames(2)
	await _shot("00_city")
	_buttons("city")
	# --- jobs: some done, some claimed
	for ev in ["pitBrawl", "den", "plazaBuy", "warlordLevel"]:
		Game.track(ev, 12)
	Game.claim_job("daily", 0)
	main.go("missions")
	await _frames(4)
	await _shot("01_missions_daily")
	_buttons("missions_daily")
	for t in ["Weekly", "Monthly"]:
		main.go("missions", {"tab": t})
		await _frames(4)
		await _shot("02_missions_" + t.to_lower())
	# claim through the screen
	main.go("missions", {"tab": "Daily"})
	await _frames(4)
	var cb = _find_btn(main.current, "CLAIM")
	if cb:
		cb.pressed.emit()
		await get_tree().create_timer(1.0).timeout
		await _shot("03_missions_claim_modal")
		_buttons("rewards_modal")
		main.close_modal()
	# --- ambitions: give progress for a few
	Game.S.campaign.stars[Game.campaign_key(0, 0, 6)] = 3
	Game.S.campaign.stars[Game.campaign_key(0, 1, 6)] = 3
	Game.claim_ambition("Campaign", Game.ambitions_list("Campaign")[0])
	for c in Data.GDD.ambitions:
		main.go("missions", {"tab": c})
		await _frames(4)
		await _shot("04_amb_" + c.replace(" & ", "_").to_lower())
	_buttons("amb_bastion")
	# tier 2 reveal: claim all of tier 1 campaign by force
	for a in Game.ambitions_list("Campaign"):
		if a.tier == 1 and not a.claimed:
			Game.S.amb.claimed.Campaign.append(a.key)
	main.go("missions", {"tab": "Campaign"})
	await _frames(4)
	await _shot("05_amb_campaign_tier2")
	# --- login rewards
	Game.S.login.progress = 9
	Game.S.login.claimed = false
	main.go("login_rewards")
	await _frames(4)
	await _shot("06_login_unclaimed")
	_buttons("login")
	var lb = _find_btn(main.current, "CLAIM DAY")
	if lb:
		lb.pressed.emit()
		await get_tree().create_timer(1.0).timeout
		await _shot("07_login_claim_modal")
		main.close_modal()
		await _frames(4)
		await _shot("08_login_claimed")
	Game.S.login.progress = 30
	Game.S.login.claimed = false
	main.current.rebuild()
	await _frames(4)
	var lb2 = _find_btn(main.current, "CLAIM DAY")
	if lb2:
		lb2.pressed.emit()
		await get_tree().create_timer(1.0).timeout
		await _shot("09b_login_day31_modal")
		main.close_modal()
	await _frames(4)
	await _shot("09_login_day31")
	# --- safehouse
	main.go("safehouse")
	await _frames(4)
	await _shot("10_safehouse_empty")
	_buttons("safehouse_poor")
	Game.add_cur("pitCoin", 8000)
	Game.safehouse_upgrade("paragon", "hpP")
	for i in 10:
		Game.safehouse_upgrade("renegade", "hack")
	for i in 4:
		Game.safehouse_upgrade("neutral", "cd")
	main.current.rebuild()
	await _frames(4)
	await _shot("11_safehouse_levels")
	_buttons("safehouse_rich")
	var pc0 := Game.cur("pitCoin")
	var ub = _find_btn(main.current, "225 PC")
	if ub:
		ub.pressed.emit()
		await _frames(4)
		print("safehouse button spent ", pc0 - Game.cur("pitCoin"), " paragon hpP lv ", Game.safehouse_level("paragon", "hpP"))
		await _shot("12_safehouse_after_click")
	# back button
	var bk = _find_btn(main, "<")
	print("cur screen before back: ", main._cur_name)
	main.back()
	await _frames(4)
	print("after back: ", main._cur_name)
	get_tree().quit()

func _find_btn(n: Node, prefix: String) -> Button:
	for c in n.get_children():
		if c is Button and c.is_visible_in_tree() and not c.disabled and String(c.text).begins_with(prefix):
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
		if c is BaseButton and c.is_visible_in_tree():
			var conns: int = c.pressed.get_connections().size() + c.gui_input.get_connections().size()
			var t: String = c.text if c is Button and c.text != "" else ("<" + c.name + ">")
			out.append("%s%s%s" % [t, " (disabled)" if c.disabled else "", " (NO HANDLER)" if conns == 0 else ""])
		_collect(c, out)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
