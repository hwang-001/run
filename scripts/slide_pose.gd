class_name RunnerSlidePose
extends Node
## The clip samples local joint poses. MurangPlayer blends them over the current gait.

var weight := 0.0
var torso := Vector3.ZERO
var hips := Vector4.ZERO
var reach := Vector2.ZERO
var animation: AnimationPlayer


func _ready() -> void:
	animation = AnimationPlayer.new()
	animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(animation)
	var clip := Animation.new()
	clip.length = Tuning.SLIDE_TIME
	var times := [0.0, 0.063, 0.145, 0.32, 0.52, 0.615, Tuning.SLIDE_TIME]
	_keys(clip, "weight", times, [0.0, 0.57, 1.0, 1.0, 1.0, 0.58, 0.0])
	_keys(clip, "torso", times, [
		Vector3(0.70, 0.0, 0.0), Vector3(0.47, 0.23, -0.13),
		Vector3(0.36, 1.17, -0.47), Vector3(0.355, 1.23, -0.47),
		Vector3(0.355, 1.24, -0.43), Vector3(0.42, 0.64, -0.28),
		Vector3(0.70, 0.0, 0.0)])
	_keys(clip, "hips", times, [
		Vector4.ZERO, Vector4(0.70, 0.44, -1.36, -1.20),
		Vector4(0.39, 0.20, -0.26, -0.55), Vector4(0.33, 0.24, -0.22, -0.49),
		Vector4(0.26, 0.20, -0.26, -0.44), Vector4(0.32, 0.10, -0.65, -0.88),
		Vector4.ZERO])
	_keys(clip, "reach", times, [
		Vector2.ZERO, Vector2(-0.31, -0.16), Vector2(-0.88, -0.51),
		Vector2(-0.83, -0.60), Vector2(-0.78, -0.51), Vector2(-0.36, -0.33), Vector2.ZERO])
	var library := AnimationLibrary.new()
	library.add_animation(&"slide", clip)
	animation.add_animation_library(&"", library)


func _keys(clip: Animation, property: String, times: Array, values: Array) -> void:
	var track := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath(".:" + property))
	for i in range(times.size()):
		clip.track_insert_key(track, times[i], values[i])


func begin() -> void:
	animation.stop()
	animation.play(&"slide")
	animation.advance(0.0)


func clear() -> void:
	animation.stop()
	weight = 0.0
