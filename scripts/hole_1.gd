extends Node2D

@onready var ground: TileMapLayer = $ground
@onready var tree: TileMapLayer = get_node_or_null("trees") as TileMapLayer
@onready var private_ground_items: TileMapLayer = $ground_items_private
@onready var community_ground_items: TileMapLayer = $ground_items_community
@onready var follow_camera: Camera2D = $FollowCamera
@onready var player: CharacterBody2D = $Player
@onready var ball: Area2D = $Ball
@onready var hole: Area2D = $Hole
@onready var entrance: Area2D = $entrance
@onready var exit: Area2D = $exit
@onready var fade_overlay: ColorRect = $HUD/FadeOverlay
@onready var dialog: TextureRect = $HUD/Dialog
@onready var rake_button: TextureButton = %Rake
@onready var private_overlay: ColorRect = $HUD/PrivateOverlay

const BASE_CAMERA_ZOOM := 2.0
const SHOT_MODE_ZOOM_MULTIPLIER := 1.5
const AIM_ZOOM_OUT_MULTIPLIER := 0.3
const PUTTING_SHOT_MODE_ZOOM_MULTIPLIER := 1.2
const PUTTING_AIM_ZOOM_OUT_MULTIPLIER := 0.5
const CAMERA_FOLLOW_SPEED := 10.0
const HOLE_MAX_ENTRY_SPEED := 120.0
const ENTRY_ZOOM_MULTIPLIER := 1.25
const EXIT_ZOOM_MULTIPLIER := 1.35
const TRANSITION_DURATION := 0.4
const EXIT_STOP_DISTANCE := 72.0
const FLYOVER_ZOOM_MULTIPLIER := 0.65
const FLYOVER_PAN_DURATION := 7.0
const FLYOVER_REVEAL_LEAD := 0.24
const FLYOVER_LAYER_FADE_WIDTH := 0.16
const FLYOVER_SPARKLE_INTERVAL := 0.022
const ROUGH_DETAIL_CHANCE := 0.4
const FLYOVER_ROUGH_DETAILS_PER_FRAME := 5
const FIRST_HOLE_SCENE_PATH := "res://Scenes/Hole1.tscn"
const END_SCENE_PATH := "res://Scenes/End.tscn"
const NPC_DIALOG_ZOOM_MULTIPLIER := 2.2
const FLYOVER_SPARKLES_SCRIPT := preload("res://scripts/flyover_sparkles.gd")
# Fraction of the viewport the NPC is pinned to while talking, so they sit large near the top.
const NPC_SCREEN_ANCHOR_RATIO := Vector2(0.5, 0.14)
const NPC_STAND_DISTANCE := 28.0

enum TransitionPhase {
	ENTERING,
	PLAYING,
	TRANSFORMING,
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
var footprint_container: Node2D
var pending_npc: Node2D = null
var focus_anchor_node: Node2D
var focus_anchor_screen_position: Vector2
var ground_items: TileMapLayer
var private_overlay_alpha: float = 0.0
var rough_details_added: bool = false
var flyover_anchor: Node2D
var flyover_rough_cells: Array[Dictionary] = []
var next_flyover_rough_index: int = 0
var flyover_ducks: Array[Node2D] = []
var next_flyover_duck_index: int = 0
var flyover_sparkles: FlyoverSparkles
var next_flyover_sparkle_time: float = 0.0

func _ready() -> void:
	CourseState.reset_hole()
	_ensure_stroke_hud()
	private_overlay_alpha = private_overlay.color.a
	flyover_anchor = Node2D.new()
	flyover_anchor.name = "FlyoverAnchor"
	flyover_anchor.global_position = Vector2(camera_limit_rect.get_center())
	add_child(flyover_anchor)

	footprint_container = Node2D.new()
	footprint_container.name = "Footprints"
	footprint_container.z_index = 1
	add_child(footprint_container)

