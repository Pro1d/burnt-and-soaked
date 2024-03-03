class_name Map
extends Node2D

@onready var top := ((%Top as CollisionShape2D).shape as WorldBoundaryShape2D).distance
@onready var bottom := -((%Bottom as CollisionShape2D).shape as WorldBoundaryShape2D).distance
@onready var left := ((%Left as CollisionShape2D).shape as WorldBoundaryShape2D).distance
@onready var right := -((%Right as CollisionShape2D).shape as WorldBoundaryShape2D).distance

@onready var boundaries := Rect2i(left, top, right - left, bottom - top)
