extends Node3D

enum State { MENU, RUNNING, PAUSED, FINISHED }

const SKY := preload("res://assets/park/kloofendal-sky.webp")
const HARBOR_SKY := preload("res://assets/coast/qwantani-sky.webp")
const FOREST_SKY := preload("res://assets/forest/misty-sky.webp")
const NEON_SKY := preload("res://assets/neon/night-sky.webp")
const SKY_SHADER := preload("res://scripts/route_sky.gdshader")
const MENU_MILE := Tuning.HARBOR_START + 47.0
const SLOW_COLOR := Color("#93ddff")
const DISPLAY_CONFIG := "user://display.cfg"
const HEALTH_COLOR := Color("#ff7f9e")
const GROUND_COLORS := [Color("#dbd5be"), Color("#ffe4bc"), Color("#d9bd8d"), Color("#aea8d9")]
const REWARD_COLOR := Color("#ffe27a")
const HIT_COLOR := Color("#ff667b")
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
var scene_mix := Vector4(-1, -1, -1, -1)
var motion_fx: RunnerMotionFX
var low_graphics := false
var landing_kick := 0.0
var camera_roll := 0.0
var skid_puffs_in := 0.0
var ground_steps := 0
var district := 0
var start_district := 0
var start_meter := 0.0
var test_run := false
var burst_index := 0
var distance := 0.0
var speed := Tuning.START_SPEED
var base_speed := Tuning.START_SPEED
var slow := RunnerSlowTime.new()
var hover_in := 2.0
var coins := 0
var banked := 0
var health := Tuning.MAX_HEALTH
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
	track.heart_taken.connect(_on_heart)
	track.timer_taken.connect(_on_slow_time)
	player = MurangPlayer.new()
	add_child(player)
	player.jumped.connect(_on_jump)
	player.landed.connect(_on_land)
	player.slide_started.connect(_on_slide)
	motion_fx = RunnerMotionFX.new()
	add_child(motion_fx)
	motion_fx.setup(player)
	camera = Camera3D.new()
	camera.current = true
	camera.near = 0.14
	camera.far = 155.0
	add_child(camera)
	_make_particles()

	audio = RunnerAudio.new()
	add_child(audio)
	records.read_records()
	var preferences := ConfigFile.new()
	if preferences.load(DISPLAY_CONFIG) == OK:
		low_graphics = bool(preferences.get_value("graphics", "low", false))
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = RunnerUI.new()
	ui.best = records.best
	ui.bank = records.bank
	ui.low_graphics = low_graphics
	canvas.add_child(ui)
	ui.start_requested.connect(_start)
	ui.test_requested.connect(func(id: int): _start(id, true))
	ui.slow_requested.connect(_request_debug_slow)
	ui.visibility_requested.connect(_toggle_visibility_debug)
	ui.heart_requested.connect(_request_debug_heart)
	ui.graphics_requested.connect(_toggle_graphics)
	ui.replay_requested.connect(_restart)
	ui.pause_requested.connect(_pause)
	ui.resume_requested.connect(_resume)
	ui.home_requested.connect(_show_home)
	ui.mute_requested.connect(_toggle_audio)
	get_viewport().size_changed.connect(_check_viewport)
	_check_viewport()
	_prepare_title_actor()
	_update_atmosphere(Tuning.scenery_weights(MENU_MILE))
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
	sky_mix.set_shader_parameter("forest_panorama", FOREST_SKY)
	sky_mix.set_shader_parameter("neon_panorama", NEON_SKY)
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


func _emit_burst(at: Vector3, tint: Color, dust := false, force := 1.0) -> void:
	var puffs := bursts[burst_index]
	burst_index = (burst_index + 1) % bursts.size()
	puffs.position = at
	puffs.mesh = dust_mesh if dust else spark_mesh
	puffs.scale_amount_max = 1.24 * force
	puffs.initial_velocity_max = 4.0 * force
	puffs.spread = 48.0 if dust else 52.0
	puffs.direction = Vector3(0, 0.36, 1.0) if dust else Vector3.UP
	puffs.lifetime = 0.32 if dust else 0.49
	(puffs.material_override as StandardMaterial3D).albedo_color = tint
	puffs.restart()


func _check_viewport() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	portrait_view = viewport_size.x < viewport_size.y * 0.98
	var baseline := 0.83 if OS.has_feature("web") and portrait_view else 1.0
	get_viewport().scaling_3d_scale = minf(baseline, 0.73) if low_graphics else baseline
	sunlight.directional_shadow_max_distance = 32.0 if portrait_view else 48.0
	sunlight.shadow_enabled = not low_graphics
	motion_fx.performance_mode = low_graphics
	track.hearts.performance_mode = low_graphics
	track.timers.performance_mode = low_graphics
	track.neon.performance_mode(low_graphics)
	for puffs in bursts:
		puffs.amount = 6 if low_graphics else 11


