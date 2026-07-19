extends Node

## EnvironmentManager
##
## Baseline environmental progression coordinator.
##
## Current responsibility:
## - Track the pebble's forward distance travelled during a run.
## - Normalize that distance into environmental progression from 0.0 to 1.0.
## - Reset progression state for each new run.
## - Coordinate the baseline viewport-bound sky presentation.
##
## This baseline does not currently own mountains, celestial bodies,
## stars, lighting, sound, or gameplay behaviour.


## Pebble whose forward movement drives environmental progression.
@export var pebble: Node2D


## Viewport-bound background layer used for baseline sky presentation.
@export var sky_canvas_layer: CanvasLayer


## Full-screen rectangle used to display the procedural sky gradient.
@export var sky_rect: TextureRect


## Forward distance required to reach environmental progression 1.0.
##
## This is currently a baseline tuning value for runtime validation.
## It does not affect pebble gameplay or physics.
@export var journey_completion_distance: float = 5000.0


## Horizontal position from which the current environmental journey began.
var run_start_x: float = 0.0


## Current positive forward distance travelled from run_start_x.
var forward_distance_travelled: float = 0.0


## Current normalized environmental progression.
## Always constrained to the range 0.0 to 1.0.
var environmental_progression: float = 0.0


func _ready() -> void:
	if pebble == null:
		push_warning(
			"EnvironmentManager: No pebble reference assigned. "
			+ "Environmental progression cannot be calculated."
		)
		return

	_connect_run_reset_notification()
	_configure_morning_calm_sky()
	reset_environmental_progression()


func _process(_delta: float) -> void:
	if pebble == null:
		return

	update_environmental_progression()


func _connect_run_reset_notification() -> void:
	if not pebble.has_signal("run_reset"):
		return

	var callback := Callable(self, "_on_pebble_run_reset")

	if not pebble.is_connected("run_reset", callback):
		pebble.connect("run_reset", callback)


func _on_pebble_run_reset() -> void:
	reset_environmental_progression()


## Establishes the baseline Morning Calm sky presentation.
##
## The sky is viewport-bound through CanvasLayer so it remains stable
## during world travel and remains compatible with future camera zoom.
func _configure_morning_calm_sky() -> void:
	if sky_canvas_layer == null:
		push_warning(
			"EnvironmentManager: No sky CanvasLayer assigned. "
			+ "Morning Calm sky cannot be configured."
		)
		return

	if sky_rect == null:
		push_warning(
			"EnvironmentManager: No sky TextureRect assigned. "
			+ "Morning Calm sky cannot be configured."
		)
		return

	sky_canvas_layer.layer = -100

	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([
	Color("12366b"),
	Color("54306f"),
	Color("b83f78"),
	Color("f2a23a"),
	])

	gradient.offsets = PackedFloat32Array([
	0.0,
	0.15,
	0.45,
	0.59
	])

	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 1
	gradient_texture.height = 512
	gradient_texture.fill_from = Vector2(0.5, 0.0)
	gradient_texture.fill_to = Vector2(0.5, 1.0)

	sky_rect.texture = gradient_texture


## Recalculates forward distance and normalized environmental progression.
##
## Backward movement cannot reduce the measured travelled distance below zero.
func update_environmental_progression() -> void:
	forward_distance_travelled = maxf(
		pebble.global_position.x - run_start_x,
		0.0
	)

	if journey_completion_distance <= 0.0:
		environmental_progression = 0.0
		return

	environmental_progression = clampf(
		forward_distance_travelled / journey_completion_distance,
		0.0,
		1.0
	)


## Resets the environmental journey to its starting state.
##
## The current pebble position becomes the new run origin.
func reset_environmental_progression() -> void:
	if pebble == null:
		return

	run_start_x = pebble.global_position.x
	forward_distance_travelled = 0.0
	environmental_progression = 0.0

	print(
		"ENVIRONMENT_RESET | start_x=",
		run_start_x,
		" | distance=",
		forward_distance_travelled,
		" | progression=",
		environmental_progression
	)


## Temporary runtime validation helper.
##
## This can be called deliberately during validation without producing
## continuous per-frame console spam.
func print_environmental_progression_debug() -> void:
	print(
		"ENVIRONMENT_PROGRESSION | start_x=",
		run_start_x,
		" | current_x=",
		pebble.global_position.x if pebble != null else 0.0,
		" | distance=",
		forward_distance_travelled,
		" | progression=",
		environmental_progression
	)
