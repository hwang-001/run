class_name MurangPlayer
extends Node3D

signal jumped
signal landed

const CHARACTER := preload("res://assets/character/murang.glb")
const STAND_HEIGHT := 1.98
const CROUCH_HEIGHT := 0.77

var lane := 0
var elevation := 0.0
var vertical_speed := 0.0
var slide := 0.0
var immunity := 0.0
var impact := 0.0
var visual_time := 0.0
var gait := 0.0
var stance := 0.0
var landing := 0.0
var lean := 0.0
var collapse := 0.0
var enter_x := 0.0
var body: Node3D
var head: Node3D
var arms: Array[Node3D] = []
var legs: Array[Node3D] = []
var tail: Node3D
var heart: Node3D
var model: Node3D
var shadow: MeshInstance3D


func _ready() -> void:
	model = CHARACTER.instantiate()
	add_child(model)
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if part.mesh and part.mesh.get_surface_count() > 0 and part.mesh.surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR:
			var material := part.get_active_material(0) as StandardMaterial3D
			if material:
				material.vertex_color_use_as_albedo = true
	body = model.find_child("Body", true, false) as Node3D
	head = body.find_child("Head", true, false) as Node3D
	tail = body.find_child("Tail", true, false) as Node3D
	heart = head.find_child("Heart", true, false) as Node3D
	for side in ["L", "R"]:
		arms.append(body.find_child("Arm" + side, true, false) as Node3D)
		legs.append(body.find_child("Leg" + side, true, false) as Node3D)

	# Smooth contact shadow also anchors the runner on low-end WebGL devices.
	shadow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.65, 1.8)
	shadow.mesh = quad
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/contact_shadow.gdshader")
	shadow.material_override = material
	shadow.rotation.x = -PI / 2.0
	shadow.position.y = 0.012
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(shadow)


func reset() -> void:
	lane = 0
	position.x = 0.0
	elevation = 0.0
	vertical_speed = 0.0
	slide = 0.0
	immunity = 0.0
	impact = 0.0
	collapse = 0.0
	stance = 0.0
	landing = 0.0
	lean = 0.0
	gait = 0.0
	model.visible = true


func steer(amount: int) -> void:
	lane = clampi(lane + amount, -1, 1)


func jump() -> void:
	if elevation > 0.0:
		return
	slide = 0.0
	vertical_speed = Tuning.JUMP_VELOCITY
	jumped.emit()


func crouch() -> void:
	if elevation > 0.0:
		vertical_speed = minf(vertical_speed, -11.0)
	slide = Tuning.SLIDE_TIME


func hit() -> void:
	immunity = Tuning.HIT_GRACE
	impact = 0.38


func height() -> float:
	return CROUCH_HEIGHT if slide > 0.0 and elevation < 0.1 else STAND_HEIGHT


func step(dt: float, speed: float, active: bool, defeated: bool) -> void:
	visual_time += dt
	if active:
		var goal := lane * Tuning.LANE
		var old_x := position.x
		position.x = move_toward(position.x, goal, Tuning.LANE_SPEED * dt)
		enter_x = clampf((position.x - old_x) / (Tuning.LANE_SPEED * dt), -1.0, 1.0)
		if elevation > 0.0 or vertical_speed > 0.0:
			elevation += vertical_speed * dt
			vertical_speed -= Tuning.GRAVITY * dt
			if elevation <= 0.0:
				elevation = 0.0
				vertical_speed = 0.0
				landing = 1.0
				landed.emit()
		slide = maxf(0.0, slide - dt)
		immunity = maxf(0.0, immunity - dt)
		impact = maxf(0.0, impact - dt)
	else:
		enter_x = 0.0
		if defeated:
			collapse = move_toward(collapse, 1.0, dt * 2.4)
			elevation = move_toward(elevation, 0.0, dt * 5.0)

	landing = move_toward(landing, 0.0, dt * 6.8)
	var running := active and elevation <= 0.0 and slide <= 0.0
	gait = fposmod(gait + dt * TAU * (2.15 + speed * 0.103), TAU)
	lean = lerpf(lean, -enter_x * 0.22, 1.0 - exp(-dt * 15.0))
	stance = move_toward(stance, float(slide > 0.0 and active), dt * 12.0)
	var pose := 1.0 - exp(-dt * 21.0)
	var stride := sin(gait) * lerpf(0.86, 1.15, clampf(speed / Tuning.MAX_SPEED, 0.0, 1.0)) if running else 0.0
	var bob := absf(cos(gait)) * 0.071 if running else sin(visual_time * 3.2) * 0.027
	var recoil := impact / 0.38 if active else 0.0
	model.position.y = elevation
	var stretch := clampf(vertical_speed * 0.010, -0.045, 0.070)
	model.scale = Vector3(1.0 + landing * 0.055, lerpf(1.0 - landing * 0.11 + stretch, 0.43, stance), 1.0 + stance * 0.18)
	body.position.y = 0.70 + bob - stance * 0.13 - collapse * 0.29 - landing * 0.035
	body.rotation.x = lerpf(-0.08 - speed * 0.003 if running else 0.0, -0.67, stance) + recoil * 0.47 + collapse * 0.89
	body.rotation.z = lean + recoil * sin(impact * 31.0) * 0.21 - collapse * 0.28
	head.rotation.x = -body.rotation.x * 0.40 + sin(gait * 2.0) * 0.028 * float(running)
	head.rotation.z = -lean * 0.30
	tail.rotation.y = sin(visual_time * 8.1) * 0.14
	var charm_height := sin(visual_time * 6.0) * 0.048
	heart.position.y = 0.828 + charm_height
	heart.rotation.y = sin(visual_time * 2.0) * 0.28
	for i in range(2):
		var step_sign := 1.0 if i == 0 else -1.0
		var leg_target := stride * step_sign
		var arm_target := -stride * step_sign * 0.78
		if elevation > 0.0:
			leg_target = -0.42 + step_sign * 0.22
			arm_target = -0.94 + step_sign * 0.14
		legs[i].rotation.x = lerpf(legs[i].rotation.x, lerpf(leg_target, 1.12, stance) + collapse * 0.29, pose)
		arms[i].rotation.x = lerpf(arms[i].rotation.x, lerpf(arm_target, -0.98, stance) + recoil * 0.65, pose)

	model.visible = not active or immunity <= 0.0 or int(immunity * 15.0) % 2 == 0
	shadow.scale = Vector3(1.0 + elevation * 0.27, 1.0 + elevation * 0.26 + stance * 0.17, 1.0)
	(shadow.material_override as ShaderMaterial).set_shader_parameter("strength", 0.40 / (1.0 + elevation * 1.07))
