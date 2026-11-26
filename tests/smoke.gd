extends SceneTree
## Run with a disposable XDG_DATA_HOME so it can exercise real persistence.

const GAME := preload("res://scenes/run.tscn")
const STEP := 1.0 / 60.0
var failures: Array[String] = []
var game: Node3D


func _initialize() -> void:
	seed(500)
	call_deferred("_run")


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures.append(description)
		push_error(description)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)


func _touch_swipe(from: Vector2, change: Vector2) -> void:
	var tap := InputEventScreenTouch.new()
	tap.position = from
	tap.pressed = true
	root.push_input(tap)
	var motion := InputEventScreenDrag.new()
	motion.position = from + change
	motion.relative = change
	root.push_input(motion)
	tap.position = motion.position
	tap.pressed = false
	root.push_input(tap)


func _step(count: int) -> void:
	for i in range(count):
		game._physics_process(STEP)


func _run() -> void:
	if not FileAccess.file_exists(RunnerSave.PATH):
		var v01 := ConfigFile.new()
		v01.set_value("records", "best", 421)
		v01.set_value("records", "furthest", 201)
		v01.set_value("records", "bank", 31)
		_check(v01.save(RunnerSave.PATH) == OK, "Legacy save fixture was written")
	game = GAME.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	var initial_bank: int = game.records.bank
	_check(game.ui.bank == initial_bank and initial_bank >= 31 and game.records.furthest >= 201, "Reads the v0.1 local record schema")
	var player: MurangPlayer = game.player
	var track: RunnerTrack = game.track
	_check(game.state == game.State.MENU, "Opens on the title screen")
	_check(game.camera.position.z > player.position.z and game.camera.rotation.y < 0.1, "Rear camera faces the track")
	_key(KEY_ENTER)
	_check(game.state == game.State.RUNNING, "Enter starts a run")
	_step(24)
	_check(game.distance > 0.9, "Runner advances automatically")
	_key(KEY_A)
	_step(4)
	_check(player.position.x < -0.6 and player.position.x > -Tuning.LANE, "Keyboard lane change interpolates")
	_step(8)
	_check(is_equal_approx(player.position.x, -Tuning.LANE), "Arrives at the left lane")
	_key(KEY_RIGHT)
	_step(10)
	_check(is_zero_approx(player.position.x), "Arrow key steers to center")
	_key(KEY_SPACE)
	_step(20)
	_check(player.elevation > 1.3, "Space jumps")
	_step(40)
	_check(is_zero_approx(player.elevation), "Jump returns to the ground")
	var waist_scale := player.body.scale
	var mesh_scale := player.head_mesh.scale
	_key(KEY_DOWN)
	_step(12)
	_check(is_equal_approx(player.height(), MurangPlayer.CROUCH_HEIGHT), "Down key lowers the collision profile")
	_check(player.body.rotation.x > 0.95 and player.body.position.y < 0.43
		and player.knees[1].rotation.x < -0.19, "Slide bends the knees, lowers the waist and leans the torso back")
	_check(player.model.scale == Vector3.ONE and player.body.scale == waist_scale and player.head_mesh.scale == mesh_scale,
		"Sliding keeps the authored part scales")
	var boot := player.knees[0].find_child("HindpawL", true, false) as MeshInstance3D
	_check(boot.global_position.z < player.body.global_position.z - 0.32, "The lead foot extends in the direction of travel")
	_key(KEY_D)
	_step(10)
	_check(is_equal_approx(player.position.x, Tuning.LANE) and player.slide > 0.0, "Lane steering remains available while sliding")
	_key(KEY_A)
	var left: float = player.slide
	_key(KEY_S)
	_check(player.slide == left, "A repeated slide press does not latch or refresh the active clip")
	_step(38)
	_check(player.height() == MurangPlayer.STAND_HEIGHT, "Slide recovers automatically")

	var touch_center := root.get_visible_rect().size * Vector2(0.5, 0.65)
	_touch_swipe(touch_center, Vector2(100, 0))
	_step(10)
	_check(player.lane == 1, "A right swipe steers")
	_touch_swipe(touch_center, Vector2(-100, 0))
	_step(10)
	_check(player.lane == 0, "A left swipe steers")
	_touch_swipe(touch_center, Vector2(0, -100))
	_step(5)
	_check(player.elevation > 0.4, "An up swipe jumps")
	_step(42)
	_touch_swipe(touch_center, Vector2(0, 100))
	_step(12)
	_check(player.height() == MurangPlayer.CROUCH_HEIGHT, "A down swipe crouches")

	_key(KEY_ESCAPE)
	var parked: float = game.distance
	_step(100)
	_check(game.state == game.State.PAUSED and game.distance == parked, "Escape pauses distance and collisions")
	_key(KEY_ESCAPE)
	_check(game.state == game.State.RUNNING, "Escape resumes the run")

	# The opening coin trail always runs through the center.
	_step(50)
	_check(game.coins > 0, "Stock 3D coins register on contact")
	var carried: int = game.coins

	game.health = 3
	_check_recovery(track, player)
	for i in range(3):
		var next := _next_obstacle(track, game.distance + 3.0)
		_check(next != null, "A hittable obstacle is pooled ahead")
		if next == null:
			break
		player.lane = next.lane
		player.position.x = next.visual.position.x
		player.slide = 0.0
		player.stance = 0.0
		player.elevation = 0.0
		player.vertical_speed = 0.0
		player.immunity = 0.0
		game.distance = next.meter - 0.39
		_step(1)
		_check(game.health == 2 - i, "Obstacle subtracts exactly one heart")
		_step(10)
		_check(game.health == 2 - i, "The same obstacle never deals repeat damage")
	_step(34)
	_check(game.state == game.State.FINISHED and game.ui.screen == RunnerUI.Screen.OVER, "Zero hearts produces the results screen")
	var saved := RunnerSave.new()
	saved.read_records()
	_check(saved.best >= Tuning.points(game.distance, game.coins) and saved.furthest >= int(game.distance), "Score and distance reload from local storage")
	_check(saved.bank == initial_bank + game.coins and game.coins >= carried, "Coins save exactly once")
	_key(KEY_ENTER)
	_check(game.state == game.State.RUNNING and game.health == 3 and game.coins == 0, "Replay resets the run immediately")
	game._show_home()
	_check(game.state == game.State.MENU and game.ui.bank == saved.bank, "Home displays the saved coin total")

	_check_harbor()
	_check_forest_and_hearts()
	_check_neon_and_slow()
	_check_schedule()
	_check_slow_schedule()
	_check_patterns(track)
	_stress(track)
	if failures.is_empty():
		print("PASS: start, rear camera, run, keyboard and swipe, pause, jump/slide clearance, coins, damage, results, save, restart, solvable rows, seamless three map boundaries, isolated test starts, rare hearts, slow time and pooled endurance")
	game.audio.music.stop()
	for voice in game.audio.voices:
		voice.stop()
	await create_timer(0.15).timeout
	quit(0 if failures.is_empty() else 1)


