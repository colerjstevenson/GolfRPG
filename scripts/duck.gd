extends CharacterBody2D

enum State { IDLE, WANDER, ALERT, FLEE, SWIM, CHASE }

@export_enum("male", "female", "baby") var type: String = "male"

@export var wander_radius: float = 48.0
@export var wander_speed: float = 18.0
@export var flee_speed: float = 40.0
@export var chase_speed: float = 90.0
@export var alert_radius: float = 70.0
@export var flee_clear_radius: float = 110.0
@export var chase_give_up_radius: float = 160.0
@export var chase_duration: float = 8.0
@export var bump_strength: float = 190.0
@export var bump_cooldown: float = 1.0
@export var slap_duration: float = 0.35
@export var min_idle_time: float = 4.0
@export var max_idle_time: float = 10.0
@export var min_idle_action_interval: float = 5.0
@export var max_idle_action_interval: float = 9.0
@export var alert_duration: float = 0.4
@export var ground_layer: TileMapLayer
@export var ground_items_layer: TileMapLayer

const BABY_SCALE := Vector2(0.6, 0.6)
const RANDOM_ACTION_DURATION := 1.6

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var state: int = State.WANDER
var home_position: Vector2
var _wander_target: Vector2
var _has_wander_target: bool = false
var _idle_timer: float = 0.0
var _alert_timer: float = 0.0
var _bump_cooldown_timer: float = 0.0
var _chase_timer: float = 0.0
var _slap_timer: float = 0.0
var _random_action_timer: float = 0.0
var _random_action_lock: float = 0.0
var _player: Node2D = null


func _ready() -> void:
	collision_mask = 0
	home_position = global_position
	if ground_layer == null:
		ground_layer = get_parent().get_node_or_null("ground") as TileMapLayer
	if ground_items_layer == null:
		ground_items_layer = get_parent().get_node_or_null("ground_items") as TileMapLayer

	if type == "baby":
		scale = BABY_SCALE

	add_to_group(&"duck")
	_idle_timer = randf_range(min_idle_time, max_idle_time)
	_random_action_timer = randf_range(min_idle_action_interval, max_idle_action_interval)

	state = State.WANDER
	_update_idle_anim()


func set_course_mode(is_community: bool, active_ground_items: TileMapLayer) -> void:
	ground_items_layer = active_ground_items
	visible = is_community
	modulate.a = 1.0
	process_mode = Node.PROCESS_MODE_INHERIT if is_community else Node.PROCESS_MODE_DISABLED


func prepare_flyover_reveal(active_ground_items: TileMapLayer) -> void:
	ground_items_layer = active_ground_items
	visible = true
	modulate.a = 0.0
	process_mode = Node.PROCESS_MODE_DISABLED


func reveal_from_flyover(duration: float = 0.28) -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	var reveal_tween := create_tween()
	reveal_tween.set_trans(Tween.TRANS_SINE)
	reveal_tween.set_ease(Tween.EASE_OUT)
	reveal_tween.tween_property(self, "modulate:a", 1.0, duration)


func knock_down() -> void:
	if state == State.CHASE or _bump_cooldown_timer > 0.0:
		return
	state = State.CHASE
	_chase_timer = chase_duration
	_slap_timer = slap_duration
	_has_wander_target = false
	_random_action_lock = 0.0
	velocity = Vector2.ZERO
	_play("slap")


func _physics_process(delta: float) -> void:
	if _bump_cooldown_timer > 0.0:
		_bump_cooldown_timer -= delta

	match state:
		State.ALERT:
			_process_alert(delta)
		State.FLEE:
			_process_flee(delta)
		State.CHASE:
			_process_chase(delta)
		_:
			_process_wander(delta)


func _process_wander(delta: float) -> void:
	var terrain_name := _get_terrain_name()
	var player := _get_player()
	if player != null and global_position.distance_to(player.global_position) <= alert_radius:
		state = State.ALERT
		_alert_timer = alert_duration
		_has_wander_target = false
		_play("swim" if _is_water(terrain_name) else "uneasy")
		velocity = Vector2.ZERO
		_set_facing(player.global_position - global_position)
		return

	if _has_wander_target:
		if not _move_toward(_wander_target, wander_speed):
			_has_wander_target = false
			velocity = Vector2.ZERO
			_update_idle_anim()
			_idle_timer = randf_range(min_idle_time, max_idle_time)
			_random_action_timer = randf_range(min_idle_action_interval, max_idle_action_interval)
		return

	_random_action_timer -= delta
	if _random_action_lock > 0.0:
		_random_action_lock -= delta
		if _random_action_lock <= 0.0:
			_update_idle_anim()
		return

	_idle_timer -= delta
	if _idle_timer > 0.0:
		if _random_action_timer <= 0.0:
			_run_random_idle_action()
		return

	var new_target := _pick_wander_target()
	if new_target != home_position or global_position == home_position:
		_wander_target = new_target
		_has_wander_target = true
	else:
		_idle_timer = randf_range(min_idle_time, max_idle_time)


func _process_alert(delta: float) -> void:
	_alert_timer -= delta
	if _alert_timer <= 0.0:
		state = State.FLEE


