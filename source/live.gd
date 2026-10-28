extends RefCounted
# TikTok-Live-Modus: automatische Runden, 4 Teams, Zuschauer = Kämpfer mit Namen.
# Ereignisse kommen über: JS (window.bcLive), WebSocket (?ws=ws://localhost:PORT), Demo (?demo=1) oder Testtasten.

const ROUND_TIME := 180.0
const PAUSE_TIME := 40.0      # 40 s Pause: erst 10 s Ergebnis, dann Erklärung + Anmeldung für die nächste Runde
const EXPLAIN_TIME := 30.0     # letzte 30 s der Pause: Erklärung + Warteschlange
const QUEUE_DROP_MS := 90000   # wer 90 s lang nicht aktiv war (Stream verlassen), fliegt aus der Warteschlange
const SLOTS := 12                  # Kämpfer pro Team (4 x 12 = 48)
const HP := 170.0
const START_R := 3400.0   # Startkreis liegt außerhalb der Karte und schrumpft ins Spielfeld
const END_R := 120.0
const CORNER_R := 1050.0
const SMALL_START_R := 850.0      # opt-in 1700px-Durchmesser
const SMALL_CORNER_R := 540.0
const LIKE_GOAL := 100
const TEAM_NAMES := ["RED", "BLUE", "GREEN", "YELLOW"]
const TEAM_COLORS := [Color(1.0, 0.3, 0.3), Color(0.35, 0.6, 1.0), Color(0.3, 0.85, 0.4), Color(1.0, 0.85, 0.25), Color(0.75, 0.3, 0.95)]
const TIER_NAMES := ["", "RARE", "EPIC", "LEGENDARY"]
const LOOT_KINDS := ["pistol"]  # Waffen nur per Geschenk/Kauf, am Boden nur Pistole
# Geschenk-Name (klein geschrieben) -> Waffe. Anpassbar; unbekannte Geschenke werden nach Münzwert zugeordnet.
# Es gibt nur noch vier Waffen: Pistole, AK, Minigun, Raketenwerfer
const GIFT_WEAPONS := {"rose": "pistol", "ice cream cone": "ak", "hand hearts": "minigun", "money gun": "rocket"}
const FILLER_NAMES := ["Luki", "Mia", "Jonas", "Lena", "Tim", "Anna", "Ben", "Emma", "Finn", "Sofia", "Noah", "Lara", "Paul", "Nina", "Leo", "Zoe", "Max", "Ida", "Elias", "Jana", "Ali", "Yara", "Kian", "Mira"]
const SKINS := ["char_player", "char_red", "char_green", "char_yellow", "char_purple", "char_orange", "char_cyan", "char_pink"]

var m
var on := false
var state := "round"
var t := 0.0
var pause_t := 0.0
var round_no := 0
var round_start_ms := 0
var free_check_done := false
const FREE_LOCK_S := 30.0   # nach 30 s einer Runde fliegen inaktive Gratis-Zuschauer raus (Likes und Chat zählen als Aktivität)
var viewers: Dictionary = {}       # name -> {team, coins, wins, kills, last, pending}
var queued := 0
var team_points := [0, 0, 0, 0]
var team_likes := [0, 0, 0, 0]
var round_kills := [0, 0, 0, 0]
var alive_t := [0, 0, 0, 0]
var streak_team := -1
var streak := 0
var crate_t := 30.0
var crate_next := 0
var focus := -1
var focus_t := 0.0
var focus_lock := 0.0
var show_queue: Array = []
var banner := ""
var banner_t := 0.0
var banner_col := Color.WHITE
var toast := ""
var toast_t := 0.0
var winner := -1
var topsup: Array = [{}, {}, {}, {}]
var splats: Array = []
# Atombombe (teuerstes Geschenk): Warnung, Blitz, Pilzwolke, nur Knochen bleiben
const BOSS_SPAWN_AT := 60.0
const INTRO_TIME := 4.0           # Start-Animation: Teamkarten und Countdown, Figuren stehen still
const BOSS_DEADLINE := 165.0      # Boss fällt spätestens hier, auch ohne Treffer (Sanduhr)
const BONE_WAVE_EVERY := 20.0      # alle 20 s rückt eine neue Welle Knochen-Krieger mit Schwert aus dem Gefängnis aus
const BONE_WAVE_SIZE := 4
const BONE_MAX_ALIVE := 6         # nie mehr als 6 Knochen gleichzeitig auf dem Feld (Bots können sie nicht besiegen)
const ZOMBIE_DECAY := 1.5          # Knochen-Krieger verlieren pro Sekunde so viel Leben und sterben mit der Zeit
const BOSS_WARNING := 8.0
const NUKE_WARN := 5.0   # Countdown 5-4-3-2-1, dann Einschlag
const NUKE_PIX := 1.0    # Pixel-Pilz blitzt nach dem Einschlag 1 Sekunde auf
const PIX_MUSH := [
	"....XXXXXX....",
	"..XXXXXXXXXX..",
	".XXXXOOXXXXXX.",
	"XXXXOOOOXXXXXX",
	"XXXXOOXXXXXXXX",
	"XXXXXXXXXXXXXX",
	".XXXXXXXXXXXX.",
	"..XXXXXXXXXX..",
	"....XXXXXX....",
	".....XXXX.....",
	".....XXXX.....",
	".....XXXX.....",
	"....XXXXXX....",
	"...XXXXXXXX...",
]
const NUKE_COINS := 40000
var nuke_t := -1.0
var nuke_by := ""
var nuke_done := false
var nuke_survivor := ""
var nuke_pos := Vector2.ZERO
var bones: Array = []
var events: Array = []
var slow_until := 0
var say_t := 0.0
var ws: WebSocketPeer = null
var ws_url := ""
var ws_open := false
var arena_small := false
var arena_r := START_R
var zone_speed := 1.0   # Schrumpf-Tempo: 0.5 = halb so schnell, 2.0 = doppelt so schnell
var corner_r := CORNER_R
var demo := false
var demo_t := 0.0
var demo_gift_t := 20.0
var help := false
var js_cb = null
var check_t := 0.0
var fn_i := 0
var boss_done := false
var boss_spawn_pos := Vector2.ZERO
var zombie_kills := 0
var streak_kills := {}
var warned_30 := false
var bone_next := 15.0

# ---------- Start ----------
func begin(main, opts := {}) -> void:
	m = main
	on = true
	demo = bool(opts.get("demo", false))
	zone_speed = clampf(float(opts.get("zone_speed", 1.0)), 0.25, 3.0)
	arena_small = str(opts.get("arena", "")) == "small"
	arena_r = SMALL_START_R if arena_small else START_R
	corner_r = SMALL_CORNER_R if arena_small else CORNER_R
	ws_url = str(opts.get("ws", ""))
	if ws_url != "":
		ws = WebSocketPeer.new()
		ws.connect_to_url(ws_url)
	_setup_js()
	m.menu_layer.visible = false
	m.touch.visible = false
	m.phase = "play"
	m.bot_dmg_mult = 0.1
	m.bot_cd_mult = 1.3
	m.zone_dmg = 0.5
	m.xp_mult = 0.0
	if OS.has_feature("web"):
		m._web_started()
	start_round()
	# Einstiegs-Erklärung vor der ersten Runde (zählt nicht als Runde)
	round_no -= 1
	state = "pause"
	pause_t = EXPLAIN_TIME

func _setup_js() -> void:
	if not OS.has_feature("web"):
		return
	js_cb = JavaScriptBridge.create_callback(_on_js)
	var w = JavaScriptBridge.get_interface("window")
	w.bcLiveRaw = js_cb
	JavaScriptBridge.eval("window.bcLive=function(o){window.bcLiveRaw(typeof o==='string'?o:JSON.stringify(o));};", true)

func _on_js(args: Array) -> void:
	if args.size() > 0:
		_ingest_text(str(args[0]))

# ---------- Ereignisse ----------
func _ingest_text(s: String) -> void:
	var j = JSON.parse_string(s)
	if j != null:
		ingest(j)

func ingest(d) -> void:
	if d is Array:
		for x in d:
			ingest(x)
		return
	if not (d is Dictionary):
		return
	var data: Dictionary = d["data"] if d.get("data") is Dictionary else d
	var ev := str(d.get("event", d.get("type", ""))).to_lower()
	var nm := str(data.get("nickname", data.get("uniqueId", data.get("name", data.get("user", ""))))).strip_edges()
	match ev:
		"chat", "comment":
			chat(nm, str(data.get("comment", data.get("text", ""))))
		"like":
			likes(nm, int(data.get("likeCount", data.get("count", 1))))
		"gift":
			gift(nm, str(data.get("giftName", data.get("gift", ""))), int(data.get("diamondCount", data.get("coins", 1))) * maxi(1, int(data.get("repeatCount", 1))))
		"follow":
			follow(nm)
		"share":
			share(nm)
		"join":
			if data.has("team"):
				join(nm, int(data["team"]))

func _clean(n: String) -> String:
	var out := ""
	for c in n:
		if c.unicode_at(0) >= 32 and c != "'" and c != "\"" and c != "\\" and c != "<" and c != ">":
			out += c
	return out.strip_edges().left(12)

func _team_from_text(low: String) -> int:
	for w in ["rot", "red"]:
		if low == w or low.begins_with(w + " "):
			return 0
	for w in ["blau", "blue"]:
		if low == w or low.begins_with(w + " "):
			return 1
	for w in ["grün", "gruen", "green"]:
		if low == w or low.begins_with(w + " "):
			return 2
	for w in ["gelb", "yellow"]:
		if low == w or low.begins_with(w + " "):
			return 3
	return -1

# Hilfe im Chat: Schlüsselwort schreiben, Erklärung erscheint für alle auf dem Stream
const HELP_TOPICS := {
	"rules": ["1. Chat RED, BLUE, GREEN or YELLOW to join a team", "2. Likes = reinforcements for your team", "3. Gifts = weapon + crate for your team", "4. Chat shop: !heal · !shield · !revive · !ak · !smg · ...", "5. The circle shrinks. Last one standing wins"],
	"shop": ["!shield = +50 shield (5 coins)", "!heal = heal to full health (10 coins)", "!revive = bring a dead player back (15 coins)", "Galaxy gift = atomic bomb next round", "weapons: send the gift – Rose pistol · TikTok uzi · GG sniper · Finger Heart shotgun · Ice Cream Cone AK · Hand Hearts minigun · Money Gun rocket"],
	"gift": ["Every paid gift = weapon + crate for your team", "Rose = Pistol · TikTok = Uzi · GG = Sniper · Finger Heart = Pumpgun", "Ice Cream Cone = AK · Doughnut = Katana · Hand Hearts = Minigun · Money Gun = Rocket", "Universe = ATOMIC BOMB"],
	"likes": ["Likes fill your team's bar", "Every 50 likes = one reinforcement fighter", "Likes count as activity: stay active or you are removed"],
	"queue": ["12 fighters per team", "Everybody else waits in the queue", "Free players who did nothing for 30 s of a round are removed"],
	"nuke": ["Universe gift = ATOMIC BOMB", "The atomic bomb is a special gift, not a free action"],
}
var help_lines: Array = []
var help_title := ""
var help_t := 0.0

func _show_help(key: String) -> void:
	help_title = key.to_upper()
	help_lines = HELP_TOPICS[key]
	help_t = 12.0

func _draw_help(vs: Vector2) -> void:
	var pw := minf(vs.x - 24.0, 600.0)
	var ph := 46.0 + 30.0 * help_lines.size()
	var px := 12.0
	var py := 150.0
	m._pill(Rect2(px, py, pw, ph), Color(0.05, 0.06, 0.12, 0.9), 18)
	m._text(Vector2(px + 20, py + 10), help_title, 20, Color(1, 0.9, 0.5), pw - 40.0)
	var y := py + 42.0
	for line in help_lines:
		m._text(Vector2(px + 20, y), str(line), 20, Color(0.95, 0.97, 1.0), pw - 40.0)
		y += 30.0

func chat(nm: String, text: String) -> void:
	var cn := _clean(nm)
	if viewers.has(cn):
		viewers[cn]["last"] = Time.get_ticks_msec()  # jede Nachricht zählt als Aktivität
	var low := text.to_lower().strip_edges()
	if HELP_TOPICS.has(low):
		_show_help(low)
		return
	if low == "?" or low == "help" or low == "how to play":
		_show_help("rules")
		return
	var tm := _team_from_text(low)
	if tm >= 0:
		join(nm, tm)
	elif _shop_word(low) != "":
		_buy(_clean(nm), _shop_word(low))
	elif low.contains("show me") and viewers.has(_clean(nm)):
		show_queue.append(_clean(nm))
		_toast("%s will be shown" % _clean(nm))

