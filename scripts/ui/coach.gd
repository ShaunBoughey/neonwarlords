class_name Coach
extends Control
## First-session guide (FTUE): dims the screen around the next thing to tap, shows a hint bubble
## and advances when that control is pressed. Steps with "go" show a button that navigates.
## Progress lives in Game.S.ftue; Game.S.tutorial_done ends it. Never blocks input outside the bubble.

const STEPS := [
	{"screen": "city", "target": "battle", "text": "Your gang needs a win. Tap BATTLE to pick a fight."},
	{"screen": "fight", "target": "campaign", "text": "The Campaign is the story of the city. Start here."},
	{"screen": "campaign", "target": "stage_battle", "text": "Stage 1-1. The panel shows the enemies, drops and chevron goals. Tap BATTLE."},
	{"screen": "squad", "target": "start", "text": "Your four strongest Warlords are already picked. The first is your Leader. START the fight."},
	{"screen": "battle", "target": "enemy", "text": "Your turn. The first skill is selected - tap an enemy to attack. Turn meters fill by Speed."},
	{"screen": "battle", "target": "", "when": "finished", "go": "armory", "go_text": "GEAR UP", "text": "Victory! Gear is what makes Warlords strong. Let's equip yours."},
	{"screen": "armory", "target": "warlord_card", "text": "Tap a Warlord to open the Armoury."},
	{"screen": "warlord", "target": "auto_equip", "text": "AUTO EQUIP puts on the best gear you own. Watch the stats go up."},
	{"screen": "warlord", "target": "", "go": "recruit", "go_text": "TO THE PAWN SHOP", "text": "You also have contract cases waiting. The Fence will open them for you."},
	{"screen": "recruit", "target": "open1", "text": "Pick a case on the left, then OPEN it to recruit a Warlord."},
	{"screen": "recruit", "target": "", "go": "missions", "go_text": "MISSIONS", "text": "Missions pay out every day. Let's claim one."},
	{"screen": "missions", "target": "claim", "optional": true, "text": "Claim finished jobs for rewards and Player XP."},
	{"screen": "", "target": "", "go": "city", "go_text": "LET'S GO", "text": "You're ready. New districts open as your Player Level rises - Hideouts, Syndicate Wars, the Pit and Gangs."},
]

