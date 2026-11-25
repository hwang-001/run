extends Node3D

enum State { MENU, RUNNING, PAUSED, FINISHED }

const SKY := preload("res://assets/park/kloofendal-sky.webp")
const HARBOR_SKY := preload("res://assets/coast/qwantani-sky.webp")
const SKY_SHADER := preload("res://scripts/route_sky.gdshader")
const MENU_MILE := Tuning.HARBOR_START + 4.0
const REWARD_COLOR := Color("#ffe27a")
const HIT_COLOR := Color("#ff667b")
const DUST_COLOR := Color("#fff1d5")
const SAVE_INTERVAL := 2.0

var state := State.MENU
var player: MurangPlayer
var track: RunnerTrack
var camera: Camera3D
var ui: RunnerUI
var audio: RunnerAudio
var records := RunnerSave.new()
var bursts: Array[CPUParticles3D] = []
var spark_mesh: SphereMesh
var dust_mesh: SphereMesh
var surf_particles: CPUParticles3D
var environment: Environment
var sunlight: DirectionalLight3D
var sky_mix: ShaderMaterial
var scene_mix := -1.0
var district := 0
var start_district := 0
var start_meter := 0.0
var test_run := false
var preview_meter := MENU_MILE
var burst_index := 0
var distance := 0.0
var speed := Tuning.START_SPEED
var coins := 0
var banked := 0
var health := 3
var start_best := 0
var shake := 0.0
var clock := 0.0
var steps_in := 0.0
var save_in := 0.0
var finish_timer := 0.0
var ready_remaining := 0.0
var swipe_id := -1
var swipe_origin := Vector2.ZERO
var last_ui_score := -1
var portrait_view := false


func _ready() -> void:
	_make_lighting()
	track = RunnerTrack.new()
	add_child(track)
	track.reset(2, MENU_MILE, true)
	track.coin_taken.connect(_on_coin)
	track.obstacle_hit.connect(_on_hit)
	player = MurangPlayer.new()
	add_child(player)
	player.hide()
	player.jumped.connect(_on_jump)
	player.landed.connect(_on_land)
	camera = Camera3D.new()
	camera.current = true
	camera.near = 0.14
	camera.far = 155.0
	add_child(camera)
	_make_particles()

	audio = RunnerAudio.new()
	add_child(audio)
	records.read_records()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = RunnerUI.new()
	ui.best = records.best
	ui.bank = records.bank
	canvas.add_child(ui)
	ui.start_requested.connect(_start)
	ui.test_requested.connect(func(): _start(Tuning.TEST_DISTRICT))
	ui.replay_requested.connect(_restart)
	ui.pause_requested.connect(_pause)
	ui.resume_requested.connect(_resume)
	ui.home_requested.connect(_show_home)
	ui.mute_requested.connect(_toggle_audio)
	get_viewport().size_changed.connect(_check_viewport)
	_check_viewport()
	_update_atmosphere(1.0)
	_camera_step(1.0)


func _make_lighting() -> void:
	var world := WorldEnvironment.new()
	var atmosphere := Environment.new()
	environment = atmosphere
	atmosphere.background_mode = Environment.BG_SKY
	var daylight := Sky.new()
	daylight.radiance_size = Sky.RADIANCE_SIZE_32
	daylight.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	sky_mix = ShaderMaterial.new()
	sky_mix.shader = SKY_SHADER
	sky_mix.set_shader_parameter("park_panorama", SKY)
	sky_mix.set_shader_parameter("harbor_panorama", HARBOR_SKY)
	daylight.sky_material = sky_mix
	atmosphere.sky = daylight
	atmosphere.sky_rotation.y = 0.8
	atmosphere.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.ambient_light_color = Color("#e3ecef")
	atmosphere.ambient_light_energy = 0.45
	atmosphere.fog_enabled = true
	atmosphere.fog_light_color = Color("#b7e3f2")
	atmosphere.fog_light_energy = 1.0
	atmosphere.fog_sky_affect = 0.04
	atmosphere.fog_density = 0.0105
	world.environment = atmosphere
	add_child(world)
	var sun := DirectionalLight3D.new()
	sunlight = sun
	sun.light_color = Color("#fff2d4")
	sun.light_energy = 0.65
	sun.rotation_degrees = Vector3(-56, -36, 0)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.8
	sun.directional_shadow_max_distance = 48.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)


