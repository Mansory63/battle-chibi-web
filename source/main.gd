extends Node2D

# BattleChibi – Demo-Prototyp v4 (Draufsicht)
# Steuerung: WASD/Pfeile = bewegen, Maus = zielen (Waffe dreht sich),
#            Leertaste oder linke Maustaste = schießen (halten), Shift = Dash,
#            E = Haus betreten/verlassen, R = neustart

# ---------- Konstanten ----------
const MAP_SIZE := Vector2(2400, 1800)
const PLAYER_RADIUS := 22.0
const BOT_RADIUS := 22.0
const BOT_COUNT := 14
const LOOT_COUNT := 45
const CHEST_COUNT := 16
const BASE_SPEED := 260.0
const BOT_SPEED := 150.0
const BOARD_SPEED_MULT := 1.6
const BOARD_DURATION := 8.0
const DASH_DISTANCE := 160.0
const MAX_DASH_CHARGES := 3
const FALL_TIME := 4.0
const FALL_SPEED := 180.0
const BULLET_LIFE := 1.0
const TREE_RADIUS := 26.0
const ZONE_CENTER := Vector2(1200, 900)
const ZONE_START_RADIUS := 1300.0
const ZONE_END_RADIUS := 150.0
const ZONE_SHRINK_TIME := 180.0
const ZONE_DAMAGE_PER_SEC := 0.5
const PICKUP_RANGE := 34.0
const DOOR_RANGE := 45.0
const ROOM_SIZE := Vector2(700, 500)
const ROOM_DOOR := Vector2(350, 470)
const ROOM_LOOT_COUNT := 3
const ART := "res://assets/art/"
# Gekippte Kamera: Welt wird gedreht und vertikal gestaucht (Schrägansicht)
const VIEW_ANGLE := 0.55
const VIEW_TILT := 0.72
const HOUSE_H := 74.0
const ROADS := [Rect2(0, 820, 2400, 160), Rect2(500, 0, 160, 1800), Rect2(1700, 0, 160, 1800)]
const TouchControlsScript := preload("res://touch_controls.gd")

const OUTLINE := Color(0.15, 0.1, 0.1)
const SKIN := Color(1, 0.86, 0.72)
const HAIR := Color(0.35, 0.2, 0.1)
const WALL_COLOR := Color(0.92, 0.85, 0.72)
const WALL_EDGE := Color(0.45, 0.35, 0.28)

const WEAPONS := {
	"pistol": {"name": "Pistole", "damage": 20.0, "cooldown": 0.45, "speed": 700.0, "ammo": 15, "spread": 0.0, "pellets": 1},
	"smg": {"name": "Uzi", "damage": 8.0, "cooldown": 0.07, "speed": 750.0, "ammo": 120, "spread": 0.12, "pellets": 1},
	"ak": {"name": "AK", "damage": 15.0, "cooldown": 0.15, "speed": 900.0, "ammo": 60, "spread": 0.05, "pellets": 1},
	"minigun": {"name": "Minigun", "damage": 7.0, "cooldown": 0.05, "speed": 820.0, "ammo": 200, "spread": 0.14, "pellets": 1},
	"shotgun": {"name": "Pumpgun", "damage": 12.0, "cooldown": 0.9, "speed": 620.0, "ammo": 10, "spread": 0.28, "pellets": 6},
	"sniper": {"name": "Scharfschützengewehr", "damage": 65.0, "cooldown": 1.3, "speed": 1200.0, "ammo": 5, "spread": 0.0, "pellets": 1},
	"rocket": {"name": "Raketenwerfer", "damage": 60.0, "cooldown": 1.6, "speed": 480.0, "ammo": 3, "spread": 0.0, "pellets": 1, "explode": 95.0},
	"revolver": {"name": "Revolver", "damage": 34.0, "cooldown": 0.62, "speed": 850.0, "ammo": 6, "spread": 0.02, "pellets": 1},
	"crossbow": {"name": "Armbrust", "damage": 52.0, "cooldown": 1.05, "speed": 1050.0, "ammo": 6, "spread": 0.0, "pellets": 1},
	"laser": {"name": "Laserkanone", "damage": 11.0, "cooldown": 0.085, "speed": 1500.0, "ammo": 160, "spread": 0.025, "pellets": 1},
	"bot": {"name": "Bot", "damage": 5.0, "cooldown": 1.0, "speed": 600.0, "ammo": 999, "spread": 0.18, "pellets": 1},
}
const LOOT_NAMES := {
	"heal": "Medipack klein", "heal_big": "Medipack groß", "shield_big": "Schild groß", "pistol": "Pistole", "smg": "Uzi", "ak": "AK", "minigun": "Minigun",
	"shotgun": "Pumpgun", "sniper": "Scharfschützengewehr", "rocket": "Raketenwerfer",
	"shield": "Schild klein", "jump": "Sprung", "power": "Power", "speed": "Speed",
	"board": "Skateboard", "dash": "Dash",
	"bat": "Baseballschläger", "pan": "Pfanne", "extinguisher": "Feuerlöscher", "chest": "Kiste",
	"revolver": "Revolver", "crossbow": "Armbrust", "laser": "Laserkanone", "katana": "Katana", "hammer": "Vorschlaghammer",
}
const LOOT_COLORS := {
	"heal": Color(1, 0.3, 0.4), "heal_big": Color(1, 0.3, 0.4), "shield_big": Color(0.3, 0.6, 1.0), "pistol": Color(0.35, 0.35, 0.4), "smg": Color(0.4, 0.8, 0.3),
	"ak": Color(0.75, 0.5, 0.25), "minigun": Color(0.9, 0.35, 0.25), "shotgun": Color(0.75, 0.45, 0.25),
	"sniper": Color(0.3, 0.55, 0.9), "rocket": Color(0.4, 0.6, 0.4),
	"shield": Color(0.3, 0.6, 1.0), "jump": Color(0.95, 0.3, 0.3), "power": Color(1.0, 0.85, 0.2), "speed": Color(0.35, 0.85, 0.35),
	"board": Color(0.6, 0.3, 0.9), "dash": Color(0.2, 0.9, 0.9),
	"bat": Color(0.8, 0.8, 0.8), "pan": Color(0.8, 0.8, 0.8), "extinguisher": Color(0.8, 0.8, 0.8), "chest": Color(1, 1, 1),
	"revolver": Color(0.6, 0.6, 0.65), "crossbow": Color(0.7, 0.5, 0.3), "laser": Color(0.3, 0.95, 0.95), "katana": Color(0.85, 0.9, 1.0), "hammer": Color(0.8, 0.6, 0.3),
}
# Bodenloot: wenig, vor allem Heilung, Nahkampf und einfache Waffen. Die guten Sachen sind in Kisten.
const LOOT_WEIGHTED := ["heal", "heal", "heal", "shield", "shield", "bat", "pan", "extinguisher", "bat", "pistol", "pistol", "smg", "shotgun", "jump", "power", "speed", "revolver", "katana", "hammer"]
const RARITY_NAMES := ["Gewöhnlich", "Selten", "Episch", "Legendär"]
const RARITY_COLORS := [Color(0.35, 0.85, 0.4), Color(0.3, 0.6, 1.0), Color(0.7, 0.4, 1.0), Color(1.0, 0.78, 0.15)]
const RARITY_MULT := [1.0, 1.15, 1.3, 1.5]
const CHEST_WEAPONS := [["pistol", "smg", "shotgun", "revolver"], ["smg", "shotgun", "ak", "revolver", "crossbow"], ["ak", "shotgun", "sniper", "minigun", "crossbow", "laser"], ["minigun", "rocket", "sniper", "ak", "laser"]]
const MELEE := {
	"fist": {"name": "Fäuste", "damage": 10.0, "cooldown": 0.45, "range": 58.0},
	"bat": {"name": "Baseballschläger", "damage": 24.0, "cooldown": 0.6, "range": 72.0},
	"pan": {"name": "Pfanne", "damage": 20.0, "cooldown": 0.5, "range": 64.0},
	"extinguisher": {"name": "Feuerlöscher", "damage": 15.0, "cooldown": 0.32, "range": 68.0},
	"katana": {"name": "Katana", "damage": 30.0, "cooldown": 0.5, "range": 80.0},
	"hammer": {"name": "Vorschlaghammer", "damage": 45.0, "cooldown": 0.95, "range": 70.0},
}
const ROOM_FURNITURE := [
	Rect2(60, 60, 150, 80),    # Bett
	Rect2(490, 60, 150, 70),   # Schrank
	Rect2(270, 230, 160, 70),  # Tisch
]

# ---------- Welt ----------
var obstacles: Array[Rect2] = [
	Rect2(80, 120, 180, 130), Rect2(300, 420, 150, 120), Rect2(90, 580, 170, 120),
	Rect2(760, 140, 220, 150), Rect2(1080, 100, 180, 130), Rect2(1380, 180, 220, 150),
	Rect2(820, 520, 180, 140), Rect2(1250, 520, 240, 150),
	Rect2(1940, 120, 200, 140), Rect2(2160, 420, 170, 130), Rect2(1960, 580, 160, 120),
	Rect2(80, 1080, 190, 140), Rect2(300, 1400, 150, 130), Rect2(80, 1580, 170, 110),
	Rect2(780, 1080, 200, 140), Rect2(1300, 1060, 220, 150), Rect2(900, 1420, 240, 140), Rect2(1380, 1440, 190, 140),
	Rect2(1960, 1080, 200, 150), Rect2(2180, 1380, 160, 130), Rect2(1940, 1570, 180, 110),
]
var trees: Array[Vector2] = []
var grass_spots: Array[Vector2] = []
var loot: Array[Dictionary] = []     # Außen: {pos, kind}
var bots: Array[Dictionary] = []     # {pos, health, alive, color, dir, think, cd, tex, gun, aim}
var bullets: Array[Dictionary] = []  # {pos, vel, damage, life, owner}
var interior_loot: Dictionary = {}   # Haus-Index -> Array[Dictionary] (Innenraum-Loot)

# ---------- Spielzustand ----------
var phase := "menu"   # "menu", "fall", "play", "over", "won"
var menu_layer: CanvasLayer
var kills := 0
var sfx: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var muted := false
var minimap: Control
var save_xp := 0
var save_skin := "char_player"
var pass_label: Label
var skin_btn: Button
var sound_btn: Button
const SAVE_PATH := "user://battlechibi.cfg"
const XP_PER_LEVEL := 300
const MAX_LEVEL := 20
# Saison-Pass: Stufe -> freigeschalteter Skin
const SKINS := [
	[1, "char_player", "Astronaut"], [2, "char_red", "Pirat"], [4, "char_green", "Ninja"], [6, "char_yellow", "Koch"],
	[8, "char_purple", "Roboter"], [10, "char_orange", "Feuerwehr"], [13, "char_cyan", "Wikinger"], [16, "char_pink", "Cowboy"],
]
var menu_title: Label
var menu_play: Button
var menu_help: Label
var fall_timer := FALL_TIME
var player_pos := Vector2(1200, 1650)
var outside_pos := Vector2.ZERO      # Position im Freien, solange man im Haus ist
var inside := -1                     # -1 = draußen, sonst Index des Hauses
var facing := Vector2.UP
var health := 100.0
var weapon := ""
var ammo := 0
var shoot_cd := 0.0
var board_timer := 0.0
var dash_charges := 2
var dash_recharge := 0.0
var weapon_rar := 0
var melee := "fist"
var player_moving := false
var melee_cd := 0.0
var swings: Array[Dictionary] = []   # Nahkampf-Schwünge zum Zeichnen: {pos, dir, t}
var tex_chests: Array[Texture2D] = []
var tex_melee: Dictionary = {}
var shield := 0.0
var jump_charges := 0
var jump_timer := 0.0
var power_timer := 0.0
var speed_timer := 0.0
var explosions: Array[Dictionary] = []   # {pos, t, r}
var elapsed := 0.0
var zone_radius := ZONE_START_RADIUS
var placement := 0
var message := ""
var message_timer := 0.0

# ---------- UI ----------
var cam: Camera2D
var units3d: Node = null
var hardcore := false
var flashes: Array[Dictionary] = []
var sparks: Array[Dictionary] = []
var fireballs: Array[Dictionary] = []
var shake := 0.0
var tut_done := false
var tut_step := 0
const TUT_TEXTS := ["Linker Daumen: laufen", "Rechter Daumen: FEUER halten = schießen, ziehen = zielen", "Kisten öffnen: 3 Sekunden daneben stehen", "Bleib in der Zone, das Feuer außen tut weh!"]
var zone_dmg := ZONE_DAMAGE_PER_SEC
var zone_time := ZONE_SHRINK_TIME
var bot_dmg_mult := 0.5
var bot_cd_mult := 1.0
var xp_mult := 1.0
var mode_btn: Button
var map_btn: Button
var map_theme := 0   # 0 Wiese, 1 Wüste, 2 Schnee
var popups: Array[Dictionary] = []
var kill_feed: Array = []
var fx: Control
var damage_flash := 0.0
var hit_marker := 0.0
const ZOOM := 1.3
const ONLINE := false   # Online-Multiplayer gibt es noch nicht; Pause verhält sich dann anders
var paused_away := false
var pause_layer: CanvasLayer
var pause_info: Label
var pause_sound_btn: Button
const CHEST_OPEN_TIME := 3.0
var chest_item: Dictionary = {}
var chest_timer := 0.0
var chest_near := false
var next_loot_id := 0
var flash_t: Dictionary = {}   # owner_id -> Zeitpunkt des letzten Schusses
var atk_t: Dictionary = {}     # owner_id -> Zeitpunkt des letzten Nahkampfschlags
const BOT_SKINS := ["char_red", "char_green", "char_yellow", "char_purple", "char_orange", "char_cyan", "char_pink"]
var hud: Label
var center_label: Label
var light: PointLight2D
var touch: CanvasLayer
var use_mouse_aim := false

