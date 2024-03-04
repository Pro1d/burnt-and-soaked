extends StaticBody2D

@onready var _body := $Sprite2D as Sprite2D
@onready var _shadow := $Sprite2D/ShadowSprite3D as Sprite2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(get_path())
	var _high := (collision_layer & 2) != 0
	var v := 0.75 if _high else 1.0
	var s := 0.0 if _high else 0.1
	_body.modulate = Color.from_hsv(rng.randf(), s, v)
	_body.z_index = 10 if _high else 5
	_shadow.modulate.a = 0.4
	_shadow.z_index = 1
	_shadow.z_as_relative = false
	_shadow.offset = Vector2.ZERO
	
	var random_rotate := 0
	for c in get_children():
		var cs := c as CollisionShape2D
		if cs == null:
			continue
		if random_rotate != 0:
			random_rotate = 0
			break
		random_rotate = -1
		if cs.shape is CircleShape2D:
			random_rotate = 1
		elif cs.shape is RectangleShape2D:
			var rs := cs.shape as RectangleShape2D
			if rs.size.x == rs.size.y:
				random_rotate = 2
				
	match random_rotate:
		1:
			rotation_degrees = rng.randf_range(0, 360)
		2:
			rotation_degrees = 90 * rng.randi_range(0, 3)

	_shadow.global_position = _body.global_position + Vector2(3.5, 2.5)
