extends Screen
## Recruitment as a back-alley pawn shop: pick a contract case, the broker slides it across the
## counter, the latches pop, the lid opens and the recruit rises out in its rarity colour.

const CASES := ["uncommon", "rare", "epic", "legendary"]

var sel := "rare"
var case_node: ContractCase
var shop: PawnShop
var busy := false

func build() -> void:
	show_nav = true
	bg_mode = "none"
	screen_title = "Recruitment"
	subtitle = "The Fence  •  Pawn & Contracts"
	sel = String(params.get("sel", _default_case()))
	busy = false
	shop = PawnShop.new()
	shop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop.offset_top = -64
	add_child(shop)
	bleed.append(shop)
	move_child(shop, 0)
	var sign := UI.lbl("PAWN", 64, UI.MAGENTA)
	var bf := Art.font(true)
	if bf:
		sign.add_theme_font_override("font", bf)
	sign.add_theme_color_override("font_shadow_color", Color(UI.MAGENTA, 0.45))
	sign.add_theme_constant_override("shadow_outline_size", 10)
	sign.position = Vector2(60, 30)
	add_child(sign)
	var tw := sign.create_tween().set_loops()
	tw.tween_property(sign, "modulate:a", 1.0, 1.6)
	tw.tween_property(sign, "modulate:a", 0.35, 0.05)
	tw.tween_property(sign, "modulate:a", 1.0, 0.05)
	tw.tween_property(sign, "modulate:a", 0.5, 0.04)
	tw.tween_property(sign, "modulate:a", 1.0, 0.06)
	var nq := UI.cap("No questions", UI.CYAN, 15)
	nq.position = Vector2(68, 112)
	add_child(nq)
	# case shelf
	var left := UI.vb(8)
	left.position = Vector2(20, 186)
	left.custom_minimum_size.x = 250
	left.add_child(UI.cap("Your cases"))
	for r in CASES:
		left.add_child(_case_btn(r))
	add_child(left)
	# odds price tag
	add_child(_price_tag())
	# the case on the counter
	case_node = ContractCase.new()
	case_node.col = Data.RARITY_COLOR[sel]
	case_node.label = "%s CONTRACT" % sel.to_upper()
	add_child(case_node)
	_place_case(false)
	resized.connect(func(): if not busy: _place_case(false))
	# CTAs
	var n := Game.item_count(["contract", sel])
	var row := UI.hb(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -74
	row.offset_bottom = -16
	var b1 := UI.btn("OPEN ×1", func(): _open(1), "primary", 200, 16)
	b1.custom_minimum_size.y = 56
	b1.disabled = n < 1
	b1.set_meta("coach", "open1")
	row.add_child(b1)
	var b10 := UI.btn("OPEN ×10", func(): _open(10), "gold", 240, 18)
	b10.custom_minimum_size.y = 56
	b10.disabled = n < 10
	row.add_child(b10)
	row.name = "Ctas"
	add_child(row)

func _default_case() -> String:
	for r in ["rare", "uncommon", "epic", "legendary"]:
		if Game.item_count(["contract", r]) > 0:
			return r
	return "rare"

func _case_btn(r: String) -> Button:
	var col: Color = Data.RARITY_COLOR[r]
	var on := r == sel
	var owned := Game.item_count(["contract", r])
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(250, 60)
	b.add_theme_stylebox_override("normal", UI._sb_selected(col, UI.NOTCH, 0) if on else UI._sb(Color(UI.DEEP, 0.92), UI.LINE, 1, UI.NOTCH, 0))
	b.add_theme_stylebox_override("hover", UI._sb(Color(col, 0.2), col, 2, UI.NOTCH, 0))
	b.add_theme_stylebox_override("pressed", UI._sb(Color(col, 0.3), col, 2, UI.NOTCH, 0))
	var h := UI.hb(12)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 14
	var mini_case := ColorRect.new()
	mini_case.color = Color("#3A3444")
	mini_case.custom_minimum_size = Vector2(46, 30)
	mini_case.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var led := ColorRect.new()
	led.color = col
	led.position = Vector2(0, 24)
	led.size = Vector2(46, 6)
	mini_case.add_child(led)
	h.add_child(mini_case)
	var v := UI.vb(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(UI.cap(r, col))
	v.add_child(UI.lbl("Owned %d" % owned, 15, UI.TEXT))
	h.add_child(v)
	UI._ignore_mouse(h)
	b.add_child(h)
	b.modulate.a = 1.0 if owned > 0 else 0.6
	b.pressed.connect(func():
		if busy:
			return
		params.sel = r
		rebuild())
	return b

func _price_tag() -> Control:
	var tag := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#E9DFC8")
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 10
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 16
	tag.add_theme_stylebox_override("panel", sb)
	var v := UI.vb(6)
	var t := UI.disp("Odds  •  " + sel, 15, Color("#1A1410"))
	v.add_child(t)
	var rates: Dictionary = Data.CONTRACT_RATES[sel]
	for k in rates:
		var row := UI.hb()
		row.add_child(UI.lbl(U.cap(k), 16, Color("#1A1410")))
		row.add_child(UI.spacer())
		row.add_child(UI.lbl("%s%%" % str(rates[k]), 16, Color("#1A1410")))
		v.add_child(row)
	v.add_child(UI.lbl("Scrap: %d / %d builds a case" % [Game.item_count(["scrap", sel]), Data.SCRAP_TO_CONTRACT], 13, Color("#4A4030")))
	tag.add_child(v)
	tag.custom_minimum_size.x = 230
	tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tag.offset_left = -270
	tag.offset_right = -40
	tag.offset_top = 200
	tag.rotation = deg_to_rad(4)
	return tag

func _place_case(front: bool) -> void:
	var cx := size.x / 2.0
	case_node.scale = Vector2.ONE * (1.2 if front else 0.62)
	case_node.position = Vector2(cx - 140, (330.0 if front else 200.0) - 64)

func _open(n: int) -> void:
	if busy:
		return
	var got: Array = []
	for i in n:
		var w = Game.open_contract(sel)
		if w != null:
			got.append(w)
	if got.is_empty():
		err("No %s contracts" % sel)
		return
	busy = true
	get_node("Ctas").visible = false
	var best: Dictionary = got[0]
	for w in got:
		if Data.rarity_idx(Game.tpl(w).rarity) > Data.rarity_idx(Game.tpl(best).rarity):
			best = w
	var bcol: Color = Data.RARITY_COLOR[Game.tpl(best).rarity]
	var cx := size.x / 2.0
	Sfx.play("slide")
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(case_node, "position", Vector2(cx - 140, 330.0 - 64), 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(case_node, "scale", Vector2.ONE * 1.2, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	for i in 3:
		tw.tween_callback(func(): Sfx.play("latch", 1.0 + i * 0.08))
		tw.tween_property(case_node, "latch_flash", 1.0, 0.08)
		tw.tween_property(case_node, "latch_flash", 0.0, 0.08)
	tw.tween_callback(func():
		case_node.col = bcol
		Sfx.play("open"))
	tw.tween_property(case_node, "lid_open", 1.0, 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _reveal(got, best, bcol))

func _reveal(got: Array, best: Dictionary, bcol: Color) -> void:
	var beam := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(bcol, 0.55))
	g.set_color(1, Color(bcol, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.85)
	gt.fill_to = Vector2(1.0, 0.85)
	beam.texture = gt
	beam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	beam.size = Vector2(560, 480)
	beam.position = Vector2(size.x / 2.0 - 280, -60)
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.modulate.a = 0.0
	add_child(beam)
	move_child(beam, case_node.get_index())
	create_tween().tween_property(beam, "modulate:a", 1.0, 0.3)
	Sfx.play("legendary" if Data.rarity_idx(Game.tpl(best).rarity) >= 3 else "reveal")
	var best_uid: String = best.uid
	var card := UI.warlord_card(best, func(): main.go("warlord", {"uid": best_uid}))
	card.scale = Vector2(1.3, 1.3)
	card.pivot_offset = Vector2(59, 75)
	card.position = Vector2(size.x / 2.0 - 59, 200)
	card.modulate.a = 0.0
	add_child(card)
	var ct := create_tween().set_parallel(true)
	ct.tween_property(card, "position:y", 70.0, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ct.tween_property(card, "modulate:a", 1.0, 0.3)
	var rar: String = Game.tpl(best).rarity
	var pull := UI.disp("%s pull" % rar if got.size() == 1 else "%d recruits  •  best: %s" % [got.size(), rar], 22, bcol)
	pull.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pull.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	pull.offset_left = -300
	pull.offset_right = 300
	pull.offset_top = 312
	add_child(pull)
	var nm := UI.disp(Game.tpl(best).name, 26, bcol)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	nm.offset_left = -300
	nm.offset_right = 300
	nm.offset_top = 342
	add_child(nm)
	var bt := Game.tpl(best)
	var tags := UI.hb(10)
	tags.alignment = BoxContainer.ALIGNMENT_CENTER
	tags.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tags.offset_left = -400
	tags.offset_right = 400
	tags.offset_top = 384
	tags.add_child(UI.class_tag(bt.cls))
	tags.add_child(UI.syn_tag(bt.syn))
	tags.add_child(UI.align_tag(bt.align))
	add_child(tags)
	var row := UI.hb(14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	row.offset_top = -74
	row.offset_bottom = -16
	if got.size() > 1:
		row.add_child(UI.btn("SEE ALL %d" % got.size(), func(): _all(got), "primary", 200, 16))
	row.add_child(UI.btn("NEXT CASE", func(): rebuild(), "gold", 220, 18))
	add_child(row)
	for c in row.get_children():
		c.custom_minimum_size.y = 56

func _all(list: Array) -> void:
	var v := UI.vb(10)
	var f := UI.flow(10)
	f.alignment = FlowContainer.ALIGNMENT_CENTER
	for w in list:
		var wuid: String = w.uid
		f.add_child(UI.warlord_card(w, func():
			main.close_modal()
			main.go("warlord", {"uid": wuid})))
	v.add_child(f)
	main.modal("New recruits", v, true)
