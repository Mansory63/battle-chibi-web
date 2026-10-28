extends SceneTree
func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(540, 960))
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	m._on_menu_play()
	for i in 120:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/portrait_check.png")
	quit(0)
