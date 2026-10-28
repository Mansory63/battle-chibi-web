extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	await process_frame
	var img := Image.create(120, 120, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.95, 0.4, 0.2))
	for y in 120:
		for x in 120:
			if (x - 60) * (x - 60) + (y - 40) * (y - 40) < 400:
				img.set_pixel(x, y, Color(1, 0.9, 0.7))
	var url := "data:image/png;base64," + Marshalls.raw_to_base64(img.save_png_to_buffer())
	m.live.ingest({"event": "chat", "data": {"nickname": "TestFan", "comment": "RED", "avatar": url}})
	m.live.ingest({"event": "chat", "data": {"nickname": "Kim", "comment": "BLUE", "avatar": "data:image/png;base64,AAAA"}})
	for i in 60:
		await process_frame
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/avatar_check.png")
	print("AVATARS:", m.live.avatar_tex.keys())
	quit(0)
