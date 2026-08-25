@tool
extends CharacterBody2D

signal clicked(npc: Node2D)

const FRAME_SIZE := Vector2i(16, 16)
const ANIMATION_SPEED := 5.0
const IDLE_ANIMATION := &"down"
const FALLEN_ANIMATION := &"fallen"

# All NPC sheets share this 16x16 cell layout; values are atlas origins per frame.
const ANIMATION_LAYOUT := {
	"down": [Vector2i(0, 0), Vector2i(16, 0), Vector2i(32, 0), Vector2i(48, 0)],
	"up": [Vector2i(64, 0), Vector2i(80, 0), Vector2i(96, 0), Vector2i(112, 0)],
	"left": [Vector2i(128, 0), Vector2i(144, 0), Vector2i(160, 0), Vector2i(176, 0)],
	"right": [Vector2i(0, 16), Vector2i(16, 16), Vector2i(32, 16), Vector2i(48, 16)],
	"fallen": [Vector2i(176, 48)],
}

@export var npc_name: String = ""

@export var sprite_sheet: Texture2D:
	set = _set_sprite_sheet

@export var sprite_sheet_pool: Array[Texture2D] = [
	preload("res://assets/sprites/sprite1.png"),
	preload("res://assets/sprites/sprite2.png"),
	preload("res://assets/sprites/sprite3.png"),
	preload("res://assets/sprites/sprite4.png"),
	preload("res://assets/sprites/sprite5.png"),
	preload("res://assets/sprites/sprite6.png"),
]

enum PatrolMode { LOOP, PING_PONG, ONE_SHOT }

## Path2D (with curve points placed by the level designer) the NPC walks along.
@export var patrol_path: NodePath = NodePath("PatrolPath")
@export var patrol_speed: float = 60.0
@export var patrol_mode: PatrolMode = PatrolMode.LOOP
@export var wait_time_at_point: float = 0.0
@export var autostart_patrol: bool = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var _patrol_node: Path2D = null
var _patrol_points: Array[Vector2] = []
var _waypoint_index: int = 0
var _waypoint_step: int = 1
var _is_patrolling: bool = false
var _wait_timer: float = 0.0
var _last_direction: String = "down"
var is_knocked_down: bool = false
var is_in_dialog: bool = false
var _was_patrolling_before_dialog: bool = false


func _ready() -> void:
	if npc_name.is_empty() and not Engine.is_editor_hint():
		npc_name = SurveyData.get_random_name()

	if sprite_sheet == null and not Engine.is_editor_hint():
		if sprite_sheet_pool.is_empty():
			push_warning("NPC has no sprite_sheet and an empty sprite_sheet_pool; keeping scene frames.")
		else:
			sprite_sheet = sprite_sheet_pool.pick_random()
	else:
		_rebuild_frames()

	if Engine.is_editor_hint():
		return

	_patrol_node = get_node_or_null(patrol_path) as Path2D
	_refresh_patrol_points()
	if autostart_patrol:
		start_patrol()
	input_pickable = true
	input_event.connect(_on_input_event)
	call_deferred("_connect_to_ball")


