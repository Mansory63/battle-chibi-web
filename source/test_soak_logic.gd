extends SceneTree
# 15-Minuten-Logiklauf (ohne Bildausgabe): Live-Modus, zufaellige Eingaben, Runden, Fehlerzaehlung
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var start := Time.get_ticks_msec()
	var end_ms := start + 15 * 60 * 1000
	var frames := 0
	var max_bots := 0
	var last_state := ""
	var rounds := 0
	var last_print := start
	while Time.get_ticks_msec() < end_ms:
		if frames % 30 == 0 and m.touch != null:
			m.touch.move_vec = Vector2.from_angle(rng.randf() * TAU)
			m.touch.fire_held = rng.randf() < 0.7
			m.touch.aim_active = rng.randf() < 0.5
			m.touch.aim_vec = Vector2.from_angle(rng.randf() * TAU)
		if m.live != null and not m.live.demo:
			m.live.demo = true   # Demo-Ereignisse: Beitritte, Likes, Follows, Geschenke
		if m.live != null and str(m.live.state) != last_state:
			if str(m.live.state) == "pause" and last_state == "round":
				rounds += 1
			last_state = str(m.live.state)
		if frames % 60 == 0:
			var alive := 0
			for b in m.bots:
				if b["alive"]:
					alive += 1
			max_bots = maxi(max_bots, alive)
		if Time.get_ticks_msec() - last_print >= 60000:
			last_print = Time.get_ticks_msec()
			print("t=%ds frames=%d rounds=%d state=%s alive_bots=%d" % [(last_print - start) / 1000, frames, rounds, last_state, max_bots])
		await process_frame
		frames += 1
	print("LOGIC_SOAK_DONE duration_s=%d frames=%d rounds_completed=%d max_alive_bots=%d" % [(Time.get_ticks_msec() - start) / 1000, frames, rounds, max_bots])
	quit(0)