	ball.ground_layer = ground
	ball.tree_layer = tree
	player.ground_layer = ground
	player.tree_layer = tree
	player.footprint_parent = footprint_container
	ball.clicked.connect(player.on_ball_clicked)
	ball.flight_started.connect(_on_flight_started)
	ball.holed.connect(_on_ball_holed)
	player.shot_mode_entered.connect(_on_shot_mode_entered)
	player.shot_mode_exited.connect(_on_shot_mode_exited)
	player.aim_drag_started.connect(_on_aim_drag_started)
	player.aim_power_changed.connect(_on_aim_power_changed)
	player.scripted_walk_finished.connect(_on_scripted_walk_finished)
	if dialog != null:
		dialog.dialog_closed.connect(_on_dialog_closed)
		dialog.answer_recorded.connect(_on_answer_recorded)
	_connect_npcs()
	CourseState.register_hole_question_count(_get_hole_number(), _get_question_npc_count())
	if rake_button != null:
		rake_button.pressed.connect(_on_rake_pressed)
	if exit != null:
		exit.input_event.connect(_on_exit_input)
		exit.input_pickable = false
		exit.monitoring = false
	camera_target = player
	get_viewport().physics_object_picking = true
	_set_camera_limits()
	flyover_anchor.global_position = Vector2(camera_limit_rect.get_center())
	target_zoom = follow_camera.zoom
	default_zoom = target_zoom
	player_entry_start = player.global_position
	player.global_position = entrance.global_position
	_apply_course_mode(CourseState.is_hole_transformed(_get_hole_number()))
	if fade_overlay != null:
		fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
		fade_overlay.visible = true
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	target_zoom = default_zoom * ENTRY_ZOOM_MULTIPLIER
	player.scripted_walk_to(player_entry_start)
	_fade_to(0.0, TRANSITION_DURATION)

func _process(delta: float) -> void:
	_update_stroke_hud()
	follow_camera.zoom = follow_camera.zoom.lerp(
		target_zoom,
		clampf(delta * CAMERA_FOLLOW_SPEED, 0.0, 1.0)
	)
	if aim_anchor_ball != null:
		var viewport_center := get_viewport_rect().size * 0.5
		var anchor_offset := (aim_anchor_screen_position - viewport_center) / follow_camera.zoom
		follow_camera.global_position = aim_anchor_ball.global_position - anchor_offset
	elif focus_anchor_node != null:
		var focus_center := get_viewport_rect().size * 0.5
		var focus_offset := (focus_anchor_screen_position - focus_center) / follow_camera.zoom
		follow_camera.global_position = follow_camera.global_position.lerp(
			focus_anchor_node.global_position - focus_offset,
			clampf(delta * CAMERA_FOLLOW_SPEED, 0.0, 1.0)
		)
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

func _on_rake_pressed() -> void:
	for footprint in footprint_container.get_children():
		footprint.queue_free()

func _on_exit_input(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if transition_phase != TransitionPhase.PLAYING:
		return
	if exit_started:
		return
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		return
	_viewport.set_input_as_handled()
	exit_started = true
	if CourseState.is_hole_ready_to_transform(_get_hole_number()):
		transition_phase = TransitionPhase.TRANSFORMING
		_set_world_input_enabled(false)
		player.set_input_locked(true)
		var exit_direction := (exit.global_position - player.global_position).normalized()
		player.scripted_walk_to(exit.global_position - exit_direction * EXIT_STOP_DISTANCE)
		return
	transition_phase = TransitionPhase.EXITING
	player.scripted_walk_to(exit.global_position)
	target_zoom = default_zoom * EXIT_ZOOM_MULTIPLIER

func _on_scripted_walk_finished() -> void:
	if transition_phase == TransitionPhase.ENTERING:
		transition_phase = TransitionPhase.PLAYING
		target_zoom = default_zoom
		_fade_to(0.0, TRANSITION_DURATION)
		return
	if transition_phase == TransitionPhase.TRANSFORMING:
		_run_exit_transformation()
		return
	if transition_phase == TransitionPhase.EXITING:
		_fade_to(1.0, TRANSITION_DURATION)
		await get_tree().create_timer(TRANSITION_DURATION).timeout
		_transition_to_next_hole()
		return
	if pending_npc != null:
		_start_dialog(pending_npc)


func _run_exit_transformation() -> void:
	_remove_camera_limits()
	flyover_anchor.global_position = entrance.global_position
	follow_camera.global_position = entrance.global_position
	focus_anchor_node = flyover_anchor
	focus_anchor_screen_position = get_viewport_rect().size * 0.5
	camera_target = null
	target_zoom = default_zoom * FLYOVER_ZOOM_MULTIPLIER
	_prepare_flyover_course_mode()
	var pan_tween := create_tween()
	pan_tween.set_parallel(true)
	pan_tween.set_trans(Tween.TRANS_SINE)
	pan_tween.set_ease(Tween.EASE_IN_OUT)
	pan_tween.tween_property(flyover_anchor, "global_position", exit.global_position, FLYOVER_PAN_DURATION)
	pan_tween.tween_method(_update_flyover_visuals, 0.0, 1.0, FLYOVER_PAN_DURATION)
	await pan_tween.finished
	_update_flyover_visuals(1.0)
	_finish_flyover_course_mode()
	CourseState.transform_hole(_get_hole_number())
	focus_anchor_node = null
	_restore_camera_limits()
	camera_target = player
	target_zoom = default_zoom * EXIT_ZOOM_MULTIPLIER
	transition_phase = TransitionPhase.EXITING
	player.set_input_locked(false)
	player.scripted_walk_to(exit.global_position)

func _connect_npcs() -> void:
	for child in get_children():
		if child.has_signal("clicked") and child.has_method("face_forward"):
			child.connect("clicked", _on_npc_clicked)


func _get_question_npc_count() -> int:
	var question_npc_count := 0
	for child in get_children():
		if not (child.has_signal("clicked") and child.has_method("face_forward")):
			continue
		var prompt: Variant = child.get("prompt")
		if prompt is String and not prompt.strip_edges().is_empty():
			continue
		question_npc_count += 1
	return question_npc_count


func _on_answer_recorded(_hole_name: String) -> void:
	CourseState.register_hole_answer(_get_hole_number())

func _on_npc_clicked(npc: Node2D) -> void:
	if transition_phase != TransitionPhase.PLAYING:
		return
	if pending_npc != null or (dialog != null and dialog.is_open()):
		return
	if npc.has_talked_to:
		return
	if player.state != player.State.FREE:
		return

	pending_npc = npc
	npc.face_forward()
	_set_world_input_enabled(false)

	var to_player := player.global_position - npc.global_position
	var offset_dir := to_player.normalized() if to_player.length() > 0.0001 else Vector2.DOWN
	player.scripted_walk_to(npc.global_position + offset_dir * NPC_STAND_DISTANCE)

func _start_dialog(npc: Node2D) -> void:
	player.face_towards(npc.global_position)
	player.set_input_locked(true)
	_remove_camera_limits()
	focus_anchor_node = npc
	focus_anchor_screen_position = get_viewport_rect().size * NPC_SCREEN_ANCHOR_RATIO
	target_zoom = default_zoom * NPC_DIALOG_ZOOM_MULTIPLIER
	dialog.open_for(npc)

func _on_dialog_closed(npc: Node2D) -> void:
	focus_anchor_node = null
	_restore_camera_limits()
	camera_target = player
	target_zoom = default_zoom
	player.set_input_locked(false)
	_set_world_input_enabled(true)
	pending_npc = null
	if npc != null:
		npc.has_talked_to = true
		if npc.has_method("resume_after_dialog"):
			npc.resume_after_dialog()

func _set_world_input_enabled(enabled: bool) -> void:
	ball.input_pickable = enabled
	if rake_button != null:
		rake_button.disabled = not enabled


func _apply_course_mode(is_community: bool) -> void:
	private_ground_items.visible = not is_community
	community_ground_items.visible = is_community
	private_ground_items.modulate.a = 1.0
	community_ground_items.modulate.a = 1.0
	ground_items = community_ground_items if is_community else private_ground_items
	ball.ground_items_layer = ground_items
	player.ground_items_layer = ground_items
	for child in get_children():
		if child.has_method("set_course_mode"):
			child.set_course_mode(is_community, ground_items)
	if is_community and not rough_details_added:
		_add_rough_details()
		rough_details_added = true
	if private_overlay == null:
		return
	var remaining_private_ratio := 1.0 - float(CourseState.get_transformed_hole_count()) / float(CourseState.TOTAL_HOLES)
	private_overlay.color.a = private_overlay_alpha * maxf(remaining_private_ratio, 0.0)
	private_overlay.visible = private_overlay.color.a > 0.0


func _prepare_flyover_course_mode() -> void:
	private_ground_items.visible = true
	private_ground_items.modulate.a = 1.0
	community_ground_items.visible = true
	community_ground_items.modulate.a = 0.0
	ground_items = private_ground_items
	ball.ground_items_layer = ground_items
	player.ground_items_layer = ground_items
	_prepare_flyover_rough_details()
	_prepare_flyover_ducks()
	if private_overlay != null:
		private_overlay.visible = true
		private_overlay.color.a = private_overlay_alpha * _get_current_private_ratio()
	flyover_sparkles = FLYOVER_SPARKLES_SCRIPT.new() as FlyoverSparkles
	$HUD.add_child(flyover_sparkles)
	next_flyover_sparkle_time = 0.0


func _update_flyover_visuals(progress: float) -> void:
	var reveal_progress := clampf(progress + FLYOVER_REVEAL_LEAD, 0.0, 1.0)
	var layer_progress := smoothstep(0.0, 1.0, (reveal_progress + FLYOVER_LAYER_FADE_WIDTH) / (1.0 + FLYOVER_LAYER_FADE_WIDTH * 2.0))
	private_ground_items.modulate.a = 1.0 - layer_progress
	community_ground_items.modulate.a = layer_progress
	if private_overlay != null:
		private_overlay.color.a = lerpf(
			private_overlay_alpha * _get_current_private_ratio(),
			private_overlay_alpha * _get_next_private_ratio(),
			layer_progress
		)
	_reveal_flyover_rough_details(reveal_progress)
	_reveal_flyover_ducks(reveal_progress)
	if flyover_sparkles != null and Time.get_ticks_msec() * 0.001 >= next_flyover_sparkle_time:
		flyover_sparkles.emit_fall(get_viewport_rect().size)
		next_flyover_sparkle_time = Time.get_ticks_msec() * 0.001 + FLYOVER_SPARKLE_INTERVAL


func _finish_flyover_course_mode() -> void:
	private_ground_items.visible = false
	private_ground_items.modulate.a = 1.0
	community_ground_items.visible = true
	community_ground_items.modulate.a = 1.0
	ground_items = community_ground_items
	ball.ground_items_layer = ground_items
	player.ground_items_layer = ground_items
	while next_flyover_rough_index < flyover_rough_cells.size():
		_apply_next_flyover_rough_detail()
	rough_details_added = true
	if private_overlay != null:
		private_overlay.color.a = private_overlay_alpha * _get_next_private_ratio()
		private_overlay.visible = private_overlay.color.a > 0.0
	if flyover_sparkles != null:
		flyover_sparkles.finish()
		flyover_sparkles = null


func _prepare_flyover_rough_details() -> void:
	flyover_rough_cells.clear()
	next_flyover_rough_index = 0
	var detail_cells := _collect_rough_detail_cells()
	if detail_cells.is_empty():
		return
	for cell_position in ground.get_used_cells():
		var tile_data := ground.get_cell_tile_data(cell_position)
		if tile_data == null or tile_data.get_custom_data("rough") != true or randf() >= ROUGH_DETAIL_CHANCE:
			continue
		var detail_cell: Dictionary = detail_cells[randi() % detail_cells.size()]
		flyover_rough_cells.append({
			"cell_position": cell_position,
			"detail_cell": detail_cell,
			"progress": _get_flyover_progress(ground.to_global(ground.map_to_local(cell_position))),
		})
	flyover_rough_cells.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return first["progress"] < second["progress"]
	)


func _reveal_flyover_rough_details(progress: float) -> void:
	var revealed_count := 0
	while next_flyover_rough_index < flyover_rough_cells.size() and revealed_count < FLYOVER_ROUGH_DETAILS_PER_FRAME:
		var reveal_cell := flyover_rough_cells[next_flyover_rough_index]
		if reveal_cell["progress"] > progress:
			return
		_apply_next_flyover_rough_detail()
		revealed_count += 1


func _apply_next_flyover_rough_detail() -> void:
	var reveal_cell := flyover_rough_cells[next_flyover_rough_index]
	var cell_position: Vector2i = reveal_cell["cell_position"]
	var detail_cell: Dictionary = reveal_cell["detail_cell"]
	ground.set_cell(cell_position, detail_cell["source_id"], detail_cell["atlas_coords"], detail_cell["alternative_tile"])
	next_flyover_rough_index += 1


func _prepare_flyover_ducks() -> void:
	flyover_ducks.clear()
	next_flyover_duck_index = 0
	for child in get_children():
		if child is Node2D and child.has_method("prepare_flyover_reveal"):
			child.prepare_flyover_reveal(community_ground_items)
			flyover_ducks.append(child)
	flyover_ducks.sort_custom(func(first: Node2D, second: Node2D) -> bool:
		return _get_flyover_progress(first.global_position) < _get_flyover_progress(second.global_position)
	)


func _reveal_flyover_ducks(progress: float) -> void:
	while next_flyover_duck_index < flyover_ducks.size():
		var duck := flyover_ducks[next_flyover_duck_index]
		if _get_flyover_progress(duck.global_position) > progress:
			return
		duck.reveal_from_flyover()
		next_flyover_duck_index += 1


func _get_flyover_progress(world_position: Vector2) -> float:
	var travel := exit.global_position - entrance.global_position
	var travel_length_squared := travel.length_squared()
	if is_zero_approx(travel_length_squared):
		return 1.0
	return clampf((world_position - entrance.global_position).dot(travel) / travel_length_squared, 0.0, 1.0)


func _get_current_private_ratio() -> float:
	return maxf(1.0 - float(CourseState.get_transformed_hole_count()) / float(CourseState.TOTAL_HOLES), 0.0)


func _get_next_private_ratio() -> float:
	return maxf(1.0 - float(CourseState.get_transformed_hole_count() + 1) / float(CourseState.TOTAL_HOLES), 0.0)

func _ensure_stroke_hud() -> void:
	var canvas_layer := get_node_or_null("HUD") as CanvasLayer
	if canvas_layer == null:
		return