# Shop: Befehle im Chat, bezahlt mit Münzen aus Geschenken
const SHOP := {"shield": 5, "heal": 10, "revive": 15}
const SHOP_WEAPONS := {"pistol": 3, "smg": 5, "shotgun": 8, "ak": 10, "sniper": 12, "minigun": 15, "rocket": 20}

# Kaufbefehle brauchen das Sonderzeichen "!" (z.B. "!heal", "!ak")
func _shop_word(low: String) -> String:
	if not low.begins_with("!"):
		return ""
	var w := low.substr(1).strip_edges()
	if SHOP.has(w):
		return w
	return ""

func _buy(nm: String, item: String) -> void:
	if not viewers.has(nm) or state != "round":
		return
	var is_weapon := SHOP_WEAPONS.has(item)
	var price: int = SHOP_WEAPONS[item] if is_weapon else SHOP[item]
	var v: Dictionary = viewers[nm]
	if int(v["coins"]) < price:
		_toast("%s: not enough coins for %s (%d)" % [nm, item, price], Color(1, 0.6, 0.3))
		return
	if item == "nuke":
		v["coins"] = int(v["coins"]) - price
		_toast("%s buys the atomic bomb (-%d coins)" % [nm, price], Color(1, 0.5, 0.1))
		nuke(nm)
		return
	var i := _find_bot(nm)
	if i < 0:
		_toast("%s is not on the field right now" % nm, Color(1, 0.6, 0.3))
		return
	var b: Dictionary = m.bots[i]
	if is_weapon:
		if not b["alive"]:
			_toast("%s is dead – only a revive helps" % nm, Color(1, 0.6, 0.3))
			return
		_equip(b, item, 0)
		v["coins"] = int(v["coins"]) - price
		m._spark_burst(b["pos"], Color(1.0, 0.85, 0.3), 24, 300.0)
		_toast("%s equips %s (-%d coins)" % [nm, m.WEAPONS[item]["name"], price], Color(0.5, 1.0, 0.6))
		return
	if item == "revive":
		if b["alive"]:
			_toast("%s is still alive – revive only works on the dead" % nm, Color(1, 0.6, 0.3))
			return
		var tm: int = int(v["team"])
		_reset_bot(b, tm, nm, true, m._nearest_free(_centroid(tm) + Vector2.from_angle(randf() * TAU) * 80.0, m.BOT_RADIUS))
		b["health"] = HP
	elif not b["alive"]:
		_toast("%s is dead – only a revive helps" % nm, Color(1, 0.6, 0.3))
		return
	elif item == "heal":
		b["health"] = HP
	else:
		b["health"] = minf(HP, float(b["health"]) + 50.0)
	v["coins"] = int(v["coins"]) - price
	m._spark_burst(b["pos"], Color(0.3, 0.9, 1.0), 24, 300.0)
	_toast("%s buys %s (-%d coins)" % [nm, item, price], Color(0.5, 1.0, 0.6))

func join(nm: String, team: int) -> void:
	nm = _clean(nm)
	if nm == "" or team < 0 or team > 3:
		return
	if viewers.has(nm):
		viewers[nm]["team"] = team
		viewers[nm]["last"] = Time.get_ticks_msec()
		return
	viewers[nm] = {"team": team, "coins": 0, "wins": 0, "kills": 0, "last": Time.get_ticks_msec(), "pending": null}
	_toast("%s joins %s!" % [nm, TEAM_NAMES[team]], TEAM_COLORS[team])
	if state == "round":
		_claim_slot(nm, team)

func _weakest_team() -> int:
	var best := 0
	for k in 4:
		if alive_t[k] < alive_t[best]:
			best = k
	return best

func _ensure_viewer(nm: String) -> String:
	nm = _clean(nm)
	if nm != "" and not viewers.has(nm):
		join(nm, _weakest_team())
	return nm

const REINFORCE_EVERY := 400   # alle 400 Likes des Teams ein Verstärkungs-Kämpfer
var team_total_likes: Array = [0, 0, 0, 0]
var reinforce_pending: Array = [0, 0, 0, 0]

# Verstärkung auf einen toten Platz des Teams setzen
func _spawn_reinforce() -> void:
	if state != "round":
		return
	for k in 4:
		if int(reinforce_pending[k]) <= 0:
			continue
		for b in _team_bots(k):
			if not b["alive"] and not b["viewer"] and Time.get_ticks_msec() - int(b.get("dead_at", 0)) > 1500:
				_reset_bot(b, k, "Reinforcement", false, m._nearest_free(_centroid(k) + Vector2.from_angle(randf() * TAU) * 90.0, m.BOT_RADIUS))
				_equip(b, "pistol", 1)
				reinforce_pending[k] = int(reinforce_pending[k]) - 1
				m._spark_burst(b["pos"], TEAM_COLORS[k], 20, 300.0)
				break

func likes(nm: String, n: int) -> void:
	nm = _clean(nm)
	var tm := -1
	if viewers.has(nm):
		tm = int(viewers[nm]["team"])
		viewers[nm]["last"] = Time.get_ticks_msec()
		# Visuelle Belohnung: kleine Funken in der Teamfarbe an der eigenen Figur (keine Münzen)
		var bi := _find_bot(nm)
		if bi >= 0 and m.bots[bi]["alive"]:
			m._spark_burst(m.bots[bi]["pos"], TEAM_COLORS[tm], 6, 200.0)
	else:
		tm = 0
		for k in 4:
			if team_likes[k] < team_likes[tm]:
				tm = k
	team_likes[tm] += maxi(1, n)
	# Verstärkung: alle 50 Likes ein Kämpfer, max. 3 wartend
	var before: int = int(team_total_likes[tm]) / REINFORCE_EVERY
	team_total_likes[tm] += maxi(1, n)
	var after: int = int(team_total_likes[tm]) / REINFORCE_EVERY
	if after > before and state == "round":
		reinforce_pending[tm] = mini(3, int(reinforce_pending[tm]) + (after - before))
		_toast("%s gets reinforcement (%d waiting)" % [TEAM_NAMES[tm], reinforce_pending[tm]], TEAM_COLORS[tm])
	if team_likes[tm] >= LIKE_GOAL:
		team_likes[tm] = 0  # keine Kiste mehr: Kisten nur bei bezahlten Geschenken

func gift(nm: String, gname: String, coins: int) -> void:
	nm = _ensure_viewer(nm)
	if nm == "":
		return
	var v: Dictionary = viewers[nm]
	v["coins"] = int(v["coins"]) + coins
	var tm: int = v["team"]
	topsup[tm][nm] = int(topsup[tm].get(nm, 0)) + coins
	if gname.to_lower().contains("universe") or gname.to_lower().contains("galaxy") or coins >= NUKE_COINS:
		nuke(nm)
		return
	var wk: String = GIFT_WEAPONS.get(gname.to_lower(), "")
	if wk == "":
		var pool: Array = ["pistol", "ak", "minigun", "rocket"]
		wk = pool[clampi(int(log(float(maxi(1, coins))) / log(4.0)), 0, 3)]
	var rar := 1 if coins < 10 else (2 if coins < 100 else 3)
	_give_weapon(nm, wk, rar)
	_gift_moment(nm, gname, tm)
	# Kiste nur bei bezahltem Geschenk: sichtbar, dass jemand bezahlt hat
	if coins > 0:
		_drop_crate(tm, 1)

func nuke(nm: String) -> void:
	if state != "round" or nuke_t >= 0.0:
		_toast("%s gifts the atomic bomb – next round!" % nm, Color(1, 0.5, 0.1))
		return
	nuke_t = 0.0
	nuke_by = nm
	nuke_done = false
	nuke_pos = m.ZONE_CENTER
	_banner("ATOMIC BOMB - %s!" % nm.to_upper(), Color(1, 0.35, 0.1), 5.0)
	_say("Warning! Atomic bomb by %s!" % nm)

func _nuke_blast() -> void:
	nuke_done = true
	m.shake = 2.0
	slow_until = Time.get_ticks_msec() + 1400
	m.bullets.clear()
	var now := Time.get_ticks_msec()
	var spare := -1
	for i in SLOTS * 4:
		if m.bots[i]["alive"] and m.bots[i].get("viewer", false) and str(m.bots[i].get("name", "")) == nuke_by:
			spare = i
	if spare < 0 and viewers.has(nuke_by):
		var tk: int = viewers[nuke_by]["team"]
		for s2 in SLOTS:
			if m.bots[tk * SLOTS + s2]["alive"]:
				spare = tk * SLOTS + s2
				break
	for i in m.bots.size():
		var b: Dictionary = m.bots[i]
		if not b["alive"]:
			continue
		if i == spare:
			b["health"] = float(HP)
			nuke_survivor = str(b.get("name", nuke_by))
			_toast("%s survives in the bunker!" % nuke_survivor, Color(1, 0.9, 0.3))
			continue
		b["alive"] = false
		b["dead_at"] = now
		bones.append({"pos": b["pos"], "seed": randf() * TAU})
	m._play_sfx("rocket", 0.0)
	m._play_sfx("explosion", 0.0)

func follow(nm: String) -> void:
	nm = _clean(nm)
	if nm != "":
		_toast("Welcome, %s!" % nm)

func share(nm: String) -> void:
	nm = _clean(nm)
	if nm == "" or not viewers.has(nm):
		return
	var tm: int = viewers[nm]["team"]
	for b in _team_bots(tm):
		if b["alive"]:
			b["health"] = minf(HP, float(b["health"]) + 25.0)
	_toast("%s shares – %s gets health!" % [nm, TEAM_NAMES[tm]], TEAM_COLORS[tm])

# ---------- Kämpfer ----------
func _team_bots(k: int) -> Array:
	var out: Array = []
	for s in SLOTS:
		out.append(m.bots[k * SLOTS + s])
	return out

func _corner(k: int) -> Vector2:
	return m.ZONE_CENTER + Vector2.from_angle(k * PI / 2.0) * corner_r   # Teams starten in Himmelsrichtungen: Osten, Süden, Westen, Norden

func _centroid(k: int) -> Vector2:
	var sum := Vector2.ZERO
	var n := 0
	for b in _team_bots(k):
		if b["alive"]:
			sum += b["pos"]
			n += 1
	return sum / n if n > 0 else _corner(k)

func _skin_for(nm: String) -> String:
	return SKINS[abs(nm.hash()) % SKINS.size()]

func _reset_bot(b: Dictionary, k: int, nm: String, viewer: bool, pos: Vector2) -> void:
	b["pos"] = pos
	b["team"] = k + 1
	b["health"] = HP
	b["alive"] = true
	b["weapon"] = "fist"
	b["gun"] = null
	b["rar"] = 0
	b["aim"] = Vector2.from_angle(randf() * TAU)
	b["dir"] = Vector2.from_angle(randf() * TAU)
	b["think"] = randf_range(1.0, 3.0)
	b["cd"] = randf_range(0.5, 2.0)
	b["tid"] = -2
	b["tsc"] = 0.0
	b["name"] = nm
	b["viewer"] = viewer
	b["skin"] = _skin_for(nm)
	b["dead_at"] = -99999
	b["lh"] = -2
	b["moving"] = false
	b["scale"] = 1.0
	b["boss"] = false
	b["maxhp"] = HP
	b["cover_goal"] = Vector2.ZERO
	b["cover_refresh"] = 0.0

func _spawn_pos(k: int, spread := 150.0) -> Vector2:
	return m._nearest_free(_corner(k) + Vector2.from_angle(randf() * TAU) * randf_range(30.0, spread), m.BOT_RADIUS)

func _equip(b: Dictionary, wk: String, rar: int) -> void:
	b["weapon"] = wk
	b["rar"] = rar
	b["gun"] = m.tex_guns.get(wk, null)
	b["ammo"] = 999 if (wk == "pistol" or not m.WEAPONS.has(wk)) else int(m.WEAPONS[wk]["ammo"])

func _claim_slot(nm: String, k: int) -> void:
	for b in _team_bots(k):
		if not b["alive"] and not b["viewer"] and Time.get_ticks_msec() - int(b.get("dead_at", 0)) > 1500:
			_reset_bot(b, k, nm, true, m._nearest_free(_centroid(k) + Vector2.from_angle(randf() * TAU) * 90.0, m.BOT_RADIUS))
			_equip(b, "pistol", 1)
			m._spark_burst(b["pos"], TEAM_COLORS[k], 12, 260.0)
			return

func _find_bot(nm: String) -> int:
	for i in SLOTS * 4:
		var b: Dictionary = m.bots[i]
		if b["viewer"] and b["name"] == nm:
			return i
	return -1

