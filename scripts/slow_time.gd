class_name RunnerSlowTime
extends RefCounted
## Only the run's forward velocity is scaled. Physics, input and UI keep their normal clocks.

var remaining := 0.0
var recovery := 0.0


func reset() -> void:
	remaining = 0.0
	recovery = 0.0


func activate() -> bool:
	if remaining > 0.0 or recovery > 0.0:
		return false
	remaining = Tuning.SLOW_DURATION
	return true


func advance(dt: float) -> void:
	if remaining > 0.0:
		var active_step := minf(dt, remaining)
		remaining = maxf(0.0, remaining - active_step)
		if remaining > 0.0:
			return
		dt -= active_step
		recovery = Tuning.SLOW_RECOVERY
	recovery = maxf(0.0, recovery - dt)


func multiplier() -> float:
	if remaining > 0.0:
		return 1.0 - Tuning.SLOW_REDUCTION
	if recovery > 0.0:
		var restored := smoothstep(0.0, 1.0, 1.0 - recovery / Tuning.SLOW_RECOVERY)
		return 1.0 - Tuning.SLOW_REDUCTION * (1.0 - restored)
	return 1.0
