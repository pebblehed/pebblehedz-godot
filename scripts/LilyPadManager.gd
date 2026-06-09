extends Node2D

# LilyPadManager
# Visual-only environmental lily pads.
# No collisions, boosts, scoring, or water physics coupling.

@export var pad_count: int = 18
@export var spawn_start_x: float = 700.0
@export var spawn_spacing_min: float = 450.0
@export var spawn_spacing_max: float = 900.0
@export var water_y: float = 430.0
@export var y_jitter: float = 14.0
@export var min_radius: float = 20.0
@export var max_radius: float = 36.0

var lily_pads: Array[Dictionary] = []


func _ready() -> void:
	_generate_lily_pads()
	queue_redraw()


func _generate_lily_pads() -> void:
	lily_pads.clear()

	var x := spawn_start_x

	for i in range(pad_count):
		x += randf_range(spawn_spacing_min, spawn_spacing_max)

		lily_pads.append({
			"x": x,
			"y": water_y + randf_range(-y_jitter, y_jitter),
			"radius": randf_range(min_radius, max_radius),
			"variant": randi_range(0, 2)
		})


func _draw() -> void:
	for pad in lily_pads:
		var pos := Vector2(pad["x"], pad["y"])
		var radius: float = pad["radius"]
		var variant: int = pad["variant"]

		_draw_lily_pad(pos, radius, variant)


func _draw_lily_pad(pos: Vector2, radius: float, variant: int) -> void:
	# Pads sit flat on the water. No random tilt.
	var ellipse_scale := Vector2(1.35, 0.72)

	draw_set_transform(pos, 0.0, ellipse_scale)

	# Soft water-contact shadow.
	draw_circle(
		Vector2(0.0, radius * 0.18),
		radius * 1.05,
		Color(0.02, 0.07, 0.08, 0.22)
	)

	# Main pad body.
	draw_circle(
		Vector2.ZERO,
		radius,
		Color(0.13, 0.36, 0.19, 0.92)
	)

	# Organic inner body highlight.
	draw_circle(
		Vector2(-radius * 0.08, -radius * 0.08),
		radius * 0.72,
		Color(0.24, 0.52, 0.28, 0.34)
	)

	# Clear wedge cut. This is the key lily pad read.
	var notch_points := PackedVector2Array([
		Vector2(radius * 0.05, 0.0),
		Vector2(radius * 1.10, -radius * 0.38),
		Vector2(radius * 1.10, radius * 0.38)
	])

	draw_colored_polygon(
		notch_points,
		Color(0.02, 0.09, 0.05, 0.96)
	)

	# Outer rim gives the pad a hand-drawn leaf edge.
	draw_arc(
		Vector2.ZERO,
		radius,
		0.52,
		5.76,
		42,
		Color(0.07, 0.23, 0.11, 0.78),
		2.2
	)

	# Central vein.
	draw_line(
		Vector2(-radius * 0.52, 0.0),
		Vector2(radius * 0.42, 0.0),
		Color(0.48, 0.74, 0.42, 0.58),
		2.0
	)

	# Side veins.
	draw_line(
		Vector2(-radius * 0.10, 0.0),
		Vector2(radius * 0.33, -radius * 0.32),
		Color(0.48, 0.74, 0.42, 0.38),
		1.4
	)

	draw_line(
		Vector2(-radius * 0.10, 0.0),
		Vector2(radius * 0.33, radius * 0.32),
		Color(0.48, 0.74, 0.42, 0.38),
		1.4
	)

	# Tiny natural variation so they do not all look cloned.
	if variant == 1:
		draw_circle(
			Vector2(-radius * 0.28, radius * 0.16),
			radius * 0.10,
			Color(0.30, 0.58, 0.30, 0.42)
		)
	elif variant == 2:
		draw_line(
			Vector2(-radius * 0.18, 0.0),
			Vector2(radius * 0.18, -radius * 0.22),
			Color(0.54, 0.78, 0.45, 0.28),
			1.2
		)

	# Reset drawing transform.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)