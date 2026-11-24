class_name RunnerTrack
extends Node3D

signal coin_taken(at: Vector3)
signal obstacle_hit(at: Vector3)

enum Kind { CRATE, CONE, BARRIER, FENCE, OVERHEAD, TRUCK }

const CITY := "res://assets/city/"
const PARK := "res://assets/park/"
const NATURE := "res://assets/props/nature-kit/"
const COMMERCIAL := "res://assets/props/city-kit-commercial/"
const WORKS := "res://assets/props/city-kit-roads/"
const PLATFORM := "res://assets/props/platformer-kit/"
const TRUCKS := "res://assets/vehicles/"
const SAFE_LANES := [0, -1, -1, 0, 1, 1, 0, 0, -1, 0, 1, 0]
const OBSTACLE_DEPTH := [0.53, 0.38, 0.41, 0.20, 0.36, 1.04]
const OBSTACLE_WIDTH := [0.55, 0.38, 0.66, 0.80, 0.78, 0.83]
const OBSTACLE_TOP := [1.06, 0.84, 1.04, 0.87, 2.80, 3.20]
const OBSTACLE_BOTTOM := [0.0, 0.0, 0.0, 0.0, 1.06, 0.0]
const ROAD_WIDTH := 11.3
const ROAD_HEIGHT := 0.0


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


class Chunk:
	var visual: Node3D
	var index: int
	var obstacles: Array[Obstacle] = []
	var coins: Array[Pickup] = []


var chunks: Array[Chunk] = []
var seed_value := 0
var phase := 0
var total_reuses := 0
var elapsed := 0.0
var scenes := {}
var lane_mark: QuadMesh
var lane_material: StandardMaterial3D


func _ready() -> void:
	lane_mark = QuadMesh.new()
	lane_mark.size = Vector2(0.09, 1.25)
	lane_material = StandardMaterial3D.new()
	lane_material.albedo_color = Color("#befae5")
	lane_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(Tuning.CHUNK_COUNT):
		chunks.append(_build_chunk(i))


func _model(parent: Node3D, path: String, at: Vector3, size: Vector3, angle := 0.0, shadow := true) -> Node3D:
	if not scenes.has(path):
		scenes[path] = load(path + ".glb")
	var scene: PackedScene = scenes[path]
	var item := scene.instantiate() as Node3D
	item.position = at
	item.scale = size
	item.rotation.y = angle
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
	_build_street(chunk.visual, theme)
	# Each row can select up to two kinds. Two slots per kind allow matching pairs.
	for row in range(Tuning.ROWS_PER_CHUNK):
		for kind in range(Kind.size()):
			for slot in range(2):
				var obstacle := Obstacle.new()
				obstacle.kind = kind
				obstacle.visual = _build_obstacle(chunk.visual, kind)
				chunk.obstacles.append(obstacle)
		for coin_index in range(4):
			var coin := Pickup.new()
			coin.visual = _model(chunk.visual, PARK + "coin", Vector3.ZERO, Vector3.ONE * 0.88, 0.0, false)
			chunk.coins.append(coin)
	return chunk