func _give_weapon(nm: String, wk: String, rar: int) -> void:
	var i := _find_bot(nm)
	var tm: int = viewers[nm]["team"]
	if state != "round" or i < 0:
		viewers[nm]["pending"] = [wk, rar]
		_toast("%s: %s (%s) waits for the next round" % [nm, m.WEAPONS[wk]["name"] if m.WEAPONS.has(wk) else wk, TIER_NAMES[rar]], TEAM_COLORS[tm])
		return
	var b: Dictionary = m.bots[i]
	var revived: bool = not b["alive"]
	if revived:
		_reset_bot(b, tm, nm, true, m._nearest_free(_centroid(tm) + Vector2.from_angle(randf() * TAU) * 80.0, m.BOT_RADIUS))
	b["health"] = HP
	_equip(b, wk, rar)
	m._spark_burst(b["pos"], TEAM_COLORS[tm], 30, 380.0)
	m._spark_burst(b["pos"], Color(1, 0.9, 0.3), 20, 300.0)
	focus = i
	focus_lock = 6.0
	focus_t = 6.0
	var wn: String = m.WEAPONS[wk]["name"] if m.WEAPONS.has(wk) else "Katana"
	_banner("%s%s: %s (%s)" % [nm, " is back" if revived else "", wn, TIER_NAMES[rar]], TEAM_COLORS[tm], 3.5)
	_say("%s gets %s" % [nm, wn])

func _spawn_boss() -> void:
	var b: Dictionary = m.bots[SLOTS * 4]
	# Boss auf dem markierten, freien Punkt nahe dem Kartenmittelpunkt spawnen.
	_reset_bot(b, 4, "BOSS", false, boss_spawn_pos)
	b["health"] = 700.0
	b["maxhp"] = 700.0
	b["scale"] = 2.1
	b["boss"] = true
	b["skin"] = "reaper"
	_equip(b, "minigun", 3)
	focus = SLOTS * 4
	focus_lock = 4.0
	focus_t = 4.0
	m.shake = 1.4
	# Einschlag: Trümmer und Knochensplitter fliegen weit
	m._spark_burst(b["pos"], TEAM_COLORS[4], 70, 620.0)
	m._spark_burst(b["pos"], Color(0.95, 0.93, 0.85), 60, 520.0)
	m._spark_burst(b["pos"], Color(0.35, 0.02, 0.05), 40, 380.0)
	_banner("BOSS INCOMING!", TEAM_COLORS[4], 4.0)
	_say("The boss appears. Defeat it for legendary weapons")

func _drop_crate(k: int, tier_bias: int) -> void:
	var pos: Vector2 = m._nearest_free(_centroid(k) + Vector2.from_angle(randf() * TAU) * randf_range(80.0 if arena_small else 120.0, 150.0 if arena_small else 260.0), 24.0)
	var rar := clampi(1 + m._random_rarity([55, 33, 12]) + (tier_bias - 1 if tier_bias > 1 else 0), 1, 3)
	var kinds := ["pistol"]
	for n in 2:
		m.loot.append({"pos": m._nearest_free(pos + Vector2.from_angle(randf() * TAU) * 50.0, 24.0), "kind": kinds[randi() % kinds.size()], "rar": rar})
	m._spark_burst(pos, TEAM_COLORS[k], 26, 300.0)
	m._spark_burst(pos, Color(1, 0.9, 0.4), 14, 260.0)
	m.shake = maxf(m.shake, 0.15)
	_toast("Crate for %s (%s)!" % [TEAM_NAMES[k], TIER_NAMES[rar]], TEAM_COLORS[k])

# ---------- Runden ----------
# Gratis-Zuschauer ohne Aktivität seit Rundenstart fliegen raus, bezahlte bleiben
func _drop_inactive_free() -> void:
	for nm in viewers.keys():
		var v: Dictionary = viewers[nm]
		if int(v["coins"]) > 0 or int(v["last"]) >= round_start_ms:
			continue
		for i in SLOTS * 4:
			var b: Dictionary = m.bots[i]
			if b.get("viewer", false) and str(b.get("name", "")) == nm:
				b["alive"] = false
				b["viewer"] = false
				b["dead_at"] = -99999
		viewers.erase(nm)

func start_round() -> void:
	round_no += 1
	round_start_ms = Time.get_ticks_msec()
	free_check_done = false
	t = 0.0
	state = "round"
	reinforce_pending = [0, 0, 0, 0]
	winner = -1
	round_kills = [0, 0, 0, 0]
	streak_kills.clear()
	warned_30 = false
	crate_t = 30.0
	crate_next = randi() % 4
	boss_done = false
	bone_next = 15.0
	boss_spawn_pos = m._nearest_free(m.ZONE_CENTER, m.BOT_RADIUS)
	zombie_kills = 0
	splats.clear()
	bones.clear()
	nuke_t = -1.0
	nuke_done = false
	topsup = [{}, {}, {}, {}]
	m.elapsed = 0.0
	m.zone_time = ROUND_TIME
	m.zone_radius = arena_r
	m.bullets.clear()
	m.kill_feed.clear()
	m.loot.clear()
	var per_team: Array = [[], [], [], []]
	var names: Array = viewers.keys()
	names.sort_custom(func(a, b): return int(viewers[a]["last"]) > int(viewers[b]["last"]))
	queued = 0
	for nm in names:
		var k: int = viewers[nm]["team"]
		if per_team[k].size() < SLOTS:
			per_team[k].append(nm)
		elif Time.get_ticks_msec() - int(viewers[nm]["last"]) > QUEUE_DROP_MS:
			viewers.erase(nm)
		else:
			queued += 1
	var fi := randi() % FILLER_NAMES.size()
	for k in 4:
		var lead := _spawn_pos(k)
		for s in SLOTS:
			var b: Dictionary = m.bots[k * SLOTS + s]
			var pos: Vector2 = m._nearest_free(_corner(k) + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 170.0), m.BOT_RADIUS)
			if s < per_team[k].size():
				var nm: String = per_team[k][s]
				_reset_bot(b, k, nm, true, pos)
				var pend = viewers[nm].get("pending")
				if pend is Array:
					_equip(b, pend[0], int(pend[1]))
					viewers[nm]["pending"] = null
			else:
				fi += 1
				_reset_bot(b, k, "%s%d" % [FILLER_NAMES[fi % FILLER_NAMES.size()], 1 + fi / FILLER_NAMES.size()], false, pos)
	for i in range(SLOTS * 4, m.bots.size()):
		m.bots[i]["alive"] = false
		m.bots[i]["dead_at"] = -99999
		m.bots[i]["pos"] = Vector2(-500, -500)
	m.prison_open = false
	_spawn_loot()
	focus = -1
	focus_t = 0.0
	_banner("ROUND %d - FIGHT!" % round_no, Color(1, 0.9, 0.4), 3.0)
	_say("Round %d. Chat red, blue, green or yellow" % round_no)

func _spawn_loot() -> void:
	for k in 4:
		for i in 6:
			_add_loot(m._nearest_free(_corner(k) + Vector2.from_angle(randf() * TAU) * randf_range(60.0, 210.0 if arena_small else 380.0), 20.0))
	for i in (20 if arena_small else 28):
		var p: Vector2 = m.ZONE_CENTER + Vector2.from_angle(randf() * TAU) * sqrt(randf()) * (arena_r - 100.0)
		_add_loot(m._nearest_free(p, 20.0))

func _add_loot(p: Vector2) -> void:
	m.loot.append({"pos": p, "kind": LOOT_KINDS[randi() % LOOT_KINDS.size()], "rar": 1 + m._random_rarity([65, 27, 8])})

# Auto-Spawn: Knochen-Krieger kommen wellenweise aus dem Gefängnis, bewaffnet mit Schwert (Katana)
func _bone_wave_update() -> void:
	if t < bone_next:
		return
	bone_next = t + BONE_WAVE_EVERY
	if not m.prison_open:
		m._outbreak()
	var door: Vector2 = m._prison_door()
	if arena_small:
		door = m._nearest_free(m.ZONE_CENTER + Vector2(-420.0, 100.0), m.BOT_RADIUS)
	var n := 0
	for i in range(m.BOT_COUNT, m.bots.size()):
		var z: Dictionary = m.bots[i]
		if not z.get("zombie", false) or z["alive"]:
			continue
		if n >= BONE_WAVE_SIZE:
			break
		m._revive_zombie(z, door, n)
		_equip(z, "katana", 0)
		n += 1
	for i in range(m.BOT_COUNT, m.bots.size()):
		var z2: Dictionary = m.bots[i]
		if z2.get("zombie", false) and z2["alive"] and z2["weapon"] == "fist":
			_equip(z2, "katana", 0)
	# Obergrenze: überzählige Knochen gehen zurück ins Gefängnis
	var alive_z := 0
	for i in range(m.BOT_COUNT, m.bots.size()):
		var z3: Dictionary = m.bots[i]
		if z3.get("zombie", false) and z3["alive"]:
			alive_z += 1
			if alive_z > BONE_MAX_ALIVE:
				z3["alive"] = false
				z3["dead_at"] = -99999
				z3["pos"] = Vector2(-500, -500)

func _boss_alive() -> bool:
	for j in m.bots.size():
		if m.bots[j]["alive"] and int(m.bots[j]["team"]) == 5:
			return true
	return false

# Knochen-Krieger sterben mit der Zeit; der Boss verliert ab Spawn so viel Leben, dass er garantiert vor Rundenende fällt
func _decay_units(delta: float) -> void:
	for i in m.bots.size():
		var b: Dictionary = m.bots[i]
		if not b["alive"]:
			continue
		if b.get("zombie", false):
			b["health"] = float(b["health"]) - ZOMBIE_DECAY * delta
			if float(b["health"]) <= 0.0:
				b["lh"] = -2
				m._kill_bot(i)
		elif b.get("boss", false) and int(b["team"]) == 5:
			var span := maxf(1.0, BOSS_DEADLINE - BOSS_SPAWN_AT)
			b["health"] = float(b["health"]) - float(b["maxhp"]) / span * delta
			if float(b["health"]) <= 0.0:
				m._kill_bot(i)

func end_round() -> void:
	var best := -1
	var n := 0
	for k in 4:
		if alive_t[k] > 0:
			best = k
			n += 1
	if n != 1:
		best = 0
		for k in 4:
			if round_kills[k] > round_kills[best]:
				best = k
	winner = best
	team_points[best] += 1
	if streak_team == best:
		streak += 1
	else:
		streak_team = best
		streak = 1
	state = "pause"
	pause_t = PAUSE_TIME
	slow_until = Time.get_ticks_msec() + 1600
	for i in SLOTS * 4:
		var b: Dictionary = m.bots[i]
		if b["alive"] and int(b["team"]) == best + 1 and b["viewer"]:
			viewers[b["name"]]["wins"] = int(viewers[b["name"]]["wins"]) + 1
	for i in 3:
		m._spark_burst(_centroid(best) + Vector2(randf_range(-80, 80), randf_range(-80, 80)), TEAM_COLORS[best], 24, 420.0)
	_banner("%s WINS THE ROUND!" % TEAM_NAMES[best], TEAM_COLORS[best], 3.5)
	_say("Team %s wins the round" % TEAM_NAMES[best])

# ---------- pro Bild ----------
var queue_t := 0.0

# Warteschlange live zählen: Zuschauer, die keinen Kämpfer-Platz haben
var queue_names: Array = []

func _refresh_queue() -> void:
	var seated := {}
	for i in SLOTS * 4:
		if m.bots[i].get("viewer", false):
			seated[str(m.bots[i].get("name", ""))] = true
	queue_names.clear()
	for nm in viewers.keys():
		if not seated.has(nm):
			queue_names.append(nm)
	queued = queue_names.size()

