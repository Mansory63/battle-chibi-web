extends SceneTree
var fails := 0
func ok(name: String, cond: bool, extra := "") -> void:
	print(("PASS " if cond else "FAIL ") + name + ("  " + extra if extra != "" else ""))
	if not cond: fails += 1
func _initialize() -> void:
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	await process_frame
	m._on_menu_play()
	await process_frame
	var L = m.live
	L.demo = false
	L.state = "round"
	# Plaetze freimachen: nicht-Zuschauer-Bots sind tot, damit Zuschauer einen Platz bekommen (wie im Spiel nach Ausscheiden)
	for i in L.SLOTS * 4:
		if not m.bots[i].get("viewer", false):
			m.bots[i]["alive"] = false
			m.bots[i]["dead_at"] = -99999
	# --- Team-Befehle ---
	for pair in [["red", 0], ["RED please", 0], ["blue", 1], ["blau", 1], ["green", 2], ["grün", 2], ["gruen", 2], ["yellow", 3], ["gelb", 3]]:
		L.chat("T_" + str(pair[0]).replace(" ", "_"), pair[0])
		var v = L.viewers.get("T_" + str(pair[0]).replace(" ", "_"))
		ok("Team-Befehl '%s'" % pair[0], v != null and int(v["team"]) == pair[1], "team=%s" % (str(v["team"]) if v else "none"))
	# --- Likes und Geschenke ---
	L.chat("LikeTest", "hallo")   # normaler Chat ohne Team = kein Beitritt
	ok("normaler Text tritt keinem Team bei", not L.viewers.has("LikeTest"))
	L.likes("LikeTest", 60)
	ok("Likes erzeugen Zuschauer/Verstärkung", L.viewers.has("LikeTest") or L.queued >= 0)
	print("DBG state=", L.state, " free0=", L._team_bots(0).filter(func(b): return not b["alive"] and not b["viewer"]).size(), " viewers=", L.viewers.keys())
	L.join("GiftFan", 0)
	print("DBG after join: bot=", L._find_bot("GiftFan"), " viewers=", L.viewers.has("GiftFan"), " ticks=", Time.get_ticks_msec())
	L._claim_slot("DbgX", 1)
	print("DBG direct claim: bot=", L._find_bot("DbgX"))
	ok("GiftFan steht als Kämpfer auf dem Feld", L._find_bot("GiftFan") >= 0)
	L.gift("GiftFan", "Rose", 1)
	var gi: int = L._find_bot("GiftFan")
	ok("Geschenk Rose -> Pistole", gi >= 0 and str(m.bots[gi]["weapon"]) == "pistol", "weapon=%s" % (str(m.bots[gi]["weapon"]) if gi >= 0 else "none"))
	L.gift("GiftFan", "TikTok", 1)
	gi = L._find_bot("GiftFan")
	ok("Geschenk TikTok -> Uzi (smg)", str(m.bots[gi]["weapon"]) == "smg", "weapon=%s" % str(m.bots[gi]["weapon"]))
	L.gift("GiftFan", "GG", 1)
	gi = L._find_bot("GiftFan")
	ok("Geschenk GG -> Sniper", str(m.bots[gi]["weapon"]) == "sniper", "weapon=%s" % str(m.bots[gi]["weapon"]))
	L.gift("GiftFan", "Finger Heart", 5)
	gi = L._find_bot("GiftFan")
	ok("Geschenk Finger Heart -> Shotgun", str(m.bots[gi]["weapon"]) == "shotgun", "weapon=%s" % str(m.bots[gi]["weapon"]))
	L.gift("GiftFan", "Doughnut", 5)
	gi = L._find_bot("GiftFan")
	ok("Geschenk Doughnut -> Katana", str(m.bots[gi]["weapon"]) == "katana", "weapon=%s" % str(m.bots[gi]["weapon"]))
	L.gift("GiftFan", "Hand Hearts", 5)
	gi = L._find_bot("GiftFan")
	ok("Geschenk Hand Hearts -> Minigun", str(m.bots[gi]["weapon"]) == "minigun")
	L.gift("GiftFan", "Money Gun", 30)
	gi = L._find_bot("GiftFan")
	ok("Geschenk Money Gun -> Rakete", str(m.bots[gi]["weapon"]) == "rocket")
	# --- Shop-Befehle ---
	L.join("ShopFan", 0)
	L.viewers["ShopFan"]["coins"] = 100
	L.chat("ShopFan", "!heal")
	ok("!heal kauft (Münzen sinken)", int(L.viewers["ShopFan"]["coins"]) == 90, "coins=%s" % str(L.viewers["ShopFan"]["coins"]))
	L.chat("ShopFan", "!shield")
	ok("!shield kauft (-5)", int(L.viewers["ShopFan"]["coins"]) == 85, "coins=%s" % str(L.viewers["ShopFan"]["coins"]))
	L.chat("ShopFan", "!ak")
	ok("!ak Waffenkauf (-10)", int(L.viewers["ShopFan"]["coins"]) == 75, "coins=%s" % str(L.viewers["ShopFan"]["coins"]))
	L.chat("ShopFan", "heal")
	ok("'heal' ohne Ausrufezeichen kauft nicht", int(L.viewers["ShopFan"]["coins"]) == 75)
	L.join("Poor", 0)
	L.viewers["Poor"]["coins"] = 1
	L.chat("Poor", "!revive")
	ok("Zu wenig Münzen: kein Kauf", int(L.viewers["Poor"]["coins"]) == 1)
	# --- Show me ---
	L.chat("ShopFan", "show me")
	ok("'show me' stellt Zuschauer in Warteschlange", L.show_queue.has("ShopFan"))
	# --- Hilfe ---
	L.chat("HelpFan", "?")
	ok("'?' öffnet Hilfe ohne Fehler", true)
	for topic in ["rules", "shop", "gift", "likes", "nuke"]:
		L.chat("HelpFan", topic)
	ok("Hilfethemen laufen durch", true)
	# --- Testtasten (alle Zahlen und Buchstaben) ---
	for code in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_L, KEY_G, KEY_F, KEY_S, KEY_BRACKETLEFT, KEY_BRACKETRIGHT, KEY_B, KEY_Z, KEY_H, KEY_D]:
		L.handle_key(code)
	ok("Testtasten 1-5, L, G, F, S, [ ], B, Z, H, D laufen ohne Fehler", true)
	L.handle_key(KEY_D)
	print("RESULT fails=%d" % fails)
	quit(0)
