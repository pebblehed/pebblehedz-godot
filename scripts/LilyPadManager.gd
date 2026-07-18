extends Node2D

# LilyPadManager
# Minimal lily-pad gameplay loop:
# - Generate fixed pads per scene run.
# - Draw pads aligned to live water surface.
# - Trigger one immediate repulsion per unconsumed pad per run.

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
@export var wave_slope_sample_distance: float = 12.0
@export var max_wave_rotation_degrees: float = 18.0
@export var wave_rotation_strength: float = 4.0

const PEBBLE_CONTACT_RADIUS: float = 12.0

var water_manager: Node
var target: Node2D
var lily_pads: Array[Dictionary] = []


func _ready() -> void:
	target = get_node_or_null(target_path) as Node2D
	water_manager = get_node_or_null(water_manager_path)
	_connect_run_reset_notification()
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
	for pad in lily_pads:
		pad["consumed"] = false


func _process(_delta: float) -> void:
	# Redraw every frame so lily pads follow live water.
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if target == null:
		return

	for pad in lily_pads:
		if pad["consumed"]:
			continue

		var transform_data := _get_live_pad_transform(pad)
		var radii := _get_pad_contact_radii(pad["radius"])

		if _is_target_overlapping_pad(
			target.global_position,
			transform_data["center"],
			transform_data["rotation"],
			radii["x"],
			radii["y"]
		):
			pad["consumed"] = true

			if target.has_method("apply_lily_pad_repulsion"):
				target.apply_lily_pad_repulsion(pad["index"])


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
			"consumed": false
		})


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


func _get_pad_contact_radii(radius: float) -> Dictionary:
	var visual_x := radius * 1.35
	var visual_y := radius * 0.72

	return {
		"x": visual_x + PEBBLE_CONTACT_RADIUS,
		"y": visual_y + PEBBLE_CONTACT_RADIUS
	}


func _is_target_overlapping_pad(
	target_position: Vector2,
	pad_center: Vector2,
	pad_rotation: float,
	x_radius: float,
	y_radius: float
) -> bool:
	var local_offset := (target_position - pad_center).rotated(-pad_rotation)

	var ratio := (
		(local_offset.x * local_offset.x) / (x_radius * x_radius)
		+ (local_offset.y * local_offset.y) / (y_radius * y_radius)
	)

	return ratio <= 1.0


func _draw() -> void:
	for pad in lily_pads:
		var transform_data := _get_live_pad_transform(pad)
		var radius: float = pad["radius"]
		var variant: int = pad["variant"]

		_draw_lily_pad(transform_data["center"], radius, variant, transform_data["rotation"])


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
