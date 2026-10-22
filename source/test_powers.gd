extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m.phase = "play"
	# Schild fängt Schaden ab
	m._apply_loot("shield")
	m._damage_player(30.0)
	print("shield after hit: ", m.shield, " health: ", m.health)
	# Rakete: Bot direkt vor den Spieler stellen und feuern
	m._apply_loot("rocket")
	m.bots[0]["pos"] = m.player_pos + Vector2(0, -150)
	m.bots[0]["health"] = 100.0
	m.facing = Vector2.UP
	m._fire(-1, m.player_pos, Vector2.UP, "rocket")
	for i in 60:
		m._update_bullets(1.0 / 60.0)
	print("bot0 health after rocket: ", m.bots[0]["health"], " explosions: ", m.explosions.size())
	# Sprung über Hindernis
	m._apply_loot("jump")
	var r: Rect2 = m.obstacles[0]
	m.player_pos = Vector2(r.position.x + r.size.x / 2.0, r.position.y - 40)
	m._try_dash()
	for i in 30:
		m._step_player(Vector2(0, 8))
	print("jump crossed obstacle: ", m.player_pos.y > r.end.y, " pos=", m.player_pos)
	# Alle Waffen feuern einmal
	for w in ["pistol", "smg", "ak", "minigun", "shotgun", "sniper", "rocket"]:
		m.bullets.clear()
		m._fire(-1, Vector2(600, 900), Vector2.RIGHT, w)
		print(w, " bullets: ", m.bullets.size())
	quit(0)
