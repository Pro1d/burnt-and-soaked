extends StaticBody2D

@onready var _body := $Sprite2D as Sprite2D
@onready var _shadow := $Sprite2D/ShadowSprite3D as Sprite2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(get_path())
	var _high := (collision_layer & 2) != 0
	var v := 0.8 if _high else 1.0
	var s := 0.07 if _high else 0.1
	_body.modulate = Color.from_hsv(rng.randf(), s, v)
	_body.z_index = 10 if _high else 5
	_shadow.modulate.a = 0.25
	_shadow.z_index = 1
	_shadow.z_as_relative = false

func _process(_delta: float) -> void:
	_shadow.global_position = _body.global_position + Vector2(3, 2)
