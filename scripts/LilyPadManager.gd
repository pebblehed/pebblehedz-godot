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
@export var water_manager_path: NodePath

@export var pad_count: int = 18
@export var spawn_start_x: float = 700.0
@export var spawn_spacing_min: float = 450.0
@export var spawn_spacing_max: float = 900.0
@export var water_y: float = 430.0
@export var y_jitter: float = 14.0
@export var min_radius: float = 20.0
@export var max_radius: float = 36.0
@export var detection_padding: float = 4.0
@export var wave_slope_sample_distance: float = 12.0
@export var max_wave_rotation_degrees: float = 18.0
@export var wave_rotation_strength: float = 4.0

# PH-LP-DIAG-002 temporary instrumentation.
const DIAG_PEBBLE_COLLISION_RADIUS: float = 12.0
const DIAG_MARKER_RADIUS: float = 4.0
const DIAG_ELLIPSE_STEPS: int = 48
const DIAG_LABEL_OFFSET: Vector2 = Vector2(14.0, -14.0)
const DIAG_VISUAL_CENTER_COLOR := Color(0.16, 0.88, 1.0, 0.95)
const DIAG_CONTACT_CENTER_COLOR := Color(1.0, 0.36, 0.24, 0.95)
const DIAG_PHYSICAL_ELLIPSE_COLOR := Color(1.0, 0.78, 0.18, 0.95)
const DIAG_PROXIMITY_ELLIPSE_COLOR := Color(1.0, 0.92, 0.38, 0.42)
const DIAG_PEBBLE_ORIGIN_COLOR := Color(1.0, 1.0, 1.0, 0.95)
const DIAG_PEBBLE_COLLISION_COLOR := Color(1.0, 1.0, 1.0, 0.45)

# PH-LP-001 canonical gameplay contact extent.
const PEBBLE_CONTACT_RADIUS: float = 12.0
const CONTACT_DIRECT_THRESHOLD: float = 0.35
const CONTACT_GOOD_THRESHOLD: float = 0.60
const LARGE_RATIO: float = 999999.0

# PH-LP-001 reset-teleport discontinuity guard.
# Keep this very conservative so legitimate gameplay sweeps are preserved.
const MAX_CONTINUOUS_STEP_DISTANCE: float = 320.0
const MAX_CONTINUOUS_STEP_DISTANCE_SQUARED: float = (
	MAX_CONTINUOUS_STEP_DISTANCE * MAX_CONTINUOUS_STEP_DISTANCE
)

var water_manager: Node
var target: Node2D
var lily_pads: Array[Dictionary] = []

var previous_target_position: Vector2 = Vector2.ZERO
var estimated_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	target = get_node_or_null(target_path) as Node2D
	water_manager = get_node_or_null(water_manager_path)
	_connect_run_reset_notification()

	if target != null:
		previous_target_position = target.global_position

	_generate_lily_pads()
	queue_redraw()


func _connect_run_reset_notification() -> void:
	if target == null:
		return

	if not target.has_signal("run_reset"):
		return

	var callback := Callable(self, "_on_target_run_reset")

	if not target.is_connected("run_reset", callback):
		target.connect("run_reset", callback)


func _on_target_run_reset() -> void:
	_reset_per_run_runtime_state()


func _reset_per_run_runtime_state() -> void:
	for pad in lily_pads:
		pad["encounter_active"] = false
		pad["had_physical_contact"] = false
		pad["strongest_contact_ratio"] = LARGE_RATIO
		pad["resolved_contact_quality"] = ""
		pad["consumed"] = false

	if target != null:
		previous_target_position = target.global_position

	estimated_velocity = Vector2.ZERO


func _process(_delta: float) -> void:
	# Redraw every frame so lily pads visually follow the live water surface.
	queue_redraw()


func _physics_process(delta: float) -> void:
	if target == null:
		return

	_update_estimated_velocity(delta)
	_check_lily_pad_detection()


func _update_estimated_velocity(delta: float) -> void:
	if delta <= 0.0:
		return

	estimated_velocity = (target.global_position - previous_target_position) / delta