# ---------- Grafiken (eigene, siehe gen_art.py) ----------
var tex_player: Texture2D
var tex_bots: Array[Texture2D] = []
var tex_roofs: Array[Texture2D] = []
var tex_trees: Array[Texture2D] = []
var tex_loot: Dictionary = {}   # Art -> Texture2D
var tex_guns: Dictionary = {}   # Waffen-Art -> Texture2D (Waffe in der Hand)
var grass_blobs: Array = []
var tex_grass: Texture2D
var tex_asphalt: Texture2D
var view := Transform2D.IDENTITY
var tex_path: Texture2D
var decor: Array[Dictionary] = []   # Textur-Vorlagen für Deko
var decor_list: Array[Dictionary] = []  # Deko-Stellen ohne Kollision: {pos, tex, size}

func _ready() -> void:
	randomize()
	units3d = load("res://units3d.gd").new()
	add_child(units3d)
	units3d.setup(self)
	_load_textures()
	_generate_trees()
	_generate_grass()
	_generate_decor()
	_spawn_loot()
	_spawn_bots()
	units3d.build_world(obstacles, trees, tex_roofs)

	cam = Camera2D.new()
	cam.zoom = Vector2(ZOOM, ZOOM)
	add_child(cam)
	cam.make_current()
	_set_camera_limits(true)

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(20, 20)
	hud.add_theme_font_size_override("font_size", 24)
	hud.add_theme_color_override("font_color", Color(1, 1, 1))
	hud.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.12))
	hud.add_theme_constant_override("outline_size", 8)
	layer.add_child(hud)
	hud.visible = false
	center_label = Label.new()
	center_label.anchor_right = 1.0
	center_label.offset_top = 250.0
	center_label.offset_bottom = 410.0
	center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	center_label.add_theme_font_size_override("font_size", 40)
	center_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	center_label.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.12))
	center_label.add_theme_constant_override("outline_size", 10)
	layer.add_child(center_label)

	_setup_visuals()
	touch = TouchControlsScript.new()
	add_child(touch)
	touch.ability_pressed.connect(_try_dash)
	touch.action_pressed.connect(_on_action_button)
	touch.pause_pressed.connect(_toggle_pause)
	touch.visible = false
	_load_save()
	_apply_skin()
	_setup_audio()
	_build_minimap(layer)
	_build_menu()
	_build_pause()
	_build_fx()

# ---------- Hauptmenü ----------
func _build_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 6
	add_child(menu_layer)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.08, 0.12, 0.3), Color(0.16, 0.42, 0.62), Color(0.3, 0.62, 0.5)])
	grad.offsets = PackedFloat32Array([0.0, 0.62, 1.0])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	var bg := TextureRect.new()
	bg.texture = gt
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(bg)
	var stage := _make_stage(menu_layer)

	menu_title = Label.new()
	menu_title.text = "BATTLECHIBI"
	menu_title.position = Vector2(0, 40)
	menu_title.size = Vector2(1280, 120)
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_size_override("font_size", 96)
	menu_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	menu_title.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.1))
	menu_title.add_theme_constant_override("outline_size", 14)
	stage.add_child(menu_title)

	var box := VBoxContainer.new()
	box.position = Vector2(440, 185)
	box.size = Vector2(400, 420)
	box.add_theme_constant_override("separation", 18)
	stage.add_child(box)

	menu_play = _menu_button("SPIELEN", Color(0.25, 0.75, 0.35))
	menu_play.pressed.connect(_on_menu_play)
	box.add_child(menu_play)
	var help_btn := _menu_button("STEUERUNG", Color(0.25, 0.5, 0.9))
	help_btn.pressed.connect(func():
		menu_help.visible = not menu_help.visible
		pass_label.visible = false)
	box.add_child(help_btn)
	var pass_btn := _menu_button("SAISON-PASS", Color(0.55, 0.4, 0.8))
	pass_btn.pressed.connect(func():
		_update_pass_label()
		pass_label.visible = not pass_label.visible
		menu_help.visible = false)
	box.add_child(pass_btn)
	mode_btn = _menu_button("", Color(0.85, 0.35, 0.3))
	mode_btn.custom_minimum_size = Vector2(400, 64)
	mode_btn.add_theme_font_size_override("font_size", 28)
	mode_btn.pressed.connect(func():
		hardcore = not hardcore
		_write_save()
		_update_menu_buttons())
	var row0 := HBoxContainer.new()
	row0.add_theme_constant_override("separation", 12)
	box.add_child(row0)
	mode_btn.custom_minimum_size = Vector2(250, 64)
	mode_btn.add_theme_font_size_override("font_size", 24)
	row0.add_child(mode_btn)
	map_btn = _menu_button("", Color(0.3, 0.5, 0.7))
	map_btn.custom_minimum_size = Vector2(138, 64)
	map_btn.add_theme_font_size_override("font_size", 22)
	map_btn.pressed.connect(func():
		map_theme = (map_theme + 1) % 3
		_write_save()
		_update_menu_buttons())
	row0.add_child(map_btn)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	skin_btn = _menu_button("", Color(0.9, 0.55, 0.2))
	skin_btn.custom_minimum_size = Vector2(250, 64)
	skin_btn.add_theme_font_size_override("font_size", 26)
	skin_btn.pressed.connect(_next_skin)
	row.add_child(skin_btn)
	sound_btn = _menu_button("", Color(0.3, 0.3, 0.4))
	sound_btn.custom_minimum_size = Vector2(138, 64)
	sound_btn.add_theme_font_size_override("font_size", 26)
	sound_btn.pressed.connect(_toggle_sound)
	row.add_child(sound_btn)
	_update_menu_buttons()

	menu_help = Label.new()
	menu_help.text = "Joystick links: laufen   |   FEUER halten: schießen, Daumen ziehen: zielen   |   Blitz: Sprung/Dash   |   II oben: Pause\nPC: WASD laufen, Maus zielen, Leertaste/Maus schießen, Shift Fähigkeit\nBlau = Schild   Rot = Sprung   Gelb = Power   Grün = Speed\nDie Feuerzone kostet 0,5 Leben pro Sekunde, Häuser betrittst du einfach durch die Tür."
	menu_help.position = Vector2(0, 590)
	menu_help.size = Vector2(1280, 120)
	menu_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_help.add_theme_font_size_override("font_size", 20)
	menu_help.visible = false
	stage.add_child(menu_help)

	pass_label = Label.new()
	pass_label.position = Vector2(870, 200)
	pass_label.size = Vector2(380, 420)
	pass_label.add_theme_font_size_override("font_size", 20)
	pass_label.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.12))
	pass_label.add_theme_constant_override("outline_size", 6)
	pass_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pass_label.visible = false
	stage.add_child(pass_label)

# ---------- Pause ----------
# 1280x720-Bühne, die bei jeder Bildschirmgröße in der Mitte sitzt
func _make_stage(layer: CanvasLayer) -> Control:
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cc)
	var stage := Control.new()
	stage.custom_minimum_size = Vector2(1280, 720)
	cc.add_child(stage)
	return stage

func _build_fx() -> void:
	var l := CanvasLayer.new()
	l.layer = 2
	add_child(l)
	fx = Control.new()
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_child(fx)
	fx.draw.connect(_draw_fx)

func _fx_screen(p: Vector2) -> Vector2:
	return (_w(p) - cam.get_screen_center_position()) * ZOOM + get_viewport_rect().size * 0.5

func _fx_bar(sp: Vector2, hp: float, col: Color) -> void:
	var w := 50.0
	var ratio := clampf(hp / 100.0, 0.0, 1.0)
	var top := sp + Vector2(-w / 2.0, -112)
	fx.draw_rect(Rect2(top - Vector2(2, 2), Vector2(w + 4, 11)), OUTLINE)
	fx.draw_rect(Rect2(top, Vector2(w, 7)), Color(0.25, 0.25, 0.28))
	fx.draw_rect(Rect2(top, Vector2(w * ratio, 7)), col)

func _pill(r: Rect2, col: Color, radius := 10) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	fx.draw_style_box(sb, r)

func _bar(r: Rect2, ratio: float, col: Color, back := Color(0.08, 0.09, 0.14, 0.75)) -> void:
	_pill(Rect2(r.position - Vector2(3, 3), r.size + Vector2(6, 6)), Color(0.05, 0.05, 0.08, 0.9), 12)
	_pill(r, back, 10)
	if ratio > 0.01:
		_pill(Rect2(r.position, Vector2(maxf(r.size.y, r.size.x * clampf(ratio, 0.0, 1.0)), r.size.y)), col, 10)
		_pill(Rect2(r.position + Vector2(3, 2), Vector2(maxf(4.0, r.size.x * clampf(ratio, 0.0, 1.0) - 6.0), r.size.y * 0.35)), Color(1, 1, 1, 0.22), 6)

