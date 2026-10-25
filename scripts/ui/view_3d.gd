class_name View3D
extends Control
## Hosts a 3D SubViewport (assign `vp` and add it as a child) and draws it at real screen pixels.
## SubViewportContainer.stretch sizes the viewport in canvas units (1280x720 even on a 4K window), so
## the 3D came out low-res and upscaled. Here vp.size = size x the final on-screen scale (window
## stretch x parent scales such as the Armoury canvas), re-checked every frame. Mobile caps the scale.

const MOBILE_MAX_SCALE := 1.25

var vp: SubViewport

## Screen pixels per canvas unit for this control, capped on mobile for fill-rate.
func render_scale() -> float:
	var s: float = get_viewport().get_final_transform().get_scale().x * get_global_transform_with_canvas().get_scale().x
	return min(s, MOBILE_MAX_SCALE) if OS.has_feature("mobile") else s

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			set_process(true)
		NOTIFICATION_PROCESS:
			if vp != null and is_visible_in_tree():
				var want := Vector2i((size * render_scale()).round()).max(Vector2i.ONE)
				if vp.size != want:
					vp.size = want
					queue_redraw()
		NOTIFICATION_RESIZED:
			queue_redraw()
		NOTIFICATION_DRAW:
			if vp != null:
				draw_texture_rect(vp.get_texture(), Rect2(Vector2.ZERO, size), false)