func update(delta: float) -> void:
	help_t = maxf(0.0, help_t - delta)
	if state == "pause":
		m.bullets.clear()  # keine Geschosse über der Erklärung
		m.sparks.clear()
		m.flashes.clear()
		for bi in m.bots.size():
			m.bots[bi]["cd"] = maxf(float(m.bots[bi]["cd"]), 1.0)  # in der Pause schießt niemand
	if state == "round" and not warned_30 and t >= ROUND_TIME - 30.0:
		warned_30 = true
		_banner("30 SECONDS LEFT!", Color(1, 0.35, 0.3), 2.5)
		m.shake = maxf(m.shake, 0.4)
	queue_t -= delta
	if queue_t <= 0.0:
		queue_t = 0.5
		_refresh_queue()
	_poll_ws()
	if Engine.get_process_frames() % 30 == 0:
		_spawn_reinforce()
	if demo:
		_demo(delta)
	var now := Time.get_ticks_msec()
	Engine.time_scale = 0.35 if now < slow_until else 1.0
	if nuke_t >= 0.0:
		nuke_t += delta
		if not nuke_done and nuke_t >= NUKE_WARN:
			_nuke_blast()
		if nuke_t > 16.0:
			nuke_t = -1.0
	banner_t = maxf(0.0, banner_t - delta)
	toast_t = maxf(0.0, toast_t - delta)
	say_t = maxf(0.0, say_t - delta)
	if state == "round":
		t += delta
		if not free_check_done and t >= FREE_LOCK_S:
			free_check_done = true
			_drop_inactive_free()
		m.elapsed = t
		var zt := t * zone_speed
		var r := lerpf(arena_r, END_R, clampf(zt / ROUND_TIME, 0.0, 1.0)) if zt < ROUND_TIME else maxf(0.0, END_R * (1.0 - (zt - ROUND_TIME) / 30.0))
		m.zone_radius = r
		if not boss_done and t >= BOSS_SPAWN_AT:
			boss_done = true
			_spawn_boss()
		if t > INTRO_TIME:
			m._update_bots(delta)
		_decay_units(delta)
		_bone_wave_update()
		if t > 240.0:
			for i in SLOTS * 4:
				var b: Dictionary = m.bots[i]
				if b["alive"] and b["pos"].distance_to(m.ZONE_CENTER) > r:
					b["health"] -= 5.0 * delta
					if b["health"] <= 0.0:
						b["lh"] = -2
						m._kill_bot(i)
		check_t -= delta
		if check_t <= 0.0:
			check_t = 0.3
			alive_t = [0, 0, 0, 0]
			for i in SLOTS * 4:
				if m.bots[i]["alive"] and int(m.bots[i]["team"]) - 1 >= 0 and int(m.bots[i]["team"]) - 1 <= 3:
					alive_t[int(m.bots[i]["team"]) - 1] += 1
			var teams := 0
			for k in 4:
				if alive_t[k] > 0:
					teams += 1
			if teams <= 1 and t > 3.0 and not _boss_alive():
				end_round()
			elif t > ROUND_TIME + 45.0:
				end_round()
	else:
		pause_t -= delta
		if pause_t <= 0.0:
			Engine.time_scale = 1.0
			start_round()
	_update_focus(delta)
	_update_zoom(delta)

# Grobe Übersicht bei großer Zone, lesbare Nahansicht zum Rundenende.
# Kamera, 2D-HUD und 3D-Einheiten nutzen dieselbe ZOOM-Variable.
func _update_zoom(delta: float) -> void:
	var progress := clampf((arena_r - m.zone_radius) / maxf(1.0, arena_r - END_R), 0.0, 1.0)
	var start_zoom := 1.0 if arena_small else 0.95   # Startansicht lesbar (vorher 0.70: Figuren winzig)
	var target := lerpf(start_zoom, 1.35, pow(progress, 0.8))
	if state == "pause":
		target = 1.0
	m.ZOOM = lerpf(m.ZOOM, target, 1.0 - exp(-2.2 * delta))
	m.cam.zoom = Vector2(m.ZOOM, m.ZOOM)

func _update_focus(delta: float) -> void:
	focus_t -= delta
	focus_lock = maxf(0.0, focus_lock - delta)
	var need: bool = focus < 0 or not m.bots[focus]["alive"] or focus_t <= 0.0
	if need and focus_lock <= 0.0:
		_pick_focus()
	var target: Vector2 = m.player_pos
	if nuke_t >= 0.0:
		target = nuke_pos
	elif state == "round" and not boss_done and t >= BOSS_SPAWN_AT - BOSS_WARNING:
		target = boss_spawn_pos  # Kamera zeigt den Einschlagspunkt fruehzeitig.
	elif state == "pause" and winner >= 0:
		target = _centroid(winner)
	elif focus >= 0:
		target = m.bots[focus]["pos"]
	m.player_pos = m.player_pos.lerp(target, 1.0 - exp(-3.0 * delta))
	m.inside = -1

func _pick_focus() -> void:
	focus_t = 6.0
	while show_queue.size() > 0:
		var nm: String = show_queue.pop_front()
		var i := _find_bot(nm)
		if i >= 0 and m.bots[i]["alive"]:
			focus = i
			focus_t = 5.0
			return
	# Mitten im Kampf: Kämpfer, dessen nächster Gegner am nächsten ist
	var cands: Array = []
	for i in SLOTS * 4:
		var b: Dictionary = m.bots[i]
		if not b["alive"]:
			continue
		var d := 99999.0
		for j in SLOTS * 4:
			var o: Dictionary = m.bots[j]
			if o["alive"] and o["team"] != b["team"]:
				d = minf(d, b["pos"].distance_squared_to(o["pos"]))
		cands.append([d, i])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	if cands.size() > 0:
		focus = cands[randi() % mini(4, cands.size())][1]

func _gift_moment(nm: String, gname: String, tm: int) -> void:
	var col: Color = TEAM_COLORS[clampi(tm, 0, 4)]
	var bi := _find_bot(nm)
	if bi >= 0:
		m._spark_burst(m.bots[bi]["pos"], col, 40, 520.0)
		m._spark_burst(m.bots[bi]["pos"], Color(1, 1, 1), 16, 360.0)
	m.shake = maxf(m.shake, 0.6)
	_banner("%s sent %s!" % [nm, gname.capitalize()], col, 2.5)

func on_kill(i: int) -> void:
	var b: Dictionary = m.bots[i]
	var k := int(b["team"]) - 1
	if k < 0 or k > 4:
		return   # nur Teams 1-5 (4 Teams + Boss) gehören zum TikTok-Modus
	if k == 5:
		# Team 6 = Zombies: normale Treffer koennen sie endgueltig ausschalten.
		m._spark_burst(b["pos"], Color(0.4, 1.0, 0.3), 28, 330.0)
		m._spark_burst(b["pos"], Color(0.95, 1.0, 0.8), 8, 180.0)
		var zk: int = int(b.get("lh", -2))
		if zk >= 0 and zk < SLOTS * 4:
			zombie_kills += 1
			var killer: Dictionary = m.bots[zk]
			if killer["viewer"]:
				var vn := str(killer["name"])
				if viewers.has(vn):
					viewers[vn]["kills"] = int(viewers[vn]["kills"]) + 1
			m.kill_feed.append({"text": "%s defeated a ZOMBIE" % str(killer["name"]), "t": 0.0})
		else:
			m.kill_feed.append({"text": "ZOMBIE eliminated", "t": 0.0})
		if m.kill_feed.size() > 5:
			m.kill_feed.pop_front()
		return
	if k == 4:
		_boss_dead(b)
		return
	var kl := int(b.get("lh", -2))
	var kname := ""
	if kl >= 0 and kl < m.bots.size() and int(m.bots[kl]["team"]) != int(b["team"]) and int(m.bots[kl]["team"]) <= 4:
		round_kills[int(m.bots[kl]["team"]) - 1] += 1
		kname = str(m.bots[kl]["name"])
		var sk := int(streak_kills.get(kname, 0)) + 1
		streak_kills[kname] = sk
		var tag := ""
		match sk:
			2:
				tag = "DOUBLE KILL"
			3:
				tag = "TRIPLE KILL"
			5:
				tag = "UNSTOPPABLE"
			7:
				tag = "GODLIKE"
		if tag != "":
			_banner("%s - %s!" % [tag, kname], TEAM_COLORS[int(m.bots[kl]["team"]) - 1], 2.5)
			m.shake = maxf(m.shake, 0.5)
			_say("%s %s" % [tag.to_lower(), kname])
		if m.bots[kl]["viewer"]:
			viewers[kname]["kills"] = int(viewers[kname]["kills"]) + 1
	if OS.get_environment("LIVEDBG") != "" and t < 30.0:
		print("kill t=", snapped(t, 0.1), " ", b["name"], " killer=", kl, " kw=", (m.bots[kl]["weapon"] if kl >= 0 else "zone"))
	m.kill_feed.append({"text": ("%s  ›  %s" % [kname, b["name"]]) if kname != "" else ("%s exploded" % b["name"]), "t": 0.0})
	if m.kill_feed.size() > 5:
		m.kill_feed.pop_front()
	# Comic-Platzen: Konfetti in Teamfarbe plus Farbklecks
	var col: Color = TEAM_COLORS[k]
	m._spark_burst(b["pos"], col, 26, 420.0)
	m._spark_burst(b["pos"], Color(1, 1, 1), 10, 300.0)
	m._spark_burst(b["pos"], Color(1, 0.9, 0.3), 10, 360.0)
	splats.append({"pos": b["pos"], "col": col, "r": randf_range(34.0, 56.0), "seed": randf() * TAU})
	if splats.size() > (200 if DisplayServer.is_touchscreen_available() else 400):
		splats.pop_front()
	var wk: String = b["weapon"]
	if m.WEAPONS.has(wk) or wk == "katana":
		m.loot.append({"pos": b["pos"], "kind": wk, "rar": int(b["rar"])})
	if b["viewer"] and kname != "" and int(m.bots[kl]["team"]) <= 4:
		_toast("%s blew up %s!" % [kname, b["name"]], TEAM_COLORS[int(m.bots[kl]["team"]) - 1])

func _boss_dead(b: Dictionary) -> void:
	var kl := int(b.get("lh", -2))
	m._spark_burst(b["pos"], TEAM_COLORS[4], 50, 520.0)
	m._spark_burst(b["pos"], Color(1, 0.9, 0.3), 30, 420.0)
	m.shake = 1.0
	var kinds := ["pistol"]
	for n in 3:
		m.loot.append({"pos": m._nearest_free(b["pos"] + Vector2.from_angle(TAU * n / 3.0) * 70.0, 24.0), "kind": kinds[randi() % kinds.size()], "rar": 3})
	if kl >= 0 and kl < SLOTS * 4 and int(m.bots[kl]["team"]) - 1 >= 0 and int(m.bots[kl]["team"]) - 1 <= 3:
		var kt := int(m.bots[kl]["team"]) - 1
		round_kills[kt] += 2
		_banner("K.O.! BOSS DOWN - %s +2 KILLS" % TEAM_NAMES[kt], TEAM_COLORS[kt], 4.0)
		_say("Team %s defeated the boss" % TEAM_NAMES[kt])
	else:
		_banner("K.O.! BOSS DOWN!", TEAM_COLORS[4], 3.0)

func _banner(txt: String, col: Color, secs: float) -> void:
	banner = txt
	banner_col = col
	banner_t = secs

func _toast(txt: String, col := Color(1, 1, 1)) -> void:
	toast = txt
	toast_t = 3.0

func _say(txt: String) -> void:
	if not OS.has_feature("web") or m.muted or say_t > 0.0:
		return
	say_t = 3.0
	JavaScriptBridge.eval("try{var u=new SpeechSynthesisUtterance('%s');u.lang='en-US';u.rate=1.1;speechSynthesis.speak(u);}catch(e){}" % _clean(txt).replace("'", ""), true)

# ---------- WebSocket ----------
func _poll_ws() -> void:
	if ws == null:
		return
	ws.poll()
	var st := ws.get_ready_state()
	ws_open = st == WebSocketPeer.STATE_OPEN
	if ws_open:
		while ws.get_available_packet_count() > 0:
			_ingest_text(ws.get_packet().get_string_from_utf8())
	elif st == WebSocketPeer.STATE_CLOSED:
		ws.connect_to_url(ws_url)

# ---------- Demo und Testtasten ----------
func _rand_name() -> String:
	return "%s%d" % [FILLER_NAMES[randi() % FILLER_NAMES.size()], randi() % 90 + 10]

func _demo(delta: float) -> void:
	demo_t -= delta
	demo_gift_t -= delta
	if demo_t <= 0.0:
		demo_t = randf_range(0.6, 1.6)
		var r := randf()
		if r < 0.45 and viewers.size() < 44:
			join(_rand_name(), randi() % 4)
		elif r < 0.9:
			likes(viewers.keys()[randi() % maxi(1, viewers.size())] if viewers.size() > 0 else "", randi() % 12 + 3)
		elif viewers.size() > 0:
			follow(viewers.keys()[randi() % viewers.size()])
	if demo_gift_t <= 0.0 and viewers.size() > 0:
		demo_gift_t = randf_range(15.0, 35.0)
		gift(viewers.keys()[randi() % viewers.size()], ["Rose", "Finger Heart", "Doughnut", "Hand Hearts", "Money Gun", "GG"][randi() % 6], [1, 5, 30, 100, 500, 1][randi() % 6])

