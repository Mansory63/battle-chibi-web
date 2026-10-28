extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	for i in 420:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/after_step3.png")
	quit(0)
