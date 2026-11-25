class_name Tuning
extends RefCounted

const LANE := 2.30
const START_SPEED := 8.5
const MAX_SPEED := 28.0
const ACCELERATION := 0.13
const LANE_SPEED := 16.0
const JUMP_VELOCITY := 8.4
const GRAVITY := 23.0
const SLIDE_TIME := 0.66
const HIT_GRACE := 1.2
const CHUNK_LENGTH := 36.0
const CHUNK_COUNT := 7
const ROW_STEP := 12.0
const FIRST_ROW := 16.0
const ROWS_PER_CHUNK := 4
const HARBOR_START := 1500.0
const HARBOR_APPROACH := 1476.0
const HARBOR_ROW_STEP := 9.0
const DOUBLE_ROW_START := 100.0
const DOUBLE_ROW_RAMP := 3000.0
const ENABLE_DISTRICT_TEST := true
const TEST_DISTRICT := 1
const DISTRICTS := [
	{"name": "시티 파크", "start": 0.0},
	{"name": "산호빛 항구", "start": HARBOR_START},
]


static func district_at(distance: float) -> int:
	for district in range(DISTRICTS.size() - 1, 0, -1):
		if distance >= float(DISTRICTS[district].start):
			return district
	return 0


static func coast_mix_at(distance: float) -> float:
	return smoothstep(HARBOR_APPROACH - 13.0, HARBOR_START, distance)


static func speed_at(distance: float) -> float:
	# v² = v₀² + 2 a s. Both start modes use this same course curve.
	return minf(MAX_SPEED, sqrt(START_SPEED * START_SPEED + 2.0 * ACCELERATION * distance))


static func double_row_chance_at(distance: float) -> float:
	return minf(0.97, 0.07 + maxf(0.0, distance - DOUBLE_ROW_START) / DOUBLE_ROW_RAMP)


static func points(distance: float, coins: int) -> int:
	return int(distance * 2.0) + coins * 25
