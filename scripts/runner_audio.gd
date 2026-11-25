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
	&"click": preload("res://assets/sound/click.ogg")
}

var music: AudioStreamPlayer
var harbor_music: AudioStreamPlayer
var surf: AudioStreamPlayer
var coastal_mix := 0.0
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
var muted := false


func _ready() -> void:
	music = _loop(preload("res://assets/sound/murang-park.ogg"))
	harbor_music = _loop(preload("res://assets/sound/murang-harbor.ogg"))
	surf = _loop(preload("res://assets/sound/harbor-surf.ogg"))
	_update_mix()
	for i in range(7):
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
	if DisplayServer.get_name() == "headless" or music.playing:
		return
	for channel in [music, harbor_music, surf]:
		channel.play()


func set_coast(blend: float) -> void:
	if is_equal_approx(coastal_mix, blend):
		return
	coastal_mix = blend
	_update_mix()


func _update_mix() -> void:
	var gain := 0.0 if muted else 1.0
	music.volume_db = linear_to_db(maxf(0.0001, gain * 0.20 * sqrt(1.0 - coastal_mix)))
	harbor_music.volume_db = linear_to_db(maxf(0.0001, gain * 0.20 * sqrt(coastal_mix)))
	surf.volume_db = linear_to_db(maxf(0.0001, gain * 0.33 * coastal_mix))


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
