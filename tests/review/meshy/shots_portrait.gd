extends Node
## Rendered card portraits (assets/portraits/<tpl>.png): real screens + every portrait size side by side.
## godot --path . res://tests/review/meshy/ShotsPortrait.tscn -- --nwtest   (set NW_SAVE=<tag>)
const OUT := "user://shots_meshy/"
const TPL := "deacon_chainz"
const OTHER := "raiden_x"          # procedural portrait, for comparison
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
	Game.S.player.level = 30
	Game.take_new_unlocks()
	var d := Game.add_warlord(TPL, true)
	Game.add_warlord(OTHER, true)
	Game.S.squads.last = [d.uid] + Game.S.squads.last.slice(0, 3)
	main.go("armory")
	await _frames(5)
	await _shot("p01_roster")
	main.go("squad", {"enc": Content.build_campaign(0, 0, 0)})
	await _frames(5)
	await _shot("p02_squad_select")
	main.go("hideout", {"id": "trolls"})
	await _frames(8)
	await _shot("p03_hideout_trolls_boss")
	# every portrait size the game uses, plus dim/flash, next to a procedural portrait
	main.go("armory")
	await _frames(3)
	var sheet := ColorRect.new()
	sheet.color = Color("#0A0F1C")
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_child(sheet)
	var row := HBoxContainer.new()
	row.position = Vector2(40, 60)
	row.add_theme_constant_override("separation", 24)
	sheet.add_child(row)
	for tpl in [TPL, OTHER]:
		var w: Dictionary = Game.S.roster.filter(func(x): return x.tpl == tpl)[0]
		row.add_child(UI.warlord_card(w, func(): pass))                 # 118x150 (roster, recruit reveal)
		row.add_child(UI.warlord_card(w, func(): pass, true))           # selected
		row.add_child(UI.warlord_card(w, func(): pass, false, true))    # compact 96x122 (squad)
		for s in [70, 104]:                                              # campaign tile / result tile
			var p := UI.portrait(tpl, s)
			row.add_child(p)
	var row2 := HBoxContainer.new()
	row2.position = Vector2(40, 300)
	row2.add_theme_constant_override("separation", 24)
	sheet.add_child(row2)
	for mode in ["dim", "flash"]:
		var p: Portrait = UI.portrait(TPL, 104)
		if mode == "dim": p.dim = true
		else: p.flash = 0.6
		row2.add_child(p)
	var big := UI.portrait(TPL, 256)
	big.custom_minimum_size = Vector2(256, 320)
	row2.add_child(big)
	await _frames(5)
	await _shot("p04_sizes_sheet")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
