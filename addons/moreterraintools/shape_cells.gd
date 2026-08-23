@tool
extends RefCounted
class_name ShapeCells


static func circle_cells(layer: TileMapLayer, center: Vector2i, radius: int) -> Array[Vector2i]:
	if layer == null or radius <= 0:
		return []

	var cells: Array[Vector2i] = []
	var min_x := center.x - radius
	var max_x := center.x + radius
	var min_y := center.y - radius
	var max_y := center.y + radius

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var cell := Vector2i(x, y)
			var delta := Vector2(cell - center)
			if delta.length_squared() <= float(radius * radius) + 0.5:
				cells.append(cell)

	return cells


static func polygon_cells(layer: TileMapLayer, points: PackedVector2Array) -> Array[Vector2i]:
	if layer == null or points.size() < 3:
		return []

	var polygon := points.duplicate()
	if polygon.size() > 1 and polygon[0] == polygon[-1]:
		polygon.remove_at(polygon.size() - 1)

	if polygon.size() < 3:
		return []

	var min_x := INF
	var min_y := INF
	var max_x := -INF
	var max_y := -INF

	for point in polygon:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)

	var origin := Vector2i(floor(min_x), floor(min_y))
	var end := Vector2i(ceil(max_x), ceil(max_y))
	var cells: Array[Vector2i] = []

	for x in range(origin.x, end.x + 1):
		for y in range(origin.y, end.y + 1):
			var cell := Vector2i(x, y)
			var center := layer.map_to_local(cell)
			if Geometry2D.is_point_in_polygon(center, polygon):
				cells.append(cell)

	if cells.size() > 200000:
		return []

	return cells
