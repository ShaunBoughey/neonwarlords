extends Screen
## The Trinium Exchange: category rail, featured offer banner and offer cards.
## Real-money items are granted free in this build when "Free IAP" is on.

const FEATURED := "Warlord Pack"

func build() -> void:
	show_nav = true
	bg_tint = Color("#2A2006")
	screen_title = "Trinium Exchange"
	subtitle = "Free IAP dev mode" if Game.S.settings.free_iap and OS.is_debug_build() else ""
	var sections: Array = ["Featured"] + Data.GDD.shop.keys() + ["Subscriptions"]
	var sec: String = params.get("sec", "Featured")
	var items: Array = []
	for s in sections:
		items.append({"id": s, "name": s, "col": UI.GOLD, "dot": s == "Packs"})
	var rl := rail([{"label": "", "items": items}], sec, func(s):
		params.sec = s
		rebuild(), 220)
	rl.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	rl.offset_left = 20
	rl.offset_right = 240
	rl.offset_top = 10
	rl.offset_bottom = -16
	add_child(rl)
	var body := UI.vb(14)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.offset_left = 260
	body.offset_right = -20
	body.offset_top = 10
	body.offset_bottom = -16
	add_child(body)
	if not Game.S.settings.free_iap and OS.is_debug_build():
		body.add_child(UI.lbl("Real-money purchases are not connected in this prototype. Enable 'Free IAP (dev)' in Settings to test packs.", 14, UI.RED, HORIZONTAL_ALIGNMENT_LEFT, true))
	if sec == "Subscriptions":
		_subscriptions(body)
		return
	if sec == "Featured":
		# taller-than-16:9 windows (tablets) share the extra height between the banner and the cards
		var grow := tall_extra()
		var f := _find(FEATURED)
		if not f.is_empty():
			var bn := _banner(f.sec, f.i)
			bn.custom_minimum_size.y += grow * 0.4
			body.add_child(bn)
		var g := UI.grid(4, 14)
		for name in ["Small Rare Contracts Pack", "Equipment Pack", "Scavenger Pack", "Energy Boost"]:
			var o := _find(name)
			if not o.is_empty():
				var cd := _card(o.sec, o.i)
				cd.custom_minimum_size.y += grow * 0.6
				g.add_child(cd)
		body.add_child(g)
		return
	var grid := UI.grid(4, 14)
	var rows: Array = Data.GDD.shop[sec]
	for i in rows.size():
		grid.add_child(_card(sec, i))
	if sec == "Trinium Vault":
		grid.add_child(_stocks_card())
	body.add_child(UI.scroll(grid))

func _find(name: String) -> Dictionary:
	for s in Data.GDD.shop:
		var rows: Array = Data.GDD.shop[s]
		for i in rows.size():
			if String(rows[i][0]) == name:
				return {"sec": s, "i": i}
	return {}

func _limit(sec: String, i: int) -> Array:
	var row: Array = Data.GDD.shop[sec][i]
	var bought := Game.shop_bought_count(sec, i)
	var lim = row[3]
	if typeof(lim) == TYPE_STRING:
		return ["", false]
	# Trinium Market limits (the Pit refills) reset daily
	return ["%d / %d%s" % [bought, int(lim), " today" if sec == "Trinium Market" else ""], bought >= int(lim)]

func _buy_btn(sec: String, i: int, big := false) -> Button:
	var row: Array = Data.GDD.shop[sec][i]
	var cost: String = row[2]
	var real := cost.begins_with("GBP")
	var b: Button
	if real:
		b = UI.btn(cost.replace("GBP ", "£"), func(): _buy(sec, i), "gold" if Game.S.settings.free_iap else "ghost", 0, 20 if big else 16)
	else:
		b = UI.btn(cost, func(): _buy(sec, i), "primary", 0, 15)
	b.custom_minimum_size.y = 56 if big else 44
	b.disabled = _limit(sec, i)[1]
	# bought plans may overflow the daily cap of 5; they are kept
	if String(row[1]).contains("Heist Plan") and not real:
		b.tooltip_text = "Plans above 5 are kept (you hold %d)." % Game.cur("heist")
	if b.disabled and sec == "Trinium Market":
		b.tooltip_text = "Daily limit reached. Resets in " + U.dur(U.secs_to_next_day())
	return b