func _generate_lily_pads() -> void:
	lily_pads.clear()

	var x := spawn_start_x

	for i in range(pad_count):
		x += randf_range(spawn_spacing_min, spawn_spacing_max)

		lily_pads.append({
			"index": i,
			"x": x,
			"y": water_y + randf_range(-y_jitter, y_jitter),
			"radius": randf_range(min_radius, max_radius),
			"variant": randi_range(0, 2),
			"encounter_active": false,
			"had_physical_contact": false,
			"strongest_contact_ratio": LARGE_RATIO,
			"resolved_contact_quality": "",
			"consumed": false
		})


func _check_lily_pad_detection() -> void:
	if target == null:
		return

	var current_target_position := target.global_position
	var previous_position := previous_target_position
	var step_vector := current_target_position - previous_position

	# Skip impossible discontinuous reposition steps (e.g. WATER_RESET teleport).
	# Synchronize history so next step resumes normal swept evaluation.
	if step_vector.length_squared() > MAX_CONTINUOUS_STEP_DISTANCE_SQUARED:
		previous_target_position = current_target_position
		return

	for pad in lily_pads:
		if pad["consumed"]:
			continue

		var transform_data := _get_live_pad_transform(pad)
		var radii_data := _get_live_pad_radii(pad["radius"])

		var min_physical_ratio_squared := _get_min_segment_ellipse_ratio_squared(
			previous_position,
			current_target_position,
			transform_data["center"],
			transform_data["rotation"],
			radii_data["physical_x"],
			radii_data["physical_y"]
		)

		var min_proximity_ratio_squared := _get_min_segment_ellipse_ratio_squared(
			previous_position,
			current_target_position,
			transform_data["center"],
			transform_data["rotation"],
			radii_data["proximity_x"],
			radii_data["proximity_y"]
		)

		var step_has_physical_contact := min_physical_ratio_squared <= 1.0
		var step_has_proximity := min_proximity_ratio_squared <= 1.0

		if not pad["encounter_active"] and (step_has_proximity or step_has_physical_contact):
			pad["encounter_active"] = true
			pad["had_physical_contact"] = false
			pad["strongest_contact_ratio"] = LARGE_RATIO
			pad["resolved_contact_quality"] = ""

		if not pad["encounter_active"]:
			continue

		if step_has_physical_contact:
			pad["had_physical_contact"] = true
			var step_ratio := sqrt(max(min_physical_ratio_squared, 0.0))
			pad["strongest_contact_ratio"] = min(
				pad["strongest_contact_ratio"],
				step_ratio
			)

		if step_has_proximity or step_has_physical_contact:
			continue

		_resolve_encounter(
			pad,
			transform_data["center"],
			pad["radius"]
		)

	previous_target_position = current_target_position


func _get_contact_quality(ellipse_ratio: float) -> String:
	if ellipse_ratio <= CONTACT_DIRECT_THRESHOLD:
		return "DIRECT"

	if ellipse_ratio <= CONTACT_GOOD_THRESHOLD:
		return "GOOD"

	return "GLANCING"


func _get_approach_angle_degrees() -> float:
	if estimated_velocity.length() <= 0.0:
		return 90.0

	return rad_to_deg(
		atan2(abs(estimated_velocity.y), abs(estimated_velocity.x))
	)


func _get_live_surface_y(pad_x: float, fallback_y: float) -> float:
	if water_manager != null and water_manager.has_method("get_surface_y_world"):
		return water_manager.get_surface_y_world(pad_x)

	return fallback_y


func _get_live_pad_transform(pad: Dictionary) -> Dictionary:
	var pad_x: float = pad["x"]
	var base_y: float = pad["y"]
	var surface_y := _get_live_surface_y(pad_x, base_y)
	var wave_rotation := 0.0

	if water_manager != null and water_manager.has_method("get_surface_y_world"):
		var left_y: float = water_manager.get_surface_y_world(
			pad_x - wave_slope_sample_distance
		)
		var right_y: float = water_manager.get_surface_y_world(
			pad_x + wave_slope_sample_distance
		)

		var slope_angle := atan2(
			right_y - left_y,
			wave_slope_sample_distance * 2.0
		)

		wave_rotation = clamp(
			slope_angle * wave_rotation_strength,
			deg_to_rad(-max_wave_rotation_degrees),
			deg_to_rad(max_wave_rotation_degrees)
		)

	return {
		"center": Vector2(pad_x, surface_y),
		"rotation": wave_rotation
	}


