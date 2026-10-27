extends Node
## Fix C: share of Hacking-checked enemy debuff attempts that land on the player squad (after chance + immunity).
var fw_squad := false

func _squad(rank: int, rar: String, glv: int) -> Array:
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	var uids: Array = []
	for id in tpls:
		var w := Game.add_warlord(id, true)
		w.rank = rank; w.level = Data.max_level(rank); w.rep = mini(rank, 6)
		for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
			var it := Game.make_equipment(slot, rank, rar, "Firewall" if fw_squad and slot in Data.GEAR_SLOTS else "")
			if fw_squad and slot in ["chest", "skeleton"]: it.pri.stat = "fw"
			it.level = glv
			Game.S.equip.append(it); Game.equip_on(w, it)
		uids.append(w.uid)
	return uids

func _run(label: String, g: Array, mk: Callable, n: int) -> void:
	var land := 0; var resist := 0; var wins := 0
	var fws: Array = []; var hk := 0
	var uids: Array = []
	for i in n:
		if i % 2 == 0: uids = _squad(g[0], g[1], g[2])   # fresh gear roll every 2 fights
		var enc: Dictionary = mk.call()
		var b := Battle.new()
		var waves: Array = []
		for wv in enc.waves: waves.append(wv.map(func(u): return u.duplicate(true)))
		b.setup(Content.player_units(uids), waves, {})
		if i == 0:
			hk = int(enc.waves[-1][0].base.hack)
		fws.append_array(b.side_units(0).map(func(u): return int(u.base.fw)))
		b.simulate()
		wins += 1 if b.result == "win" else 0
		for e in b.events:
			var u = b.unit(e.get("u", -1)) if e.has("u") else null
			if u == null or u.side != 0: continue
			if e.get("e") == "debuff" and not Data.DEBUFFS.get(e.id, {}).get("noCheck", false): land += 1
			elif e.get("e") == "resist": resist += 1
	var tot := maxi(1, land + resist)
	print("%s%s win %d/%d bossHack=%d playerFw p50=%d landed %d / %d = %d%%" % ["FW-SQUAD " if fw_squad else "", label, wins, n, hk, _med(fws), land, land + resist, roundi(100.0 * land / tot)])

func _med(a: Array) -> int:
	a.sort()
	return a[a.size() / 2] if not a.is_empty() else 0

func _ready() -> void:
	await get_tree().process_frame
	for pass_fw in [false, true]:
		fw_squad = pass_fw
		Game.reset_save()
		Game.new_game("FixC")
		for band in [[1, [2, "uncommon", 4]], [10, [5, "epic", 12]], [20, [6, "legendary", 16]]]:
			var g: Array = band[1]
			for hid in ["trolls", "vultures", "vikings"]:
				var st: int = band[0]
				_run("hideout %s s%d (R%d %s +%d)" % [hid, st, g[0], g[1], g[2]], g, func(): return Content.build_hideout(hid, st), 6)
		if not pass_fw:
			for c in [[0, 4, [4, "rare", 8]], [1, 4, [5, "epic", 12]], [2, 9, [6, "legendary", 16]]]:
				var g2: Array = c[2]
				_run("campaign d%d den%d boss (R%d %s +%d)" % [c[0], c[1] + 1, g2[0], g2[1], g2[2]], g2, func(): return Content.build_campaign(c[0], c[1], 6), 6)
	print("SIM DONE")
	get_tree().quit()
