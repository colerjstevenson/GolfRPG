extends Area2D

signal clicked(ball: Node2D)
signal stopped
signal flight_started(ball: Node2D)
signal holed

enum State {
	IDLE,
	FLYING,
	ROLLING,
	HOLED,
}

@export var max_drag_px: float = 350.0
@export var min_shot_power_ratio: float = 0.08
@export var max_speed: float = 500.0
@export var max_flight_distance: float = 400.0
@export var max_arc_height: float = 40.0
@export var flight_duration_base: float = 0.9
@export var landing_bounce_height: float = 8.0
@export var landing_bounce_duration: float = 0.18
@export var friction: float = 350.0
@export var max_putt_speed: float = 420.0
@export var green_friction: float = 180.0
@export var wobble_max_angle_deg: float = 20.0
@export var wobble_frequency: float = 6.0
@export var npc_bounce_speed_ratio: float = 0.4
@export var npc_hit_min_speed: float = 40.0
@export var ground_layer: TileMapLayer
@export var ground_items_layer: TileMapLayer

@onready var ball_sprite: Sprite2D = $Sprite2D

var velocity: Vector2 = Vector2.ZERO
var state: int = State.IDLE
var aim_active: bool = false
var aim_dir: Vector2 = Vector2.RIGHT
var aim_power: float = 0.0
var flight_start: Vector2
var flight_end: Vector2
var flight_time: float = 0.0
var flight_duration: float = 0.0
var flight_power: float = 0.0
var landing_bounce_time: float = 0.0
var landing_bounce_height_current: float = 0.0
var landing_bounce_duration_current: float = 0.0
var base_sprite_position: Vector2
var base_sprite_scale: Vector2
var is_putting_shot: bool = false

func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	body_entered.connect(_on_body_entered)
	base_sprite_position = ball_sprite.position
	base_sprite_scale = ball_sprite.scale
	add_to_group(&"ball")

func _on_input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if state != State.IDLE:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked.emit(self)
		_viewport.set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if not body.has_method("knock_down"):
		return
	if state == State.FLYING:
		var incoming_dir := (flight_end - flight_start).normalized()
		var incoming_speed := predicted_distance(flight_power) / maxf(flight_duration, 0.001)
		_bounce_off_npc(body, incoming_dir, incoming_speed)
	elif state == State.ROLLING and velocity.length() > npc_hit_min_speed:
		_bounce_off_npc(body, velocity.normalized(), velocity.length())

func _bounce_off_npc(body: Node, incoming_dir: Vector2, incoming_speed: float) -> void:
	body.knock_down()
	ball_sprite.position = base_sprite_position
	ball_sprite.scale = base_sprite_scale
	landing_bounce_time = 0.0
	landing_bounce_height_current = 0.0
	landing_bounce_duration_current = 0.0
	velocity = -incoming_dir * incoming_speed * npc_bounce_speed_ratio
	state = State.ROLLING

func set_aim_preview(direction: Vector2, power_ratio: float) -> void:
	if direction.length_squared() < 0.0001:
		clear_aim_preview()
		return
	var max_power_ratio := _get_max_shot_power_ratio()
	aim_dir = direction.normalized()
	aim_power = clamp(power_ratio, 0.0, max_power_ratio)
	aim_active = true
	queue_redraw()

func clear_aim_preview() -> void:
	aim_active = false
	aim_power = 0.0
	aim_dir = Vector2.RIGHT
	queue_redraw()

func sink(hole_position: Vector2) -> void:
	if state != State.ROLLING:
		return

	state = State.HOLED
	velocity = Vector2.ZERO
	input_pickable = false
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "global_position", hole_position, 0.18)
	tween.tween_property(ball_sprite, "scale", Vector2.ZERO, 0.18)
	await tween.finished
	visible = false
	state = State.IDLE
	stopped.emit()
	holed.emit()

func _get_max_shot_power_ratio() -> float:
	var terrain_name := get_terrain_name()
	if terrain_name == "sand":
		return 0.5
	if terrain_name == "rough":
		return 0.8
	return 1.0

func predicted_distance(power_ratio: float) -> float:
	return clamp(power_ratio, 0.0, 1.0) * max_flight_distance

