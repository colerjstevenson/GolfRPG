extends TextureRect

## Greeting -> question -> answer flow for NPC conversations. Content comes from the SurveyData autoload.

signal dialog_closed(npc: Node2D)
signal answer_recorded(hole_name: String)

const ADVANCE_GUARD_SECONDS := 0.25
const ANSWER_GUARD_SECONDS := 0.3

enum Phase { HIDDEN, GREETING, QUESTION, MESSAGE, LOCKED }

@onready var greeting_label: RichTextLabel = $greeting
@onready var question_label: RichTextLabel = $question
@onready var option_buttons: Array[TextureButton] = [
	$Option1 as TextureButton,
	$Option2 as TextureButton,
	$Option3 as TextureButton,
	$Option4 as TextureButton,
]

var phase: int = Phase.HIDDEN
var current_npc: Node2D = null
var current_question: Dictionary = {}

var _guard_until_msec: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for index in option_buttons.size():
		option_buttons[index].pressed.connect(_on_option_pressed.bind(index))
	_reset_panel()
	visible = false


func is_open() -> bool:
	return phase != Phase.HIDDEN


func open_for(npc: Node2D) -> void:
	if is_open():
		return

	current_npc = npc
	_reset_panel()

	var npc_name := ""
	if npc != null:
		if npc.has_method("get_npc_name"):
			npc_name = npc.get_npc_name()
		elif npc.get("npc_name") is String:
			npc_name = str(npc.npc_name)
	if npc_name.is_empty():
		npc_name = SurveyData.get_random_name()
	var npc_prompt: Variant = npc.get("prompt") if npc != null else null
	if npc_prompt is String and not npc_prompt.strip_edges().is_empty():
		greeting_label.text = npc_prompt
		phase = Phase.MESSAGE
	else:
		greeting_label.text = SurveyData.get_greeting_for(npc_name)
		phase = Phase.GREETING
	greeting_label.visible = true

	_start_guard(ADVANCE_GUARD_SECONDS)
	visible = true


func _gui_input(event: InputEvent) -> void:
	if _is_advance_click(event):
		accept_event()
		_show_question()


func _unhandled_input(event: InputEvent) -> void:
	if _is_advance_click(event):
		get_viewport().set_input_as_handled()
		_show_question()


func _is_advance_click(event: InputEvent) -> bool:
	if phase != Phase.GREETING and phase != Phase.MESSAGE or _is_guarded():
		return false
	return event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed


func _show_question() -> void:
	if phase == Phase.MESSAGE:
		_close()
		return

	current_question = SurveyData.get_next_question()
	greeting_label.visible = false
	question_label.text = str(current_question.get("prompt", ""))
	question_label.visible = true

	var options: Array = current_question.get("options", [])
	for index in option_buttons.size():
		var button := option_buttons[index]
		if index >= options.size():
			button.visible = false
			continue
		var option: Dictionary = options[index]
		_set_option_text(button, str(option.get("label", "")))
		button.disabled = true
		button.visible = true

	phase = Phase.QUESTION
	_start_guard(ANSWER_GUARD_SECONDS)
	await get_tree().create_timer(ANSWER_GUARD_SECONDS).timeout
	if phase != Phase.QUESTION:
		return
	for button in option_buttons:
		if button.visible:
			button.disabled = false


func _on_option_pressed(index: int) -> void:
	# Guards against a second press landing before the panel finishes closing.
	if phase != Phase.QUESTION:
		return
	phase = Phase.LOCKED
	for button in option_buttons:
		button.disabled = true

	var options: Array = current_question.get("options", [])
	if index < options.size():
		var option: Dictionary = options[index]
		var hole_name := get_tree().current_scene.name
		SurveyData.record_answer(
			str(current_question.get("id", "")),
			str(option.get("id", "")),
			str(option.get("label", "")),
			hole_name
		)
		answer_recorded.emit(hole_name)

	_close()


func _close() -> void:
	var npc := current_npc
	current_npc = null
	current_question = {}
	phase = Phase.HIDDEN
	visible = false
	_reset_panel()
	dialog_closed.emit(npc)


func _reset_panel() -> void:
	greeting_label.visible = false
	greeting_label.text = ""
	question_label.visible = false
	question_label.text = ""
	for button in option_buttons:
		button.visible = false
		button.disabled = true
		_set_option_text(button, "")


func _set_option_text(button: TextureButton, text: String) -> void:
	var label := button.get_node_or_null("text") as RichTextLabel
	if label == null:
		push_warning("Dialog: option button %s has no \"text\" RichTextLabel child." % button.name)
		return
	label.text = text


func _start_guard(seconds: float) -> void:
	_guard_until_msec = Time.get_ticks_msec() + int(seconds * 1000.0)


func _is_guarded() -> bool:
	return Time.get_ticks_msec() < _guard_until_msec
