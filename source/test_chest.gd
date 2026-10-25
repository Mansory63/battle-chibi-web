extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	m.fall_timer = 0.01
	for i in 5: await process_frame
	m.player_pos = Vector2(1180, 760)
	m.loot.clear()
	m.loot.append({"pos": Vector2(1190, 760), "kind": "chest", "rar": 3})
	for b in m.bots:
		b["alive"] = false
	var t0 := Time.get_ticks_msec()
	var t := 0.0
	while (Time.get_ticks_msec() - t0) < 1500:
		await process_frame
		t += 0.016
	print("after 1.5s loot=", m.loot.size(), " timer=", snappedf(m.chest_timer, 0.1))
	while (Time.get_ticks_msec() - t0) < 3800:
		await process_frame
		t += 0.016
	var kinds := []
	for it in m.loot: kinds.append(it["kind"])
	print("after 3.8s loot=", kinds)
	quit(0)