func handle_key(code: int) -> void:
	match code:
		KEY_1, KEY_2, KEY_3, KEY_4:
			join(_rand_name(), code - KEY_1)
		KEY_5:
			for i in 12:
				join(_rand_name(), randi() % 4)
		KEY_L:
			likes("", 60)
		KEY_G:
			if viewers.size() > 0:
				gift(viewers.keys()[randi() % viewers.size()], ["Rose", "Finger Heart", "Doughnut", "Hand Hearts", "Money Gun"][randi() % 5], [1, 5, 30, 100, 500][randi() % 5])
		KEY_F:
			follow(_rand_name())
		KEY_S:
			if viewers.size() > 0:
				share(viewers.keys()[randi() % viewers.size()])
		KEY_BRACKETLEFT:
			zone_speed = maxf(0.25, zone_speed - 0.25)
			_toast("Zone speed %.2f" % zone_speed)
		KEY_BRACKETRIGHT:
			zone_speed = minf(3.0, zone_speed + 0.25)
			_toast("Zone speed %.2f" % zone_speed)
		KEY_B:
			nuke(viewers.keys()[randi() % viewers.size()] if viewers.size() > 0 else "Fan")
		KEY_N:
			if state == "round":
				end_round()
		KEY_D:
			demo = not demo
		KEY_H:
			help = not help
		KEY_Z:
			if viewers.size() > 0:
				show_queue.append(viewers.keys()[randi() % viewers.size()])

# ---------- Boss-Zielzone, im Weltkoordinatensystem (unter den Figuren) ----------
func _draw_boss_signal() -> void:
	if state != "round" or boss_done or t < BOSS_SPAWN_AT - BOSS_WARNING:
		return
	var center: Vector2 = boss_spawn_pos
	var remain := maxf(0.0, BOSS_SPAWN_AT - t)
	var pulse := 0.5 + 0.5 * sin(t * 9.0)
	var rad := 125.0 + pulse * 23.0
	m.draw_circle(center, rad + 25.0, Color(0.7, 0.02, 0.02, 0.15 + 0.14 * pulse))
	m.draw_arc(center, rad, 0.0, TAU, 72, Color(1.0, 0.16, 0.04, 0.9), 12.0)
	m.draw_arc(center, 85.0, 0.0, TAU, 64, Color(1.0, 0.75, 0.2, 0.8), 5.0)
	# Warnsymbol am Boden: Schaedel + gekreuzte Schwerter.
	var color := Color(1.0, 0.86, 0.28)
	m.draw_circle(center + Vector2(0, -14), 32.0, color)
	m.draw_rect(Rect2(center + Vector2(-19, 10), Vector2(38, 19)), color)
	m.draw_circle(center + Vector2(-13, -20), 7.0, Color(0.14, 0.03, 0.04))
	m.draw_circle(center + Vector2(13, -20), 7.0, Color(0.14, 0.03, 0.04))
	m.draw_line(center + Vector2(-60, 65), center + Vector2(60, -55), Color.WHITE, 7.0)
	m.draw_line(center + Vector2(60, 65), center + Vector2(-60, -55), Color.WHITE, 7.0)
	var font: Font = ThemeDB.fallback_font
	m.draw_string_outline(font, center + Vector2(-125, 120), "BOSS IN %d" % int(ceil(remain)), HORIZONTAL_ALIGNMENT_CENTER, 250, 30, 7, Color(0.13, 0.02, 0.04))
	m.draw_string(font, center + Vector2(-125, 120), "BOSS IN %d" % int(ceil(remain)), HORIZONTAL_ALIGNMENT_CENTER, 250, 30, Color.WHITE)

# ---------- Zeichnen ----------
func draw_ground() -> void:
	if arena_small:
		m.draw_arc(m.ZONE_CENTER, arena_r, 0.0, TAU, 128, Color(1.0, 0.85, 0.25, 0.78), 12.0)
	_draw_boss_signal()
	if nuke_t >= NUKE_WARN:
		var rr := minf(2100.0, (nuke_t - NUKE_WARN) * 950.0)
		m.draw_circle(nuke_pos, rr, Color(0.06, 0.04, 0.03, 0.6))
		m.draw_circle(nuke_pos, rr * 0.55, Color(0.03, 0.02, 0.02, 0.5))
		if rr < 2100.0:
			m.draw_arc(nuke_pos, rr, 0.0, TAU, 96, Color(1, 0.55, 0.1, 0.8), 14.0)
	for bn in bones:
		var bp: Vector2 = bn["pos"]
		var a: float = bn["seed"]
		var d := Vector2.from_angle(a)
		var bc := Color(0.95, 0.93, 0.85)
		for sgn in [-1.0, 1.0]:
			var dd: Vector2 = d.rotated(sgn * 0.6) * 20.0
			m.draw_line(bp - dd, bp + dd, bc, 5.0)
			m.draw_circle(bp - dd, 4.0, bc)
			m.draw_circle(bp + dd, 4.0, bc)
		m.draw_circle(bp + Vector2(0, -6), 11.0, bc)
		m.draw_rect(Rect2(bp + Vector2(-6, 1), Vector2(12, 7)), bc)
		m.draw_circle(bp + Vector2(-4, -6), 3.0, Color(0.1, 0.08, 0.08))
		m.draw_circle(bp + Vector2(4, -6), 3.0, Color(0.1, 0.08, 0.08))
	# Blutflecken als Texturen statt Polygonkreise (viel günstiger im Browser)
	for s in splats:
		var c: Color = s["col"]
		c.a = 0.5
		var p: Vector2 = s["pos"]
		var r: float = s["r"]
		m.draw_texture_rect(m.tex_disc, Rect2(p - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false, c)
		var a: float = float(s["seed"])
		var q: Vector2 = p + Vector2.from_angle(a) * r * 1.1
		m.draw_texture_rect(m.tex_disc, Rect2(q - Vector2(r * 0.35, r * 0.35), Vector2(r * 0.7, r * 0.7)), false, c)

func _fmt_time(sec: float) -> String:
	var s := maxi(0, int(ceil(sec)))
	return "%d:%02d" % [floori(s / 60.0), s % 60]

func draw_hud(vs: Vector2) -> void:
	_draw_intro(vs)
	# 3D-Figuren liegen über dem 2D-Fenster: in der Erklärung ausblenden, damit der Text lesbar ist
	if m.units3d != null and m.units3d.layer != null:
		m.units3d.layer.visible = state != "pause"
	var f: Font = ThemeDB.fallback_font
	var ui := 1.0 if vs.x >= vs.y else 1.75   # Hochformat: Anzeigen größer
	# Teamfarben-Ringe, Namen und Lebensbalken
	for i in (0 if state == "pause" else SLOTS * 4 + 1):  # in der Pause keine Balken über den Texten
		var b: Dictionary = m.bots[i]
		if not b["alive"]:
			continue
		var sp: Vector2 = m._fx_screen(b["pos"])
		if not Rect2(Vector2(-60, -160), vs + Vector2(120, 260)).has_point(sp):
			continue
		var col: Color = TEAM_COLORS[clampi(int(b["team"]) - 1, 0, 4)]
		var z: float = m.ZOOM
		var rx := 24.0 * z   # etwas schmaler, damit Ringe im Gedränge nicht zu einer Fläche verschmelzen
		var ry: float = rx * m.VIEW_TILT
		m.fx.draw_texture_rect(m.tex_ring, Rect2(sp.x - rx * 1.0, sp.y + 8.0 - ry * 1.0, rx * 2.0, ry * 2.0), false, Color(col.r, col.g, col.b, 0.55))
		var hb: float = 112.0 * z / 1.15
		m._fx_bar2(sp, minf(100.0, float(b["health"]) * 100.0 / float(b.get("maxhp", HP))), col, hb)
		var nm: String = b["name"]
		if b["viewer"] and _is_top(nm, int(b["team"]) - 1):
			nm = "♛ " + nm
		var nc := Color.WHITE if b["viewer"] else Color(0.8, 0.85, 0.9, 0.85)
		var ty := sp.y - hb - 12.0
		var nfs := int(17 * ui)
		m.fx.draw_string_outline(f, Vector2(sp.x - 90, ty), nm, HORIZONTAL_ALIGNMENT_CENTER, 180, nfs, 6, Color(0.06, 0.05, 0.1, 0.95))
		m.fx.draw_string(f, Vector2(sp.x - 90, ty), nm, HORIZONTAL_ALIGNMENT_CENTER, 180, nfs, nc)
		if b["viewer"] and viewers.has(nm):
			_coin_bar(Vector2(sp.x, ty + 5.0), int(viewers[nm]["coins"]))
		if i == focus:
			m.fx.draw_string(f, Vector2(sp.x - 90, ty - 22 * ui), "★", HORIZONTAL_ALIGNMENT_CENTER, 180, int(22 * ui), Color(1, 0.9, 0.3))
	# Gesundheitsleiste aller sichtbaren Zombies; gruen = feindlich, nicht unsterblich.
	for zi in range(SLOTS * 4 + 1, m.bots.size()):
		var z: Dictionary = m.bots[zi]
		if not z.get("zombie", false) or not z["alive"]:
			continue
		var zp: Vector2 = m._fx_screen(z["pos"])
		if not Rect2(Vector2(-50, -50), vs + Vector2(100, 100)).has_point(zp):
			continue
		# Kugel-Balken: jeder Treffer ist eine Kugel, bei voll ist der Knochen-Krieger tot
		var nb := 8
		var filled := clampi(int(floor((1.0 - float(z["health"]) / 60.0) * nb)), 0, nb)
		if filled > int(z.get("fill_shown", 0)):
			z["fill_shown"] = filled
			z["fill_t"] = Time.get_ticks_msec()
		_draw_bullet_bar(zp, filled, nb, z)
	m.fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2(ui, ui))
	vs = vs / ui
	# Spielregeln während der Pause
	# Kopfleiste: Countdown + Teams
	var w := minf(vs.x - 24.0, 760.0)
	var x0 := vs.x * 0.5 - w * 0.5
	var left := maxf(0.0, ROUND_TIME - t) if state == "round" else 0.0
	m._pill(Rect2(vs.x * 0.5 - 130, 10, 260, 54), Color(0.05, 0.06, 0.12, 0.8), 27)
	var tcol := Color(1, 0.9, 0.5) if left > 30.0 else Color(1, 0.4, 0.3)
	m._text(Vector2(vs.x * 0.5 - 130, 50), (_fmt_time(left) if state == "round" else "PAUSE %d" % int(ceil(pause_t))), 38, tcol, 260.0, HORIZONTAL_ALIGNMENT_CENTER)
	m._text(Vector2(vs.x * 0.5 - 130, 84), ("ROUND %d · MINI" % round_no) if arena_small else ("ROUND %d" % round_no), 16, Color(0.8, 0.9, 1.0), 260.0, HORIZONTAL_ALIGNMENT_CENTER)
	var cw := w / 4.0 - 6.0
	for k in 4:
		var cx := x0 + k * (cw + 8.0)
		var cy := 96.0
		var col: Color = TEAM_COLORS[k]
		m._pill(Rect2(cx, cy, cw, 66), Color(col.r * 0.35, col.g * 0.35, col.b * 0.35, 0.88), 14)
		m._text(Vector2(cx + 10, cy + 19), TEAM_NAMES[k], 17, col, cw - 12.0)
		var score_line := ("%d · %d K" % [alive_t[k], round_kills[k]]) if vs.x < 620.0 else ("%d alive · %d kills · %d rnd%s" % [alive_t[k], round_kills[k], team_points[k], ("  🔥x%d" % streak) if (streak_team == k and streak >= 2) else ""])
		m._text(Vector2(cx + 10, cy + 37), score_line, 12 if vs.x < 620.0 else 14, Color.WHITE, cw - 12.0)
		# Countdown: Balken und Zahl bis zum nächsten Verstärkungs-Kämpfer (Likes)
		var into: int = int(team_total_likes[k]) % REINFORCE_EVERY
		var likes_left: int = REINFORCE_EVERY - into
		m.fx.draw_rect(Rect2(cx + 4.0, cy + 47.0, cw - 8.0, 5.0), Color(0.05, 0.05, 0.1, 0.85))
		m.fx.draw_rect(Rect2(cx + 4.0, cy + 47.0, (cw - 8.0) * float(into) / float(REINFORCE_EVERY), 5.0), col)
		m._text(Vector2(cx + 4.0, cy + 54.0), "+1 in %d likes" % likes_left, 11, Color(0.95, 0.95, 1.0), cw - 8.0)
	var boss: Dictionary = m.bots[SLOTS * 4]
	if boss["alive"] and boss["boss"]:
		var bw := minf(vs.x - 40.0, 420.0)
		var bx := vs.x * 0.5 - bw * 0.5
		m._pill(Rect2(bx - 4, 172, bw + 8, 22), Color(0.05, 0.03, 0.1, 0.85), 11)
		m.fx.draw_rect(Rect2(bx, 176, bw * clampf(float(boss["health"]) / 700.0, 0.0, 1.0), 14), TEAM_COLORS[4])
		m._text(Vector2(bx, 190), "BOSS", 13, Color.WHITE, bw, HORIZONTAL_ALIGNMENT_CENTER)
	# Boss-Countdown zusätzlich sichtbar, wenn der Bodenmarker verdeckt ist.
	if state == "round" and not boss_done and t >= BOSS_SPAWN_AT - BOSS_WARNING:
		var remaining := maxi(0, int(ceil(BOSS_SPAWN_AT - t)))
		m._text(Vector2(vs.x * 0.5 - 160, 206), "BOSS IN %d" % remaining, 27, Color(1.0, 0.3, 0.16), 320, HORIZONTAL_ALIGNMENT_CENTER)
	# Zombie-Hinweis: Zombies sind verwundbar und koennen sterben.
	if m.prison_open:
		var remaining_z := 0
		for z in range(SLOTS * 4 + 1, m.bots.size()):
			if m.bots[z].get("zombie", false) and m.bots[z]["alive"]:
				remaining_z += 1
		m._text(Vector2(12, 162), "BONES: %d | KILLS: %d" % [remaining_z, zombie_kills], 14, Color(0.5, 1.0, 0.35), minf(260.0, vs.x - 20.0))
	# Kill-Feed links
	var fy := 192.0 if boss["alive"] and boss["boss"] else 170.0
	for kf in m.kill_feed:
		var fa := clampf(1.0 - (float(kf["t"]) - 4.0), 0.0, 1.0)
		if fa <= 0.0:
			continue
		var feed_w := minf(250.0, vs.x - 24.0)
		m._pill(Rect2(12, fy - 20, feed_w, 28), Color(0.05, 0.06, 0.12, 0.6 * fa), 14)
		m._text(Vector2(22, fy), str(kf["text"]), 15 if vs.x < 620.0 else 16, Color(1, 0.9, 0.6, fa), feed_w - 14.0)
		fy += 32.0
	# Top-Unterstützer rechts
	var ry := maxf(170.0, fy + 12.0) if vs.x < 620.0 else 170.0
	for k in 4:
		var top_n := ""
		var top_c := 0
		for nm in topsup[k]:
			if int(topsup[k][nm]) > top_c:
				top_c = int(topsup[k][nm])
				top_n = nm
		if top_n != "":
			var sx := 12.0 if vs.x < 620.0 else vs.x - 190.0
			m._pill(Rect2(sx, ry - 20, 178, 28), Color(0.05, 0.06, 0.12, 0.6), 14)
			m._text(Vector2(sx + 10, ry), "♛ %s" % top_n, 16, TEAM_COLORS[k], 160.0)
			ry += 32.0
	# Banner
	if banner_t > 0.0:
		var a := clampf(banner_t, 0.0, 1.0)
		var bc := banner_col
		bc.a = a
		# Banner als goldenes Band mit eingekerbten Enden (wie ein Titel-Band im Spiel)
		var fs := 32 if vs.x < 620.0 else 52
		var bw := minf(vs.x - 40.0, fs * 0.62 * float(banner.length()) + 80.0)
		var by := vs.y * 0.32 - fs * 0.15
		var bh := fs * 1.7
		var bx := vs.x * 0.5 - bw * 0.5
		var notch := bh * 0.45
		var band := PackedVector2Array([Vector2(bx, by), Vector2(bx + bw, by), Vector2(bx + bw - notch, by + bh * 0.5), Vector2(bx + bw, by + bh), Vector2(bx, by + bh), Vector2(bx + notch, by + bh * 0.5)])
		m.fx.draw_colored_polygon(band, Color(0.1, 0.06, 0.14, 0.9 * a))
		var inner := PackedVector2Array([Vector2(bx + 5, by + 5), Vector2(bx + bw - 5, by + 5), Vector2(bx + bw - notch, by + bh * 0.5), Vector2(bx + bw - 5, by + bh - 5), Vector2(bx + 5, by + bh - 5), Vector2(bx + notch, by + bh * 0.5)])
		m.fx.draw_colored_polygon(inner, Color(1.0, 0.86, 0.35, a))
		m._text(Vector2(0, by + bh * 0.5 + fs * 0.35), banner, fs, Color(0.3, 0.14, 0.02, a), vs.x, HORIZONTAL_ALIGNMENT_CENTER)
	if toast_t > 0.0:
		var ta := clampf(toast_t, 0.0, 1.0)
		var toast_w := minf(vs.x - 24.0, 520.0)
		var toast_x := (vs.x - toast_w) * 0.5
		m._pill(Rect2(toast_x, vs.y - 142, toast_w, 38), Color(0.05, 0.06, 0.12, 0.75 * ta), 19)
		m._text(Vector2(toast_x, vs.y - 116), toast, 16 if vs.x < 620.0 else 20, Color(1, 1, 1, ta), toast_w, HORIZONTAL_ALIGNMENT_CENTER)
	# Kompakte Anleitung, damit Text im Hochformat nicht abgeschnitten wird.
	var foot_w := minf(vs.x - 20.0, 680.0)
	var foot_x := (vs.x - foot_w) * 0.5
	m._pill(Rect2(foot_x, vs.y - 90, foot_w, 52), Color(0.05, 0.06, 0.12, 0.8), 26)
	# Shop unten: Kacheln mit Bild und Preisschild (Münzen)
	_draw_shop(vs, foot_x, foot_w)
	# Tipp-Leiste: wechselt alle 4 s zwischen kurzen Erklärungen
	const TIPS := [
		"Chat: type RED, BLUE, GREEN or YELLOW = fighters",
		"Likes = more fighters. The top bar shows how many",
		"Gifts = weapons (see the shop tiles)",
		"Chat shop: !heal !shield !revive (on your name)",
		"Galaxy gift = atomic bomb",
		"Last team standing wins. Beat the boss in time!",
	]
	var tip_i := int(Time.get_ticks_msec() / 4000.0) % TIPS.size()
	# Tipp passt sich der Leistenbreite an (kleiner werden statt überlaufen)
	var tip_txt := "TIP: " + str(TIPS[tip_i])
	var tip_size := 14 if vs.x >= 620.0 else 12
	var tip_font: Font = m.ui_font()
	while tip_size > 9 and tip_font.get_string_size(tip_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(tip_size * 1.12))).x > foot_w - 24.0:
		tip_size -= 1
	m._text(Vector2(foot_x + 10.0, vs.y - 80), tip_txt, tip_size, Color(1, 0.95, 0.7), foot_w - 20.0, HORIZONTAL_ALIGNMENT_CENTER)
	if state != "pause":
		m._text(Vector2(foot_x, vs.y - 57), "Queue: %d" % queued, 20, Color(1, 0.95, 0.7), foot_w, HORIZONTAL_ALIGNMENT_CENTER)
	if state == "pause" and not (nuke_t >= 0.0 and nuke_t < NUKE_WARN + 9.0):
		if pause_t > EXPLAIN_TIME:
			_draw_results(vs)   # Ergebnis der letzten Runde
		else:
			_draw_pause_info(vs)  # Countdown + Warteschlange
	if help_t > 0.0 and help_lines.size() > 0:
		_draw_help(vs)
	if help:
		m._text(Vector2(12, vs.y - 168), "TEST: 1-4 join · 5 many · L likes · G gift · F follow · S share · [ ] zone speed · Z show me · B atomic bomb · N end round · D demo · H help", 14, Color(0.7, 0.8, 0.9, 0.8))
	m.fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if nuke_t >= 0.0:
		_draw_nuke(vs)

