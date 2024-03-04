class_name MainMenu
extends Control

signal play_pressed()
signal leaderboard_pressed()

func _ready() -> void:
	(%StartButton as Button).pressed.connect(func(): play_pressed.emit())
	(%RankingButton as Button).pressed.connect(func(): leaderboard_pressed.emit())
