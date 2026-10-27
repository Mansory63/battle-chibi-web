extends Control
# Hub-Menü (Kopfleiste, Seitenbuttons, Tab-Leiste, Shop, Skins, Aufgaben, Mehr).
# Läuft in der 1280x720-Bühne des Hauptmenüs. Originales Design, keine fremden Assets.

const NAVY := Color(0.07, 0.1, 0.22, 0.92)
const NAVY2 := Color(0.12, 0.17, 0.34, 0.96)
const GOLD := Color(1.0, 0.82, 0.2)
const INK := Color(0.1, 0.07, 0.12)
const MISSIONS := [
	["Play 3 rounds", 3, 60, 0],
	["Eliminate 5 enemies", 5, 80, 0],
	["Reach the top 10", 1, 0, 5],
]
const SHOP := [
	["shield", "Starting shield", "Start with 50 shield", 50],
	["pistol", "Starter pistol", "Start with pistol + ammo", 40],
	["xp", "Double XP", "Double XP for 1 round", 80],
]
const TABS := ["SHOP", "SKINS", "BATTLE", "TASKS", "MORE"]

class Ico extends Control:
	var kind := "coin"
	var col := Color.WHITE
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5
		match kind:
			"coin":
				draw_circle(c, r, INK)
				draw_circle(c, r * 0.82, Color(1, 0.8, 0.15))
				draw_circle(c, r * 0.55, Color(1, 0.92, 0.5))
				draw_circle(c, r * 0.36, Color(1, 0.78, 0.12))
			"gem":
				var p := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, -r * 0.2), c + Vector2(0, r), c + Vector2(-r, -r * 0.2)])
				draw_colored_polygon(p, Color(0.35, 0.85, 1.0))
				draw_polyline(PackedVector2Array([p[0], p[1], p[2], p[3], p[0]]), INK, 3.0)
				draw_line(c + Vector2(-r, -r * 0.2), c + Vector2(r, -r * 0.2), INK, 2.0)
			"trophy":
				draw_rect(Rect2(c.x - r * 0.55, c.y - r * 0.8, r * 1.1, r * 0.9), col)
				draw_circle(c + Vector2(0, r * 0.1), r * 0.55, col)
				draw_rect(Rect2(c.x - r * 0.12, c.y + r * 0.4, r * 0.24, r * 0.3), col)
				draw_rect(Rect2(c.x - r * 0.45, c.y + r * 0.65, r * 0.9, r * 0.2), col)
			"list":
				for i in 3:
					draw_rect(Rect2(c.x - r * 0.7, c.y - r * 0.6 + i * r * 0.55, r * 0.25, r * 0.25), col)
					draw_rect(Rect2(c.x - r * 0.3, c.y - r * 0.6 + i * r * 0.55, r * 1.0, r * 0.25), col)
			"star":
				var pts := PackedVector2Array()
				for i in 10:
					var a := -PI / 2.0 + i * PI / 5.0
					pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
				draw_colored_polygon(pts, col)
			"team":
				for i in 3:
					var o := (i - 1) * r * 0.55
					draw_circle(c + Vector2(o, -r * 0.25 + (0 if i == 1 else r * 0.12)), r * 0.28, col)
					draw_rect(Rect2(c.x + o - r * 0.26, c.y + r * 0.1 + (0 if i == 1 else r * 0.12), r * 0.52, r * 0.5), col)
			"map":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r * 0.6), c + Vector2(-r * 0.33, -r * 0.8), c + Vector2(r * 0.33, -r * 0.6), c + Vector2(r, -r * 0.8), c + Vector2(r, r * 0.6), c + Vector2(r * 0.33, r * 0.8), c + Vector2(-r * 0.33, r * 0.6), c + Vector2(-r, r * 0.8)]), col)
				draw_line(c + Vector2(-r * 0.33, -r * 0.8), c + Vector2(-r * 0.33, r * 0.6), INK, 2.0)
				draw_line(c + Vector2(r * 0.33, -r * 0.6), c + Vector2(r * 0.33, r * 0.8), INK, 2.0)
			"mode":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.8, -r * 0.4), c + Vector2(r * 0.55, r * 0.5), c + Vector2(0, r), c + Vector2(-r * 0.55, r * 0.5), c + Vector2(-r * 0.8, -r * 0.4)]), col)
				draw_line(c + Vector2(0, -r * 0.5), c + Vector2(0, r * 0.5), INK, 3.0)
				draw_line(c + Vector2(-r * 0.4, 0), c + Vector2(r * 0.4, 0), INK, 3.0)
			"sound":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r, -r * 0.3), c + Vector2(-r * 0.4, -r * 0.3), c + Vector2(r * 0.1, -r * 0.8), c + Vector2(r * 0.1, r * 0.8), c + Vector2(-r * 0.4, r * 0.3), c + Vector2(-r, r * 0.3)]), col)
				if col.a > 0.9 and col != Color(0.6, 0.6, 0.65):
					draw_arc(c + Vector2(r * 0.1, 0), r * 0.55, -0.9, 0.9, 12, col, 3.0)
					draw_arc(c + Vector2(r * 0.1, 0), r * 0.95, -0.9, 0.9, 12, col, 3.0)
				else:
					draw_line(c + Vector2(r * 0.3, -r * 0.5), c + Vector2(r, r * 0.5), Color(1, 0.4, 0.4), 4.0)
					draw_line(c + Vector2(r, -r * 0.5), c + Vector2(r * 0.3, r * 0.5), Color(1, 0.4, 0.4), 4.0)
			"lock":
				draw_rect(Rect2(c.x - r * 0.6, c.y - r * 0.1, r * 1.2, r * 0.9), col)
				draw_arc(c + Vector2(0, -r * 0.1), r * 0.4, PI, TAU, 12, col, 4.0)
			"shield":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.7), c + Vector2(r * 0.8, -r * 0.7), c + Vector2(r * 0.7, r * 0.2), c + Vector2(0, r), c + Vector2(-r * 0.7, r * 0.2)]), Color(0.3, 0.6, 1.0))
			"gun":
				draw_rect(Rect2(c.x - r, c.y - r * 0.3, r * 1.6, r * 0.5), Color(0.55, 0.55, 0.62))
				draw_rect(Rect2(c.x - r * 0.4, c.y, r * 0.5, r * 0.9), Color(0.45, 0.3, 0.2))
			"xp":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 0.2, -r), c + Vector2(r * 0.6, -r * 0.1), c + Vector2(r * 0.05, -r * 0.1), c + Vector2(r * 0.3, r), c + Vector2(-r * 0.6, r * 0.1), c + Vector2(-r * 0.05, r * 0.1)]), GOLD)

