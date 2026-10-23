extends Node
# 3D-Figuren (Kenney Mini Characters, CC0) als Overlay über der 2D-Welt.
# Die Figuren werden in einem durchsichtigen SubViewport gerendert (orthografische Kamera,
# 1 Einheit = 1 Pixel) und liegen als Bild über dem Spiel.

const MODEL_DIR := "res://assets/3d/"
const SKIN_MODELS := {
	"char_player": "character-male-a", "char_red": "character-male-b", "char_green": "character-male-c",
	"char_yellow": "character-male-d", "char_purple": "character-female-a", "char_orange": "character-female-b",
	"char_cyan": "character-female-c", "char_pink": "character-female-d",
}
const UNIT_SCALE := 118.0
const PITCH := 0.42   # Neigung zur Kamera (leichte Draufsicht)

const VIEW_ANGLE := 0.55
const VIEW_TILT := 0.72
const RES_SCALE := 1.0
const HOUSE_WALL_H := 84.0
const ROOF_H := 44.0
const CAM_DIST := 1600.0
var pitch_angle := asin(VIEW_TILT)
var world_root: Node3D
var unit_root: Node3D
var world_mode := false
var zoom := 1.0
var houses: Array = []
var tree_nodes: Array = []
var mat_tree_solid: StandardMaterial3D
var mat_tree_fade: StandardMaterial3D
var vsize := Vector2(1280, 720)
var cam_target := Vector3.ZERO
var viewport: SubViewport
var camera: Camera3D
var rect: TextureRect
var layer: CanvasLayer
var units: Dictionary = {}   # id -> Dictionary
var scenes: Dictionary = {}

func setup(host: Node, layer_index := 1) -> void:
	layer = CanvasLayer.new()
	layer.layer = layer_index
	host.add_child(layer)
	viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_2X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	rect = TextureRect.new()
	rect.texture = viewport.get_texture()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	world_root = Node3D.new()
	world_root.rotation.y = -VIEW_ANGLE
	viewport.add_child(world_root)
	var gplane := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(5000, 4600)
	gplane.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.shadow_to_opacity = true
	gm.albedo_color = Color(0, 0, 0, 1)
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	gplane.material_override = gm
	gplane.position = Vector3(1200, 0.2, 900)
	gplane.name = "ShadowGround"
	world_root.add_child(gplane)
	unit_root = Node3D.new()
	viewport.add_child(unit_root)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 1.0
	camera.far = 4000.0
	viewport.add_child(camera)
	camera.make_current()
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.15
	sun.shadow_enabled = false
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 1500.0
	sun.shadow_bias = 0.05
	sun.shadow_normal_bias = 1.0
	sun.shadow_opacity = 0.55
	viewport.add_child(sun)
	sun.look_at_from_position(Vector3(0, 0, 0), Vector3(0.55, -1.0, 0.45), Vector3.UP)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 1.0)
	env.ambient_light_energy = 0.75
	var we := WorldEnvironment.new()
	we.environment = env
	viewport.add_child(we)
	_resize()
	host.get_viewport().size_changed.connect(_resize)

func _resize() -> void:
	var s: Vector2 = get_viewport().get_visible_rect().size
	viewport.size = Vector2i(int(s.x * RES_SCALE), int(s.y * RES_SCALE))
	camera.size = s.y
	vsize = s
	_apply_camera()

func _scene_for(skin: String) -> PackedScene:
	var m: String = SKIN_MODELS.get(skin, "character-male-a")
	if not scenes.has(m):
		scenes[m] = load(MODEL_DIR + m + ".glb")
	return scenes[m]

