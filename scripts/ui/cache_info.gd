class_name CacheInfo
## Pit Cache contents and chances, read straight from the GDD "Pit Cache Rewards" table.
## Each row rolls on its own (Game.open_cache), so a cache can give several rows at once.

## Normalised chance in percent for a GDD cache row.
static func chance(row: Array) -> float:
	var ch := float(row[1])
	if ch < 1.5:
		ch *= 100.0
	return ch

## Plain-text list of a cache's rows, for tooltips: "text - 50%".
static func text(kind: String) -> String:
	var name := _name(kind)
	if not Data.GDD.caches.has(name):
		return ""
	var lines: Array = [name + " - each row rolls separately:"]
	for row in Data.GDD.caches[name]:
		var ch := chance(row)
		lines.append("%s - %s" % [String(row[0]), "always" if ch >= 100.0 else "%d%%" % int(round(ch))])
	return "\n".join(lines)

## Cache name inside a reward text such as "2x Meager Cache" ("" when none).
static func kind_in(text: String) -> String:
	var m := RegEx.create_from_string("(Meager|Substantial|Sublime|Exalted) Cache").search(text)
	return m.get_string(0) if m else ""

## A flat button that opens the cache modal (used on reward cells).
static func link(main, label: String, kind: String, size := 14, col := UI.DIM) -> Button:
	var b := Button.new()
	b.flat = true
	b.text = label + "  (i)"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", col)
	b.add_theme_color_override("font_hover_color", UI.CYAN)
	b.tooltip_text = text(kind)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func(): show(main, kind))
	return b

## Accepts "Meager", "meager" or "Meager Cache".
static func _name(kind: String) -> String:
	var k := kind.strip_edges()
	if not k.to_lower().ends_with("cache"):
		k += " Cache"
	return k.substr(0, 1).to_upper() + k.substr(1)

## Modal listing the cache's contents and chances.
static func show(main, kind: String) -> void:
	var name := _name(kind)
	if not Data.GDD.caches.has(name):
		return
	var v := UI.vb(8)
	v.add_child(UI.lbl("Every row rolls separately, so one cache can give several of these.", 14, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	for row in Data.GDD.caches[name]:
		var ch := chance(row)
		var h := UI.hb(10)
		var t := UI.lbl(String(row[0]), 15, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(t)
		h.add_child(UI.lbl("Always" if ch >= 100.0 else "%d%%" % int(round(ch)), 15, UI.GREEN if ch >= 100.0 else UI.GOLD))
		v.add_child(h)
	main.modal(name, v)
