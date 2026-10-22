extends SceneTree
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	print("sfx loaded: ", m.sfx.keys().size(), " music: ", m.music_player.stream != null, " minimap: ", m.minimap != null)
	var xp_before: int = m.save_xp
	m._on_menu_play()
	m.phase = "play"
	# Bot läuft zu einer Waffe und hebt sie auf
	var b: Dictionary = m.bots[0]
	m.player_pos = Vector2(50, 50)
	b["pos"] = Vector2(1200, 1300)
	m.loot.append({"pos": Vector2(1260, 1300), "kind": "ak"})
	for i in 120:
		m._update_bots(1.0 / 60.0)
	print("bot weapon: ", b["weapon"], " gun tex: ", b["gun"] != null)
	# Kill durch den Spieler zählt
	m.bots[1]["health"] = 1.0
	m.bots[1]["pos"] = Vector2(1200, 905)
	m.bullets.append({"pos": Vector2(1200, 905), "vel": Vector2.ZERO, "damage": 10.0, "life": 1.0, "owner": -1, "explode": 0.0})
	m._update_bullets(0.016)
	print("kills: ", m.kills)
	# Runde verlieren -> XP gespeichert
	m.health = 1.0
	m._damage_player(10.0)
	print("phase: ", m.phase, " xp gained: ", m.save_xp - xp_before, " title: ", m.menu_title.text)
	var cfg := ConfigFile.new()
	print("save file ok: ", cfg.load(m.SAVE_PATH) == OK, " xp in file: ", cfg.get_value("pass", "xp", -1))
	m._update_pass_label()
	print(m.pass_label.text.split("\n")[0])
	quit(0)
