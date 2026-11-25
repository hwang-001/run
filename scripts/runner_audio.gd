class_name RunnerAudio
extends Node

const SOUNDS := {
	&"coin": preload("res://assets/sound/coin.ogg"),
	&"coin_accent": preload("res://assets/sound/coin-accent.ogg"),
	&"step": preload("res://assets/sound/walking.ogg"),
	&"jump": preload("res://assets/sound/jump.ogg"),
	&"land": preload("res://assets/sound/land.ogg"),
	&"hit": preload("res://assets/sound/hit.ogg"),
	&"over": preload("res://assets/sound/fall.ogg"),
	&"click": preload("res://assets/sound/click.ogg"),
	&"slide": preload("res://assets/sound/slide-grit.ogg"),
	&"health": preload("res://assets/sound/heart-chime.ogg"),
}

var music: AudioStreamPlayer
var harbor_music: AudioStreamPlayer
var forest_music: AudioStreamPlayer
var surf: AudioStreamPlayer
var forest_air: AudioStreamPlayer
var wind: AudioStreamPlayer
var weights := Vector3(1, 0, 0)
var wind_power := 0.0
var music_started := false
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
var muted := false


func _ready() -> void:
	music = _loop(preload("res://assets/sound/murang-park.ogg"))
	harbor_music = _loop(preload("res://assets/sound/murang-harbor.ogg"))
	forest_music = _loop(preload("res://assets/sound/murang-forest.ogg"))
	surf = _loop(preload("res://assets/sound/harbor-surf.ogg"))
	forest_air = _loop(preload("res://assets/sound/forest-air.ogg"))
	wind = _loop(preload("res://assets/sound/speed-wind.ogg"))
	_update_mix()
	for index in range(7):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)


func _loop(stream: AudioStreamOggVorbis) -> AudioStreamPlayer:
	var channel := AudioStreamPlayer.new()
	stream.loop = true
	channel.stream = stream
	add_child(channel)
	return channel


func start_music() -> void:
	if DisplayServer.get_name() == "headless" or music_started:
		return
	music_started = true
	_update_mix()


func set_scenery(mix: Vector3) -> void:
	if weights.is_equal_approx(mix):
		return
	weights = mix
	_update_mix()


func set_wind(power: float) -> void:
	if is_equal_approx(wind_power, power):
		return
	wind_power = power
	wind.pitch_scale = lerpf(0.77, 1.23, power)
	_channel(wind, 0.45 * pow(power, 1.6))


func _channel(channel: AudioStreamPlayer, linear_gain: float) -> void:
	channel.volume_db = linear_to_db(maxf(0.0001, 0.0 if muted else linear_gain))
	if not music_started:
		return
	if linear_gain > 0.003 and not channel.playing:
		channel.play()
	elif linear_gain <= 0.003 and channel.playing:
		channel.stop()


func _update_mix() -> void:
	_channel(music, 0.20 * sqrt(weights.x))
	_channel(harbor_music, 0.20 * sqrt(weights.y))
	_channel(forest_music, 0.20 * sqrt(weights.z))
	_channel(surf, 0.33 * weights.y)
	_channel(forest_air, 0.35 * weights.z)
	_channel(wind, 0.45 * pow(wind_power, 1.6))


func play_sound(sound: StringName, volume := -8.0, pitch := 1.0) -> void:
	if muted:
		return
	var voice := voices[voice_index]
	voice_index = (voice_index + 1) % voices.size()
	voice.stream = SOUNDS[sound]
	voice.volume_db = volume
	voice.pitch_scale = pitch
	voice.play()


func set_muted(value: bool) -> void:
	muted = value
	_update_mix()
	if muted:
		for voice in voices:
			voice.stop()