func _process_flee(_delta: float) -> void:
	var player := _get_player()
	if player == null:
		state = State.WANDER
		return

	var distance := global_position.distance_to(player.global_position)
	if distance >= flee_clear_radius:
		state = State.WANDER
		velocity = Vector2.ZERO
		_update_idle_anim()
		_idle_timer = randf_range(min_idle_time, max_idle_time)
		return

	var away_dir := (global_position - player.global_position).normalized()
	var flee_target := global_position + away_dir * wander_radius
	if _is_out_of_bounds(_terrain_name_at(flee_target)):
		velocity = Vector2.ZERO
		return

	_move_toward(flee_target, flee_speed, "run")


func _process_chase(delta: float) -> void:
	var player := _get_player()
	if player == null:
		_end_chase()
		return

	if _slap_timer > 0.0:
		_slap_timer -= delta
		velocity = Vector2.ZERO
		_play("slap")
		_set_facing(player.global_position - global_position)
		return

	_chase_timer -= delta
	var distance := global_position.distance_to(player.global_position)
	# Only give up on distance once the angry-chase window has elapsed, otherwise a duck
	# hit by a long shot would quit on the same frame it was knocked down.
	if _chase_timer <= 0.0 and distance > chase_give_up_radius:
		_end_chase()
		return

	var direction := (player.global_position - global_position)
	if direction.length() > 0.0001:
		direction = direction.normalized()
		var in_water := _is_water(_get_terrain_name())
		var speed := chase_speed * 0.7 if in_water else chase_speed
		velocity = direction * speed
		_play("swim" if in_water else "run")
		_set_facing(direction)
	move_and_slide()

	if _bump_cooldown_timer <= 0.0:
		if distance < 18.0:
			if player.has_method("apply_knockback"):
				player.apply_knockback(direction, bump_strength)
			_bump_cooldown_timer = bump_cooldown
			_slap_timer = slap_duration
		else:
			for i in get_slide_collision_count():
				var collider := get_slide_collision(i).get_collider()
				if collider is Node and (collider as Node).is_in_group(&"player"):
					(collider as Node).apply_knockback(direction, bump_strength)
					_bump_cooldown_timer = bump_cooldown
					_slap_timer = slap_duration
					break


func _end_chase() -> void:
	state = State.WANDER
	_chase_timer = 0.0
	_slap_timer = 0.0
	_has_wander_target = false
	velocity = Vector2.ZERO
	_idle_timer = randf_range(min_idle_time, max_idle_time)
	_update_idle_anim()


func _process_swim(delta: float) -> void:
	_process_wander(delta)


func _move_toward(target: Vector2, speed: float, anim_name: String = "walk_1") -> bool:
	var to_target := target - global_position
	var distance := to_target.length()
	if distance < 1.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return false

	var direction := to_target / distance
	var in_water := _is_water(_get_terrain_name())
	var current_speed := speed * 0.7 if in_water else speed
	var current_anim := "swim" if in_water else anim_name

	velocity = direction * current_speed
	_set_facing(direction)
	_play(current_anim)
	move_and_slide()
	return true


func _pick_wander_target() -> Vector2:
	for _attempt in 10:
		var candidate := home_position + Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		var terrain_name := _terrain_name_at(candidate)
		if not _is_out_of_bounds(terrain_name):
			return candidate
	return home_position


func _run_random_idle_action() -> void:
	_random_action_timer = randf_range(min_idle_action_interval, max_idle_action_interval)
	if _is_water(_get_terrain_name()):
		return

	var choices: Array[String] = ["blink", "sit", "sleep", "none", "none"]

	var choice: String = choices[randi() % choices.size()]
	if choice == "none":
		return

	_random_action_lock = RANDOM_ACTION_DURATION
	_play(choice)


func _update_idle_anim() -> void:
	if _is_water(_get_terrain_name()):
		_play("swim")
	else:
		_play("idle")


func _get_player() -> Node2D:
	if _player == null:
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
	return _player


func _anim(name: String) -> StringName:
	return StringName("%s_%s" % [type, name])


func _has_anim(name: String) -> bool:
	return animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(_anim(name))


func _play(name: String) -> void:
	var anim_name := _anim(name)
	if not _has_anim(name):
		anim_name = _anim("idle")
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)


func _set_facing(direction: Vector2) -> void:
	if absf(direction.x) > 0.01:
		animated_sprite.flip_h = direction.x > 0.0


func _get_terrain_name() -> String:
	return _terrain_name_at(global_position)


func _terrain_name_at(sample_position: Vector2) -> String:
	var ground_items_terrain := _terrain_name_at_layer(sample_position, ground_items_layer)
	if not ground_items_terrain.is_empty():
		return ground_items_terrain

	var ground_terrain := _terrain_name_at_layer(sample_position, ground_layer)
	if not ground_terrain.is_empty():
		return ground_terrain

	return "fairway"


func _terrain_name_at_layer(sample_position: Vector2, layer: TileMapLayer) -> String:
	if layer == null:
		return ""

	var cell := layer.local_to_map(layer.to_local(sample_position))
	var tile_data := layer.get_cell_tile_data(cell)
	if tile_data == null or tile_data.terrain < 0:
		return ""

	return layer.tile_set.get_terrain_name(0, tile_data.terrain).to_lower()


func _is_water(terrain_name: String) -> bool:
	return terrain_name.contains("water")


func _is_out_of_bounds(terrain_name: String) -> bool:
	return terrain_name.contains("out") and terrain_name.contains("bounds")