func _text(p: Vector2, t: String, size: int, col := Color.WHITE, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var f := ThemeDB.fallback_font
	fx.draw_string_outline(f, p, t, align, width, size, 7, Color(0.06, 0.05, 0.1, 0.95))
	fx.draw_string(f, p, t, align, width, size, col)

func _draw_hud(vs: Vector2) -> void:
	var alive := _living_bots() + 1
	_pill(Rect2(16, 14, 170, 40), Color(0.05, 0.06, 0.12, 0.7), 20)
	_text(Vector2(30, 43), "ÜBRIG  %d" % alive, 24, Color(1, 0.9, 0.5))
	_pill(Rect2(16, 60, 130, 34), Color(0.05, 0.06, 0.12, 0.7), 17)
	_text(Vector2(30, 85), "KILLS  %d" % kills, 20)
	# Kill-Feed
	var fy := 118.0
	for kf in kill_feed:
		var fa := clampf(1.0 - (float(kf["t"]) - 4.0), 0.0, 1.0)
		if fa <= 0.0:
			continue
		_pill(Rect2(16, fy - 22, 190, 30), Color(0.05, 0.06, 0.12, 0.6 * fa), 15)
		_text(Vector2(28, fy), str(kf["text"]), 18, Color(1, 0.85, 0.5, fa))
		fy += 34.0
	# Leiste unten in der Mitte
	var w := clampf(vs.x - 760.0, 300.0, 420.0)
	var x0 := vs.x * 0.5 - w * 0.5
	var y0 := vs.y - 56.0
	var hp := health / 100.0
	var hcol := Color(0.3, 0.9, 0.4) if hp > 0.5 else (Color(1, 0.8, 0.2) if hp > 0.25 else Color(1, 0.3, 0.3))
	_bar(Rect2(x0, y0, w, 26), hp, hcol)
	_text(Vector2(x0, y0 + 21), "%d" % int(ceil(health)), 20, Color.WHITE, w, HORIZONTAL_ALIGNMENT_CENTER)
	_bar(Rect2(x0 + 14, y0 - 22, w - 28, 12), shield / 100.0, Color(0.35, 0.65, 1.0))
	# Waffe
	var wname: String = MELEE[melee]["name"]
	var rc := Color(0.6, 0.6, 0.65)
	var ammo_t := ""
	if weapon != "":
		wname = WEAPONS[weapon]["name"]
		rc = RARITY_COLORS[weapon_rar]
		ammo_t = "  %d" % ammo
	_pill(Rect2(x0 + 14, y0 - 64, w - 28, 34), Color(0.05, 0.06, 0.12, 0.75), 17)
	_pill(Rect2(x0 + 14, y0 - 64, 10, 34), rc, 5)
	_text(Vector2(x0 + 34, y0 - 40), wname + ammo_t, 21, rc.lightened(0.35))
	# Ladungen: Sprung (rot) und Dash (cyan)
	for i in jump_charges:
		fx.draw_circle(Vector2(x0 - 22 - i * 22, y0 + 13), 8, Color(1, 0.3, 0.3))
		fx.draw_arc(Vector2(x0 - 22 - i * 22, y0 + 13), 8, 0.0, TAU, 16, Color(1, 1, 1, 0.8), 2.0)
	for i in dash_charges:
		fx.draw_circle(Vector2(x0 + w + 22 + i * 22, y0 + 13), 8, Color(0.3, 0.9, 1.0))
		fx.draw_arc(Vector2(x0 + w + 22 + i * 22, y0 + 13), 8, 0.0, TAU, 16, Color(1, 1, 1, 0.8), 2.0)
	var ty := y0 - 74.0
	if power_timer > 0.0:
		_text(Vector2(x0 + 14, ty), "POWER %d" % int(ceil(power_timer)), 18, Color(1, 0.85, 0.2))
	if speed_timer > 0.0:
		_text(Vector2(x0 + w - 100, ty), "SPEED %d" % int(ceil(speed_timer)), 18, Color(0.4, 1, 0.5))

func _draw_fx() -> void:
	if phase == "menu" or phase == "over" or phase == "won":
		return
	var vs := get_viewport_rect().size
	if phase == "play" and inside < 0 and _living_bots() <= 3:
		var cc := vs * 0.5
		for b in bots:
			if not b["alive"]:
				continue
			var sp := _fx_screen(b["pos"])
			if Rect2(Vector2(40, 40), vs - Vector2(80, 80)).has_point(sp):
				continue
			var dv := (sp - cc).normalized()
			var edge := Vector2(clampf(cc.x + dv.x * 4000.0, 50.0, vs.x - 50.0), clampf(cc.y + dv.y * 4000.0, 130.0, vs.y - 130.0))
			var tip := edge
			var pa := PackedVector2Array([tip + dv * 18.0, tip - dv * 12.0 + dv.orthogonal() * 14.0, tip - dv * 12.0 - dv.orthogonal() * 14.0])
			fx.draw_colored_polygon(pa, Color(1, 0.25, 0.25, 0.9))
	if hit_marker > 0.0:
		var hc := vs * 0.5 + Vector2(0, -20)
		var ha := hit_marker / 0.18
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				fx.draw_line(hc + Vector2(sx, sy) * 8.0, hc + Vector2(sx, sy) * (16.0 + 6.0 * (1.0 - ha)), Color(1, 1, 1, ha), 4.0)
	if damage_flash > 0.0:
		var a := damage_flash / 0.35 * 0.3
		for k in 6:
			var m := 14.0 * (k + 1)
			fx.draw_rect(Rect2(0, 0, vs.x, m), Color(1, 0.1, 0.1, a * 0.3))
			fx.draw_rect(Rect2(0, vs.y - m, vs.x, m), Color(1, 0.1, 0.1, a * 0.3))
			fx.draw_rect(Rect2(0, 0, m, vs.y), Color(1, 0.1, 0.1, a * 0.3))
			fx.draw_rect(Rect2(vs.x - m, 0, m, vs.y), Color(1, 0.1, 0.1, a * 0.3))
	if phase == "fall":
		_pill(Rect2(vs.x * 0.5 - 150, 84, 300, 44), Color(0.05, 0.06, 0.12, 0.7), 22)
		_text(Vector2(vs.x * 0.5 - 150, 116), "Landung in %d s" % int(ceil(fall_timer)), 24, Color(1, 0.9, 0.5), 300.0, HORIZONTAL_ALIGNMENT_CENTER)
	if phase == "play":
		_draw_hud(vs)
		var hb := 112.0 * ZOOM / 1.15
		_fx_bar2(_fx_screen(player_pos), health, Color(0.3, 0.95, 0.4), hb)
		if inside < 0:
			for b in bots:
				if b["alive"]:
					_fx_bar2(_fx_screen(b["pos"]), b["health"], Color(0.95, 0.35, 0.3), hb)
	# Kugeln
	for bl in bullets:
		var sp := _fx_screen(bl["pos"]) + Vector2(0, -30.0 * ZOOM)
		var dv := _screen_dir(bl["vel"])
		if bl["explode"] > 0.0:
			for k in 5:
				fx.draw_circle(sp - dv * (10.0 + k * 9.0), 9.0 - k, Color(1, 0.55 - k * 0.07, 0.15, 0.55 - k * 0.1))
			fx.draw_circle(sp, 9, OUTLINE)
			fx.draw_circle(sp, 7, Color(0.55, 0.8, 0.55))
		else:
			fx.draw_line(sp - dv * 26.0, sp, Color(1, 0.8, 0.25, 0.35), 8.0)
			fx.draw_line(sp - dv * 20.0, sp, Color(1, 0.95, 0.6, 0.85), 3.5)
			fx.draw_circle(sp, 6, Color(1, 0.9, 0.4, 0.35))
			fx.draw_circle(sp, 3.5, Color(1, 1, 0.9))
	# Mündungsfeuer
	for f in flashes:
		var fp := _fx_screen(f["pos"]) + Vector2(0, -30.0 * ZOOM)
		var fd := _screen_dir(f["dir"])
		var sz := 26.0 if f["big"] else 17.0
		var pts := PackedVector2Array()
		for i in 8:
			var ang := TAU * i / 8.0
			var r := sz if i % 2 == 0 else sz * 0.45
			pts.append(fp + fd * sz * 0.5 + Vector2.from_angle(ang) * r)
		fx.draw_colored_polygon(pts, Color(1, 0.85, 0.3, 0.9))
		fx.draw_circle(fp + fd * sz * 0.5, sz * 0.4, Color(1, 1, 0.9, 0.95))
	# Explosionen
	for fb in fireballs:
		var k: float = fb["t"] / 0.55
		var ep := _fx_screen(fb["pos"]) + Vector2(0, -20.0)
		var rr: float = fb["r"] * ZOOM * (0.35 + 0.75 * k) * 0.8
		fx.draw_circle(ep, rr, Color(1, 0.45, 0.1, 0.55 * (1.0 - k)))
		fx.draw_circle(ep + Vector2(0, -rr * 0.15), rr * 0.7, Color(1, 0.75, 0.25, 0.7 * (1.0 - k)))
		fx.draw_circle(ep + Vector2(0, -rr * 0.3), rr * 0.4, Color(1, 0.98, 0.7, 0.8 * (1.0 - k)))
		fx.draw_circle(ep + Vector2(0, -rr * 0.9 * k), rr * 0.45, Color(0.2, 0.18, 0.2, 0.35 * (1.0 - k)))
		fx.draw_arc(ep, rr * 1.05, 0.0, TAU, 40, Color(1, 0.9, 0.6, 0.6 * (1.0 - k)), 5.0)
	# Funken
	for sp in sparks:
		var k2: float = sp["t"] / sp["life"]
		var c: Color = sp["col"]
		c.a = 1.0 - k2
		fx.draw_circle(_fx_screen(sp["pos"]) + sp["o"] * ZOOM, 4.5 * (1.0 - k2 * 0.6), c)
	var f2 := ThemeDB.fallback_font
	for p in popups:
		var k3: float = p["t"] / 0.9
		var sp2 := _fx_screen(p["pos"]) + Vector2(-20, -100.0 * ZOOM / 1.15 - 46.0 * k3)
		var c2: Color = p["col"]
		c2.a = 1.0 - k3 * k3
		var sc := 1.0 + 0.5 * maxf(0.0, 1.0 - k3 * 6.0)
		fx.draw_string_outline(f2, sp2, p["text"], HORIZONTAL_ALIGNMENT_CENTER, 40, int(28 * sc), 7, Color(0.1, 0.08, 0.1, c2.a))
		fx.draw_string(f2, sp2, p["text"], HORIZONTAL_ALIGNMENT_CENTER, 40, int(28 * sc), c2)

func _fx_bar2(sp: Vector2, hp: float, col: Color, up: float) -> void:
	var w := 54.0
	var top := sp + Vector2(-w / 2.0, -up)
	_bar(Rect2(top, Vector2(w, 8)), hp / 100.0, col)

func _build_pause() -> void:
	pause_layer = CanvasLayer.new()
	pause_layer.layer = 8
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.visible = false
	add_child(pause_layer)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.05, 0.1, 0.72)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(bg)
	var pstage := _make_stage(pause_layer)
	var title := Label.new()
	title.text = "PAUSE"
	title.position = Vector2(0, 90)
	title.size = Vector2(1280, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.1, 0.1))
	title.add_theme_constant_override("outline_size", 12)
	pstage.add_child(title)
	pause_info = Label.new()
	pause_info.position = Vector2(240, 195)
	pause_info.size = Vector2(800, 70)
	pause_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_info.add_theme_font_size_override("font_size", 22)
	pause_info.add_theme_color_override("font_outline_color", Color(0.1, 0.08, 0.12))
	pause_info.add_theme_constant_override("outline_size", 6)
	pstage.add_child(pause_info)
	var box := VBoxContainer.new()
	box.position = Vector2(440, 280)
	box.size = Vector2(400, 380)
	box.add_theme_constant_override("separation", 16)
	pstage.add_child(box)
	var resume := _menu_button("WEITER", Color(0.25, 0.75, 0.35))
	resume.pressed.connect(_toggle_pause)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	var sc := Shortcut.new()
	sc.events = [esc]
	resume.shortcut = sc
	box.add_child(resume)
	pause_sound_btn = _menu_button("", Color(0.3, 0.3, 0.4))
	pause_sound_btn.pressed.connect(func():
		_toggle_sound()
		_update_menu_buttons())
	box.add_child(pause_sound_btn)
	var quit_btn := _menu_button("AUFGEBEN", Color(0.8, 0.3, 0.3))
	quit_btn.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	box.add_child(quit_btn)

func _toggle_pause() -> void:
	if phase != "play" and phase != "fall":
		return
	paused_away = not paused_away
	pause_layer.visible = paused_away
	pause_info.text = "Du bist weg vom Spiel, bleibst aber verbunden und kannst getroffen werden." if ONLINE else "Das Spiel ist angehalten."
	if not ONLINE:
		get_tree().paused = paused_away
	_update_menu_buttons()

func _style_for(col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(5)
	sb.border_color = Color(0.15, 0.1, 0.1)
	return sb

func _apply_difficulty() -> void:
	if hardcore:
		zone_dmg = 2.0
		zone_time = 130.0
		bot_dmg_mult = 1.0
		bot_cd_mult = 0.6
		xp_mult = 2.0
		for i in 6:
			var nb: Dictionary = bots[i].duplicate(true)
			nb["pos"] = _random_free(BOT_RADIUS)
			nb["skin"] = BOT_SKINS[(i + 3) % BOT_SKINS.size()]
			bots.append(nb)
		var keep: Array[Dictionary] = []
		for it in loot:
			if it["kind"] == "chest" or randf() < 0.7:
				keep.append(it)
		loot = keep
	else:
		zone_dmg = ZONE_DAMAGE_PER_SEC
		zone_time = ZONE_SHRINK_TIME
		bot_dmg_mult = 0.5
		bot_cd_mult = 1.0
		xp_mult = 1.0

func _menu_button(text: String, col: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(400, 84)
	b.add_theme_font_size_override("font_size", 38)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color.WHITE)
	b.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.07))
	b.add_theme_constant_override("outline_size", 6)
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(18)
	sb.set_border_width_all(5)
	sb.border_color = Color(0.15, 0.1, 0.1)
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate()
	sbh.bg_color = col.lightened(0.2)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	return b

func _on_menu_play() -> void:
	if phase == "over" or phase == "won":
		get_tree().reload_current_scene()
		return
	menu_layer.visible = false
	touch.visible = true
	_apply_difficulty()
	phase = "fall"
	if music_player and not music_player.playing:
		music_player.play()
	_show_message("Fallschirm-Absprung! Steuere zum Landeplatz", 3.0)

func _show_end_menu(title: String) -> void:
	_play_sfx("win" if title.begins_with("SIEG") else "lose", -4.0)
	menu_title.text = title
	menu_title.add_theme_font_size_override("font_size", 54)
	menu_play.text = "NOCHMAL"
	menu_layer.visible = true
	touch.visible = false

# ---------- Speicherstand und Saison-Pass ----------
func _level() -> int:
	return mini(MAX_LEVEL, 1 + save_xp / XP_PER_LEVEL)

func _load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		save_xp = int(cfg.get_value("pass", "xp", 0))
		save_skin = str(cfg.get_value("pass", "skin", "char_player"))
		muted = bool(cfg.get_value("settings", "muted", false))
		hardcore = bool(cfg.get_value("settings", "hardcore", false))
		map_theme = int(cfg.get_value("settings", "map_theme", 0)) % 3
		tut_done = bool(cfg.get_value("settings", "tut_done", false))
	if not _skin_unlocked(save_skin):
		save_skin = "char_player"

func _write_save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("pass", "xp", save_xp)
	cfg.set_value("pass", "skin", save_skin)
	cfg.set_value("settings", "muted", muted)
	cfg.set_value("settings", "hardcore", hardcore)
	cfg.set_value("settings", "map_theme", map_theme)
	cfg.set_value("settings", "tut_done", tut_done)
	cfg.save(SAVE_PATH)

func _skin_unlocked(skin: String) -> bool:
	for e in SKINS:
		if e[1] == skin:
			return _level() >= e[0]
	return false

func _apply_skin() -> void:
	var t := _load_tex(ART + save_skin + ".png")
	if t:
		tex_player = t

func _next_skin() -> void:
	var idx := 0
	for i in SKINS.size():
		if SKINS[i][1] == save_skin:
			idx = i
	for k in range(1, SKINS.size() + 1):
		var cand: Array = SKINS[(idx + k) % SKINS.size()]
		if _level() >= cand[0]:
			save_skin = cand[1]
			break
	_apply_skin()
	_write_save()
	_update_menu_buttons()

func _skin_name() -> String:
	for e in SKINS:
		if e[1] == save_skin:
			return e[2]
	return "Astronaut"

func _update_menu_buttons() -> void:
	if skin_btn:
		skin_btn.text = "SKIN: " + _skin_name()
	if sound_btn:
		sound_btn.text = "TON AUS" if muted else "TON AN"
	if mode_btn:
		mode_btn.text = "HARDCORE" if hardcore else "NORMAL"
	if map_btn:
		map_btn.text = ["WIESE", "WÜSTE", "SCHNEE"][map_theme]
		mode_btn.add_theme_stylebox_override("normal", _style_for(Color(0.75, 0.15, 0.15) if hardcore else Color(0.3, 0.6, 0.4)))
	if pause_sound_btn:
		pause_sound_btn.text = "TON AUS" if muted else "TON AN"

func _update_pass_label() -> void:
	var lvl := _level()
	var into := save_xp % XP_PER_LEVEL
	var txt := "SAISON 1 – STUFE %d / %d\nXP: %d / %d bis zur nächsten Stufe\n\nBelohnungen:\n" % [lvl, MAX_LEVEL, into, XP_PER_LEVEL]
	if lvl >= MAX_LEVEL:
		txt = "SAISON 1 – MAXIMALE STUFE %d\n\nBelohnungen:\n" % MAX_LEVEL
	for e in SKINS:
		var mark := "✔" if lvl >= e[0] else "🔒"
		txt += "%s  Stufe %d: Skin %s\n" % [mark, e[0], e[2]]
	txt += "\nXP: 20 pro Runde, 50 pro Kill, bis 300 für die Platzierung"
	pass_label.text = txt

func _award_xp() -> String:
	var before := _level()
	var total := bots.size()
	var gained := int((20 + kills * 50 + int(300.0 * float(total + 1 - placement) / float(total))) * xp_mult)
	save_xp += gained
	_write_save()
	_update_menu_buttons()
	var msg := "+%d XP" % gained
	if _level() > before:
		msg += "   STUFE %d!" % _level()
	return msg

