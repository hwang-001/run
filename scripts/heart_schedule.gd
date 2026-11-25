class_name RunnerHeartSchedule
extends RefCounted
## A seeded roll per absolute course marker. Replays and test starts share the same history.

var rng := RandomNumberGenerator.new()
var next_meter := Tuning.HEART_FIRST_METER
var last_meter := -Tuning.HEART_COOLDOWN


func reset(seed_id: int, skip_through: float) -> void:
	rng.seed = seed_id ^ 0x6D757261
	next_meter = Tuning.HEART_FIRST_METER
	last_meter = -Tuning.HEART_COOLDOWN
	advance(skip_through)


func advance(through_meter: float) -> int:
	var spawn := -1
	while next_meter <= through_meter:
		var roll := rng.randf()
		if next_meter - last_meter >= Tuning.HEART_COOLDOWN and roll < Tuning.HEART_CHANCE:
			last_meter = next_meter
			spawn = next_meter
		next_meter += Tuning.HEART_ROLL_STEP
	return spawn
