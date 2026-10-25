extends Screen
## Inbox (mail with attached rewards) and Friends.

func build() -> void:
	var tab: String = params.get("tab", "Inbox")
	var h := header("INBOX / FRIENDS")
	h.add_child(tabs(["Inbox", "Friends"], tab, func(n):
		params.tab = n
		rebuild()))
	if tab == "Inbox":
		_inbox()
	else:
		_friends()

func _inbox() -> void:
	var bar := UI.hb()
	bar.add_child(UI.lbl("%d %s, %d unclaimed" % [Game.S.inbox.size(), "message" if Game.S.inbox.size() == 1 else "messages", Game.unclaimed_mail()], 14, UI.DIM))
	bar.add_child(UI.spacer())
	bar.add_child(UI.btn("Claim All", func():
		var got: Array = []
		for m in Game.S.inbox:
			got.append_array(Game.claim_mail(m))
		main.show_rewards("Mail Rewards", got, rebuild), "gold"))
	root.add_child(bar)
	var list := UI.vb(6)
	for m in Game.S.inbox:
		var mail: Dictionary = m
		var p := UI.panel(UI.YELLOW.darkened(0.4) if not m.claimed else Color(0, 0, 0, 0))
		var hh := UI.hb(10)
		p.add_child(hh)
		var v := UI.vb(2)
		UI.expand(v)
		v.add_child(UI.lbl(m.title, 16, UI.TEXT if not m.claimed else UI.DIM))
		v.add_child(UI.lbl(m.body, 13, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
		if not m.rewards.is_empty():
			v.add_child(UI.reward_chips(m.rewards))
		hh.add_child(v)
		hh.add_child(UI.lbl(Time.get_datetime_string_from_unix_time(int(m.t)).replace("T", " ").substr(0, 16), 11, UI.DIM))
		if not m.claimed:
			hh.add_child(UI.btn("Claim", func(): main.show_rewards(mail.title, Game.claim_mail(mail), rebuild), "gold"))
		list.add_child(p)
	root.add_child(UI.scroll(list))

func _friends() -> void:
	root.add_child(UI.lbl("Friends can be challenged once online play is connected. Here are your gang mates for now.", 13, UI.DIM))
	var g := UI.grid(3, 10)
	for m in Game.S.gang.members:
		var p := UI.panel()
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var h := UI.hb(8)
		p.add_child(h)
		h.add_child(Icon.make("users", UI.CYAN, 28))
		var v := UI.vb(0)
		v.add_child(UI.lbl(m.name, 15))
		v.add_child(UI.lbl("Power %s • %s" % [U.fmt(m.power), Game.S.gang.name], 12, UI.DIM))
		h.add_child(v)
		g.add_child(p)
	root.add_child(UI.scroll(g))