func _next_obstacle(track: RunnerTrack, after: float) -> RunnerTrack.Obstacle:
	var result: RunnerTrack.Obstacle
	for chunk in track.chunks:
		for obstacle in chunk.obstacles:
			if obstacle.armed and obstacle.meter > after and (result == null or obstacle.meter < result.meter):
				result = obstacle
	return result


func _check_recovery(track: RunnerTrack, player: MurangPlayer) -> void:
	var chunk := track.chunks[2]
	var fixture := RunnerTrack.Obstacle.new()
	fixture.visual = Node3D.new()
	chunk.visual.add_child(fixture.visual)
	fixture.meter = Tuning.FIRST_ROW - 6.0
	fixture.lane = 0
	fixture.kind = RunnerTrack.Kind.CRATE
	fixture.armed = true
	chunk.obstacles.append(fixture)
	chunk.visual.position.z = 16.0
	player.position.x = 0.0
	player.elevation = 1.36
	player.immunity = 0.0
	player.slide = 0.0
	track.check_contacts(fixture.meter - 0.1, fixture.meter, player)
	_check(fixture.armed and player.immunity == 0.0, "A jump clears the low crate")
	fixture.kind = RunnerTrack.Kind.BOOM
	player.elevation = 0.0
	player.slide = 0.30
	player.stance = 1.0
	track.check_contacts(fixture.meter - 0.1, fixture.meter, player)
	_check(fixture.armed and player.immunity == 0.0, "A slide clears the overhead barrier")
	player.slide = 0.0
	player.stance = 0.0
	var before: int = game.health
	track.check_contacts(fixture.meter - 1.4, fixture.meter + 1.4, player)
	_check(game.health == before - 1 and not fixture.armed, "A swept contact catches a fully crossed obstacle")
	game.health = before
	player.immunity = 0.0
	chunk.obstacles.pop_back()
	fixture.visual.free()
	track.scroll(game.distance, 0.0)