# ---------- Waffen aus einfachen Formen ----------
func _box(size: Vector3, col: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.6
	mi.material_override = mat
	mi.position = pos
	return mi

func _cyl(r: float, h: float, col: Color, pos: Vector3, rot_x := PI / 2.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.5
	mi.material_override = mat
	mi.position = pos
	mi.rotation.x = rot_x
	return mi

# Waffe zeigt entlang +Z (nach vorn), Einheiten in Modellmaß (Figur ca. 1 hoch)
func _build_weapon(kind: String) -> Node3D:
	var n := Node3D.new()
	var dark := Color(0.16, 0.17, 0.2)
	var metal := Color(0.45, 0.48, 0.55)
	match kind:
		"pistol":
			n.add_child(_box(Vector3(0.05, 0.07, 0.22), dark, Vector3(0, 0, 0.12)))
			n.add_child(_box(Vector3(0.045, 0.1, 0.06), Color(0.3, 0.2, 0.12), Vector3(0, -0.07, 0.04)))
		"smg":
			n.add_child(_box(Vector3(0.06, 0.09, 0.3), Color(0.25, 0.7, 0.3), Vector3(0, 0, 0.15)))
			n.add_child(_box(Vector3(0.04, 0.16, 0.05), dark, Vector3(0, -0.1, 0.12)))
			n.add_child(_cyl(0.015, 0.14, metal, Vector3(0, 0.01, 0.37)))
		"ak":
			n.add_child(_box(Vector3(0.06, 0.09, 0.5), Color(0.55, 0.35, 0.18), Vector3(0, 0, 0.25)))
			n.add_child(_box(Vector3(0.04, 0.15, 0.07), dark, Vector3(0.0, -0.1, 0.22)))
			n.add_child(_cyl(0.017, 0.22, metal, Vector3(0, 0.02, 0.58)))
		"minigun":
			for i in 3:
				var a := TAU * i / 3.0
				n.add_child(_cyl(0.02, 0.5, metal, Vector3(cos(a) * 0.04, sin(a) * 0.04, 0.3)))
			n.add_child(_box(Vector3(0.14, 0.14, 0.2), Color(0.85, 0.3, 0.2), Vector3(0, 0, 0.0)))
		"shotgun":
			n.add_child(_box(Vector3(0.06, 0.08, 0.55), Color(0.6, 0.38, 0.2), Vector3(0, 0, 0.27)))
			n.add_child(_cyl(0.022, 0.4, metal, Vector3(0, 0.03, 0.5)))
		"sniper":
			n.add_child(_box(Vector3(0.05, 0.07, 0.7), Color(0.25, 0.4, 0.75), Vector3(0, 0, 0.35)))
			n.add_child(_cyl(0.03, 0.2, dark, Vector3(0, 0.08, 0.3)))
			n.add_child(_cyl(0.014, 0.3, metal, Vector3(0, 0.02, 0.8)))
		"rocket":
			n.add_child(_cyl(0.07, 0.6, Color(0.4, 0.55, 0.4), Vector3(0, 0.02, 0.3)))
			n.add_child(_cyl(0.085, 0.1, dark, Vector3(0, 0.02, 0.62)))
			n.add_child(_box(Vector3(0.04, 0.1, 0.06), dark, Vector3(0, -0.07, 0.25)))
		"revolver":
			n.add_child(_box(Vector3(0.05, 0.08, 0.26), Color(0.6, 0.6, 0.66), Vector3(0, 0, 0.14)))
			n.add_child(_cyl(0.045, 0.07, metal, Vector3(0, 0.0, 0.1), PI / 2.0))
			n.add_child(_box(Vector3(0.045, 0.1, 0.06), Color(0.4, 0.25, 0.12), Vector3(0, -0.08, 0.03)))
		"crossbow":
			n.add_child(_box(Vector3(0.05, 0.06, 0.5), Color(0.5, 0.32, 0.16), Vector3(0, 0, 0.25)))
			n.add_child(_box(Vector3(0.5, 0.03, 0.04), Color(0.35, 0.22, 0.1), Vector3(0, 0.0, 0.45)))
			n.add_child(_cyl(0.008, 0.45, Color(0.9, 0.9, 0.9), Vector3(0, 0.04, 0.3)))
		"laser":
			n.add_child(_box(Vector3(0.09, 0.11, 0.45), Color(0.3, 0.9, 0.95), Vector3(0, 0, 0.22)))
			n.add_child(_cyl(0.03, 0.2, Color(0.9, 0.2, 0.9), Vector3(0, 0.0, 0.52)))
			n.add_child(_box(Vector3(0.05, 0.12, 0.06), dark, Vector3(0, -0.1, 0.18)))
		"katana":
			n.add_child(_cyl(0.012, 0.7, Color(0.9, 0.93, 1.0), Vector3(0, 0.12, 0.25), 0.0))
			n.add_child(_cyl(0.03, 0.04, Color(0.8, 0.6, 0.2), Vector3(0, 0.12, -0.08), 0.0))
		"hammer":
			n.add_child(_cyl(0.025, 0.6, Color(0.6, 0.42, 0.22), Vector3(0, 0.12, 0.1), 0.0))
			n.add_child(_box(Vector3(0.16, 0.14, 0.22), Color(0.5, 0.5, 0.55), Vector3(0, 0.38, 0.1)))
		"bat":
			n.add_child(_cyl(0.035, 0.55, Color(0.8, 0.62, 0.38), Vector3(0, 0.12, 0.1), 0.0))
		"pan":
			n.add_child(_cyl(0.015, 0.25, dark, Vector3(0, 0.0, 0.1)))
			n.add_child(_cyl(0.11, 0.025, Color(0.25, 0.26, 0.3), Vector3(0, 0.0, 0.3), PI / 2.0))
		"extinguisher":
			n.add_child(_cyl(0.06, 0.28, Color(0.9, 0.15, 0.15), Vector3(0, 0.05, 0.12), 0.0))
			n.add_child(_box(Vector3(0.03, 0.03, 0.1), dark, Vector3(0, 0.22, 0.15)))
		_:
			pass
	return n

# ---------- Einheiten ----------
func _outline_mat(amount: float, col := Color(0.08, 0.06, 0.1)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.cull_mode = BaseMaterial3D.CULL_FRONT
	m.grow = true
	m.grow_amount = amount
	return m

func _add_outline(node: Node, mat: Material) -> void:
	for ch in node.find_children("*", "MeshInstance3D", true, false):
		(ch as MeshInstance3D).material_overlay = mat

var _tree_outline: StandardMaterial3D = _outline_mat(1.2, Color(0.06, 0.16, 0.1))

func _make_unit(skin: String) -> Dictionary:
	var pivot := Node3D.new()
	var yaw := Node3D.new()
	pivot.add_child(yaw)
	var model: Node3D = _scene_for(skin).instantiate()
	yaw.add_child(model)
	_add_outline(model, _outline_mat(0.018))
	pivot.scale = Vector3.ONE * UNIT_SCALE
	unit_root.add_child(pivot)
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	var hand: Node3D = model.find_child("arm-right", true, false)
	var d := {"pivot": pivot, "yaw": yaw, "model": model, "ap": ap, "hand": hand, "skin": skin,
		"weapon": "", "weapon_node": null, "anim": "", "yaw_t": 0.0}
	return d

func _play(d: Dictionary, anim: String, speed := 1.0) -> void:
	var ap: AnimationPlayer = d["ap"]
	if ap == null:
		return
	if d["anim"] != anim:
		d["anim"] = anim
		if ap.has_animation(anim):
			var a := ap.get_animation(anim)
			a.loop_mode = Animation.LOOP_NONE if anim == "die" else Animation.LOOP_LINEAR
			ap.play(anim, 0.12)
	ap.speed_scale = speed

func _set_weapon(d: Dictionary, kind: String) -> void:
	if d["weapon"] == kind:
		return
	d["weapon"] = kind
	if d["weapon_node"] != null:
		d["weapon_node"].queue_free()
		d["weapon_node"] = null
	if kind == "" or kind == "fist":
		return
	var w := _build_weapon(kind)
	# Arm-Knoten ist klein skaliert/gedreht; Waffe in Modellraum am Körper befestigen
	var holder: Node3D = d["yaw"]
	w.position = Vector3(-0.13, 0.27, 0.09)
	w.scale = Vector3.ONE * 0.95
	holder.add_child(w)
	d["weapon_node"] = w

# Eintrag pro Frame: id, skin, screen (Vector2), aim (Bildschirmrichtung), moving, firing, weapon, alive, lift
func update_unit(id: String, e: Dictionary) -> void:
	var d: Dictionary
	if units.has(id):
		d = units[id]
		if d["skin"] != e["skin"]:
			d["pivot"].queue_free()
			units.erase(id)
			d = _make_unit(e["skin"])
			units[id] = d
	else:
		d = _make_unit(e["skin"])
		units[id] = d
	d["seen"] = true
	var pivot: Node3D = d["pivot"]
	pivot.visible = e.get("visible", true)
	var lift: float = e.get("lift", 0.0)
	pivot.scale = Vector3.ONE * UNIT_SCALE * float(e.get("scale", 1.0))
	var aim: Vector2 = e.get("aim", Vector2.DOWN)
	if world_mode:
		# Weltkoordinaten (x, Höhe, y); Figur steht aufrecht, Kamera kippt
		var wp: Vector2 = e["world"]
		pivot.position = Vector3(wp.x, lift / cos(pitch_angle), wp.y)
		pivot.rotation.x = 0.0
		aim = e.get("aimw", Vector2.DOWN)
	else:
		var s: Vector2 = e["screen"]
		pivot.position = Vector3(s.x, -s.y + lift, 0.0)
		pivot.rotation.x = PITCH
	var target_yaw := atan2(aim.x, aim.y)
	d["yaw_t"] = lerp_angle(d["yaw_t"], target_yaw, 0.35)
	d["yaw"].rotation.y = d["yaw_t"]
	var weapon: String = e.get("weapon", "")
	_set_weapon(d, weapon)
	var armed: bool = weapon != "" and weapon != "fist" and not (weapon in ["bat", "pan", "extinguisher", "katana", "hammer"])
	var anim := "idle"
	var spd := 1.0
	if not e.get("alive", true):
		anim = "die"
	elif e.get("falling", false):
		anim = "fall"
	elif e.get("jumping", false):
		anim = "jump"
	elif e.get("attacking", false):
		anim = "attack-melee-right"
		spd = 1.4
	elif armed and e.get("firing", false):
		anim = "holding-right-shoot"
	elif e.get("moving", false):
		anim = "sprint" if e.get("fast", false) else "walk"
		spd = 1.3
	elif armed:
		anim = "holding-right"
	_play(d, anim, spd)
	# Rückstoß: Waffe ruckt beim Schießen nach hinten und kippt leicht hoch
	var wn = d["weapon_node"]
	if wn != null:
		var k: float = float(d.get("kick", 0.0))
		if armed and e.get("firing", false):
			k = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.045)
		else:
			k = move_toward(k, 0.0, 0.2)
		d["kick"] = k
		wn.position = Vector3(-0.13, 0.27, 0.09 - 0.06 * k)
		wn.rotation.x = -0.18 * k

# Nach dem Aktualisieren aller Einheiten: nicht mehr gesehene aufräumen
func begin_frame() -> void:
	for id in units:
		units[id]["seen"] = false

func end_frame() -> void:
	var gone: Array = []
	for id in units:
		if not units[id]["seen"]:
			gone.append(id)
	for id in gone:
		units[id]["pivot"].queue_free()
		units.erase(id)


# ---------- Kamera und Modus ----------
func _apply_camera() -> void:
	camera.size = vsize.y / zoom if world_mode else vsize.y
	if world_mode:
		camera.rotation = Vector3(-pitch_angle, 0.0, 0.0)
		camera.position = cam_target + Vector3(0.0, sin(pitch_angle) * CAM_DIST, cos(pitch_angle) * CAM_DIST)
	else:
		camera.rotation = Vector3.ZERO
		camera.position = Vector3(vsize.x * 0.5, -vsize.y * 0.5, 2000.0)

# Außen: echte 3D-Welt; im Haus: flache Bildschirm-Darstellung
func set_mode(world: bool, center_world: Vector2) -> void:
	world_mode = world
	world_root.visible = world
	unit_root.transform = world_root.transform if world else Transform3D.IDENTITY
	if world:
		cam_target = world_root.transform * Vector3(center_world.x, 0.0, center_world.y)
	_apply_camera()

# Häuser und Bäume ausblenden, wenn der Spieler dahinter steht
func update_fades(player: Vector2) -> void:
	if not world_mode:
		return
	var u := Vector2(sin(VIEW_ANGLE), cos(VIEW_ANGLE))   # Richtung zur Kamera (Bodenebene, Welt)
	var tp := tan(pitch_angle)
	for h in houses:
		var hid := false
		var r: Rect2 = h["rect"]
		if r.grow(60).has_point(player):
			var d := 8.0
			while d < (HOUSE_WALL_H + ROOF_H) / tp:
				if r.has_point(player + u * d):
					hid = true
					break
				d += 14.0
		_set_house_fade(h, hid)
	for t in tree_nodes:
		var hid2 := false
		var tpos: Vector2 = t["pos"]
		if tpos.distance_to(player) < 140.0:
			var d2 := 20.0
			while d2 < 130.0:
				if (player + u * d2).distance_to(tpos) < 30.0:
					hid2 = true
					break
				d2 += 12.0
		if t["faded"] != hid2:
			t["faded"] = hid2
			t["node"].material_override = mat_tree_fade if hid2 else mat_tree_solid
			t["node"].material_overlay = null if hid2 else _tree_outline

func _set_house_fade(h: Dictionary, hid: bool) -> void:
	if h["faded"] == hid:
		return
	h["faded"] = hid
	for key in ["wall_mat", "roof_mat"]:
		var m: StandardMaterial3D = h[key]
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if hid else BaseMaterial3D.TRANSPARENCY_DISABLED
		m.albedo_color = Color(1, 1, 1, 0.35 if hid else 1.0)

# ---------- Welt aus einfachen Formen ----------
func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, uv_scale := Vector2.ZERO, ref := Vector3(1e9, 0, 0)) -> void:
	var n := (b - a).cross(d - a).normalized()
	if ref.x < 1e8 and n.dot((a + b + c + d) * 0.25 - ref) < 0.0:
		n = -n
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	if uv_scale != Vector2.ZERO:
		uvs = [Vector2(0, 0), Vector2(uv_scale.x, 0), Vector2(uv_scale.x, uv_scale.y), Vector2(0, uv_scale.y)]
	var pts := [a, b, c, a, c, d]
	var idx := [0, 1, 2, 0, 2, 3]
	for k in 6:
		st.set_normal(n)
		st.set_color(col)
		st.set_uv(uvs[idx[k]])
		st.add_vertex(pts[k])

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color, ref := Vector3(1e9, 0, 0)) -> void:
	var n := (b - a).cross(c - a).normalized()
	if ref.x < 1e8 and n.dot((a + b + c) / 3.0 - ref) < 0.0:
		n = -n
	for p in [a, b, c]:
		st.set_normal(n)
		st.set_color(col)
		st.set_uv(Vector2.ZERO)
		st.add_vertex(p)

