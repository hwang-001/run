class_name RunnerTrack
extends Node3D

signal coin_taken(at: Vector3)
signal obstacle_hit(at: Vector3)
signal heart_taken(at: Vector3)
signal timer_taken(at: Vector3)

enum Kind { CRATE, CONE, BARRIER, FENCE, OVERHEAD, TRUCK, BARREL, CARGO, BOOM, DINGHY, LOG, BOULDER, WOOD_FENCE, BOUGH, WOOD_BOX, LOG_WALL, HOVER_CAR, ROAD_BLOCK, ENERGY, LASER, DATA_CRATE, LOW_SIGN, SERVICE_BOT, BEACON }

const CITY := "res://assets/city/"
const NATURE := "res://assets/props/nature-kit/"
const COMMERCIAL := "res://assets/props/city-kit-commercial/"
const WORKS := "res://assets/props/city-kit-roads/"
const PLATFORM := "res://assets/props/platformer-kit/"
const TRUCKS := "res://assets/vehicles/"
const SAFE_LANES := [0, -1, -1, 0, 1, 1, 0, 0, -1, 0, 1, 0]
const OBSTACLE_DEPTH := [0.53, 0.38, 0.41, 0.20, 0.36, 1.04, 0.56, 0.67, 0.40, 1.17, 0.45, 0.89, 0.25, 0.40, 0.57, 0.75, 1.20, 0.53, 0.39, 0.40, 0.60, 0.55, 0.75, 0.45]
const OBSTACLE_WIDTH := [0.55, 0.38, 0.66, 0.80, 0.78, 0.83, 0.53, 0.61, 0.79, 0.80, 0.77, 0.76, 0.80, 0.82, 0.58, 0.81, 0.83, 0.72, 0.78, 0.77, 0.79, 0.75, 0.80, 0.50]
const OBSTACLE_TOP := [1.06, 0.84, 1.04, 0.87, 2.80, 3.20, 0.97, 1.18, 2.70, 2.60, 0.91, 2.68, 0.89, 2.37, 1.04, 2.60, 2.42, 0.96, 0.88, 1.87, 1.06, 2.44, 2.55, 0.86]
const OBSTACLE_BOTTOM := [0.0, 0.0, 0.0, 0.0, 1.29, 0.0, 0.0, 0.0, 1.29, 0.0, 0.0, 0.0, 0.0, 1.29, 0.0, 0.0, 0.0, 0.0, 0.0, 1.29, 0.0, 1.29, 0.0, 0.0]
const ROAD_WIDTH := 11.3
const TILES_PER_CHUNK := 3
const COINS_PER_ROW := 4
const KIND_CAPACITY := 3
const NEON_COMBO := [Kind.ROAD_BLOCK, Kind.LASER, Kind.HOVER_CAR, Kind.DATA_CRATE,
	Kind.LOW_SIGN, Kind.BEACON, Kind.SERVICE_BOT, Kind.ENERGY]
const NEON_CROSS := [Kind.SERVICE_BOT, Kind.DATA_CRATE, Kind.ROAD_BLOCK, Kind.LOW_SIGN,
	Kind.BEACON, Kind.ENERGY, Kind.LASER, Kind.HOVER_CAR]
const FOREST_COMBO := [Kind.LOG, Kind.BOUGH, Kind.BOULDER, Kind.WOOD_FENCE, Kind.BOUGH, Kind.WOOD_BOX, Kind.LOG_WALL, Kind.LOG]
const FOREST_CROSS := [Kind.BOULDER, Kind.LOG_WALL, Kind.LOG, Kind.WOOD_BOX, Kind.LOG, Kind.BOUGH, Kind.WOOD_FENCE, Kind.BOUGH]
const HARBOR_ORDER := [Kind.BARREL, Kind.BOOM, Kind.CARGO, Kind.DINGHY, Kind.BOOM, Kind.CARGO]
const HARBOR_CHAIN := [Kind.BARREL, Kind.BARREL, Kind.BOOM, Kind.BOOM, Kind.CARGO, Kind.DINGHY]


class Obstacle:
	var visual: Node3D
	var kind: int
	var lane: int
	var meter: float
	var armed := false


class Pickup:
	var visual: Node3D
	var meter: float
	var collected := true
	var base_y: float
	var finish_material: StandardMaterial3D


class Chunk:
	var visual: Node3D
	var index: int
	var obstacles: Array[Obstacle] = []
	var coins: Array[Pickup] = []
	var street: Array[Node3D] = []
	var shore: Array[Node3D] = []
	var boardwalk: Array[Node3D] = []
	var roads: Array[Node3D] = []
	var entry: Node3D
	var forest_entry: Node3D
	var forest_banks: Array[Node3D] = []
	var forest_verges: Array[Node3D] = []
	var forest_floors: Array[Node3D] = []
	var neon_approach: Array[Node3D] = []
	var neon_street: Array[Node3D] = []
	var neon_road: Array[Node3D] = []
	var traffic: Array[NeonScenery.Traffic] = []
	var neon_entry: Node3D
	var items: Node3D