	var hud := canvas_layer.get_node_or_null("StrokeHud") as Label
	if hud == null:
		hud = Label.new()
		hud.name = "StrokeHud"
		hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hud.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hud.text = "Hole 1: 0 | Total: 0"
		var stroke_font := load("res://assets/fonts/Delicatus.ttf") as FontFile
		if stroke_font != null:
			hud.add_theme_font_override("font", stroke_font)
		hud.add_theme_font_size_override("font_size", 20)
		hud.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		hud.position = Vector2(0.0, 18.0)
		hud.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		hud.offset_left = -180
		hud.offset_top = 16
		hud.offset_right = -18
		hud.offset_bottom = 52
		canvas_layer.add_child(hud)
	_update_stroke_hud()

func _update_stroke_hud() -> void:
	var canvas_layer := get_node_or_null("HUD") as CanvasLayer
	if canvas_layer == null:
		return
	var hud := canvas_layer.get_node_or_null("StrokeHud") as Label
	if hud == null:
		return
	var hole_number := _get_hole_number()
	hud.text = "Hole %s: %d | Total: %d" % [str(hole_number), CourseState.hole_strokes, CourseState.total_strokes]

func _get_hole_number() -> int:
	var regex := RegEx.new()
	regex.compile("(\\d+)(?=\\.tscn$)")
	var result := regex.search(scene_file_path)
	if result == null:
		return 1
	return int(result.get_string())

func _transition_to_next_hole() -> void:
	_tally_hole_results()
	if scene_file_path.ends_with("Start.tscn"):
		get_tree().change_scene_to_file(FIRST_HOLE_SCENE_PATH)
		return
	if next_hole_scene != null:
		get_tree().change_scene_to_packed(next_hole_scene)
		return
	var next_path := _get_next_hole_scene_path()
	if not next_path.is_empty() and ResourceLoader.exists(next_path):
		get_tree().change_scene_to_file(next_path)
		return
	get_tree().change_scene_to_file(END_SCENE_PATH)

## Records NPCs never talked to and whether footprints were left unraked, for the end-of-round score.
func _tally_hole_results() -> void:
	var missed_count := 0
	for child in get_children():
		if child.has_signal("clicked") and child.has_method("face_forward"):
			if child.get("has_talked_to") != true:
				missed_count += 1
	var bunker_unswept := footprint_container != null and footprint_container.get_child_count() > 0
	CourseState.register_hole_results(missed_count, bunker_unswept)

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
	_remove_camera_limits()

func _clear_aim_anchor() -> void:
	aim_anchor_ball = null
	_restore_camera_limits()

func _remove_camera_limits() -> void:
	follow_camera.limit_left = -1000000000
	follow_camera.limit_top = -1000000000
	follow_camera.limit_right = 1000000000
	follow_camera.limit_bottom = 1000000000

func _restore_camera_limits() -> void:
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

