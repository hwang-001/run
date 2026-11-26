class_name ForestScenery
extends RefCounted

const NATURE := "res://assets/forest/nature-kit/"
const CASTLE := "res://assets/forest/castle-kit/"
const CRATE_KIT := "res://assets/forest/pirate-kit/"
const TRAIL := preload("res://assets/forest/forest-trail.webp")
const WATER := preload("res://scripts/forest_water.gdshader")
const TREES := ["tree-pinetalla-detailed", "tree-pinetallc", "tree-pineroundd", "tree-oak"]

var source: CoastScenery
var model: Callable
var dirt := StandardMaterial3D.new()
var creek := ShaderMaterial.new()
var falls := ShaderMaterial.new()
var sunlight := ShaderMaterial.new()


func _init(surfaces: CoastScenery, instancer: Callable) -> void:
	source = surfaces
	model = instancer
	source._pave(dirt, TRAIL, Color("#c1b49e"), Vector2(2.1, 3.0))
	creek.shader = WATER
	falls.shader = WATER
	falls.set_shader_parameter("waterfall", true)
	sunlight.shader = preload("res://scripts/valley_light.gdshader")


func floor_tile(parent: Node3D, z: float, bridge: bool) -> void:
	source.surface(parent, "Valley bridge deck" if bridge else "Forest trail",
		Vector3(0, 0, z), Vector2(9.5, Tuning.ROW_STEP), source.deck if bridge else dirt)
	for side in [-1, 1]:
		if bridge:
			# The imported bridge models support the full-width playable deck at each edge.
			model.call(parent, NATURE + "bridge-wood", Vector3(side * 5.0, -0.53, z),
				Vector3(1.45, 2.24, 11.53), 0.0, true)
		else:
			model.call(parent, NATURE + "grass-leafslarge", Vector3(side * 5.02, -0.05, z + side * 2.8),
				Vector3(2.60, 1.62, 4.0), side * 0.65, false)


