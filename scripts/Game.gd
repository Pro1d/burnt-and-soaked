extends Node2D

@onready var _root := %Root as Node2D
@onready var _player := %Truck as Truck
@onready var _map := %Map as Map
@onready var _camera := %Camera2D as Camera2D
var _recently_collided := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player.collided.connect(_on_player_collided)
	_camera.limit_top = _map.top
	_camera.limit_bottom = _map.bottom
	_camera.limit_left = _map.left
	_camera.limit_right = _map.right

func _on_player_collided(strength: int) -> void:
	if not _recently_collided:
		var pos := _player.global_position 
		var p := Puddle.make_puddle(strength)
		p.global_position = pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		_root.add_child(p)
		_recently_collided = true
		await get_tree().create_timer(0.5).timeout
		_recently_collided = false