func _buy(sec: String, i: int) -> void:
	var row: Array = Data.GDD.shop[sec][i]
	if String(row[2]).ends_with("Trinium"):
		# Trinium buys can cost thousands per click: confirm first
		main.confirm("Buy %s (%s) for %s?" % [String(row[0]), String(row[1]), String(row[2])], func():
			main.show_rewards(String(row[0]), Game.shop_buy(sec, i), rebuild), "BUY")
		return
	if not String(row[2]).begins_with("GBP") or not Game.S.settings.free_iap:
		main.show_rewards(String(row[0]), Game.shop_buy(sec, i), rebuild)
		return
	# real-money packs: show the full contents and confirm before buying
	var v := UI.vb(14)
	v.add_child(UI.cap("Contains", UI.DIM, 13))
	v.add_child(UI.reward_chips(_contents(sec, i), 15))
	var h := UI.hb(10)
	h.add_child(UI.spacer())
	var dim_ref := []
	h.add_child(UI.btn("CANCEL", func(): main._close(dim_ref[0]), "ghost", 140))
	h.add_child(UI.btn("BUY  " + String(row[2]).replace("GBP ", "£"), func():
		main._close(dim_ref[0])
		main.show_rewards(String(row[0]), Game.shop_buy(sec, i), rebuild), "gold", 200, 16))
	dim_ref.append(main.modal(String(row[0]), v, false, true, h))

## Parsed contents of a shop row (deeds rows name their alignment in the title).
func _contents(sec: String, i: int) -> Array:
	var row: Array = Data.GDD.shop[sec][i]
	var desc := String(row[1])
	if desc.contains("Minor"):
		var al := String(row[0]).split(" ")[0].to_lower()
		return [{"k": "deeds", "align": al, "tier": "minor", "n": 30}, {"k": "deeds", "align": al, "tier": "major", "n": 20}, {"k": "deeds", "align": al, "tier": "grand", "n": 10}]
	return U.parse_rewards(desc)

func _banner(sec: String, i: int) -> Control:
	var row: Array = Data.GDD.shop[sec][i]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._sb(Color("#3A2606"), Color("#6E5414"), 1, UI.NOTCH, 0))
	p.custom_minimum_size.y = 250
	var stack := Control.new()
	stack.custom_minimum_size.y = 250
	p.add_child(stack)
	var sil := Silhouette.new()
	sil.rim = Color("#FFD36A")
	sil.flip = true
	sil.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	sil.offset_left = -360
	sil.offset_right = -110
	sil.offset_top = -10
	stack.add_child(sil)
	var v := UI.vb(8)
	v.position = Vector2(28, 24)
	v.custom_minimum_size.x = 540
	var tags := UI.hb(8)
	tags.add_child(UI.tag("Best value", UI.GOLD))
	var lim: Array = _limit(sec, i)
	if lim[0] != "":
		tags.add_child(UI.tag("Limit " + lim[0], Color("#FF8AA0")))
	for tg in tags.get_children():
		tg.add_theme_font_size_override("font_size", 13)
	v.add_child(tags)
	v.add_child(UI.disp(row[0], 36))
	var d := UI.lbl(row[1], 16, Color("#E8D9B0"), HORIZONTAL_ALIGNMENT_LEFT, true)
	d.custom_minimum_size.x = 520
	v.add_child(d)
	v.add_child(UI.spacer(false, 0, 6))
	var bb := _buy_btn(sec, i, true)
	bb.custom_minimum_size.x = 200
	bb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(bb)
	stack.add_child(v)
	return p

