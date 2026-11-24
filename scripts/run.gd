extends Node3D

enum State { MENU, RUNNING, PAUSED, FINISHED }

const SKY := preload("res://assets/park/kloofendal-sky.webp")
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
	track.reset(2)
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
	ui.touch = OS.has_feature("web_android") or OS.has_feature("web_ios") or DisplayServer.is_touchscreen_available()
	canvas.add_child(ui)
	ui.start_requested.connect(_start)
	ui.pause_requested.connect(_pause)
	ui.resume_requested.connect(_resume)
	ui.home_requested.connect(_show_home)
	ui.mute_requested.connect(_toggle_audio)
	get_viewport().size_changed.connect(_check_viewport)
	_check_viewport()
	_camera_step(1.0)


func _make_lighting() -> void:
	var world := WorldEnvironment.new()
	var atmosphere := Environment.new()
	atmosphere.background_mode = Environment.BG_SKY
	var daylight := Sky.new()
	var panoramic := PanoramaSkyMaterial.new()
	panoramic.panorama = SKY
	panoramic.filter = true
	daylight.sky_material = panoramic
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
	sun.light_color = Color("#fff2d4")
	sun.light_energy = 0.65
	sun.rotation_degrees = Vector3(-56, -36, 0)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.8
	sun.directional_shadow_max_distance = 52.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)


func _make_particles() -> void:
	var mote := SphereMesh.new()
	mote.radial_segments = 6
	mote.rings = 3
	mote.radius = 0.07
	mote.height = 0.14
	for i in range(8):
		var puffs := CPUParticles3D.new()
		puffs.mesh = mote
		puffs.amount = 11
		puffs.one_shot = true
		puffs.emitting = false
		puffs.lifetime = 0.37
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
		puffs.material_override = material
		puffs.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bursts.append(puffs)
		add_child(puffs)


func _emit_burst(at: Vector3, tint: Color) -> void:
	var puffs := bursts[burst_index]
	burst_index = (burst_index + 1) % bursts.size()
	puffs.position = at
	(puffs.material_override as StandardMaterial3D).albedo_color = tint
	puffs.restart()


func _check_viewport() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	portrait_view = viewport_size.x < viewport_size.y * 0.98
	if OS.has_feature("web"):
		get_viewport().scaling_3d_scale = 0.84 if portrait_view else 1.0


func _start() -> void:
	audio.play_sound(&"click")
	if not audio.music.playing:
		audio.music.play()
	distance = 0.0
	speed = Tuning.START_SPEED
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
	track.reset(randi() & 0x7ffffff)
	state = State.RUNNING
	ui.update_values(0, 0, 0, 3)
	ui.show_screen(RunnerUI.Screen.HUD)


func _show_home() -> void:
	if state != State.MENU:
		_save_progress()
	audio.play_sound(&"click")
	player.reset()
	player.hide()
	track.reset(2)
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
	ui.new_best = Tuning.points(distance, coins) > start_best
	_save_progress()
	audio.play_sound(&"over", -10.0)


func _save_progress() -> void:
	records.record(distance, Tuning.points(distance, coins), coins - banked)
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
		elif key == KEY_ENTER and ui.screen in [RunnerUI.Screen.TITLE, RunnerUI.Screen.OVER]:
			_start()
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
	_emit_burst(player.position + Vector3(0, 0.13, 0.24), DUST_COLOR)
	audio.play_sound(&"land", -15.0)


func _on_coin(at: Vector3) -> void:
	if state != State.RUNNING:
		return
	coins += 1
	_emit_burst(at, REWARD_COLOR)
	audio.play_sound(&"coin", -12.0, 1.0 + float(coins % 5) * 0.043)
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
		var point_total := Tuning.points(distance, coins)
		if point_total != last_ui_score:
			last_ui_score = point_total
			ui.update_values(point_total, int(distance), coins, health)
	elif state == State.MENU:
		player.step(dt, 0.0, false, false)
		track.scroll(0.0, dt * 0.42)
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
	var shake_x := sin(clock * 89.0) * shake * 0.33
	var shake_y := cos(clock * 74.0) * shake * 0.27
	var goal := Vector3(offset + shake_x, 4.54 + rise + shake_y, 6.85 if portrait_view else 6.45)
	camera.position = camera.position.lerp(goal, blend)
	camera.look_at(Vector3(offset * 0.45, 1.14 + rise * 0.40, -9.4), Vector3.UP)
	var base_fov := 78.0 if portrait_view else 59.0
	var wanted := base_fov + ui.pace * 5.0
	camera.fov = lerpf(camera.fov, wanted, blend)
