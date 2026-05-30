extends Node2D
class_name WaterSegmentManager

# WaterSegmentManager.gd
# Endless right-moving Hooke water segment manager.
#
# Purpose:
# - Keep water appearing ahead of the pebble.
# - Remove old water behind the player.
# - Preserve HookeWater2D unchanged.
# - Reduce visible seams by handing ripple energy to neighbouring segments.

@export var template_water_path: NodePath
@export var target_path: NodePath

@export_group("Endless Water")
@export var segments_ahead: int = 4
@export var segments_behind: int = 2

@export_group("Seam Ripple Transfer")
@export var seam_transfer_enabled: bool = true
@export var seam_transfer_zone_ratio: float = 0.12
@export var seam_transfer_strength: float = 0.45

var template_water: HookeWater2D
var target: Node2D

var segment_width: float = 1150.0
var water_y: float = 430.0

var segments: Dictionary = {}


func _ready() -> void:
	template_water = get_node_or_null(template_water_path) as HookeWater2D
	target = get_node_or_null(target_path) as Node2D

	if template_water == null or target == null:
		return

	segment_width = template_water.surface_width
	water_y = template_water.global_position.y

	segments[0] = template_water
	_position_segment(template_water, 0)

	call_deferred("_update_segments")


func _process(_delta: float) -> void:
	if template_water == null or target == null:
		return

	_update_segments()


func _update_segments() -> void:
	var current_index: int = _world_x_to_segment_index(target.global_position.x)

	for index in range(current_index - segments_behind, current_index + segments_ahead + 1):
		_ensure_segment(index)

	_remove_old_segments(current_index)


func _ensure_segment(index: int) -> void:
	if segments.has(index):
		return

	var new_segment: HookeWater2D = template_water.duplicate() as HookeWater2D
	new_segment.name = "HookeWater2D_%s" % index

	template_water.get_parent().add_child(new_segment)

	_position_segment(new_segment, index)
	new_segment.reset_water()

	segments[index] = new_segment


func _remove_old_segments(current_index: int) -> void:
	var min_allowed: int = current_index - segments_behind
	var indexes_to_remove: Array[int] = []

	for index in segments.keys():
		if index < min_allowed:
			indexes_to_remove.append(index)

	for index in indexes_to_remove:
		var old_segment = segments[index]

		segments.erase(index)

		if old_segment != template_water:
			old_segment.queue_free()


func _position_segment(water_segment: HookeWater2D, index: int) -> void:
	water_segment.global_position = Vector2(
		float(index) * segment_width + segment_width * 0.5,
		water_y
	)


func _world_x_to_segment_index(world_x: float) -> int:
	return int(floor(world_x / segment_width))


func _get_segment_for_world_x(world_x: float) -> HookeWater2D:
	var index: int = _world_x_to_segment_index(world_x)

	_ensure_segment(index)

	return segments.get(index, null)


func get_surface_y_world(world_x: float) -> float:
	var active_segment: HookeWater2D = _get_segment_for_world_x(world_x)

	if active_segment == null:
		return water_y

	return active_segment.get_surface_y_world(world_x)


func disturb_world(world_x: float, impact_velocity: float, radius: int = -1) -> void:
	var current_index: int = _world_x_to_segment_index(world_x)
	var active_segment: HookeWater2D = _get_segment_for_world_x(world_x)

	if active_segment == null:
		return

	active_segment.disturb_world(world_x, impact_velocity, radius)

	if seam_transfer_enabled:
		_transfer_ripple_to_neighbour_if_needed(
			world_x,
			impact_velocity,
			radius,
			current_index
		)


func _transfer_ripple_to_neighbour_if_needed(
	world_x: float,
	impact_velocity: float,
	radius: int,
	current_index: int
) -> void:
	var local_x: float = world_x - (float(current_index) * segment_width)
	var edge_zone: float = segment_width * seam_transfer_zone_ratio

	if local_x > segment_width - edge_zone:
		var next_index: int = current_index + 1
		var next_segment = segments.get(next_index, null)

		if next_segment != null:
			var neighbour_x: float = float(next_index) * segment_width + 4.0
			next_segment.disturb_world(
				neighbour_x,
				impact_velocity * seam_transfer_strength,
				radius
			)

	elif local_x < edge_zone:
		var previous_index: int = current_index - 1
		var previous_segment = segments.get(previous_index, null)

		if previous_segment != null:
			var neighbour_x: float = float(current_index) * segment_width - 4.0
			previous_segment.disturb_world(
				neighbour_x,
				impact_velocity * seam_transfer_strength,
				radius
			)


func reset_water() -> void:
	for water_segment in segments.values():
		if water_segment != null:
			water_segment.reset_water()