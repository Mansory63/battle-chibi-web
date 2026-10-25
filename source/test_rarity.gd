extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	m.phase = "play"
	var chests := 0
	var ground := 0
	for it in m.loot:
		if it["kind"] == "chest": chests += 1
		else: ground += 1
	print("ground items: ", ground, " chests: ", chests)
	# Gold-Kiste öffnen
	m.loot.clear()
	m.player_pos = Vector2(1200, 900)
	m.loot.append({"pos": Vector2(1200, 900), "kind": "chest", "rar": 3})
	m._update_play(1.0)
	print("chest after 1 s still closed: ", m.loot.size() == 1)
	m._update_play(2.1)
	var kinds := []
	for it in m.loot:
		kinds.append("%s/%d" % [it["kind"], it["rar"]])
	print("gold chest drops: ", kinds)
	# Legendäre Waffe aufheben -> Schaden 1,5x
	var w: Dictionary = m.loot[0]
	m.player_pos = w["pos"]
	m._update_play(0.016)
	print("weapon: ", m.weapon, " rarity: ", m.weapon_rar)
	m.bullets.clear()
	m._fire(-1, Vector2(1200, 900), Vector2.RIGHT, m.weapon)
	print("bullet damage: ", m.bullets[0]["damage"], " base: ", m.WEAPONS[m.weapon]["damage"])
	# Nahkampf trifft Bot
	m.weapon = ""
	m.melee = "bat"
	var b: Dictionary = m.bots[0]
	b["pos"] = m.player_pos + Vector2(50, 0)
	b["health"] = 100.0
	m._melee_attack(-1, m.player_pos, Vector2.RIGHT, "bat")
	print("bot health after bat: ", b["health"])
	# Bot mit Fäusten trifft Spieler
	m.health = 100.0
	m.shield = 0.0
	m._melee_attack(0, b["pos"], Vector2.LEFT, "fist")
	print("player health after bot fist: ", m.health)
	# Dash lädt sich auf
	m.dash_charges = 0
	for i in 500:
		m._update_play(0.02)
	print("dash charges after 10 s: ", m.dash_charges)
	quit(0)
