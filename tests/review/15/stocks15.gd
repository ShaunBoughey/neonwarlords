extends Node
## Wave 2: Stocks Vault +25 cap row (buy x4 through confirm, then disabled).
const OUT := "user://shots_15/"
var main

func _ready() -> void:
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
	main.close_modal()
	for k in 5:
		main.go("shop", {"sec": "Trinium Vault"})
		await _frames(4)
		if k == 0:
			await _shot("50_stocks_row")
		var b := _find_btn(main.current, "£1.99", true)
		print("try %d: button %s disabled=%s" % [k, b != null, b.disabled if b else "-"])
		if b == null or b.disabled:
			break
		b.pressed.emit()
		await _frames(30)
		if k == 0:
			await _shot("51_stocks_confirm")
		var ok := _find_btn(main, "BUY", false)
		if ok:
			ok.pressed.emit()
		await _frames(4)
		print("  cap_bonus=", Game.S.stocks.cap_bonus, " cap=", Game.stocks_cap())
	main.go("shop", {"sec": "Trinium Vault"})
	await _frames(4)
	await _shot("52_stocks_maxed")
	Game.S.settings.free_iap = false
	Game.S.stocks.cap_bonus = 0
	main.go("shop", {"sec": "Trinium Vault"})
	await _frames(4)
	var b2 := _find_btn(main.current, "£1.99", true)
	b2.pressed.emit()
	await _frames(4)
	print("IAP off: cap_bonus=", Game.S.stocks.cap_bonus, " overlay children=", main.overlay.get_child_count())
	get_tree().quit()

func _find_btn(n: Node, prefix: String, any: bool) -> Button:
	for c in n.get_children():
		if c is Button and String(c.text).begins_with(prefix) and (any or not c.disabled):
			return c
		var r = _find_btn(c, prefix, any)
		if r: return r
	return null

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
