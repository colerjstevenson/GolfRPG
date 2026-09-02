extends Node2D

## Reveals the round's final score by counting up each stat label in turn, then offers a restart.

const START_SCENE_PATH := "res://Scenes/Start.tscn"
const COUNT_DURATION := 1.0

@onready var strokes_label: RichTextLabel = $HUD/Score/Strokes
@onready var questions_label: RichTextLabel = $HUD/Score/Questions
@onready var bunkers_label: RichTextLabel = $HUD/Score/Bunkers
@onready var final_label: RichTextLabel = $HUD/Score/Final
@onready var new_round_button: TextureButton = $HUD/Score/NewRound


func _ready() -> void:
	new_round_button.disabled = true
	new_round_button.pressed.connect(_on_new_round_pressed)
	_run_score_sequence()


func _run_score_sequence() -> void:
	var strokes := CourseState.total_strokes
	var missed_npcs := CourseState.npcs_missed
	var unswept_bunkers := CourseState.bunker_holes_unswept
	var final_score := CourseState.get_final_score()

	await _count_up(strokes_label, "Strokes", strokes)
	await _count_up(questions_label, "Questions Missed", missed_npcs)
	await _count_up(bunkers_label, "Unraked Bunkers", unswept_bunkers)
	await _count_up(final_label, "Final Score", final_score, "\n")
	new_round_button.disabled = false


func _count_up(label: RichTextLabel, prefix: String, target_value: int, separator: String = ": ") -> void:
	if target_value <= 0:
		label.text = "%s%s%d" % [prefix, separator, 0]
		return
	var tween := create_tween()
	tween.tween_method(
		func(value: float) -> void: label.text = "%s%s%d" % [prefix, separator, roundi(value)],
		0.0, float(target_value), COUNT_DURATION
	)
	await tween.finished


func _on_new_round_pressed() -> void:
	CourseState.reset_round()
	get_tree().change_scene_to_file(START_SCENE_PATH)
