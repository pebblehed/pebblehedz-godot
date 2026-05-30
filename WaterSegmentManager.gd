extends Node2D
class_name WaterSegmentManager

# WaterSegmentManager.gd
# Creates endless right-moving Hooke water segments.
#
# Purpose:
# - Keep water appearing ahead of the pebble.
# - Remove old water far behind the camera/player.
# - Preserve the existing HookeWater2D script unchanged.
# - Provide the same methods the pebble already expects:
#   get_surface_y_world()
#   disturb_world()
#   reset_water()

@export var template_water_path: NodePath
@export var target_path: NodePath

@export_group("Endless Water")
@export var segments_ahead: int = 4
@export var segments_behind: int = 2

var template_water: HookeWater2D
var target: Node2D
var segment_width: float = 1150.0
var water_y: float = 430.0
var segments: Dictionary = {}


func _ready() -> void:
	# Resolve the existing water node and the pebble/player target.
	template_water = get_node_or_null(template_water_path) as HookeWater2D
	target = get_node_or_null(target_path) as Node2D

	if template_water == null or target == null:
		return

	# Read segment dimensions from the existing water node.
	segment_width = template_water.surface_width
	water_y = template_water.global_position.y

	# The original water node becomes segment 0.
	segments[0] = template_water
	_position_segment(template_water, 0)

	# Wait one frame before creating extra segments so Godot finishes scene setup.
	call_deferred("_update_segments")


func _process(_delta: float) -> void:
	if template_water == null or target == null:
		return

	_update_segments()


func _update_segments() -> void:
	var current_index: int = _world_x_to_segment_index(target.global_position.x)

	# Ensure water exists ahead and slightly behind for camera safety.
	for index in range(current_index - segments_behind, current_index + segments_ahead + 1):
		_ensure_segment(index)

	_remove_old_segments(current_index)


func _ensure_segment(index: int) -> void:
	if segments.has(index):
		return

	# Duplicate the working Hooke water node.
	var new_segment: HookeWater2D = template_water.duplicate() as HookeWater2D
	new_segment.name = "HookeWater2D_%s" % index

	# Add immediately during normal process frames.
	# This is safe because initial creation is deferred from _ready().
	template_water.get_parent().add_child(new_segment)

	_position_segment(new_segment, index)

	# Initialise the duplicated water after it has entered the scene tree.
	new_segment.reset_water()

	segments[index] = new_segment


func _remove_old_segments(current_index: int) -> void:
	var min_allowed: int = current_index - segments_behind
	var indexes_to_remove: Array[int] = []

	for index in segments.keys():
		if index < min_allowed:
			indexes_to_remove.append(index)

	for index in indexes_to_remove:
		var segment: HookeWater2D = segments[index]

		segments.erase(index)

		if segment != template_water:
			segment.queue_free()


func _position_segment(segment: HookeWater2D, index: int) -> void:
	# Segment 0 is centered at half a segment width.
	# Segment 1 starts immediately to the right, and so on.
	segment.global_position = Vector2(
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
	var segment: HookeWater2D = _get_segment_for_world_x(world_x)

	if segment == null:
		return water_y

	return segment.get_surface_y_world(world_x)


func disturb_world(world_x: float, impact_velocity: float, radius: int = -1) -> void:
	var segment: HookeWater2D = _get_segment_for_world_x(world_x)

	if segment == null:
		return

	segment.disturb_world(world_x, impact_velocity, radius)


func reset_water() -> void:
	# Compatibility method so the pebble can reset water without caring
	# whether it is talking to one water node or the endless manager.
	for segment in segments.values():
		if segment != null:
			segment.reset_water()