func build_banks(parent: Node3D, theme: int, tile: int, z: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = theme * 871 + tile + 1742
	var gorge := tile == 1
	source.surface(parent, "Valley stream", Vector3(0, -2.1, z), Vector2(125.0, Tuning.ROW_STEP), creek)
	for side in [-1, 1]:
		var sign_x := float(side)
		var near_bank := -0.97 if side < 0 else -1.47
		if not gorge:
			model.call(parent, CASTLE + "ground-hills", Vector3(sign_x * 7.6, near_bank, z),
				Vector3(6.0, 3.3, 12.0), side * PI, false)
		model.call(parent, CASTLE + "ground-hills", Vector3(sign_x * 18.7, -3.25, z),
			Vector3(21.8, 12.6, 12.0), side * PI, false)
		var cliff := "rock-tallg" if (tile + theme + side) % 2 == 0 else "rock-tallc"
		model.call(parent, NATURE + cliff, Vector3(sign_x * (19.8 + tile * 3.2 + (4.0 if side > 0 else 0.0)), -2.4, z - 3.1),
			Vector3(rng.randf_range(24, 31), rng.randf_range(8.6, 15.5), rng.randf_range(20, 28)),
			rng.randf_range(-0.9, 0.9), false)
		if tile != 2:
			model.call(parent, NATURE + "rock-largeb", Vector3(sign_x * (33 + 4 * tile + theme), -3.1, z - 3.5),
				Vector3(33, rng.randf_range(25, 52), 24), side * 0.68, false)
		for row in range(3):
			if gorge and side > 0 and row == 0:
				continue
			var tree: String = TREES[posmod(theme + row + tile + side, TREES.size())]
			var x := sign_x * (6.4 + row * 2.6 + rng.randf_range(0.0, 1.5))
			var tree_z := z + 3.2 - row * 3.58 + rng.randf_range(-0.8, 0.8)
			var bank_y := near_bank + (0.18 if gorge and row == 0 else 0.53)
			model.call(parent, NATURE + "rock-largeb", Vector3(x, bank_y - 0.53, tree_z),
				Vector3(6.1, 2.2, 4.4), rng.randf_range(0, TAU), false)
			model.call(parent, NATURE + tree, Vector3(x, bank_y + 0.22, tree_z),
				Vector3.ONE * rng.randf_range(4.6, 8.0), rng.randf_range(-PI, PI), row < 2)
		if not gorge:
			for patch in range(2):
				var edge_x := sign_x * (5.45 + patch * 0.96)
				model.call(parent, NATURE + "mushroom-redgroup", Vector3(edge_x, -0.19, z - 2.75 + patch * 4.8),
					Vector3.ONE * rng.randf_range(1.05, 2.2), rng.randf_range(-PI, PI), false)
			model.call(parent, NATURE + "plant-bushlarge", Vector3(sign_x * 6.7, -0.15, z + 2.8),
				Vector3.ONE * 3.2, rng.randf_range(-PI, PI), false)
			model.call(parent, "res://assets/props/nature-kit/flower-purpleb", Vector3(sign_x * 5.62, -0.09, z - 1.0),
				Vector3.ONE * 2.2, 0.6 * side, false)

	if gorge:
		model.call(parent, NATURE + "rock-tallg", Vector3(9.2, -1.85, z - 3.5), Vector3(7.8, 7.6, 6.5), 0.20, false)
		var curtain := source.surface(parent, "Waterfall", Vector3(8.15, 0.97, z - 1.82), Vector2(2.19, 5.85), falls)
		curtain.rotation = Vector3(0, -0.56, -0.045)
		if theme % 2 == 0:
			var shaft := source.surface(parent, "Canopy sunlight", Vector3(-6.5, 3.6, z - 2.9), Vector2(2.3, 7.2), sunlight)
			shaft.rotation = Vector3(0, -0.15, -0.46)
		model.call(parent, NATURE + "stone-largee", Vector3(7.18, -1.84, z - 0.7),
			Vector3(2.98, 1.1, 1.7), 0.56, false)
		model.call(parent, NATURE + "stone-largee", Vector3(10.5, -1.83, z + 1.5),
			Vector3(2.2, 1.9, 1.5), -0.54, false)
		model.call(parent, NATURE + "rock-largeb", Vector3(9.15, 3.62, z - 3.2), Vector3(4.5, 2.0, 3.4), 0.12, false)
	if tile == 0:
		model.call(parent, CoastScenery.PLANTS + "sign", Vector3(-5.65, -0.09, z + 1.2), Vector3.ONE * 4.4, 0.25, false)


func build_verge(parent: Node3D, tile: int, z: float) -> void:
	model.call(parent, NATURE + "plant-bushlarge", Vector3(-6.65, -0.59, z - 1.1),
		Vector3.ONE * 3.8, 0.58, false)
	model.call(parent, NATURE + "tree-pineroundd", Vector3(-10.10, -0.85, z + 3.4),
		Vector3.ONE * 3.9, 0.29, true)
	if tile == 0:
		model.call(parent, NATURE + "tree-pinetalla-detailed", Vector3(-13.3, -0.79, z - 2.5),
			Vector3.ONE * 4.9, 1.28, true)


func finish_model(root: Node3D, asset_path: String) -> void:
	# Imported meshes keep their geometry and palette structure. The valley uses
	# evergreen tones, muted slate and warm bark across the different asset kits.
	var surfaces := {
		"grass": Color("#537453"),
		"leafsGreen": Color("#55714f"),
		"leafsDark": Color("#344f42"),
		"woodBarkDark": Color("#835944"),
		"woodBark": Color("#967050"),
		"woodInner": Color("#e6bd86"),
		"wood": Color("#a57752"),
		"dirt": Color("#71776a"),
		"stone": Color("#778d86"),
	}
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for index in mesh.mesh.get_surface_count():
			var material := mesh.mesh.surface_get_material(index) as StandardMaterial3D
			if not material:
				continue
			var key := material.resource_name
			if key.begins_with("leafs"):
				var canopy := ShaderMaterial.new()
				canopy.shader = preload("res://scripts/forest_foliage.gdshader")
				canopy.set_shader_parameter("fir", surfaces.get(key, Color("#3b5c49")))
				mesh.mesh.surface_set_material(index, canopy)
			elif surfaces.has(key):
				material.albedo_color = surfaces[key]
			elif asset_path.contains("ground-hills"):
				material.albedo_color = Color("#84957d")
			elif key == "_defaultMat" and (asset_path.contains("rock-") or asset_path.contains("stone-")):
				material.albedo_color = Color("#919d96")
