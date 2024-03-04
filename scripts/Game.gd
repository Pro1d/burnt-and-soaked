extends Node2D

enum State {STARTING_LEVEL, DRIVING, LEVEL_FAILING, LEVEL_FINISHING, FINISHED}
enum StateUI {MENU, SCORE_SCREEN, PLAYING, LEADERBOARD, NONE}

@onready var _score_screen := %ScoreScreen as ScoreScreen
@onready var _main_menu := %MainMenu as MainMenu
@onready var _hud := %Hud as HUD
@onready var _root := %Root as Node2D
@onready var _player := %Truck as Truck
@onready var _map := %Map as Map
@onready var _camera := %Camera2D as Camera2D
var _current_level : Map.Level
var _current_level_index := 0
var _state := State.FINISHED
var _state_ui := StateUI.MENU

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_player.collided.connect(_on_player_collided)
	_camera.limit_top = _map.top
	_camera.limit_bottom = _map.bottom
	_camera.limit_left = _map.left
	_camera.limit_right = _map.right
	
	for level in _map.levels:
		level.target_area.body_entered.connect(func(_b): _on_play_enter_target_area())
	
	_update_ui()
	_main_menu.play_pressed.connect(_start_game)
	_main_menu.leaderboard_pressed.connect(func():_update_ui(StateUI.LEADERBOARD))
	_score_screen.leave_animation_finished.connect(func():_update_ui(StateUI.MENU))
	_hud.menu_pressed.connect(func():
		_state = State.FINISHED
		_update_ui(StateUI.MENU)
	)
	_hud.restart_pressed.connect(func():
		if _state != State.STARTING_LEVEL:
			_end_level(false)
	)


func _start_game() -> void:
	_state_ui = StateUI.PLAYING
	Config.timer = 0.0
	_update_ui()
	_player.set_water_supply(100)
	_hud.set_water_supply(_player.get_water_supply(), false)
	_start_level(0)

func _start_level(level_index: int) -> void:
	_current_level_index = level_index
	_current_level = _map.select_level(_current_level_index)
	_hud.set_level(_current_level_index + 1, _map.levels.size())
	_player.start_loading(_current_level.start_position, _current_level.target_area)
	_state = State.STARTING_LEVEL
	
	printerr("TODO implement loading")
	_player.set_water_supply(0)
	_hud.set_water_supply(_player.get_water_supply(), false)
	await get_tree().create_timer(0.8).timeout
	if _state != State.STARTING_LEVEL:
		return
	
	_player.set_water_supply(40)
	_hud.set_water_supply(_player.get_water_supply(), true)
	_player.shake()
	await get_tree().create_timer(0.8).timeout
	if _state != State.STARTING_LEVEL:
		return
		
	_player.set_water_supply(80)
	_hud.set_water_supply(_player.get_water_supply(), true)
	_player.shake()
	await get_tree().create_timer(0.8).timeout
	if _state != State.STARTING_LEVEL:
		return
	
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
	_state_ui = StateUI.SCORE_SCREEN
	_score_screen.set_time(Config.timer)
	_update_ui()

func _physics_process(delta: float) -> void:
	match _state:
		State.STARTING_LEVEL, State.DRIVING, State.LEVEL_FAILING, State.LEVEL_FINISHING:
			Config.timer += delta

func _on_player_collided(strong: bool) -> void:
	if _state != State.DRIVING:
		return
	if _player.try_take_damage():
		var pos := _player.global_position 
		var p := Puddle.make_puddle(3 if strong else 2)
		p.global_position = pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		_root.add_child(p)
		var ws := _player.add_water_supply(-10 if strong else -25)
		_hud.set_water_supply(ws, true)
		_player.shake()
		
		if not _player.has_water_supply():
			_state = State.LEVEL_FAILING
			_player.emergency_stop()
			await get_tree().create_timer(1.0).timeout
			if _state == State.LEVEL_FAILING:
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
		await get_tree().create_timer(1.0).timeout
		
		if _state == State.LEVEL_FINISHING:
			_end_level(true)

func _update_ui(s: StateUI = StateUI.NONE) -> void:
	if s != StateUI.NONE:
		_state_ui = s
	_main_menu.visible = _state_ui == StateUI.MENU
	_score_screen.visible = _state_ui == StateUI.SCORE_SCREEN or _state_ui == StateUI.LEADERBOARD
	_score_screen.show_leaderboard_only(_state_ui == StateUI.LEADERBOARD)
	_hud.visible = _state_ui == StateUI.PLAYING