# ---------- Sound ----------
func _setup_audio() -> void:
	for n in ["shot", "shotgun", "rocket", "explosion", "pickup", "power", "hit", "chest", "win", "lose"]:
		var path: String = "res://assets/sfx/" + n + ".wav"
		if ResourceLoader.exists(path):
			sfx[n] = load(path)
	for i in 10:
		var pl := AudioStreamPlayer.new()
		add_child(pl)
		sfx_players.append(pl)
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -10.0
	if ResourceLoader.exists("res://assets/sfx/music.wav"):
		music_player.stream = load("res://assets/sfx/music.wav")
		music_player.finished.connect(func(): music_player.play())
	add_child(music_player)
	AudioServer.set_bus_mute(0, muted)

func _play_sfx(n: String, vol_db := 0.0) -> void:
	if muted or not sfx.has(n):
		return
	for pl in sfx_players:
		if not pl.playing:
			pl.stream = sfx[n]
			pl.volume_db = vol_db
			pl.pitch_scale = randf_range(0.92, 1.08)
			pl.play()
			return

func _toggle_sound() -> void:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	_write_save()
	_update_menu_buttons()

# ---------- Minikarte ----------
func _build_minimap(layer: CanvasLayer) -> void:
	minimap = Control.new()
	minimap.anchor_left = 1.0
	minimap.anchor_right = 1.0
	minimap.offset_left = -236.0
	minimap.offset_right = -16.0
	minimap.offset_top = 16.0
	minimap.offset_bottom = 181.0
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap.clip_contents = true
	layer.add_child(minimap)
	minimap.draw.connect(_draw_minimap)

func _draw_minimap() -> void:
	var m := minimap
	var center_pos := player_pos if inside < 0 else _door_of(inside)
	m.draw_rect(Rect2(Vector2.ZERO, m.size), Color(0.2, 0.42, 0.6, 0.9))
	var sc := 0.065
	var basis := Transform2D(Vector2(1, 0), Vector2(0, VIEW_TILT), Vector2.ZERO) * Transform2D(VIEW_ANGLE, Vector2.ZERO)
	var mt := Transform2D(0.0, Vector2(sc, sc), 0.0, m.size / 2.0) * basis * Transform2D(0.0, -center_pos)
	m.draw_set_transform_matrix(mt)
	m.draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), [Color(0.35, 0.65, 0.35), Color(0.85, 0.72, 0.45), Color(0.9, 0.94, 0.98)][map_theme])
	for road in ROADS:
		m.draw_rect(road, Color(0.45, 0.47, 0.52))
	for r in obstacles:
		m.draw_rect(r, Color(0.85, 0.4, 0.3))
	m.draw_arc(ZONE_CENTER, zone_radius, 0.0, TAU, 64, Color(1, 0.6, 0.1), 30.0)
	m.draw_set_transform_matrix(Transform2D.IDENTITY)
	if _living_bots() <= 3:
		for b in bots:
			if b["alive"]:
				var mp: Vector2 = mt * (b["pos"] as Vector2)
				m.draw_circle(mp, 5.0, Color(1, 0.2, 0.2))
				m.draw_arc(mp, 6.0, 0.0, TAU, 12, Color.WHITE, 2.0)
	m.draw_circle(m.size / 2.0, 5.0, Color.WHITE)
	m.draw_arc(m.size / 2.0, 6.0, 0.0, TAU, 12, Color(0.1, 0.1, 0.1), 2.0)
	m.draw_rect(Rect2(Vector2.ZERO, m.size), Color(0.1, 0.08, 0.12), false, 3.0)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

func _load_textures() -> void:
	tex_player = _load_tex(ART + "char_player.png")
	for n in ["char_red", "char_green", "char_yellow", "char_purple", "char_orange", "char_cyan", "char_pink"]:
		var t := _load_tex(ART + n + ".png")
		if t:
			tex_bots.append(t)
	for n in ["roof_red", "roof_orange", "roof_teal", "roof_blue"]:
		var r := _load_tex(ART + n + ".png")
		if r:
			tex_roofs.append(r)
	for n in ["tree_a", "tree_b"]:
		var tt := _load_tex(ART + n + ".png")
		if tt:
			tex_trees.append(tt)
	for k in ["heal", "board", "dash", "pistol", "smg", "shotgun", "sniper"]:
		var lt := _load_tex(ART + "loot_" + k + ".png")
		if lt:
			tex_loot[k] = lt
	var g := _load_tex(ART + "weapon_pistol.png")
	if g:
		tex_guns["pistol"] = g
	for k in ["shield", "jump", "power", "speed"]:
		var ot := _load_tex(ART + "orb_" + k + ".png")
		if ot:
			tex_loot[k] = ot
	for wk in ["minigun", "smg", "ak", "shotgun", "sniper", "rocket"]:
		var wt := _load_tex(ART + "weapon_" + wk + ".png")
		if wt:
			tex_guns[wk] = wt
	tex_grass = _load_tex(ART + "grass.png")
	tex_asphalt = _load_tex(ART + "asphalt.png")
	for c in 4:
		var ct := _load_tex(ART + "chest_%d.png" % c)
		if ct:
			tex_chests.append(ct)
	for mk in ["bat", "pan", "extinguisher"]:
		var mt := _load_tex(ART + "melee_" + mk + ".png")
		if mt:
			tex_melee[mk] = mt
	for pair in [["heal", "item_heal_small"], ["heal_big", "item_heal_big"], ["shield", "item_shield_small"], ["shield_big", "item_shield_big"]]:
		var it := _load_tex(ART + pair[1] + ".png")
		if it:
			tex_loot[pair[0]] = it
	tex_path = _load_tex(ART + "path.png")
	for dn in [["bush_a", Vector2(44, 44)], ["bush_b", Vector2(44, 44)], ["flower_pink", Vector2(20, 20)],
			["flower_white", Vector2(20, 20)], ["flower_yellow", Vector2(20, 20)], ["rock", Vector2(32, 32)]]:
		var dt := _load_tex(ART + dn[0] + ".png")
		if dt:
			decor.append({"tex": dt, "size": dn[1], "name": dn[0]})

# ---------- Licht und Stimmung ----------
func _setup_visuals() -> void:
	# Jahreszeit-Farbton über die Systemzeit (Winter kühl, Sommer warm, Herbst orange)
	var mod := CanvasModulate.new()
	mod.color = _season_tint()
	add_child(mod)

	# Spotlight, das der Figur folgt
	light = PointLight2D.new()
	light.texture = _radial_texture(Color.WHITE, Color.BLACK)
	light.texture_scale = 4.0
	light.energy = 0.0
	add_child(light)

	# Vignette: dunkle Ränder über dem Bild
	var vig_layer := CanvasLayer.new()
	vig_layer.layer = 2
	add_child(vig_layer)
	var vig := TextureRect.new()
	vig.texture = _radial_texture(Color(0, 0, 0, 0), Color(0, 0, 0, 0.14))
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig_layer.add_child(vig)

func _season_tint() -> Color:
	var month: int = Time.get_date_dict_from_system()["month"]
	if month == 12 or month <= 2:
		return Color(0.78, 0.86, 1.0)     # Winter: kühl
	elif month <= 5:
		return Color(0.92, 1.0, 0.9)      # Frühling: frisch
	elif month <= 8:
		return Color(0.98, 0.96, 0.85)    # Sommer: warm
	return Color(1.0, 0.93, 0.84)         # Herbst: warm

