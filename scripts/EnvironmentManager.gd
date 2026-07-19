extends Node

## EnvironmentManager
##
## Baseline environmental progression coordinator.
##
## Current responsibility:
## - Track the pebble's forward distance travelled during a run.
## - Normalize that distance into environmental progression from 0.0 to 1.0.
## - Reset progression state for each new run.
##
## This baseline does not currently own any visual environmental behaviour.


## Pebble whose forward movement drives environmental progression.
@export var pebble: Node2D


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