func _get_live_pad_radii(radius: float) -> Dictionary:
	var visual_x := radius * 1.35
	var visual_y := radius * 0.72

	var physical_x := visual_x + PEBBLE_CONTACT_RADIUS
	var physical_y := visual_y + PEBBLE_CONTACT_RADIUS

	return {
		"physical_x": physical_x,
		"physical_y": physical_y,
		"proximity_x": physical_x + detection_padding,
		"proximity_y": physical_y + detection_padding
	}


func _get_min_segment_ellipse_ratio_squared(
	segment_start_world: Vector2,
	segment_end_world: Vector2,
	ellipse_center_world: Vector2,
	ellipse_rotation: float,
	x_radius: float,
	y_radius: float
) -> float:
	var start_local: Vector2 = (
		segment_start_world - ellipse_center_world
	).rotated(-ellipse_rotation)

	var end_local: Vector2 = (
		segment_end_world - ellipse_center_world
	).rotated(-ellipse_rotation)

	var delta: Vector2 = end_local - start_local

	var x_inv_sq: float = 1.0 / (x_radius * x_radius)
	var y_inv_sq: float = 1.0 / (y_radius * y_radius)

	var a: float = (
		delta.x * delta.x * x_inv_sq
		+ delta.y * delta.y * y_inv_sq
	)

	var b: float = 2.0 * (
		start_local.x * delta.x * x_inv_sq
		+ start_local.y * delta.y * y_inv_sq
	)

	var c: float = (
		start_local.x * start_local.x * x_inv_sq
		+ start_local.y * start_local.y * y_inv_sq
	)

	if a <= 0.0:
		return c

	var min_t: float = clamp(
		-b / (2.0 * a),
		0.0,
		1.0
	)

	var f0: float = c

	var f1: float = (
		end_local.x * end_local.x * x_inv_sq
		+ end_local.y * end_local.y * y_inv_sq
	)

	var fm: float = (
		a * min_t * min_t
		+ b * min_t
		+ c
	)

	return min(f0, min(f1, fm))


