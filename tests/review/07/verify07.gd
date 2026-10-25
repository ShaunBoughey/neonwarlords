extends Node
func _ready() -> void:
	Game.reset_save()
	Game.new_game("V07")
	for hid in ["trolls", "vultures", "teratek", "vikings"]:
		var enc := Content.build_hideout(hid, 5)
		print(hid, " boss immune=", enc.waves[1][0].immune, " wave2=", enc.waves[1].size())
	var none := 0; var multi := 0; var credits := 0
	for i in 2000:
		var r := Content.hideout_rewards({"mode": "hideout", "id": "deeds_paragon", "stage": 4}, true)
		var tiers := 0
		for it in r.items:
			if String(it.label).contains("Deeds"): tiers += 1
			if String(it.label).contains("Credits"): credits += 1
		if tiers == 0: none += 1
		if tiers > 1: multi += 1
	print("deeds s4 2000 wins: no-deeds=%d multi=%d credits=%d" % [none, multi, credits])
	for st in [1, 2, 3]:
		print("bastion st%d top tier: %s" % [st, Content.bastion_rewards(st, 999999).map(func(r): return U.reward_label(r))])
	print("bastion turns ", Content.BASTION_TURNS, " title ", Content.build_bastion(1).title, " adds ", Content.build_bastion(1).waves[0].map(func(u): return u.tpl))
	print("campaign title ", Content.build_campaign(0, 0, 0).title, " boss escorts ", Content.build_campaign(0, 2, 6).waves[0].map(func(u): return u.tpl))
	get_tree().quit()
