class_name NeonScenery
extends RefCounted

const CITY := "res://assets/neon/city-kit-commercial/"
const ROAD := "res://assets/neon/city-kit-roads/"
const SPACE := "res://assets/neon/space-kit/"
const CAR := "res://assets/neon/car-kit/"
const CARGO := "res://assets/neon/blaster-kit/"
const TOWERS := ["building-skyscraper-b", "building-skyscraper-d", "building-skyscraper-e"]
const STORES := ["building-d", "building-h", "building-n"]
const CYAN := Color("#73d9f3")
const VIOLET := Color("#ada2ff")
const PINK := Color("#f58bbd")
const CREAM := Color("#fff0ce")
const INK := Color("#192335")
const HAZARD := Color("#ef9d56")


class Traffic:
	var vehicle: Node3D
	var anchor: Vector3
	var phase: float
	var rate: float
	var airborne: bool
	var hologram := false


var source: CoastScenery
var model: Callable
var wet_road := ShaderMaterial.new()
var teal_screen := ShaderMaterial.new()
var pink_screen := ShaderMaterial.new()
var sidewalk := StandardMaterial3D.new()
var curb_teal := StandardMaterial3D.new()
var curb_pink := StandardMaterial3D.new()
var yellow_light := StandardMaterial3D.new()
var hazard_stripe := ShaderMaterial.new()
var hologram_coating := ShaderMaterial.new()


func _init(surfaces: CoastScenery, instancer: Callable) -> void:
	source = surfaces
	model = instancer
	wet_road.shader = preload("res://scripts/neon_road.gdshader")
	wet_road.set_shader_parameter("asphalt", CoastScenery.ASPHALT)
	hazard_stripe.shader = preload("res://scripts/hazard_mark.gdshader")
	hologram_coating.shader = preload("res://scripts/neon_hologram.gdshader")
	source._pave(sidewalk, CoastScenery.ASPHALT, Color("#384862"), Vector2(1.5, 3.0))
	_make_light(curb_teal, CYAN)
	_make_light(curb_pink, PINK)
	_make_light(yellow_light, HAZARD)
	for screen in [teal_screen, pink_screen]:
		screen.shader = preload("res://scripts/neon_display.gdshader")
		screen.set_shader_parameter("accent", CYAN if screen == teal_screen else PINK)


func _make_light(material: StandardMaterial3D, tint: Color) -> void:
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = tint


func performance_mode(low: bool) -> void:
	hologram_coating.set_shader_parameter("scan_speed", 0.0 if low else 1.0)
	wet_road.set_shader_parameter("reflection_strength", 0.40 if low else 1.0)
	teal_screen.set_shader_parameter("animation_strength", 0.0 if low else 1.0)
	pink_screen.set_shader_parameter("animation_strength", 0.0 if low else 1.0)


func build_approach(parent: Node3D, theme: int, tile: int, z: float) -> void:
	for edge in [-1, 1]:
		var tower: String = TOWERS[posmod(theme + tile + edge, TOWERS.size())]
		var width := 6.5 + (theme + tile) % 3
		model.call(parent, CITY + tower, Vector3(edge * (20.0 + 2.6 * (theme % 3)), -1.6, z - 1.4),
			Vector3(width, 7.2 + (theme % 3) * 1.7, width), edge * 0.18, false)
		model.call(parent, ROAD + "light-square-double", Vector3(edge * 5.26, -0.1, z + 2.9),
			Vector3.ONE * 7.4, PI / 2.0, false)
		_bar(parent, Vector3(edge * 5.25, 4.22, z + 2.9), Vector2(0.16, 1.94), curb_teal, false)


func build_asphalt(parent: Node3D, z: float) -> void:
	source.surface(parent, "Wet luminous paving", Vector3(0, 0, z), Vector2(9.5, Tuning.ROW_STEP), wet_road)
	for side in [-1, 1]:
		_bar(parent, Vector3(side * 4.53, 0.013, z), Vector2(0.074, 12.0),
			curb_teal if side < 0 else curb_pink, true)


