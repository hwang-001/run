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
	_key(KEY_DOWN)
	_step(3)
	_check(player.height() == MurangPlayer.CROUCH_HEIGHT, "Down key crouches")
	_step(45)
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
	_step(5)
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
	_check_patterns(track)
	_stress(track)
	if failures.is_empty():
		print("PASS: start, rear camera, run, keyboard and swipe, pause, jump/slide clearance, coins, damage, results, save, restart, solvable rows, seamless 1,500 m boundary, isolated test starts and pooled endurance")
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
	track.check_contacts(fixture.meter - 0.1, fixture.meter, player)
	_check(fixture.armed and player.immunity == 0.0, "A slide clears the overhead barrier")
	player.slide = 0.0
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
	game.ui.test_requested.emit()
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


func _check_patterns(track: RunnerTrack) -> void:
	for seed_id in range(12):
		track.reset(seed_id)
		var last_safe := 0
		var last_row := Tuning.FIRST_ROW - Tuning.ROW_STEP
		for chunk_index in range(67):
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
							var from_harbor := obstacle.kind >= RunnerTrack.Kind.BARREL
							_check(from_harbor == (row_meter >= Tuning.HARBOR_START), "Uses the correct obstacle kit")
							_check(obstacle.lane != safe, "Coin guidance denotes an open lane")
					_check(blocked >= 1 and blocked <= 2, "Every occupied row leaves an open lane")
					_check(abs(safe - last_safe) <= 1, "A safe path needs no double lane change")
					var gap := row_meter - last_row
					_check(gap >= Tuning.HARBOR_ROW_STEP - 0.01 and gap <= Tuning.ROW_STEP + 0.01, "Row gaps remain bounded across chunk edges")
					_check(gap / Tuning.speed_at(row_meter) > Tuning.LANE / Tuning.LANE_SPEED + 0.13, "Reaction and lane-change budget remains at maximum speed")
					last_safe = safe
					last_row = row_meter
	_check(Tuning.speed_at(3500) == Tuning.MAX_SPEED and Tuning.speed_at(1501) < Tuning.speed_at(2700) and Tuning.speed_at(0) == Tuning.START_SPEED, "Difficulty ramps to the speed cap")


func _stress(track: RunnerTrack) -> void:
	track.reset(381)
	var nodes := get_node_count()
	var started := Time.get_ticks_msec()
	var simulated_distance := 0.0
	for frame in range(60 * 60 * 12):
		simulated_distance += STEP * Tuning.speed_at(simulated_distance)
		track.scroll(simulated_distance, STEP)
	_check(get_node_count() == nodes, "Twelve simulated minutes do not increase the node count")
	_check(track.chunks.size() == Tuning.CHUNK_COUNT and track.total_reuses > 400, "Track continuously recycles its fixed-size pool")
	print("Pool endurance: %.0f m, %d reuses, %d ms CPU test" % [simulated_distance, track.total_reuses, Time.get_ticks_msec() - started])
