extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	var L = m.live
	var n := 0
	while L.state != "round" and n < 3000:
		await process_frame
		n += 1
	print("round after frames=", n, " state=", L.state)
	L.t = L.BOSS_SPAWN_AT + 0.1
	for i in 10:
		await process_frame
	var b = m.bots[L.SLOTS * 4]
	print("A boss_done=", L.boss_done, " health=", b.get("health"), " alive=", b.get("alive"), " boss=", b.get("boss"))
	for i in 60:
		await process_frame
	print("B state=", L.state, " boss_alive=", L._boss_alive(), " health=", b.get("health"))
	root.get_viewport().get_texture().get_image().save_png("/home/claude/scratch/shots/boss.png")
	quit(0)
