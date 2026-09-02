extends Node

const TOTAL_HOLES := 9
const COMMUNITY_UNLOCK_PATH := "user://community_course_unlock.json"

var hole_strokes: int = 0
var total_strokes: int = 0
var counting_enabled: bool = false
var npcs_missed: int = 0
var bunker_holes_unswept: int = 0
var community_course_unlocked: bool = false

var _required_answers_by_hole: Dictionary[int, int] = {}
var _answers_by_hole: Dictionary[int, int] = {}
var _transformed_holes: Dictionary[int, bool] = {}


func _ready() -> void:
	community_course_unlocked = _load_community_unlock()

func reset_round() -> void:
	hole_strokes = 0
	total_strokes = 0
	counting_enabled = false
	npcs_missed = 0
	bunker_holes_unswept = 0
	_required_answers_by_hole.clear()
	_answers_by_hole.clear()
	_transformed_holes.clear()


func register_hole_question_count(hole_number: int, question_count: int) -> void:
	if hole_number < 1 or hole_number > TOTAL_HOLES:
		return
	_required_answers_by_hole[hole_number] = maxi(question_count, 0)


func register_hole_answer(hole_number: int) -> void:
	if hole_number < 1 or hole_number > TOTAL_HOLES or community_course_unlocked:
		return
	_answers_by_hole[hole_number] = _answers_by_hole.get(hole_number, 0) + 1


func is_hole_ready_to_transform(hole_number: int) -> bool:
	if community_course_unlocked or is_hole_transformed(hole_number):
		return false
	var required_answers: int = _required_answers_by_hole.get(hole_number, 0)
	var recorded_answers: int = _answers_by_hole.get(hole_number, 0)
	return required_answers > 0 and recorded_answers >= required_answers


func transform_hole(hole_number: int) -> void:
	if hole_number < 1 or hole_number > TOTAL_HOLES:
		return
	_transformed_holes[hole_number] = true
	if _transformed_holes.size() == TOTAL_HOLES:
		community_course_unlocked = true
		_save_community_unlock()


func is_hole_transformed(hole_number: int) -> bool:
	return community_course_unlocked or _transformed_holes.get(hole_number, false)


func get_transformed_hole_count() -> int:
	return TOTAL_HOLES if community_course_unlocked else _transformed_holes.size()

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


func _load_community_unlock() -> bool:
	if not FileAccess.file_exists(COMMUNITY_UNLOCK_PATH):
		return false
	var file := FileAccess.open(COMMUNITY_UNLOCK_PATH, FileAccess.READ)
	if file == null:
		push_error("Course state: could not read %s." % COMMUNITY_UNLOCK_PATH)
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return typeof(parsed) == TYPE_DICTIONARY and parsed.get("community_course_unlocked", false) == true


func _save_community_unlock() -> void:
	var file := FileAccess.open(COMMUNITY_UNLOCK_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Course state: could not write %s." % COMMUNITY_UNLOCK_PATH)
		return
	file.store_string(JSON.stringify({ "community_course_unlocked": true }))
