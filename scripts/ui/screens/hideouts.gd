extends Screen
## Hideouts: hideout list on the left, the boss centre stage with counter tips,
## stage picker, power check, drops and BATTLE on the right.

const BOSS_TPL := {"trolls": "deacon_chainz", "vultures": "cormac", "teratek": "issac_vaun", "vikings": "hammer_of_four",
	"synapse": "mnemosyne", "heist": "warden9", "chopshop": "doc_sawbones", "deeds_paragon": "saint_lumen",
	"deeds_neutral": "broker_grey", "deeds_renegade": "red_mara", "deeds_generic": "archivist"}
const KIND_LABEL := {"gear": "Gear", "implant": "Implants", "credits": "Credits", "mf": "Memory Fragments", "deeds": "Deeds"}

var id := "trolls"
var stage := 1

func build() -> void:
	id = String(params.get("id", "trolls"))
	var info: Dictionary = Content.HIDEOUTS[id]
	var st := Game.hideout_state(id)
	var unlocked_max := mini(20, int(st.max) + 1)
	stage = clampi(int(params.get("stage", unlocked_max)), 1, unlocked_max)
	bg_tint = Color("#4A0F22")
	screen_title = "Hideouts"
	subtitle = ""
	# ---- left rail
	var groups := [{"label": "Gear", "items": []}, {"label": "Resources", "items": []}, {"label": "Deeds", "items": []}]
	for hid in Content.HIDEOUT_ORDER:
		var hi: Dictionary = Content.HIDEOUTS[hid]
		var g := 0 if hi.kind == "gear" else (2 if hi.kind == "deeds" else 1)
		var best := int(Game.hideout_state(hid).max)
		var right := "%d/20" % best
		var rcol := UI.DIM
		if hid == "heist":
			right = "%d plans" % Game.cur("heist")
			rcol = UI.GOLD if Game.cur("heist") > 0 else UI.RED
		groups[g].items.append({"id": hid, "name": String(hi.get("short", hi.name)).replace(" Deeds", ""), "right": right, "right_col": rcol, "col": UI.RED})
	var rl := rail(groups, id, func(hid):
		params.id = hid
		params.erase("stage")
		rebuild(), 262)
	rl.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	rl.offset_left = 20
	rl.offset_right = 282
	rl.offset_top = 10
	rl.offset_bottom = -18
	add_child(rl)
	# ---- centre: boss
	var centre := Control.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.offset_left = 300
	centre.offset_right = -400
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	# the boss in 3D on a turntable (drag to rotate), like the Armoury centrepiece
	var mp := ModelPreview.new()
	mp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mp.offset_top = 200
	mp.offset_bottom = -150
	mp.cam_dist = 4.6
	mp.cam_height = 1.6
	centre.add_child(mp)
	mp.set_models([{"tpl": BOSS_TPL[id], "boss": true}])
	var hv := UI.vb(4)
	hv.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hv.offset_top = 10
	hv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var c1 := UI.cap("Hideout boss  •  " + KIND_LABEL.get(info.kind, ""), Color("#FF8AA0"))
	c1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(c1)
	var bn := UI.disp(info.boss, 36)
	bn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bn.add_theme_color_override("font_shadow_color", Color(UI.RED, 0.5))
	bn.add_theme_constant_override("shadow_outline_size", 14)
	hv.add_child(bn)
	var ds := UI.lbl(info.desc, 15, UI.SOFT, HORIZONTAL_ALIGNMENT_CENTER, true)
	hv.add_child(ds)
	centre.add_child(hv)
	var tv := UI.vb(8)
	tv.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tv.offset_bottom = -20
	tv.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var c2 := UI.cap("Counter with")
	c2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv.add_child(c2)
	var tf := UI.flow(6)
	tf.alignment = FlowContainer.ALIGNMENT_CENTER
	for t in info.tips:
		var chip := UI.lbl(t, 14, UI.TEXT)
		chip.add_theme_stylebox_override("normal", UI._sb(Color(UI.DEEP, 0.92), UI.LINE, 1, 8, 10))
		tf.add_child(chip)
	tv.add_child(tf)
	centre.add_child(tv)
	# keep the boss between the header and the tips however many lines they wrap to
	hv.resized.connect(func(): mp.offset_top = max(200.0, hv.position.y + hv.size.y + 6))
	tv.resized.connect(func(): mp.offset_bottom = min(-150.0, -(20.0 + tv.size.y + 6)))
	# ---- right: stages + battle
	add_child(_panel(st, unlocked_max))

