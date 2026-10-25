extends Screen

func build() -> void:
	header("SETTINGS")
	var p := UI.panel()
	var v := UI.vb(12)
	p.add_child(v)
	var s: Dictionary = Game.S.settings
	v.add_child(_row("Battle speed", "x%d" % int(s.speed), func():
		s.speed = (int(s.speed) % 3) + 1
		Game.mark()
		rebuild()))
	v.add_child(_row("Music", "ON" if s.get("music", true) else "OFF", func():
		s.music = not s.get("music", true)
		Game.mark()
		Sfx.refresh_music("city")
		rebuild()))
	v.add_child(_row("Sound effects", "ON" if s.get("sfx", true) else "OFF", func():
		s.sfx = not s.get("sfx", true)
		Game.mark()
		rebuild()))
	v.add_child(_row("Auto battle by default", "ON" if s.auto else "OFF", func():
		s.auto = not s.auto
		Game.mark()
		rebuild()))
	v.add_child(_row("Fullscreen", "ON" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "OFF", func():
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		rebuild()))
	v.add_child(_row("Replay tutorial", "Show", func():
		Game.S.tutorial_done = false
		Game.S.ftue = 0
		main.home()))
	v.add_child(_row("Save now", "Save", func():
		Game.save_game()
		Game.say("Saved")))
	# developer rows: debug builds (editor / portable exe) only, never in a release export
	if OS.is_debug_build():
		v.add_child(UI.cap("Developer", UI.HINT))
		v.add_child(_row("Free IAP (dev mode)", "ON" if s.free_iap else "OFF", func():
			s.free_iap = not s.free_iap
			Game.mark()
			rebuild()))
		v.add_child(_row("Grant test items", "Grant", func(): main.show_rewards("Test Kit", Game.grant_test_kit(), rebuild), "ghost"))
		v.add_child(UI.lbl("Save file: " + ProjectSettings.globalize_path(Game.save_path), 14, UI.DIM))
	v.add_child(_row("Delete save and restart", "Reset", func(): main.confirm("This permanently deletes your progress.", func():
		Game.reset_save()
		main.stack.clear()
		main.replace("login")), "danger"))
	root.add_child(p)

func _row(label: String, value: String, cb: Callable, kind := "primary") -> HBoxContainer:
	var h := UI.hb(10)
	var l := UI.lbl(label, 17)
	UI.expand(l)
	h.add_child(l)
	h.add_child(UI.btn(value, cb, kind, 140))
	return h
