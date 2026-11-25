class_name CoastScenery
extends RefCounted

const PIRATE := "res://assets/coast/kenney/pirate-kit/"
const PLANTS := "res://assets/coast/kenney/nature-kit/"
const ARCADE := "res://assets/coast/kenney/platformer-kit/"
const SAND := preload("res://assets/surfaces/sand.webp")
const WOOD := preload("res://assets/surfaces/wood.webp")
const ASPHALT := preload("res://assets/surfaces/asphalt.webp")
const WATER := preload("res://scripts/water.gdshader")
const FONT := preload("res://assets/ui/Outfit-Bold.ttf")
const KOREAN := preload("res://assets/ui/GowunDodum.ttf")

var asphalt := StandardMaterial3D.new()
var deck := StandardMaterial3D.new()
var sand := StandardMaterial3D.new()
var water := ShaderMaterial.new()
var make_model: Callable


func _init(instancer: Callable) -> void:
	make_model = instancer
	_pave(asphalt, ASPHALT, Color("#646f83"), Vector2(4.0, 7.8))
	_pave(deck, WOOD, Color("#dec8a7"), Vector2(2.4, 3.0))
	_pave(sand, SAND, Color("#efd4a3"), Vector2(5.0, 4.0))
	water.shader = WATER


func _pave(material: StandardMaterial3D, texture: Texture2D, tint: Color, tiles: Vector2) -> void:
	material.albedo_texture = texture
	material.albedo_color = tint
	material.roughness = 0.86
	material.uv1_scale = Vector3(tiles.x, tiles.y, 1.0)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


func surface(parent: Node3D, name: String, at: Vector3, size: Vector2, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = name
	var quad := QuadMesh.new()
	quad.size = size
	instance.rotation.x = -PI / 2
	instance.position = at
	instance.mesh = quad
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance


func asphalt_strip(parent: Node3D, z: float) -> void:
	surface(parent, "AsphaltTexture", Vector3(0, 0.005, z), Vector2(6.214, Tuning.ROW_STEP), asphalt)


func boardwalk(parent: Node3D, z: float) -> void:
	surface(parent, "Boardwalk", Vector3(0, 0, z), Vector2(9.5, Tuning.ROW_STEP), deck)
	# The continuous deck sits over modular posts with textured planks along each edge.
	for side in [-1, 1]:
		make_model.call(parent, PIRATE + "structure-platform-dock-small",
			Vector3(side * 5.27, -1.46, z), Vector3(1.02, 0.92, 4.70), 0.0, false)
		for offset in [-4.0, 0.0, 4.0]:
			make_model.call(parent, ARCADE + "fence-rope", Vector3(side * 4.66, 0.015, z + offset),
				Vector3(4.22, 3.6, 2.5), PI/2.0, true)


func build_shore(parent: Node3D, seed_id: int, tile: int, z: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_id * 127 + 911 + tile
	surface(parent, "Surf", Vector3(0, -1.14, z), Vector2(180, Tuning.ROW_STEP), water)
	surface(parent, "Sand", Vector3(-15.0, -0.92, z), Vector2(19, Tuning.ROW_STEP), sand)
	for i in range(3):
		var left: float = -8.0 - i * 3.7 + rng.randf_range(-0.5, 0.6)
		make_model.call(parent, PIRATE + ("patch-sand-foliage" if i == 0 else "patch-sand"),
			Vector3(left, -1.06, z + rng.randf_range(-2.0, 2.0)), Vector3(0.65, 1.2, 1.04),
			0.0, false)
		var tree := "tree-palmdetailedtall" if i != 1 else "tree-palmbend"
		make_model.call(parent, PLANTS + tree,
			Vector3(left, -0.88, z + i * 2.15 - 3.8), Vector3.ONE * rng.randf_range(3.3, 4.9),
			rng.randf_range(-PI, PI), i < 2)
		make_model.call(parent, PLANTS + "plant-flattall",
			Vector3(left + 1.1, -0.63, z + i * 2.9 - 2.2), Vector3.ONE * 2.7,
			rng.randf_range(-PI, PI), false)
	var rock := "rocks-sand-a" if (tile + seed_id) % 2 == 0 else "rocks-sand-c"
	make_model.call(parent, PIRATE + rock, Vector3(-22 - rng.randf_range(0.0, 3.0), -1.24, z),
		Vector3.ONE * rng.randf_range(2.3, 3.7), rng.randf_range(-PI, PI), false)
	if tile != 1:
		make_model.call(parent, PIRATE + ("structure-fence" if seed_id % 3 == 1 else "structure"), Vector3(-9.0 - tile, -0.75, z + 1.5),
			Vector3.ONE * 1.55, -PI / 2, true)
		make_model.call(parent, PIRATE + "flag-high-pennant", Vector3(-6.2, -0.78, z - 3.3),
			Vector3.ONE * 1.20, -0.24, false)
	if tile == 1:
		var tower := "tower-complete-small" if seed_id % 3 else "tower-watch"
		make_model.call(parent, PIRATE + tower, Vector3(-15, -0.82, z - 1), Vector3.ONE * 1.75,
			PI / 2, true)
		if seed_id % 3 != 0:
			var ship := "ship-medium" if seed_id % 2 else "ship-small"
			make_model.call(parent, PIRATE + ship,
				Vector3(rng.randf_range(14.5, 22.0), -1.56, z - 2.0), Vector3.ONE * rng.randf_range(0.94, 1.27),
				rng.randf_range(-1.0, 0.45), false)
	if tile == 2:
		make_model.call(parent, PIRATE + "boat-row-large", Vector3(8.6, -1.24, z - 1.8),
			Vector3.ONE * 0.92, -0.48, false)
	if tile == 0 and seed_id % 2 == 0:
		make_model.call(parent, PIRATE + rock, Vector3(34.0, -1.22, z - 2.0), Vector3(4.9, 2.1, 3.0),
			-0.33, false)
		make_model.call(parent, PLANTS + "tree-palmdetailedtall", Vector3(35.8, 1.91, z - 1.0),
			Vector3.ONE * 4.1, 0.92, false)


func label(parent: Node3D, value: String, at: Vector3, pixel: float, color: Color, font: Font) -> void:
	var text := Label3D.new()
	text.text = value
	text.font = font
	text.font_size = 64
	text.pixel_size = pixel
	text.outline_size = 14
	text.modulate = color
	text.outline_modulate = Color("#142f42")
	text.position = at
	text.shaded = false
	parent.add_child(text)
