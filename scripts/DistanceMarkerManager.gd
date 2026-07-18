extends Node2D
class_name DistanceMarkerManager

# DistanceMarkerManager.gd
# Crude debug-only distance markers.
#
# Purpose:
# - Gives visual reference points so we can see forward movement.
# - Helps diagnose when the pebble stops travelling horizontally.
# - Does not affect gameplay, water, camera, or physics.

@export var target_path: NodePath

@export_group("Markers")
@export var marker_spacing: float = 500.0
@export var markers_ahead: int = 12
@export var markers_behind: int = 3
@export var marker_y: float = 250.0
@export var marker_size: Vector2 = Vector2(36.0, 36.0)

var target: Node2D
var markers: Dictionary = {}


func _ready() -> void:
	target = get_node_or_null(target_path) as Node2D


func _process(_delta: float) -> void:
	if target == null:
		return

	_update_markers()


func _update_markers() -> void:
	var current_index: int = int(floor(target.global_position.x / marker_spacing))

	for index in range(current_index - markers_behind, current_index + markers_ahead + 1):
		_ensure_marker(index)

	_remove_old_markers(current_index)


func _ensure_marker(index: int) -> void:
	if markers.has(index):
		return

	var marker := ColorRect.new()
	marker.name = "DistanceMarker_%s" % index
	marker.size = marker_size
	marker.color = Color(1.0, 1.0, 1.0, 0.35)

	add_child(marker)

	marker.global_position = Vector2(
		float(index) * marker_spacing,
		marker_y
	)

	markers[index] = marker


func _remove_old_markers(current_index: int) -> void:
	var min_allowed: int = current_index - markers_behind
	var indexes_to_remove: Array[int] = []

	for index in markers.keys():
		if index < min_allowed:
			indexes_to_remove.append(index)

	for index in indexes_to_remove:
		var marker = markers[index]
		markers.erase(index)

		if marker != null:
			marker.queue_free()