func _add_box(st: SurfaceTool, c: Vector3, size: Vector3, col: Color) -> void:
	var h := size * 0.5
	var p := [Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z),
		Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
	for i in 8:
		p[i] += c
	_quad(st, p[4], p[5], p[6], p[7], col)   # +z
	_quad(st, p[1], p[0], p[3], p[2], col)   # -z
	_quad(st, p[5], p[1], p[2], p[6], col)   # +x
	_quad(st, p[0], p[4], p[7], p[3], col)   # -x
	_quad(st, p[3], p[7], p[6], p[2], col)   # oben
	_quad(st, p[0], p[1], p[5], p[4], col)   # unten

func _add_sphere(st: SurfaceTool, c: Vector3, r: float, col: Color, squash := 0.9) -> void:
	var rings := 6
	var segs := 10
	for i in rings:
		var a0 := PI * i / rings
		var a1 := PI * (i + 1) / rings
		for j in segs:
			var b0 := TAU * j / segs
			var b1 := TAU * (j + 1) / segs
			var v00 := Vector3(sin(a0) * cos(b0), cos(a0), sin(a0) * sin(b0))
			var v01 := Vector3(sin(a0) * cos(b1), cos(a0), sin(a0) * sin(b1))
			var v10 := Vector3(sin(a1) * cos(b0), cos(a1), sin(a1) * sin(b0))
			var v11 := Vector3(sin(a1) * cos(b1), cos(a1), sin(a1) * sin(b1))
			var shade := 0.82 + 0.18 * (v00.y * 0.5 + 0.5)
			var cc := Color(col.r * shade, col.g * shade, col.b * shade)
			for tri in [[v00, v10, v11], [v00, v11, v01]]:
				for v in tri:
					st.set_normal(v)
					st.set_color(cc)
					st.set_uv(Vector2.ZERO)
					st.add_vertex(c + Vector3(v.x * r, v.y * r * squash, v.z * r))

