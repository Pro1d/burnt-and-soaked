class_name HUD
extends Control

signal menu_pressed()
signal restart_pressed()

@onready var time_display := %TimeDisplay as TimeDisplay
@onready var water_supply := %TextureProgressBar as TextureProgressBar
var effective_water_supply := 0
var water_supply_tween : Tween
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#(%MenuButton as Button).pressed.connect
	#(%MusicButton as Button).pressed.connect
	time_display.get_time_func = (func() -> float: return Config.timer)
	water_supply.pivot_offset = water_supply.size / 2
	(%MenuButton as Button).pressed.connect(func(): menu_pressed.emit())
	(%RetryButton as Button).pressed.connect(func(): restart_pressed.emit())

func set_water_supply(w: int, animate: bool = true) -> void:
	effective_water_supply = w
	if not animate:
		water_supply.value = w
		return
	if water_supply_tween != null:
		water_supply_tween.stop()
	var tween := create_tween()
	#tween.tween_property(water_supply, "scale", Vector2.ONE, 0.7).from(Vector2(1.3, 1.3))\
		#.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(water_supply, "rotation", 0, 0.7).from(deg_to_rad(10))\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.parallel().tween_property(water_supply, "value", effective_water_supply, 1.0) \
		.from_current().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	water_supply_tween = tween

func set_level(level: int, max_level: int) -> void:
	(%LevelLabel as Label).text = "Level %s/%s" % [level, max_level]