	default_zoom = Vector2.ONE * BASE_CAMERA_ZOOM
	follow_camera.zoom = default_zoom



func _collect_rough_detail_cells() -> Array[Dictionary]:
	var detail_cells: Array[Dictionary] = []
	for source_index in ground.tile_set.get_source_count():
		var source_id := ground.tile_set.get_source_id(source_index)
		var atlas_source := ground.tile_set.get_source(source_id) as TileSetAtlasSource
		if atlas_source == null:
			continue
		for tile_index in atlas_source.get_tiles_count():
			var atlas_coords := atlas_source.get_tile_id(tile_index)
			for alternative_tile in atlas_source.get_alternative_tiles_count(atlas_coords):
				var alternative_id := atlas_source.get_alternative_tile_id(atlas_coords, alternative_tile)
				var tile_data := atlas_source.get_tile_data(atlas_coords, alternative_id)
				if tile_data.get_custom_data("rough details"):
					detail_cells.append({
						"source_id": source_id,
						"atlas_coords": atlas_coords,
						"alternative_tile": alternative_id,
					})
	return detail_cells

func _add_rough_details() -> void:
	var detail_chance := 0.4
	var detail_cells = _collect_rough_detail_cells()
	if detail_cells.is_empty():
		return

	#swap out some of the rough tiles for rough detail tiles
	for cell_position in ground.get_used_cells():
		var tile_data := ground.get_cell_tile_data(cell_position)
		if tile_data == null:
			continue

		if tile_data.get_custom_data("rough") == true and randf() < detail_chance:
			var cell = detail_cells[randi() % detail_cells.size()]
			ground.set_cell(cell_position, cell["source_id"], cell["atlas_coords"], cell["alternative_tile"])
