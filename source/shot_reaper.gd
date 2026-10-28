extends SceneTree
func _initialize() -> void:
	var u = load("res://units3d.gd").new()
	var r: Node3D = u._build_reaper()
	root.add_child(r)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.25, 0.4, 0.2)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.5, 0)
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.position = Vector3(0.6, 1.4, 3.2)
	root.add_child(cam)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	cam.current = true
	for i in 5:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/reaper.png")
	quit(0)
