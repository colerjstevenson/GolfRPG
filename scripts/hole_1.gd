extends Node2D

@onready var ground: TileMapLayer = $ground
@onready var ground_items: TileMapLayer = $ground_items
@onready var follow_camera: Camera2D = $FollowCamera
@onready var player: CharacterBody2D = $Player
@onready var ball: Area2D = $Ball
@onready var hole: Area2D = $Hole
@onready var entrance: Area2D = $entrance
@onready var exit: Area2D = $exit
@onready var fade_overlay: ColorRect = $CanvasLayer/FadeOverlay

const CAMERA_ZOOM_MULTIPLIER := 2
const SHOT_MODE_ZOOM_MULTIPLIER := 1.5
const AIM_ZOOM_OUT_MULTIPLIER := 0.3
const PUTTING_SHOT_MODE_ZOOM_MULTIPLIER := 1.2
const PUTTING_AIM_ZOOM_OUT_MULTIPLIER := 0.9
const CAMERA_FOLLOW_SPEED := 10.0
const HOLE_MAX_ENTRY_SPEED := 120.0
const ENTRY_ZOOM_MULTIPLIER := 1.25
const EXIT_ZOOM_MULTIPLIER := 1.35
const TRANSITION_DURATION := 0.4
const FIRST_HOLE_SCENE_PATH := "res://Scenes/Hole1.tscn"

enum TransitionPhase {
	ENTERING,
	PLAYING,
	EXITING,
}

@export var next_hole_scene: PackedScene

var camera_target: Node2D
var default_zoom: Vector2
var target_zoom: Vector2
var aim_anchor_ball: Node2D
var aim_anchor_screen_position: Vector2
var camera_limit_rect: Rect2i
var transition_phase: int = TransitionPhase.ENTERING
var exit_started: bool = false
var player_entry_start: Vector2

func _ready() -> void:
	ball.ground_layer = ground
	ball.ground_items_layer = ground_items
	ball.clicked.connect(player.on_ball_clicked)
	ball.flight_started.connect(_on_flight_started)
	ball.holed.connect(_on_ball_holed)
	player.shot_mode_entered.connect(_on_shot_mode_entered)
	player.shot_mode_exited.connect(_on_shot_mode_exited)
	player.aim_drag_started.connect(_on_aim_drag_started)
	player.aim_power_changed.connect(_on_aim_power_changed)
	player.scripted_walk_finished.connect(_on_scripted_walk_finished)
	if exit != null:
		exit.input_event.connect(_on_exit_input)
		exit.input_pickable = false
		exit.monitoring = false
	camera_target = player
	get_viewport().physics_object_picking = true
	_set_camera_limits()
	target_zoom = follow_camera.zoom
	default_zoom = target_zoom
	player_entry_start = player.global_position
	player.global_position = entrance.global_position
	if fade_overlay != null:
		fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
		fade_overlay.visible = true
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	target_zoom = default_zoom * ENTRY_ZOOM_MULTIPLIER
	player.scripted_walk_to(player_entry_start)
	_fade_to(0.0, TRANSITION_DURATION)

func _process(delta: float) -> void:
	follow_camera.zoom = follow_camera.zoom.lerp(
		target_zoom,
		clampf(delta * CAMERA_FOLLOW_SPEED, 0.0, 1.0)
	)
	if aim_anchor_ball != null:
		var viewport_center := get_viewport_rect().size * 0.5
		var anchor_offset := (aim_anchor_screen_position - viewport_center) / follow_camera.zoom
		follow_camera.global_position = aim_anchor_ball.global_position - anchor_offset
	elif camera_target != null:
		follow_camera.global_position = follow_camera.global_position.lerp(
			camera_target.global_position,
			clampf(delta * CAMERA_FOLLOW_SPEED, 0.0, 1.0)
		)

func _physics_process(_delta: float) -> void:
	if ball.state == ball.State.ROLLING and ball.velocity.length() <= HOLE_MAX_ENTRY_SPEED:
		if hole.overlaps_area(ball):
			ball.sink(hole.global_position)

func _fade_to(alpha: float, duration: float = TRANSITION_DURATION) -> void:
	if fade_overlay == null:
		return
	fade_overlay.visible = true
	fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", alpha, duration)
	if is_zero_approx(alpha):
		tween.tween_callback(func() -> void:
			fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fade_overlay.visible = false
		)

func _on_ball_holed() -> void:
	if transition_phase != TransitionPhase.PLAYING:
		return
	if exit != null:
		exit.input_pickable = true
		exit.monitoring = true

