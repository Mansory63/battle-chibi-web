extends SceneTree
func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(540, 960))
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 60:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/p_menu.png")
	m._on_menu_play()
	for i in 20:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/p_intro.png")
	quit(0)
