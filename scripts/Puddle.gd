class_name Puddle
extends Sprite2D

const PuddleResource := preload("res://scenes/Puddle.tscn")
const _textures : Array[Texture2D] = [
	null,
	preload("res://resources/textures/flat/puddle1.atlastex"),
	preload("res://resources/textures/flat/puddle2.atlastex"),
	preload("res://resources/textures/flat/puddle3.atlastex"),
	preload("res://resources/textures/flat/puddle4.atlastex"),
	preload("res://resources/textures/flat/puddle5.atlastex"),
	preload("res://resources/textures/flat/puddle6.atlastex"),
	preload("res://resources/textures/flat/puddle7.atlastex"),
	preload("res://resources/textures/flat/puddle8.atlastex"),
	preload("res://resources/textures/flat/puddle9.atlastex"),
	preload("res://resources/textures/flat/water_particle.atlastex"),
]

static func make_puddle(size: int) -> Puddle:
	var p := PuddleResource.instantiate() as Puddle
	p.rotation = randf_range(0, 2 * PI)
	p.scale = Vector2.ONE * randf_range(0.9, 1.0)
	match size:
		0:
			p.texture = _textures[10]
		1:
			p.texture = _textures[randi_range(8, 9)]
		2:
			p.texture = _textures[randi_range(5, 7)]
		3:
			p.texture = _textures[randi_range(3, 4)]
		4:
			p.texture = _textures[randi_range(1, 2)]
		_:
			printerr("Bad puddle size ", size)
	return p