func _radial_texture(inner: Color, outer: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.colors = PackedColorArray([inner, outer])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	return t

# ---------- Generierung ----------
func _generate_trees() -> void:
	for i in 220:
		var p := Vector2(randf_range(30, MAP_SIZE.x - 30), randf_range(30, MAP_SIZE.y - 30))
		if _is_free(p, TREE_RADIUS + 40.0) and not _on_road(p, 40.0) and p.distance_to(Vector2(1200, 1650)) > 120:
			trees.append(p)

func _generate_decor() -> void:
	var placed: Array[Dictionary] = []
	for i in 520:
		var p := Vector2(randf_range(10, MAP_SIZE.x - 10), randf_range(10, MAP_SIZE.y - 10))
		if not _is_free(p, 8.0) or _on_road(p, 20.0):
			continue
		var pick := randi() % 10
		var tex_idx := 0
		if pick < 5:
			tex_idx = 2 + randi() % 3          # Blumen
		elif pick < 8:
			tex_idx = randi() % 2              # Büsche
		else:
			tex_idx = 5                        # Steine
		if tex_idx >= decor.size():
			continue
		var entry: Dictionary = decor[tex_idx]
		placed.append({"pos": p, "tex": entry["tex"], "size": entry["size"]})
	decor_list = placed

func _generate_grass() -> void:
	for i in 260:
		grass_spots.append(Vector2(randf_range(0, MAP_SIZE.x), randf_range(0, MAP_SIZE.y)))

func _random_rarity(weights: Array) -> int:
	var total := 0
	for w in weights:
		total += int(w)
	var roll := randi() % total
	for k in weights.size():
		roll -= int(weights[k])
		if roll < 0:
			return k
	return 0

func _spawn_loot() -> void:
	for i in LOOT_COUNT:
		var kind := _random_kind()
		loot.append({"pos": _random_free(20.0), "kind": kind, "rar": _random_rarity([70, 25, 5, 0]) if WEAPONS.has(kind) else 0})
	for i in CHEST_COUNT:
		loot.append({"pos": _random_free(30.0), "kind": "chest", "rar": _random_rarity([40, 30, 20, 10])})

func _random_kind() -> String:
	return LOOT_WEIGHTED[randi() % LOOT_WEIGHTED.size()]

func _spread_spawn() -> Vector2:
	var best := _random_free(BOT_RADIUS)
	var best_d := -1.0
	for k in 12:
		var p := _random_free(BOT_RADIUS)
		var d := 99999.0
		for b in bots:
			d = minf(d, p.distance_to(b["pos"]))
		if d > best_d:
			best_d = d
			best = p
	return best

func _spawn_bots() -> void:
	for i in BOT_COUNT:
		bots.append({
			"pos": _spread_spawn(),
			"health": 100.0,
			"alive": true,
			"color": Color(0.9, 0.5, 0.5),
			"dir": Vector2.from_angle(randf() * TAU),
			"think": randf_range(1.0, 3.0),
			"cd": randf_range(0.5, 2.0),
			"tex": tex_bots[i % tex_bots.size()] if tex_bots.size() > 0 else null,
			"skin": BOT_SKINS[i % BOT_SKINS.size()],
			"gun": null,
			"weapon": "fist",
			"rar": 0,
			"aim": Vector2.UP,
		})

func _generate_interior(i: int) -> void:
	var items: Array[Dictionary] = []
	for n in 2:
		var kind := _random_kind()
		items.append({"pos": Vector2(randf_range(80, 620), randf_range(330, 420)), "kind": kind, "rar": 0})
	# In jedem Haus steht eine Kiste, oft eine bessere als draußen
	items.append({"pos": Vector2(560, 260), "kind": "chest", "rar": _random_rarity([25, 35, 25, 15])})
	interior_loot[i] = items

# Kiste öffnen: Waffe in der Seltenheit der Kiste plus Heilung/Schild
func _open_chest(list: Array[Dictionary], pos: Vector2, rar: int) -> void:
	_play_sfx("chest", -3.0)
	var pool: Array = CHEST_WEAPONS[rar]
	var wk: String = pool[randi() % pool.size()]
	var extras: Array = []
	if rar >= 2:
		extras = ["heal_big", "shield_big"]
	else:
		extras = ["heal", "shield"]
	if rar == 3:
		extras.append(["power", "speed", "jump"][randi() % 3])
	var drops: Array = [[wk, rar]]
	for e in extras:
		drops.append([e, 0])
	for k in drops.size():
		var ang := -PI / 2.0 + (k - (drops.size() - 1) / 2.0) * 0.9
		list.append({"pos": pos + Vector2.from_angle(ang) * 62.0, "kind": drops[k][0], "rar": drops[k][1]})
	_play_sfx("power", 0.0)
	_show_message("%s-Kiste geöffnet!" % RARITY_NAMES[rar], 1.2)

func _set_camera_limits(_outdoor: bool) -> void:
	# Bei gekippter Kamera keine festen Grenzen; außerhalb der Insel liegt Wasser
	cam.limit_left = -1000000
	cam.limit_top = -1000000
	cam.limit_right = 1000000
	cam.limit_bottom = 1000000

func _is_free(p: Vector2, r: float) -> bool:
	if p.x < r or p.y < r or p.x > MAP_SIZE.x - r or p.y > MAP_SIZE.y - r:
		return false
	for o in obstacles:
		if o.grow(r).has_point(p):
			return false
	for t in trees:
		if p.distance_to(t) < r + TREE_RADIUS:
			return false
	return true

func _on_road(p: Vector2, margin: float) -> bool:
	for road in ROADS:
		if road.grow(margin).has_point(p):
			return true
	return false

# Welt -> Bildschirm (gekippte Kamera); im Haus keine Kippung
func _update_view() -> void:
	if inside >= 0:
		view = Transform2D.IDENTITY
	else:
		var squash := Transform2D(Vector2(1, 0), Vector2(0, VIEW_TILT), Vector2.ZERO)
		view = squash * Transform2D(VIEW_ANGLE, Vector2.ZERO)

func _w(p: Vector2) -> Vector2:
	return view * p

func _screen_dir(d: Vector2) -> Vector2:
	var v := view.basis_xform(d)
	return v.normalized() if v != Vector2.ZERO else Vector2.DOWN

func _world_dir(d: Vector2) -> Vector2:
	if d == Vector2.ZERO:
		return Vector2.ZERO
	return view.affine_inverse().basis_xform(d).normalized() * d.length()

func _random_free(r: float) -> Vector2:
	for i in 500:
		var p := Vector2(randf_range(40, MAP_SIZE.x - 40), randf_range(40, MAP_SIZE.y - 40))
		if _is_free(p, r):
			return p
	return ZONE_CENTER

func _nearest_free(p: Vector2, r: float) -> Vector2:
	if _is_free(p, r):
		return p
	for i in 400:
		var c := p + Vector2.from_angle(randf() * TAU) * randf_range(10.0, 300.0)
		if _is_free(c, r):
			return c
	return p

# Bewegt eine Figur Achse für Achse, damit man an Hindernissen entlanggleitet
func _move(pos: Vector2, step: Vector2, r: float) -> Vector2:
	var result := pos
	var nx := Vector2(pos.x + step.x, pos.y)
	if _is_free(nx, r):
		result.x = nx.x
	var ny := Vector2(result.x, result.y + step.y)
	if _is_free(ny, r):
		result.y = ny.y
	return result

# Spielerbewegung: draußen mit Welt-Kollision, drinnen im Raum
func _step_player(step: Vector2) -> void:
	if inside < 0 and jump_timer > 0.0:
		# Sprung: über Hindernisse hinweg, nur der Kartenrand bleibt
		player_pos = (player_pos + step).clamp(Vector2.ONE * PLAYER_RADIUS, MAP_SIZE - Vector2.ONE * PLAYER_RADIUS)
		return
	if inside < 0:
		player_pos = _move(player_pos, step, PLAYER_RADIUS)
		return
	var np := player_pos + step
	np.x = clampf(np.x, 40.0, ROOM_SIZE.x - 40.0)
	np.y = clampf(np.y, 40.0, ROOM_SIZE.y - 40.0)
	for f in ROOM_FURNITURE:
		if f.grow(PLAYER_RADIUS).has_point(np):
			return
	player_pos = np

func _door_entered() -> int:
	for i in obstacles.size():
		if _door_of(i).distance_to(player_pos) < 34.0:
			return i
	return -1

func _nearest_door() -> int:
	for i in obstacles.size():
		if _door_of(i).distance_to(player_pos) < DOOR_RANGE:
			return i
	return -1

func _door_of(i: int) -> Vector2:
	return Vector2(obstacles[i].position.x + obstacles[i].size.x / 2.0, obstacles[i].end.y)

func _enter_house(i: int) -> void:
	if not interior_loot.has(i):
		_generate_interior(i)
	outside_pos = player_pos
	inside = i
	player_pos = Vector2(ROOM_DOOR.x, ROOM_DOOR.y - 60)
	_set_camera_limits(false)
	_show_message("Im Haus. [E] verlässt das Haus", 2.0)

func _exit_house() -> void:
	var door := _door_of(inside)   # Tür merken, bevor inside zurückgesetzt wird
	inside = -1
	player_pos = _nearest_free(door + Vector2(0, 52), PLAYER_RADIUS)
	outside_pos = Vector2.ZERO
	_set_camera_limits(true)

func _current_loot() -> Array[Dictionary]:
	if inside >= 0:
		return interior_loot[inside]
	return loot

func _bullet_blocked(p: Vector2) -> bool:
	if p.x < 0 or p.y < 0 or p.x > MAP_SIZE.x or p.y > MAP_SIZE.y:
		return true
	for o in obstacles:
		if o.has_point(p):
			return true
	for t in trees:
		if p.distance_to(t) < TREE_RADIUS * 0.8:
			return true
	return false

func _living_bots() -> int:
	var n := 0
	for b in bots:
		if b["alive"]:
			n += 1
	return n

func _show_message(text: String, duration: float) -> void:
	message = text
	message_timer = duration

func _fire(owner_id: int, origin: Vector2, dir: Vector2, weapon_key: String) -> void:
	flashes.append({"pos": origin + dir.normalized() * 34.0, "dir": dir.normalized(), "t": 0.0, "big": WEAPONS[weapon_key].has("explode") or int(WEAPONS[weapon_key]["pellets"]) > 1})
	if owner_id == -1:
		shake = maxf(shake, 0.12 if not WEAPONS[weapon_key].has("explode") else 0.35)
	flash_t[owner_id] = Time.get_ticks_msec()
	var w: Dictionary = WEAPONS[weapon_key]
	var snd := "rocket" if w.has("explode") else ("shotgun" if int(w["pellets"]) > 1 else "shot")
	var near := owner_id == -1 or origin.distance_to(player_pos) < 700.0
	if near:
		_play_sfx(snd, 0.0 if owner_id == -1 else -9.0)
	for n in int(w["pellets"]):
		var d := dir.normalized().rotated(randf_range(-w["spread"], w["spread"]))
		var dmg: float = w["damage"]
		if owner_id == -1:
			dmg *= RARITY_MULT[weapon_rar]
			if power_timer > 0.0:
				dmg *= 1.5
		if owner_id >= 0 and weapon_key != "bot":
			dmg *= bot_dmg_mult * RARITY_MULT[int(bots[owner_id].get("rar", 0))]   # Bots treffen schwächer
		bullets.append({
			"pos": origin + d * (PLAYER_RADIUS + 26.0),
			"vel": d * w["speed"],
			"damage": dmg,
			"life": BULLET_LIFE + (0.6 if w.has("explode") else 0.0),
			"owner": owner_id,
			"explode": w.get("explode", 0.0),
		})

# ---------- Eingaben ----------
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_SHIFT:
		_try_dash()
	elif event.keycode == KEY_E:
		_on_action_button()
	elif event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
		_toggle_pause()
	elif event.keycode == KEY_R and (phase == "over" or phase == "won"):
		get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	# Merkt sich, ob zuletzt Maus oder Touch benutzt wurde (Zielen nur mit Maus)
	if event is InputEventMouseMotion:
		use_mouse_aim = true
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		use_mouse_aim = false

func _can_action() -> bool:
	return false   # Häuser werden automatisch betreten, keine Tür-Taste mehr

func _on_action_button() -> void:
	if phase != "play":
		return
	if inside >= 0:
		if player_pos.distance_to(ROOM_DOOR) < DOOR_RANGE + 20.0:
			_exit_house()
	else:
		var idx := _nearest_door()
		if idx >= 0:
			_enter_house(idx)

func _try_dash() -> void:
	if phase != "play":
		return
	if jump_charges > 0 and inside < 0:
		jump_charges -= 1
		jump_timer = 0.6
		_show_message("Sprung!", 0.8)
		return
	if dash_charges <= 0:
		return
	dash_charges -= 1
	for i in 16:
		_step_player(facing * (DASH_DISTANCE / 16.0))

func _read_move_input() -> Vector2:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1
	# Tastatur und Joystick zusammen, maximal volle Geschwindigkeit
	return (dir + touch.move_vec).limit_length(1.0)

func _nearest_enemy_dir() -> Vector2:
	var best := 560.0
	var dir := Vector2.ZERO
	for b in bots:
		if not b["alive"]:
			continue
		var d: float = b["pos"].distance_to(player_pos)
		if d < best:
			best = d
			dir = (b["pos"] - player_pos).normalized()
	return dir

func _wants_fire() -> bool:
	if paused_away:
		return false
	return Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or touch.fire_held

# ---------- Spielschleife ----------
func _process(delta: float) -> void:
	if message_timer > 0.0:
		message_timer -= delta
		if message_timer <= 0.0:
			message = ""

	for p in popups:
		p["t"] += delta
	popups = popups.filter(func(p): return p["t"] < 0.9)
	damage_flash = maxf(0.0, damage_flash - delta)
	hit_marker = maxf(0.0, hit_marker - delta)
	shake = maxf(0.0, shake - delta * 2.2)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 16.0
	for f in flashes:
		f["t"] += delta
	flashes = flashes.filter(func(f): return f["t"] < 0.07)
	for fb in fireballs:
		fb["t"] += delta
	fireballs = fireballs.filter(func(fb): return fb["t"] < 0.55)
	for sp in sparks:
		sp["t"] += delta
		sp["o"] += sp["v"] * delta
		sp["v"] = Vector2(sp["v"].x * 0.93, sp["v"].y + 520.0 * delta)
	sparks = sparks.filter(func(sp): return sp["t"] < sp["life"])
	_update_view()
	match phase:
		"fall":
			_update_fall(delta)
		"play":
			_update_play(delta)

	_update_bullets(delta)
	if minimap:
		minimap.queue_redraw()
	_update_view()
	cam.position = _w(player_pos)
	light.position = _w(player_pos)
	_sync_units3d()
	if fx:
		fx.queue_redraw()
	_update_ui()
	queue_redraw()

func _update_fall(delta: float) -> void:
	var dir := _world_dir(_read_move_input())
	if dir != Vector2.ZERO:
		player_pos += dir.normalized() * FALL_SPEED * delta
		player_pos = player_pos.clamp(Vector2.ONE * PLAYER_RADIUS, MAP_SIZE - Vector2.ONE * PLAYER_RADIUS)
	fall_timer -= delta
	if fall_timer <= 0.0:
		player_pos = _nearest_free(player_pos, PLAYER_RADIUS)
		phase = "play"
		_show_message("Gelandet! Sammle Loot und überlebe!", 2.5)

func _update_play(delta: float) -> void:
	elapsed += delta
	if not tut_done and tut_step < TUT_TEXTS.size() and elapsed > 1.0 + 5.0 * tut_step:
		_show_message(TUT_TEXTS[tut_step], 4.5)
		tut_step += 1
		if tut_step >= TUT_TEXTS.size():
			tut_done = true
			_write_save()
	zone_radius = lerpf(ZONE_START_RADIUS, ZONE_END_RADIUS, clampf(elapsed / zone_time, 0.0, 1.0))

	# Bewegen (Joystick/Tasten sind Bildschirm-Richtungen)
	var dir := _world_dir(_read_move_input())
	if paused_away:
		dir = Vector2.ZERO
	player_moving = dir != Vector2.ZERO
	if dir != Vector2.ZERO:
		var speed := BASE_SPEED * (BOARD_SPEED_MULT if board_timer > 0.0 else 1.0) * (1.4 if speed_timer > 0.0 else 1.0)
		_step_player(dir.normalized() * speed * delta)

	# Zielen: Waffe zeigt zur Maus (wenn die Maus im Fenster ist), sonst in Laufrichtung
	var mouse_in_window := Rect2(Vector2.ZERO, get_viewport_rect().size).has_point(get_viewport().get_mouse_position())
	if touch.aim_active:
		# Zielstick: Richtung vom Daumen
		facing = _world_dir(touch.aim_vec).normalized()
	elif touch.fire_held and inside < 0 and _nearest_enemy_dir() != Vector2.ZERO:
		# Nur Feuer gedrückt, nicht gezogen: automatisch auf den nächsten Gegner zielen
		facing = _nearest_enemy_dir()
	elif touch.fire_held and inside < 0:
		pass   # Schießen ohne Gegner: Blickrichtung bleibt, unabhängig von der Laufrichtung
	elif inside < 0 and mouse_in_window and use_mouse_aim:
		var to_mouse := view.affine_inverse() * get_global_mouse_position() - player_pos
		if to_mouse.length() > 8.0:
			facing = to_mouse.normalized()
	elif dir != Vector2.ZERO:
		facing = dir.normalized()

	board_timer = maxf(0.0, board_timer - delta)
	power_timer = maxf(0.0, power_timer - delta)
	speed_timer = maxf(0.0, speed_timer - delta)
	jump_timer = maxf(0.0, jump_timer - delta)
	shoot_cd -= delta

	# Angreifen (Taste halten): mit Munition schießen, sonst Nahkampf
	melee_cd -= delta
	if inside < 0 and _wants_fire():
		if weapon != "" and ammo > 0:
			if shoot_cd <= 0.0:
				_fire(-1, player_pos, facing, weapon)
				shoot_cd = WEAPONS[weapon]["cooldown"]
				ammo -= 1
				if ammo <= 0:
					_show_message("Munition leer! Nahkampf: " + MELEE[melee]["name"], 1.5)
					weapon = ""
		elif melee_cd <= 0.0:
			_melee_attack(-1, player_pos, facing, melee)
			melee_cd = MELEE[melee]["cooldown"]

	# Dash lädt sich alle 8 Sekunden selbst auf (max. 3)
	if dash_charges < MAX_DASH_CHARGES:
		dash_recharge += delta
		if dash_recharge >= 8.0:
			dash_recharge = 0.0
			dash_charges += 1

	# Automatisch rein- und rausgehen, sobald man an der Tür steht
	if inside < 0:
		var door_idx := _door_entered()
		if door_idx >= 0:
			_enter_house(door_idx)
			return
	elif player_pos.distance_to(ROOM_DOOR) < 30.0:
		_exit_house()
		return

	# Loot einsammeln (draußen oder im Haus)
	var items := _current_loot()
	chest_near = false
	for i in range(items.size() - 1, -1, -1):
		var item: Dictionary = items[i]
		if item["pos"].distance_to(player_pos) < PICKUP_RANGE + (10.0 if item["kind"] == "chest" else 0.0):
			if item["kind"] == "chest":
				# Kiste muss ca. 3 Sekunden geöffnet werden (in der Nähe bleiben)
				if chest_item != item:
					chest_item = item
					chest_timer = 0.0
				chest_timer += delta
				chest_near = true
				if chest_timer >= CHEST_OPEN_TIME:
					items.remove_at(i)
					chest_item = {}
					chest_timer = 0.0
					_open_chest(items, item["pos"], int(item["rar"]))
				break
			weapon_rar = int(item.get("rar", 0))
			_apply_loot(item["kind"])
			_play_sfx("power" if item["kind"] in ["shield", "shield_big", "jump", "power", "speed"] else "pickup", -3.0)
			items.remove_at(i)

	if not chest_near:
		chest_item = {}
		chest_timer = 0.0

	# Zone wirkt auf den Spieler (im Haus zählt die Tür)
	var zone_pos := player_pos
	if inside >= 0:
		zone_pos = _door_of(inside)
	if zone_pos.distance_to(ZONE_CENTER) > zone_radius:
		health -= zone_dmg * delta
	if health <= 0.0:
		_player_died()
		return

	# Bots sind eingefroren, solange man im Haus ist
	if inside < 0:
		_update_bots(delta)

func _apply_loot(kind: String) -> void:
	match kind:
		"heal":
			health = minf(100.0, health + 25.0)
		"heal_big":
			health = minf(100.0, health + 60.0)
		"shield_big":
			shield = minf(100.0, shield + 60.0)
		"pistol", "smg", "ak", "minigun", "shotgun", "sniper", "rocket", "revolver", "crossbow", "laser":
			weapon = kind
			ammo = WEAPONS[kind]["ammo"]
		"bat", "pan", "extinguisher", "katana", "hammer":
			melee = kind
		"shield":
			shield = minf(100.0, shield + 25.0)
		"jump":
			jump_charges = mini(3, jump_charges + 1)
		"power":
			power_timer = 8.0
		"speed":
			speed_timer = 8.0
		"board":
			board_timer = BOARD_DURATION
		"dash":
			dash_charges = mini(MAX_DASH_CHARGES, dash_charges + 1)
	if WEAPONS.has(kind):
		_show_message("%s (%s)" % [LOOT_NAMES[kind], RARITY_NAMES[weapon_rar]], 1.4)
	else:
		_show_message(LOOT_NAMES[kind] + " eingesammelt", 1.2)

# Nahkampf: trifft Gegner vor der Figur (Kegel in Blickrichtung)
func _melee_attack(owner_id: int, origin: Vector2, dir: Vector2, kind: String) -> void:
	var m: Dictionary = MELEE[kind]
	var rng: float = m["range"]
	var dmg: float = m["damage"]
	atk_t[owner_id] = Time.get_ticks_msec()
	swings.append({"pos": origin, "dir": dir.normalized(), "t": 0.0})
	if owner_id == -1:
		if power_timer > 0.0:
			dmg *= 1.5
		for i in bots.size():
			var b: Dictionary = bots[i]
			if not b["alive"]:
				continue
			var to_b: Vector2 = b["pos"] - origin
			if to_b.length() < rng + BOT_RADIUS and to_b.normalized().dot(dir.normalized()) > 0.3:
				b["health"] -= dmg
				_popup(b["pos"], dmg, Color(1, 0.95, 0.5))
				_play_sfx("hit", -2.0)
				if b["health"] <= 0.0:
					_kill_bot(i, true)
	else:
		var to_p := player_pos - origin
		if inside < 0 and to_p.length() < rng + PLAYER_RADIUS:
			_damage_player(dmg * 0.6)

func _damage_player(amount: float) -> void:
	if phase != "play":
		return
	damage_flash = 0.35
	shake = maxf(shake, 0.3)
	_popup(player_pos, amount, Color(1, 0.35, 0.3))
	_play_sfx("hit", -4.0)
	if shield > 0.0:
		var absorbed := minf(shield, amount)
		shield -= absorbed
		amount -= absorbed
	health -= amount
	if health <= 0.0:
		_player_died()

func _explode(pos: Vector2, bl: Dictionary) -> void:
	fireballs.append({"pos": pos, "t": 0.0, "r": float(bl["explode"])})
	_spark_burst(pos, Color(1, 0.6, 0.2), 22, 360.0)
	shake = maxf(shake, 0.6 if pos.distance_to(player_pos) < 500.0 else 0.2)
	var radius: float = bl["explode"]
	explosions.append({"pos": pos, "t": 0.0, "r": radius})
	_play_sfx("explosion", -2.0)
	for i in bots.size():
		var b: Dictionary = bots[i]
		if b["alive"] and b["pos"].distance_to(pos) < radius + BOT_RADIUS:
			b["health"] -= bl["damage"]
			if b["health"] <= 0.0:
				_kill_bot(i, bl["owner"] == -1)
	if bl["owner"] != -1 and inside < 0 and player_pos.distance_to(pos) < radius + PLAYER_RADIUS:
		_damage_player(bl["damage"] * 0.6)

func _player_died() -> void:
	health = 0.0
	phase = "over"
	placement = _living_bots() + 1
	_show_message("", 0.0)
	var xp_msg := _award_xp()
	_show_end_menu("PLATZ %d VON %d   %s" % [placement, bots.size() + 1, xp_msg])

func _update_bots(delta: float) -> void:
	for i in bots.size():
		var b: Dictionary = bots[i]
		if not b["alive"]:
			continue
		b["think"] -= delta
		b["cd"] -= delta
		var to_player: Vector2 = player_pos - b["pos"]
		var dist := to_player.length()
		var step := Vector2.ZERO

		if b["pos"].distance_to(ZONE_CENTER) > zone_radius:
			# außerhalb der Zone: zurück zur Mitte
			step = ZONE_CENTER - b["pos"]
		elif dist < 280.0 and elapsed > 10.0 and MELEE.has(b["weapon"]):
			# Nur Nahkampf: direkt auf den Spieler zu
			step = to_player
			if b["cd"] <= 0.0 and dist < MELEE[b["weapon"]]["range"] + PLAYER_RADIUS:
				_melee_attack(i, b["pos"], to_player, b["weapon"])
				b["cd"] = randf_range(0.7, 1.1)
		elif dist < 520.0 and elapsed > 10.0 and not MELEE.has(b["weapon"]):
			# Spieler gesehen: angreifen oder seitlich ausweichen
			if dist > 320.0:
				step = to_player
			else:
				step = to_player.rotated(PI / 2.0) * 0.7
			if b["cd"] <= 0.0 and dist < 480.0:
				var aim := to_player.normalized().rotated(randf_range(-0.15, 0.15))
				_fire(i, b["pos"], aim, b["weapon"])
				b["cd"] = randf_range(1.2, 2.0) * bot_cd_mult
		else:
			# ohne Waffe: zur nächsten Waffe laufen, sonst ziellos herumlaufen
			var target := -1
			if MELEE.has(b["weapon"]):
				var best := 420.0
				for li in loot.size():
					var it: Dictionary = loot[li]
					if WEAPONS.has(it["kind"]):
						var dl: float = it["pos"].distance_to(b["pos"])
						if dl < best:
							best = dl
							target = li
			if target >= 0:
				var it2: Dictionary = loot[target]
				step = it2["pos"] - b["pos"]
				if it2["pos"].distance_to(b["pos"]) < PICKUP_RANGE:
					b["weapon"] = it2["kind"]
					b["rar"] = int(it2.get("rar", 0))
					b["gun"] = tex_guns.get(it2["kind"], null)
					loot.remove_at(target)
			else:
				if b["think"] <= 0.0:
					b["dir"] = Vector2.from_angle(randf() * TAU)
					b["think"] = randf_range(1.0, 3.0)
				step = b["dir"]

		if dist < 520.0 and phase == "play":
			b["aim"] = to_player.normalized()
		elif step != Vector2.ZERO:
			b["aim"] = step.normalized()
		b["moving"] = step != Vector2.ZERO
		if step != Vector2.ZERO:
			b["pos"] = _move(b["pos"], step.normalized() * BOT_SPEED * delta, BOT_RADIUS)

		if b["pos"].distance_to(ZONE_CENTER) > zone_radius:
			b["health"] -= ZONE_DAMAGE_PER_SEC * delta * (1.0 + 5.0 * clampf(elapsed / zone_time, 0.0, 1.0))
			if b["health"] <= 0.0:
				_kill_bot(i)

func _spark_burst(pos: Vector2, col: Color, n: int, speed: float) -> void:
	for i in n:
		var a := randf() * TAU
		sparks.append({"pos": pos, "o": Vector2(0, -26), "v": Vector2.from_angle(a) * randf_range(0.3, 1.0) * speed + Vector2(0, -120), "t": 0.0, "life": randf_range(0.25, 0.5), "col": col})

func _popup(pos: Vector2, amount: float, col: Color) -> void:
	_spark_burst(pos, col, 6, 150.0)
	if col.g > 0.9:
		hit_marker = 0.18
	popups.append({"pos": pos, "text": str(int(round(amount))), "t": 0.0, "col": col})

func _kill_bot(i: int, by_player := false) -> void:
	if not bots[i]["alive"]:
		return
	bots[i]["alive"] = false
	bots[i]["dead_at"] = Time.get_ticks_msec()
	_spark_burst(bots[i]["pos"], Color(1, 1, 1), 16, 260.0)
	if by_player:
		kills += 1
		_show_message("Gegner erledigt! (%d)" % kills, 1.2)
		kill_feed.append({"text": "DU  ›  %s" % str(bots[i].get("skin", "Gegner")).replace("char_", "").capitalize(), "t": 0.0})
		if kill_feed.size() > 4:
			kill_feed.pop_front()
	if phase == "play" and _living_bots() == 0:
		phase = "won"
		placement = 1
		_show_message("", 0.0)
		var xp_msg := _award_xp()
		_show_end_menu("SIEG! #1   " + xp_msg)

func _update_bullets(delta: float) -> void:
	for kf in kill_feed:
		kf["t"] += delta
	kill_feed = kill_feed.filter(func(e): return e["t"] < 5.0)
	for ex in explosions:
		ex["t"] += delta
	explosions = explosions.filter(func(e): return e["t"] < 0.4)
	for sw in swings:
		sw["t"] += delta
	swings = swings.filter(func(e): return e["t"] < 0.18)
	for bi in range(bullets.size() - 1, -1, -1):
		var bl: Dictionary = bullets[bi]
		bl["pos"] += bl["vel"] * delta
		bl["life"] -= delta
		var explodes: bool = bl["explode"] > 0.0
		if bl["life"] <= 0.0 or _bullet_blocked(bl["pos"]):
			if explodes:
				_explode(bl["pos"], bl)
			bullets.remove_at(bi)
			continue

		var hit := false
		if bl["owner"] == -1:
			for i in bots.size():
				var b: Dictionary = bots[i]
				if b["alive"] and b["pos"].distance_to(bl["pos"]) < BOT_RADIUS:
					hit = true
					if not explodes:
						b["health"] -= bl["damage"]
						_popup(b["pos"], bl["damage"], Color(1, 0.95, 0.5))
						if b["health"] <= 0.0:
							_kill_bot(i, true)
					break
		elif phase == "play" and inside < 0 and player_pos.distance_to(bl["pos"]) < PLAYER_RADIUS:
			_damage_player(bl["damage"])
			hit = true
		if hit:
			if explodes:
				_explode(bl["pos"], bl)
			bullets.remove_at(bi)

func _update_ui() -> void:
	if phase == "fall":
		hud.text = "Fallschirm… Landung in %d s" % int(ceil(fall_timer))
	else:
		var weapon_text: String = MELEE[melee]["name"]
		if weapon != "":
			weapon_text = "%s %s (%d)" % [WEAPONS[weapon]["name"], RARITY_NAMES[weapon_rar], ammo]
		hud.text = "Leben: %d  |  Schild: %d  |  Sprung: %d  |  Dash: %d\nWaffe: %s  |  Übrig: %d  |  Kills: %d" % [
			int(health), int(shield), jump_charges, dash_charges, weapon_text, _living_bots() + 1, kills]
		if power_timer > 0.0:
			hud.text += "  |  Power %d s" % int(ceil(power_timer))
		if speed_timer > 0.0:
			hud.text += "  |  Speed %d s" % int(ceil(speed_timer))
	touch.set_action_visible(_can_action())
	center_label.text = message

# ---------- Zeichnen ----------
# Bodenflächen werden mit der Kamera-Transformation gezeichnet (gedreht + geneigt),
# alles mit Höhe (Häuser, Bäume, Figuren, Loot) aufrecht an der umgerechneten Position.
func _draw() -> void:
	if inside >= 0:
		_draw_interior()
	else:
		_draw_outdoor()

func _draw_outdoor() -> void:
	var t_now := Time.get_ticks_msec() / 1000.0

	# ----- Boden (flach, mit Transformation) -----
	draw_set_transform_matrix(view)
	draw_rect(Rect2(-2500, -2500, MAP_SIZE.x + 5000, MAP_SIZE.y + 5000), [Color(0.22, 0.5, 0.72), Color(0.15, 0.6, 0.65), Color(0.35, 0.55, 0.75)][map_theme])
	# Wasser: animierte Wellenringe und Schaum am Strand
	for w in 5:
		var off := 120.0 + w * 150.0 + sin(t_now * 0.8 + w * 1.7) * 26.0
		draw_rect(Rect2(-60 - off, -60 - off, MAP_SIZE.x + 120 + off * 2.0, MAP_SIZE.y + 120 + off * 2.0), Color(1, 1, 1, 0.07), false, 6.0)
	draw_rect(Rect2(-60, -60, MAP_SIZE.x + 120, MAP_SIZE.y + 120).grow(40.0 + sin(t_now * 1.6) * 14.0), Color(0.75, 0.92, 1, 0.5), false, 10.0)
	draw_rect(Rect2(-60, -60, MAP_SIZE.x + 120, MAP_SIZE.y + 120).grow(14.0), Color(0.85, 0.75, 0.5), false, 22.0)
	draw_rect(Rect2(-60, -60, MAP_SIZE.x + 120, MAP_SIZE.y + 120), Color(0.93, 0.85, 0.62))
	if map_theme == 1:
		draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.9, 0.76, 0.46))
	elif map_theme == 2:
		draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.92, 0.95, 0.99))
	elif tex_grass:
		draw_texture_rect(tex_grass, Rect2(Vector2.ZERO, MAP_SIZE), true)
	else:
		draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.56, 0.84, 0.46))

	# Gras-Variation: weiche helle und dunkle Flecken
	if grass_blobs.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for k in 160:
			grass_blobs.append([Vector2(rng.randf() * MAP_SIZE.x, rng.randf() * MAP_SIZE.y), rng.randf_range(60, 190), rng.randf() < 0.5])
	for gb in grass_blobs:
		var gc := Color(0.75, 1, 0.5, 0.10) if gb[2] else Color(0.1, 0.4, 0.2, 0.10)
		if map_theme == 1:
			gc = Color(1, 0.9, 0.6, 0.18) if gb[2] else Color(0.75, 0.5, 0.2, 0.16)
		elif map_theme == 2:
			gc = Color(1, 1, 1, 0.5) if gb[2] else Color(0.65, 0.78, 0.95, 0.22)
		draw_circle(gb[0], gb[1], gc)
		draw_circle(gb[0], gb[1] * 0.6, gc)

	# Straßen: Bürgersteig, Asphalt, Mittelstreifen
	for road in ROADS:
		draw_rect(road.grow(16), Color(0.78, 0.78, 0.8))
	for road in ROADS:
		if tex_asphalt:
			draw_texture_rect(tex_asphalt, road, true)
		else:
			draw_rect(road, Color(0.32, 0.33, 0.37))
	for road in ROADS:
		if road.size.x > road.size.y:
			var cy: float = road.get_center().y
			for x in range(int(road.position.x), int(road.end.x), 90):
				draw_rect(Rect2(x, cy - 4, 45, 8), Color(1, 1, 1, 0.75))
		else:
			var cx: float = road.get_center().x
			for y in range(int(road.position.y), int(road.end.y), 90):
				draw_rect(Rect2(cx - 4, y, 8, 45), Color(1, 1, 1, 0.75))

	# Deko am Boden (Blumen, Steine, Büsche)
	for dd in decor_list:
		var sz: Vector2 = dd["size"]
		draw_texture_rect(dd["tex"], Rect2(dd["pos"] - sz / 2.0, sz), false)

	# Wolkenschatten ziehen langsam über die Karte
	for ci in 7:
		var cx := fposmod(float(ci) * 677.0 + t_now * 24.0, MAP_SIZE.x + 800.0) - 400.0
		var cy := fposmod(float(ci) * 431.0 + t_now * 9.0 + sin(float(ci)) * 300.0, MAP_SIZE.y + 600.0) - 300.0
		for part in 4:
			draw_circle(Vector2(cx + part * 110.0 - 160.0, cy + sin(float(part + ci)) * 50.0), 150.0 - part * 12.0, Color(0.05, 0.1, 0.2, 0.045))

	# Schatten von Häusern und Bäumen
	for r in obstacles:
		draw_rect(Rect2(r.position + Vector2(26, 26), r.size), Color(0, 0, 0, 0.22))
	for t in trees:
		draw_circle(t + Vector2(16, 16), TREE_RADIUS * 1.2, Color(0, 0, 0, 0.2))

	# Ringe unter dem Loot
	for item in loot:
		var col := _ring_color(item)
		var rad := 40.0 if item["kind"] == "chest" else 30.0
		draw_circle(item["pos"], rad, Color(col.r, col.g, col.b, 0.22))
		draw_arc(item["pos"], rad, 0.0, TAU, 40, col.lightened(0.3), 4.0)

	# Explosionen liegen flach am Boden
	for ex in explosions:
		var k: float = ex["t"] / 0.4
		var rr: float = ex["r"] * (0.4 + 0.6 * k)
		draw_circle(ex["pos"], rr, Color(1, 0.55, 0.1, 0.55 * (1.0 - k)))
		draw_circle(ex["pos"], rr * 0.6, Color(1, 0.9, 0.5, 0.7 * (1.0 - k)))
	draw_set_transform_matrix(Transform2D.IDENTITY)

	# ----- Alles mit Höhe, nach Bildschirm-Tiefe sortiert -----
	var order: Array = []
	if units3d == null:
		for i in obstacles.size():
			order.append([_house_depth(i), 0, i])
		for i in trees.size():
			order.append([_w(trees[i]).y, 1, i])
	if units3d == null:
		for i in loot.size():
			order.append([_w(loot[i]["pos"]).y - 1.0, 4, i])
	for i in bots.size():
		if bots[i]["alive"]:
			order.append([_w(bots[i]["pos"]).y, 2, i])
	if phase != "fall":
		order.append([_w(player_pos).y, 3, 0])
	order.sort_custom(func(a, b): return a[0] < b[0])
	for e in order:
		match e[1]:
			0:
				_draw_house(e[2])
			1:
				_draw_tree(e[2])
			2:
				var b: Dictionary = bots[e[2]]
				var bp := _w(b["pos"])
				_draw_unit(bp, b["tex"], b["gun"], _screen_dir(b["aim"]), b.get("moving", false), float(e[2]) * 0.37)
			3:
				_draw_player()
			4:
				var it: Dictionary = loot[e[2]]
				_draw_loot_item(_w(it["pos"]), it["kind"], t_now + float(e[2]), int(it.get("rar", 0)))

	# ----- Feuerzone über allem (flach, mit Transformation) -----
	draw_set_transform_matrix(view)
	_draw_zone()
	draw_set_transform_matrix(Transform2D.IDENTITY)

	_draw_swings()
	_draw_chest_progress()

	if phase == "fall":
		_draw_fall()

