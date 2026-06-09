extends Node2D

# LilyPadManager
# Environmental lily pads for Pebble Hedz.
#
# Current phase:
# - Visual lily pads.
# - Contact quality detection.
# - Outcome logging only.
#
# Design rule:
# The player does not steer into lily pads.
# Lily pad outcomes are driven by physics, chance, speed, approach angle,
# and contact quality after launch.

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

var previous_target_position: Vector2 = Vector2.ZERO
var estimated_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	target = get_node_or_null(target_path) as Node2D

	if target != null:
		previous_target_position = target.global_position

	_generate_lily_pads()
	queue_redraw()


func _process(delta: float) -> void:
	if target == null:
		return

	_update_estimated_velocity(delta)
	_check_lily_pad_detection()


func _update_estimated_velocity(delta: float) -> void:
	if delta <= 0.0:
		return

	estimated_velocity = (target.global_position - previous_target_position) / delta
	previous_target_position = target.global_position


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

		# Match detection to the drawn flat lily pad ellipse.
		var ellipse_x_radius := radius * 1.35 + detection_padding
		var ellipse_y_radius := radius * 0.72 + detection_padding

		var offset := target.global_position - pad_pos

		var ellipse_distance := sqrt(
			pow(offset.x / ellipse_x_radius, 2.0) +
			pow(offset.y / ellipse_y_radius, 2.0)
		)

		if ellipse_distance <= 1.0:
			pad["detected"] = true

			var contact_quality := _get_contact_quality(ellipse_distance)
			var outcome := _estimate_lily_pad_outcome(contact_quality)

			print(
				"LILY_PAD_OUTCOME",
				" | contact=", contact_quality,
				" | outcome=", outcome,
				" | speed=", estimated_velocity.length(),
				" | approach_angle=", _get_approach_angle_degrees(),
				" | ellipse_ratio=", ellipse_distance,
				" | pad_x=", pad_pos.x,
				" | pebble_x=", target.global_position.x
			)


func _get_contact_quality(ellipse_ratio: float) -> String:
	if ellipse_ratio <= 0.35:
		return "DIRECT"

	if ellipse_ratio <= 0.60:
		return "GOOD"

	if ellipse_ratio <= 0.85:
		return "GLANCING"

	return "NEAR_MISS"


func _get_approach_angle_degrees() -> float:
	if estimated_velocity.length() <= 0.0:
		return 90.0

	return rad_to_deg(
		atan2(abs(estimated_velocity.y), abs(estimated_velocity.x))
	)


func _estimate_lily_pad_outcome(contact_quality: String) -> String:
	var speed := estimated_velocity.length()
	var approach_angle := _get_approach_angle_degrees()

	# Shallow contact is better for survival.
	# Steep contact should not give a strong save.
	var shallow_contact := approach_angle <= 18.0
	var moderate_contact := approach_angle <= 32.0

	if contact_quality == "DIRECT" and shallow_contact and speed > 700.0:
		return "WOULD_STRONG_SURVIVAL_BOOST"

	if contact_quality == "DIRECT" and moderate_contact:
		return "WOULD_MEDIUM_SURVIVAL_BOOST"

	if contact_quality == "GOOD" and moderate_contact and speed > 500.0:
		return "WOULD_MEDIUM_SURVIVAL_BOOST"

	if contact_quality == "GLANCING" and shallow_contact and speed > 600.0:
		return "WOULD_SMALL_SKIM_ASSIST"

	if contact_quality == "NEAR_MISS":
		return "WOULD_NO_EFFECT"

	return "WOULD_WEAK_OR_FAILED_SAVE"


func _draw() -> void:
	for pad in lily_pads:
		var pos := Vector2(pad["x"], pad["y"])
		var radius: float = pad["radius"]
		var variant: int = pad["variant"]

		_draw_lily_pad(pos, radius, variant)


func _draw_lily_pad(pos: Vector2, radius: float, variant: int) -> void:
	var ellipse_scale := Vector2(1.35, 0.72)

	draw_set_transform(pos, 0.0, ellipse_scale)

	draw_circle(
		Vector2(0.0, radius * 0.18),
		radius * 1.05,
		Color(0.02, 0.07, 0.08, 0.22)
	)

	draw_circle(
		Vector2.ZERO,
		radius,
		Color(0.13, 0.36, 0.19, 0.92)
	)

	draw_circle(
		Vector2(-radius * 0.08, -radius * 0.08),
		radius * 0.72,
		Color(0.24, 0.52, 0.28, 0.34)
	)

	var notch_points := PackedVector2Array([
		Vector2(radius * 0.05, 0.0),
		Vector2(radius * 1.10, -radius * 0.38),
		Vector2(radius * 1.10, radius * 0.38)
	])

	draw_colored_polygon(
		notch_points,
		Color(0.02, 0.09, 0.05, 0.96)
	)

	draw_arc(
		Vector2.ZERO,
		radius,
		0.52,
		5.76,
		42,
		Color(0.07, 0.23, 0.11, 0.78),
		2.2
	)

	draw_line(
		Vector2(-radius * 0.52, 0.0),
		Vector2(radius * 0.42, 0.0),
		Color(0.48, 0.74, 0.42, 0.58),
		2.0
	)

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

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)