func _draw_nuke(vs: Vector2) -> void:
	var sc: Vector2 = m._fx_screen(nuke_pos)
	# 1) Countdown 5-4-3-2-1 riesig in der Mitte
	if nuke_t < NUKE_WARN:
		var pulse := 0.5 + 0.5 * sin(nuke_t * 14.0)
		m.fx.draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 0.05, 0.0, 0.08 + 0.12 * pulse))
		var n := int(ceil(NUKE_WARN - nuke_t))
		var frac := fmod(nuke_t, 1.0)
		var punch := 1.0 + 0.6 * maxf(0.0, 1.0 - frac * 3.0)
		var col := Color(1, 0.9, 0.2) if n > 1 else Color(1, 0.3, 0.2)
		_big_text(vs, str(n), 340, col, punch)
		return
	# 2) Einschlag: Blitz, dann 1 Sekunde Pixel-Pilz
	var tp := nuke_t - NUKE_WARN
	if tp < 0.25:
		m.fx.draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 1, 0.92, 1.0 - tp / 0.25))
	if tp < NUKE_PIX:
		_draw_pixel_mushroom(vs, tp)
		_big_text(vs, "NUKE!", 200, Color(1, 0.95, 0.5), 1.0 + 0.4 * maxf(0.0, 1.0 - tp * 2.0))
		return
	# 3) Großer Atompilz
	var tb := tp - NUKE_PIX
	var fade := clampf(1.0 - (tb - 9.0) / 6.0, 0.0, 1.0)
	var z: float = m.ZOOM
	var e := 1.0 - pow(1.0 - clampf(tb / 6.0, 0.0, 1.0), 3.0)
	var h := vs.y * 0.36 * e
	# Druckwelle
	if tb < 2.5:
		var rr := tb * 1100.0 * z
		m.fx.draw_texture_rect(m.tex_ring, Rect2(sc.x - rr, sc.y - rr * 0.6, rr * 2.0, rr * 1.2), false, Color(1, 0.75, 0.4, 0.8 * (1.0 - tb / 2.5)))
	# Stiel: von unten orange, nach oben grau-braun, leicht verjüngt
	var n_s := 12
	for i in n_s:
		var f := float(i) / n_s
		var y := sc.y - h * f
		var w := lerpf(120.0, 70.0, f) * (0.6 + 0.4 * e)
		var col_s := Color(1.0, 0.5, 0.12).lerp(Color(0.38, 0.32, 0.29), clampf(f * 1.1, 0.0, 1.0))
		col_s.a = fade
		m._fdisc(Vector2(sc.x, y), w * 0.5, col_s)
		m.fx.draw_rect(Rect2(sc.x - w * 0.5, y - h / n_s, w, h / n_s + 2.0), col_s)
	# Feuerball am Boden
	m._fdisc(sc, 150.0 * e + 24.0, Color(1.0, 0.55, 0.12, 0.9 * fade))
	m._fdisc(sc, 90.0 * e + 12.0, Color(1.0, 0.9, 0.5, 0.9 * fade))
	# Pilzkappe
	var top := Vector2(sc.x, sc.y - h)
	var R := 210.0 * e + 28.0
	m._fdisc(top + Vector2(0, R * 0.14), R * 0.98, Color(0.3, 0.22, 0.19, 0.95 * fade))
	# Wolkenkranz oben
	for k in 22:
		var a := float(k) / 22.0 * TAU + tb * 0.12
		var off := Vector2(cos(a) * R * 0.8, sin(a) * R * 0.36 - R * 0.05)
		var cc := Color(0.42, 0.32, 0.28).lerp(Color(1.0, 0.55, 0.15), 0.4 + 0.4 * sin(a * 2.0 + tb * 1.5))
		cc.a = 0.95 * fade
		m._fdisc(top + off, R * (0.3 + 0.06 * sin(a * 3.0)), cc)
	# eingerollter Rand (nach außen hängend)
	for k in 12:
		var a2 := PI * float(k) / 11.0
		var pos2 := top + Vector2(cos(a2) * R * 0.95, sin(a2) * R * 0.22 + R * 0.2)
		m._fdisc(pos2, R * 0.2, Color(1.0, 0.62, 0.28, 0.9 * fade))
	# helle Kuppe und Kern
	m._fdisc(top + Vector2(0, -R * 0.25), R * 0.6, Color(1.0, 0.72, 0.35, 0.95 * fade))
	m._fdisc(top + Vector2(0, -R * 0.3), R * 0.36, Color(1.0, 0.95, 0.7, 0.9 * fade))
	# Blitz am Anfang des großen Pilzes
	if tb < 0.6:
		m.fx.draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 0.95, 0.8, 0.5 * (1.0 - tb / 0.6)))
	if tb > 1.0 and tb < 7.0:
		m._text(Vector2(vs.x * 0.5 - 340, vs.y * 0.14), "ONLY %s SURVIVED" % nuke_survivor.to_upper(), 40, Color(1, 0.9, 0.3, clampf(7.0 - tb, 0.0, 1.0)), 680.0, HORIZONTAL_ALIGNMENT_CENTER)

