extends Node

var hole_strokes: int = 0
var total_strokes: int = 0

func reset_round() -> void:
	hole_strokes = 0
	total_strokes = 0

func reset_hole() -> void:
	hole_strokes = 0

func register_shot() -> void:
	hole_strokes += 1
	total_strokes += 1
