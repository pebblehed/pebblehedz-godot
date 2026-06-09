extends Node2D

# LilyPadManager
# Visual-only environmental lily pads.
# Phase 1 rules:
# - No collisions.
# - No boosts.
# - No water physics changes.
# - Random but fair placement ahead of the player.

@export var pad_count: int = 18
@export var spawn_start_x: float = 700.0
@export var spawn_spacing_min: float = 450.0
@export var spawn_spacing_max: float = 900.0
@export var water_y: float = 430.0
@export var y_jitter: float = 18.0
@export var min_radius: float = 18.0
@export var max_radius: float = 34.0

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
			"rotation": 0.0
		})

func _draw() -> void:
	for pad in lily_pads:
		var pos := Vector2(pad["x"], pad["y"])
		var radius: float = pad["radius"]
		var pad_rotation: float = pad["rotation"]

		# Convert the circular pad into a flatter organic ellipse.
		var ellipse_scale := Vector2(1.45, 0.72)

		draw_set_transform(pos, pad_rotation, ellipse_scale)

		# Main lily pad body.
		draw_circle(Vector2.ZERO, radius, Color(0.16, 0.40, 0.22, 0.88))

		# Softer inner highlight to stop the pad feeling flat.
		draw_circle(Vector2(radius * 0.12, -radius * 0.10), radius * 0.58, Color(0.26, 0.55, 0.30, 0.32))

		# Lily pad wedge cut.
		var notch_points := PackedVector2Array([
			Vector2(radius * 0.10, 0.0),
			Vector2(radius * 1.00, -radius * 0.34),
			Vector2(radius * 1.00, radius * 0.34)
		])

		draw_colored_polygon(
			notch_points,
			Color(0.04, 0.12, 0.06, 0.95)
		)

		# Simple central vein.
		draw_line(
			Vector2(-radius * 0.45, 0.0),
			Vector2(radius * 0.55, 0.0),
			Color(0.46, 0.72, 0.42, 0.55),
			2.0
		)

		# Small side veins.
		draw_line(
			Vector2(0.0, 0.0),
			Vector2(radius * 0.35, -radius * 0.32),
			Color(0.46, 0.72, 0.42, 0.35),
			1.5
		)

		draw_line(
			Vector2(0.0, 0.0),
			Vector2(radius * 0.35, radius * 0.32),
			Color(0.46, 0.72, 0.42, 0.35),
			1.5
		)

		# Reset drawing transform after each pad.
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		if true:
			print("test")
