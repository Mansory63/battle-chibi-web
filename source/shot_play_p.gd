extends SceneTree
func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(540, 960))
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	m._on_menu_play()
	var L = m.live
	var n := 0
	while L.state != "round" and n < 3000:
		await process_frame
		n += 1
	for i in 60:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/p_play.png")
	print("STATE ", L.state)
	quit(0)