func _toggle_graphics() -> void:
	low_graphics = not low_graphics
	var config := ConfigFile.new()
	config.set_value("graphics", "low", low_graphics)
	if config.save(DISPLAY_CONFIG) != OK:
		push_warning("Could not save the graphics preference.")
	ui.low_graphics = low_graphics
	audio.play_sound(&"click")
	_check_viewport()
	surf_particles.emitting = scene_mix.y > 0.39 and not low_graphics
	ui.show_screen(ui.screen)


func _start(requested_district := 0, practice := false) -> void:
	audio.play_sound(&"click")
	test_run = practice and Tuning.ENABLE_DISTRICT_TEST
	start_district = clampi(requested_district, 0, Tuning.DISTRICTS.size() - 1) if test_run else 0
	start_meter = float(Tuning.DISTRICTS[start_district].start)
	distance = start_meter
	base_speed = Tuning.speed_at(distance)
	speed = base_speed
	slow.reset()
	hover_in = 2.0
	ui.slow_seconds = 0.0
	ui.slow_recovery = 0.0
	ui.slow_wave = 0.0
	ui.base_speed = base_speed
	ui.visibility_debug = false
	district = Tuning.district_at(distance)
	coins = 0
	banked = 0
	health = Tuning.MAX_HEALTH
	start_best = records.best
	shake = 0.0
	finish_timer = 0.0
	ready_remaining = 0.23
	save_in = SAVE_INTERVAL
	last_ui_score = -1
	steps_in = 0.0
	ui.pace = Tuning.speed_effect(speed)
	ui.speed = speed
	ui.heal_time = 0.0
	ui.pulse = 0.0
	swipe_id = -1
	landing_kick = 0.0
	camera_roll = 0.0
	skid_puffs_in = 0.0
	ground_steps = 0
	motion_fx.reset()
	player.reset()
	player.model.rotation = Vector3.ZERO
	player.show()
	track.reset(randi() & 0x7ffffff, distance)
	if test_run:
		player.lane = track.spawn_lane_at(distance)
		player.position.x = player.lane * Tuning.LANE
	_update_atmosphere(Tuning.scenery_weights(distance))
	audio.start_music()
	audio.set_wind(ui.pace)
	state = State.RUNNING
	ui.test_run = test_run
	ui.set_district(district, test_run)
	ui.update_values(0, int(distance), 0, Tuning.MAX_HEALTH)
	ui.show_screen(RunnerUI.Screen.HUD)


func _restart() -> void:
	_start(start_district, test_run)


func _session_score() -> int:
	return Tuning.points(distance - start_meter, coins)


func _update_atmosphere(weights: Vector4) -> void:
	# Update the panorama in bounded steps. The road and input keep moving.
	var harbor := snappedf(weights.y, 1.0 / 48.0)
	var forest := snappedf(weights.z, 1.0 / 48.0)
	var neon := snappedf(weights.w, 1.0 / 48.0)
	var mix := Vector4(maxf(0.0, 1.0 - harbor - forest - neon), harbor, forest, neon)
	if scene_mix.is_equal_approx(mix):
		return
	scene_mix = mix
	sky_mix.set_shader_parameter("districts", mix)
	environment.ambient_light_color = Color("#d9eaf5").lerp(Color("#f1d7c5"), harbor).lerp(Color("#cfded3"), forest).lerp(Color("#c0d3fc"), neon)
	environment.ambient_light_energy = 0.41 - 0.01 * harbor + 0.025 * forest + 0.05 * neon
	environment.fog_light_color = Color("#c5e5f0").lerp(Color("#edc6a6"), harbor).lerp(Color("#96ada6"), forest).lerp(Color("#2c3356"), neon)
	environment.fog_density = 0.0086 - 0.0019 * harbor + 0.0035 * forest - 0.003 * neon
	sunlight.light_color = Color("#fff0d8").lerp(Color("#ffd0a3"), harbor).lerp(Color("#fff1d2"), forest).lerp(Color("#b2ccff"), neon)
	sunlight.light_energy = 0.58 + 0.07 * harbor + 0.015 * forest - 0.37 * neon
	sunlight.rotation_degrees = Vector3(-56, -36, 0).lerp(Vector3(-31, -55, 0), harbor).lerp(Vector3(-43, -51, 0), forest).lerp(Vector3(-51, 46, 0), neon)
	audio.set_scenery(mix)
	surf_particles.emitting = harbor > 0.39 and not low_graphics


