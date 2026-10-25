extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	m.phase = "play"
	m.player_pos = Vector2(1200, 900)
	m._update_view()
	var s0: Vector2 = m._w(m.player_pos)
	m.touch.move_vec = Vector2(0, -1)
	for i in 30:
		m._update_play(1.0 / 60.0)
	m._update_view()
	var s1: Vector2 = m._w(m.player_pos)
	print("joystick up -> screen move: ", (s1 - s0).round(), "  (x should be ~0, y negative)")
	m.touch.move_vec = Vector2(1, 0)
	s0 = m._w(m.player_pos)
	for i in 30:
		m._update_play(1.0 / 60.0)
	s1 = m._w(m.player_pos)
	print("joystick right -> screen move: ", (s1 - s0).round(), "  (y should be ~0, x positive)")
	quit(0)
