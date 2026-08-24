extends CharacterBody2D

signal shot_mode_entered(ball: Node2D)
signal shot_mode_exited
signal aim_drag_started(ball: Node2D, screen_position: Vector2)
signal aim_power_changed(power_ratio: float)
signal scripted_walk_finished

enum State {
	FREE,
	WALK_TO_BALL,
	AIMING,
	LOCKED,
	SCRIPTED_WALK,
}

@export var speed: float = 100.0
@export var stand_distance: float = 24.0
@export var footprint_spacing: float = 16.0
@export var footprint_stride_side_offset: float = 2.5
@export var footprint_step_forward_offset: float = 1.5
@export var footprint_size: Vector2 = Vector2(2.0, 4.0)
@export var footprint_color: Color = Color(0.24, 0.16, 0.09, 0.35)
@export var ground_layer: TileMapLayer
@export var ground_items_layer: TileMapLayer
@export var footprint_parent: Node2D

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
var has_last_footprint: bool = false
var last_footprint_position: Vector2

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

func scripted_walk_to(destination: Vector2) -> void:
	if state == State.LOCKED:
		return
	state = State.SCRIPTED_WALK
	target_position = destination
	is_moving = true

func _unhandled_input(event: InputEvent) -> void:
	if state == State.FREE and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		target_position = get_global_mouse_position()
		is_moving = true
		return

	if state != State.AIMING:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_start = get_viewport().get_mouse_position()
			dragging = true
			drag_power = 0.0
			drag_dir = Vector2.ZERO
			aim_drag_started.emit(current_ball, drag_start)
		elif dragging:
			var pull := get_viewport().get_mouse_position() - drag_start
			if pull.length() > 2.0:
				drag_dir = (-pull).normalized()
				drag_power = clamp(pull.length() / current_ball.max_drag_px, 0.0, 1.0)
				if drag_power < current_ball.min_shot_power_ratio:
					current_ball.clear_aim_preview()
					drag_power = 0.0
					aim_power_changed.emit(0.0)
				else:
					aim_power_changed.emit(drag_power)
					current_ball.set_aim_preview(drag_dir, drag_power)
					current_ball.launch(drag_dir, drag_power)
					state = State.LOCKED
			else:
				current_ball.clear_aim_preview()
				aim_power_changed.emit(0.0)
				state = State.FREE
				current_ball = null
				shot_mode_exited.emit()
			dragging = false
			return

	if event is InputEventMouseMotion and dragging and current_ball != null:
		var pull := get_viewport().get_mouse_position() - drag_start
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
		var final_direction := to_target.normalized() if distance > 0.0001 else Vector2.DOWN
		velocity = to_target / maxf(delta, 0.001)
		move_and_slide()
		if global_position.distance_to(target_position) > 0.5:
			_stop_movement()
			return
		global_position = target_position
		_maybe_place_footprint(final_direction)
		_finish_movement()
		if state == State.SCRIPTED_WALK:
			state = State.FREE
			scripted_walk_finished.emit()
			return
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
	_maybe_place_footprint(direction)
	if global_position.distance_squared_to(previous_position) < 0.0001 and get_slide_collision_count() > 0:
		_stop_movement()

func _finish_movement() -> void:
	is_moving = false
	velocity = Vector2.ZERO
	_reset_footprint_spacing()
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

func get_terrain_name() -> String:
	var ground_items_terrain := _get_terrain_name_at_position(ground_items_layer)
	if not ground_items_terrain.is_empty():
		return ground_items_terrain

	var ground_terrain := _get_terrain_name_at_position(ground_layer)
	if not ground_terrain.is_empty():
		return ground_terrain

	return "fairway"

func _get_terrain_name_at_position(layer: TileMapLayer) -> String:
	return _get_terrain_name_at_global_position(global_position, layer)

func _get_terrain_name_at_global_position(sample_position: Vector2, layer: TileMapLayer) -> String:
	if layer == null:
		return ""

	var cell := layer.local_to_map(layer.to_local(sample_position))
	var tile_data := layer.get_cell_tile_data(cell)
	if tile_data == null or tile_data.terrain < 0:
		return ""

	return layer.tile_set.get_terrain_name(0, tile_data.terrain).to_lower()

func _maybe_place_footprint(direction: Vector2) -> void:
	if state != State.FREE or footprint_parent == null:
		_reset_footprint_spacing()
		return
	if get_terrain_name() != "sand":
		_reset_footprint_spacing()
		return
	if direction.length_squared() < 0.0001:
		return
	var normalized_direction := direction.normalized()
	if not _can_place_footprint(normalized_direction):
		_reset_footprint_spacing()
		return
	if has_last_footprint and global_position.distance_to(last_footprint_position) < footprint_spacing:
		return

	_spawn_footprint(normalized_direction)
	last_footprint_position = global_position
	has_last_footprint = true

func _can_place_footprint(direction: Vector2) -> bool:
	var side := Vector2(-direction.y, direction.x)
	var offsets: Array[Vector2] = [
		side * footprint_stride_side_offset + direction * footprint_step_forward_offset,
		-side * footprint_stride_side_offset - direction * footprint_step_forward_offset,
	]

	for offset: Vector2 in offsets:
		var mark_position: Vector2 = global_position + offset
		if not _is_sand_at_position(mark_position):
			return false
		if not _is_sand_at_position(mark_position + direction * footprint_size.y):
			return false
		if not _is_sand_at_position(mark_position - direction * footprint_size.y):
			return false
		if not _is_sand_at_position(mark_position + side * footprint_size.x):
			return false
		if not _is_sand_at_position(mark_position - side * footprint_size.x):
			return false

	return true

func _is_sand_at_position(sample_position: Vector2) -> bool:
	var ground_items_terrain := _get_terrain_name_at_global_position(sample_position, ground_items_layer)
	if not ground_items_terrain.is_empty():
		return ground_items_terrain == "sand"

	var ground_terrain := _get_terrain_name_at_global_position(sample_position, ground_layer)
	return ground_terrain == "sand"

func _spawn_footprint(direction: Vector2) -> void:
	var footprint := Node2D.new()
	footprint.global_position = global_position
	footprint.rotation = direction.angle()
	footprint_parent.add_child(footprint)

	var side := Vector2(-direction.y, direction.x)
	_create_footprint_mark(footprint, side * footprint_stride_side_offset + direction * footprint_step_forward_offset, 0.18)
	_create_footprint_mark(footprint, -side * footprint_stride_side_offset - direction * footprint_step_forward_offset, -0.18)

func _create_footprint_mark(parent: Node2D, offset: Vector2, rotation_offset: float) -> void:
	var mark := Polygon2D.new()
	mark.polygon = PackedVector2Array([
		Vector2(0.0, -footprint_size.y),
		Vector2(footprint_size.x, -footprint_size.y * 0.35),
		Vector2(footprint_size.x * 0.8, footprint_size.y * 0.55),
		Vector2(0.0, footprint_size.y),
		Vector2(-footprint_size.x * 0.8, footprint_size.y * 0.55),
		Vector2(-footprint_size.x, -footprint_size.y * 0.35),
	])
	mark.color = footprint_color
	mark.position = parent.to_local(parent.global_position + offset)
	mark.rotation = PI * 0.5 + rotation_offset
	parent.add_child(mark)

func _reset_footprint_spacing() -> void:
	has_last_footprint = false