func _ring_color(item: Dictionary) -> Color:
	var kind: String = item["kind"]
	if kind == "chest" or WEAPONS.has(kind):
		return RARITY_COLORS[int(item.get("rar", 0))]
	return LOOT_COLORS.get(kind, Color.WHITE)

func _draw_chest_progress() -> void:
	if chest_item.is_empty() or chest_timer <= 0.0:
		return
	var p: Vector2 = chest_item["pos"]
	if inside < 0:
		p = _w(p)
	p += Vector2(0, -62)
	var k := clampf(chest_timer / CHEST_OPEN_TIME, 0.0, 1.0)
	var col: Color = RARITY_COLORS[int(chest_item.get("rar", 0))]
	draw_rect(Rect2(p + Vector2(-42, -9), Vector2(84, 18)), OUTLINE)
	draw_rect(Rect2(p + Vector2(-39, -6), Vector2(78, 12)), Color(0.2, 0.2, 0.22))
	draw_rect(Rect2(p + Vector2(-39, -6), Vector2(78.0 * k, 12)), col)
	var f := ThemeDB.fallback_font
	draw_string(f, p + Vector2(-40, -16), "Öffnen…", HORIZONTAL_ALIGNMENT_CENTER, 80, 16, Color(1, 1, 1))

func _draw_swings() -> void:
	for sw in swings:
		var k: float = sw["t"] / 0.18
		var sp := _w(sw["pos"]) + Vector2(0, -24)
		var ang := _screen_dir(sw["dir"]).angle()
		draw_arc(sp, 52.0, ang - 1.0 + k * 0.6, ang + 0.4 + k * 0.6, 16, Color(1, 1, 1, 0.85 * (1.0 - k)), 7.0)