func _card(sec: String, i: int) -> Control:
	var row: Array = Data.GDD.shop[sec][i]
	var name: String = row[0]
	var desc: String = row[1]
	if name == "Raid Boss Ticket":
		desc += ". " + String(Data.REWARD_INFO.get("raidTicket", ""))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._sb(Color(UI.DEEP, 0.92), UI.LINE, 1, UI.NOTCH, 14))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.y = 250
	var v := UI.vb(6)
	p.add_child(v)
	var art := _art_for(name + " " + desc)
	var top := UI.hb()
	top.add_child(UI.cap(art[0], art[1]))
	top.add_child(UI.spacer())
	top.add_child(UI.lbl(_limit(sec, i)[0], 13, UI.DIM))
	v.add_child(top)
	var holder := CenterContainer.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.custom_minimum_size.y = 84
	holder.add_child(art[2])
	v.add_child(holder)
	var t := UI.lbl(name, 16, UI.TEXT)
	t.clip_text = true
	t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	t.tooltip_text = name
	t.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(t)
	var d := UI.lbl(desc, 14, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true)
	d.custom_minimum_size.y = 38
	d.max_lines_visible = 2
	d.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	d.tooltip_text = desc
	d.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(d)
	v.add_child(_buy_btn(sec, i))
	return p

## [category label, colour, art node] chosen from what the offer contains.
func _art_for(text: String) -> Array:
	var tl := text.to_lower()
	if "equipment" in tl:
		return ["Gear", UI.PURPLE, _gear_row(["chest", "weapon", "helmet"], "legendary")]
	if "implant" in tl:
		return ["Implants", UI.PURPLE, _gear_row(["limbs", "organs", "skeleton"], "epic")]
	if "contract" in tl:
		var r := "legendary" if "legendary" in tl else ("epic" if "epic" in tl else "rare")
		return ["Contracts", Data.RARITY_COLOR[r], _cases(r)]
	if "deed" in tl:
		return ["Deeds", UI.GREEN, Icon.make("ticket", UI.GREEN, 64)]
	if "fragment" in tl:
		return ["Neuronet", UI.CYAN, Art.icon(Art.mf_icon(1), Vector2(60, 78))]
	if "neon" in tl:
		return ["Neons", UI.GREEN, Art.icon(Art.neon_small("arm"), Vector2(80, 80))]
	if "heist" in tl or "firmware" in tl or "xp boost" in tl and "energy" in tl:
		return ["Progress", UI.GOLD, Icon.make("bag", UI.GOLD, 64)]
	if "credit" in tl or "investment" in tl:
		return ["Credits", UI.TEXT, Icon.make("coin", UI.TEXT, 64)]
	if "trinium" in tl:
		return ["Trinium", UI.CYAN, Icon.make("diamond", UI.CYAN, 64)]
	if "energy" in tl or "refill" in tl or "boost" in tl:
		return ["Boosts", UI.GOLD, Icon.make("bolt", UI.GOLD, 64)]
	return ["Bundle", UI.GOLD, Icon.make("bag", UI.GOLD, 64)]

func _gear_row(slots: Array, rarity: String) -> Control:
	var h := UI.hb(4)
	for s in slots:
		var c := Control.new()
		c.custom_minimum_size = Vector2(52, 63)
		c.add_child(Art.icon(Art.SLOT_BUTTON[s], Vector2(52, 63)))
		c.add_child(Art.rect(Art.equip_border(rarity), Vector2.ZERO, 1.0, Vector2(52, 63)))
		h.add_child(c)
	return h

## The Recruit counter's contract case, shrunk to card size (two stacked when the pack has several).
func _cases(r: String) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(142, 82)
	holder.clip_contents = true
	for k in 2:
		# scale a plain wrapper, not the case: the case centres its own pivot for the Recruit pop,
		# which shifted it out of the card on some layouts
		var wrap := Control.new()
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.scale = Vector2(0.42, 0.42)
		wrap.position = Vector2(k * 24, k * 12)
		var c := ContractCase.new()
		c.col = Data.RARITY_COLOR[r]
		c.label = ""
		wrap.add_child(c)
		holder.add_child(wrap)
	return holder

