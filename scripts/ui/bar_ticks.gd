class_name BarTicks
extends Control
## Segment ticks drawn over a ProgressBar for a HUD-gauge look.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var step := 10.0 if size.x < 220 else 14.0
	var x := step
	while x < size.x:
		draw_line(Vector2(x, 1), Vector2(x - 2, size.y - 1), Color(0, 0, 0, 0.45), 2.0)
		x += step
