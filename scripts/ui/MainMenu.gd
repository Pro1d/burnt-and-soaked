extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	(%StartButton as Button).pressed.connect(SceneManager.go_to_game)
