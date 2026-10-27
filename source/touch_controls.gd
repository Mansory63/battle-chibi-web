extends CanvasLayer

# Bildschirm-Steuerung im Querformat (Layout passt sich an die Bildschirmbreite an).
# Links: Joystick (erscheint dort, wo der Daumen aufsetzt). Rechts: Ziel-/Feuer-Stick:
# Daumen drauf = schießen, Daumen ziehen = zielen. Daneben: Fähigkeit (Blitz). Oben: Pause.
# Funktioniert mit Touch und mit Maus am PC.

signal ability_pressed
@warning_ignore("unused_signal")
signal action_pressed
signal pause_pressed

const JOY_RADIUS := 100.0
const FIRE_RADIUS := 100.0
const ABILITY_RADIUS := 56.0
const PAUSE_RADIUS := 30.0
const AIM_DEADZONE := 0.28
const MARGIN := 48.0
const NO_ID := -99
const MOUSE_ID := -2

var move_vec := Vector2.ZERO
var fire_held := false
var aim_vec := Vector2.ZERO        # Zielrichtung in Bildschirm-Richtung (Länge 0..1)
var aim_active := false            # Daumen wurde über die Totzone hinaus gezogen
var action_visible := false
var sprint_held := false
var sprint_energy := 1.0
var sprint_locked := false
var _sprint_id := NO_ID
var size := Vector2(1280, 720)
var _joy_id := NO_ID
var _fire_id := NO_ID
var _joy_center := Vector2.ZERO
var _fire_c := Vector2.ZERO
var _knob := Vector2.ZERO
var _view: Control

func _ready() -> void:
	layer = 3
	_view = Control.new()
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_view)
	_view.draw.connect(_draw_controls)
	_update_size()
	_joy_center = _joy_home()

func _update_size() -> void:
	size = get_viewport().get_visible_rect().size

func _joy_home() -> Vector2:
	return Vector2(MARGIN + JOY_RADIUS + 10.0, size.y - MARGIN - JOY_RADIUS)

func _fire_home() -> Vector2:
	return Vector2(size.x - MARGIN - FIRE_RADIUS - 10.0, size.y - MARGIN - FIRE_RADIUS)

func _fire_center() -> Vector2:
	return _fire_c if _fire_id != NO_ID else _fire_home()

func _ability_center() -> Vector2:
	return _fire_home() + Vector2(-FIRE_RADIUS - ABILITY_RADIUS - 8.0, 30.0)

func _sprint_center() -> Vector2:
	return _ability_center() + Vector2(0, -ABILITY_RADIUS * 2.0 - 14.0)

func _pause_center() -> Vector2:
	return Vector2(size.x * 0.5, 14.0 + PAUSE_RADIUS)

func _process(_delta: float) -> void:
	_update_size()
	if _joy_id == NO_ID:
		_joy_center = _joy_home()
	_view.queue_redraw()

func set_action_visible(v: bool) -> void:
	action_visible = v

