extends SceneTree
func _initialize() -> void:
	var inst = load("res://assets/3d/quat/Superhero_Male_FullBody.gltf").instantiate()
	var holder := Node3D.new()
	root.add_child(holder)
	holder.add_child(inst)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.2, 0.25, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.8, 0.8)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.8, 0.5, 0)
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.1, 4.0)
	root.add_child(cam)
	cam.look_at(Vector3(0, 0.95, 0), Vector3.UP)
	cam.current = true
	for i in 10:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/quat_male.png")
	print("SKEL ", inst.find_child("Skeleton3D", true, false) != null, " AP ", inst.find_child("AnimationPlayer", true, false) != null)
	quit(0)
