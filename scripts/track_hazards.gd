class_name TrackHazards
extends RefCounted

const AMBER := Color("#ffd28a")
const CORAL := Color("#ffaf86")
const MARK := preload("res://scripts/hazard_mark.gdshader")

var surface: CoastScenery
var decal := ShaderMaterial.new()


func _init(surfaces: CoastScenery) -> void:
	surface = surfaces
	decal.shader = MARK


func style(pivot: Node3D, half_width: float, depth: float, bottom: float, top: float,
		contrast: bool) -> void:
	var action := 1 if bottom > 0.0 else (2 if top > 1.5 else 0)
	var tones := [Color("#d27035"), Color("#be573e"), Color("#a85d3b")]
	var trim := [AMBER, CORAL, AMBER][action] as Color
	if contrast:
		for child in pivot.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			for i in mesh.mesh.get_surface_count():
				var base := mesh.get_active_material(i) as StandardMaterial3D
				if not base:
					continue
				var coating := base.duplicate() as StandardMaterial3D
				var ink := tones[action] as Color
				if not coating.albedo_texture:
					var value := clampf(base.albedo_color.get_luminance(), 0.12, 1.0)
					coating.albedo_color = ink.lerp(trim, value * 0.49)
				else:
					coating.albedo_color = Color("#ffcf8a")
				coating.emission_enabled = true
				coating.emission = ink
				coating.emission_energy_multiplier = 0.30
				coating.roughness = 0.77
				mesh.set_surface_override_material(i, coating)

	# One sign language across districts. Only collidable pieces get amber pavement marks.
	for child in pivot.find_children("*", "Label3D", true, false):
		child.hide()
	var sign_height := (top + 0.13) if action == 0 else (bottom + 0.42 if action == 1 else 1.44)
	surface.surface(pivot, "Hazard marking", Vector3(0, 0.022, depth + 0.29),
		Vector2(half_width * 2.0 + 0.15, 0.36), decal)
	surface.label(pivot, ["▲", "▼", "‹  ›"][action], Vector3(0, sign_height, depth + 0.09),
		0.0065 if contrast else 0.0055, trim, CoastScenery.KOREAN)
