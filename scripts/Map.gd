class_name Map
extends Node2D

@onready var top := ((%Top as CollisionShape2D).shape as WorldBoundaryShape2D).distance
@onready var bottom := -((%Bottom as CollisionShape2D).shape as WorldBoundaryShape2D).distance
@onready var left := ((%Left as CollisionShape2D).shape as WorldBoundaryShape2D).distance
@onready var right := -((%Right as CollisionShape2D).shape as WorldBoundaryShape2D).distance

@onready var boundaries := Rect2i(left, top, right - left, bottom - top)

class Level:
	var target_area : Area2D
	var fires : Array[Fire] = []
	var start_position : Transform2D
	
	func hide() -> void:
		for f in fires:
			f.stop()
			f.hide()
		target_area.hide()
		target_area.monitoring = false
	
	func show() -> void:
		for f in fires:
			f.light()
			f.show()
		target_area.show()
		target_area.monitoring = true
	
var levels : Array[Level] = []

func _ready() -> void:
	for node in %Levels.get_children():
		var level := Level.new()
		for f in node.find_children("", "Fire"):
			level.fires.append(f)
		level.start_position = (node.find_child("Marker2D") as Node2D).global_transform
		level.target_area = node.find_child("AreaOfInterest")
		levels.append(level)

func select_level(index: int) -> Level:
	for i in range(levels.size()):
		if i != index:
			levels[i].hide()
	var l := levels[index]
	l.show()
	return l
