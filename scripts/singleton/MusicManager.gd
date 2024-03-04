extends Node

enum Volume { MUTE=0, LOW=1, HIGH=2 }

signal volume_changed()

#const menu_music := preload("res://assets/musics/last-stand-in-space.ogg")
const game_music := preload("res://assets/musics/one_0.ogg")

var _default_vol := Volume.HIGH
var _vol := Volume.HIGH
@onready var _player := AudioStreamPlayer.new()
@onready var _music_bus := AudioServer.get_bus_index(&"Music")
@onready var _default_volume_db := AudioServer.get_bus_volume_db(_music_bus)

func _ready() -> void:
	_player.bus = &"Music"
	set_volume(_vol)
	add_child(_player)
	MusicManager.start_game_music()

func toggle_mute() -> void:
	if is_mute():
		set_volume(_default_vol)
	else:
		set_volume(Volume.MUTE)

func is_mute() -> bool:
	return _vol == Volume.MUTE

func set_volume(level: Volume) -> void: # range 0 (mute) - 2 (max)
	_vol = level
	volume_changed.emit()
	if level != Volume.MUTE:
		_default_vol = level
	AudioServer.set_bus_mute(_music_bus, level == Volume.MUTE)
	match level:
		Volume.HIGH:
			AudioServer.set_bus_volume_db(_music_bus, _default_volume_db)
		Volume.LOW:
			AudioServer.set_bus_volume_db(_music_bus, _default_volume_db - 9.0)

func start_menu_music():
	#_player.stream = menu_music
	_player.play()

func start_game_music():
	_player.stream = game_music
	_player.play()

func stop_music():
	_player.stop()

const MusicOnIcon := preload("res://resources/textures/ui/music.atlastex")
const MusicOffIcon := preload("res://resources/textures/ui/music_off.atlastex")

func update_button_icon(button: Button) -> void:
	print(is_mute())
	button.icon = MusicOffIcon if is_mute() else MusicOnIcon

func connect_music_button(button: Button) -> void:
	update_button_icon(button) # init
	volume_changed.connect(func(): update_button_icon(button))
	button.pressed.connect(toggle_mute)