func build_street(parent: Node3D, moving: Node3D, theme: int, tile: int, z: float, traffic: Array[Traffic]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4820 + theme * 575 + tile
	for side in [-1, 1]:
		var edge := float(side)
		var color := curb_teal if side < 0 else curb_pink
		source.surface(parent, "Plaza tiles", Vector3(edge * 12.2, -0.07, z), Vector2(15.0, 12), sidewalk)
		_bar(parent, Vector3(edge * 6.66, -0.052, z), Vector2(0.06, 12.0), color, true)
		var store: String = STORES[posmod(theme + tile * 2 + side, STORES.size())]
		if tile == 1 and (theme + side) % 3 == 0:
			model.call(parent, SPACE + ("hangar-roundglass" if theme % 2 == 0 else "hangar-smalla"), Vector3(edge * 10.4, -0.05, z),
				Vector3(2.05, 2.4, 3.32), side * PI / 2.0, false)
			_board(parent, "심야 정류장", Vector3(edge * 8.55, 2.98, z + 3.8), Vector2(3.9, 0.87), -side * 0.41, side)
		else:
			model.call(parent, CITY + store, Vector3(edge * rng.randf_range(11.2, 13.8), -0.06, z - 0.75),
				Vector3.ONE * rng.randf_range(4.7, 6.1), -side * PI / 2.0, false)
			if tile == 1:
				model.call(parent, CITY + "detail-awning-wide", Vector3(edge * 9.0, 2.29, z + 0.55),
					Vector3.ONE * 5.7, -side * PI / 2.0, false)
			var brands: Array[String] = ["달빛 문구", "별빛 정비소", "심야 카페", "구름 택배"]
			var brand := brands[posmod(theme * 2 + tile + side, brands.size())]
			_board(parent, brand, Vector3(edge * 8.2, 2.78, z + 1.28), Vector2(3.2, 0.72), -side * 0.68, side)
		if tile == 0 or (tile == 2 and theme % 3 == 0):
			_board(parent, "심야 셔틀", Vector3(edge * 9.8, 6.5, z - 0.56),
				Vector2(4.95, 2.11), -side * 0.35, side, "다음 열차  ·  중앙역")
		if tile == 1:
			model.call(parent, ROAD + "traffic-light", Vector3(edge * 4.87, 0.0, z - 3.2),
				Vector3.ONE * 7.9, -side * 0.40, false)
		for n in range(2):
			_bar(parent, Vector3(edge * (8.2 + n * 0.27), 4.3 + n * 0.42, z + 3.35),
				Vector2(0.055, 2.83), color, false)
	if tile != 1:
		var vehicle := SPACE + "craft-speedera" if tile == 0 else CAR + "race-future"
		_add_vehicle(moving, traffic, vehicle, Vector3(6.28, 0.36, z),
			0.87 if tile == 0 else 1.65, rng.randf(), 0.90, false)
	if tile == 0 and theme % 3 == 1:
		var projection := Traffic.new()
		projection.anchor = Vector3(9.2, 5.4, z + 2.50)
		projection.vehicle = model.call(moving, SPACE + "craft-racer", projection.anchor,
			Vector3.ONE * 2.0, PI * 0.5, false)
		for part in projection.vehicle.find_children("*", "MeshInstance3D", true, false):
			part.material_override = hologram_coating
		projection.hologram = true
		traffic.append(projection)
	if tile == 1:
		_add_vehicle(moving, traffic, SPACE + "craft-speederd", Vector3(-8.65, 8.2 + theme * 0.32, z - 3.1),
			1.15, rng.randf(), 0.78, true)
		_add_vehicle(moving, traffic, SPACE + "craft-cargob", Vector3(10.8, 7.8, z + 1.28),
			0.90, rng.randf(), 0.65, true)
	if tile == 2:
		model.call(parent, SPACE + "monorail-trackstraight", Vector3(-11.4, 4.42, z),
			Vector3(4.83, 2.7, 12), 0.0, false)
		model.call(parent, SPACE + "supports-low", Vector3(-11.42, 0.15, z),
			Vector3(3.10, 8.6, 1.6), 0.0, false)
		_add_vehicle(moving, traffic, SPACE + "monorail-trainfront", Vector3(-11.4, 4.77, z),
			2.2, rng.randf(), 0.50, false)


func _add_vehicle(parent: Node3D, all: Array[Traffic], path: String, at: Vector3,
		size: float, phase: float, rate: float, airborne: bool) -> void:
	var car := Traffic.new()
	car.vehicle = model.call(parent, path, at, Vector3.ONE * size, PI, false)
	car.anchor = at
	car.phase = phase
	car.rate = rate
	car.airborne = airborne
	_bar(car.vehicle, Vector3(0, 0.06, -0.48), Vector2(0.72, 0.08), curb_teal, false)
	all.append(car)


func animate(traffic: Array[Traffic], time: float, speed: float) -> void:
	for item in traffic:
		if item.hologram:
			item.vehicle.position.y = item.anchor.y + sin(time * 1.4) * 0.19
			item.vehicle.rotation.y = time * 0.43
			continue
		var rhythm := time * (0.27 + speed * 0.026) * item.rate + item.phase * TAU
		var motion := sin(rhythm)
		item.vehicle.position = item.anchor + Vector3(
			sin(rhythm * 0.68) * (1.1 if item.airborne else 0.07),
			sin(rhythm * 1.47) * (0.40 if item.airborne else 0.06),
			motion * (4.0 if item.airborne else 4.75))
		if item.airborne:
			item.vehicle.rotation.z = sin(rhythm * 0.68) * 0.11


func _board(parent: Node3D, label: String, at: Vector3, size: Vector2, yaw: float,
		side: int, subline := "") -> void:
	var board := Node3D.new()
	board.position = at
	board.rotation.y = yaw
	parent.add_child(board)
	_bar(board, Vector3.ZERO, size, teal_screen if side < 0 else pink_screen, false)
	var title_y := 0.29 if not subline.is_empty() else 0.0
	source.label(board, label, Vector3(0, title_y, 0.021), 0.0063 if subline.is_empty() else 0.010,
		Color("#f5f5f0"), CoastScenery.KOREAN)
	if not subline.is_empty():
		source.label(board, subline, Vector3(0, -0.46, 0.023), 0.0056,
			CYAN if side < 0 else PINK, CoastScenery.KOREAN)


func _bar(parent: Node3D, at: Vector3, size: Vector2, material: Material, flat: bool) -> void:
	var face := source.surface(parent, "City lighting", at, size, material)
	if not flat:
		face.rotation.x = 0.0


func entry(parent: Node3D) -> void:
	model.call(parent, ROAD + "sign-highway-wide", Vector3(-5.6, 0, -0.28), Vector3(7.7, 8.5, 7.4),
		-PI / 2.0, false)
	model.call(parent, ROAD + "traffic-light-hanging", Vector3(-4.68, 1.40, -1.32),
		Vector3.ONE * 6.9, -PI / 2.0, false)
	_board(parent, "네온 시티", Vector3(-5.1, 4.76, 0.13), Vector2(4.5, 1.64), 0.34, -1, "중앙대로")


func finish_model(root: Node3D, path: String) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		for surface in part.mesh.get_surface_count():
			var material := part.mesh.surface_get_material(surface) as StandardMaterial3D
			if not material:
				continue
			if path.begins_with(CITY) and material.albedo_texture:
				var facade := ShaderMaterial.new()
				facade.shader = preload("res://scripts/neon_facade.gdshader")
				facade.set_shader_parameter("atlas", material.albedo_texture)
				var style := posmod(path.hash(), 3)
				facade.set_shader_parameter("stone", [Color("#323e59"), Color("#3f345a"), Color("#2d5268")][style])
				facade.set_shader_parameter("glass", [CYAN, PINK, VIOLET][style])
				part.mesh.surface_set_material(surface, facade)
			elif path.begins_with(SPACE):
				if not path.ends_with("craft-racer") and not path.ends_with("rover"):
					var base := material.albedo_color
					material.albedo_color = Color("#7c95b8").lerp(CYAN, 0.44) if base.b > 0.55 else Color("#344157")
					material.emission_enabled = true
					material.emission = CYAN if base.b > 0.55 else VIOLET
					material.emission_energy_multiplier = 0.15
