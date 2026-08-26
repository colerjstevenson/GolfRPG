extends Node

var hole_strokes: int = 0
var total_strokes: int = 0
var counting_enabled: bool = false

func reset_round() -> void:
	hole_strokes = 0
	total_strokes = 0
	counting_enabled = false

func reset_hole() -> void:
	hole_strokes = 0
	counting_enabled = true

func register_shot() -> void:
	if not counting_enabled:
		return
	hole_strokes += 1
	total_strokes += 1