var m
var tab := 2
var bat: Control
var pan: Control
var tabbtns: Array[Button] = []
var lvl_lbl: Label
var avatar: TextureRect
var xp_ratio := 0.0
var xp_bar: Control
var coin_lbl: Label
var gem_lbl: Label
var win_lbl: Label
var plate_lbl: Label
var plate_sub: Label
var sub_lbl: Label
var side_icons: Dictionary = {}

func setup(main, stage: Control) -> void:
	m = main
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(self)
	_build_top()
	bat = Control.new()
	bat.set_anchors_preset(Control.PRESET_FULL_RECT)
	bat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bat)
	_build_battle()
	pan = Control.new()
	pan.position = Vector2(40, 100)
	pan.size = Vector2(1200, 540)
	add_child(pan)
	_build_tabbar()
	set_tab(2)

# ---------- Bausteine ----------
func _sb(col: Color, radius := 16, border := 4, bcol := INK) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border)
	sb.border_color = bcol
	return sb

func _lbl(parent: Control, t: String, pos: Vector2, sz: Vector2, fs: int, col := Color.WHITE, al := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = sz
	l.horizontal_alignment = al
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", maxi(3, fs / 5))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _box(parent: Control, pos: Vector2, sz: Vector2, col: Color, radius := 16, border := 4, bcol := INK) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = sz
	p.add_theme_stylebox_override("panel", _sb(col, radius, border, bcol))
	parent.add_child(p)
	return p

func _button(parent: Control, text: String, pos: Vector2, sz: Vector2, col: Color, fs := 24, fcol := Color.WHITE) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	b.custom_minimum_size = sz
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_color_override("font_color", fcol)
	b.add_theme_color_override("font_hover_color", fcol)
	b.add_theme_color_override("font_pressed_color", fcol)
	b.add_theme_color_override("font_outline_color", INK)
	b.add_theme_constant_override("outline_size", maxi(3, fs / 5))
	b.add_theme_stylebox_override("normal", _sb(col))
	b.add_theme_stylebox_override("hover", _sb(col.lightened(0.15)))
	b.add_theme_stylebox_override("pressed", _sb(col.darkened(0.15)))
	b.add_theme_stylebox_override("disabled", _sb(col.darkened(0.35)))
	parent.add_child(b)
	return b

func _ico(parent: Control, kind: String, pos: Vector2, sz: Vector2, col := Color.WHITE) -> Ico:
	var i := Ico.new()
	i.kind = kind
	i.col = col
	i.position = pos
	i.size = sz
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(i)
	return i

func _pill(parent: Control, kind: String, x: float, w: float) -> Label:
	_box(parent, Vector2(x, 20), Vector2(w, 44), NAVY, 22, 3)
	_ico(parent, kind, Vector2(x + 6, 26), Vector2(32, 32), GOLD)
	return _lbl(parent, "0", Vector2(x + 44, 20), Vector2(w - 52, 44), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)

# ---------- Kopfleiste ----------
func _build_top() -> void:
	_box(self, Vector2(0, 0), Vector2(1280, 84), Color(0.04, 0.06, 0.15, 0.78), 0, 0)
	var ring := _box(self, Vector2(16, 10), Vector2(68, 68), Color(0.2, 0.3, 0.55), 34, 5, GOLD)
	avatar = TextureRect.new()
	avatar.position = Vector2(4, 4)
	avatar.size = Vector2(60, 60)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.add_child(avatar)
	ring.clip_contents = true
	_box(self, Vector2(60, 52), Vector2(38, 28), GOLD, 10, 3)
	lvl_lbl = _lbl(self, "1", Vector2(60, 52), Vector2(38, 28), 20, INK)
	lvl_lbl.add_theme_constant_override("outline_size", 0)
	_lbl(self, "PLAYER", Vector2(108, 8), Vector2(200, 32), 24)
	xp_bar = Control.new()
	xp_bar.position = Vector2(108, 46)
	xp_bar.size = Vector2(190, 18)
	xp_bar.draw.connect(func():
		xp_bar.draw_rect(Rect2(0, 0, 190, 18), INK)
		xp_bar.draw_rect(Rect2(3, 3, 184, 12), Color(0.15, 0.18, 0.32))
		xp_bar.draw_rect(Rect2(3, 3, 184.0 * xp_ratio, 12), Color(0.35, 0.85, 0.45))
		xp_bar.draw_rect(Rect2(3, 3, 184.0 * xp_ratio, 4), Color(1, 1, 1, 0.25)))
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(xp_bar)
	coin_lbl = _pill(self, "coin", 760, 160)
	gem_lbl = _pill(self, "gem", 930, 130)
	win_lbl = _pill(self, "trophy", 1070, 130)
	# Titel (wird im Endbildschirm für Ergebnis genutzt)
	m.menu_title = _lbl(self, "BATTLEYAROO", Vector2(310, 6), Vector2(440, 72), 46, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	m.menu_title.add_theme_constant_override("outline_size", 10)

# ---------- Kampf-Tab ----------
func _side(parent: Control, kind: String, caption: String, pos: Vector2, col: Color) -> Button:
	var b := _button(parent, "", pos, Vector2(150, 88), col, 18)
	_ico(b, kind, Vector2(10, 18), Vector2(42, 42), Color.WHITE)
	var l := _lbl(b, caption, Vector2(54, 4), Vector2(94, 80), 16)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.set_meta("lbl", l)
	return b

func _build_battle() -> void:
	# Linke Spalte
	var b1 := _side(bat, "list", "TASKS", Vector2(20, 130), Color(0.85, 0.5, 0.2))
	b1.pressed.connect(func(): set_tab(3))
	var b2 := _side(bat, "star", "SEASON PASS", Vector2(20, 236), Color(0.55, 0.4, 0.8))
	b2.pressed.connect(func(): set_tab(4))
	var b3 := _side(bat, "shield", "SKINS", Vector2(20, 342), Color(0.25, 0.55, 0.85))
	b3.pressed.connect(func(): set_tab(1))
	var b4 := _side(bat, "mode", "LIVE MODE", Vector2(20, 448), Color(0.9, 0.25, 0.5))
	b4.pressed.connect(func(): m.start_live({}))
	# Rechte Spalte
	m.team_btn = _side(bat, "team", "", Vector2(1110, 130), Color(0.2, 0.55, 0.75))
	m.team_btn.pressed.connect(func():
		m.team_size = m.team_size % 4 + 1
		m._write_save()
		m._update_menu_buttons())
	m.map_btn = _side(bat, "map", "", Vector2(1110, 236), Color(0.3, 0.6, 0.4))
	m.map_btn.pressed.connect(func():
		m.map_theme = (m.map_theme + 1) % 3
		m._write_save()
		m._update_menu_buttons())
	m.mode_btn = _side(bat, "mode", "", Vector2(1110, 342), Color(0.85, 0.35, 0.3))
	m.mode_btn.pressed.connect(func():
		m.hardcore = not m.hardcore
		m._write_save()
		m._update_menu_buttons())
	m.sound_btn = _side(bat, "sound", "", Vector2(1110, 448), Color(0.3, 0.3, 0.45))
	m.sound_btn.pressed.connect(m._toggle_sound)
	side_icons["sound"] = m.sound_btn.get_child(0)
	# Heldenplatte (Name + Stufe), Held selbst kommt aus der 3D-Ebene
	_box(bat, Vector2(500, 478), Vector2(280, 54), NAVY, 14, 3)
	plate_lbl = _lbl(bat, "Astronaut", Vector2(500, 478), Vector2(280, 30), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	plate_sub = _lbl(bat, "", Vector2(500, 506), Vector2(280, 24), 16, Color(0.7, 0.85, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
	# Spielen
	m.menu_play = _button(bat, "PLAY", Vector2(450, 548), Vector2(380, 80), Color(1.0, 0.75, 0.1), 46, INK)
	m.menu_play.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.7, 0.8))
	m.menu_play.pressed.connect(m._on_menu_play)
	sub_lbl = _lbl(bat, "", Vector2(450, 628), Vector2(380, 24), 16, Color(0.85, 0.92, 1.0), HORIZONTAL_ALIGNMENT_CENTER)

func _build_tabbar() -> void:
	_box(self, Vector2(0, 656), Vector2(1280, 64), Color(0.04, 0.06, 0.15, 0.92), 0, 0)
	for i in TABS.size():
		var b := _button(self, TABS[i], Vector2(12 + i * 252, 662), Vector2(244, 54), Color(0.2, 0.26, 0.45), 22)
		var idx := i
		b.pressed.connect(func(): set_tab(idx))
		tabbtns.append(b)

func set_tab(t: int) -> void:
	tab = t
	m.hub_tab = t
	for i in tabbtns.size():
		var on := i == t
		var col := Color(1.0, 0.75, 0.1) if on else Color(0.2, 0.26, 0.45)
		tabbtns[i].add_theme_stylebox_override("normal", _sb(col))
		tabbtns[i].add_theme_stylebox_override("hover", _sb(col.lightened(0.12)))
		tabbtns[i].add_theme_color_override("font_color", INK if on else Color.WHITE)
		tabbtns[i].add_theme_color_override("font_hover_color", INK if on else Color.WHITE)
		tabbtns[i].add_theme_color_override("font_outline_color", Color(1, 0.95, 0.7, 0.8) if on else INK)
	bat.visible = t == 2
	m.menu_title.visible = true
	pan.visible = t != 2
	refresh()

# ---------- Aktualisieren ----------
func refresh() -> void:
	if m == null:
		return
	var h: Dictionary = m.hub_data
	var lvl: int = m._level()
	lvl_lbl.text = str(lvl)
	xp_ratio = 1.0 if lvl >= m.MAX_LEVEL else float(m.save_xp % m.XP_PER_LEVEL) / float(m.XP_PER_LEVEL)
	xp_bar.queue_redraw()
	coin_lbl.text = str(int(h["coins"]))
	gem_lbl.text = str(int(h["gems"]))
	win_lbl.text = str(int(h["wins"]))
	avatar.texture = m._load_tex(m.ART + "portrait_" + m.save_skin + ".png")
	plate_lbl.text = m._skin_name()
	plate_sub.text = "Level %d" % lvl
	sub_lbl.text = "%s · %s · %s" % [["SOLO", "DUO", "TRIO", "QUAD"][m.team_size - 1], ["Meadow", "Desert", "Snow", "Dark"][m.map_theme], "Hardcore" if m.hardcore else "Normal"]
	if side_icons.has("sound"):
		var ic: Ico = side_icons["sound"]
		ic.col = Color(0.6, 0.6, 0.65) if m.muted else Color.WHITE
		ic.queue_redraw()
	for c in pan.get_children():
		c.queue_free()
	match tab:
		0:
			_build_shop()
		1:
			_build_skins()
		3:
			_build_missions()
		4:
			_build_more()

func _panel_base(title: String) -> void:
	_box(pan, Vector2.ZERO, pan.size, NAVY, 22, 5)
	_lbl(pan, title, Vector2(24, 10), Vector2(600, 52), 34, GOLD)

# ---------- Skins ----------
func _rarity(lv: int) -> Color:
	if lv <= 1:
		return Color(0.55, 0.62, 0.72)
	if lv <= 4:
		return Color(0.35, 0.78, 0.4)
	if lv <= 8:
		return Color(0.3, 0.6, 1.0)
	if lv <= 13:
		return Color(0.7, 0.4, 0.95)
	return Color(1.0, 0.6, 0.15)

func _build_skins() -> void:
	_panel_base("SKINS")
	var lvl: int = m._level()
	for i in m.SKINS.size():
		var e: Array = m.SKINS[i]
		var col: Color = _rarity(e[0])
		var x: int = 24 + (i % 4) * 290
		var y: int = 76 + (i / 4) * 230
		var unlocked: bool = lvl >= e[0]
		var sel: bool = m.save_skin == e[1]
		var card := _box(pan, Vector2(x, y), Vector2(270, 212), col.darkened(0.55), 18, 6, GOLD if sel else col)
		var tr := TextureRect.new()
		tr.texture = m._load_tex(m.ART + "portrait_" + e[1] + ".png")
		tr.position = Vector2(65, 6)
		tr.size = Vector2(140, 136)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked:
			tr.modulate = Color(0.25, 0.25, 0.3, 0.9)
		card.add_child(tr)
		_box(card, Vector2(0, 142), Vector2(270, 70), Color(0.03, 0.04, 0.1, 0.8), 14, 0).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lbl(card, e[2], Vector2(0, 148), Vector2(270, 32), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		if unlocked:
			_lbl(card, "EQUIPPED" if sel else "TAP TO EQUIP", Vector2(0, 178), Vector2(270, 26), 15, GOLD if sel else Color(0.8, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER)
			var btn := Button.new()
			btn.flat = true
			btn.set_anchors_preset(Control.PRESET_FULL_RECT)
			btn.focus_mode = Control.FOCUS_NONE
			var skin_id: String = e[1]
			btn.pressed.connect(func():
				m.save_skin = skin_id
				m._apply_skin()
				m._write_save()
				m._update_menu_buttons()
				refresh())
			card.add_child(btn)
		else:
			_ico(card, "lock", Vector2(106, 50), Vector2(58, 58), Color(0.85, 0.85, 0.9))
			_lbl(card, "Level %d" % e[0], Vector2(0, 178), Vector2(270, 26), 18, Color(1, 0.85, 0.5), HORIZONTAL_ALIGNMENT_CENTER)

# ---------- Shop ----------
func _build_shop() -> void:
	_panel_base("SHOP")
	_lbl(pan, "Purchased items apply to your next round.", Vector2(24, 62), Vector2(800, 30), 18, Color(0.8, 0.9, 1.0))
	var h: Dictionary = m.hub_data
	for i in SHOP.size():
		var it: Array = SHOP[i]
		var x := 24 + i * 390
		var card := _box(pan, Vector2(x, 110), Vector2(370, 380), NAVY2, 18, 5, Color(0.4, 0.55, 0.9))
		var ic := _ico(card, "gun" if it[0] == "pistol" else it[0], Vector2(135, 30), Vector2(100, 100))
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lbl(card, it[1], Vector2(0, 150), Vector2(370, 40), 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		_lbl(card, it[2], Vector2(10, 192), Vector2(350, 56), 18, Color(0.8, 0.9, 1.0), HORIZONTAL_ALIGNMENT_CENTER).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var have := int(h["inv"].get(it[0], 0))
		_lbl(card, "Im Besitz: %d" % have, Vector2(0, 252), Vector2(370, 30), 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER)
		var can: bool = int(h["coins"]) >= int(it[3])
		var b := _button(card, "   %d" % it[3], Vector2(60, 300), Vector2(250, 60), Color(0.3, 0.75, 0.4) if can else Color(0.4, 0.4, 0.5), 28)
		_ico(b, "coin", Vector2(24, 14), Vector2(32, 32))
		var key: String = it[0]
		var cost: int = it[3]
		b.pressed.connect(func():
			if int(m.hub_data["coins"]) >= cost:
				m.hub_data["coins"] = int(m.hub_data["coins"]) - cost
				m.hub_data["inv"][key] = int(m.hub_data["inv"].get(key, 0)) + 1
				m._write_save()
				m._play_sfx("pickup")
				refresh())

# ---------- Aufgaben ----------
func _build_missions() -> void:
	_panel_base("DAILY TASKS")
	_lbl(pan, "New tasks every day.", Vector2(24, 62), Vector2(600, 30), 18, Color(0.8, 0.9, 1.0))
	var h: Dictionary = m.hub_data
	for i in MISSIONS.size():
		var ms: Array = MISSIONS[i]
		var y := 110 + i * 136
		var row := _box(pan, Vector2(24, y), Vector2(1152, 120), NAVY2, 18, 4, Color(0.4, 0.55, 0.9))
		var prog := mini(int(h["mprog"][i]), int(ms[1]))
		var done: bool = prog >= int(ms[1])
		var claimed: bool = bool(h["mclaim"][i])
		_lbl(row, ms[0], Vector2(24, 12), Vector2(600, 40), 28)
		var bar := Control.new()
		bar.position = Vector2(24, 70)
		bar.size = Vector2(600, 30)
		var ratio := float(prog) / float(ms[1])
		bar.draw.connect(func():
			bar.draw_rect(Rect2(0, 0, 600, 30), INK)
			bar.draw_rect(Rect2(4, 4, 592, 22), Color(0.15, 0.18, 0.32))
			bar.draw_rect(Rect2(4, 4, 592.0 * ratio, 22), Color(0.35, 0.85, 0.45) if done else Color(0.95, 0.7, 0.2)))
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(bar)
		_lbl(row, "%d / %d" % [prog, ms[1]], Vector2(640, 68), Vector2(120, 34), 22)
		var rtxt := ("%d coins" % ms[2]) if int(ms[2]) > 0 else ("%d gems" % ms[3])
		_ico(row, "coin" if int(ms[2]) > 0 else "gem", Vector2(770, 16), Vector2(36, 36))
		_lbl(row, rtxt, Vector2(812, 12), Vector2(150, 44), 20, GOLD)
		var bt := "CLAIMED" if claimed else ("CLAIM" if done else "OPEN")
		var b := _button(row, bt, Vector2(960, 40), Vector2(180, 52), Color(0.3, 0.75, 0.4) if (done and not claimed) else Color(0.4, 0.4, 0.5), 24)
		b.disabled = not done or claimed
		var idx := i
		b.pressed.connect(func():
			m.hub_data["mclaim"][idx] = true
			m.hub_data["coins"] = int(m.hub_data["coins"]) + int(MISSIONS[idx][2])
			m.hub_data["gems"] = int(m.hub_data["gems"]) + int(MISSIONS[idx][3])
			m._write_save()
			m._play_sfx("pickup")
			refresh())

# ---------- Mehr ----------
func _build_more() -> void:
	_panel_base("MORE")
	var h: Dictionary = m.hub_data
	var rec := "RECORDS\n\nRounds played: %d\nWins: %d\nBest placement: %s\nMost kills: %d" % [int(h["matches"]), int(h["wins"]), ("#%d" % int(h["best_place"])) if int(h["best_place"]) > 0 else "–", int(h["best_kills"])]
	var l1 := _lbl(pan, rec, Vector2(30, 70), Vector2(360, 300), 22, Color.WHITE)
	l1.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var ctl := "CONTROLS\n\nLeft joystick: move\nHOLD FIRE: shoot, drag thumb: aim\nLightning: jump / dash\nII top: pause\nPC: WASD, mouse, space, shift\nBlue = shield, Red = jump,\nYellow = power, Green = speed"
	var l2 := _lbl(pan, ctl, Vector2(420, 70), Vector2(380, 440), 20, Color.WHITE)
	l2.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m._update_pass_label()
	var ptxt: String = m.pass_label.text
	var l3 := _lbl(pan, ptxt, Vector2(830, 70), Vector2(350, 460), 17, Color.WHITE)
	l3.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