var chunks: Array[Chunk] = []
var seed_value := 0
var phase := 0
var total_reuses := 0
var elapsed := 0.0
var scenes := {}
var lane_mark: QuadMesh
var lane_material: StandardMaterial3D
var coast: CoastScenery
var forest: ForestScenery
var neon: NeonScenery
var hazards: TrackHazards
var hearts: RunnerPickupPool
var timers: RunnerPickupPool
var visibility_debug := false
var debug_mesh := ImmediateMesh.new()
var debug_geometry: MeshInstance3D
var preview := false


func _ready() -> void:
	coast = CoastScenery.new(_model)
	forest = ForestScenery.new(coast, _model)
	neon = NeonScenery.new(coast, _model)
	hazards = TrackHazards.new(coast)
	hearts = RunnerPickupPool.new()
	add_child(hearts)
	hearts.taken.connect(func(at: Vector3): heart_taken.emit(at))
	timers = RunnerPickupPool.new(true)
	add_child(timers)
	timers.taken.connect(func(at: Vector3): timer_taken.emit(at))
	debug_geometry = MeshInstance3D.new()
	debug_geometry.mesh = debug_mesh
	var outline := StandardMaterial3D.new()
	outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline.albedo_color = Color("#ffe297")
	debug_geometry.material_override = outline
	debug_geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(debug_geometry)
	debug_geometry.hide()
	lane_mark = QuadMesh.new()
	lane_mark.size = Vector2(0.09, 1.25)
	lane_material = StandardMaterial3D.new()
	lane_material.albedo_color = Color("#f6eecf")
	lane_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(Tuning.CHUNK_COUNT):
		chunks.append(_build_chunk(i))


func _model(parent: Node3D, path: String, at: Vector3, size: Vector3, angle := 0.0, shadow := true) -> Node3D:
	var first_load := not scenes.has(path)
	if first_load:
		scenes[path] = load(path + ".glb")
	var scene: PackedScene = scenes[path]
	var item := scene.instantiate() as Node3D
	item.position = at
	item.scale = size
	item.rotation.y = angle
	if first_load and (path.begins_with(ForestScenery.NATURE) or path.begins_with(ForestScenery.CASTLE)):
		forest.finish_model(item, path)
	if first_load and path.begins_with("res://assets/neon/"):
		neon.finish_model(item, path)
	if first_load and path.begins_with(CoastScenery.PLANTS + "tree-palm"):
		coast.finish_palm(item)
	parent.add_child(item)
	if not shadow:
		for child in item.find_children("*", "MeshInstance3D", true, false):
			child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if item is MeshInstance3D:
			item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return item


func _build_chunk(theme: int) -> Chunk:
	var chunk := Chunk.new()
	chunk.visual = Node3D.new()
	chunk.visual.name = "PooledBlock%d" % theme
	add_child(chunk.visual)
	chunk.items = Node3D.new()
	chunk.items.name = "Items"
	chunk.visual.add_child(chunk.items)
	chunk.entry = Node3D.new()
	chunk.visual.add_child(chunk.entry)
	_build_gate(chunk.entry)
	chunk.forest_entry = Node3D.new()
	chunk.visual.add_child(chunk.forest_entry)
	_build_forest_gate(chunk.forest_entry)
	chunk.neon_entry = Node3D.new()
	chunk.visual.add_child(chunk.neon_entry)
	neon.entry(chunk.neon_entry)
	for tile in range(TILES_PER_CHUNK):
		var z := -6.0 - tile * Tuning.ROW_STEP
		var road := Node3D.new()
		var street := Node3D.new()
		var shore := Node3D.new()
		var boardwalk := Node3D.new()
		var forest_bank := Node3D.new()
		var forest_floor := Node3D.new()
		var verge := Node3D.new()
		var city_edge := Node3D.new()
		var city_street := Node3D.new()
		var city_road := Node3D.new()
		for group in [road, street, shore, boardwalk, forest_bank, forest_floor, verge, city_edge, city_street, city_road]:
			chunk.visual.add_child(group)
		chunk.roads.append(road)
		chunk.street.append(street)
		chunk.shore.append(shore)
		chunk.boardwalk.append(boardwalk)
		chunk.forest_banks.append(forest_bank)
		chunk.forest_verges.append(verge)
		chunk.forest_floors.append(forest_floor)
		chunk.neon_approach.append(city_edge)
		chunk.neon_street.append(city_street)
		chunk.neon_road.append(city_road)
		neon.build_approach(city_edge, theme, tile, z)
		neon.build_asphalt(city_road, z)
		var storefronts := Node3D.new()
		city_street.add_child(storefronts)
		neon.build_street(storefronts, city_street, theme, tile, z, chunk.traffic)
		_build_street(street, theme, tile, z)
		coast.build_shore(shore, theme, tile, z)
		coast.boardwalk(boardwalk, z)
		forest.build_banks(forest_bank, theme, tile, z)
		forest.build_verge(verge, tile, z)
		forest.floor_tile(forest_floor, z, tile == 1)
		_model(road, CITY + ("road-straight-lightposts" if tile == 1 else "road-straight"),
			Vector3(0, 0, z), Vector3(ROAD_WIDTH, 6.8, 12))
		coast.asphalt_strip(road, z)
		_build_marks(chunk.visual, z)
		for group in [street, shore, boardwalk, forest_bank, forest_floor, city_edge, storefronts]:
			_batch_repeats(group)
	# Pool each kit piece at chunk scope. A full kind uses another piece in the same kit.
	for kind in range(Kind.size()):
		for slot in range(KIND_CAPACITY):
			var obstacle := Obstacle.new()
			obstacle.kind = kind
			obstacle.visual = _build_obstacle(chunk.items, kind)
			hazards.style(obstacle.visual, OBSTACLE_WIDTH[kind], OBSTACLE_DEPTH[kind],
				OBSTACLE_BOTTOM[kind], OBSTACLE_TOP[kind], kind >= Kind.LOG)
			chunk.obstacles.append(obstacle)
	for coin_index in range(Tuning.ROWS_PER_CHUNK * COINS_PER_ROW):
		var coin := Pickup.new()
		coin.visual = _model(chunk.items, CoastScenery.ARCADE + "coin-gold", Vector3.ZERO, Vector3.ONE * 1.04, 0.0, false)
		_finish_coin(coin)
		chunk.coins.append(coin)
	return chunk