# Bildschirm-Tiefe eines Hauses: unterste Ecke
func _house_depth(i: int) -> float:
	var r: Rect2 = obstacles[i]
	var d := -INF
	for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		d = maxf(d, _w(c).y)
	return d

# Haus als Block: sichtbare Wände, Fenster, Tür, Dach mit Textur
func _draw_house(i: int) -> void:
	var r: Rect2 = obstacles[i]
	var up := Vector2(0, -HOUSE_H)
	var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var sc: Array = []
	for c in corners:
		sc.append(_w(c))
	var center := _w(r.get_center())
	var fade := 1.0
	var ps := _w(player_pos) + Vector2(0, -30)
	if _house_depth(i) > _w(player_pos).y:
		var hull := PackedVector2Array()
		for c in sc:
			hull.append(c)
		for c in sc:
			hull.append(c + up)
		if Geometry2D.convex_hull(hull).size() > 0 and Geometry2D.is_point_in_polygon(ps, Geometry2D.convex_hull(hull)):
			fade = 0.45   # Spieler steht hinter dem Haus
	var wall_cols := [Color(0.96, 0.9, 0.78, fade), Color(0.86, 0.79, 0.66, fade), Color(0.96, 0.9, 0.78, fade), Color(0.86, 0.79, 0.66, fade)]
	for k in 4:
		var a: Vector2 = sc[k]
		var b: Vector2 = sc[(k + 1) % 4]
		if (a + b).y / 2.0 <= center.y:
			continue   # Rückwand, vom Dach verdeckt
		var quad := PackedVector2Array([a, b, b + up, a + up])
		draw_colored_polygon(quad, wall_cols[k])
		draw_colored_polygon(PackedVector2Array([a, b, b + Vector2(0, -8), a + Vector2(0, -8)]), wall_cols[k].darkened(0.2))
		draw_polyline(PackedVector2Array([a, b, b + up, a + up, a]), OUTLINE, 3.0)
		var e := (b - a).normalized()
		# Fenster
		for tt in [0.22, 0.78]:
			var wp: Vector2 = a.lerp(b, tt) + up * 0.6
			var win := PackedVector2Array([wp - e * 11 + Vector2(0, -9), wp + e * 11 + Vector2(0, -9), wp + e * 11 + Vector2(0, 9), wp - e * 11 + Vector2(0, 9)])
			draw_colored_polygon(win, Color(0.55, 0.82, 1.0))
			draw_polyline(PackedVector2Array([win[0], win[1], win[2], win[3], win[0]]), OUTLINE, 2.0)
		# Tür auf der Südseite (Weltkante unten = Ecken 2 -> 3)
		if k == 2:
			var dp := _w(_door_of(i))
			var door := PackedVector2Array([dp - e * 15, dp + e * 15, dp + e * 15 + Vector2(0, -44), dp - e * 15 + Vector2(0, -44)])
			draw_colored_polygon(door, Color(0.45, 0.28, 0.16))
			draw_polyline(PackedVector2Array([door[0], door[1], door[2], door[3], door[0]]), OUTLINE, 2.0)
	# Dach mit Überstand
	var rg := r.grow(8)
	var roof := PackedVector2Array()
	for c in [rg.position, Vector2(rg.end.x, rg.position.y), rg.end, Vector2(rg.position.x, rg.end.y)]:
		roof.append(_w(c) + up)
	if tex_roofs.size() > 0:
		draw_polygon(roof, PackedColorArray([Color(1, 1, 1, fade)]),
			PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]), tex_roofs[i % tex_roofs.size()])
	else:
		draw_colored_polygon(roof, Color(0.8, 0.3, 0.3))
	draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2], roof[3], roof[0]]), OUTLINE, 3.0)

# Baum: Stamm und Krone stehen aufrecht
func _draw_tree(i: int) -> void:
	var p := _w(trees[i])
	var ps := _w(player_pos)
	var a := 1.0
	if p.y > ps.y and absf(p.x - ps.x) < 70.0 and p.y - ps.y < 120.0:
		a = 0.38   # Baum steht vor dem Spieler: durchsichtig
	draw_rect(Rect2(p.x - 7, p.y - 30, 14, 32), Color(0.45, 0.28, 0.16, a))
	if tex_trees.size() > 0:
		draw_texture_rect(tex_trees[i % tex_trees.size()], Rect2(p - Vector2(44, 108), Vector2(88, 88)), false, Color(1, 1, 1, a))
	else:
		draw_circle(p - Vector2(0, 60), TREE_RADIUS + 10, Color(0.22, 0.55, 0.28))

func _draw_interior() -> void:
	# Holzboden mit Dielen
	draw_rect(Rect2(-600, -600, ROOM_SIZE.x + 1200, ROOM_SIZE.y + 1200), Color(0.12, 0.1, 0.12))
	draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), Color(0.72, 0.5, 0.32))
	for x in range(0, int(ROOM_SIZE.x), 70):
		draw_rect(Rect2(x, 0, 2, ROOM_SIZE.y), Color(0.6, 0.4, 0.25))
	# Wände mit Türöffnung unten
	var wall := WALL_COLOR
	draw_rect(Rect2(0, 0, ROOM_SIZE.x, 20), wall)
	draw_rect(Rect2(0, 0, 20, ROOM_SIZE.y), wall)
	draw_rect(Rect2(ROOM_SIZE.x - 20, 0, 20, ROOM_SIZE.y), wall)
	draw_rect(Rect2(0, ROOM_SIZE.y - 20, 300, 20), wall)
	draw_rect(Rect2(400, ROOM_SIZE.y - 20, 300, 20), wall)
	draw_rect(Rect2(0, 0, ROOM_SIZE.x, ROOM_SIZE.y), WALL_EDGE, false, 4.0)
	draw_rect(Rect2(ROOM_DOOR.x - 50, ROOM_SIZE.y - 20, 100, 20), Color(0.45, 0.28, 0.16))
	# Möbel
	draw_rect(Rect2(60, 60, 150, 80), Color(0.85, 0.3, 0.35))
	draw_rect(Rect2(60, 60, 150, 20), Color(1, 0.95, 0.9))
	draw_rect(Rect2(490, 60, 150, 70), Color(0.5, 0.33, 0.2))
	draw_rect(Rect2(270, 230, 160, 70), Color(0.6, 0.4, 0.25))
	# Loot im Raum mit Ring
	var t_now := Time.get_ticks_msec() / 1000.0
	var items := _current_loot()
	for k in items.size():
		var it: Dictionary = items[k]
		var icol := _ring_color(it)
		draw_arc(it["pos"], 34, 0.0, TAU, 40, icol.lightened(0.3), 4.0)
		_draw_loot_item(it["pos"], it["kind"], t_now + k, int(it.get("rar", 0)))
	_draw_player()
	_draw_swings()
	_draw_chest_progress()

func _draw_player() -> void:
	var sp := _w(player_pos)
	var gun_tex: Texture2D = tex_guns.get(weapon, null) if weapon != "" else tex_melee.get(melee, null)
	var lift := Vector2.ZERO
	if jump_timer > 0.0:
		lift = Vector2(0, -sin((0.6 - jump_timer) / 0.6 * PI) * 40.0)
		draw_circle(sp + Vector2(0, 14), 18, Color(0, 0, 0, 0.2))
	if board_timer > 0.0:
		draw_rect(Rect2(sp + Vector2(-26, 14), Vector2(52, 9)), Color(0.6, 0.3, 0.9))
	if power_timer > 0.0:
		draw_circle(sp + lift + Vector2(0, -38), 46, Color(1, 0.85, 0.2, 0.22))
	if speed_timer > 0.0:
		draw_arc(sp + lift + Vector2(0, 8), 30, 0.0, TAU, 32, Color(0.4, 1, 0.4, 0.6), 3.0)
	# Zielanzeige (Streubereich der Waffe), solange Feuer gehalten wird
	if touch != null and touch.visible and _wants_fire() and phase == "play" and inside < 0:
		_draw_aim_area()
	# Blauer Ring am Boden zeigt den Spieler
	draw_arc(sp + Vector2(0, 14), 26, 0.0, TAU, 32, Color(0.25, 0.55, 1.0, 0.9), 4.0)
	_draw_unit(sp + lift, tex_player, gun_tex, _screen_dir(facing), player_moving)
	if shield > 0.0:
		draw_arc(sp + lift + Vector2(0, -40), 50, 0.0, TAU * (shield / 100.0), 48, Color(0.35, 0.65, 1.0, 0.9), 5.0)

