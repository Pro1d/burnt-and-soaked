class_name ScoreScreen
extends MarginContainer

signal leave_animation_finished()

var _score : int

func _ready() -> void:
	(%TemplateNameLabel as Control).visible = false
	(%TemplateScoreLabel as Control).visible = false
	(%NameLineEdit as LineEdit).text= _generate_random_name()
	(%NameLineEdit as LineEdit).text_changed.connect(func(_t: String): _update_submit_button())
	_update_submit_button()
	(%SubmitButton as Button).pressed.connect(_on_submit_pressed)
	(%BackButton as Button).pressed.connect(_leave_animation)
	visibility_changed.connect(func():
		if visible:
			position.x = 0
			_on_show()
	)

func show_leaderboard_only(lb_only: bool) -> void:
#	%SubmitContainer.visible = not lb_only
#	%ScoreLabel.visible = not lb_only
	(%ScorePanelContainer as Control).visible = not lb_only

func set_time(t: float) -> void:
	_score = -roundi(t * 100)
	(%ScoreLabel as Label).text = "Total time: %s" % [TimeDisplay.time_to_string(t)]

func _leave_animation() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(self, "position:x", size.x, 0.5) \
		.from(0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.finished.connect(func():
		print("animation finished")
		leave_animation_finished.emit())

func _update_submit_button() -> void:
	(%SubmitButton as Button).disabled = (%NameLineEdit as LineEdit).text.is_empty()

func _on_show() -> void:
	(%NameLineEdit as LineEdit).editable = true
	(%NameLineEdit as LineEdit).grab_focus()
	(%NameLineEdit as LineEdit).select_all()
	if %LeaderboardGridContainer.get_child_count() > 2:
		(%LeaderboardScrollContainer as ScrollContainer).ensure_control_visible(
			%LeaderboardGridContainer.get_child(2) as Control
		)
	_update_submit_button()
	_reload_leaderboard()

func _on_submit_pressed() -> void:
	(%SubmitButton as Button).disabled = true
	(%NameLineEdit as LineEdit).editable = false
	Leaderboard.post_score(
		(%NameLineEdit as LineEdit).text, _score, func(_success):_reload_leaderboard()
	)

func _reload_leaderboard() -> void:
	Leaderboard.load_leaderboard(make_leaderboard)

func make_leaderboard(scores) -> void: # scores: Optional[Array]
	var container := %LeaderboardGridContainer as Container
	
	if scores == null:
		return
	
	# Fill
	var templates : Array[Label] = [
		%TemplateNameLabel as Label,
		%TemplateScoreLabel as Label
	]
	var child_count := container.get_child_count()
	var node_index := 2
	for s in scores:
		var score := int("%s" % [s.score])
		for text in [s.player_name, TimeDisplay.time_to_string(-float(score) / 100)]:
			var label : Label
			if node_index < child_count: # Re-use existing label if possible
				label = container.get_child(node_index)
			else:
				label = templates[node_index % 2].duplicate()
				label.visible = true
				container.add_child(label)
			label.text = text
			node_index += 1
	
	# not useful in practice because leaderboard should only increase in size
	while container.get_child_count() > node_index:
		container.remove_child(container.get_child(container.get_child_count() - 1))

func _generate_random_name() -> String:
	randomize()
	var vowels := "aaeeiiuoo"
	var consonants := "zrrttppssddfjllmmccvbbnn"
	var generated := ""
	if randf() < 0.5:
		generated += vowels[randi_range(0, len(vowels) - 1)]
	for i in range(randi_range(2, 4)):
		generated += consonants[randi_range(0, len(vowels) - 1)]
		generated += vowels[randi_range(0, len(vowels) - 1)]
	return generated.capitalize()