func _check_harbor() -> void:
	var track: RunnerTrack = game.track
	game._start()
	game.ready_remaining = 0.0
	game.distance = Tuning.HARBOR_START - 0.12
	track.reset(553, game.distance)
	var pool_nodes := get_node_count()
	var first := _next_obstacle(track, Tuning.HARBOR_START)
	_check(first != null and first.kind >= RunnerTrack.Kind.BARREL, "Harbor-only obstacles are prepooled")
	var first_signature := Vector3(first.lane, first.kind, first.meter)
	_step(1)
	_check(game.state == game.State.RUNNING and game.distance > Tuning.HARBOR_START, "Crossing 1,500 m stays in the running state")
	_check(game.track == track and game.track.seed_value == 553 and get_node_count() == pool_nodes, "Transition reuses the same live track and nodes")
	_check(game.district == 1 and game.ui.district == 1 and game.ui.area_time > 0.0, "Crossing announces the harbor")
	_check(is_equal_approx(game.speed, Tuning.speed_at(Tuning.HARBOR_START - 0.12)), "Crossing preserves the continuous speed curve")
	for chunk in track.chunks:
		if chunk.index == 41:
			_check(chunk.roads[0].visible and chunk.shore[0].visible and chunk.roads[1].visible, "The approach keeps the road beside the shore")
			_check(chunk.boardwalk[2].visible and not chunk.roads[2].visible, "The 1,500 m tile starts the boardwalk")

	game._show_home()
	var before := RunnerSave.new()
	before.read_records()
	game.ui.test_requested.emit(1)
	_check(game.test_run and game.distance == Tuning.HARBOR_START and game.district == 1, "Title test action enters the harbor")
	_check(game.health == 3 and game.coins == 0 and game.ui.score == 0 and game.ui.test_run, "Test starts with clean run totals and full health")
	_check(is_equal_approx(game.speed, Tuning.speed_at(Tuning.HARBOR_START)), "Direct and normal starts use the same speed curve")
	track.reset(553, Tuning.HARBOR_START)
	first = _next_obstacle(track, Tuning.HARBOR_START)
	_check(Vector3(first.lane, first.kind, first.meter) == first_signature, "The same seed produces the exact same entry row on either path")
	game._on_coin(Vector3.ZERO)
	_check(game.coins == 1 and game._session_score() == 25, "Test coin scoring uses distance relative to the test start")
	game.distance = 3500.0
	game._save_progress()
	game._finish()
	_step(31)
	var after := RunnerSave.new()
	after.read_records()
	_check(after.best == before.best and after.furthest == before.furthest and after.bank == before.bank,
		"Test coin, distance and score never change regular records")
	_check(not game.ui.new_best and game.ui.screen == RunnerUI.Screen.OVER, "Test results stay separate")
	_key(KEY_ENTER)
	_check(game.test_run and game.distance == Tuning.HARBOR_START, "Test replay returns to the same district")
	game._show_home()
	_key(KEY_ENTER)
	_check(not game.test_run and game.distance == 0.0 and game.ui.score == 0, "Normal play still starts from zero afterward")
	game._show_home()