func _physics_process(delta: float) -> void:
	if aim_active or state == State.FLYING or landing_bounce_time < landing_bounce_duration_current:
		queue_redraw()

	if state == State.FLYING:
		_process_flight(delta)
		return

	if state != State.ROLLING:
		return

	_update_landing_bounce(delta)
	position += velocity * delta
	var rolling_friction := friction
	if is_putting_shot:
		rolling_friction = _get_roll_friction(get_terrain_name())
	velocity = velocity.move_toward(Vector2.ZERO, rolling_friction * delta)

	if velocity.length() <= 1.0:
		velocity = Vector2.ZERO
		state = State.IDLE
		is_putting_shot = false
		stopped.emit()

func _update_landing_bounce(delta: float) -> void:
	if landing_bounce_time >= landing_bounce_duration_current:
		return

	landing_bounce_time += delta
	var progress := clampf(landing_bounce_time / landing_bounce_duration_current, 0.0, 1.0)
	var bounce_height := sin(progress * PI) * landing_bounce_height_current
	ball_sprite.position = base_sprite_position + Vector2(0.0, -bounce_height)
	ball_sprite.scale = base_sprite_scale * (1.0 + bounce_height / maxf(landing_bounce_height, 0.001) * 0.1)
	if progress >= 1.0:
		ball_sprite.position = base_sprite_position
		ball_sprite.scale = base_sprite_scale

func _process_flight(delta: float) -> void:
	flight_time += delta
	var progress := clampf(flight_time / flight_duration, 0.0, 1.0)
	global_position = flight_start.lerp(flight_end, progress)
	var arc_height := sin(progress * PI) * max_arc_height * clampf(flight_power, 0.2, 1.0)
	ball_sprite.position = base_sprite_position + Vector2(0.0, -arc_height)
	ball_sprite.scale = base_sprite_scale * (1.0 + arc_height / max_arc_height * 0.25)
	if progress >= 1.0:
		_land()

func _land() -> void:
	global_position = flight_end
	ball_sprite.position = base_sprite_position
	ball_sprite.scale = base_sprite_scale
	landing_bounce_time = 0.0
	var terrain_name := get_terrain_name()
	if terrain_name.contains("water") or (terrain_name.contains("out") and terrain_name.contains("bounds")):
		global_position = flight_start
		ball_sprite.position = base_sprite_position
		ball_sprite.scale = base_sprite_scale
		velocity = Vector2.ZERO
		state = State.IDLE
		stopped.emit()
		return

	var incoming_speed := predicted_distance(flight_power) / maxf(flight_duration, 0.001)
	var roll_factor := 0.5
	var bounce_factor := 1.0
	friction = 350.0
	if terrain_name == "rough":
		roll_factor = 0.2
		bounce_factor = 0.65
		friction = 600.0
	elif terrain_name == "sand":
		roll_factor = 0.05
		bounce_factor = 0.25
		friction = 900.0
	landing_bounce_height_current = clampf(incoming_speed * 0.02, 1.5, landing_bounce_height) * bounce_factor
	landing_bounce_duration_current = landing_bounce_duration * bounce_factor
	velocity = (flight_end - flight_start).normalized() * incoming_speed * roll_factor
	state = State.ROLLING

func get_terrain_name() -> String:
	var ground_items_terrain := _get_terrain_name_at_position(ground_items_layer)
	if not ground_items_terrain.is_empty():
		return ground_items_terrain

	var ground_terrain := _get_terrain_name_at_position(ground_layer)
	if not ground_terrain.is_empty():
		return ground_terrain

	return "fairway"

func _get_terrain_name_at_position(layer: TileMapLayer) -> String:
	if layer == null:
		return ""

	var cell := layer.local_to_map(layer.to_local(global_position))
	var tile_data := layer.get_cell_tile_data(cell)
	if tile_data == null or tile_data.terrain < 0:
		return ""

	return layer.tile_set.get_terrain_name(0, tile_data.terrain).to_lower()

func _get_roll_friction(terrain_name: String) -> float:
	if terrain_name == "green":
		return green_friction
	if terrain_name == "rough":
		return 600.0
	if terrain_name == "sand":
		return 900.0
	return 350.0

func _is_on_green() -> bool:
	return get_terrain_name() == "green"

func predicted_putt_distance(power_ratio: float) -> float:
	var putt_speed := clampf(power_ratio, 0.0, 1.0) * max_putt_speed
	return putt_speed * putt_speed / (2.0 * maxf(green_friction, 0.001))