func _add_cyl(st: SurfaceTool, base: Vector3, r: float, h: float, col: Color) -> void:
	var segs := 8
	for j in segs:
		var b0 := TAU * j / segs
		var b1 := TAU * (j + 1) / segs
		var p0 := base + Vector3(cos(b0) * r, 0, sin(b0) * r)
		var p1 := base + Vector3(cos(b1) * r, 0, sin(b1) * r)
		_quad(st, p1, p0, p0 + Vector3(0, h, 0), p1 + Vector3(0, h, 0), col)

func _vc_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.85
	return m

const WALL_TINTS := [Color(0.97, 0.91, 0.78), Color(0.98, 0.86, 0.72), Color(0.9, 0.93, 0.85), Color(0.95, 0.85, 0.85), Color(0.86, 0.9, 0.97)]
const TREE_GREENS := [Color(0.26, 0.62, 0.3), Color(0.3, 0.68, 0.28), Color(0.2, 0.55, 0.34), Color(0.4, 0.72, 0.3)]

func build_world(obstacles: Array, trees: Array, roofs: Array) -> void:
	for ch in world_root.get_children():
		ch.queue_free()
	houses.clear()
	tree_nodes.clear()
	mat_tree_solid = _vc_material()
	mat_tree_fade = _vc_material()
	mat_tree_fade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_tree_fade.albedo_color = Color(1, 1, 1, 0.38)
	for i in obstacles.size():
		var r: Rect2 = obstacles[i]
		var wall_col: Color = WALL_TINTS[i % WALL_TINTS.size()]
		var H := HOUSE_WALL_H
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		# Wände und Sockel
		_add_box(st, Vector3(r.get_center().x, H * 0.5, r.get_center().y), Vector3(r.size.x, H, r.size.y), wall_col)
		_add_box(st, Vector3(r.get_center().x, 7.0, r.get_center().y), Vector3(r.size.x + 6, 14, r.size.y + 6), wall_col.darkened(0.25))
		# Fenster auf allen vier Seiten
		var glass := Color(0.55, 0.82, 1.0)
		var frame := Color(1, 1, 1)
		for k in 4:
			var along := Vector3.RIGHT if k < 2 else Vector3.BACK
			var normal: Vector3
			var base: Vector3
			var length: float
			match k:
				0:
					normal = Vector3.BACK
					base = Vector3(r.position.x, 0, r.end.y)
					length = r.size.x
				1:
					normal = Vector3.FORWARD
					base = Vector3(r.position.x, 0, r.position.y)
					length = r.size.x
				2:
					normal = Vector3.RIGHT
					base = Vector3(r.end.x, 0, r.position.y)
					length = r.size.y
				_:
					normal = Vector3.LEFT
					base = Vector3(r.position.x, 0, r.position.y)
					length = r.size.y
			for tt in [0.2, 0.8]:
				var c: Vector3 = base + along * (length * tt) + Vector3(0, 56, 0) + normal * 1.5
				var sz := Vector3(26, 30, 3) if k < 2 else Vector3(3, 30, 26)
				_add_box(st, c, sz + Vector3(4, 4, 4) * (Vector3(1, 1, 0) if k < 2 else Vector3(0, 1, 1)), frame)
				_add_box(st, c + normal * 1.0, sz, glass)
		# Tür (Südseite)
		var dc := Vector3(r.get_center().x, 24, r.end.y + 1.5)
		_add_box(st, dc + Vector3(0, 2, -0.5), Vector3(40, 52, 3), Color(1, 1, 1))
		_add_box(st, dc + Vector3(0, 0, 1.0), Vector3(32, 48, 3), Color(0.45, 0.28, 0.16))
		_add_box(st, Vector3(dc.x, 1.5, r.end.y + 12), Vector3(48, 3, 20), Color(0.7, 0.68, 0.64))
		# Dach (Firstrichtung entlang der längeren Seite)
		var rg := r.grow(10)
		var rh := ROOF_H
		var cz := r.get_center().y
		var cx := r.get_center().x
		var roof_st := SurfaceTool.new()
		roof_st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var white := Color(1, 1, 1)
		var refp := Vector3(cx, H * 0.6, cz)
		if r.size.x >= r.size.y:
			var len := 1.0
			_quad(roof_st, Vector3(rg.position.x, H, rg.end.y), Vector3(rg.end.x, H, rg.end.y), Vector3(rg.end.x, H + rh, cz), Vector3(rg.position.x, H + rh, cz), white, Vector2(len, 1.0), refp)
			_quad(roof_st, Vector3(rg.end.x, H, rg.position.y), Vector3(rg.position.x, H, rg.position.y), Vector3(rg.position.x, H + rh, cz), Vector3(rg.end.x, H + rh, cz), white, Vector2(len, 1.0), refp)
			_tri(st, Vector3(r.position.x, H, r.end.y), Vector3(r.position.x, H, r.position.y), Vector3(r.position.x, H + rh * 0.92, cz), wall_col, refp)
			_tri(st, Vector3(r.end.x, H, r.position.y), Vector3(r.end.x, H, r.end.y), Vector3(r.end.x, H + rh * 0.92, cz), wall_col, refp)
			_add_box(st, Vector3(r.position.x + 36, H + rh * 0.55, cz + 18), Vector3(16, 46, 16), Color(0.7, 0.32, 0.25))
		else:
			var len2 := 1.0
			_quad(roof_st, Vector3(rg.end.x, H, rg.position.y), Vector3(rg.end.x, H, rg.end.y), Vector3(cx, H + rh, rg.end.y), Vector3(cx, H + rh, rg.position.y), white, Vector2(len2, 1.0), refp)
			_quad(roof_st, Vector3(rg.position.x, H, rg.end.y), Vector3(rg.position.x, H, rg.position.y), Vector3(cx, H + rh, rg.position.y), Vector3(cx, H + rh, rg.end.y), white, Vector2(len2, 1.0), refp)
			_tri(st, Vector3(r.end.x, H, r.end.y), Vector3(r.position.x, H, r.end.y), Vector3(cx, H + rh * 0.92, r.end.y), wall_col, refp)
			_tri(st, Vector3(r.position.x, H, r.position.y), Vector3(r.end.x, H, r.position.y), Vector3(cx, H + rh * 0.92, r.position.y), wall_col, refp)
			_add_box(st, Vector3(cx + 18, H + rh * 0.55, r.position.y + 36), Vector3(16, 46, 16), Color(0.7, 0.32, 0.25))
		var wall_mat := _vc_material()
		var roof_mat := StandardMaterial3D.new()
		roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		roof_mat.roughness = 0.8
		if roofs.size() > 0:
			roof_mat.albedo_texture = roofs[i % roofs.size()]
			roof_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		else:
			roof_mat.albedo_color = Color(0.8, 0.3, 0.3)
		var wm := MeshInstance3D.new()
		wm.mesh = st.commit()
		wm.material_override = wall_mat
		world_root.add_child(wm)
		var rm := MeshInstance3D.new()
		rm.mesh = roof_st.commit()
		rm.material_override = roof_mat
		world_root.add_child(rm)
		houses.append({"rect": r, "wall_mat": wall_mat, "roof_mat": roof_mat, "faded": false})
	for i in trees.size():
		var p: Vector2 = trees[i]
		var st2 := SurfaceTool.new()
		st2.begin(Mesh.PRIMITIVE_TRIANGLES)
		var g: Color = TREE_GREENS[i % TREE_GREENS.size()]
		_add_cyl(st2, Vector3(0, 0, 0), 7.0, 46.0, Color(0.45, 0.28, 0.16))
		_add_sphere(st2, Vector3(0, 70, 0), 36.0, g)
		_add_sphere(st2, Vector3(16, 98, 8), 22.0, g.lightened(0.1))
		_add_sphere(st2, Vector3(-18, 90, -8), 20.0, g.darkened(0.05))
		var tm := MeshInstance3D.new()
		tm.mesh = st2.commit()
		tm.material_override = mat_tree_solid
		tm.material_overlay = _tree_outline
		tm.position = Vector3(p.x, 0, p.y)
		tm.rotation.y = float(i) * 1.7
		world_root.add_child(tm)
		tree_nodes.append({"pos": p, "node": tm, "faded": false})