func _check_forest_and_hearts() -> void:
	var track: RunnerTrack = game.track
	var runner: MurangPlayer = game.player
	game._start()
	game.ready_remaining = 0.0
	var before_fov: float = game.camera.fov
	game._request_debug_heart()
	_check(track.hearts.debug.meter < 0.0, "Ordinary play cannot force a debug pickup")
	game.distance = Tuning.FOREST_START - 0.11
	game.health = 2
	game.coins = 5
	game.banked = 5
	track.reset(611, game.distance)
	runner.lane = track.spawn_lane_at(game.distance)
	runner.position.x = runner.lane * Tuning.LANE
	_step(12)
	_check(game.state == game.State.RUNNING and game.track == track and game.district == 2 and game.ui.area_time > 0.0, "3,000 m transitions on the live run")
	_check(game.health == 2 and game.coins >= 5 and game.speed > Tuning.speed_at(2999), "Forest entry retains health, coins and speed")
	_check(game.camera.fov > before_fov + 3.0 and game.ui.pace >= 0.75 and track.forest != null,
		"Late-run speed widens the camera and activates the forest")
	var visible_wind := 0
	for streak in game.motion_fx.wind:
		visible_wind += int(streak.visible)
		_check(not streak.visible or absf(streak.position.x) > 4.7, "World wind remains outside the lanes")
	_check(visible_wind >= 19, "High speed raises the pooled wind count")
	for block in track.chunks:
		if block.index == 83:
			_check(block.boardwalk[0].visible and not block.forest_floors[0].visible, "The approach keeps the coastal deck")
			_check(block.forest_floors[1].visible and not block.boardwalk[1].visible, "The 3,000 m tile begins the valley bridge")
	game._show_home()
	var before := RunnerSave.new()
	before.read_records()
	game.ui.test_requested.emit(2)
	_check(game.test_run and game.distance == Tuning.FOREST_START and game.health == Tuning.MAX_HEALTH
		and game.ui.score == 0 and game.coins == 0, "Forest test starts at 3,000 m with full health and clean totals")
	_check(game.speed == Tuning.speed_at(Tuning.FOREST_START) and game.ui.pace == Tuning.speed_effect(game.speed),
		"Direct forest tests have the correct speed and effect tier immediately")

	game.health = 2
	_key(KEY_H)
	var debug: RunnerPickupPool.Slot = track.hearts.debug
	var at: float = debug.meter
	_check(at > game.distance, "H places a pooled heart ahead during a test")
	game.ui.heart_requested.emit()
	_check(debug.meter == at, "A second debug request leaves one active debug heart")
	runner.position.x = debug.lane * Tuning.LANE
	runner.elevation = 0.0
	track.hearts.scroll(at, STEP)
	var coins_before: int = game.coins
	track.hearts.check_contacts(at - 2.1, at + 2.1, runner)
	_check(game.health == Tuning.MAX_HEALTH and game.ui.heal_time > 0.0 and debug.meter < 0.0,
		"A swept high-speed pickup heals exactly one heart")
	_check(game.coins == coins_before, "Healing does not award coins")
	game.ui.heart_requested.emit()
	at = debug.meter
	runner.position.x = debug.lane * Tuning.LANE
	track.hearts.scroll(at, STEP)
	track.hearts.check_contacts(at - 2.1, at + 2.1, runner)
	_check(game.health == Tuning.MAX_HEALTH and game.coins == coins_before and debug.meter < 0.0,
		"A full-health pickup is consumed without bonus health or coins")

	var reduced: bool = game.low_graphics
	game._toggle_graphics()
	_check(game.low_graphics != reduced and game.motion_fx.performance_mode == game.low_graphics
		and game.sunlight.shadow_enabled != game.low_graphics, "Graphics switch updates particles, trails and shadows")
	var settings := ConfigFile.new()
	_check(settings.load(game.DISPLAY_CONFIG) == OK and settings.get_value("graphics", "low") == game.low_graphics,
		"Graphics settings persist separately from records")
	game._toggle_graphics()
	game._show_home()
	var after := RunnerSave.new()
	after.read_records()
	_check(after.best == before.best and after.bank == before.bank and after.furthest == before.furthest,
		"Forest test and recovery leave ordinary records intact")