# Große Schrift mit dicker dunkler Umrandung, zentriert, optional mit Schlag-Effekt
# Shop-Leiste: Hilfsitems oben, Waffen darunter, jede Kachel mit Bild und Preisschild
func _draw_shop(vs: Vector2, fx: float, fw: float) -> void:
	# Eine Reihe mit acht Kacheln direkt über der Tipp-Leiste, damit der Kampf frei bleibt
	var top := vs.y - 186.0
	# Breite begrenzt, damit die Leiste nicht unter die Aktionsknöpfe rechts reicht
	fw = minf(fw, 580.0)
	m._pill(Rect2(fx, top, fw, 92), Color(0.05, 0.06, 0.12, 0.85), 18)
	var util := [["heal", SHOP["heal"]], ["shield", SHOP["shield"]], ["revive", SHOP["revive"]], ["nuke", -1]]   # Atombombe kostet keine Münzen: der Preis ist ein Galaxy-Geschenk
	var guns := ["pistol", "ak", "minigun", "rocket"]   # die vier Waffen zur Auswahl
	# Preis der Waffe = das Geschenk, das sie bringt
	var gift_tag := {"pistol": "Rose", "smg": "TikTok", "shotgun": "Finger", "ak": "Ice Cream", "sniper": "GG", "minigun": "Hands", "rocket": "Money Gun"}
	var tw := minf(96.0, (fw - 16.0) / 8.0)
	var x0 := fx + (fw - 8.0 * tw) * 0.5
	for k in util.size():
		_shop_tile(Vector2(x0 + k * tw, top + 6.0), tw - 6.0, str(util[k][0]), str(util[k][1]) if int(util[k][1]) >= 0 else "GALAXY")
	for k in guns.size():
		_shop_tile(Vector2(x0 + (k + 4) * tw, top + 6.0), tw - 6.0, guns[k], str(gift_tag[guns[k]]))

# Seitenansicht der kaufbaren Waffen, gezeichnet (keine Textur): Pistole, AK, Minigun, Raketenwerfer
func _gun_icon(key: String, c: Vector2, u: float) -> void:
	var steel := Color(0.36, 0.38, 0.44)
	var steel_hi := Color(0.62, 0.66, 0.72)
	var dark := Color(0.13, 0.13, 0.16)
	match key:
		"pistol":
			m.fx.draw_rect(Rect2(c + Vector2(-1.5 * u, -0.6 * u), Vector2(2.6 * u, 0.5 * u)), steel)
			m.fx.draw_rect(Rect2(c + Vector2(-1.5 * u, -0.6 * u), Vector2(2.6 * u, 0.14 * u)), steel_hi)
			m.fx.draw_rect(Rect2(c + Vector2(-0.2 * u, -0.1 * u), Vector2(1.1 * u, 0.42 * u)), steel.darkened(0.15))
			m.fx.draw_colored_polygon(PackedVector2Array([c + Vector2(0.2 * u, 0.32 * u), c + Vector2(1.05 * u, 0.32 * u), c + Vector2(0.85 * u, 1.45 * u), c + Vector2(0.3 * u, 1.45 * u)]), Color(0.3, 0.12, 0.2))
			m.fx.draw_line(c + Vector2(-0.15 * u, 0.42 * u), c + Vector2(0.45 * u, 0.42 * u), dark, 2.0)
			m.fx.draw_rect(Rect2(c + Vector2(1.1 * u, -0.6 * u), Vector2(0.2 * u, 0.12 * u)), dark)
		"ak":
			var wood := Color(0.62, 0.42, 0.22)
			var wood_hi := Color(0.8, 0.6, 0.35)
			m.fx.draw_colored_polygon(PackedVector2Array([c + Vector2(-1.7 * u, -0.1 * u), c + Vector2(-0.6 * u, -0.25 * u), c + Vector2(-0.5 * u, 0.3 * u), c + Vector2(-1.7 * u, 0.5 * u)]), wood)
			m.fx.draw_rect(Rect2(c + Vector2(-0.6 * u, -0.35 * u), Vector2(1.5 * u, 0.5 * u)), steel)
			m.fx.draw_rect(Rect2(c + Vector2(-0.6 * u, -0.35 * u), Vector2(1.5 * u, 0.12 * u)), steel_hi)
			m.fx.draw_rect(Rect2(c + Vector2(0.9 * u, -0.2 * u), Vector2(1.1 * u, 0.2 * u)), dark)
			m.fx.draw_rect(Rect2(c + Vector2(0.2 * u, -0.1 * u), Vector2(0.9 * u, 0.3 * u)), wood_hi)
			m.fx.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.1 * u, 0.15 * u), c + Vector2(0.35 * u, 0.15 * u), c + Vector2(0.25 * u, 1.0 * u), c + Vector2(-0.05 * u, 1.0 * u)]), dark)
			m.fx.draw_colored_polygon(PackedVector2Array([c + Vector2(0.45 * u, 0.15 * u), c + Vector2(0.8 * u, 0.15 * u), c + Vector2(0.65 * u, 0.9 * u), c + Vector2(0.4 * u, 0.9 * u)]), wood)
		"minigun":
			m.fx.draw_rect(Rect2(c + Vector2(-1.2 * u, -0.5 * u), Vector2(1.1 * u, 1.0 * u)), Color(0.8, 0.2, 0.2))
			m.fx.draw_rect(Rect2(c + Vector2(-1.2 * u, -0.5 * u), Vector2(1.1 * u, 0.18 * u)), Color(1, 0.5, 0.45))
			for bi in 4:
				var by := -0.45 * u + bi * 0.25 * u
				m.fx.draw_rect(Rect2(c + Vector2(-0.2 * u, by), Vector2(1.9 * u, 0.17 * u)), steel)
				m.fx.draw_rect(Rect2(c + Vector2(-0.2 * u, by), Vector2(1.9 * u, 0.06 * u)), steel_hi)
			m.fx.draw_rect(Rect2(c + Vector2(1.55 * u, -0.6 * u), Vector2(0.2 * u, 0.9 * u)), dark)
			m.fx.draw_rect(Rect2(c + Vector2(-1.0 * u, 0.5 * u), Vector2(0.4 * u, 0.9 * u)), dark)
			m.fx.draw_circle(c + Vector2(-0.8 * u, -0.7 * u), 0.3 * u, dark)
		"rocket":
			m.fx.draw_rect(Rect2(c + Vector2(-1.5 * u, -0.4 * u), Vector2(2.6 * u, 0.75 * u)), Color(0.3, 0.6, 0.35))
			m.fx.draw_rect(Rect2(c + Vector2(-1.5 * u, -0.4 * u), Vector2(2.6 * u, 0.16 * u)), Color(0.55, 0.85, 0.5))
			m.fx.draw_colored_polygon(PackedVector2Array([c + Vector2(1.1 * u, -0.3 * u), c + Vector2(1.6 * u, -0.3 * u), c + Vector2(1.6 * u, 0.3 * u), c + Vector2(1.1 * u, 0.3 * u)]), Color(0.85, 0.85, 0.9))
			m.fx.draw_colored_polygon(PackedVector2Array([c + Vector2(1.6 * u, -0.3 * u), c + Vector2(2.0 * u, 0.0), c + Vector2(1.6 * u, 0.3 * u)]), Color(0.9, 0.25, 0.2))
			m.fx.draw_rect(Rect2(c + Vector2(-0.5 * u, 0.35 * u), Vector2(0.4 * u, 0.7 * u)), dark)
			m.fx.draw_rect(Rect2(c + Vector2(-0.6 * u, -0.6 * u), Vector2(0.5 * u, 0.2 * u)), dark)

