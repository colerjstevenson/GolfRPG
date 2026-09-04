class_name FlyoverSparkles
extends Control

const COLORS := [
	Color("fff3a3"),
	Color("f6a8d8"),
	Color("9ce8d7"),
	Color("ffffff"),
]
const MAX_PARTICLES := 800

var particles: Array[Dictionary] = []
var emitting: bool = true


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func emit_fall(viewport_size: Vector2) -> void:
	if not emitting:
		return
	_spawn_particle(Vector2(
		randf_range(0.0, viewport_size.x),
		randf_range(0.0, viewport_size.y)
	))


func finish() -> void:
	emitting = false
	if particles.is_empty():
		queue_free()


func _process(delta: float) -> void:
	for particle in particles:
		particle["position"] += particle["velocity"] * delta
		particle["velocity"].y += 4.0 * delta
		particle["age"] += delta
	particles = particles.filter(func(particle: Dictionary) -> bool:
		return particle["age"] < particle["lifetime"]
	)
	queue_redraw()
	if not emitting and particles.is_empty():
		queue_free()


func _draw() -> void:
	for particle in particles:
		var lifetime: float = particle["lifetime"]
		var alpha := clampf(1.0 - particle["age"] / lifetime, 0.0, 1.0)
		var color: Color = particle["color"]
		color.a *= alpha
		var pixel_position: Vector2 = particle["position"]
		var pixel_size: float = particle["size"]
		if particle["is_star"]:
			draw_rect(Rect2(pixel_position + Vector2(-pixel_size, 0.0), Vector2(pixel_size * 3.0, pixel_size)), color)
			draw_rect(Rect2(pixel_position + Vector2(0.0, -pixel_size), Vector2(pixel_size, pixel_size * 3.0)), color)
		else:
			draw_rect(Rect2(pixel_position, Vector2(pixel_size, pixel_size)), color)


func _spawn_particle(screen_position: Vector2) -> void:
	if particles.size() >= MAX_PARTICLES:
		particles.pop_front()
	particles.append({
		"position": screen_position.round(),
		"velocity": Vector2(randf_range(-4.0, 4.0), randf_range(10.0, 20.0)).round(),
		"age": 0.0,
		"lifetime": randf_range(1.6, 2.8),
		"color": COLORS[randi() % COLORS.size()],
		"size": 2.0 if randf() < 0.75 else 4.0,
		"is_star": true,
	})