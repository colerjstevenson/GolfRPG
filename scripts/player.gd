extends CharacterBody2D

signal shot_mode_entered(ball: Node2D)
signal shot_mode_exited
signal aim_power_changed(power_ratio: float)

enum State {
	FREE,
	WALK_TO_BALL,
	AIMING,
	LOCKED,
}

@export var speed: float = 100.0
@export var stand_distance: float = 24.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var target_position: Vector2
var is_moving: bool = false
var last_direction: String = "down"
var state: int = State.FREE
var current_ball: Node2D = null
var drag_start: Vector2
var dragging: bool = false
var drag_power: float = 0.0
var drag_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
	target_position = global_position
	animated_sprite.animation = last_direction
	animated_sprite.frame = 0
	animated_sprite.pause()

func on_ball_clicked(ball: Node2D) -> void:
	if state != State.FREE:
		return
	if ball == null:
		return

	current_ball = ball
	var to_ball := ball.global_position - global_position
	var offset_dir := Vector2.ZERO
	if to_ball.length() > 0.0001:
		offset_dir = to_ball.normalized()
	else:
		offset_dir = Vector2.DOWN

	target_position = ball.global_position - offset_dir * stand_distance
	is_moving = true
	state = State.WALK_TO_BALL

func _unhandled_input(event: InputEvent) -> void:
	if state == State.FREE and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		target_position = get_global_mouse_position()
		is_moving = true
		return

	if state != State.AIMING:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start = get_global_mouse_position()
			dragging = true
			drag_power = 0.0
			drag_dir = Vector2.ZERO
		elif dragging:
			var pull := get_global_mouse_position() - drag_start
			if pull.length() > 2.0:
				drag_dir = (-pull).normalized()
				drag_power = clamp(pull.length() / current_ball.max_drag_px, 0.0, 1.0)
				aim_power_changed.emit(drag_power)
				current_ball.set_aim_preview(drag_dir, drag_power)
				current_ball.launch(drag_dir, drag_power)
				state = State.LOCKED
			else:
				current_ball.clear_aim_preview()
				state = State.FREE
				current_ball = null
				shot_mode_exited.emit()
			dragging = false
			return

	if event is InputEventMouseMotion and dragging and current_ball != null:
		var pull := get_global_mouse_position() - drag_start
		if pull.length() > 2.0:
			drag_dir = (-pull).normalized()
			drag_power = clamp(pull.length() / current_ball.max_drag_px, 0.0, 1.0)
			aim_power_changed.emit(drag_power)
			current_ball.set_aim_preview(drag_dir, drag_power)
		else:
			current_ball.clear_aim_preview()

func _physics_process(delta: float) -> void:
	if state == State.LOCKED and current_ball != null and current_ball.state == current_ball.State.IDLE:
		state = State.FREE
		current_ball = null
		shot_mode_exited.emit()

	if not is_moving:
		return

	var to_target := target_position - global_position
	var distance := to_target.length()
	var step := speed * delta

	if distance <= step:
		velocity = to_target / maxf(delta, 0.001)
		move_and_slide()
		if global_position.distance_to(target_position) > 0.5:
			_stop_movement()
			return
		global_position = target_position
		_finish_movement()
		if state == State.WALK_TO_BALL:
			state = State.AIMING
			shot_mode_entered.emit(current_ball)
			if current_ball != null:
				var ball_dir := current_ball.global_position - global_position
				if ball_dir.length() > 0.0001:
					_update_animation(ball_dir.normalized())
				else:
					_update_animation(Vector2.DOWN)
				animated_sprite.frame = 0
				animated_sprite.pause()
		return

	var direction := to_target.normalized()
	var previous_position := global_position
	velocity = direction * speed
	move_and_slide()
	_update_animation(direction)
	if global_position.distance_squared_to(previous_position) < 0.0001 and get_slide_collision_count() > 0:
		_stop_movement()

func _finish_movement() -> void:
	is_moving = false
	velocity = Vector2.ZERO
	animated_sprite.animation = last_direction
	animated_sprite.frame = 0
	animated_sprite.pause()

func _stop_movement() -> void:
	_finish_movement()
	if state == State.WALK_TO_BALL:
		state = State.FREE
		current_ball = null

func _update_animation(direction: Vector2) -> void:
	var anim_name: String
	if abs(direction.x) > abs(direction.y):
		anim_name = "right" if direction.x > 0 else "left"
	else:
		anim_name = "down" if direction.y > 0 else "up"

	last_direction = anim_name
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)
