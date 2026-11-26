class_name RunnerPickupSchedule
extends RefCounted
## A seeded roll per absolute course marker. A reserved marker still consumes its RNG roll.

var rng := RandomNumberGenerator.new()
var first_meter: int
var chance: float
var cooldown: int
var salt: int
var next_meter: int
var last_meter: int


func _init(first := Tuning.HEART_FIRST_METER, probability := Tuning.HEART_CHANCE,
		gap := Tuning.HEART_COOLDOWN, seed_salt := 0x6D757261) -> void:
	first_meter = first
	chance = probability
	cooldown = gap
	salt = seed_salt
	next_meter = first
	last_meter = -gap


func reset(seed_id: int, skip_through := 0.0) -> void:
	rng.seed = seed_id ^ salt
	next_meter = first_meter
	last_meter = -cooldown
	advance(skip_through)


func advance(through_meter: float, reserved_meter := -1) -> int:
	var spawn := -1
	while next_meter <= through_meter:
		var roll := rng.randf()
		if next_meter != reserved_meter and next_meter - last_meter >= cooldown and roll < chance:
			last_meter = next_meter
			spawn = next_meter
		next_meter += Tuning.PICKUP_ROLL_STEP
	return spawn
