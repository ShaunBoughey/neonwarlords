extends Node
func _ready() -> void:
	for f in ["armour", "firepower", "modder", "hacker"]:
		var sc: PackedScene = load("res://assets/models/warlord_%s.glb" % f)
		var n := sc.instantiate()
		var ap: AnimationPlayer = n.find_child("AnimationPlayer", true, false)
		var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
		var mi: MeshInstance3D = n.find_child("*", true, false) as MeshInstance3D
		var meshes := n.find_children("*", "MeshInstance3D", true, false)
		var mats := []
		for m in meshes:
			for i in m.mesh.get_surface_count():
				mats.append(m.mesh.surface_get_material(i).resource_name)
		print(f, " anims=", ap.get_animation_list() if ap else "none", " bones=", sk.get_bone_count() if sk else 0, " mats=", mats)
		for a in ap.get_animation_list():
			print("   ", a, " len=", ap.get_animation(a).length)
		n.free()
	get_tree().quit()
