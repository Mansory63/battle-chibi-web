extends SceneTree
# 15-Minuten-Dauerlauf: zufaellige Eingaben, Rundenwechsel, FPS-Proben
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	m.phase = "play"
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var start := Time.get_ticks_msec()
	var end_ms := start + 15 * 60 * 1000
	var frames := 0
	var rounds := 0
	var last_sample := start
	var fps_samples: Array = []
	var worst := 9999.0
	var last_phase: String = m.phase
	while Time.get_ticks_msec() < end_ms:
		if frames % 40 == 0:
			m.touch.move_vec = Vector2.from_angle(rng.randf() * TAU)
			m.touch.fire_held = rng.randf() < 0.7
			m.touch.aim_active = rng.randf() < 0.5
			m.touch.aim_vec = Vector2.from_angle(rng.randf() * TAU)
		if frames % 500 == 0:
			m.player_pos = m._random_free(22.0)
		if frames % 900 == 450:
			m._try_dash()
		if m.phase != "play" and m.phase != last_phase:
			rounds += 1
		if m.phase != "play":
			m._on_menu_play()
			m.phase = "play"
		last_phase = m.phase
		var now := Time.get_ticks_msec()
		if now - last_sample >= 5000:
			var f := Engine.get_frames_per_second()
			fps_samples.append(f)
			worst = minf(worst, f)
			last_sample = now
			print("t=%ds fps=%.0f frames=%d rounds=%d" % [(now - start) / 1000, f, frames, rounds])
		await process_frame
		frames += 1
	var avg := 0.0
	for f in fps_samples:
		avg += f
	avg = avg / maxf(1.0, fps_samples.size())
	print("SOAK_DONE duration_s=%d frames=%d rounds=%d fps_avg=%.1f fps_min=%.1f samples=%d" % [(Time.get_ticks_msec() - start) / 1000, frames, rounds, avg, worst, fps_samples.size()])
	quit(0)
