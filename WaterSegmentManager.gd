extends Node2D
class_name WaterSegmentManager

# WaterSegmentManager.gd
# Single rolling water manager for Pebble Hedz.
#
# Foundation principle:
# Use ONE active HookeWater2D simulation instead of multiple stitched segments.
#
# Benefits:
# - No visible seams.
# - Lower computational overhead.
# - One spring array.
# - One draw surface.
# - Cleaner mobile-first architecture.

@export var template_water_path: NodePath
@export var target_path: NodePath

@export_group("Rolling Water")
@export var initial_left_x: float = 0
@export var roll_trigger_ratio: float = 0.65
@export var roll_distance_ratio: float = 0.50

var water: HookeWater2D
var target: Node2D

# Actual width is pulled from HookeWater2D during _ready()
var water_width: float = 0.0
var water_left_x: float = 0
var water_y: float = 430.0
var skip_roll_update_once: bool = false


func _ready() -> void:
	# Resolve the single Hooke water body and the pebble target.
	water = get_node_or_null(template_water_path) as HookeWater2D
	target = get_node_or_null(target_path) as Node2D

	if water == null or target == null:
		return

	# Read dimensions from the actual Hooke water node.
	water_width = water.surface_width
	water_y = water.global_position.y
	water_left_x = initial_left_x

	_position_water()


func _process(_delta: float) -> void:
	if water == null or target == null:
		return

	if skip_roll_update_once:
		skip_roll_update_once = false
		return

	_update_rolling_position()


func _update_rolling_position() -> void:
	# When the pebble has travelled far enough into the current water body,
	# shift the whole water body forward.
	#
	# This is not visible because the water body is intentionally much wider
	# than the camera view.
	var trigger_x: float = water_left_x + water_width * roll_trigger_ratio

	if target.global_position.x > trigger_x:
		water_left_x += water_width * roll_distance_ratio
		_position_water()

		# Reset ripples only when rolling forward.
		# At this point the old ripple zone is behind the player/camera.
		water.reset_water()


func _position_water() -> void:
	# HookeWater2D draws from -width/2 to +width/2 around its origin.
	# Therefore the node origin must sit at left + width/2.
	water.global_position = Vector2(
		water_left_x + water_width * 0.5,
		water_y
	)


func get_surface_y_world(world_x: float) -> float:
	if water == null:
		return water_y

	return water.get_surface_y_world(world_x)


func disturb_world(world_x: float, impact_velocity: float, radius: int = -1) -> void:
	if water == null:
		return

	water.disturb_world(world_x, impact_velocity, radius)


func reset_water() -> void:
	if water == null:
		return

	water_left_x = initial_left_x
	_position_water()
	skip_roll_update_once = true
	water.reset_water()