func _batch_repeats(group: Node3D) -> void:
	var batches := {}
	for item in group.find_children("*", "MeshInstance3D", true, false):
		var source := item as MeshInstance3D
		if not source.mesh or source.get_child_count() or source.material_override:
			continue
		var key := [source.mesh.get_instance_id(), source.cast_shadow]
		if not batches.has(key):
			batches[key] = []
		batches[key].append(source)
	var local := group.global_transform.affine_inverse()
	for batch: Array in batches.values():
		if batch.size() < 2:
			continue
		var template := batch[0] as MeshInstance3D
		var instance := MultiMeshInstance3D.new()
		var casting := template.cast_shadow
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_3D
		mesh.mesh = template.mesh
		mesh.instance_count = batch.size()
		for index in batch.size():
			var source := batch[index] as MeshInstance3D
			mesh.set_instance_transform(index, local * source.global_transform)
			source.free()
		instance.multimesh = mesh
		instance.cast_shadow = casting
		group.add_child(instance)


func _build_street(parent: Node3D, theme: int, tile: int, z: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = theme * 103 + tile + 701
	var shops := ["building-small-a", "building-small-b", "building-small-c", "building-small-d"]
	var towers := ["building-f", "building-i", "building-m", "building-skyscraper-a", "building-skyscraper-c"]
	_model(parent, CITY + "grass", Vector3(0, -0.69, z), Vector3(155, 8, 12), 0.0, false)
	for side in [-1, 1]:
		var s := float(side)
		var plaza: bool = side == 1 and (theme + tile) % 4 == 2
		var ground := "pavement-fountain" if plaza else ("pavement" if side < 0 else "grass")
		_model(parent, CITY + ground, Vector3(s * 8.85, -0.14, z), Vector3(6.4, 6.0, 12), s * PI, plaza)
		if side < 0:
			var shop: String = shops[(theme + tile) % shops.size()]
			var tower: String = towers[(theme * 2 + tile) % towers.size()]
			_model(parent, CITY + shop, Vector3(-10.4, 0.20, z - 0.6), Vector3.ONE * rng.randf_range(5.0, 6.5), PI / 2.0)
			if tile == 1:
				_model(parent, COMMERCIAL + "detail-awning-wide", Vector3(-8.38, 2.11, z + 0.48),
					Vector3.ONE * 5.8, PI / 2, false)
			_model(parent, COMMERCIAL + tower, Vector3(-22.0 - rng.randf_range(0.0, 6.0), -0.1, z - 2.2), Vector3.ONE * rng.randf_range(8.8, 10.9), PI / 2.0, false)
		elif not plaza:
			if (theme + tile) % 3 == 0:
				_model(parent, CITY + "grass-trees-tall", Vector3(11.0, 0.04, z), Vector3(7.1, 7.5, 9.1), PI * float(tile % 2))
			else:
				for tree in range(2):
					_model(parent, CoastScenery.PLANTS + "tree-detailed", Vector3(9.1 + tree * 2.6, 0.31, z - tree * 3.8), Vector3.ONE * rng.randf_range(3.8, 5.5), rng.randf_range(-PI, PI))
		var greenery := "plant-bushdetailed" if (theme + tile) % 3 == 0 else "plant-bushlarge"
		_model(parent, NATURE + greenery, Vector3(s * 6.74, 0.19, z + 3.8), Vector3.ONE * 2.25, rng.randf_range(-PI, PI), false)
		var flowers: String = ["flower-redb", "flower-yellowb", "flower-purpleb"][(theme + tile) % 3]
		for bunch in range(3):
			_model(parent, NATURE + flowers, Vector3(s * (6.2 + bunch * 0.35), 0.20, z + 1.4 + rng.randf_range(-0.46, 0.46)), Vector3.ONE * rng.randf_range(1.25, 1.7), rng.randf_range(-PI, PI), false)
		if side > 0 and not plaza:
			for length in range(2):
				_model(parent, NATURE + "fence-planks", Vector3(8.40, 0.19, z + 1.7 + length * 2.6), Vector3(2.6, 1.9, 1.9), PI/2.0)
			if tile == 2:
				_model(parent, CoastScenery.PLANTS + "sign", Vector3(6.9, 0.24, z - 2.3),
					Vector3.ONE * 3.7, -0.30, false)


func _build_marks(parent: Node3D, z: float) -> void:
	var mesh := MultiMesh.new()
	mesh.mesh = lane_mark
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.instance_count = 6
	for dash in range(3):
		for side in range(2):
			var x := (side - 0.5) * Tuning.LANE
			mesh.set_instance_transform(dash * 2 + side,
				Transform3D(Basis(Vector3.RIGHT, -PI / 2), Vector3(x, 0.012, z + (dash - 1) * 4.0)))
	var marks := MultiMeshInstance3D.new()
	marks.multimesh = mesh
	marks.material_override = lane_material
	marks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(marks)


func _build_gate(parent: Node3D) -> void:
	for side in [-1, 1]:
		_model(parent, CoastScenery.PIRATE + "flag-high-pennant", Vector3(side * 4.85, 0, 0),
			Vector3.ONE * 1.4, PI if side > 0 else 0.0)
	coast.label(parent, "CORAL HARBOR", Vector3(-6.5, 3.35, -1.1), 0.0082, Color("#fff1c3"), CoastScenery.FONT)
	coast.label(parent, "산호빛 항구", Vector3(-6.5, 2.83, -1.1), 0.0062, Color("#ffd7ad"), CoastScenery.KOREAN)


func _build_forest_gate(parent: Node3D) -> void:
	_model(parent, CoastScenery.PLANTS + "sign", Vector3(-6.4, 0.19, -0.7),
		Vector3.ONE * 8.3, PI, false)
	coast.label(parent, "PINEWIND VALLEY", Vector3(-6.4, 4.1, -0.33), 0.0068, Color("#edffd4"), CoastScenery.FONT)
	coast.label(parent, "솔바람 계곡", Vector3(-6.4, 3.67, -0.32), 0.0060, Color("#dcfcc5"), CoastScenery.KOREAN)


func _finish_coin(coin: Pickup) -> void:
	for item in coin.visual.find_children("*", "MeshInstance3D", true, false):
		var mesh := item as MeshInstance3D
		var original := mesh.get_active_material(0) as StandardMaterial3D
		if not original:
			continue
		var metal := original.duplicate() as StandardMaterial3D
		metal.metallic = 0.24
		metal.roughness = 0.25
		metal.emission_enabled = true
		metal.emission = Color("#ffab2a")
		metal.emission_energy_multiplier = 0.13
		mesh.set_surface_override_material(0, metal)
		coin.finish_material = metal
		break


func _build_obstacle(parent: Node3D, kind: int) -> Node3D:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	match kind:
		Kind.CRATE:
			_model(pivot, CoastScenery.ARCADE + "crate-item-strong", Vector3.ZERO, Vector3.ONE * 1.75)
		Kind.CONE:
			_model(pivot, WORKS + "construction-cone", Vector3.ZERO, Vector3.ONE * 9.0)
		Kind.BARRIER:
			_model(pivot, WORKS + "construction-barrier", Vector3.ZERO, Vector3(5.8, 8.0, 5.8), PI/2.0)
		Kind.FENCE:
			_model(pivot, PLATFORM + "fence-low-straight", Vector3(0, 0, -0.79), Vector3(1.6, 2.9, 2.0))
		Kind.OVERHEAD:
			for side in [-1, 1]:
				_model(pivot, WORKS + "construction-barrier", Vector3(side * 0.95, 0, 0), Vector3(3.25, 10.2, 4.3))
			_model(pivot, WORKS + "construction-barrier", Vector3(0, 1.29, 0), Vector3(5.0, 8.0, 9.0), PI/2.0)
			var sign := Label3D.new()
			sign.text = "▼"
			sign.font = preload("res://assets/ui/Outfit-Medium.ttf")
			sign.font_size = 64
			sign.pixel_size = 0.010
			sign.outline_size = 16
			sign.modulate = Color("#fff4c2")
			sign.outline_modulate = Color("#263351")
			sign.position = Vector3(0, 2.10, 0.41)
			sign.no_depth_test = false
			pivot.add_child(sign)
		Kind.TRUCK:
			_model(pivot, TRUCKS + "vehicle-truck-yellow", Vector3.ZERO, Vector3.ONE * 1.55, PI)
		Kind.BARREL:
			_model(pivot, CoastScenery.PIRATE + "barrel", Vector3.ZERO, Vector3.ONE * 0.80)
			coast.label(pivot, "▲", Vector3(0, 0.74, 0.56), 0.006, Color("#ffdf79"), CoastScenery.KOREAN)
		Kind.CARGO:
			_model(pivot, CoastScenery.PIRATE + "crate-bottles", Vector3.ZERO, Vector3.ONE * 1.10)
		Kind.BOOM:
			for side in [-1, 1]:
				_model(pivot, CoastScenery.PIRATE + "barrel",
					Vector3(side * 1.00, 0, 0), Vector3(0.31, 1.08, 0.37))
			_model(pivot, CoastScenery.ARCADE + "fence-rope", Vector3(0, 1.29, 0),
				Vector3(2.02, 2.55, 3.50))
			coast.label(pivot, "▼", Vector3(0, 1.91, 0.44), 0.009, Color("#fff0a2"), CoastScenery.KOREAN)
		Kind.DINGHY:
			_model(pivot, CoastScenery.PIRATE + "boat-row-large", Vector3(0, -0.08, 0),
				Vector3(0.57, 1.45, 0.80), -0.11)
			_model(pivot, CoastScenery.PIRATE + "crate-bottles", Vector3(0, 0.39, 0.25), Vector3(0.92, 1.27, 0.88))
			coast.label(pivot, "‹   ›", Vector3(0, 1.66, 0.99), 0.008, Color("#ffc088"), CoastScenery.FONT)
		Kind.LOG:
			_model(pivot, ForestScenery.NATURE + "log-large", Vector3.ZERO, Vector3(1.51, 2.18, 1.44))
			coast.label(pivot, "▲", Vector3(0, 0.77, 0.52), 0.007, Color("#ffe0a0"), CoastScenery.KOREAN)
		Kind.BOULDER:
			_model(pivot, ForestScenery.NATURE + "rock-tallc", Vector3(0, 0.13, 0.0), Vector3(3.2, 3.4, 3.9), 0.22)
			coast.label(pivot, "‹   ›", Vector3(0, 1.56, 0.91), 0.008, Color("#ffddb1"), CoastScenery.FONT)
		Kind.WOOD_FENCE:
			_model(pivot, ForestScenery.NATURE + "fence-simplelow", Vector3(0, 0, 0.76),
				Vector3(1.50, 4.50, 1.60))
		Kind.BOUGH:
			for side in [-1, 1]:
				_model(pivot, ForestScenery.NATURE + "log-large", Vector3(side * 0.97, 0.77, 0.0),
					Vector3(1.44, 0.61, 0.73), 0).rotation.z = PI / 2.0
			_model(pivot, ForestScenery.NATURE + "log-large", Vector3(0, 1.29, 0), Vector3(2.02, 1.0, 1.30))
			_model(pivot, ForestScenery.NATURE + "plant-bushlarge", Vector3(0.21, 1.62, -0.03),
				Vector3(3.28, 2.10, 2.20), 0.23)
			coast.label(pivot, "▼", Vector3(0, 1.60, 0.44), 0.008, Color("#e5ffb8"), CoastScenery.KOREAN)
		Kind.WOOD_BOX:
			_model(pivot, ForestScenery.CRATE_KIT + "crate", Vector3.ZERO, Vector3.ONE * 0.95)
		Kind.LOG_WALL:
			_model(pivot, ForestScenery.NATURE + "log-stack", Vector3.ZERO, Vector3(3.55, 4.13, 2.13))
			_model(pivot, ForestScenery.NATURE + "log-stack", Vector3(0.10, 1.20, 0.05), Vector3(2.80, 3.4, 1.82))
			coast.label(pivot, "‹   ›", Vector3(0, 1.42, 0.90), 0.008, Color("#ffddb1"), CoastScenery.FONT)
		Kind.HOVER_CAR:
			_model(pivot, NeonScenery.SPACE + "craft-cargob", Vector3(0, 0.19, 0),
				Vector3(1.03, 2.46, 0.87), PI)
		Kind.ROAD_BLOCK:
			_model(pivot, NeonScenery.SPACE + "machine-generator", Vector3(-0.33, 0, 0.08),
				Vector3(1.70, 2.30, 1.32), 0.0)
		Kind.ENERGY:
			_model(pivot, NeonScenery.SPACE + "gate-simple", Vector3.ZERO, Vector3(1.54, 0.79, 1.51))
			neon._bar(pivot, Vector3(0, 0.54, 0.24), Vector2(1.30, 0.44), neon.teal_screen, false)
		Kind.LASER:
			for side in [-1, 1]:
				_model(pivot, NeonScenery.SPACE + "machine-barrellarge", Vector3(1.07 * side, 0, 0),
					Vector3(0.62, 2.62, 0.75))
			neon._bar(pivot, Vector3(0, 1.44, 0.13), Vector2(1.98, 0.14), neon.yellow_light, false)
			neon._bar(pivot, Vector3(0, 1.34, 0.13), Vector2(1.98, 0.055), neon.yellow_light, false)
		Kind.DATA_CRATE:
			_model(pivot, NeonScenery.CARGO + "crate-wide", Vector3(0.23, 0.04, 0),
				Vector3(1.93, 4.76, 0.97))
			_model(pivot, NeonScenery.CARGO + "crate-medium", Vector3(-0.62, 0.08, 0.06),
				Vector3(0.90, 2.09, 0.79))
		Kind.LOW_SIGN:
			for side in [-1, 1]:
				_model(pivot, NeonScenery.ROAD + "light-square-double", Vector3(side * 1.05, 0, 0),
					Vector3(5.5, 3.54, 2.1), PI / 2.0, false)
			neon._bar(pivot, Vector3(0, 1.74, 0.23), Vector2(1.94, 0.87), neon.pink_screen, false)
		Kind.SERVICE_BOT:
			_model(pivot, NeonScenery.SPACE + "rover", Vector3.ZERO, Vector3(5.10, 6.40, 4.00), -0.10)
		Kind.BEACON:
			_model(pivot, NeonScenery.SPACE + "machine-barrellarge", Vector3.ZERO, Vector3(1.30, 1.43, 1.31))
	return pivot


func reset(run_seed: int, start_at := 0.0, show_preview := false) -> void:
	seed_value = run_seed
	phase = posmod(run_seed, SAFE_LANES.size())
	total_reuses = 0
	preview = show_preview
	hearts.reset(run_seed)
	timers.reset(run_seed)
	_set_visibility_debug(false)
	_pickups_through(start_at - 0.58, INF)
	var first := floori(start_at / Tuning.CHUNK_LENGTH) - 1
	for index in range(first, first + chunks.size()):
		_fill_chunk(chunks[posmod(index + 1, chunks.size())], index)
	scroll(start_at, 0.0)


func _fill_chunk(chunk: Chunk, index: int) -> void:
	chunk.index = index
	var start := index * Tuning.CHUNK_LENGTH
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + index + 1000003
	for obstacle in chunk.obstacles:
		obstacle.armed = false
		obstacle.visual.hide()
	for coin in chunk.coins:
		coin.collected = true
		coin.visual.hide()
	for tile in range(TILES_PER_CHUNK):
		var tile_start := start + tile * Tuning.ROW_STEP
		chunk.roads[tile].visible = tile_start < Tuning.HARBOR_START
		chunk.street[tile].visible = tile_start < Tuning.HARBOR_APPROACH
		chunk.shore[tile].visible = tile_start >= Tuning.HARBOR_APPROACH and tile_start < Tuning.FOREST_APPROACH
		chunk.boardwalk[tile].visible = tile_start >= Tuning.HARBOR_START and tile_start < Tuning.FOREST_START
		chunk.forest_banks[tile].visible = tile_start >= Tuning.FOREST_APPROACH and tile_start < Tuning.NEON_START
		chunk.forest_verges[tile].visible = tile_start >= Tuning.FOREST_GREENBELT and tile_start < Tuning.FOREST_APPROACH
		chunk.forest_floors[tile].visible = tile_start >= Tuning.FOREST_START and tile_start < Tuning.NEON_ASPHALT
		chunk.neon_approach[tile].visible = tile_start >= Tuning.NEON_APPROACH
		chunk.neon_street[tile].visible = tile_start >= Tuning.NEON_START
		chunk.neon_road[tile].visible = tile_start >= Tuning.NEON_ASPHALT
	chunk.entry.visible = not preview and start <= Tuning.HARBOR_START and start + Tuning.CHUNK_LENGTH > Tuning.HARBOR_START
	chunk.entry.position.z = -(Tuning.HARBOR_START - start)
	chunk.forest_entry.visible = not preview and start <= Tuning.FOREST_START and start + Tuning.CHUNK_LENGTH > Tuning.FOREST_START
	chunk.forest_entry.position.z = -(Tuning.FOREST_START - start)
	chunk.neon_entry.visible = not preview and start <= Tuning.NEON_START and start + Tuning.CHUNK_LENGTH > Tuning.NEON_START
	chunk.neon_entry.position.z = -(Tuning.NEON_START - start)
	chunk.items.visible = not preview
	if preview:
		return

	# Keep the original early grids. The mixed forest chunk uses 12 m
	# thereafter, with a stable row index and no short gap at either boundary.
	var dense_begin := ceili(Tuning.HARBOR_START / Tuning.CHUNK_LENGTH)
	var late_begin := floori(Tuning.FOREST_START / Tuning.CHUNK_LENGTH)
	var dense := index >= dense_begin and index < late_begin
	var row_count := Tuning.ROWS_PER_CHUNK if dense else 3
	var used: Array[int] = []
	used.resize(Kind.size())
	used.fill(0)
	for row in range(row_count):
		var offset := 4.0 + row * Tuning.ROW_STEP
		var row_number := index * 3 + row
		if dense:
			offset = 3.0 + row * Tuning.HARBOR_ROW_STEP
			row_number = dense_begin * 3 + (index - dense_begin) * Tuning.ROWS_PER_CHUNK + row
		elif index >= late_begin:
			offset = 3.0 + row * Tuning.LATE_ROW_STEP
			row_number = dense_begin * 3 + (late_begin - dense_begin) * Tuning.ROWS_PER_CHUNK + (index - late_begin) * 3 + row
		var meter := start + offset
		if meter >= Tuning.FIRST_ROW:
			_fill_row(chunk, row, row_number, offset, meter, rng, used)


func _fill_row(chunk: Chunk, row: int, row_number: int, offset: float, meter: float, rng: RandomNumberGenerator, used: Array[int]) -> void:
	var harbor := meter >= Tuning.HARBOR_START
	var safe: int = SAFE_LANES[posmod(row_number + phase, SAFE_LANES.size())]
	var closed := [-1, 0, 1]
	closed.erase(safe)
	if rng.randi_range(0, 1) == 1:
		closed.reverse()
	var difficulty := Tuning.double_row_chance_at(meter)
	var permits_pair := meter < Tuning.FOREST_START or row_number % 2 == 1
	var count := 2 if permits_pair and meter > Tuning.DOUBLE_ROW_START and rng.randf() < difficulty else 1
	var kind_limit := Kind.CONE if meter < 45.0 else (Kind.FENCE if meter < 105.0 else Kind.TRUCK)
	var forest_route := meter >= Tuning.FOREST_START
	var neon_route := meter >= Tuning.NEON_START
	var lowest := Kind.HOVER_CAR if neon_route else (Kind.LOG if forest_route else (Kind.BARREL if harbor else Kind.CRATE))
	var highest := Kind.BEACON if neon_route else (Kind.LOG_WALL if forest_route else (Kind.DINGHY if harbor else kind_limit))
	if meter == Tuning.FIRST_ROW:
		safe = 0
		closed = [-1, 1]
		count = 1
	for slot in range(count):
		var kind := rng.randi_range(Kind.CRATE, kind_limit)
		if neon_route:
			var chain := NEON_COMBO if slot == 0 else NEON_CROSS
			kind = chain[posmod(row_number + phase, chain.size())]
		elif forest_route:
			var chain := FOREST_COMBO if slot == 0 else FOREST_CROSS
			kind = chain[posmod(row_number + phase, chain.size())]
		elif harbor:
			# Low cargo and marked booms alternate in the adjacent lanes.
			# The open lane stays within one move of the previous row's exit.
			var pattern := HARBOR_CHAIN if slot == 0 and meter > 1900.0 else HARBOR_ORDER
			kind = pattern[posmod(row_number + phase + slot * 3, pattern.size())]
		elif meter == Tuning.FIRST_ROW:
			kind = Kind.CRATE
		while used[kind] >= KIND_CAPACITY:
			kind = lowest + posmod(kind - lowest + 1, highest - lowest + 1)
		var index_in_pool := kind * KIND_CAPACITY + used[kind]
		used[kind] += 1
		var obstacle := chunk.obstacles[index_in_pool]
		obstacle.lane = closed[slot]
		obstacle.meter = meter
		obstacle.armed = true
		obstacle.visual.position = Vector3(obstacle.lane * Tuning.LANE, 0, -offset)
		obstacle.visual.show()
	var jump_line := meter > 65.0 and rng.randf() < (0.58 if forest_route else (0.44 if harbor else 0.29))
	for slot in range(COINS_PER_ROW):
		var coin := chunk.coins[row * COINS_PER_ROW + slot]
		var advance := -7.2 + slot * 1.9 if harbor else -8.65 + slot * 2.45
		var lift := sin(float(slot) * PI / 3.0) * 1.63 if jump_line else 0.0
		coin.meter = meter + advance
		coin.collected = false
		coin.base_y = 0.89 + lift
		coin.visual.position = Vector3(safe * Tuning.LANE, coin.base_y, -offset - advance)
		coin.visual.show()


func scroll(distance: float, dt: float, speed := 0.0) -> void:
	elapsed += dt
	var base_index := floori(distance / Tuning.CHUNK_LENGTH) - 1
	for chunk in chunks:
		if chunk.index < base_index:
			var cycles := ceili(float(base_index - chunk.index) / chunks.size())
			_fill_chunk(chunk, chunk.index + cycles * chunks.size())
			total_reuses += cycles
		chunk.visual.position.z = distance - chunk.index * Tuning.CHUNK_LENGTH
		chunk.visual.visible = chunk.visual.position.z > -147.0 and chunk.visual.position.z < 55.0
		if chunk.visual.visible and chunk.index * Tuning.CHUNK_LENGTH >= Tuning.NEON_START:
			neon.animate(chunk.traffic, elapsed, speed)
		if preview or chunk.visual.position.z < -90.0:
			continue
		for coin in chunk.coins:
			if not coin.collected:
				var spin := fposmod(elapsed * 3.5 + coin.meter * 0.15, TAU)
				coin.visual.rotation.y = spin
				coin.visual.position.y = coin.base_y + sin(spin) * 0.070
				coin.visual.rotation.z = sin(spin * 0.5 + PI) * 0.09
				if coin.finish_material:
					coin.finish_material.emission_energy_multiplier = 0.11 + 0.34 * pow(absf(cos(spin)), 12.0)

	if not preview:
		_pickups_through(distance + Tuning.PICKUP_LOOKAHEAD, distance - 0.58)
		hearts.scroll(distance, dt)
		timers.scroll(distance, dt)
	if visibility_debug:
		_update_debug_boxes(distance)


func check_contacts(previous: float, distance: float, player: MurangPlayer) -> void:
	var bottom := player.elevation + 0.06
	var top := player.elevation + player.height()
	for chunk in chunks:
		if absf(chunk.visual.position.z - Tuning.CHUNK_LENGTH * 0.5) > Tuning.CHUNK_LENGTH:
			continue
		for obstacle in chunk.obstacles:
			if not obstacle.armed:
				continue
			var kind := obstacle.kind
			var reach: float = OBSTACLE_DEPTH[kind] + 0.24
			if previous > obstacle.meter + reach:
				obstacle.armed = false
				continue
			if distance < obstacle.meter - reach:
				continue
			if absf(player.position.x - obstacle.visual.position.x) >= OBSTACLE_WIDTH[kind] + 0.26:
				continue
			if bottom >= OBSTACLE_TOP[kind] or top <= OBSTACLE_BOTTOM[kind]:
				continue
			if player.immunity <= 0.0:
				obstacle.armed = false
				player.hit()
				obstacle_hit.emit(Vector3(obstacle.visual.position.x, 0.8, 0.0))
		for coin in chunk.coins:
			if coin.collected:
				continue
			if previous > coin.meter + 0.48:
				coin.collected = true
				coin.visual.hide()
				continue
			if distance < coin.meter - 0.48 or absf(player.position.x - coin.visual.position.x) > 0.63:
				continue
			if bottom > coin.base_y + 0.37 or top < coin.base_y - 0.07:
				continue
			coin.collected = true
			coin.visual.hide()
			coin_taken.emit(Vector3(coin.visual.position.x, coin.visual.position.y, 0.0))

	hearts.check_contacts(previous, distance, player)
	timers.check_contacts(previous, distance, player)


func spawn_lane_at(distance: float) -> int:
	var available := [0, -1, 1]
	for chunk in chunks:
		for obstacle in chunk.obstacles:
			if obstacle.armed and obstacle.meter >= distance and obstacle.meter < distance + Tuning.HARBOR_ROW_STEP:
				available.erase(obstacle.lane)
	return available[0] if not available.is_empty() else 0


func _pickup_lane(meter: float) -> int:
	var nearest := 10.0
	var lane_id := 0
	for chunk in chunks:
		for row in range(Tuning.ROWS_PER_CHUNK):
			var coin := chunk.coins[row * COINS_PER_ROW]
			if coin.collected:
				continue
			var row_meter := coin.meter + (7.2 if coin.meter >= Tuning.HARBOR_START - 7.2 else 8.65)
			var gap := absf(meter - row_meter)
			if gap < nearest:
				nearest = gap
				lane_id = roundi(coin.visual.position.x / Tuning.LANE)
	return lane_id


func _pickups_through(through: float, earliest_visible: float) -> void:
	while hearts.schedule.next_meter <= through:
		var marker := hearts.schedule.next_meter
		var heart := hearts.schedule.advance(marker)
		var timer := timers.schedule.advance(marker, heart)
		if heart >= earliest_visible:
			hearts.spawn_natural(heart, _pickup_lane(heart))
		if timer >= earliest_visible:
			timers.spawn_natural(timer, _pickup_lane(timer))


func debug_pickup(distance: float, is_timer: bool) -> bool:
	var target := timers if is_timer else hearts
	for offset in range(16, 27):
		var meter := distance + offset
		if not hearts.has_near(meter, 2.40) and not timers.has_near(meter, 2.40):
			return target.spawn_debug(meter, _pickup_lane(meter))
	return false


func _set_visibility_debug(enabled: bool) -> void:
	visibility_debug = enabled
	debug_geometry.visible = enabled
	if not enabled:
		debug_mesh.clear_surfaces()


func _update_debug_boxes(distance: float) -> void:
	debug_mesh.clear_surfaces()
	var drawn := false
	for chunk in chunks:
		for obstacle in chunk.obstacles:
			if not obstacle.armed:
				continue
			var z := distance - obstacle.meter
			if z > 3.0 or z < -42.0:
				continue
			var kind := obstacle.kind
			var x := obstacle.lane * Tuning.LANE
			var w: float = OBSTACLE_WIDTH[kind]
			var low: float = OBSTACLE_BOTTOM[kind]
			var high: float = OBSTACLE_TOP[kind]
			var front: float = z + OBSTACLE_DEPTH[kind]
			if not drawn:
				debug_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
				drawn = true
			var corners := [Vector3(x - w, low, front), Vector3(x + w, low, front),
				Vector3(x + w, high, front), Vector3(x - w, high, front)]
			for i in range(4):
				debug_mesh.surface_add_vertex(corners[i])
				debug_mesh.surface_add_vertex(corners[(i + 1) % 4])
	if drawn:
		debug_mesh.surface_end()
