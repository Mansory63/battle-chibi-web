extends SceneTree
const MODELS := ["tree", "tree-high", "rocks-low", "stones", "plant"]
func _initialize() -> void:
	for name in MODELS:
		var inst = load("res://assets/kenney_mini/%s.glb" % name).instantiate()
		var vp := SubViewport.new()
		vp.size = Vector2i(256, 256)
		vp.transparent_bg = true
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.disable_3d = false
		root.add_child(vp)
		var holder := Node3D.new()
		vp.add_child(holder)
		holder.add_child(inst)
		var aabb := _aabb(inst)
		var c := aabb.get_center()
		var sz := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		inst.position = -c
		inst.position.y += aabb.size.y * 0.5 - aabb.position.y * 0 - 0.0
		var cam := Camera3D.new()
		vp.add_child(cam)
		cam.position = Vector3(0, sz * 0.5, sz * 1.6)
		cam.look_at(Vector3(0, sz * 0.5, 0), Vector3.UP)
		cam.current = true
		var sun := DirectionalLight3D.new()
		sun.rotation = Vector3(-0.9, 0.6, 0)
		vp.add_child(sun)
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_CLEAR_COLOR
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color(0.8, 0.8, 0.8)
		vp.add_child(env)
		for i in 4:
			await process_frame
		var img := vp.get_texture().get_image()
		img.save_png("/home/claude/scratch/shots/kenney/%s.png" % name)
		print("RENDERED ", name, " size=", sz)
		vp.queue_free()
		await process_frame
	quit(0)
func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for mi in _meshes(n):
		var a: AABB = mi.get_aabb()
		a = mi.global_transform * a if mi.is_inside_tree() else a
		if first:
			out = a
			first = false
		else:
			out = out.merge(a)
	return out
func _meshes(n: Node) -> Array:
	var arr: Array = []
	if n is MeshInstance3D:
		arr.append(n)
	for c in n.get_children():
		arr.append_array(_meshes(c))
	return arr
