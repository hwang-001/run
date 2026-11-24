class_name Tuning
extends RefCounted

const LANE := 2.30
const START_SPEED := 8.5
const MAX_SPEED := 22.0
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
const ROWS_PER_CHUNK := 3

static func speed_at(distance: float) -> float:
	# v² = v₀² + 2 a s. Rows can evaluate the expected arrival speed in advance.
	return minf(MAX_SPEED, sqrt(START_SPEED * START_SPEED + 2.0 * ACCELERATION * distance))


static func points(distance: float, coins: int) -> int:
	return int(distance * 2.0) + coins * 25