# Zeigt den Wirkungsbereich: Linie (Pistole, Sniper, Rakete) oder Keil (AK, Uzi, Minigun, Pumpgun)
func _draw_aim_area() -> void:
	var col := Color(1, 0.35, 0.3)
	var reach := 480.0
	var half := 0.0
	var is_rocket := false
	if weapon != "" and ammo > 0:
		var w: Dictionary = WEAPONS[weapon]
		half = float(w["spread"])
		reach = clampf(float(w["speed"]) * 0.55, 330.0, 640.0)
		if weapon == "sniper":
			reach = 760.0
		is_rocket = w.has("explode")
		col = RARITY_COLORS[weapon_rar].lerp(Color(1, 0.4, 0.3), 0.5)
	else:
		reach = float(MELEE[melee]["range"]) + 14.0
		half = 0.7
	draw_set_transform_matrix(view)
	var o := player_pos
	var d := facing.normalized()
	if half < 0.04:
		# Eine Linie
		var e := o + d * reach
		draw_line(o, e, Color(col.r, col.g, col.b, 0.35), 20.0)
		draw_line(o, e, Color(1, 1, 1, 0.55), 5.0)
		if is_rocket:
			draw_arc(e, 95.0, 0.0, TAU, 40, Color(1, 0.5, 0.2, 0.7), 5.0)
			draw_circle(e, 95.0, Color(1, 0.5, 0.2, 0.18))
	else:
		# Keil mit dem Streuwinkel der Waffe
		var pts := PackedVector2Array([o])
		var steps := 14
		for i in steps + 1:
			var a := -half + 2.0 * half * float(i) / float(steps)
			pts.append(o + d.rotated(a) * reach)
		draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.34))
		draw_polyline(PackedVector2Array([pts[1], o, pts[pts.size() - 1]]), Color(1, 1, 1, 0.6), 4.0)
		draw_line(o, o + d * reach, Color(1, 1, 1, 0.3), 3.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)

func _draw_fall() -> void:
	var sp := _w(player_pos)
	draw_circle(sp, 22, Color(0, 0, 0, 0.25))
	var height := Vector2(0, -110)
	var canopy_center := sp + height + Vector2(0, -60)
	draw_line(canopy_center + Vector2(-40, 0), sp + height + Vector2(-10, -30), OUTLINE, 2.0)
	draw_line(canopy_center + Vector2(40, 0), sp + height + Vector2(10, -30), OUTLINE, 2.0)
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + (PI * i / 16.0)
		pts.append(canopy_center + Vector2.from_angle(a) * 50.0)
	draw_colored_polygon(pts, Color(1, 0.6, 0.2))
	draw_line(canopy_center, canopy_center + Vector2(0, -50), Color(1, 0.95, 0.8), 6.0)
	_draw_unit(sp + height, tex_player, null, Vector2.DOWN)

func _draw_zone() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var seg := 96
	var outer := 4200.0
	for k in seg:
		var a0 := TAU * k / seg
		var a1 := TAU * (k + 1) / seg
		var flick := 0.5 + 0.5 * sin(t * 5.0 + a0 * 7.0) * cos(t * 2.3 + a0 * 3.0)
		var alpha := 0.28 + 0.12 * flick
		var inner0 := ZONE_CENTER + Vector2.from_angle(a0) * zone_radius
		var inner1 := ZONE_CENTER + Vector2.from_angle(a1) * zone_radius
		var outer0 := ZONE_CENTER + Vector2.from_angle(a0) * outer
		var outer1 := ZONE_CENTER + Vector2.from_angle(a1) * outer
		draw_colored_polygon(PackedVector2Array([inner0, inner1, outer1, outer0]),
			Color(1.0, 0.35 + 0.1 * flick, 0.05, alpha))
	var edge_flick := 0.6 + 0.4 * sin(t * 9.0)
	draw_arc(ZONE_CENTER, zone_radius, 0.0, TAU, 160, Color(1.0, 0.55, 0.1, 0.55 * edge_flick), 26.0)
	draw_arc(ZONE_CENTER, zone_radius, 0.0, TAU, 160, Color(1.0, 0.92, 0.5, 0.6 * edge_flick), 8.0)

# Figur steht aufrecht und schaut zur Kamera, nur die Waffe dreht sich (aim in Bildschirm-Richtung)
func _draw_unit(p: Vector2, body_tex: Texture2D, gun_tex: Texture2D, aim: Vector2, moving := false, seed := 0.0) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(p + Vector2(0, 4), 20, Color(0, 0, 0, 0.28))
	if units3d != null:
		return
	if body_tex == null:
		_draw_chibi(p, Color(0.2, 0.5, 0.9))
		return
	# Laufanimation: Wippen und leichtes Schwanken; im Stand nur Atmen
	var t := Time.get_ticks_msec() / 1000.0 + seed
	var bob := 0.0
	var tilt := 0.0
	if moving:
		bob = absf(sin(t * 12.0)) * 6.0
		tilt = sin(t * 12.0) * 0.07
	else:
		bob = sin(t * 2.2) * 1.2
	var size := body_tex.get_size() * 0.72
	var flip := -1.0 if aim.x < -0.1 else 1.0
	var gun_behind := aim.y < -0.3
	var hand := p + Vector2(0, -22 - bob)
	if gun_tex and gun_behind:
		_draw_gun(hand, gun_tex, aim)
	draw_set_transform(p + Vector2(0, -bob), tilt, Vector2(flip, 1.0))
	draw_texture_rect(body_tex, Rect2(Vector2(-size.x / 2.0, -size.y + 6.0), size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if gun_tex and not gun_behind:
		_draw_gun(hand, gun_tex, aim)

func _draw_gun(hand: Vector2, gun_tex: Texture2D, aim: Vector2) -> void:
	var gsize := gun_tex.get_size() * 0.85
	draw_set_transform(hand + aim * 24.0, aim.angle() + PI / 2.0, Vector2.ONE)
	draw_texture_rect(gun_tex, Rect2(-gsize / 2.0, gsize), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_loot_item(p: Vector2, kind: String, phase_t := 0.0, rar := 0) -> void:
	if kind == "chest" and tex_chests.size() == 4:
		var ct: Texture2D = tex_chests[rar]
		var csz := ct.get_size() * 1.1
		draw_texture_rect(ct, Rect2(p + Vector2(-csz.x / 2.0, -csz.y + 12.0), csz), false)
		if rar == 3:
			draw_circle(p + Vector2(0, -30), 36, Color(1, 0.85, 0.3, 0.12 + 0.08 * sin(phase_t * 4.0)))
		return
	var bob := Vector2(0, -22 - 4.0 * sin(phase_t * 3.0))
	if tex_melee.has(kind):
		var mtex: Texture2D = tex_melee[kind]
		var ms := mtex.get_size() * 0.8
		draw_set_transform(p + bob, PI / 2.0, Vector2.ONE)
		draw_texture_rect(mtex, Rect2(-ms / 2.0, ms), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	if tex_loot.has(kind):
		var t: Texture2D = tex_loot[kind]
		var sz := t.get_size()
		if sz.x > 56:
			sz *= 48.0 / sz.x
		draw_texture_rect(t, Rect2(p + bob - sz / 2.0, sz), false)
		return
	if tex_guns.has(kind):
		var gt: Texture2D = tex_guns[kind]
		var gs := gt.get_size() * 0.8
		draw_set_transform(p + bob, PI / 2.0, Vector2.ONE)
		draw_texture_rect(gt, Rect2(-gs / 2.0, gs), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var col: Color = LOOT_COLORS[kind]
	draw_rect(Rect2(p + bob - Vector2(12, 12), Vector2(24, 24)), col)

func _draw_chibi(p: Vector2, body: Color) -> void:
	# Fallback ohne Grafik: gezeichnete Chibi-Figur
	draw_circle(p + Vector2(0, 12), 19, OUTLINE)
	draw_circle(p + Vector2(0, 12), 17, body)
	draw_circle(p + Vector2(0, -10), 24, OUTLINE)
	draw_circle(p + Vector2(0, -12), 21, HAIR)
	draw_circle(p + Vector2(0, -6), 17, SKIN)
	draw_circle(p + Vector2(-7, -4), 3.5, OUTLINE)
	draw_circle(p + Vector2(7, -4), 3.5, OUTLINE)

func _draw_health_bar(p: Vector2, hp: float) -> void:
	var w := 44.0
	var ratio := clampf(hp / 100.0, 0.0, 1.0)
	var top := p + Vector2(-w / 2.0, -132 if units3d != null else -98)
	draw_rect(Rect2(top - Vector2(2, 2), Vector2(w + 4, 10)), OUTLINE)
	draw_rect(Rect2(top, Vector2(w, 6)), Color(0.25, 0.25, 0.25))
	draw_rect(Rect2(top, Vector2(w * ratio, 6)), Color(0.3, 0.9, 0.3))


# ---------- 3D-Welt und Figuren ----------
func _sync_units3d() -> void:
	if units3d == null:
		return
	var now := Time.get_ticks_msec()
	var vsize := get_viewport_rect().size
	var cam_center: Vector2 = cam.get_screen_center_position()
	var outdoor := inside < 0
	units3d.zoom = ZOOM
	units3d.set_mode(outdoor, view.affine_inverse() * cam_center)
	if menu_layer != null and menu_layer.visible and phase in ["menu", "over", "won"]:
		# Menü: zwei Figuren links und rechts
		units3d.layer.layer = 7
		units3d.zoom = 1.0
		units3d.set_mode(false, Vector2.ZERO)
		units3d.begin_frame()
		var tt := Time.get_ticks_msec() / 1000.0
		units3d.update_unit("hero1", {"skin": save_skin, "screen": Vector2(vsize.x * 0.5 - 520.0 if vsize.x < 1500.0 else vsize.x * 0.17, vsize.y * 0.88), "aim": Vector2(sin(tt * 0.8) * 0.6, 1.0),
			"weapon": "ak", "alive": true, "scale": 2.6})
		units3d.update_unit("hero2", {"skin": "char_red", "screen": Vector2(vsize.x * 0.5 + 520.0 if vsize.x < 1500.0 else vsize.x * 0.83, vsize.y * 0.88), "aim": Vector2(-sin(tt * 0.7) * 0.6, 1.0),
			"weapon": "shotgun", "alive": true, "scale": 2.6})
		units3d.end_frame()
		return
	units3d.layer.layer = 1
	units3d.begin_frame()
	if phase != "menu":
		var lift := 0.0
		if jump_timer > 0.0:
			lift = sin((0.6 - jump_timer) / 0.6 * PI) * 40.0
		var wk: String = weapon if weapon != "" else melee
		var falling := phase == "fall"
		if falling:
			lift = 110.0
		units3d.update_unit("player", {
			"skin": save_skin, "screen": (_w(player_pos) - cam_center) * ZOOM + vsize * 0.5 + (Vector2(0, -110 * ZOOM) if falling else Vector2.ZERO), "scale": ZOOM,
			"world": player_pos, "aimw": facing if not falling else Vector2(0, 1),
			"lift": lift, "aim": _screen_dir(facing) if not falling else Vector2.DOWN,
			"moving": player_moving, "fast": board_timer > 0.0 or speed_timer > 0.0, "weapon": wk,
			"firing": now - int(flash_t.get(-1, -9999)) < 260,
			"attacking": now - int(atk_t.get(-1, -9999)) < 260,
			"jumping": jump_timer > 0.0, "falling": falling, "alive": phase != "over" or health > 0.0,
			"visible": true,
		})
		if outdoor:
			for i in bots.size():
				var b: Dictionary = bots[i]
				if not b["alive"]:
					if now - int(b.get("dead_at", -99999)) < 1800:
						units3d.update_unit("bot%d" % i, {"skin": b["skin"], "world": b["pos"], "aimw": b["aim"], "weapon": "", "alive": false, "visible": true})
					continue
				units3d.update_unit("bot%d" % i, {
					"skin": b["skin"], "world": b["pos"], "aimw": b["aim"], "moving": b.get("moving", false),
					"weapon": b["weapon"], "firing": now - int(flash_t.get(i, -9999)) < 260,
					"attacking": now - int(atk_t.get(i, -9999)) < 260, "alive": true, "visible": true,
				})
	units3d.end_frame()
	units3d.update_fades(player_pos)
	# Loot als 3D-Objekte (nur in der Nähe der Kamera)
	units3d.begin_loot()
	if outdoor and phase != "menu":
		var tn := Time.get_ticks_msec() / 1000.0
		var wc: Vector2 = view.affine_inverse() * cam_center
		for it in loot:
			if not it.has("id"):
				next_loot_id += 1
				it["id"] = next_loot_id
			if it["pos"].distance_to(wc) > 1000.0:
				continue
			var ok := 0.0
			if it["kind"] == "chest" and not chest_item.is_empty() and chest_item.get("id", -1) == it["id"]:
				ok = clampf(chest_timer / CHEST_OPEN_TIME, 0.0, 1.0)
			units3d.update_loot(int(it["id"]), it["pos"], it["kind"], int(it.get("rar", 0)), tn, ok)
	units3d.end_loot()
