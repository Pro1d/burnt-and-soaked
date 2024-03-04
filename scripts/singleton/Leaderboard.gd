extends Node

const api_key_path := "res://silent-wolf-api-key.json"
var leaderboard_enabled := false

func _ready() -> void:
	leaderboard_enabled = not _configure_silent_wolf()

func _configure_silent_wolf() -> bool:
	var file := FileAccess.open(api_key_path, FileAccess.READ)
	if file == null:
		printerr("Cannot open SilentWolf API key file.")
		return false
	var json_result := JSON.parse_string(file.get_as_text()) as Dictionary
	if json_result == null:
		printerr("Cannot parse SilentWolf API key file.")
		return false
	json_result["log_level"] = 0
	SilentWolf.configure(json_result)
	return true

@warning_ignore("unsafe_method_access")
@warning_ignore("unsafe_property_access")
func load_leaderboard(on_loaded: Callable) -> void:
	# on_loaded(Array[Dictionary["player_name"/"score"]] / null)
	SilentWolf.Scores.get_scores(200)
	SilentWolf.Scores.sw_get_scores_complete.connect(
		func(result: Dictionary):
			on_loaded.call(result.get("scores") if result != null else null)
	)

@warning_ignore("unsafe_method_access")
@warning_ignore("unsafe_property_access")
func get_leaderboard() -> Array:
	return SilentWolf.Scores.scores

@warning_ignore("unsafe_method_access")
@warning_ignore("unsafe_property_access")
func post_score(player_name: String, score: int, on_posted: Callable) -> void:
	# on_posted(bool)
	SilentWolf.Scores.save_score(player_name, score)
	SilentWolf.Scores.sw_save_score_complete.connect(
		func(result: Dictionary):
			on_posted.call(result.has("score_id"))
	)

@warning_ignore("unsafe_method_access")
@warning_ignore("unsafe_property_access")
func wipe_leaderboard() -> void:
	SilentWolf.Scores.wipe_leaderboard()