# Seitenansicht der kaufbaren Waffen, gezeichnet (keine Textur): Pistole, AK, Minigun, Raketenwerfer
func _shop_tile(p: Vector2, w: float, key: String, label: String) -> void:
	var h := 80.0
	# Kachel mit Verlauf: oben heller, unten dunkler
	m.fx.draw_rect(Rect2(p, Vector2(w, h)), Color(0.12, 0.14, 0.24, 0.95))
	m.fx.draw_rect(Rect2(p, Vector2(w, h * 0.45)), Color(0.2, 0.23, 0.36, 0.55))
	m.fx.draw_rect(Rect2(p, Vector2(w, h)), Color(0.5, 0.56, 0.78, 0.9), false, 1.5)
	var c := p + Vector2(w * 0.5, h * 0.4)
	var s := minf(w, h) * 0.26
	# Bodenschatten für den 3D-Effekt
	m.fx.draw_circle(c + Vector2(0, s * 1.05), s * 0.85, Color(0, 0, 0, 0.35))
	match key:
		"heal":
			# Medipack als kleine 3D-Kiste: weißer Körper, rote Kante, Kreuz
			var box := Rect2(c - Vector2(s, s), Vector2(2 * s, 2 * s))
			m.fx.draw_rect(Rect2(box.position + Vector2(0, s * 0.18), box.size), Color(0.7, 0.72, 0.8))
			m.fx.draw_rect(box, Color(1, 1, 1))
			m.fx.draw_rect(Rect2(box.position, Vector2(2 * s, s * 0.22)), Color(1, 0.95, 0.95))
			m.fx.draw_rect(Rect2(c - Vector2(s * 0.3, s * 0.85), Vector2(s * 0.6, s * 1.7)), Color(0.85, 0.1, 0.12))
			m.fx.draw_rect(Rect2(c - Vector2(s * 0.85, s * 0.3), Vector2(s * 1.7, s * 0.6)), Color(0.85, 0.1, 0.12))
			m.fx.draw_rect(Rect2(c - Vector2(s * 0.3, s * 0.85), Vector2(s * 0.25, s * 1.7)), Color(1, 0.35, 0.35, 0.8))
		"revive":
			# Rosa 3D-Herz: dunkle Unterlage, Körper, Glanz
			var hc := Color(1.0, 0.3, 0.55)
			var hd := Color(0.6, 0.1, 0.32)
			var hp := PackedVector2Array([c + Vector2(-s * 1.05, -s * 0.05), c + Vector2(s * 1.05, -s * 0.05), c + Vector2(0, s * 1.1)])
			var hp_dark := PackedVector2Array([c + Vector2(-s * 1.05, s * 0.2), c + Vector2(s * 1.05, s * 0.2), c + Vector2(0, s * 1.3)])
			m.fx.draw_circle(c + Vector2(-s * 0.5, -s * 0.2 + s * 0.2), s * 0.55, hd)
			m.fx.draw_circle(c + Vector2(s * 0.5, -s * 0.2 + s * 0.2), s * 0.55, hd)
			m.fx.draw_colored_polygon(hp_dark, hd)
			m.fx.draw_circle(c + Vector2(-s * 0.5, -s * 0.2), s * 0.55, hc)
			m.fx.draw_circle(c + Vector2(s * 0.5, -s * 0.2), s * 0.55, hc)
			m.fx.draw_colored_polygon(hp, hc)
			m.fx.draw_circle(c + Vector2(-s * 0.55, -s * 0.4), s * 0.2, Color(1, 1, 1, 0.9))
		"shield":
			# Blauer 3D-Schild: dunkle Kante, Körper, heller Innenteil, weißer Rand
			var sh := PackedVector2Array([c + Vector2(-s, -s * 0.9), c + Vector2(s, -s * 0.9), c + Vector2(s, s * 0.1), c + Vector2(0, s * 1.2), c + Vector2(-s, s * 0.1)])
			var sh_dark := PackedVector2Array([c + Vector2(-s, -s * 0.7), c + Vector2(s, -s * 0.7), c + Vector2(s, s * 0.3), c + Vector2(0, s * 1.4), c + Vector2(-s, s * 0.3)])
			m.fx.draw_colored_polygon(sh_dark, Color(0.1, 0.3, 0.65))
			m.fx.draw_colored_polygon(sh, Color(0.25, 0.65, 1.0))
			var sh_in := PackedVector2Array([c + Vector2(-s * 0.55, -s * 0.6), c + Vector2(s * 0.2, -s * 0.6), c + Vector2(s * 0.2, s * 0.2), c + Vector2(-s * 0.55, s * 0.2)])
			m.fx.draw_colored_polygon(sh_in, Color(0.6, 0.85, 1.0, 0.8))
			var sh_edge := sh.duplicate()
			sh_edge.append(sh[0])
			m.fx.draw_polyline(sh_edge, Color(1, 1, 1), 2.0)
		"nuke":
			# Atom-Kugel in 3D: dunkler Rand, gelber Körper, Glanz, drei schwarze Flügel
			m.fx.draw_circle(c, s, Color(0.7, 0.5, 0.05))
			m.fx.draw_circle(c + Vector2(-s * 0.1, -s * 0.12), s * 0.88, Color(1.0, 0.85, 0.2))
			m.fx.draw_circle(c + Vector2(-s * 0.35, -s * 0.4), s * 0.22, Color(1, 1, 0.8, 0.8))
			for a in 3:
				var ang := TAU * a / 3.0 - PI / 2.0
				m.fx.draw_circle(c + Vector2.from_angle(ang) * s * 0.45, s * 0.3, Color(0.15, 0.1, 0.0))
			m.fx.draw_circle(c, s * 0.2, Color(0.15, 0.1, 0.0))
		"pistol", "ak", "minigun", "rocket":
			_gun_icon(key, c, s)
		_:
			var tex: Texture2D = m.tex_guns.get(key, null)
			if tex:
				var ts := tex.get_size()
				var k2 := minf((w - 12.0) / ts.x, (h - 24.0) / ts.y)
				var sz := ts * k2
				m.fx.draw_texture_rect(tex, Rect2(p + Vector2(w, h) * 0.5 - sz * 0.5 - Vector2(0, 4), sz), false)
	# Preisschild: dunkle Leiste mit heller, gut lesbarer Schrift
	m.fx.draw_rect(Rect2(p.x + 2.0, p.y + h - 21.0, w - 4.0, 19.0), Color(0.06, 0.08, 0.16))
	m.fx.draw_rect(Rect2(p.x + 2.0, p.y + h - 21.0, w - 4.0, 19.0), Color(1, 0.85, 0.25), false, 1.5)
	# Passt der Name nicht ins Preisschild, läuft er als Laufschrift durch
	var fs := 16 if label.length() <= 4 else 13
	var room := maxi(1, int((w - 4.0) / (fs * 0.6)))
	if label.length() <= room:
		m._text(Vector2(p.x + 2.0, p.y + h - 20.0), label, fs, Color(1, 0.95, 0.6), w - 4.0, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		var full := label + "   "
		var start := int(Time.get_ticks_msec() / 180.0) % full.length()
		var win := (full + full).substr(start, room)
		m._text(Vector2(p.x + 2.0, p.y + h - 20.0), win, fs, Color(1, 0.95, 0.6), w - 4.0, HORIZONTAL_ALIGNMENT_LEFT)

func _coin_bar(center: Vector2, coins: int) -> void:
	var stages := [5, 10, 15]
	var goal := 15
	for s in stages:
		if coins < s:
			goal = s
			break
	var f: Font = ThemeDB.fallback_font
	var w := 56.0
	var fill := clampf(float(coins) / float(goal), 0.0, 1.0)
	var r := Rect2(center.x - w * 0.5, center.y, w, 5.0)
	m.fx.draw_rect(r, Color(0.05, 0.05, 0.1, 0.8))
	m.fx.draw_rect(Rect2(r.position, Vector2(w * fill, 5.0)), Color(1.0, 0.85, 0.25))
	m.fx.draw_string(f, Vector2(center.x - 60, center.y + 13.0), "%d/%d COINS" % [coins, goal], HORIZONTAL_ALIGNMENT_CENTER, 120, 10, Color(1, 0.9, 0.5))

# Start-Animation: Teamkarten mit Kämpferzahl, Modus-Titel und Countdown 3-2-1-FIGHT
func _draw_intro(vs: Vector2) -> void:
	if state != "round" or t >= INTRO_TIME:
		return
	var a := clampf(1.0 - maxf(0.0, t - (INTRO_TIME - 0.6)) / 0.6, 0.0, 1.0)
	m.fx.draw_rect(Rect2(Vector2.ZERO, vs), Color(0.04, 0.05, 0.12, 0.72 * a))
	var small := vs.x < 620.0
	m._text(Vector2(0, vs.y * 0.14), "LAST TEAM STANDING", 34 if small else 48, Color(1, 0.9, 0.4, a), vs.x, HORIZONTAL_ALIGNMENT_CENTER)
	m._text(Vector2(0, vs.y * 0.14 + 54), "Chat your team color to join", 18, Color(0.9, 0.95, 1.0, a), vs.x, HORIZONTAL_ALIGNMENT_CENTER)
	var cw := minf(200.0, (vs.x - 40.0) / 4.0 - 10.0)
	var x0 := vs.x * 0.5 - (cw + 10.0) * 2.0 + 5.0
	for k in 4:
		var alive := 0
		for i in SLOTS * 4:
			if m.bots[i]["alive"] and int(m.bots[i]["team"]) == k + 1:
				alive += 1
		var cx := x0 + k * (cw + 10.0)
		var cy := vs.y * 0.36
		var col: Color = TEAM_COLORS[k]
		m._pill(Rect2(cx, cy, cw, 150), Color(col.r * 0.4, col.g * 0.4, col.b * 0.4, 0.92 * a), 16)
		m._text(Vector2(cx, cy + 14), TEAM_NAMES[k], 26, Color(col.r, col.g, col.b, a), cw, HORIZONTAL_ALIGNMENT_CENTER)
		m._text(Vector2(cx, cy + 58), str(alive), 42, Color(1, 1, 1, a), cw, HORIZONTAL_ALIGNMENT_CENTER)
		m._text(Vector2(cx, cy + 118), "FIGHTERS", 14, Color(0.9, 0.95, 1.0, a), cw, HORIZONTAL_ALIGNMENT_CENTER)
	# Countdown in der Mitte: 3, 2, 1, dann FIGHT
	var label := str(3 - int(t)) if t < 3.0 else "FIGHT!"
	var size := 220 if t < 3.0 else (150 if small else 190)
	_big_text(vs, label, size, Color(1, 0.9, 0.4), 1.0)

func _big_text(vs: Vector2, t: String, size: int, col: Color, punch: float) -> void:
	var f: Font = m.ui_font()
	m.fx.draw_set_transform(vs * 0.5, 0.0, Vector2(punch, punch))
	var pos := Vector2(-vs.x * 0.5, size * 0.35)
	m.fx.draw_string_outline(f, pos, t, HORIZONTAL_ALIGNMENT_CENTER, vs.x, size, 18, Color(0.05, 0.02, 0.0, 0.95))
	m.fx.draw_string(f, pos, t, HORIZONTAL_ALIGNMENT_CENTER, vs.x, size, col)
	m.fx.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# Pixel-Pilz: grobe Blöcke, Farben flackern, verblasst am Ende der Sekunde
func _draw_pixel_mushroom(vs: Vector2, tp: float) -> void:
	var px := minf(vs.x, vs.y) / 36.0
	var ox := vs.x * 0.5 - px * 7.0
	var oy := vs.y * 0.30
	var alpha := clampf((NUKE_PIX - tp) * 6.0, 0.0, 1.0)
	var tick := int(tp * 30.0)
	for j in PIX_MUSH.size():
		var row: String = PIX_MUSH[j]
		for i in row.length():
			var ch := row[i]
			if ch == ".":
				continue
			var hsh := sin(float(i * 13 + j * 7 + tick * 5) * 12.9898) * 43758.5453
			var jit: float = hsh - floor(hsh)
			var col := Color(1.0, 0.45 + 0.3 * jit, 0.1 + 0.1 * jit)
			if ch == "O":
				col = Color(1.0, 0.92, 0.5)
			col.a = alpha
			m.fx.draw_rect(Rect2(ox + i * px, oy + j * px, px, px), col)

func _is_top(nm: String, k: int) -> bool:
	if k < 0 or k > 3 or not topsup[k].has(nm):
		return false
	for o in topsup[k]:
		if int(topsup[k][o]) > int(topsup[k][nm]):
			return false
	return true

func _draw_results(vs: Vector2) -> void:
	var pw := minf(vs.x - 40.0, 520.0)
	var px := vs.x * 0.5 - pw * 0.5
	var py := vs.y * 0.42
	m._pill(Rect2(px, py, pw, 290), Color(0.04, 0.05, 0.12, 0.88), 22)
	var wc: Color = TEAM_COLORS[maxi(0, winner)]
	m._text(Vector2(px, py + 44), "TEAM %s WINS!" % TEAM_NAMES[maxi(0, winner)], 34, wc, pw, HORIZONTAL_ALIGNMENT_CENTER)
	if streak >= 2:
		m._text(Vector2(px, py + 74), "Siegesserie: %d" % streak, 20, Color(1, 0.6, 0.2), pw, HORIZONTAL_ALIGNMENT_CENTER)
	m._text(Vector2(px, py + 108), "OVERALL SCORE", 18, Color(0.8, 0.9, 1.0), pw, HORIZONTAL_ALIGNMENT_CENTER)
	var order := [0, 1, 2, 3]
	order.sort_custom(func(a, b): return team_points[a] > team_points[b])
	for r in 4:
		var k: int = order[r]
		m._text(Vector2(px + 40, py + 144 + r * 30), "%d. %s" % [r + 1, TEAM_NAMES[k]], 22, TEAM_COLORS[k])
		m._text(Vector2(px + pw - 200, py + 144 + r * 30), "%d points · %d kills" % [team_points[k], round_kills[k]], 20, Color.WHITE, 170.0, HORIZONTAL_ALIGNMENT_RIGHT)
	m._text(Vector2(px, py + 278), "Next round: choose a team and join!", 16, Color(0.8, 0.9, 1.0), pw, HORIZONTAL_ALIGNMENT_CENTER)

# Pause-Anzeige: Countdown, Warteschlange mit Namen und Spielregeln (englisch, für Zuschauer)
const HOW_TO_PLAY := [
	"1. CHAT YOUR TEAM COLOR",
	"2. LIKES = MORE FIGHTERS",
	"3. GIFTS = WEAPONS",
	"4. LAST TEAM STANDING WINS",
]

func _draw_pause_info(vs: Vector2) -> void:
	var k := clampf(vs.x / 420.0, 0.9, 1.4)
	var pw := minf(vs.x - 20.0, 620.0)
	var px := vs.x * 0.5 - pw * 0.5
	var ph := 196.0 * k + HOW_TO_PLAY.size() * 26.0 * k
	var py := maxf(vs.y * 0.5 - ph * 0.5 + 40.0, 110.0)
	m._pill(Rect2(px - 3, py - 3, pw + 6, ph + 6), Color(0.75, 0.45, 1.0, 0.9), 24)
	m._pill(Rect2(px, py, pw, ph), Color(0.07, 0.04, 0.14, 0.95), 22)
	m._text(Vector2(px, py + 34 * k), "NEXT ROUND IN %d s" % int(ceil(pause_t)), int(30 * k), Color(1, 0.9, 0.5), pw, HORIZONTAL_ALIGNMENT_CENTER)
	m._text(Vector2(px, py + 74 * k), "Queue: %d" % queued, int(22 * k), Color(0.9, 0.95, 1.0), pw, HORIZONTAL_ALIGNMENT_CENTER)
	var shown: Array = []
	for i in mini(3, queue_names.size()):
		shown.append(str(queue_names[i]).substr(0, 10))
	var more := queue_names.size() - shown.size()
	var names_txt := ", ".join(shown)
	if more > 0:
		names_txt += "  +%d more" % more
	m._text(Vector2(px, py + 108 * k), names_txt, int(18 * k), Color(0.75, 0.85, 1.0), pw, HORIZONTAL_ALIGNMENT_CENTER)
	var y := py + 146.0 * k
	for line in HOW_TO_PLAY:
		m._text(Vector2(px + 14, y), line, int(18 * k), Color(1, 0.97, 0.85), pw - 28.0, HORIZONTAL_ALIGNMENT_CENTER)
		y += 26.0 * k

# Kugel-Balken über dem Knochen-Krieger: jeder Treffer fliegt als Kugel in den nächsten Platz
func _draw_bullet(p: Vector2, w: float, h: float, col: Color) -> void:
	m.fx.draw_rect(Rect2(p, Vector2(w, h * 0.7)), col)
	m.fx.draw_colored_polygon(PackedVector2Array([p + Vector2(0, h * 0.7), p + Vector2(w, h * 0.7), p + Vector2(w * 0.5, h)]), col)

func _draw_bullet_bar(sp: Vector2, filled: int, nb: int, z: Dictionary) -> void:
	var w: float = 9.0 * m.ZOOM
	var h: float = 16.0 * m.ZOOM
	var gap: float = 3.0 * m.ZOOM
	var total: float = nb * w + (nb - 1) * gap
	var x0 := sp.x - total * 0.5
	var y: float = sp.y - 58.0 * m.ZOOM
	var age := clampf(float(Time.get_ticks_msec() - int(z.get("fill_t", 0))) / 350.0, 0.0, 1.0)
	for i in nb:
		var slot := Vector2(x0 + i * (w + gap), y)
		if i < filled and i == filled - 1 and age < 1.0:
			# frisch getroffen: die Kugel fliegt von oben in ihren Platz
			var from: Vector2 = slot + Vector2(0, -40.0 * m.ZOOM)
			_draw_bullet(from.lerp(slot, age), w, h, Color(1.0, 0.95, 0.5))
		elif i < filled:
			_draw_bullet(slot, w, h, Color(1.0, 0.8, 0.25))
		else:
			_draw_bullet(slot, w, h, Color(0.25, 0.25, 0.3, 0.9))
