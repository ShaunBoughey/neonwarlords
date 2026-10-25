extends Screen
## The Plaza: credit market refreshed hourly.

var _hour := -1
var _count: Label
var _tick := 0.0

func build() -> void:
	show_nav = true
	var h := header("THE PLAZA", UI.YELLOW)
	_count = UI.lbl("", 15, UI.DIM)
	h.add_child(_count)
	_update_count()
	var items := Game.plaza_items()
	_hour = int(Game.S.plaza.hour)
	var g := UI.grid(3, 14)
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i in items.size():
		var it: Dictionary = items[i]
		var bought: bool = Game.S.plaza.bought.has(i) or Game.S.plaza.bought.has(float(i))
		var r: Dictionary = it.r
		var col: Color = Data.RARITY_COLOR.get(r.get("r", ""), UI.CYAN)
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI._sb(Color(UI.DEEP, 0.92), UI.LINE, 1, UI.NOTCH, 14))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vb(6)
		p.add_child(v)
		var top := UI.hb()
		top.add_child(UI.cap(_category(r), col, 13))
		top.add_child(UI.spacer())
		if r.has("rank"):
			top.add_child(UI.lbl("Rank %d" % int(r.rank), 13, UI.DIM))
		v.add_child(top)
		var holder := CenterContainer.new()
		holder.custom_minimum_size.y = 76
		holder.add_child(_art(r))
		v.add_child(holder)
		v.add_child(UI.lbl(U.reward_label(r), 16, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true))
		v.add_child(UI.lbl(_detail(r), 14, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER, true))
		var idx := i
		var hr := _hour
		var b := UI.btn("SOLD" if bought else "      " + U.fmt(it.cost), func(): _buy(idx, hr), "gold")
		if not bought:
			var ic := Icon.make("coin", UI.INK, 20)
			ic.position = Vector2(16, 12)
			ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(ic)
		b.disabled = bought or Game.cur("credits") < int(it.cost)
		v.add_child(b)
		g.add_child(p)
	root.add_child(g)

func _buy(idx: int, hour: int) -> void:
	if hour != U.hour_id():
		Game.say("The Plaza restocked.", UI.GOLD)
		rebuild()
		return
	# Game.plaza_buy(i, hour) also refuses a buy across the hour boundary (owner E's API)
	var got: Array = Game.callv("plaza_buy", [idx, hour]) if _buy_takes_hour() else Game.plaza_buy(idx)
	main.show_rewards("The Plaza", got, rebuild)

func _buy_takes_hour() -> bool:
	for m in Game.get_method_list():
		if m.name == "plaza_buy":
			return m.args.size() >= 2
	return false

func _process(delta: float) -> void:
	_tick += delta
	if _tick < 1.0:
		return
	_tick = 0.0
	if _hour >= 0 and U.hour_id() != _hour:
		rebuild()
	else:
		_update_count()

func _update_count() -> void:
	if is_instance_valid(_count):
		_count.text = "New stock in " + U.dur(3600.0 - fmod(U.now(), 3600.0))

func _category(r: Dictionary) -> String:
	match r.k:
		"gear": return "%s Gear" % U.cap(r.get("r", ""))
		"implant": return "%s Implant" % U.cap(r.get("r", ""))
		"metabolic": return "Metabolic"
		"deeds": return "Deeds"
	return "Supplies"

func _detail(r: Dictionary) -> String:
	if r.k in ["gear", "implant"]:
		var parts: Array = []
		if r.get("slot", "") != "":
			parts.append(U.cap(r.slot))
		if r.get("set", "") != "":
			parts.append(String(r.set) + " set")
		return "  •  ".join(parts) if not parts.is_empty() else "Random slot and set"
	if r.k in ["metabolic", "deeds"]:
		return "%s %s" % [U.cap(r.align), U.cap(r.tier)]
	return ""

func _art(r: Dictionary) -> Control:
	var slot: String = r.get("slot", "")
	if slot != "" and Art.SLOT_BUTTON.has(slot):
		var c := Control.new()
		c.custom_minimum_size = Vector2(56, 68)
		c.add_child(Art.icon(Art.SLOT_BUTTON[slot], Vector2(56, 68)))
		c.add_child(Art.rect(Art.equip_border(r.get("r", "rare")), Vector2.ZERO, 1.0, Vector2(56, 68)))
		return c
	return UI.reward_node(r, 64)