func _on_input_event(viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if is_in_dialog or is_knocked_down:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	viewport.set_input_as_handled()
	clicked.emit(self)


## Freezes the NPC facing the camera for the duration of a conversation.
func get_npc_name() -> String:
	if npc_name.is_empty():
		npc_name = SurveyData.get_random_name()
	return npc_name


func face_forward() -> void:
	is_in_dialog = true
	_was_patrolling_before_dialog = _is_patrolling
	_last_direction = "down"
	stop_patrol()


func resume_after_dialog() -> void:
	is_in_dialog = false
	if _was_patrolling_before_dialog and not is_knocked_down:
		start_patrol()
	_was_patrolling_before_dialog = false


func _connect_to_ball() -> void:
	var ball_node := get_tree().get_first_node_in_group(&"ball")
	if ball_node != null and ball_node.has_signal("flight_started"):
		ball_node.flight_started.connect(_on_ball_flight_started)


func _on_ball_flight_started(_ball: Node2D) -> void:
	recover()


func knock_down() -> void:
	if is_knocked_down:
		return
	is_knocked_down = true
	_is_patrolling = false
	velocity = Vector2.ZERO
	animated_sprite.play(FALLEN_ANIMATION)


func recover() -> void:
	if not is_knocked_down:
		return
	is_knocked_down = false
	if autostart_patrol and _patrol_node != null:
		_is_patrolling = true


func start_patrol() -> void:
	if _patrol_points.is_empty():
		_refresh_patrol_points()
	if _patrol_points.is_empty():
		return
	_waypoint_index = 0
	_waypoint_step = 1
	_is_patrolling = true


func stop_patrol() -> void:
	_is_patrolling = false
	velocity = Vector2.ZERO
	animated_sprite.play(_last_direction)
	animated_sprite.pause()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not _is_patrolling:
		return

	if _wait_timer > 0.0:
		_wait_timer -= delta
		return

	var target := _patrol_points[_waypoint_index]
	var to_target := target - global_position
	var distance := to_target.length()
	var step := patrol_speed * delta

	if distance <= step:
		global_position = target
		velocity = Vector2.ZERO
		move_and_slide()
		_advance_waypoint()
		if _is_patrolling and wait_time_at_point > 0.0:
			_wait_timer = wait_time_at_point
			animated_sprite.play(_last_direction)
			animated_sprite.pause()
		return

	var direction := to_target.normalized()
	velocity = direction * patrol_speed
	move_and_slide()
	_update_animation(direction)


func _advance_waypoint() -> void:
	var point_count := _patrol_points.size()
	match patrol_mode:
		PatrolMode.LOOP:
			_waypoint_index = (_waypoint_index + 1) % point_count
		PatrolMode.PING_PONG:
			_waypoint_index += _waypoint_step
			if _waypoint_index >= point_count - 1:
				_waypoint_index = point_count - 1
				_waypoint_step = -1
			elif _waypoint_index <= 0:
				_waypoint_index = 0
				_waypoint_step = 1
		PatrolMode.ONE_SHOT:
			if _waypoint_index < point_count - 1:
				_waypoint_index += 1
			else:
				stop_patrol()


func _refresh_patrol_points() -> void:
	_patrol_points.clear()
	if _patrol_node == null or _patrol_node.curve == null:
		return

	for point_index in _patrol_node.curve.point_count:
		_patrol_points.append(_patrol_node.to_global(_patrol_node.curve.get_point_position(point_index)))


func _update_animation(direction: Vector2) -> void:
	var anim_name: String
	if abs(direction.x) > abs(direction.y):
		anim_name = "right" if direction.x > 0 else "left"
	else:
		anim_name = "down" if direction.y > 0 else "up"

	_last_direction = anim_name
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)


func _set_sprite_sheet(value: Texture2D) -> void:
	sprite_sheet = value
	_rebuild_frames()


func _rebuild_frames() -> void:
	# The exported setter can fire before the node tree is ready.
	if animated_sprite == null or sprite_sheet == null:
		return

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	for animation_name: String in ANIMATION_LAYOUT:
		frames.add_animation(animation_name)
		frames.set_animation_loop(animation_name, true)
		frames.set_animation_speed(animation_name, ANIMATION_SPEED)
		for origin: Vector2i in ANIMATION_LAYOUT[animation_name]:
			var atlas := AtlasTexture.new()
			atlas.atlas = sprite_sheet
			atlas.region = Rect2(origin, FRAME_SIZE)
			frames.add_frame(animation_name, atlas)

	animated_sprite.sprite_frames = frames
	if Engine.is_editor_hint():
		animated_sprite.animation = IDLE_ANIMATION
		animated_sprite.frame = 0
		animated_sprite.pause()
	else:
		animated_sprite.animation = IDLE_ANIMATION
		animated_sprite.frame = 0
		animated_sprite.pause()
