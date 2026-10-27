extends Node
## Lists every warlord the campaign treats as a team healer (den boss HP multiplier 1.0).
func _ready() -> void:
	var out: Array = []
	for id in Warlords.RECRUITABLE:
		if Content._heals_team(Warlords.get_t(id)):
			out.append(id)
	print("TEAM HEALERS ", out, "  issac mult ", Content.campaign_boss_mult("issac_vaun"), "  raiden mult ", Content.campaign_boss_mult("raiden_x"))
	get_tree().quit()
