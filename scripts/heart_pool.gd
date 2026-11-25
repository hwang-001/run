class_name RunnerHeartPool
extends Node3D

signal taken(at: Vector3)

const MODEL := preload("res://assets/forest/platformer-kit/heart.glb")
const HEART_COLOR := Color("#ef3456")


class Slot:
	var node: Node3D
	var sparks: CPUParticles3D
	var meter := -1.0
	var lane := 0


var natural: Slot
var debug: Slot
var schedule := RunnerHeartSchedule.new()
var glow := StandardMaterial3D.new()
var elapsed := 0.0
var performance_mode := false


func _ready() -> void:
	glow.albedo_color = HEART_COLOR
	glow.metallic = 0.18
	glow.roughness = 0.25
	glow.emission_enabled = true
	glow.emission = Color("#f72b60")
	glow.emission_energy_multiplier = 0.43
	natural = _build_slot()
	debug = _build_slot()


func _build_slot() -> Slot:
	var slot := Slot.new()
	slot.node = Node3D.new()
	add_child(slot.node)
	var model := MODEL.instantiate() as Node3D
	model.scale = Vector3.ONE * 2.36
	model.position.y = -0.42
	slot.node.add_child(model)
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		mesh.material_override = glow
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shimmer := CPUParticles3D.new()
	shimmer.emitting = false
	shimmer.amount = 9
	shimmer.lifetime = 0.83
	shimmer.local_coords = true
	shimmer.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	shimmer.emission_sphere_radius = 0.47
	shimmer.direction = Vector3.UP
	shimmer.spread = 110.0
	shimmer.gravity = Vector3(0, 0.60, 0)
	shimmer.scale_amount_min = 0.37
	shimmer.scale_amount_max = 1.0
	var star := PrismMesh.new()
	star.size = Vector3(0.053, 0.12, 0.035)
	var tint := StandardMaterial3D.new()
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.albedo_color = Color("#ffd2d2")
	shimmer.mesh = star
	shimmer.material_override = tint
	shimmer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	slot.sparks = shimmer
	slot.node.add_child(shimmer)
	_remove(slot)
	return slot


func _remove(slot: Slot) -> void:
	slot.node.hide()
	slot.sparks.emitting = false
	slot.meter = -1.0


func reset(run_seed: int, start_at: float, preview: bool) -> void:
	_remove(natural)
	_remove(debug)
	elapsed = 0.0
	if not preview:
		schedule.reset(run_seed, start_at - 0.58)


func spawn_debug(meter: float, lane_id: int) -> bool:
	if debug.meter >= 0.0:
		return false
	_place(debug, meter, lane_id)
	return true


func _place(slot: Slot, meter: float, lane_id: int) -> void:
	slot.meter = meter
	slot.lane = lane_id
	slot.node.position = Vector3(lane_id * Tuning.LANE, 1.13, -103.0)
	slot.node.show()


func scroll(distance: float, dt: float, lane_selector: Callable) -> void:
	elapsed += dt
	var candidate := schedule.advance(distance + Tuning.HEART_LOOKAHEAD)
	if candidate >= distance - 0.58:
		_place(natural, candidate, lane_selector.call(float(candidate)))
	for slot in [natural, debug]:
		if slot.meter < 0.0:
			continue
		var remaining: float = slot.meter - distance
		slot.node.position = Vector3(slot.lane * Tuning.LANE, 1.13 + sin(elapsed * 3.7) * 0.13, -remaining)
		slot.node.rotation.y = elapsed * 1.9
		slot.sparks.emitting = not performance_mode and remaining < 36.0 and remaining > -1.0


func check_contacts(previous: float, distance: float, player: MurangPlayer) -> void:
	for slot in [natural, debug]:
		if slot.meter < 0.0:
			continue
		if previous > slot.meter + 0.58:
			_remove(slot)
			continue
		if distance < slot.meter - 0.58:
			continue
		if absf(player.position.x - slot.node.position.x) > 0.69 or player.elevation > 1.57:
			continue
		var at: Vector3 = slot.node.position
		_remove(slot)
		taken.emit(at)
