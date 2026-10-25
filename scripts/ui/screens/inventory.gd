extends Screen
## Equipment, implants and neons inventory with bulk sell.

func build() -> void:
	var tab: String = params.get("tab", "Gear")
	var slot: String = params.get("slot", "all")
	screen_title = "Inventory"
	var gear_n: int = Game.S.equip.filter(func(e): return e.kind != "implant").size()
	var imp_n: int = Game.S.equip.filter(func(e): return e.kind == "implant").size()
	var cats := [{"id": "Gear", "name": "Gear", "right": str(gear_n)}, {"id": "Implants", "name": "Implants", "right": str(imp_n)},
		{"id": "Neons", "name": "Neons", "right": str(Game.S.neons.size())}, {"id": "Items", "name": "Items", "right": ""}]
	var rl := rail([{"label": "", "items": cats}], tab, func(id):
		params.tab = id
		params.slot = "all"
		rebuild(), 220)
	rl.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	rl.offset_left = 20
	rl.offset_right = 240
	rl.offset_top = 10
	rl.offset_bottom = -16
	add_child(rl)
	root.offset_left = 260
	match tab:
		"Gear", "Implants": _equip(tab == "Implants", slot)
		"Neons": _neons()
		"Items": _items()

func _equip(implants: bool, slot: String) -> void:
	var slots: Array = Data.IMPLANT_SLOTS if implants else Data.GEAR_SLOTS
	# slot tabs get the full row so all 7 stay reachable; the count and bulk sell sit underneath
	root.add_child(tabs(["all"] + slots, slot, func(n):
		params.slot = n
		rebuild()))
	var items: Array = Game.S.equip.filter(func(e): return (e.kind == "implant") == implants and (slot == "all" or e.slot == slot))
	items.sort_custom(func(a, b): return a.rank * 1000 + Data.rarity_idx(a.rarity) * 100 + a.level > b.rank * 1000 + Data.rarity_idx(b.rarity) * 100 + b.level)
	var f := UI.hb(6)
	f.add_child(UI.lbl("%d items" % items.size(), 14, UI.DIM))
	f.add_child(UI.spacer())
	f.add_child(UI.btn("Sell unequipped Common/Uncommon", func(): _bulk_sell(implants), "danger"))
	root.add_child(f)
	var g := UI.flow(8)
	for it in items:
		var item: Dictionary = it
		g.add_child(UI.item_card(item, func(): ItemView.open(main, item, rebuild)))
	root.add_child(UI.scroll(g))

func _bulk_sell(implants: bool) -> void:
	var targets: Array = Game.S.equip.filter(func(e): return (e.kind == "implant") == implants and e.owner == "" and not e.locked and e.rarity in ["common", "uncommon"])
	if targets.is_empty():
		err("Nothing to sell")
		return
	var total := 0
	for e in targets:
		total += Game.equip_sell_value(e)
	main.confirm("Sell %d items for %s Credits?" % [targets.size(), U.fmt(total)], func():
		for e in targets:
			Game.sell_equipment(e)
		rebuild())

func _neons() -> void:
	root.add_child(UI.lbl("Neons attach to equipment of the same or higher rank and boost a matching substat (Armoury > Upgrade > Graft). Spare neons sell for Credits.", 13, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	var groups := {}
	for n in Game.S.neons:
		var key := "%d|%s" % [n.rank, n.stat]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(n)
	var keys: Array = groups.keys()
	keys.sort()
	keys.reverse()
	var g := UI.flow(8)
	for k in keys:
		var list: Array = groups[k]
		var n0: Dictionary = list[0]
		var p := UI.panel(UI.MAGENTA.darkened(0.3))
		var h := UI.hb(6)
		h.add_child(Art.icon(Art.neon_small(n0.stat), Vector2(32, 32)))
		var v := UI.vb(0)
		v.add_child(UI.lbl("R%d %s x%d" % [n0.rank, Data.STATS[n0.stat].name, list.size()], 14))
		v.add_child(UI.lbl("+%s to a %s substat" % [str(Data.SUBSTAT[n0.stat][n0.rank]), Data.STATS[n0.stat].short], 12, UI.DIM))
		h.add_child(v)
		h.add_child(UI.btn("Sell (%s)" % U.fmt(Game.neon_sell_value(n0)), func():
			Game.sell_neon(n0)
			rebuild(), "ghost", 0, 12))
		p.add_child(h)
		g.add_child(p)
	if keys.is_empty():
		g.add_child(UI.lbl("No Neons yet - win Syndicate Wars stages.", 14, UI.DIM))
	root.add_child(UI.scroll(g))

func _items() -> void:
	var it: Dictionary = Game.S.items
	var g := UI.grid(2, 20)
	var add := func(name: String, val: String):
		g.add_child(UI.lbl(name, 14, UI.DIM))
		g.add_child(UI.lbl(val, 14))
	for r in ["uncommon", "rare", "epic", "legendary"]:
		add.call(U.cap(r) + " Contracts / scrap", "%d   (%d/10 scrap)" % [int(it.contract[r]), int(it.scrap[r])])
	for r in ["uncommon", "rare", "epic", "legendary"]:
		add.call(U.cap(r) + " Stimms", str(int(it.stimm[r])))
	for lv in range(1, 6):
		add.call("Mk %d Firmware (rank-up chip)" % lv, str(int(it.firmware[str(lv)])))
	for tier in [1, 2, 3]:
		add.call("Tier %d Memory Fragments" % tier, str(int(it.mf[str(tier)])))
	for al in ["paragon", "neutral", "renegade", "generic"]:
		var d: Dictionary = it.deeds[al]
		add.call(U.cap(al) + " Deeds (minor/major/grand)", "%d / %d / %d" % [int(d.minor), int(d.major), int(d.grand)])
	for al in ["paragon", "neutral", "renegade", "generic"]:
		var m: Dictionary = it.metabolic[al]
		add.call(U.cap(al) + " Metabolics", "%d / %d / %d" % [int(m.minor), int(m.major), int(m.grand)])
	add.call("Energy Batteries", str(int(it.battery)))
	add.call("XP Boosts (100% / 10%)", "%d / %d" % [int(it.xpBoost), int(it.xpBoostMinor)])
	add.call("Heist Plans / Bounty Tokens", "%d / %d" % [Game.cur("heist"), Game.cur("bounty")])
	add.call("Brawl / Royal Invites", "%d / %d" % [Game.cur("brawl"), Game.cur("royal")])
	add.call("Raid Boss Tickets", str(Game.cur("raidTicket")))
	var row := UI.hb(16)
	row.add_child(g)
	var caches := UI.vb(6)
	caches.add_child(UI.lbl("Pit Caches", 16, UI.CYAN))
	for c in it.cache:
		var n := int(it.cache[c])
		var cname: String = c
		var b := UI.btn("Open %s (%d)" % [c, n], func(): main.show_rewards(cname, Game.open_cache(cname), rebuild), "gold")
		b.disabled = n <= 0
		caches.add_child(b)
	row.add_child(caches)
	root.add_child(UI.scroll(row))
