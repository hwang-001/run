extends SceneTree
## Run with a disposable XDG_DATA_HOME so it can exercise real persistence.

const GAME := preload("res://scenes/run.tscn")
const STEP := 1.0 / 60.0
var failures: Array[String] = []
var game: Node3D


func _initialize() -> void:
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
	game = GAME.instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	await process_frame
	var initial_bank: int = game.records.bank
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

	_check_patterns(track)
	_stress(track)
	if failures.is_empty():
		print("PASS: start, rear camera, run, keyboard and swipe, pause, jump/slide clearance, coins, damage, results, save, restart, solvable rows and pooled endurance")
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
	fixture.meter = game.distance + 1.0
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
	fixture.kind = RunnerTrack.Kind.OVERHEAD
	player.elevation = 0.0
	player.slide = 0.30
	track.check_contacts(fixture.meter - 0.1, fixture.meter, player)
	_check(fixture.armed and player.immunity == 0.0, "A slide clears the overhead barrier")
	player.slide = 0.0
	chunk.obstacles.pop_back()
	fixture.visual.free()
	track.scroll(game.distance, 0.0)


func _check_patterns(track: RunnerTrack) -> void:
	for seed_id in range(12):
		track.reset(seed_id)
		var last_safe := 0
		var last_row := Tuning.FIRST_ROW - Tuning.ROW_STEP
		for chunk_index in range(32):
			track.scroll(chunk_index * Tuning.CHUNK_LENGTH, 0.0)
			for chunk in track.chunks:
				if chunk.index != chunk_index:
					continue
				for row in range(Tuning.ROWS_PER_CHUNK):
					var coin := chunk.coins[row * 4]
					if coin.collected:
						continue
					var row_meter := coin.meter + 8.65
					var safe := roundi(coin.visual.position.x / Tuning.LANE)
					var blocked := 0
					for obstacle in chunk.obstacles:
						if obstacle.armed and is_equal_approx(obstacle.meter, row_meter):
							blocked += 1
							_check(obstacle.lane != safe, "Coin guidance denotes an open lane")
					_check(blocked >= 1 and blocked <= 2, "Every occupied row leaves an open lane")
					_check(abs(safe - last_safe) <= 1, "A safe path needs no double lane change")
					_check(is_equal_approx(row_meter - last_row, Tuning.ROW_STEP), "Row gaps remain consistent across chunk edges")
					last_safe = safe
					last_row = row_meter
	_check(Tuning.speed_at(1600) == Tuning.MAX_SPEED and Tuning.speed_at(0) == Tuning.START_SPEED, "Difficulty ramps to the speed cap")


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