# ---------- Loot als 3D-Objekte ----------
var loot_nodes: Dictionary = {}
var loot_mesh_cache: Dictionary = {}
const RARITY_COL := [Color(0.35, 0.85, 0.4), Color(0.3, 0.6, 1.0), Color(0.7, 0.4, 1.0), Color(1.0, 0.78, 0.15)]

func begin_loot() -> void:
	for k in loot_nodes:
		loot_nodes[k]["seen"] = false

func end_loot() -> void:
	var gone: Array = []
	for k in loot_nodes:
		if not loot_nodes[k]["seen"]:
			gone.append(k)
	for k in gone:
		loot_nodes[k]["node"].queue_free()
		loot_nodes.erase(k)

func clear_loot() -> void:
	begin_loot()
	end_loot()

func _emissive(col: Color, energy := 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	return m

func _mesh_from(st: SurfaceTool) -> ArrayMesh:
	return st.commit()

func _new_st() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

func _mi(mesh: Mesh, mat: Material, pos := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return mi

func _make_chest(rar: int) -> Dictionary:
	var col: Color = RARITY_COL[rar]
	var wood := col.darkened(0.15)
	var band := Color(0.22, 0.2, 0.2)
	var root := Node3D.new()
	var st := _new_st()
	_add_box(st, Vector3(0, 15, 0), Vector3(62, 30, 42), wood)
	_add_box(st, Vector3(-18, 15, 0), Vector3(7, 31, 44), band)
	_add_box(st, Vector3(18, 15, 0), Vector3(7, 31, 44), band)
	_add_box(st, Vector3(0, 2, 0), Vector3(66, 5, 46), band)
	root.add_child(_mi(st.commit(), _vc_material()))
	# Deckel: dreht sich um die Hinterkante
	var lid := Node3D.new()
	lid.position = Vector3(0, 30, -21)
	root.add_child(lid)
	var st2 := _new_st()
	_add_box(st2, Vector3(0, 8, 21), Vector3(64, 16, 44), col)
	_add_box(st2, Vector3(-18, 8, 21), Vector3(7, 17, 46), band)
	_add_box(st2, Vector3(18, 8, 21), Vector3(7, 17, 46), band)
	_add_sphere(st2, Vector3(0, 0, 21), 1.0, col, 1.0)   # (unsichtbar klein, hält Mesh-Format gleich)
	_add_box(st2, Vector3(0, 2, 43.5), Vector3(10, 12, 4), Color(1, 0.85, 0.3))
	lid.add_child(_mi(st2.commit(), _vc_material()))
	if rar == 3:
		var glow := _mi(SphereMesh.new(), _emissive(Color(1, 0.8, 0.2, 1), 0.8))
		glow.scale = Vector3(1, 1, 1) * 0.1
		glow.visible = false
		root.add_child(glow)
	return {"node": root, "lid": lid}

func _make_item(kind: String, rar: int) -> Node3D:
	var root := Node3D.new()
	var white := Color(0.96, 0.96, 0.98)
	var red := Color(0.9, 0.2, 0.25)
	match kind:
		"heal", "heal_big":
			var s := 1.0 if kind == "heal" else 1.5
			var st := _new_st()
			_add_box(st, Vector3(0, 12 * s, 0), Vector3(30 * s, 24 * s, 22 * s), white)
			_add_box(st, Vector3(0, 12 * s, 11.5 * s), Vector3(18 * s, 6 * s, 2 * s), red)
			_add_box(st, Vector3(0, 12 * s, 11.5 * s), Vector3(6 * s, 18 * s, 2.2 * s), red)
			_add_box(st, Vector3(0, 26 * s, 0), Vector3(12 * s, 4 * s, 6 * s), Color(0.7, 0.7, 0.75))
			root.add_child(_mi(st.commit(), _vc_material()))
		"shield", "shield_big":
			var s2 := 1.0 if kind == "shield" else 1.5
			var blue := Color(0.25, 0.55, 1.0)
			var st2 := _new_st()
			_add_sphere(st2, Vector3(0, 14 * s2, 0), 14 * s2, blue, 1.0)
			_add_cyl(st2, Vector3(0, 24 * s2, 0), 5 * s2, 12 * s2, Color(0.85, 0.9, 1.0))
			_add_cyl(st2, Vector3(0, 35 * s2, 0), 6.5 * s2, 4 * s2, Color(0.7, 0.45, 0.25))
			root.add_child(_mi(st2.commit(), _vc_material()))
			var ring := _mi(SphereMesh.new(), _emissive(Color(0.3, 0.6, 1.0), 0.6))
			ring.scale = Vector3.ONE * 0.01
			root.add_child(ring)
		"jump", "power", "speed":
			var oc: Color = {"jump": Color(1.0, 0.25, 0.25), "power": Color(1.0, 0.85, 0.2), "speed": Color(0.3, 0.9, 0.35)}[kind]
			var sm := SphereMesh.new()
			sm.radius = 14.0
			sm.height = 28.0
			root.add_child(_mi(sm, _emissive(oc, 1.8), Vector3(0, 18, 0)))
			var sm2 := SphereMesh.new()
			sm2.radius = 19.0
			sm2.height = 38.0
			var gm := _emissive(Color(oc.r, oc.g, oc.b, 0.3), 0.6)
			gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			root.add_child(_mi(sm2, gm, Vector3(0, 18, 0)))
		_:
			var w := _build_weapon(kind)
			var wrap := Node3D.new()
			wrap.add_child(w)
			w.position = Vector3(0, 0, -0.1)
			wrap.scale = Vector3.ONE * 105.0
			wrap.position = Vector3(0, 20, 0)
			if kind in ["bat", "pan", "extinguisher", "katana", "hammer"]:
				wrap.scale = Vector3.ONE * 95.0
			root.add_child(wrap)
	return root

func update_loot(key: int, pos: Vector2, kind: String, rar: int, t: float, open_k: float) -> void:
	var d: Dictionary
	if loot_nodes.has(key):
		d = loot_nodes[key]
	else:
		var node: Node3D
		var lid: Node3D = null
		if kind == "chest":
			var c := _make_chest(rar)
			node = c["node"]
			lid = c["lid"]
		else:
			node = _make_item(kind, rar)
		unit_root.add_child(node)
		d = {"node": node, "lid": lid, "kind": kind, "phase": float(key) * 0.7}
		loot_nodes[key] = d
	d["seen"] = true
	var n: Node3D = d["node"]
	n.position = Vector3(pos.x, 0, pos.y)
	if kind == "chest":
		d["lid"].rotation.x = -open_k * 1.9
		n.rotation.y = 0.0
	else:
		var bob := 8.0 + 3.0 * sin(t * 3.0 + d["phase"])
		n.position.y = bob
		n.rotation.y = t * 1.6 + d["phase"]