func _make_particles() -> void:
	spark_mesh = SphereMesh.new()
	spark_mesh.radial_segments = 4
	spark_mesh.rings = 1
	spark_mesh.radius = 0.071
	spark_mesh.height = 0.25
	dust_mesh = SphereMesh.new()
	dust_mesh.radial_segments = 6
	dust_mesh.rings = 3
	dust_mesh.radius = 0.11
	dust_mesh.height = 0.16
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.43, 1.0])
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.82), Color(1, 1, 1, 0)])
	for i in range(8):
		var puffs := CPUParticles3D.new()
		puffs.mesh = spark_mesh
		puffs.color_ramp = fade
		puffs.amount = 11
		puffs.one_shot = true
		puffs.emitting = false
		puffs.lifetime = 0.49
		puffs.explosiveness = 0.93
		puffs.direction = Vector3.UP
		puffs.spread = 67.0
		puffs.initial_velocity_min = 1.0
		puffs.initial_velocity_max = 4.0
		puffs.gravity = Vector3(0, -7.0, 4.0)
		puffs.scale_amount_min = 0.34
		puffs.scale_amount_max = 1.24
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.vertex_color_use_as_albedo = true
		puffs.material_override = material
		puffs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bursts.append(puffs)
		add_child(puffs)

	surf_particles = CPUParticles3D.new()
	surf_particles.mesh = spark_mesh
	surf_particles.amount = 22
	surf_particles.lifetime = 2.65
	surf_particles.emitting = false
	surf_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	surf_particles.emission_box_extents = Vector3(4.4, 0.22, 26.0)
	surf_particles.position = Vector3(9.2, -0.98, -24.0)
	surf_particles.direction = Vector3(0.36, 0.62, 0.58)
	surf_particles.spread = 27.0
	surf_particles.initial_velocity_min = 0.45
	surf_particles.initial_velocity_max = 1.22
	surf_particles.gravity = Vector3(0.0, -0.27, 0.0)
	surf_particles.scale_amount_min = 0.10
	surf_particles.scale_amount_max = 0.39
	surf_particles.color_ramp = fade
	surf_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var foam := StandardMaterial3D.new()
	foam.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	foam.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	foam.vertex_color_use_as_albedo = true
	foam.albedo_color = Color("#ffedc7")
	surf_particles.material_override = foam
	add_child(surf_particles)


func _emit_burst(at: Vector3, tint: Color, dust := false) -> void:
	var puffs := bursts[burst_index]
	burst_index = (burst_index + 1) % bursts.size()
	puffs.position = at
	puffs.mesh = dust_mesh if dust else spark_mesh
	puffs.spread = 85.0 if dust else 48.0
	(puffs.material_override as StandardMaterial3D).albedo_color = tint
	puffs.restart()


func _check_viewport() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	portrait_view = viewport_size.x < viewport_size.y * 0.98
	if OS.has_feature("web"):
		get_viewport().scaling_3d_scale = 0.83 if portrait_view else 1.0
	sunlight.directional_shadow_max_distance = 32.0 if portrait_view else 48.0


func _start(requested_district := 0) -> void:
	audio.play_sound(&"click")
	audio.start_music()
	start_district = clampi(requested_district, 0, Tuning.DISTRICTS.size() - 1) if Tuning.ENABLE_DISTRICT_TEST else 0
	test_run = start_district > 0
	start_meter = float(Tuning.DISTRICTS[start_district].start)
	distance = start_meter
	speed = Tuning.speed_at(distance)
	district = Tuning.district_at(distance)
	coins = 0
	banked = 0
	health = 3
	start_best = records.best
	shake = 0.0
	finish_timer = 0.0
	ready_remaining = 0.23
	save_in = SAVE_INTERVAL
	last_ui_score = -1
	steps_in = 0.0
	ui.pace = 0.0
	ui.pulse = 0.0
	swipe_id = -1
	player.reset()
	player.show()
	track.reset(randi() & 0x7ffffff, distance)
	if test_run:
		player.lane = track.spawn_lane_at(distance)
		player.position.x = player.lane * Tuning.LANE
	_update_atmosphere(Tuning.coast_mix_at(distance))
	state = State.RUNNING
	ui.test_run = test_run
	ui.set_district(district, test_run)
	ui.update_values(0, int(distance), 0, 3)
	ui.show_screen(RunnerUI.Screen.HUD)


