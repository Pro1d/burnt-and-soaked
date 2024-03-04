class_name HUD
extends Control

signal menu_pressed()
signal restart_pressed()

@onready var time_display := %TimeDisplay as TimeDisplay
@onready var water_supply := %TextureProgressBar as TextureProgressBar
var effective_water_supply := 0
var water_supply_tween : Tween
var low_water_supply_tween : Tween

func _ready() -> void:
	time_display.get_time_func = (func() -> float: return Config.timer)
	water_supply.pivot_offset = water_supply.size / 2
	(%MenuButton as Button).pressed.connect(func(): menu_pressed.emit())
	(%RetryButton as Button).pressed.connect(func(): restart_pressed.emit())
	MusicManager.connect_music_button(%MusicButton as Button)
	
	# Low water supply animation
	var tween := create_tween()
	tween.tween_interval(2.0)
	var from := 0
	var to := -40
	tween.tween_property(water_supply, "position:y", to, 0.15).from(from) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(water_supply, "position:y", from, 0.7).from(to) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.stop()
	tween.set_loops()
	low_water_supply_tween = tween

func set_water_supply(w: int, animate: bool = true) -> void:
	effective_water_supply = w
	
	if w <= 30 and not low_water_supply_tween.is_running():
		low_water_supply_tween.play()
	elif w > 30 and low_water_supply_tween.is_running():
		low_water_supply_tween.stop()
	
	if not animate:
		water_supply.value = w
	else:
		if water_supply_tween != null:
			water_supply_tween.kill()
		var tween := create_tween()
		tween.tween_property(water_supply, "rotation", 0, 0.6).from(deg_to_rad(7))\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.parallel().tween_property(water_supply, "value", effective_water_supply, 1.0) \
			.from_current().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		water_supply_tween = tween

func set_level(level: int, max_level: int) -> void:
	(%LevelLabel as Label).text = "Level %s/%s" % [level, max_level]
