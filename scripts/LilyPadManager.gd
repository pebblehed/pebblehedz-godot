extends Node2D

# LilyPadManager
# Visual-only lily pads plus detection-only interaction logging.
#
# Phase 2 rules:
# - Detect when the pebble overlaps a lily pad.
# - Print debug confirmation.
# - No boost.
# - No bounce.
# - No energy changes.
# - No water physics changes.

@export var target_path: NodePath

@export var pad_count: int = 18
@export var spawn_start_x: float = 700.0
@export var spawn_spacing_min: float = 450.0
@export var spawn_spacing_max: float = 900.0
@export var water_y: float = 430.0
@export var y_jitter: float = 14.0
@export var min_radius: float = 20.0
@export var max_radius: float = 36.0
@export var detection_padding: float = 4.0

var target: Node2D
var lily_pads: Array[Dictionary] = []


func _ready() -> void:
	target = get_node_or_null(target_path) as Node2D

	_generate_lily_pads()
	queue_redraw()


func _process(_delta: float) -> void:
	if target == null:
		return

	_check_lily_pad_detection()


func _generate_lily_pads() -> void:
	lily_pads.clear()

	var x := spawn_start_x

	for i in range(pad_count):
		x += randf_range(spawn_spacing_min, spawn_spacing_max)

		lily_pads.append({
			"x": x,
			"y": water_y + randf_range(-y_jitter, y_jitter),
			"radius": randf_range(min_radius, max_radius),
			"variant": randi_range(0, 2),
			"detected": false
		})


func _check_lily_pad_detection() -> void:
	for pad in lily_pads:
		if pad["detected"]:
			continue

		var pad_pos := Vector2(pad["x"], pad["y"])
		var radius: float = pad["radius"]

		# Match detection to the visual lily pad ellipse.
		# X is wider than Y because the pad is drawn as a flat ellipse.
		var ellipse_x_radius := radius * 1.35 + detection_padding
		var ellipse_y_radius := radius * 0.72 + detection_padding

		var offset := target.global_position - pad_pos

		# Normalised ellipse distance:
		# <= 1.0 means the pebble is inside the lily pad's contact area.
		var ellipse_distance := sqrt(
			pow(offset.x / ellipse_x_radius, 2.0) +
			pow(offset.y / ellipse_y_radius, 2.0)
		)

		if ellipse_distance <= 1.0:
			pad["detected"] = true

			var contact_ratio := ellipse_distance
			var contact_quality := "NEAR_MISS"
			if contact_ratio <= 0.35:
				contact_quality = "DIRECT"
			elif contact_ratio <= 0.60:
				contact_quality = "GOOD"
			elif contact_ratio <= 0.85:
				contact_quality = "GLANCING"

			print(
				"LILY_PAD_CONTACT | quality=", contact_quality,
				" | ratio=", contact_ratio,
				" | pad_x=", pad_pos.x,
				" | pad_y=", pad_pos.y,
				" | pebble_x=", target.global_position.x,
				" | pebble_y=", target.global_position.y,
				" | ellipse_ratio=", ellipse_distance,
			)


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
