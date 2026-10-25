extends SceneTree

func _initialize() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# Spieler direkt vor die Tür des ersten Hauses stellen und Eingabe simulieren
	main.phase = "play"
	main.player_pos = main._door_of(0) + Vector2(0, 10)
	var idx: int = main._nearest_door()
	print("nearest door index: ", idx)
	main._enter_house(idx)
	print("inside: ", main.inside, " loot in room: ", main._current_loot().size())
	for i in 30:
		main._step_player(Vector2(5, 0))
		await process_frame
	print("after moving inside, pos: ", main.player_pos)
	main.player_pos = main.ROOM_DOOR + Vector2(0, -5)
	main._exit_house()
	print("after exit: inside=", main.inside, " pos=", main.player_pos)
	# Weiterlaufen im Freien ohne Fehler
	for i in 120:
		main._update_play(1.0 / 60.0)
		await process_frame
	print("outdoor ok, health=", main.health, " phase=", main.phase, " bots alive=", main._living_bots())
	quit(0)
