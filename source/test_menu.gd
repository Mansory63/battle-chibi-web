extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	print("start phase: ", m.phase, " menu visible: ", m.menu_layer.visible, " touch visible: ", m.touch.visible)
	m._on_menu_play()
	print("after play: ", m.phase, " menu visible: ", m.menu_layer.visible, " touch visible: ", m.touch.visible)
	for i in 300:
		await process_frame
	print("after 300 frames: ", m.phase)
	m.phase = "play"
	m.health = 1.0
	m._damage_player(5.0)
	print("after death: ", m.phase, " title: ", m.menu_title.text, " button: ", m.menu_play.text)
	quit(0)
