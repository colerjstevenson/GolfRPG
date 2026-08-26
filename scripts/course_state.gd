extends Node

var hole_strokes: int = 0
var total_strokes: int = 0
var counting_enabled: bool = false
var npcs_missed: int = 0
var bunker_holes_unswept: int = 0

func reset_round() -> void:
	hole_strokes = 0
	total_strokes = 0
	counting_enabled = false
	npcs_missed = 0
	bunker_holes_unswept = 0

func reset_hole() -> void:
	hole_strokes = 0
	counting_enabled = true

func register_shot() -> void:
	if not counting_enabled:
		return
	hole_strokes += 1
	total_strokes += 1

## Tally the outcome of a completed hole toward the end-of-round score.
func register_hole_results(missed_npc_count: int, bunker_unswept: bool) -> void:
	npcs_missed += missed_npc_count
	if bunker_unswept:
		bunker_holes_unswept += 1

func get_final_score() -> int:
	return total_strokes + npcs_missed + bunker_holes_unswept