func _get_wobble_angle(power_ratio: float, threshold: float = -1.0) -> float:
	if threshold < 0.0:
		threshold = 0.9
		var terrain_name := get_terrain_name()
		if terrain_name == "rough":
			threshold = 0.75
		elif terrain_name == "sand":
			threshold = 0.0

	var over := _get_wobble_over(power_ratio, threshold)
	if over <= 0.0:
		return 0.0

	var amplitude: float = deg_to_rad(wobble_max_angle_deg) * over
	var oscillation: float = sin(Time.get_ticks_msec() / 1000.0 * wobble_frequency)
	return oscillation * amplitude

func _get_wobble_over(power_ratio: float, threshold: float = -1.0) -> float:
	if threshold < 0.0:
		threshold = 0.9
		var terrain_name := get_terrain_name()
		if terrain_name == "rough":
			threshold = 0.55
		elif terrain_name == "sand":
			threshold = 0.0
	return clamp((power_ratio - threshold) / max(0.0001, 1.0 - threshold), 0.0, 1.0)

func launch(direction: Vector2, power_ratio: float) -> void:
	if direction.length_squared() < 0.0001:
		return

	CourseState.register_shot()

	var max_power_ratio := _get_max_shot_power_ratio()
	var shot_power := clampf(power_ratio, 0.0, max_power_ratio)

	is_putting_shot = _is_on_green()
	if is_putting_shot:
		var putt_wobble := _get_wobble_angle(shot_power, 0.4)
		var putt_direction := direction.normalized().rotated(putt_wobble)
		velocity = putt_direction * shot_power * max_putt_speed
		landing_bounce_time = 0.0
		landing_bounce_height_current = 0.0
		landing_bounce_duration_current = 0.0
		ball_sprite.position = base_sprite_position
		ball_sprite.scale = base_sprite_scale
		state = State.ROLLING
		aim_active = false
		aim_power = 0.0
		flight_started.emit(self)
		queue_redraw()
		return

	var wobble := _get_wobble_angle(shot_power)
	var final_direction := direction.normalized().rotated(wobble)
	flight_start = global_position
	flight_end = flight_start + final_direction * predicted_distance(shot_power)
	flight_time = 0.0
	flight_duration = flight_duration_base * clampf(shot_power, 0.35, 1.0)
	flight_power = shot_power
	state = State.FLYING
	aim_active = false
	aim_power = 0.0
	flight_started.emit(self)
	queue_redraw()

func _draw() -> void:
	var bounce_progress := clampf(landing_bounce_time / maxf(landing_bounce_duration_current, 0.001), 0.0, 1.0)
	var bounce_height := sin(bounce_progress * PI) * landing_bounce_height_current
	var shadow_scale := 1.0 - bounce_height / maxf(landing_bounce_height, 0.001) * 0.35
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45 * shadow_scale))
	draw_circle(Vector2(0.0, 5.0), 6.0, Color(0.05, 0.05, 0.05, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if not aim_active:
		return

	var is_putting_preview := _is_on_green()
	var preview_dir := aim_dir.rotated(_get_wobble_angle(aim_power)) if not is_putting_preview else aim_dir.rotated(_get_wobble_angle(aim_power))
	var pull_endpoint := preview_dir * aim_power * max_drag_px
	var color := Color(0.2, 1.0, 0.3)
	if aim_power > 0.5:
		color = Color(1.0, 0.6, 0.2)
	if aim_power > 0.8:
		color = Color(1.0, 0.2, 0.2)

	if is_putting_preview:
		preview_dir = aim_dir.rotated(_get_wobble_angle(aim_power, 0.4))
		draw_line(Vector2.ZERO, preview_dir * predicted_putt_distance(aim_power), color, 2.0)
		return

	var landing_point := preview_dir * predicted_distance(aim_power)
	draw_line(Vector2.ZERO, pull_endpoint, color, 2.0)
	draw_circle(pull_endpoint, 2.5, color)
	draw_arc(landing_point, 8.0, 0.0, TAU, 16, color, 2.0)
	draw_line(landing_point - Vector2(4.0, 4.0), landing_point + Vector2(4.0, 4.0), color, 2.0)
	draw_line(landing_point + Vector2(-4.0, 4.0), landing_point + Vector2(4.0, -4.0), color, 2.0)
