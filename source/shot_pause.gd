extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	await process_frame
	m._toggle_pause()
	for i in 420:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/pause_check.png")
	quit(0)