func _show_home() -> void:
	if state != State.MENU:
		_save_progress()
	audio.play_sound(&"click")
	_prepare_title_actor()
	motion_fx.reset()
	audio.set_wind(0.0)
	track.reset(2, MENU_MILE, true)
	_update_atmosphere(Tuning.scenery_weights(MENU_MILE))
	distance = 0.0
	state = State.MENU
	swipe_id = -1
	ui.show_screen(RunnerUI.Screen.TITLE)


func _prepare_title_actor() -> void:
	player.reset()
	player.model.rotation.y = PI - 0.43
	player.position.x = 0.0 if portrait_view else 2.60
	player.show()


func _pause() -> void:
	if state != State.RUNNING:
		return
	state = State.PAUSED
	audio.set_wind(0.0)
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
	motion_fx.reset()
	audio.set_wind(0.0)
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
			elif state == State.MENU and ui.screen in [RunnerUI.Screen.HELP, RunnerUI.Screen.DEV]:
				ui.show_screen(RunnerUI.Screen.TITLE)
			else:
				return
		elif state == State.RUNNING:
			match key:
				KEY_A, KEY_LEFT: player.steer(-1)
				KEY_D, KEY_RIGHT: player.steer(1)
				KEY_H: _request_debug_heart()
				KEY_T: _request_debug_slow()
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


func _request_debug_heart() -> void:
	if state != State.RUNNING or not test_run or not Tuning.ENABLE_DISTRICT_TEST:
		return
	if track.debug_pickup(distance, false):
		audio.play_sound(&"click")


func _request_debug_slow() -> void:
	if state == State.RUNNING and test_run and Tuning.ENABLE_DISTRICT_TEST and track.debug_pickup(distance, true):
		audio.play_sound(&"click")


func _toggle_visibility_debug() -> void:
	if test_run and state == State.RUNNING:
		ui.visibility_debug = not ui.visibility_debug
		track._set_visibility_debug(ui.visibility_debug)
		ui.show_screen(ui.screen)


func _on_slow_time(at: Vector3) -> void:
	if state != State.RUNNING or not slow.activate():
		return
	speed = base_speed * slow.multiplier()
	ui.speed = speed
	ui.pace = Tuning.speed_effect(speed)
	ui.slow_seconds = slow.remaining
	ui.slow_wave = 0.43
	_emit_burst(at, SLOW_COLOR, false, 1.4)
	_emit_burst(player.position + Vector3(0, 0.73, 0), Color("#b4efff"))
	audio.play_sound(&"slow", -8.0)


func _on_heart(at: Vector3) -> void:
	if state != State.RUNNING or health >= Tuning.MAX_HEALTH:
		return
	health += 1
	_emit_burst(at, HEALTH_COLOR, false, 1.36)
	_emit_burst(player.position + Vector3(0, 0.71, 0), Color("#ffbccc"))
	audio.play_sound(&"health", -8.0)
	ui.update_values(_session_score(), int(distance), coins, health)
	ui.show_heal(health - 1)


func _on_jump() -> void:
	if ui.pace > 0.39:
		_emit_burst(player.position + Vector3(0, 0.1, 0.18), GROUND_COLORS[district], true, 0.9 + ui.pace * 0.4)
	audio.play_sound(&"jump", -12.0)


func _on_land() -> void:
	landing_kick = 0.18
	_emit_burst(player.position + Vector3(0, 0.09, 0.24), GROUND_COLORS[district], true, 0.88 + ui.pace * 0.42)
	audio.play_sound(&"land", -15.0)


func _on_slide() -> void:
	skid_puffs_in = 0.0
	audio.play_sound(&"slide", lerpf(-17.0, -8.0, ui.pace), lerpf(0.78, 1.28, ui.pace))


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
	_emit_burst(at, HIT_COLOR, false, 1.19)
	_emit_burst(at + Vector3(0, -0.55, 0.19), GROUND_COLORS[district].lerp(Color("#7a5d48"), 0.42), true, 1.16)
	audio.play_sound(&"hit", -14.0)
	if health <= 0:
		_finish()