func _check_schedule() -> void:
	var schedule := RunnerPickupSchedule.new()
	var eligible := 0
	var spawns := 0
	for run_seed in range(100):
		schedule.reset(run_seed, 0.0)
		_check(schedule.advance(499.9) == -1, "No hearts below 500 m")
		var last := -Tuning.HEART_COOLDOWN
		for meter in range(500, 19001, 100):
			var available := meter - last >= Tuning.HEART_COOLDOWN
			eligible += int(available)
			var spawn := schedule.advance(meter)
			if spawn >= 0:
				_check(spawn == meter and available, "Heart spawns honor the exact 100 m roll and 800 m cooldown")
				last = meter
				spawns += 1
			_check(schedule.advance(meter) == -1, "An already evaluated marker cannot spawn twice")
		var replay := RunnerPickupSchedule.new()
		replay.reset(run_seed, 19000.0)
		_check(schedule.last_meter == replay.last_meter and schedule.advance(19100.0) == replay.advance(19100.0),
			"A direct start preserves the seed and heart cooldown from prior course markers")
	var rate := float(spawns) / eligible
	_check(absf(rate - Tuning.HEART_CHANCE) <= 0.015, "Eligible heart rolls stay close to 10 percent")
	print("Heart schedule: %d/%d eligible rolls (%.2f%%), 100 seeds" % [spawns, eligible, 100.0 * rate])



func _check_neon_and_slow() -> void:
	var track: RunnerTrack = game.track
	var player: MurangPlayer = game.player
	game.ui.test_requested.emit(0)
	_check(game.test_run and game.distance == 0 and game.ui.test_run, "The city park has an isolated developer start")
	game._show_home()
	game._start()
	_key(KEY_T)
	_check(track.timers.debug.meter < 0.0, "Normal runs cannot force Slow Time")
	game.ready_remaining = 0.0
	game.distance = Tuning.NEON_START - 0.08
	game.coins = 9
	game.banked = 9
	game.health = 2
	track.reset(308, game.distance)
	player.immunity = 1.0
	game._on_slow_time(Vector3.ZERO)
	_step(1)
	_check(game.distance > Tuning.NEON_START and game.district == 3 and game.ui.area_time > 0.0, "4,500 m enters the city on the same run")
	_check(game.health == 2 and game.coins >= 9 and game.slow.remaining > 5.9
		and is_equal_approx(game.speed, game.base_speed * 0.8), "Transition carries health, coins, base speed and active Slow Time")
	for chunk in track.chunks:
		if chunk.index == 124:
			_check(chunk.forest_floors[0].visible and chunk.neon_road[1].visible
				and chunk.neon_approach[0].visible and not chunk.neon_street[0].visible, "Forest road meets the lit urban approach")
		if chunk.index == 125:
			_check(chunk.neon_street[0].visible and chunk.neon_road[0].visible
				and not chunk.forest_banks[0].visible and not chunk.traffic.is_empty(), "Neon city uses its own street and vehicle assets")
	game._show_home()

	var recorded := RunnerSave.new()
	recorded.read_records()
	game.ui.test_requested.emit(3)
	_check(game.test_run and game.distance == 4500.0 and game.ui.score == 0 and game.slow.remaining == 0.0,
		"Stage four practice starts at full pace with a fresh timer")
	game.ready_remaining = 0.0
	game.ui.visibility_requested.emit()
	_step(1)
	_check(track.visibility_debug and track.debug_mesh.get_surface_count() == 1, "Developer visibility control draws obstacle faces")
	game.ui.visibility_requested.emit()
	_check(not track.visibility_debug and track.debug_mesh.get_surface_count() == 0, "Disabling outlines clears the debug mesh")
	var wind_material := game.motion_fx.wind_material as ShaderMaterial
	var full_tint: Color = wind_material.get_shader_parameter("tint")
	_key(KEY_H)
	_key(KEY_T)
	var pickup := track.timers.debug
	_check(pickup.meter >= game.distance + 16.0 and absf(pickup.meter - track.hearts.debug.meter) >= 2.4,
		"Forced timer and heart are placed ahead at separate positions")
	if pickup.meter < 0.0:
		game._show_home()
		return

	var at := pickup.meter
	player.lane = pickup.lane
	player.position.x = pickup.lane * Tuning.LANE
	track.timers.scroll(at, STEP)
	track.timers.check_contacts(at - 2.1, at + 2.1, player)
	_check(game.slow.remaining == Tuning.SLOW_DURATION and pickup.meter < 0.0, "Swept collection starts the six-second timer")
	player.immunity = 10.0
	var initial_distance: float = game.distance
	_step(1)
	_check(is_equal_approx((game.distance - initial_distance) / STEP, game.base_speed * 0.8)
		and Engine.time_scale == 1.0, "Slow Time reduces forward distance per frame by 20 percent")
	var slow_tint: Color = wind_material.get_shader_parameter("tint")
	_check(slow_tint.a < full_tint.a, "Neon trails are weaker while the player moves slower")
	var remaining: float = game.slow.remaining
	game._on_slow_time(Vector3.ZERO)
	_check(game.slow.remaining == remaining and is_equal_approx(game.slow.multiplier(), 0.8), "Slow Time neither refreshes nor stacks")
	_key(KEY_ESCAPE)
	_step(36)
	_check(game.slow.remaining == remaining, "Pausing preserves the timer")
	_key(KEY_ESCAPE)
	var old_lane := player.lane
	_key(KEY_D if old_lane < 1 else KEY_A)
	_step(11)
	_check(player.lane != old_lane and is_equal_approx(player.position.x, player.lane * Tuning.LANE), "Lane changes keep their timing during Slow Time")
	_key(KEY_SPACE)
	_step(5)
	_check(player.elevation > 0.4, "Jump remains responsive with Slow Time")
	_step(43)
	_key(KEY_DOWN)
	_step(12)
	_check(player.height() == MurangPlayer.CROUCH_HEIGHT, "Slide keeps its collision profile with Slow Time")

	_step(300)
	_check(game.slow.remaining == 0.0 and game.slow.recovery > 0.0
		and game.slow.recovery < Tuning.SLOW_RECOVERY, "Effect expiry begins the gradual recovery")
	var recovering_ratio: float = game.speed / game.base_speed
	game._on_slow_time(Vector3.ZERO)
	_check(game.slow.remaining == 0, "Collection during the recovery cannot restart Slow Time")
	_step(40)
	_check(game.speed / game.base_speed > recovering_ratio and game.speed < game.base_speed, "Recovery accelerates smoothly from the reduced speed")
	_step(62)
	_check(game.slow.recovery == 0.0 and is_equal_approx(game.speed, game.base_speed), "Forward motion returns to the live base curve")
	game._show_home()
	var after := RunnerSave.new()
	after.read_records()
	_check(after.best == recorded.best and after.bank == recorded.bank and after.furthest == recorded.furthest,
		"Neon practice and Slow Time do not modify regular records")


