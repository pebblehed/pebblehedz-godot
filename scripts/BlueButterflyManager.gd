extends Node2D

# BlueButterflyManager
# Minimal blue-butterfly gameplay loop:
# - Generate fixed blue butterflies per scene run.
# - Draw butterflies in the air.
# - Trigger one slow-motion effect per unconsumed butterfly per run.
# - Restore butterflies on run reset.

@export var target_path: NodePath

@export var butterfly_count: int = 8
@export var spawn_start_x: float = 900.0
@export var spawn_spacing_min: float = 700.0
@export var spawn_spacing_max: float = 1200.0
@export var min_y: float = 180.0
@export var max_y: float = 340.0
@export var contact_radius: float = 24.0

@export_group("Flight")
@export var flight_radius_x: float = 90.0
@export var flight_radius_y: float = 55.0
@export var min_flight_speed: float = 35.0
@export var max_flight_speed: float = 85.0
@export var retarget_time_min: float = 0.18
@export var retarget_time_max: float = 0.65
@export var wing_flap_speed: float = 14.0

var target: Node2D
var butterflies: Array[Dictionary] = []


func _ready() -> void:
	target = get_node_or_null(target_path) as Node2D
	_connect_run_reset_notification()
	_generate_butterflies()
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
	for butterfly in butterflies:
		butterfly["consumed"] = false

	queue_redraw()


func _physics_process(delta: float) -> void:
	if target == null:
		return

	for butterfly in butterflies:
		if butterfly["consumed"]:
			continue

		_update_butterfly_flight(butterfly, delta)

		if target.global_position.distance_to(butterfly["position"]) <= contact_radius:
			butterfly["consumed"] = true

			if target.has_method("activate_blue_butterfly_slow_motion"):
				target.activate_blue_butterfly_slow_motion()

	queue_redraw()


func _generate_butterflies() -> void:
	butterflies.clear()

	var x := spawn_start_x

	for i in range(butterfly_count):
		x += randf_range(spawn_spacing_min, spawn_spacing_max)

		var spawn_position := Vector2(
			x,
			randf_range(min_y, max_y)
		)

		butterflies.append({
			"index": i,
			"home_position": spawn_position,
			"position": spawn_position,
			"target_position": spawn_position,
			"flight_speed": randf_range(
				min_flight_speed,
				max_flight_speed
			),
			"retarget_timer": randf_range(
				retarget_time_min,
				retarget_time_max
			),
			"flap_phase": randf_range(0.0, TAU),
			"consumed": false
		})



func _update_butterfly_flight(
	butterfly: Dictionary,
	delta: float
) -> void:
	butterfly["retarget_timer"] -= delta
	butterfly["flap_phase"] += wing_flap_speed * delta

	if butterfly["retarget_timer"] <= 0.0:
		var home_position: Vector2 = butterfly["home_position"]

		butterfly["target_position"] = home_position + Vector2(
			randf_range(-flight_radius_x, flight_radius_x),
			randf_range(-flight_radius_y, flight_radius_y)
		)

		butterfly["flight_speed"] = randf_range(
			min_flight_speed,
			max_flight_speed
		)

		butterfly["retarget_timer"] = randf_range(
			retarget_time_min,
			retarget_time_max
		)

	var current_position: Vector2 = butterfly["position"]
	var target_position: Vector2 = butterfly["target_position"]
	var flight_speed: float = butterfly["flight_speed"]

	butterfly["position"] = current_position.move_toward(
		target_position,
		flight_speed * delta
	)

func _draw() -> void:
	for butterfly in butterflies:
		if butterfly["consumed"]:
			continue

		var pos: Vector2 = butterfly["position"]
		var flap_phase: float = butterfly["flap_phase"]

		var wing_spread: float = lerpf(
			3.0,
			10.0,
			(abs(sin(flap_phase)) + 0.15) / 1.15
		)

		draw_circle(
			pos + Vector2(-wing_spread, 0.0),
			7.0,
			Color(0.20, 0.55, 1.0, 0.85)
		)

		draw_circle(
			pos + Vector2(wing_spread, 0.0),
			7.0,
			Color(0.20, 0.55, 1.0, 0.85)
		)

		draw_circle(
			pos,
			3.0,
			Color(0.04, 0.08, 0.12, 1.0)
		)
