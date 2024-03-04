class_name Fire
extends Node2D

signal extinguished()

const estimated_extinguish_duration := 1.5  # audio is the longest

@onready var _smoke := %SmokeCPUParticles2D as CPUParticles2D
@onready var _flame := %FlameCPUParticles2D as CPUParticles2D
@onready var default_smoke_scales : Array[float] = [_smoke.scale_amount_min, _smoke.scale_amount_max]

var _is_extinguished := false

func _ready() -> void:
	stop()
	#_smoke.finished.connect(func(): extinguished.emit())
	
func light() -> void:
	_smoke.emitting = true
	_flame.emitting = true
	_smoke.color = Color(0.239, 0.239, 0.239)
	_smoke.scale_amount_min = default_smoke_scales[0]
	_smoke.scale_amount_max = default_smoke_scales[1]
	_is_extinguished = false
	(%BurningAudio as RandomSoundPlayer).play_random()

func extinguish() -> void:
	_flame.emitting = false
	_smoke.color = Color.WHITE
	_smoke.scale_amount_min = default_smoke_scales[0]
	_smoke.scale_amount_max = default_smoke_scales[1] * 1.2
	_smoke.one_shot = true
	(%ExtinguishAudio as RandomSoundPlayer).play_random(6.0)
	(%BurningAudio as RandomSoundPlayer).stop()
	
	await _smoke.finished
	_is_extinguished = true
	extinguished.emit()

func stop() -> void:
	_smoke.emitting = false
	_flame.emitting = false
	_is_extinguished = true

func is_extinguished() -> bool:
	return _is_extinguished
