extends Node
## Resolution matrix: shoots the main screens at phone, tablet, desktop and 4K sizes. Run windowed:
##   NW_SAVE=res godot --path . res://tests/review/res/ShotsRes.tscn -- --nwtest [--only=3840x2160]
## Sizes bigger than the monitor work because the window is made borderless at (0,0) and resized from
## script (Windows allows a borderless window larger than the desktop); the viewport texture then has
## exactly the target pixel size, so each PNG is what a real device of that size would show.

var OUT := "user://shots_res/"   # --out=<dir> (under user://) for before/after sets
const SIZES := [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160),
	Vector2i(2400, 1080), Vector2i(2048, 1536), Vector2i(3440, 1440)]
var main
var issues := []
var tex_scale := {}   # "<size> <path>" -> [min, max] screen px per texel

func _ready() -> void:
	Game.reset_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	main.current._new()
	await _frames(3)
	main.close_modal()
	Game.S.tutorial_done = true
	Game.S.player.level = 30
	Game.take_new_unlocks()
	Game.S.items.contract.rare = 12
	for i in 12:
		Game.open_contract("rare")
	var w: Dictionary = Game.S.roster[0]
	for slot in Data.GEAR_SLOTS:
		for it in Game.S.equip:
			if it.slot == slot and it.owner == "":
				Game.equip_on(w, it)
				break
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	var sizes: Array = SIZES
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--size="):   # any WxH list, e.g. --size=5120x1440,1080x1920
			sizes = []
			for one in a.substr(7).split(","):
				var p := one.split("x")
				sizes.append(Vector2i(int(p[0]), int(p[1])))
		if a.begins_with("--out="):
			OUT = "user://" + a.substr(6).trim_suffix("/") + "/"
	for s in sizes:
		var tag := "%dx%d" % [s.x, s.y]
		if only != "" and only != tag:
			continue
		await _resize(s)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + tag))
		await _matrix(tag, w)
	print("RES ISSUES: ", issues.size())
	for i in issues:
		print("  ", i)
	for k in tex_scale.keys():
		var r: Array = tex_scale[k]
		if r[1] > 1.3 or r[0] < 0.55:
			print("TEX ", k, " min=%.2f max=%.2f" % r)
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _matrix(tag: String, w: Dictionary) -> void:
	main.home()
	await _frames(6)
	await _shot(tag, "01_city")
	for s in ["fight", "campaign", "hideouts", "shop", "recruit", "arena", "armory", "gang", "missions", "settings"]:
		main.go(s)
		await _frames(5)
		await _shot(tag, "10_" + s)
	main.go("campaign", {"d": 0, "loc": 0})
	await _frames(6)
	await _shot(tag, "11_campaign_diorama")
	main.go("hideout", {"id": "vikings"})
	await _frames(6)
	await _shot(tag, "12_hideout_vikings")
	main.go("warlord", {"uid": w.uid})
	await _frames(6)
	await _shot(tag, "20_armoury_gear")
	main.current._go_page("neuronet")
	await _frames(4)
	await _shot(tag, "21_armoury_neuronet")
	main.go("squad", {"enc": Content.build_campaign(0, 0, 0)})
	await _frames(6)
	await _shot(tag, "30_squad")
	Game.S.settings.auto = false
	main.current._start()
	await get_tree().create_timer(2.5).timeout
	await _shot(tag, "31_battle")

## Borderless at the origin so Windows keeps sizes larger than the desktop.
func _resize(s: Vector2i) -> void:
	var win := get_window()
	win.mode = Window.MODE_WINDOWED
	win.borderless = true
	win.position = Vector2i.ZERO
	win.size = s
	await _frames(6)
	if win.size != s:
		issues.append("window %s came out %s" % [s, win.size])

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(tag: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + tag + "/" + name + ".png")
	_audit(tag + "/" + name)

## Flags visible buttons/labels that stick out of the window, and 3D views rendering below screen pixels.
func _audit(where: String) -> void:
	var vr := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).grow(2)
	var px := get_viewport().get_final_transform().get_scale().x
	var out := []
	for n in main.find_children("*", "Control", true, false):
		var c: Control = n
		if not c.is_visible_in_tree():
			continue
		var tex: Texture2D = null
		if c is TextureRect:
			tex = c.texture
		elif c is TextureButton:
			tex = c.texture_normal
		elif c is NinePatchRect:
			tex = null   # nine-patches stretch by design
		if tex != null and tex.resource_path != "" and tex.get_width() > 0:
			var sx: float = c.get_global_rect().size.x * px / tex.get_width()
			if c is TextureRect and c.stretch_mode in [TextureRect.STRETCH_TILE, TextureRect.STRETCH_KEEP]:
				sx = px
			var key := "%s %s" % [where.get_slice("/", 0), tex.resource_path.get_file()]
			var r: Array = tex_scale.get(key, [99.0, 0.0])
			tex_scale[key] = [min(r[0], sx), max(r[1], sx)]
		if (c is Button or c is Label) and not _clipped(c):
			var r := c.get_global_rect()
			if r.size.x > 1 and not vr.encloses(r):
				out.append("%s'%s'" % [c.get_class(), (c.text if "text" in c else "").left(18)])
	for n in main.find_children("*", "SubViewport", true, false):
		var vp: SubViewport = n
		var host: Control = vp.get_parent() as Control
		if host and host.is_visible_in_tree() and host.size.x > 0:
			var want: float = get_viewport().get_final_transform().get_scale().x * host.get_global_transform_with_canvas().get_scale().x * host.size.x
			if vp.size.x < want * 0.95 and not OS.has_feature("mobile"):
				issues.append("%s: 3D %s renders %d px for %d screen px" % [where, host.get_class(), vp.size.x, int(want)])
	if not out.is_empty():
		issues.append("%s: %d off-screen: %s" % [where, out.size(), ", ".join(out.slice(0, 6))])

func _clipped(c: Control) -> bool:
	var p := c.get_parent()
	while p is Control:
		if p is ScrollContainer or (p as Control).clip_contents:
			return true
		p = p.get_parent()
	return false