func _subscriptions(body: Control) -> void:
	var p := UI.panel(Color("#6E5414"), Color("#2A1C04"))
	var v := UI.vb(10)
	p.add_child(v)
	v.add_child(UI.tag("Subscription", UI.GOLD))
	v.add_child(UI.disp("Player Progress Double Rewards", 24))
	v.add_child(UI.lbl("Doubles the rewards of every player level from now on (energy, credits, contracts, trinium, firmware).", 15, Color("#E8D9B0"), HORIZONTAL_ALIGNMENT_LEFT, true))
	var owned: bool = Game.S.get("double_rewards", false)
	var b := UI.btn("OWNED" if owned else "£9.99", func():
		err(Game.buy_double_rewards())
		rebuild(), "gold" if Game.S.settings.free_iap else "ghost", 200, 18)
	b.custom_minimum_size.y = 56
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.disabled = owned
	v.add_child(b)
	body.add_child(p)
	var p2 := UI.panel()
	var v2 := UI.vb(8)
	p2.add_child(v2)
	v2.add_child(UI.disp("Battle Pass", 20))
	v2.add_child(UI.lbl("Premium track and the +25 level boost live on the Battle Pass screen.", 15, UI.DIM))
	var bp := UI.btn("OPEN BATTLE PASS", func(): main.go("battle_pass"), "primary", 240)
	bp.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v2.add_child(bp)
	body.add_child(p2)

## GDD Trinium Stocks: "additional caps being a microtransaction" (price is an open lever).
const STOCKS_PRICE := "£1.99"

func _stocks_buys() -> Array:
	var k: Dictionary = Data.get_script().get_script_constant_map()
	var step := int(k.get("STOCKS_CAP_STEP", 25))
	var buys := int(k.get("STOCKS_CAP_BUYS", 4))
	return [int(Game.S.stocks.get("cap_bonus", 0)) / max(1, step), buys, step]

func _stocks_card() -> Control:
	var info := _stocks_buys()
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._sb(Color(UI.DEEP, 0.92), UI.LINE, 1, UI.NOTCH, 14))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.custom_minimum_size.y = 250
	var v := UI.vb(6)
	p.add_child(v)
	var top := UI.hb()
	top.add_child(UI.cap("Stocks", UI.GREEN))
	top.add_child(UI.spacer())
	top.add_child(UI.lbl("%d / %d" % [info[0], info[1]], 13, UI.DIM))
	v.add_child(top)
	var holder := CenterContainer.new()
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.custom_minimum_size.y = 84
	holder.add_child(Icon.make("chart", UI.GREEN, 64))
	v.add_child(holder)
	v.add_child(UI.lbl("Stocks Vault +%d cap" % info[2], 16, UI.TEXT))
	var d := UI.lbl("Store %d more Trinium in your Stocks (cap now %d)." % [info[2], Game.stocks_cap()], 14, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true)
	d.custom_minimum_size.y = 38
	v.add_child(d)
	var iap: bool = Game.S.settings.free_iap
	var b := UI.btn("SOLD OUT" if info[0] >= info[1] else STOCKS_PRICE, func(): _buy_stocks(), "gold" if iap else "ghost", 0, 16)
	b.disabled = info[0] >= info[1] or not Game.has_method("buy_stocks_cap")
	v.add_child(b)
	return p

func _buy_stocks() -> void:
	if not Game.S.settings.free_iap:
		err("Real-money purchases are not connected in this build.")
		return
	var info := _stocks_buys()
	main.confirm("Raise your Stocks Vault cap by %d Trinium for %s? (%d of %d bought)" % [info[2], STOCKS_PRICE, info[0], info[1]], func():
		err(String(Game.call("buy_stocks_cap")))
		rebuild(), "BUY " + STOCKS_PRICE)