func _on_exit_input(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if transition_phase != TransitionPhase.PLAYING:
		return
	if exit_started:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	_viewport.set_input_as_handled()
	exit_started = true
	transition_phase = TransitionPhase.EXITING
	player.scripted_walk_to(exit.global_position)
	target_zoom = default_zoom * EXIT_ZOOM_MULTIPLIER

func _on_scripted_walk_finished() -> void:
	if transition_phase == TransitionPhase.ENTERING:
		transition_phase = TransitionPhase.PLAYING
		target_zoom = default_zoom
		_fade_to(0.0, TRANSITION_DURATION)
		return
	if transition_phase == TransitionPhase.EXITING:
		_fade_to(1.0, TRANSITION_DURATION)
		await get_tree().create_timer(TRANSITION_DURATION).timeout
		_transition_to_next_hole()

func _transition_to_next_hole() -> void:
	if next_hole_scene != null:
		get_tree().change_scene_to_packed(next_hole_scene)
		return
	var next_path := _get_next_hole_scene_path()
	if not next_path.is_empty() and ResourceLoader.exists(next_path):
		get_tree().change_scene_to_file(next_path)
		return
	get_tree().change_scene_to_file(FIRST_HOLE_SCENE_PATH)

# Finds "HoleN.tscn" for the current scene and returns "Hole(N+1).tscn"; empty if no number found.
func _get_next_hole_scene_path() -> String:
	var regex := RegEx.new()
	regex.compile("(\\d+)(?=\\.tscn$)")
	var result := regex.search(scene_file_path)
	if result == null:
		return ""
	var next_number := int(result.get_string()) + 1
	return scene_file_path.substr(0, result.get_start()) + str(next_number) + ".tscn"

func _on_shot_mode_entered(shot_ball: Node2D) -> void:
	var zoom_multiplier := SHOT_MODE_ZOOM_MULTIPLIER
	if shot_ball.get_terrain_name() == "green":
		zoom_multiplier = PUTTING_SHOT_MODE_ZOOM_MULTIPLIER
	target_zoom = default_zoom * zoom_multiplier

func _on_shot_mode_exited() -> void:
	_clear_aim_anchor()
	camera_target = player
	target_zoom = default_zoom

func _on_flight_started(flight_ball: Node2D) -> void:
	_clear_aim_anchor()
	camera_target = flight_ball
	var zoom_multiplier := AIM_ZOOM_OUT_MULTIPLIER
	if flight_ball.get_terrain_name() == "green":
		zoom_multiplier = PUTTING_AIM_ZOOM_OUT_MULTIPLIER
	target_zoom = default_zoom * zoom_multiplier

func _on_aim_drag_started(shot_ball: Node2D, screen_position: Vector2) -> void:
	aim_anchor_ball = shot_ball
	aim_anchor_screen_position = screen_position
	follow_camera.limit_left = -1000000000
	follow_camera.limit_top = -1000000000
	follow_camera.limit_right = 1000000000
	follow_camera.limit_bottom = 1000000000

func _clear_aim_anchor() -> void:
	aim_anchor_ball = null
	follow_camera.limit_left = camera_limit_rect.position.x
	follow_camera.limit_top = camera_limit_rect.position.y
	follow_camera.limit_right = camera_limit_rect.end.x
	follow_camera.limit_bottom = camera_limit_rect.end.y

func _on_aim_power_changed(power_ratio: float) -> void:
	var shot_mode_zoom_multiplier := SHOT_MODE_ZOOM_MULTIPLIER
	var aim_zoom_out_multiplier := AIM_ZOOM_OUT_MULTIPLIER
	if ball.get_terrain_name() == "green":
		shot_mode_zoom_multiplier = PUTTING_SHOT_MODE_ZOOM_MULTIPLIER
		aim_zoom_out_multiplier = PUTTING_AIM_ZOOM_OUT_MULTIPLIER
	var zoom_multiplier := lerpf(
		shot_mode_zoom_multiplier,
		aim_zoom_out_multiplier,
		clampf(power_ratio, 0.0, 1.0)
	)
	target_zoom = default_zoom * zoom_multiplier

func _set_camera_limits() -> void:
	var used_rect := ground.get_used_rect()
	var tile_size := Vector2(ground.tile_set.tile_size)
	var map_position := Vector2(used_rect.position) * tile_size
	var map_size := Vector2(used_rect.size) * tile_size
	camera_limit_rect = Rect2i(map_position, map_size)

	follow_camera.limit_left = camera_limit_rect.position.x
	follow_camera.limit_top = camera_limit_rect.position.y
	follow_camera.limit_right = camera_limit_rect.end.x
	follow_camera.limit_bottom = camera_limit_rect.end.y
	follow_camera.limit_smoothed = true

	var viewport_size := get_viewport_rect().size
	var required_zoom := maxf(1.0, maxf(viewport_size.x / map_size.x, viewport_size.y / map_size.y))
	default_zoom = Vector2.ONE * required_zoom * CAMERA_ZOOM_MULTIPLIER
	follow_camera.zoom = default_zoom
