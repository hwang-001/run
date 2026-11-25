class_name RunnerMotionFX
extends Node3D

const FILM := preload("res://scripts/motion_veil.gdshader")
const WIND_COLOR := Color("#d2f0ff")
const TRAIL_COLOR := Color("#aee0f4")
const SKID_COLOR := Color("#4f3a23")
const MAX_ECHOES := 5
const MAX_SKIDS := 12
const ECHO_LIFE := 0.21
const SKID_LIFE := 0.28


class Echo:
	var root: Node3D
	var parts: Array[MeshInstance3D] = []
	var material: ShaderMaterial
	var life := 0.0


class Skid:
	var model: MeshInstance3D
	var material: ShaderMaterial
	var life := 0.0


var echoes: Array[Echo] = []
var skids: Array[Skid] = []
var wind: Array[MeshInstance3D] = []
var wind_material: ShaderMaterial
var drift: Array[CPUParticles3D] = []
var drift_material: StandardMaterial3D
var echo_cursor := 0
var skid_cursor := 0
var echo_delay := 0.0
var skid_delay := 0.0
var wind_clock := 0.0
var district := -1
var performance_mode := false


func setup(player: MurangPlayer) -> void:
	var plane := QuadMesh.new()
	plane.size = Vector2.ONE
	wind_material = _film(WIND_COLOR, true)
	for index in Tuning.WIND_LIMIT:
		var streak := _quad(self, plane, wind_material)
		streak.hide()
		wind.append(streak)
	for index in MAX_ECHOES:
		var echo := Echo.new()
		echo.root = Node3D.new()
		add_child(echo.root)
		echo.material = _film(TRAIL_COLOR, false)
		for component in [player.head_mesh, player.torso_mesh]:
			var copy := _quad(echo.root, component.mesh, echo.material)
			copy.rotation = Vector3.ZERO
			echo.parts.append(copy)
		echo.root.hide()
		echoes.append(echo)
	for index in MAX_SKIDS:
		var skid := Skid.new()
		skid.material = _film(SKID_COLOR, true)
		skid.model = _quad(self, plane, skid.material)
		skid.model.hide()
		skids.append(skid)
	_make_drifts()


func _film(color: Color, band: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = FILM
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("band", band)
	return material


func _quad(parent: Node3D, mesh: Mesh, material: Material) -> MeshInstance3D:
	var quad := MeshInstance3D.new()
	quad.mesh = mesh
	quad.material_override = material
	quad.rotation.x = -PI / 2
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(quad)
	return quad


func _make_drifts() -> void:
	var petal := PrismMesh.new()
	petal.size = Vector3(0.11, 0.056, 0.016)
	drift_material = StandardMaterial3D.new()
	drift_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drift_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drift_material.vertex_color_use_as_albedo = true
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.31, 0.78, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.66), Color(1, 1, 1, 0.54), Color(1, 1, 1, 0.0)])
	for side in [-1.0, 1.0]:
		var particle := CPUParticles3D.new()
		particle.mesh = petal
		particle.material_override = drift_material
		particle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		particle.emitting = false
		particle.amount = 21
		particle.lifetime = 1.85
		particle.position = Vector3(side * 6.5, 1.82, -17.0)
		particle.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		particle.emission_box_extents = Vector3(1.65, 1.75, 14.0)
		particle.direction = Vector3(side * 0.15, 0.15, 1)
		particle.spread = 13.0
		particle.gravity = Vector3(side * 0.35, -0.80, 0)
		particle.angle_min = -180
		particle.angle_max = 180
		particle.angular_velocity_min = -230
		particle.angular_velocity_max = 230
		particle.color_ramp = gradient
		particle.scale_amount_min = 0.54
		particle.scale_amount_max = 1.3
		add_child(particle)
		drift.append(particle)


func reset() -> void:
	echo_delay = 0.0
	skid_delay = 0.0
	for echo in echoes:
		echo.life = 0.0
		echo.root.hide()
	for skid in skids:
		skid.life = 0.0
		skid.model.hide()
	for streak in wind:
		streak.hide()
	for node in drift:
		node.emitting = false