func _check_slow_schedule() -> void:
	var schedule := RunnerPickupSchedule.new(Tuning.SLOW_FIRST_METER, Tuning.SLOW_CHANCE,
		Tuning.SLOW_COOLDOWN, 0x74696D65)
	var hearts := RunnerPickupSchedule.new()
	var eligible := 0
	var spawns := 0
	for run_seed in range(100):
		schedule.reset(run_seed)
		hearts.reset(run_seed)
		_check(schedule.advance(2999.9) == -1, "Slow Time cannot spawn under 3,000 m")
		var last := -Tuning.SLOW_COOLDOWN
		for meter in range(Tuning.SLOW_FIRST_METER, 19001, Tuning.PICKUP_ROLL_STEP):
			var heart := hearts.advance(meter)
			var allowed := meter - last >= Tuning.SLOW_COOLDOWN and heart != meter
			eligible += int(allowed)
			var spawn := schedule.advance(meter, heart)
			if spawn >= 0:
				_check(spawn == meter and allowed, "Slow Time occupies an eligible marker and never shares a heart marker")
				spawns += 1
				last = meter
			_check(schedule.advance(meter, heart) == -1, "Slow Time only rolls each marker once")
	var rate := float(spawns) / eligible
	_check(absf(rate - Tuning.SLOW_CHANCE) <= 0.015, "Eligible Slow Time rolls stay close to 20 percent")
	print("Slow Time schedule: %d/%d eligible rolls (%.2f%%), 100 seeds" % [spawns, eligible, 100.0 * rate])