var main
var _rect := Rect2()
var _show := false
var _bubble: PanelContainer
var _text: Label
var _go: Button
var _hooked := {}
var _acc := 0.0
var _pulse := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override("panel", UI._sb(Color(UI.DEEP, 0.97), UI.GOLD, 2, UI.NOTCH, 16))
	_bubble.custom_minimum_size.x = 340
	_bubble.mouse_filter = Control.MOUSE_FILTER_STOP
	var v := UI.vb(10)
	v.add_child(UI.cap("Guide", UI.GOLD))
	_text = UI.lbl("", 16, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
	_text.custom_minimum_size.x = 300
	v.add_child(_text)
	var h := UI.hb(8)
	var skip := UI.btn("SKIP GUIDE", func(): finish(), "ghost", 0, 12)
	skip.custom_minimum_size.y = 44
	h.add_child(skip)
	h.add_child(UI.spacer())
	_go = UI.btn("GO", func(): _do_go(), "gold", 120, 14)
	_go.custom_minimum_size.y = 44
	h.add_child(_go)
	v.add_child(h)
	_bubble.add_child(v)
	add_child(_bubble)
	_bubble.visible = false

func active() -> bool:
	return not Game.S.is_empty() and not Game.S.get("tutorial_done", true)

func step() -> int:
	return int(Game.S.get("ftue", 0))

func finish() -> void:
	Game.S.tutorial_done = true
	Game.mark()
	_show = false
	_bubble.visible = false
	queue_redraw()

func advance() -> void:
	Game.S.ftue = step() + 1
	Game.mark()
	_hooked.clear()
	if step() >= STEPS.size():
		finish()

func _do_go() -> void:
	var s: Dictionary = STEPS[step()]
	var dest: String = s.get("go", "")
	advance()
	if dest == "city":
		main.home()
	elif dest != "":
		main.stack.clear()
		main.stack.append(["city", {}])
		main.replace(dest)

func _process(delta: float) -> void:
	_pulse += delta
	_acc += delta
	if _acc < 0.1:
		if _show:
			queue_redraw()
		return
	_acc = 0.0
	_update()

func _find(n: Node, id: String) -> Control:
	if n is Control and n.has_meta("coach") and n.get_meta("coach") == id and n.is_visible_in_tree():
		return n
	for c in n.get_children():
		var f := _find(c, id)
		if f:
			return f
	return null

func _update() -> void:
	_show = false
	if not active() or main == null or main.current == null or main.overlay.get_child_count() > 0:
		_bubble.visible = false
		queue_redraw()
		return
	if step() >= STEPS.size():
		finish()
		return
	var s: Dictionary = STEPS[step()]
	var scr: String = main._cur_name
	if s.screen != "" and s.screen != scr:
		_bubble.visible = false
		queue_redraw()
		return
	if s.get("when", "") == "finished" and not main.current.get("finished"):
		_bubble.visible = false
		queue_redraw()
		return
	var target: Control = null
	if s.target != "":
		if main.current.has_method("coach_node"):
			target = main.current.coach_node(s.target)
		if target == null:
			target = _find(main.current, s.target)
		if target == null:
			if s.get("optional", false):
				advance()
			_bubble.visible = false
			queue_redraw()
			return
		var key := target.get_instance_id()
		if not _hooked.has(key) and target is BaseButton:
			_hooked[key] = true
			target.pressed.connect(func(): if active() and STEPS[step()].target == s.target: advance(), CONNECT_ONE_SHOT)
		_rect = target.get_global_rect().grow(6)
	else:
		_rect = Rect2()
	_show = true
	_text.text = s.text
	_go.visible = s.get("go", "") != ""
	_go.text = s.get("go_text", "GO")
	_bubble.visible = true
	_bubble.reset_size()
	_place_bubble()
	queue_redraw()

func _place_bubble() -> void:
	var vs := get_viewport_rect().size
	var bs := _bubble.size
	var p: Vector2 = (vs - bs) / 2.0
	if _rect.size != Vector2.ZERO:
		var cx := _rect.position.x + _rect.size.x / 2.0 - bs.x / 2.0
		var cy := _rect.position.y + _rect.size.y / 2.0 - bs.y / 2.0
		var cands := [Vector2(cx, _rect.position.y - bs.y - 18), Vector2(cx, _rect.end.y + 18),
			Vector2(_rect.end.x + 18, cy), Vector2(_rect.position.x - bs.x - 18, cy)]
		p = cands[0]
		for c in cands:
			var q := Vector2(clampf(c.x, 12, vs.x - bs.x - 12), clampf(c.y, 12, vs.y - bs.y - 12))
			if not Rect2(q, bs).intersects(_rect.grow(4)):
				p = q
				break
	p.x = clampf(p.x, 12, vs.x - bs.x - 12)
	p.y = clampf(p.y, 12, vs.y - bs.y - 12)
	_bubble.position = p

func _draw() -> void:
	if not _show:
		return
	var vs := get_viewport_rect().size
	var dim := Color(0.01, 0.02, 0.05, 0.62)
	if _rect.size == Vector2.ZERO:
		draw_rect(Rect2(Vector2.ZERO, vs), dim)
		return
	var r := _rect
	draw_rect(Rect2(0, 0, vs.x, r.position.y), dim)
	draw_rect(Rect2(0, r.end.y, vs.x, vs.y - r.end.y), dim)
	draw_rect(Rect2(0, r.position.y, r.position.x, r.size.y), dim)
	draw_rect(Rect2(r.end.x, r.position.y, vs.x - r.end.x, r.size.y), dim)
	var a := 0.6 + 0.4 * sin(_pulse * 5.0)
	draw_rect(r, Color(UI.GOLD, a), false, 3.0)
	draw_rect(r.grow(6 + 3 * sin(_pulse * 5.0)), Color(UI.GOLD, 0.25 * a), false, 2.0)