func _build_street(parent: Node3D, theme: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = theme + 701
	var shops := ["building-small-a", "building-small-b", "building-small-c", "building-small-d"]
	var towers := ["building-f", "building-i", "building-m", "building-skyscraper-a", "building-skyscraper-c"]
	_model(parent, CITY + "grass", Vector3(0, -0.69, -18), Vector3(155, 8, 36), 0.0, false)
	for tile in range(3):
		var z := -6.0 - tile * Tuning.ROW_STEP
		_model(parent, CITY + ("road-straight-lightposts" if tile == 1 else "road-straight"),
			Vector3(0, ROAD_HEIGHT, z), Vector3(ROAD_WIDTH, 6.8, 12))
		for side in [-1, 1]:
			var s := float(side)
			var plaza: bool = side == 1 and (theme + tile) % 4 == 2
			var ground := "pavement-fountain" if plaza else ("pavement" if side < 0 else "grass")
			_model(parent, CITY + ground, Vector3(s * 8.85, -0.14, z), Vector3(6.4, 6.0, 12), s * PI, plaza)
			if side < 0:
				var shop: String = shops[(theme + tile) % shops.size()]
				var tower: String = towers[(theme * 2 + tile) % towers.size()]
				_model(parent, CITY + shop, Vector3(-10.4, 0.20, z - 0.6), Vector3.ONE * rng.randf_range(5.0, 6.5), PI / 2.0)
				_model(parent, COMMERCIAL + tower, Vector3(-22.0 - rng.randf_range(0.0, 6.0), -0.1, z - 2.2), Vector3.ONE * rng.randf_range(8.8, 10.9), PI / 2.0, false)
			elif not plaza:
				var grove := "grass-trees-tall" if (theme + tile) % 2 == 0 else "grass-trees"
				_model(parent, CITY + grove, Vector3(11.0, 0.04, z), Vector3(7.1, 7.5, 9.1), PI * float(tile % 2))
				if tile == 2 and theme % 3 == 0:
					_model(parent, COMMERCIAL + towers[(theme + 1) % towers.size()], Vector3(42.0, -0.1, z - 5), Vector3.ONE * 7.5, -PI / 2, false)
			var greenery := "plant-bushdetailed" if (theme + tile) % 3 == 0 else "plant-bushlarge"
			_model(parent, NATURE + greenery, Vector3(s * 6.74, 0.19, z + 3.8), Vector3.ONE * 2.25, rng.randf_range(-PI, PI), false)
			var flowers: String = ["flower-redb", "flower-yellowb", "flower-purpleb"][(theme + tile) % 3]
			for bunch in range(3):
				_model(parent, NATURE + flowers, Vector3(s * (6.2 + bunch * 0.35), 0.20, z + 1.4 + rng.randf_range(-0.46, 0.46)), Vector3.ONE * rng.randf_range(1.25, 1.7), rng.randf_range(-PI, PI), false)
			if side > 0 and not plaza:
				for length in range(2):
					_model(parent, NATURE + "fence-planks", Vector3(8.40, 0.19, z + 1.7 + length * 2.6), Vector3(2.6, 1.9, 1.9), PI/2.0)
		for dash in range(3):
			for side in [-1, 1]:
				var mark := MeshInstance3D.new()
				mark.mesh = lane_mark
				mark.material_override = lane_material
				mark.rotation.x = -PI / 2.0
				mark.position = Vector3(float(side) * Tuning.LANE / 2.0, 0.008, z + (dash - 1) * 4.0)
				mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				parent.add_child(mark)


func _build_obstacle(parent: Node3D, kind: int) -> Node3D:
	var pivot := Node3D.new()
	parent.add_child(pivot)
	match kind:
		Kind.CRATE:
			_model(pivot, PLATFORM + "crate", Vector3.ZERO, Vector3.ONE * 2.12)
		Kind.CONE:
			_model(pivot, WORKS + "construction-cone", Vector3.ZERO, Vector3.ONE * 9.0)
		Kind.BARRIER:
			_model(pivot, WORKS + "construction-barrier", Vector3.ZERO, Vector3(5.8, 8.0, 5.8), PI/2.0)
		Kind.FENCE:
			_model(pivot, PLATFORM + "fence-low-straight", Vector3(0, 0, -0.79), Vector3(1.6, 2.9, 2.0))
		Kind.OVERHEAD:
			for side in [-1, 1]:
				_model(pivot, WORKS + "construction-barrier", Vector3(side * 0.95, 0, 0), Vector3(3.25, 10.2, 4.3))
			_model(pivot, WORKS + "construction-barrier", Vector3(0, 1.06, 0), Vector3(5.0, 8.0, 9.0), PI/2.0)
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
	return pivot


func reset(run_seed: int) -> void:
	seed_value = run_seed
	phase = posmod(run_seed, SAFE_LANES.size())
	total_reuses = 0
	for i in range(chunks.size()):
		_fill_chunk(chunks[i], i - 1)
	scroll(0.0, 0.0)


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
	for row in range(Tuning.ROWS_PER_CHUNK):
		var offset := 4.0 + row * Tuning.ROW_STEP
		var meter := start + offset
		if meter < Tuning.FIRST_ROW:
			continue
		var row_number := index * Tuning.ROWS_PER_CHUNK + row
		var safe: int = SAFE_LANES[posmod(row_number + phase, SAFE_LANES.size())]
		# One open lane always remains. Consecutive open lanes are at most
		# one move apart, and row spacing is constant across chunk seams.
		var other_lanes := [-1, 0, 1]
		other_lanes.erase(safe)
		if rng.randi_range(0, 1) == 1:
			other_lanes.reverse()
		var count := 2 if meter > 100.0 and rng.randf() < minf(0.86, (meter - 70.0) / 550.0) else 1
		var kind_limit := Kind.CONE if meter < 45.0 else (Kind.FENCE if meter < 105.0 else Kind.TRUCK)
		var first_kind := -1
		for slot in range(count):
			var kind := rng.randi_range(Kind.CRATE, kind_limit)
			if meter == Tuning.FIRST_ROW:
				kind = Kind.CRATE
				safe = 0
				other_lanes = [-1, 1]
			var duplicate := int(first_kind == kind)
			var index_in_pool := row * Kind.size() * 2 + kind * 2 + duplicate
			var obstacle := chunk.obstacles[index_in_pool]
			obstacle.lane = other_lanes[slot]
			obstacle.meter = meter
			obstacle.armed = true
			obstacle.visual.position = Vector3(obstacle.lane * Tuning.LANE, 0, -offset)
			obstacle.visual.show()
			first_kind = kind
		var jump_line := meter > 65.0 and rng.randf() < 0.29
		for slot in range(4):
			var coin := chunk.coins[row * 4 + slot]
			var advance := -8.65 + slot * 2.45
			var lift := sin(float(slot) * PI / 3.0) * 1.63 if jump_line else 0.0
			coin.meter = meter + advance
			coin.collected = false
			coin.base_y = 0.91 + lift
			coin.visual.position = Vector3(safe * Tuning.LANE, coin.base_y, -offset - advance)
			coin.visual.show()


func scroll(distance: float, dt: float) -> void:
	elapsed += dt
	var base_index := floori(distance / Tuning.CHUNK_LENGTH) - 1
	for chunk in chunks:
		if chunk.index < base_index:
			var cycles := ceili(float(base_index - chunk.index) / chunks.size())
			_fill_chunk(chunk, chunk.index + cycles * chunks.size())
			total_reuses += cycles
		chunk.visual.position.z = distance - chunk.index * Tuning.CHUNK_LENGTH
		if chunk.visual.position.z < -90.0:
			continue
		for coin in chunk.coins:
			if not coin.collected:
				var spin := fposmod(elapsed * 3.5 + coin.meter * 0.15, TAU)
				coin.visual.rotation.y = spin
				coin.visual.position.y = coin.base_y + sin(spin) * 0.055


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
