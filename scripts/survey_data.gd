extends Node

## Autoload: owns the survey question bank, NPC name/greeting pools, and the answer log.
##
## questions.json schema (edit this file to add or change questions, no code changes needed):
##   { "questions": [
##       { "id": "q_001",
##         "prompt": "Question text shown to the player.",
##         "options": [ { "id": "option_id", "label": "Answer text on the button." } ] } ] }
## A question needs a non-empty id, a non-empty prompt, and 2-4 options. Extra options are ignored
## because the dialog panel only has four buttons.
##
## names.txt and greetings.txt are plain text, one entry per line. Every greeting should contain the
## token NAME, which is replaced with the randomly drawn NPC name.

const QUESTIONS_PATH := "res://data/questions.json"
const NAMES_PATH := "res://data/names.txt"
const GREETINGS_PATH := "res://data/greetings.txt"
const ANSWER_LOG_PATH := "user://survey_answers.json"
const MAX_OPTIONS := 4
const NAME_TOKEN := "NAME"

const FALLBACK_QUESTION := {
	"id": "fallback",
	"prompt": "Question data failed to load.",
	"options": [
		{ "id": "ok", "label": "Okay." },
	],
}

var questions: Array[Dictionary] = []
var npc_names: PackedStringArray = PackedStringArray()
var greetings: PackedStringArray = PackedStringArray()
var answers: Array[Dictionary] = []

var _question_deck: Array[Dictionary] = []


func _ready() -> void:
	randomize()
	_load_questions()
	npc_names = _load_lines(NAMES_PATH)
	greetings = _load_lines(GREETINGS_PATH)
	answers = _load_answer_log()
	if npc_names.is_empty():
		npc_names = PackedStringArray(["A Golfer"])
	if greetings.is_empty():
		greetings = PackedStringArray(["Hey, it's NAME. Got a second?"])


## Draws a question without repeating until every question has been used, then reshuffles.
func get_next_question() -> Dictionary:
	if questions.is_empty():
		return FALLBACK_QUESTION
	if _question_deck.is_empty():
		_refill_deck()
	return _question_deck.pop_back()


func get_random_name() -> String:
	return npc_names[randi() % npc_names.size()]


func get_greeting_for(npc_name: String) -> String:
	var template := greetings[randi() % greetings.size()]
	return template.replace(NAME_TOKEN, npc_name)


func record_answer(question_id: String, option_id: String, option_label: String, hole: String) -> void:
	var entry := {
		"question_id": question_id,
		"option_id": option_id,
		"option_label": option_label,
		"hole": hole,
		"timestamp": Time.get_datetime_string_from_system(true),
	}
	answers.append(entry)
	_save_answer_log()

## Wipes the saved answer log, used when starting a new round.
func clear_answers() -> void:
	answers = []
	_save_answer_log()


func _refill_deck() -> void:
	_question_deck = questions.duplicate()
	_question_deck.shuffle()


func _load_questions() -> void:
	questions.clear()
	var raw := _read_text_file(QUESTIONS_PATH)
	if raw.is_empty():
		questions.append(FALLBACK_QUESTION)
		return

	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("questions"):
		push_error("Survey: %s is not a dictionary with a \"questions\" array." % QUESTIONS_PATH)
		questions.append(FALLBACK_QUESTION)
		return

	for entry: Variant in parsed["questions"]:
		var question := _validate_question(entry)
		if not question.is_empty():
			questions.append(question)

	if questions.is_empty():
		push_error("Survey: no valid questions found in %s." % QUESTIONS_PATH)
		questions.append(FALLBACK_QUESTION)


func _validate_question(entry: Variant) -> Dictionary:
	if typeof(entry) != TYPE_DICTIONARY:
		push_warning("Survey: skipping a non-object entry in %s." % QUESTIONS_PATH)
		return {}

	var question: Dictionary = entry
	var id := str(question.get("id", "")).strip_edges()
	var prompt := str(question.get("prompt", "")).strip_edges()
	if id.is_empty() or prompt.is_empty():
		push_warning("Survey: skipping question with a missing id or prompt.")
		return {}

	var raw_options: Variant = question.get("options", [])
	if typeof(raw_options) != TYPE_ARRAY:
		push_warning("Survey: skipping question \"%s\" because options is not an array." % id)
		return {}

	var options: Array[Dictionary] = []
	for raw_option: Variant in raw_options:
		if typeof(raw_option) != TYPE_DICTIONARY:
			continue
		var option: Dictionary = raw_option
		var label := str(option.get("label", "")).strip_edges()
		if label.is_empty():
			continue
		options.append({
			"id": str(option.get("id", "option_%d" % options.size())),
			"label": label,
		})
		if options.size() == MAX_OPTIONS:
			break

	if options.size() < 2:
		push_warning("Survey: skipping question \"%s\" because it has fewer than two valid options." % id)
		return {}

	return { "id": id, "prompt": prompt, "options": options }


func _load_lines(path: String) -> PackedStringArray:
	var lines := PackedStringArray()
	var raw := _read_text_file(path)
	if raw.is_empty():
		return lines
	for line: String in raw.split("\n"):
		var trimmed := line.strip_edges()
		if not trimmed.is_empty():
			lines.append(trimmed)
	return lines


func _read_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		push_error("Survey: missing data file %s." % path)
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Survey: could not open %s (error %d)." % [path, FileAccess.get_open_error()])
		return ""
	return file.get_as_text()


func _load_answer_log() -> Array[Dictionary]:
	var loaded: Array[Dictionary] = []
	if not FileAccess.file_exists(ANSWER_LOG_PATH):
		return loaded
	var file := FileAccess.open(ANSWER_LOG_PATH, FileAccess.READ)
	if file == null:
		return loaded
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return loaded
	for entry: Variant in parsed:
		if typeof(entry) == TYPE_DICTIONARY:
			loaded.append(entry)
	return loaded


func _save_answer_log() -> void:
	var file := FileAccess.open(ANSWER_LOG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Survey: could not write %s (error %d)." % [ANSWER_LOG_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(answers, "\t"))