func _restart() -> void:
	_start(start_district)


func _session_score() -> int:
	return Tuning.points(distance - start_meter, coins)


func _update_atmosphere(blend: float) -> void:
	# Quantization bounds skymap refreshes while the coast lighting changes.
	blend = snappedf(blend, 1.0 / 48.0)
	if is_equal_approx(scene_mix, blend):
		return
	scene_mix = blend
	sky_mix.set_shader_parameter("harbor", blend)
	environment.ambient_light_color = Color("#d9eaf5").lerp(Color("#f1d7c5"), blend)
	environment.ambient_light_energy = lerpf(0.41, 0.40, blend)
	environment.fog_light_color = Color("#c5e5f0").lerp(Color("#edc6a6"), blend)
	environment.fog_density = lerpf(0.0086, 0.0067, blend)
	sunlight.light_color = Color("#fff0d8").lerp(Color("#ffd0a3"), blend)
	sunlight.light_energy = lerpf(0.58, 0.65, blend)
	sunlight.rotation_degrees = Vector3(-56, -36, 0).lerp(Vector3(-31, -55, 0), blend)
	audio.set_coast(blend)
	surf_particles.emitting = blend > 0.39


func _show_home() -> void:
	if state != State.MENU:
		_save_progress()
	audio.play_sound(&"click")
	player.reset()
	player.hide()
	track.reset(2, MENU_MILE, true)
	preview_meter = MENU_MILE
	_update_atmosphere(1.0)
	distance = 0.0
	state = State.MENU
	swipe_id = -1
	ui.show_screen(RunnerUI.Screen.TITLE)


func _pause() -> void:
	if state != State.RUNNING:
		return
	state = State.PAUSED
	swipe_id = -1
	_save_progress()
	audio.play_sound(&"click")
	ui.show_screen(RunnerUI.Screen.PAUSED)


func _resume() -> void:
	if state != State.PAUSED:
		return
	state = State.RUNNING
	audio.play_sound(&"click")
	ui.show_screen(RunnerUI.Screen.HUD)


func _toggle_audio() -> void:
	audio.set_muted(not audio.muted)
	ui.muted = audio.muted
	if not audio.muted:
		audio.play_sound(&"click")
	ui.show_screen(ui.screen)


func _finish() -> void:
	state = State.FINISHED
	finish_timer = 0.46
	swipe_id = -1
	ui.new_best = not test_run and _session_score() > start_best
	_save_progress()
	audio.play_sound(&"over", -10.0)


func _save_progress() -> void:
	if test_run:
		return
	records.record(distance, _session_score(), coins - banked)
	banked = coins
	ui.best = records.best
	ui.bank = records.bank


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.RUNNING:
		_pause()
	if what == NOTIFICATION_WM_CLOSE_REQUEST and state == State.RUNNING:
		_save_progress()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if not event.pressed or event.echo:
			return
		var key := event.physical_keycode as Key
		if key == KEY_NONE:
			key = event.keycode
		if key == KEY_ESCAPE:
			if state == State.RUNNING:
				_pause()
			elif state == State.PAUSED:
				_resume()
			elif state == State.MENU and ui.screen == RunnerUI.Screen.HELP:
				ui.show_screen(RunnerUI.Screen.TITLE)
			else:
				return
		elif state == State.RUNNING:
			match key:
				KEY_A, KEY_LEFT: player.steer(-1)
				KEY_D, KEY_RIGHT: player.steer(1)
				KEY_SPACE, KEY_W, KEY_UP:
					ready_remaining = 0.0
					player.jump()
				KEY_S, KEY_DOWN:
					ready_remaining = 0.0
					player.crouch()
				_: return
		elif key == KEY_ENTER and ui.screen == RunnerUI.Screen.TITLE:
			_start()
		elif key == KEY_ENTER and ui.screen == RunnerUI.Screen.OVER:
			_restart()
		else:
			return
		get_viewport().set_input_as_handled()
	elif state == State.RUNNING:
		if event is InputEventScreenTouch:
			if event.pressed and swipe_id < 0 and event.position.y > get_viewport().get_visible_rect().size.y * 0.13:
				swipe_id = event.index
				swipe_origin = event.position
			elif not event.pressed and event.index == swipe_id:
				_apply_swipe(event.position)
				swipe_id = -1
		elif event is InputEventScreenDrag and event.index == swipe_id:
			if _apply_swipe(event.position):
				swipe_id = -1


