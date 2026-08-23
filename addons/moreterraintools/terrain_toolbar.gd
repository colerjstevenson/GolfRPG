@tool
extends HBoxContainer

signal tool_changed(tool_name: StringName)
signal terrain_changed

var button_group: ButtonGroup
var off_button: Button
var circle_button: Button
var lasso_button: Button
var radius_spinbox: SpinBox
var terrain_set_option: OptionButton
var terrain_option: OptionButton
var current_layer: TileMapLayer
var active_tool: StringName = "off"


func _ready() -> void:
	_build_ui()
	set_tool("off")


func _build_ui() -> void:
	add_theme_constant_override("separation", 6)
	button_group = ButtonGroup.new()

	off_button = Button.new()
	off_button.text = "Off"
	off_button.toggle_mode = true
	off_button.button_group = button_group
	off_button.pressed.connect(_on_tool_pressed.bind("off"))
	add_child(off_button)

	circle_button = Button.new()
	circle_button.text = "Circle"
	circle_button.toggle_mode = true
	circle_button.button_group = button_group
	circle_button.pressed.connect(_on_tool_pressed.bind("circle"))
	add_child(circle_button)

	lasso_button = Button.new()
	lasso_button.text = "Lasso"
	lasso_button.toggle_mode = true
	lasso_button.button_group = button_group
	lasso_button.pressed.connect(_on_tool_pressed.bind("lasso"))
	add_child(lasso_button)

	radius_spinbox = SpinBox.new()
	radius_spinbox.min_value = 1
	radius_spinbox.max_value = 64
	radius_spinbox.value = 3
	radius_spinbox.step = 1
	radius_spinbox.tooltip_text = "Circle radius"
	add_child(radius_spinbox)

	terrain_set_option = OptionButton.new()
	terrain_set_option.tooltip_text = "Terrain set"
	terrain_set_option.item_selected.connect(_on_terrain_set_selected)
	add_child(terrain_set_option)

	terrain_option = OptionButton.new()
	terrain_option.tooltip_text = "Terrain"
	terrain_option.item_selected.connect(_on_terrain_selected)
	add_child(terrain_option)


func set_tool(tool_name: StringName) -> void:
	active_tool = tool_name
	if tool_name == "off":
		off_button.button_pressed = true
	elif tool_name == "circle":
		circle_button.button_pressed = true
	elif tool_name == "lasso":
		lasso_button.button_pressed = true
	tool_changed.emit(active_tool)


func get_tool() -> StringName:
	return active_tool


func get_radius() -> int:
	return int(radius_spinbox.value)


func get_terrain_set() -> int:
	if current_layer == null or current_layer.tile_set == null:
		return 0
	return terrain_set_option.selected


func get_terrain() -> int:
	if current_layer == null or current_layer.tile_set == null:
		return 0
	return terrain_option.selected


func set_layer(layer: TileMapLayer) -> void:
	current_layer = layer
	_refresh_terrain_options()
	if current_layer == null or current_layer.tile_set == null:
		hide()
		set_tool("off")
		return
	show()


func _on_tool_pressed(tool_name: StringName) -> void:
	set_tool(tool_name)


func _on_terrain_set_selected(index: int) -> void:
	_refresh_terrain_list()
	terrain_changed.emit()


func _on_terrain_selected(index: int) -> void:
	terrain_changed.emit()


func _refresh_terrain_options() -> void:
	terrain_set_option.clear()
	terrain_option.clear()

	if current_layer == null or current_layer.tile_set == null:
		terrain_set_option.disabled = true
		terrain_option.disabled = true
		return

	var tile_set := current_layer.tile_set
	var terrain_sets := tile_set.get_terrain_sets_count()
	for set_index in range(terrain_sets):
		var label := "Terrain Set %d" % set_index
		terrain_set_option.add_item(label, set_index)

	if terrain_sets > 0:
		terrain_set_option.select(0)
		_refresh_terrain_list()
		terrain_set_option.disabled = false
		terrain_option.disabled = false


func _refresh_terrain_list() -> void:
	terrain_option.clear()
	if current_layer == null or current_layer.tile_set == null:
		return

	var tile_set := current_layer.tile_set
	var set_index := terrain_set_option.selected
	var terrain_count := tile_set.get_terrains_count(set_index)
	for terrain_index in range(terrain_count):
		var terrain_name := tile_set.get_terrain_name(set_index, terrain_index)
		if terrain_name == "":
			terrain_name = "Terrain %d" % terrain_index
		terrain_option.add_item(terrain_name, terrain_index)
		var color := tile_set.get_terrain_color(set_index, terrain_index)
		terrain_option.set_item_metadata(terrain_index, color)

	if terrain_count > 0:
		terrain_option.select(0)