func _check_patterns(track: RunnerTrack) -> void:
	for seed_id in range(12):
		track.reset(seed_id)
		var last_safe := 0
		var last_row := Tuning.FIRST_ROW - Tuning.ROW_STEP
		var last_blocked := 0
		for chunk_index in range(170):
			track.scroll(chunk_index * Tuning.CHUNK_LENGTH, 0.0)
			for chunk in track.chunks:
				if chunk.index != chunk_index:
					continue
				for row in range(Tuning.ROWS_PER_CHUNK):
					var coin := chunk.coins[row * 4]
					if coin.collected:
						continue
					var row_meter := coin.meter + (7.2 if coin.meter >= Tuning.HARBOR_START - 7.2 else 8.65)
					var safe := roundi(coin.visual.position.x / Tuning.LANE)
					var blocked := 0
					for obstacle in chunk.obstacles:
						if obstacle.armed and is_equal_approx(obstacle.meter, row_meter):
							blocked += 1
							var kit := 0
							if obstacle.kind >= RunnerTrack.Kind.HOVER_CAR:
								kit = 3
							elif obstacle.kind >= RunnerTrack.Kind.LOG:
								kit = 2
							elif obstacle.kind >= RunnerTrack.Kind.BARREL:
								kit = 1
							_check(kit == Tuning.district_at(row_meter), "Uses the correct obstacle kit")
							_check(obstacle.lane != safe, "Coin guidance denotes an open lane")
					_check(blocked >= 1 and blocked <= 2, "Every occupied row leaves an open lane")
					_check(abs(safe - last_safe) <= 1, "A safe path needs no double lane change")
					var gap := row_meter - last_row
					_check(gap >= Tuning.HARBOR_ROW_STEP - 0.01 and gap <= Tuning.ROW_STEP + 0.01, "Row gaps remain bounded across chunk edges")
					_check(gap / Tuning.speed_at(row_meter) > Tuning.LANE / Tuning.LANE_SPEED + 0.13, "Reaction and lane-change budget remains at maximum speed")
					if row_meter >= Tuning.FOREST_START:
						_check(is_equal_approx(gap, Tuning.LATE_ROW_STEP), "Late obstacles keep a full 12 m gap")
						if last_row >= Tuning.FOREST_START:
							_check(blocked + last_blocked <= 3, "Complex late rows do not directly follow each other")
					last_blocked = blocked
					last_safe = safe
					last_row = row_meter
	for meter in [0.0, 1000.0, 1500.0, 2700.0, 3000.0]:
		var old_speed := sqrt(Tuning.START_SPEED * Tuning.START_SPEED + 2.0 * Tuning.ACCELERATION * meter)
		_check(is_equal_approx(Tuning.speed_at(meter), old_speed), "Early speed matches version 0.3")
	var opening := Tuning.speed_at(3000)
	var middle := Tuning.speed_at(4500)
	var late := Tuning.speed_at(6000)
	_check(absf(Tuning.speed_at(2999.99) - Tuning.speed_at(3000.01)) < 0.001, "Speed is continuous through the forest entry")
	_check(late > middle and middle > opening and late - middle < middle - opening
		and is_equal_approx(Tuning.speed_at(1000000.0), Tuning.MAX_SPEED), "Late acceleration tapers toward the cap")


func _stress(track: RunnerTrack) -> void:
	track.reset(381)
	var nodes := get_node_count()
	var started := Time.get_ticks_msec()
	var simulated_distance := 0.0
	for frame in range(60 * 60 * 12):
		simulated_distance += STEP * Tuning.speed_at(simulated_distance)
		track.scroll(simulated_distance, STEP)
	_check(get_node_count() == nodes, "Twelve simulated minutes do not increase the node count")
	_check(track.chunks.size() == Tuning.CHUNK_COUNT and track.total_reuses > 510, "Track continuously recycles its fixed-size pool")
	print("Pool endurance: %.0f m, %d reuses, %d ms CPU test" % [simulated_distance, track.total_reuses, Time.get_ticks_msec() - started])
