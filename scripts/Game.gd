extends Node2D

enum State {STARTING_LEVEL, DRIVING, LEVEL_FAILING, LEVEL_FINISHING, FINISHED}

@onready var _hud := %Hud as HUD
@onready var _root := %Root as Node2D
@onready var _player := %Truck as Truck
@onready var _map := %Map as Map
@onready var _camera := %Camera2D as Camera2D
var _recently_collided := false
var _current_level : Map.Level
var _current_level_index := 0
var _state := State.STARTING_LEVEL

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player.collided.connect(_on_player_collided)
	_camera.limit_top = _map.top
	_camera.limit_bottom = _map.bottom
	_camera.limit_left = _map.left
	_camera.limit_right = _map.right
	
	for level in _map.levels:
		level.target_area.body_entered.connect(func(_b): _on_play_enter_target_area())
	
	_start_game()

func _start_game() -> void:
	Config.timer = 0.0
	_player.set_water_supply(100)
	_hud.set_water_supply(_player.get_water_supply(), false)
	_start_level(0)

func _start_level(level_index: int) -> void:
	_current_level_index = level_index
	_current_level = _map.select_level(_current_level_index)
	_player.start_loading(_current_level.start_position, _current_level.target_area)
	_state = State.STARTING_LEVEL
	
	printerr("TODO implement loading")
	_player.set_water_supply(0)
	_hud.set_water_supply(_player.get_water_supply(), false)
	_player.shake()
	await get_tree().create_timer(1.0).timeout
	_player.set_water_supply(50)
	_hud.set_water_supply(_player.get_water_supply(), true)
	_player.shake()
	await get_tree().create_timer(1.0).timeout
	_player.set_water_supply(100)
	_hud.set_water_supply(_player.get_water_supply(), true)
	_player.shake()
	_state = State.DRIVING
	_player.start_driving()

func _end_level(victory: bool) -> void:
	if victory:
		if _current_level_index + 1 >= _map.levels.size():
			_end_game()
		else:
			_start_level(_current_level_index + 1)
	else:
		_start_level(_current_level_index)

func _end_game() -> void:
	_state = State.FINISHED
	printerr("EndGame, time=", Config.timer)

func _process(_delta: float) -> void:
	# Arrow: target direction
	pass

func _physics_process(delta: float) -> void:
	match _state:
		State.FINISHED:
			pass
		_:
			Config.timer += delta

func invicibility_timer() ->  void:
	_recently_collided = true
	await get_tree().create_timer(0.5).timeout
	_recently_collided = false

func _on_player_collided(strong: bool) -> void:
	if not _recently_collided and _state == State.DRIVING:
		var pos := _player.global_position 
		var p := Puddle.make_puddle(3 if strong else 2)
		p.global_position = pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		_root.add_child(p)
		var ws := _player.add_water_supply(-10 if strong else -25)
		_hud.set_water_supply(ws, true)
		_player.shake()
		invicibility_timer()
		
		if not _player.has_water_supply():
			_state = State.LEVEL_FAILING
			_player.emergency_stop()
			await get_tree().create_timer(1.0).timeout
			_end_level(false)

func _on_play_enter_target_area() -> void:
	if _player.has_water_supply() and _state == State.DRIVING:
		_state = State.LEVEL_FINISHING
		var p := Vector2.ZERO
		for f in _current_level.fires:
			p += f.global_position
		p /= _current_level.fires.size()
		_player.catapult_water(p)
		for f in _current_level.fires:
			f.extinguish()
		# Wait fire to extinguish
		for f in _current_level.fires:
			if not f.is_extinguished():
				await f.extinguished
		await get_tree().create_timer(2.0).timeout
		_end_level(true)
