class_name RandomSoundPlayer
extends AudioStreamPlayer2D

@export var streams : Array[AudioStream] = []
@onready var default_volume := volume_db
var prev_sound_index := -1

func play_random(random_half_tone_variation: float = 0.0, volume: float = 0.0) -> void:
	var i := randi_range(0, streams.size() - 1)
	if i == prev_sound_index:
		i = randi_range(0, streams.size() - 1)
	prev_sound_index = i
	stream = streams[i]
	pitch_scale = pow(2.0, randf_range(-random_half_tone_variation, random_half_tone_variation) / 12.0)
	volume_db = default_volume + volume
	play()

