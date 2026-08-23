@tool
extends EditorPlugin

const TerrainToolbar := preload("res://addons/moreterraintools/terrain_toolbar.gd")
const ShapeCells := preload("res://addons/moreterraintools/shape_cells.gd")

var toolbar: HBoxContainer
var current_layer: TileMapLayer
var stroke_points: PackedVector2Array = []
var stroke_active := false
var last_mouse_position := Vector2.ZERO


func _enter_tree() -> void:
	toolbar = TerrainToolbar.new()
	toolbar.visible = false
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	toolbar.tool_changed.connect(_on_tool_changed)
	toolbar.terrain_changed.connect(_refresh_layer_target)


func _exit_tree() -> void:
	if toolbar != null:
		remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, toolbar)
		toolbar.queue_free()
		toolbar = null
	current_layer = null
	stroke_points.clear()
	stroke_active = false


func _handles(object: Variant) -> bool:
	return object is TileMapLayer


func _edit(object: Variant) -> void:
	if object is TileMapLayer:
		current_layer = object
		if toolbar != null:
			toolbar.set_layer(current_layer)
		return
	current_layer = null
	if toolbar != null:
		toolbar.set_layer(null)


func _make_visible(visible: bool) -> void:
	if toolbar == null:
		return
	toolbar.visible = visible and current_layer != null
	if not visible:
		stroke_points.clear()
		stroke_active = false
		if toolbar != null:
			toolbar.set_tool("off")


func _forward_canvas_gui_input(event: InputEvent) -> bool:
	if toolbar == null or current_layer == null:
		return false

	var tool_name: StringName = toolbar.get_tool()
	if tool_name == "off":
		return false

	var local_position: Variant = _get_local_mouse_position(event)
	if local_position == null:
		return false

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var is_erase := mouse_event.button_index == MOUSE_BUTTON_RIGHT
		if mouse_event.pressed:
			if tool_name == "circle":
				stroke_active = true
				last_mouse_position = local_position
				_commit_circle(local_position, is_erase)
				return true
			if tool_name == "lasso":
				stroke_active = true
				stroke_points.clear()
				stroke_points.append(local_position)
				last_mouse_position = local_position
				update_overlays()
				return true
		return false

	if event is InputEventMouseButton and not event.pressed:
		var mouse_event := event as InputEventMouseButton
		var is_erase := mouse_event.button_index == MOUSE_BUTTON_RIGHT
		if tool_name == "lasso":
			if stroke_active and stroke_points.size() >= 3:
				stroke_points.append(stroke_points[0])
				_commit_polygon(stroke_points, is_erase)
			stroke_points.clear()
			stroke_active = false
			update_overlays()
			return true
		if tool_name == "circle":
			stroke_active = false
			return true
		return false

	if event is InputEventMouseMotion and stroke_active:
		if tool_name == "lasso":
			var distance: float = local_position.distance_to(last_mouse_position)
			if distance > 2.0:
				stroke_points.append(local_position)
				last_mouse_position = local_position
				update_overlays()
			return true
		return false

	return false


func _forward_canvas_draw_over_viewport(overlay: Control) -> void:
	if current_layer == null or toolbar == null:
		return
	if toolbar.get_tool() == "off":
		return

	var color := Color(0.35, 0.8, 1.0, 0.85)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		color = Color(1.0, 0.3, 0.3, 0.85)

	if toolbar.get_tool() == "circle":
		var mouse_position: Vector2 = get_editor_interface().get_inspector().get_viewport().get_mouse_position()
		var local_position: Variant = _screen_to_layer_local(mouse_position)
		if local_position == null:
			return
		var radius: int = toolbar.get_radius()
		var circle_points: PackedVector2Array = PackedVector2Array()
		for i in range(0, 360, 8):
			var angle: float = deg_to_rad(float(i))
			var point: Vector2 = local_position + Vector2(cos(angle), sin(angle)) * radius * current_layer.tile_set.tile_size.x
			circle_points.append(point)
		if circle_points.size() > 1:
			overlay.draw_polyline(circle_points, color, 2.0, true)
		return

	if toolbar.get_tool() == "lasso" and stroke_active and stroke_points.size() > 1:
		var preview_points := stroke_points.duplicate()
		if preview_points.size() > 2 and preview_points[0] != preview_points[-1]:
			preview_points.append(preview_points[0])
		overlay.draw_polyline(preview_points, color, 2.0, true)


func _on_tool_changed(tool_name: StringName) -> void:
	stroke_points.clear()
	stroke_active = false
	update_overlays()


func _refresh_layer_target() -> void:
	if current_layer == null:
		return
	if toolbar != null:
		toolbar.set_layer(current_layer)


func _get_local_mouse_position(event: InputEvent) -> Variant:
	if current_layer == null:
		return null
	var viewport := get_editor_interface().get_inspector().get_viewport()
	if viewport == null:
		return null
	var screen_position: Vector2
	if event is InputEventMouseButton:
		screen_position = (event as InputEventMouseButton).position
	elif event is InputEventMouseMotion:
		screen_position = (event as InputEventMouseMotion).position
	else:
		return null
	return _screen_to_layer_local(screen_position)


func _screen_to_layer_local(screen_position: Vector2) -> Variant:
	if current_layer == null:
		return null
	var viewport: Variant = get_editor_interface().get_inspector().get_viewport()
	if viewport == null:
		return null
	var canvas_transform: Transform2D = current_layer.get_canvas_transform()
	var inverse: Transform2D = canvas_transform.affine_inverse()
	var local: Vector2 = inverse * screen_position
	return local


func _commit_circle(center_local: Vector2, erase: bool) -> void:
	if current_layer == null:
		return
	var center_cell: Vector2i = current_layer.local_to_map(center_local)
	var radius: int = toolbar.get_radius()
	var cells: Array[Vector2i] = ShapeCells.circle_cells(current_layer, center_cell, radius)
	_commit_cells(cells, erase)


func _commit_polygon(points: PackedVector2Array, erase: bool) -> void:
	if current_layer == null:
		return
	var cells := ShapeCells.polygon_cells(current_layer, points)
	_commit_cells(cells, erase)


func _commit_cells(cells: Array[Vector2i], erase: bool) -> void:
	if cells.is_empty():
		return
	var terrain_set: int = toolbar.get_terrain_set()
	var terrain_index: int = toolbar.get_terrain()
	if erase:
		terrain_index = -1
	var undo_redo := get_undo_redo()
	undo_redo.create_action("MoreTerrainTools Paint")
	for cell in cells:
		var prev: Array = _capture_cell_state(cell)
		undo_redo.add_undo_method(current_layer, "set_cell", cell, prev[0], prev[1], prev[2])
	undo_redo.add_do_method(current_layer, "set_cells_terrain_connect", cells, terrain_set, terrain_index, false)
	undo_redo.commit_action()


func _capture_cell_state(cell: Vector2i) -> Array:
	if current_layer == null:
		return [0, Vector2i.ZERO, 0]
	var source_id: int = current_layer.get_cell_source_id(cell)
	var atlas_coords: Vector2i = current_layer.get_cell_atlas_coords(cell)
	var alternative_tile: int = current_layer.get_cell_alternative_tile(cell)
	var terrain_data: Variant = current_layer.get_cell_terrain_path(cell)
	return [source_id, atlas_coords, alternative_tile, terrain_data]
