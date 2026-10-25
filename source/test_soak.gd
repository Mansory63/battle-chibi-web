extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.hardcore = true
	m._on_menu_play()
	m.phase = "play"
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var frames := 0
	while frames < 6000 and m.phase == "play":
		if frames % 40 == 0:
			m.touch.move_vec = Vector2.from_angle(rng.randf() * TAU)
			m.touch.fire_held = rng.randf() < 0.7
			m.touch.aim_active = rng.randf() < 0.5
			m.touch.aim_vec = Vector2.from_angle(rng.randf() * TAU)
		if frames % 500 == 0:
			m.player_pos = m._random_free(22.0)
		if frames % 900 == 450:
			m._try_dash()
		await process_frame
		frames += 1
	print("soak frames: ", frames, " phase: ", m.phase, " kills: ", m.kills, " health: ", snappedf(m.health, 0.1), " bots alive: ", m._living_bots(), " loot: ", m.loot.size())
	quit(0)