func _apply_swipe(at: Vector2) -> bool:
	var movement := at - swipe_origin
	var threshold := clampf(get_viewport().get_visible_rect().size.x * 0.047, 24.0, 50.0)
	if movement.length_squared() < threshold * threshold:
		return false
	ready_remaining = 0.0
	if absf(movement.x) > absf(movement.y):
		player.steer(1 if movement.x > 0 else -1)
	elif movement.y < 0:
		player.jump()
	else:
		player.crouch()
	return true


func _on_jump() -> void:
	audio.play_sound(&"jump", -12.0)


func _on_land() -> void:
	_emit_burst(player.position + Vector3(0, 0.09, 0.24), DUST_COLOR, true)
	audio.play_sound(&"land", -15.0)


func _on_coin(at: Vector3) -> void:
	if state != State.RUNNING:
		return
	coins += 1
	_emit_burst(at, REWARD_COLOR)
	audio.play_sound(&"coin", -12.0, 1.0 + float(coins % 5) * 0.043)
	audio.play_sound(&"coin_accent", -26.0, 1.18)
	_save_progress()


func _on_hit(at: Vector3) -> void:
	if state != State.RUNNING:
		return
	health -= 1
	shake = 0.29
	ui.pulse = 1.0
	_emit_burst(at, HIT_COLOR)
	audio.play_sound(&"hit", -14.0)
	if health <= 0:
		_finish()


func _physics_process(dt: float) -> void:
	clock += dt
	if state == State.RUNNING:
		if ready_remaining > 0.0:
			ready_remaining -= dt
			player.step(dt, 0.0, false, false)
			_camera_step(dt)
			return
		var previous := distance
		speed = Tuning.speed_at(distance)
		distance += dt * speed
		var next := Tuning.district_at(distance)
		if district != next:
			district = next
			ui.set_district(district, true)
		_update_atmosphere(Tuning.coast_mix_at(distance))
		player.step(dt, speed, true, false)
		track.scroll(distance, dt)
		track.check_contacts(previous, distance, player)
		steps_in -= dt
		if steps_in <= 0.0 and player.elevation < 0.025 and player.slide <= 0.0:
			steps_in = 1.0 / (5.4 + speed * 0.15)
			audio.play_sound(&"step", -30.0, 0.93 + 0.07 * sin(clock * 17.0))
		ui.pace = smoothstep(16.0, Tuning.MAX_SPEED, speed)
		save_in -= dt
		if save_in <= 0.0:
			_save_progress()
			save_in = SAVE_INTERVAL
		var point_total := _session_score()
		if point_total != last_ui_score:
			last_ui_score = point_total
			ui.update_values(point_total, int(distance), coins, health)
	elif state == State.MENU:
		player.step(dt, 0.0, false, false)
		preview_meter += dt * 1.2
		track.scroll(preview_meter, dt)
	elif state == State.FINISHED:
		player.step(dt, 0.0, false, true)
		if finish_timer > 0.0:
			finish_timer -= dt
			if finish_timer <= 0.0:
				ui.show_screen(RunnerUI.Screen.OVER)
	_camera_step(dt)


func _camera_step(dt: float) -> void:
	if state == State.PAUSED:
		return
	shake = maxf(0.0, shake - dt)
	var blend := 1.0 - exp(-7.0 * dt)
	var offset := player.position.x * (0.55 if portrait_view else 0.39)
	var rise := minf(0.45, player.elevation * 0.25)
	if state == State.MENU:
		offset += sin(clock * 0.22) * 0.59
	var shake_x := sin(clock * 89.0) * shake * 0.33
	var shake_y := cos(clock * 74.0) * shake * 0.27
	var goal := Vector3(offset + shake_x, 4.54 + rise + shake_y, 6.85 if portrait_view else 6.45)
	camera.position = camera.position.lerp(goal, blend)
	camera.look_at(Vector3(offset * 0.45, 1.14 + rise * 0.40, -9.4), Vector3.UP)
	var base_fov := 78.0 if portrait_view else 59.0
	var wanted := base_fov + ui.pace * 7.0
	camera.fov = lerpf(camera.fov, wanted, blend)