func _panel(st: Dictionary, unlocked_max: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._sb(Color(UI.DEEP, 0.94), UI.LINE, 1, UI.NOTCH, 18))
	p.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	p.offset_left = -380
	p.offset_right = -20
	p.offset_top = 10
	p.offset_bottom = -18
	var outer := UI.vb(12)
	p.add_child(outer)
	var v := UI.vb(10)
	var sc := UI.scroll(v)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sc)
	v.add_child(UI.cap("Select stage"))
	var page := int(params.get("page", (stage - 1) / 10))
	var g := UI.grid(5, 6)
	for s in range(page * 10 + 1, page * 10 + 11):
		var on := s == stage
		var wins := int(st.wins.get(str(s), 0))
		var b := UI.btn(str(s), func():
			params.stage = s
			rebuild(), "normal", 0, 15)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 48
		b.add_theme_stylebox_override("normal", UI._sb(UI.RED if on else Color(1, 1, 1, 0.06), Color(0, 0, 0, 0), 0, 8, 4))
		b.add_theme_color_override("font_color", UI.BG if on else (UI.CYAN if wins > 0 else UI.SOFT))
		b.disabled = s > unlocked_max
		g.add_child(b)
	v.add_child(g)
	var pg := UI.hb()
	var pb := UI.btn("‹ 1-10", func():
		params.page = 0
		rebuild(), "ghost", 0, 12)
	pb.disabled = page == 0
	pg.add_child(pb)
	pg.add_child(UI.spacer())
	var nb := UI.btn("11-20 ›", func():
		params.page = 1
		rebuild(), "ghost", 0, 12)
	nb.disabled = page == 1
	pg.add_child(nb)
	v.add_child(pg)
	var enc := Content.build_hideout(id, stage)
	var mine := Game.team_power(Game.S.squads.last)
	var theirs := Content.enc_power(enc)
	var ratio: float = float(mine) / max(1.0, float(theirs))
	var sh := UI.hb()
	sh.add_child(UI.disp("Stage %d" % stage, 22))
	var rec := UI.lbl("Recommended " + U.fmt(theirs), 14, UI.GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	rec.clip_text = true
	rec.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UI.expand(rec)
	sh.add_child(rec)
	v.add_child(sh)
	var split := UI.hb(0)
	for part in [[UI.CYAN, mine], [UI.RED, theirs]]:
		var r := ColorRect.new()
		r.color = part[0]
		r.custom_minimum_size.y = 8
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.size_flags_stretch_ratio = max(0.05, float(part[1]))
		split.add_child(r)
	v.add_child(split)
	var vr := UI.hb()
	vr.add_child(UI.lbl("You " + U.fmt(mine), 14, UI.CYAN))
	vr.add_child(UI.spacer())
	var verdict: Array = ["Favoured", UI.GREEN] if ratio > 1.15 else (["Fair fight", UI.GOLD] if ratio > 0.9 else (["Hard", Color("#FF8A3A")] if ratio > 0.7 else ["Deadly", UI.RED]))
	vr.add_child(UI.lbl(verdict[0], 14, verdict[1]))
	v.add_child(vr)
	v.add_child(UI.cap("Drops"))
	v.add_child(_drop_tiles())
	for line in _reward_lines():
		v.add_child(UI.lbl(line, 13, UI.SOFT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var foot := UI.hb(10)
	foot.add_child(UI.btn("INTEL", func(): _intel(enc), "primary", 96, 14))
	var cost_n := 0
	var cost_icon := "bolt"
	for k in enc.cost:
		cost_n = int(enc.cost[k])
		cost_icon = "bolt" if k == "energy" else "ticket"
	var go := UI.cta("BATTLE", func(): main.start_encounter(Content.build_hideout(id, stage)), str(cost_n), cost_icon)
	go.disabled = Game.can_pay(enc.cost) != ""
	if go.disabled:
		go.tooltip_text = Game.can_pay(enc.cost)
	UI.expand(go)
	foot.add_child(go)
	outer.add_child(foot)
	return p

func _intel(enc: Dictionary) -> void:
	var v := UI.vb(10)
	var seen := {}
	for u in enc.waves[1]:
		if seen.has(u.tpl):
			continue
		seen[u.tpl] = true
		var t: Dictionary = Warlords.get_t(u.tpl)
		var uh := UI.hb(10)
		var pr := UI.portrait(u.tpl, 56)
		pr.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		uh.add_child(pr)
		var uv := UI.vb(2)
		UI.expand(uv)
		uv.add_child(UI.disp(t.name + ("  •  boss" if u.boss else ""), 16, UI.RED if u.boss else UI.TEXT))
		for a in t.abilities:
			uv.add_child(UI.lbl("%s: %s" % [a.name, a.desc], 14, UI.SOFT, HORIZONTAL_ALIGNMENT_LEFT, true))
		if u.boss and Content.BRING_IT_ON_TEXT.has(id):
			uv.add_child(UI.lbl(Content.BRING_IT_ON_TEXT[id], 14, UI.SOFT, HORIZONTAL_ALIGNMENT_LEFT, true))
		uh.add_child(uv)
		v.add_child(uh)
	main.modal("Boss intel", v, true)

func _pct_text(d: Dictionary, prefix := "") -> String:
	var parts: Array = []
	var total := 0.0
	for k in d:
		total += float(d[k])
	for k in d:
		if float(d[k]) > 0:
			parts.append("%s%s %d%%" % [prefix, U.cap(str(k)), int(round(float(d[k]) / total * 100.0))])
	return ", ".join(parts)

## Drop tiles like the design canvas: item art with a rank / tier badge and the odds underneath.
func _drop_tiles() -> HFlowContainer:
	var f := UI.flow(6)
	var kind: String = Content.HIDEOUTS[id].kind
	match kind:
		"gear", "implant":
			var row: Dictionary = (Data.GDD.chopshop if kind == "implant" else Data.GDD.hideoutGear)[stage - 1]
			var top := "rare"   # tile border shows the best rarity on offer
			for r in row.rar:
				if float(row.rar[r]) > 0:
					top = r
			var total := 0.0
			for k in row.ranks:
				total += float(row.ranks[k])
			for k in row.ranks:
				if float(row.ranks[k]) > 0:
					f.add_child(_tile(UI.reward_node({"k": kind, "r": top}, 48), "R" + str(k), "%d%%" % int(round(float(row.ranks[k]) / total * 100.0))))
			f.add_child(_tile(UI.reward_node({"k": "credits"}, 48), "", U.fmt(row.credits)))
		"mf":
			for r in Data.GDD.synapse[stage - 1].rows:
				var tier := int(String(r[0]).split(" ")[1])
				f.add_child(_tile(UI.reward_node({"k": "mf", "tier": tier}, 48), "T%d" % tier, _range_text(String(r[1]))))
		"credits":
			for r in Data.GDD.heist[stage - 1].rows:
				var list := U.parse_rewards(String(r[0]))
				if list.is_empty():
					continue
				var rw: Dictionary = list[0]
				var amount := U.fmt(rw.n) if rw.k == "credits" else ("%dx" % int(rw.get("n", 1)))
				f.add_child(_tile(UI.reward_node(rw, 48), amount, "%s%%" % str(r[1])))
		"deeds":
			var align: String = Content.HIDEOUTS[id].align
			for r in Data.GDD.deeds[stage - 1].rows:
				var text := String(r[0])
				if text.begins_with("N/A") or float(String(r[1]).replace("%", "")) <= 0.0:
					continue
				var parts := text.split(" ")
				if parts[parts.size() - 1] in ["Minor", "Major", "Grand"]:
					f.add_child(_tile(UI.reward_node({"k": "deeds", "align": align, "tier": parts[parts.size() - 1].to_lower()}, 48), parts[0], String(r[1])))
				else:
					var list := U.parse_rewards(text)
					if not list.is_empty():
						var rw: Dictionary = list[0]
						f.add_child(_tile(UI.reward_node(rw, 48), U.fmt(rw.n) if rw.k == "credits" else "1x", String(r[1])))
	return f

func _tile(art: Control, badge: String, caption: String) -> Control:
	var box := UI.vb(2)
	var holder := Panel.new()
	holder.custom_minimum_size = Vector2(60, 64)
	holder.add_theme_stylebox_override("panel", UI._sb(Color(1, 1, 1, 0.06), UI.LINE, 1, 8, 0))
	art.position = (Vector2(60, 64) - art.custom_minimum_size) / 2.0 + Vector2(0, 6)
	holder.add_child(art)
	if badge != "":
		var bl := UI.lbl(badge, 12, Color.WHITE)
		bl.position = Vector2(6, 1)
		holder.add_child(bl)
	box.add_child(holder)
	box.add_child(UI.lbl(caption, 12, UI.GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	return box

## "08-28" -> "8-28"
func _range_text(s: String) -> String:
	if s.contains("-"):
		var p := s.split("-")
		return "%d-%d" % [int(p[0]), int(p[1])]
	return str(int(s))

func _reward_lines() -> Array:
	var kind: String = Content.HIDEOUTS[id].kind
	var out: Array = []
	match kind:
		"gear", "implant":
			var row: Dictionary = (Data.GDD.chopshop if kind == "implant" else Data.GDD.hideoutGear)[stage - 1]
			out.append("1x random %s  •  Rarity: %s" % ["Implant" if kind == "implant" else "Equipment", _pct_text(row.rar)])
			if kind == "gear":
				out.append("Sets: " + ", ".join(Data.HIDEOUT_SETS[id]))
			else:
				out.append("Slot: " + _pct_text(row.slots))
		"mf":
			out.append("Memory Fragments by tier, rolled each win")
		"credits":
			out.append("One payout per win")
		"deeds":
			out.append("One of Minor / Major / Grand %s Deeds per win" % U.cap(Content.HIDEOUTS[id].align))
	out.append("Warlord XP: %s (shared)" % U.fmt(3000 + 1500 * stage))
	return out
