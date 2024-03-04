extends Node

func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func go_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
