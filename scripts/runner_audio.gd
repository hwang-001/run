class_name RunnerAudio
extends Node

const SOUNDS := {
	&"coin": preload("res://assets/sound/coin.ogg"),
	&"step": preload("res://assets/sound/walking.ogg"),
	&"jump": preload("res://assets/sound/jump.ogg"),
	&"land": preload("res://assets/sound/land.ogg"),
	&"hit": preload("res://assets/sound/hit.ogg"),
	&"over": preload("res://assets/sound/fall.ogg"),
	&"click": preload("res://assets/sound/click.ogg")
}

var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
var muted := false


func _ready() -> void:
	music = AudioStreamPlayer.new()
	music.stream = preload("res://assets/sound/murang-park.ogg")
	(music.stream as AudioStreamOggVorbis).loop = true
	music.volume_db = -14.0
	add_child(music)
	for i in range(7):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)


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
	music.volume_db = -80.0 if muted else -14.0
	if muted:
		for voice in voices:
			voice.stop()
