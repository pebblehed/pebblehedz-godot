extends Camera2D
class_name PebbleCamera2D

# PebbleCamera2D.gd
# Baseline camera follow system for Pebble Hedz.
#
# Purpose:
# - Follow the pebble horizontally.
# - Keep vertical framing stable for now.
# - Do not add zoom, cinematic behaviour, or dynamic effects yet.

@export var target_path: NodePath

@export_group("Follow")
@export var follow_x: bool = true
@export var follow_y: bool = false
@export var follow_smoothing: float = 6.0

@export_group("Framing")
@export var vertical_lock_y: float = 360.0
@export var horizontal_offset: float = 260.0

var target: Node2D


func _ready() -> void:
	# Resolve the pebble once when the scene starts.
	target = get_node_or_null(target_path) as Node2D

	# Make this the active camera.
	make_current()


func _process(delta: float) -> void:
	if target == null:
		return

	var desired_position := global_position

	if follow_x:
		desired_position.x = target.global_position.x + horizontal_offset

	if follow_y:
		desired_position.y = target.global_position.y
	else:
		desired_position.y = vertical_lock_y

	# Smooth camera movement so it does not snap harshly.
	global_position = global_position.lerp(
		desired_position,
		1.0 - exp(-follow_smoothing * delta)
	)