func _draw_controls() -> void:
	var v := _view
	var fc := _fire_center()
	var ac := _ability_center()
	# Joystick
	v.draw_circle(_joy_center, JOY_RADIUS, Color(1, 1, 1, 0.14))
	v.draw_arc(_joy_center, JOY_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.5), 4.0)
	v.draw_circle(_joy_center + _knob, 42.0, Color(1, 1, 1, 0.5))
	# Ziel-/Feuer-Stick
	v.draw_circle(fc, FIRE_RADIUS, Color(1, 0.35, 0.3, 0.55 if fire_held else 0.34))
	v.draw_arc(fc, FIRE_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.65), 4.0)
	if fire_held:
		v.draw_circle(fc + aim_vec * FIRE_RADIUS * 0.7, 36.0, Color(1, 0.9, 0.85, 0.75))
	else:
		v.draw_string(ThemeDB.fallback_font, fc + Vector2(-80, 10), "FIRE", HORIZONTAL_ALIGNMENT_CENTER, 160, 26, Color(1, 1, 1, 0.95))
	# Fähigkeit: nur Symbol (Blitz)
	v.draw_circle(ac, ABILITY_RADIUS, Color(0.3, 0.9, 1.0, 0.4))
	v.draw_arc(ac, ABILITY_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.65), 4.0)
	var bolt := PackedVector2Array([
		ac + Vector2(6, -28), ac + Vector2(-14, 4), ac + Vector2(-1, 4),
		ac + Vector2(-6, 28), ac + Vector2(14, -4), ac + Vector2(1, -4),
	])
	v.draw_colored_polygon(bolt, Color(1, 0.95, 0.4, 0.95))
	# Sprint (hält gedrückt, lädt sich wieder auf)
	var sc := _sprint_center()
	var scol := Color(1, 0.6, 0.2, 0.6 if sprint_held else 0.38) if not sprint_locked else Color(0.5, 0.5, 0.55, 0.35)
	v.draw_circle(sc, ABILITY_RADIUS, scol)
	v.draw_arc(sc, ABILITY_RADIUS + 5.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(sprint_energy, 0.0, 1.0), 48, Color(0.5, 1, 0.5, 0.9) if not sprint_locked else Color(1, 0.4, 0.3, 0.9), 6.0)
	v.draw_arc(sc, ABILITY_RADIUS, 0.0, TAU, 64, Color(1, 1, 1, 0.65), 3.0)
	for i in 3:
		var o := Vector2(-14 + i * 14, 0)
		v.draw_colored_polygon(PackedVector2Array([sc + o + Vector2(-8, -18), sc + o + Vector2(6, 0), sc + o + Vector2(-8, 18), sc + o + Vector2(-2, 0)]), Color(1, 0.95, 0.8, 0.95))
	# Pause (zwei Balken)
	var pc := _pause_center()
	v.draw_circle(pc, PAUSE_RADIUS, Color(0, 0, 0, 0.35))
	v.draw_arc(pc, PAUSE_RADIUS, 0.0, TAU, 40, Color(1, 1, 1, 0.7), 3.0)
	v.draw_rect(Rect2(pc + Vector2(-9, -12), Vector2(6, 24)), Color(1, 1, 1, 0.9))
	v.draw_rect(Rect2(pc + Vector2(3, -12), Vector2(6, 24)), Color(1, 1, 1, 0.9))

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		_handle_press(event.position, event.pressed, event.index)
	elif event is InputEventScreenDrag:
		_handle_move(event.position, event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_press(event.position, event.pressed, MOUSE_ID)
	elif event is InputEventMouseMotion and (_joy_id == MOUSE_ID or _fire_id == MOUSE_ID):
		_handle_move(event.position, MOUSE_ID)

func _handle_press(pos: Vector2, pressed: bool, id: int) -> void:
	if pressed:
		if pos.distance_to(_pause_center()) <= PAUSE_RADIUS * 1.4:
			pause_pressed.emit()
		elif pos.distance_to(_ability_center()) <= ABILITY_RADIUS * 1.2:
			ability_pressed.emit()
		elif pos.distance_to(_sprint_center()) <= ABILITY_RADIUS * 1.25:
			_sprint_id = id
			sprint_held = true
		elif _fire_id == NO_ID and (pos.distance_to(_fire_home()) <= FIRE_RADIUS * 1.25 or (id != MOUSE_ID and pos.x > size.x * 0.5 and pos.y > size.y * 0.22)):
			# Feuer-/Zielstick: am Knopf oder frei irgendwo rechts auf dem Bildschirm
			_fire_id = id
			fire_held = true
			if pos.distance_to(_fire_home()) <= FIRE_RADIUS * 1.25:
				_fire_c = _fire_home()
			else:
				_fire_c = Vector2(clampf(pos.x, size.x * 0.5 + FIRE_RADIUS, size.x - FIRE_RADIUS - 10.0), clampf(pos.y, size.y * 0.35, size.y - FIRE_RADIUS - 10.0))
			_handle_move(pos, id)
		elif _joy_id == NO_ID and ((id != MOUSE_ID and pos.x < size.x * 0.45 and pos.y > size.y * 0.2) or (id == MOUSE_ID and pos.distance_to(_joy_home()) <= JOY_RADIUS * 1.3)):
			# Joystick erscheint dort, wo der Daumen aufsetzt (innerhalb der linken Hälfte)
			_joy_id = id
			_joy_center = Vector2(
				clampf(pos.x, JOY_RADIUS + 10.0, size.x * 0.45),
				clampf(pos.y, size.y * 0.4, size.y - JOY_RADIUS - 10.0))
			_handle_move(pos, id)
	else:
		if id == _sprint_id:
			_sprint_id = NO_ID
			sprint_held = false
		if id == _joy_id:
			_joy_id = NO_ID
			move_vec = Vector2.ZERO
			_knob = Vector2.ZERO
		if id == _fire_id:
			_fire_id = NO_ID
			fire_held = false
			aim_active = false
			aim_vec = Vector2.ZERO

func _handle_move(pos: Vector2, id: int) -> void:
	if id == _joy_id:
		var v := ((pos - _joy_center) / JOY_RADIUS).limit_length(1.0)
		move_vec = v
		_knob = v * JOY_RADIUS * 0.55
	elif id == _fire_id:
		var d := (pos - _fire_center()) / FIRE_RADIUS
		aim_vec = d.limit_length(1.0)
		aim_active = d.length() > AIM_DEADZONE
		if not aim_active:
			aim_vec = Vector2.ZERO