func step(dt: float, speed: float, power: float, region: int, player: MurangPlayer) -> void:
	_update_wind(dt, power)
	_update_drift(speed, power, region)
	var sliding := player.stance > 0.58 and player.elevation < 0.09
	for echo in echoes:
		if echo.life <= 0.0:
			continue
		echo.life = maxf(0.0, echo.life - dt)
		echo.root.visible = echo.life > 0.0 and not performance_mode
		echo.root.position.z += speed * dt * 0.54
		echo.material.set_shader_parameter("tint", Color(TRAIL_COLOR, pow(echo.life / ECHO_LIFE, 1.7) * lerpf(0.065, 0.20, power)))
	for skid in skids:
		if skid.life <= 0.0:
			continue
		skid.life = maxf(0.0, skid.life - dt)
		skid.model.visible = skid.life > 0.0
		skid.model.position.z += speed * dt
		skid.material.set_shader_parameter("tint", Color(SKID_COLOR, (skid.life / SKID_LIFE) * 0.32))

	echo_delay = maxf(0.0, echo_delay - dt)
	skid_delay = maxf(0.0, skid_delay - dt)
	var turning := absf(player.enter_x) > 0.35 and power > 0.33
	if not performance_mode and echo_delay <= 0.0 and player.model.visible 			and (power > Tuning.TRAIL_THRESHOLD or turning or sliding):
		_capture(player)
		echo_delay = lerpf(0.091, 0.042, power)
	if sliding and skid_delay <= 0.0:
		_mark(player.position.x - 0.17, player.enter_x)
		_mark(player.position.x + 0.18, player.enter_x)
		skid_delay = lerpf(0.074, 0.045, power)


func _capture(player: MurangPlayer) -> void:
	var echo := echoes[echo_cursor]
	echo_cursor = (echo_cursor + 1) % echoes.size()
	echo.root.position = Vector3(0, 0, 0.35)
	echo.parts[0].transform = global_transform.affine_inverse() * player.head_mesh.global_transform
	echo.parts[1].transform = global_transform.affine_inverse() * player.torso_mesh.global_transform
	echo.material.set_shader_parameter("tint", Color(TRAIL_COLOR, 0.0))
	echo.life = ECHO_LIFE
	echo.root.show()


func _mark(x: float, steer: float) -> void:
	var skid := skids[skid_cursor]
	skid_cursor = (skid_cursor + 1) % skids.size()
	skid.model.position = Vector3(x, 0.015, 0.12)
	skid.model.rotation.y = -steer * 0.25
	skid.model.scale = Vector3(0.13, 0.88, 1)
	skid.material.set_shader_parameter("tint", Color(SKID_COLOR, 0.0))
	skid.life = SKID_LIFE
	skid.model.show()


func _update_wind(dt: float, power: float) -> void:
	wind_clock = fposmod(wind_clock + dt * lerpf(0.32, 1.75, power), 1024.0)
	var count := mini(wind.size(), 4 + roundi(20.0 * power))
	if performance_mode:
		count = mini(count, 7)
	wind_material.set_shader_parameter("tint", Color(WIND_COLOR, lerpf(0.12, 0.48, power)))
	for index in wind.size():
		var streak := wind[index]
		streak.visible = index < count
		if not streak.visible:
			continue
		var time := fposmod(wind_clock + index * 0.618, 1.0)
		var side := -1.0 if index % 2 == 0 else 1.0
		var seed := fposmod(index * 0.239, 1.0)
		streak.position = Vector3(side * lerpf(4.76, 10.2, seed), 0.51 + fposmod(index * 0.58, 3.27), lerpf(-38.0, 7.72, time))
		streak.scale = Vector3(lerpf(0.013, 0.047, power), lerpf(0.54, 2.62, power) * (0.55 + seed), 1.0)


func _update_drift(speed: float, power: float, region: int) -> void:
	if district != region:
		district = region
		drift_material.albedo_color = [Color("#f9bbc2"), Color("#d0f2fc"), Color("#d1e785")][region]
	for particle in drift:
		particle.emitting = not performance_mode
		particle.initial_velocity_min = 2.9 + speed * 0.22
		particle.initial_velocity_max = 5.4 + speed * 0.55
		particle.speed_scale = lerpf(0.74, 1.45, power)
