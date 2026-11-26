class_name Tuning
extends RefCounted

const LANE := 2.30
const START_SPEED := 8.5
const MAX_SPEED := 30.6
const LATE_SPEED_RAMP := 1500.0
const ACCELERATION := 0.13
const LANE_SPEED := 16.0
const JUMP_VELOCITY := 8.4
const GRAVITY := 23.0
const SLIDE_TIME := 0.72
const HIT_GRACE := 1.2
const CHUNK_LENGTH := 36.0
const CHUNK_COUNT := 7
const ROW_STEP := 12.0
const FIRST_ROW := 16.0
const ROWS_PER_CHUNK := 4
const HARBOR_START := 1500.0
const HARBOR_APPROACH := 1476.0
const HARBOR_ROW_STEP := 9.0
const LATE_ROW_STEP := 12.0
const DOUBLE_ROW_START := 100.0
const DOUBLE_ROW_RAMP := 3000.0
const ENABLE_DISTRICT_TEST := true
const FOREST_START := 3000.0
const FOREST_APPROACH := 2964.0
const FOREST_GREENBELT := FOREST_APPROACH - 24.0
const NEON_START := 4500.0
const NEON_APPROACH := NEON_START - 60.0
const NEON_ASPHALT := NEON_START - 24.0
const HEART_FIRST_METER := 500
const PICKUP_ROLL_STEP := 100
const HEART_CHANCE := 0.10
const HEART_COOLDOWN := 800
const PICKUP_LOOKAHEAD := 94.0
const SLOW_FIRST_METER := 3000
const SLOW_CHANCE := 0.20
const SLOW_COOLDOWN := 300
const SLOW_REDUCTION := 0.20
const SLOW_DURATION := 6.0
const SLOW_RECOVERY := 1.5
const MAX_HEALTH := 3
const SPEED_TIERS := [8.5, 14.0, 21.6, 27.0, MAX_SPEED]
const SPEED_FOV_GAIN := 11.0
const TRAIL_THRESHOLD := 0.53
const WIND_LIMIT := 24
const SPEED_FX_SCALE := 1.0
const DISTRICTS := [
	{"name": "시티 파크", "start": 0.0},
	{"name": "산호빛 항구", "start": HARBOR_START},
	{"name": "솔바람 계곡", "start": FOREST_START},
	{"name": "네온 시티", "start": NEON_START},
]


static func district_at(distance: float) -> int:
	for district in range(DISTRICTS.size() - 1, 0, -1):
		if distance >= float(DISTRICTS[district].start):
			return district
	return 0


static func scenery_weights(distance: float) -> Vector4:
	var coast := smoothstep(HARBOR_APPROACH - 13.0, HARBOR_START, distance)
	var forest := smoothstep(FOREST_APPROACH - 10.0, FOREST_START, distance)
	var neon := smoothstep(NEON_APPROACH - 25.0, NEON_START, distance)
	return Vector4(1.0 - coast, coast - forest, forest - neon, neon)


static func speed_effect(speed: float) -> float:
	for i in range(1, SPEED_TIERS.size()):
		if speed <= float(SPEED_TIERS[i]):
			var spread := inverse_lerp(float(SPEED_TIERS[i - 1]), float(SPEED_TIERS[i]), speed)
			return clampf((i - 1 + spread) * 0.25, 0.0, 1.0) * SPEED_FX_SCALE
	return SPEED_FX_SCALE


static func speed_at(distance: float) -> float:
	# v² = v₀² + 2 a s. Both start modes use this same course curve.
	var early_speed := sqrt(START_SPEED * START_SPEED + 2.0 * ACCELERATION * minf(distance, FOREST_START))
	if distance <= FOREST_START:
		return early_speed
	var late_distance := distance - FOREST_START
	return lerpf(early_speed, MAX_SPEED, 1.0 - exp(-late_distance / LATE_SPEED_RAMP))


static func double_row_chance_at(distance: float) -> float:
	if distance < FOREST_START:
		return minf(0.97, 0.07 + maxf(0.0, distance - DOUBLE_ROW_START) / DOUBLE_ROW_RAMP)
	return lerpf(0.55, 0.86, 1.0 - exp(-(distance - FOREST_START) / 1800.0))


static func points(distance: float, coins: int) -> int:
	return int(distance * 2.0) + coins * 25
