extends SceneTree
func _initialize() -> void:
	var base = load("res://assets/3d/quat/Superhero_Male_FullBody.gltf").instantiate()
	var ual = load("res://assets/anim/UAL1_Standard.glb").instantiate()
	var uap: AnimationPlayer = ual.find_child("AnimationPlayer", true, false)
	print("UAL AP ", uap != null, " list ", uap.get_animation_list().slice(0,6))
	root.add_child(base)
	var ap := AnimationPlayer.new()
	base.add_child(ap)
	ap.root_node = NodePath("..")
	var lib := AnimationLibrary.new()
	for n in ["Walk", "Idle"]:
		lib.add_animation(n, uap.get_animation(n))
	ap.add_animation_library("", lib)
	ap.play("Walk")
	print("CHECK ", ap.get_animation_list())
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
	cam.position = Vector3(0, 1.0, 3.6)
	root.add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	cam.current = true
	for i in 30:
		await process_frame
	print("PLAYING ", ap.current_animation, " pos ", ap.current_animation_position)
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/walk_test.png")
	quit(0)
