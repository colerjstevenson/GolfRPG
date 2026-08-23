extends Node2D

@onready var ground: TileMapLayer = $ground
@onready var ground_items: TileMapLayer = $ground_items
@onready var follow_camera: Camera2D = $FollowCamera
@onready var player: CharacterBody2D = $Player
@onready var ball: Area2D = $Ball

const CAMERA_ZOOM_MULTIPLIER := 1.15
const SHOT_MODE_ZOOM_MULTIPLIER := 1.5
const AIM_ZOOM_OUT_MULTIPLIER := 0.9
const CAMERA_FOLLOW_SPEED := 10.0

var camera_target: Node2D
var default_zoom: Vector2
var target_zoom: Vector2

func _ready() -> void:
	ball.ground_layer = ground
	ball.ground_items_layer = ground_items
	ball.clicked.connect(player.on_ball_clicked)
	ball.flight_started.connect(_on_flight_started)
	player.shot_mode_entered.connect(_on_shot_mode_entered)
	player.shot_mode_exited.connect(_on_shot_mode_exited)
	player.aim_power_changed.connect(_on_aim_power_changed)
	camera_target = player
	# Area2D input_event only fires once mouse picking is enabled on the viewport.
	get_viewport().physics_object_picking = true
	_set_camera_limits()
	target_zoom = follow_camera.zoom
	default_zoom = target_zoom

func _process(delta: float) -> void:
	if camera_target != null:
		follow_camera.global_position = follow_camera.global_position.lerp(
			camera_target.global_position,
			clampf(delta * CAMERA_FOLLOW_SPEED, 0.0, 1.0)
		)
	follow_camera.zoom = follow_camera.zoom.lerp(
		target_zoom,
		clampf(delta * CAMERA_FOLLOW_SPEED, 0.0, 1.0)
	)

func _on_shot_mode_entered(_ball: Node2D) -> void:
	target_zoom = default_zoom * SHOT_MODE_ZOOM_MULTIPLIER

func _on_shot_mode_exited() -> void:
	camera_target = player
	target_zoom = default_zoom

func _on_flight_started(flight_ball: Node2D) -> void:
	camera_target = flight_ball
	target_zoom = default_zoom * AIM_ZOOM_OUT_MULTIPLIER

func _on_aim_power_changed(power_ratio: float) -> void:
	var zoom_multiplier := lerpf(
		SHOT_MODE_ZOOM_MULTIPLIER,
		AIM_ZOOM_OUT_MULTIPLIER,
		clampf(power_ratio, 0.0, 1.0)
	)
	target_zoom = default_zoom * zoom_multiplier

func _set_camera_limits() -> void:
	var used_rect := ground.get_used_rect()
	var tile_size := Vector2(ground.tile_set.tile_size)
	var map_position := Vector2(used_rect.position) * tile_size
	var map_size := Vector2(used_rect.size) * tile_size

	follow_camera.limit_left = int(map_position.x)
	follow_camera.limit_top = int(map_position.y)
	follow_camera.limit_right = int(map_position.x + map_size.x)
	follow_camera.limit_bottom = int(map_position.y + map_size.y)
	follow_camera.limit_smoothed = true

	var viewport_size := get_viewport_rect().size
	var required_zoom := maxf(1.0, maxf(viewport_size.x / map_size.x, viewport_size.y / map_size.y))
	default_zoom = Vector2.ONE * required_zoom * CAMERA_ZOOM_MULTIPLIER
	follow_camera.zoom = default_zoom