func _physics_process(dt: float) -> void:
	clock += dt
	if state == State.RUNNING:
		if ready_remaining > 0.0:
			ready_remaining -= dt
			player.step(dt, 0.0, false, false)
			motion_fx.step(dt, speed, ui.pace, district, player)
			_camera_step(dt)
			return
		var previous := distance
		var had_time := slow.remaining
		# Sample the current frame's multiplier before consuming its duration.
		base_speed = Tuning.speed_at(distance)
		speed = base_speed * slow.multiplier()
		distance += dt * speed
		slow.advance(dt)
		ui.slow_seconds = slow.remaining
		ui.slow_recovery = slow.recovery
		ui.base_speed = base_speed
		if had_time > 0.85 and slow.remaining <= 0.85:
			audio.play_sound(&"slow", -24.0, 1.45)
		var next := Tuning.district_at(distance)
		if district != next:
			district = next
			ui.set_district(district, true)
		_update_atmosphere(Tuning.scenery_weights(distance))
		ui.pace = Tuning.speed_effect(speed)
		ui.speed = speed
		audio.set_wind(ui.pace)
		player.step(dt, speed, true, false)
		motion_fx.step(dt, speed, ui.pace, district, player)
		track.scroll(distance, dt, speed)
		track.check_contacts(previous, distance, player)
		if district == 3:
			hover_in -= dt
			if hover_in <= 0.0:
				audio.play_sound(&"hover", -26.0 + ui.pace * 4.5, 0.82 + ui.pace * 0.20)
				hover_in = 3.7 + sin(clock * 0.55) * 0.82
		steps_in -= dt
		if steps_in <= 0.0 and player.elevation < 0.025 and player.slide <= 0.0:
			steps_in = 1.0 / (5.4 + speed * 0.15)
			ground_steps += 1
			audio.play_sound(&"step", lerpf(-31.0, -21.0, ui.pace), 0.89 + ui.pace * 0.24 + 0.06 * sin(clock * 17.0))
			if ground_steps % (1 if ui.pace > 0.64 and not low_graphics else 3) == 0:
				var heel := 0.17 if ground_steps % 2 == 0 else -0.17
				_emit_burst(player.position + Vector3(heel, 0.06, 0.28), GROUND_COLORS[district], true, 0.48 + ui.pace * 0.34)
		skid_puffs_in = maxf(0.0, skid_puffs_in - dt)
		if player.stance > 0.53 and skid_puffs_in <= 0.0:
			_emit_burst(player.position + Vector3(0, 0.055, 0.43), GROUND_COLORS[district], true, 0.90 + ui.pace * 0.57)
			skid_puffs_in = lerpf(0.119, 0.065, ui.pace) * (1.42 if low_graphics else 1.0)
		save_in -= dt
		if save_in <= 0.0:
			_save_progress()
			save_in = SAVE_INTERVAL
		var point_total := _session_score()
		if point_total != last_ui_score:
			last_ui_score = point_total
			ui.update_values(point_total, int(distance), coins, health)
	elif state == State.MENU:
		player.position.x = 0.0 if portrait_view else 2.60
		player.step(dt, 0.0, false, false)
		player.model.rotation.y = PI - 0.43 + sin(clock * 0.72) * 0.072
		track.scroll(MENU_MILE, dt)
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
	if state == State.MENU:
		_title_camera(dt)
		return
	shake = maxf(0.0, shake - dt)
	landing_kick = maxf(0.0, landing_kick - dt * 1.1)
	var blend := 1.0 - exp(-7.0 * dt)
	var power := ui.pace if state == State.RUNNING else 0.0
	var offset := player.position.x * (0.62 if portrait_view else 0.42)
	var rise := minf(0.47, player.elevation * 0.28) - player.stance * 0.54 - landing_kick
	var jitter := power * power * (0.013 if low_graphics else 0.024)
	var shake_x := sin(clock * 89.0) * shake * 0.26 + sin(clock * 24.0) * jitter
	var shake_y := cos(clock * 74.0) * shake * 0.24 + sin(clock * 31.0) * jitter
	var pullback := (6.85 if portrait_view else 6.45) + power * 1.10
	var goal := Vector3(offset + shake_x, 4.54 + rise + shake_y, pullback)
	camera.position = camera.position.lerp(goal, blend)
	camera_roll = lerpf(camera_roll, -player.enter_x * (0.015 + power * 0.021), blend)
	camera.look_at(Vector3(offset * 0.45, 1.14 + rise * 0.48, -9.4), Vector3.UP)
	camera.rotate_object_local(Vector3.BACK, camera_roll)
	var base_fov := 78.0 if portrait_view else 59.0
	var gain := 0.76 if portrait_view else 1.0
	camera.fov = lerpf(camera.fov, base_fov + power * Tuning.SPEED_FOV_GAIN * gain, blend)


func _title_camera(dt: float) -> void:
	var float_x := sin(clock * 0.32) * 0.13
	var dolly := cos(clock * 0.24) * 0.15
	var goal := Vector3(0.06 + float_x, 2.10, 4.30 + dolly) if portrait_view else Vector3(-0.45 + float_x, 2.26, 5.15 + dolly)
	camera.position = camera.position.lerp(goal, 1.0 - exp(-6.0 * dt))
	var aim := Vector3(0.0, -0.03, -3.0) if portrait_view else Vector3(0.47, 1.40, -3.5)
	camera.look_at(aim, Vector3.UP)
	camera.fov = lerpf(camera.fov, 60.0 if portrait_view else 48.0, 1.0 - exp(-6.0 * dt))