func _resolve_encounter(pad: Dictionary, live_center: Vector2, radius: float) -> void:
	var contact_quality := "NEAR_MISS"

	if pad["had_physical_contact"]:
		contact_quality = _get_contact_quality(pad["strongest_contact_ratio"])

	pad["resolved_contact_quality"] = contact_quality
	pad["encounter_active"] = false

	if contact_quality != "NEAR_MISS":
		pad["consumed"] = true

	var outcome := _estimate_lily_pad_outcome(contact_quality)
	var lift_amount := _get_lily_pad_lift(contact_quality)
	var stored_y: float = pad["y"]

	print(
		"LILY_PAD_OUTCOME",
		" | pad_index=", pad["index"],
		" | contact=", contact_quality,
		" | outcome=", outcome,
		" | lift=", lift_amount,
		" | speed=", estimated_velocity.length(),
		" | approach_angle=", _get_approach_angle_degrees(),
		" | strongest_contact_ratio=", pad["strongest_contact_ratio"],
		" | had_physical_contact=", pad["had_physical_contact"],
		" | consumed=", pad["consumed"],
		" | pad_x=", live_center.x,
		" | stored_pad_y=", stored_y,
		" | live_surface_y=", live_center.y,
		" | vertical_difference=", live_center.y - stored_y,
		" | pad_radius=", radius,
		" | pebble_position=", target.global_position,
		" | estimated_pebble_velocity=", estimated_velocity,
		" | pebble_x=", target.global_position.x
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

func _get_lily_pad_lift(contact_quality: String) -> float:
	if contact_quality == "DIRECT":
		return 55.0

	if contact_quality == "GOOD":
		return 35.0

	if contact_quality == "GLANCING":
		return 18.0

	return 0.0


func _draw() -> void:
	for pad in lily_pads:
		var transform_data := _get_live_pad_transform(pad)
		var radius: float = pad["radius"]
		var variant: int = pad["variant"]

		_draw_lily_pad(transform_data["center"], radius, variant, transform_data["rotation"])
		_draw_ph_lp_diag_002_pad_overlay(
			pad,
			transform_data["center"],
			transform_data["rotation"],
			radius
		)

	_draw_ph_lp_diag_002_pebble_overlay()


func _draw_ph_lp_diag_002_pad_overlay(
	pad: Dictionary,
	center: Vector2,
	pad_rotation: float,
	pad_radius: float
) -> void:
	var radii_data := _get_live_pad_radii(pad_radius)

	_draw_ph_lp_diag_002_cross(center, DIAG_VISUAL_CENTER_COLOR)
	_draw_ph_lp_diag_002_cross(center, DIAG_CONTACT_CENTER_COLOR)
	_draw_ph_lp_diag_002_ellipse(
		center,
		pad_rotation,
		radii_data["physical_x"],
		radii_data["physical_y"],
		DIAG_PHYSICAL_ELLIPSE_COLOR
	)

	_draw_ph_lp_diag_002_ellipse(
		center,
		pad_rotation,
		radii_data["proximity_x"],
		radii_data["proximity_y"],
		DIAG_PROXIMITY_ELLIPSE_COLOR
	)

	if pad["resolved_contact_quality"] != "":
		var label_pos := center + DIAG_LABEL_OFFSET
		var label_color := _get_ph_lp_diag_002_contact_color(pad["resolved_contact_quality"])
		var fallback_font := ThemeDB.fallback_font

		if fallback_font != null:
			draw_string(
				fallback_font,
				label_pos,
				str(pad["resolved_contact_quality"]),
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				ThemeDB.fallback_font_size,
				label_color
			)


func _draw_ph_lp_diag_002_pebble_overlay() -> void:
	if target == null:
		return

	draw_arc(
		target.global_position,
		DIAG_PEBBLE_COLLISION_RADIUS,
		0.0,
		TAU,
		DIAG_ELLIPSE_STEPS,
		DIAG_PEBBLE_COLLISION_COLOR,
		1.5
	)

	_draw_ph_lp_diag_002_cross(target.global_position, DIAG_PEBBLE_ORIGIN_COLOR)


func _draw_ph_lp_diag_002_cross(center: Vector2, color: Color) -> void:
	draw_line(
		center + Vector2(-DIAG_MARKER_RADIUS, 0.0),
		center + Vector2(DIAG_MARKER_RADIUS, 0.0),
		color,
		1.5,
		true
	)
	draw_line(
		center + Vector2(0.0, -DIAG_MARKER_RADIUS),
		center + Vector2(0.0, DIAG_MARKER_RADIUS),
		color,
		1.5,
		true
	)


func _draw_ph_lp_diag_002_ellipse(
	center: Vector2,
	ellipse_rotation: float,
	x_radius: float,
	y_radius: float,
	color: Color
) -> void:
	var points := PackedVector2Array()

	for step in range(DIAG_ELLIPSE_STEPS + 1):
		var angle := (TAU * float(step)) / float(DIAG_ELLIPSE_STEPS)
		var local_point := Vector2(cos(angle) * x_radius, sin(angle) * y_radius)
		points.append(
			center + local_point.rotated(ellipse_rotation)
		)

	draw_polyline(points, color, 1.5, true)


func _get_ph_lp_diag_002_contact_color(contact_quality: String) -> Color:
	if contact_quality == "DIRECT":
		return Color(1.0, 0.2, 0.2, 0.98)

	if contact_quality == "GOOD":
		return Color(1.0, 0.72, 0.18, 0.98)

	if contact_quality == "GLANCING":
		return Color(1.0, 0.95, 0.28, 0.98)

	return Color(0.82, 0.82, 0.82, 0.95)


func _draw_lily_pad(pos: Vector2, radius: float, variant: int, wave_rotation: float) -> void:
	var ellipse_scale := Vector2(1.35, 0.72)

	draw_set_transform(pos, wave_rotation, ellipse_scale)

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
