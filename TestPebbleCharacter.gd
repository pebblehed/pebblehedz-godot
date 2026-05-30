extends CharacterBody2D
class_name TestPebbleCharacter

# TestPebbleCharacter.gd
# Pebble Hedz launch + skip/sink baseline.
#
# Ownership:
# - This file owns pebble launch, flight, skip, sink, and reset behaviour.
# - It does NOT own water physics.
# - It does NOT own camera movement.
# - It does NOT own distance markers.
#
# Current design:
# - Tap 1 locks angle.
# - Tap 2 locks power and launches.
# - Water impact decides whether pebble skips or sinks.
# - If forward energy dies, pebble sinks instead of pogo-bouncing forever.

@export var water_path: NodePath

@export_group("Spawn")
@export var reset_position: Vector2 = Vector2(160.0, 120.0)
@export var reset_below_y: float = 900.0

@export_group("Launch")
@export var min_angle_degrees: float = -1.0
@export var max_angle_degrees: float = 93.0
@export var angle_sweep_speed: float = 95.0
@export var min_launch_power: float = 280.0
@export var max_launch_power: float = 920.0
@export var power_sweep_speed: float = 1.45

@export_group("Motion")
@export var gravity: float = 980.0
@export var air_drag: float = 0.995
@export var horizontal_drag_on_skip: float = 0.97

@export_group("Water Impact")
@export var impact_min_speed: float = 80.0
@export var impact_cooldown: float = 0.22
@export var skip_bounce_factor: float = 0.18
@export var max_bounce_velocity: float = 260.0
@export var water_impulse_multiplier: float = 1.0

@export_group("Skip / Sink Rules")
@export var min_horizontal_speed_to_skip: float = 95.0
@export var max_vertical_speed_to_skip: float = 900.0
@export var sink_gravity_multiplier: float = 0.55
@export var sink_drag: float = 0.94

enum LaunchState {
	ANGLE_SELECT,
	POWER_SELECT,
	LAUNCHED,
	SINKING
}

var launch_state: LaunchState = LaunchState.ANGLE_SELECT
var water: Node

var current_angle: float = 20.0
var locked_angle: float = 20.0
var angle_direction: float = 1.0

var power_phase: float = 0.0
var selected_power: float = 0.0

var cooldown_timer: float = 0.0
var was_above_surface: bool = true


func _ready() -> void:
	water = get_node_or_null(water_path)
	reset_pebble()


func _physics_process(delta: float) -> void:
	if water == null:
		return

	cooldown_timer = max(0.0, cooldown_timer - delta)

	if launch_state == LaunchState.ANGLE_SELECT:
		_update_angle_select(delta)
	elif launch_state == LaunchState.POWER_SELECT:
		_update_power_select(delta)
	elif launch_state == LaunchState.LAUNCHED:
		_update_launched_motion(delta)
	elif launch_state == LaunchState.SINKING:
		_update_sinking_motion(delta)

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or _is_primary_tap(event):
		if launch_state == LaunchState.ANGLE_SELECT:
			locked_angle = current_angle
			launch_state = LaunchState.POWER_SELECT
		elif launch_state == LaunchState.POWER_SELECT:
			_launch_pebble()

	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reset_pebble()

		if water != null:
			water.reset_water()


func _is_primary_tap(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	if event is InputEventScreenTouch:
		return event.pressed

	return false


func _update_angle_select(delta: float) -> void:
	current_angle += angle_direction * angle_sweep_speed * delta

	if current_angle >= max_angle_degrees:
		current_angle = max_angle_degrees
		angle_direction = -1.0

	if current_angle <= min_angle_degrees:
		current_angle = min_angle_degrees
		angle_direction = 1.0

	velocity = Vector2.ZERO
	global_position = reset_position


func _update_power_select(delta: float) -> void:
	power_phase += power_sweep_speed * delta

	if power_phase > 1.0:
		power_phase -= 1.0

	velocity = Vector2.ZERO
	global_position = reset_position


func _update_launched_motion(delta: float) -> void:
	velocity.y += gravity * delta
	velocity.x *= air_drag

	var surface_y: float = water.get_surface_y_world(global_position.x)
	var is_above_surface: bool = global_position.y < surface_y

	if was_above_surface and not is_above_surface and velocity.y > impact_min_speed:
		if cooldown_timer <= 0.0:
			_handle_water_impact()

	was_above_surface = is_above_surface

	move_and_slide()

	if global_position.y > reset_below_y:
		reset_pebble()


func _update_sinking_motion(delta: float) -> void:
	# Once sinking, the pebble loses forward energy and drops away.
	velocity.y += gravity * sink_gravity_multiplier * delta
	velocity.x *= sink_drag

	move_and_slide()

	if global_position.y > reset_below_y:
		reset_pebble()


func _launch_pebble() -> void:
	var power_ratio: float = _get_power_ratio()
	selected_power = lerp(min_launch_power, max_launch_power, power_ratio)

	var angle_radians: float = deg_to_rad(locked_angle)

	velocity = Vector2(
		cos(angle_radians) * selected_power,
		-sin(angle_radians) * selected_power
	)

	launch_state = LaunchState.LAUNCHED
	was_above_surface = true
	cooldown_timer = 0.0


func _get_power_ratio() -> float:
	return (sin(power_phase * TAU - PI / 2.0) + 1.0) * 0.5


func _handle_water_impact() -> void:
	var downward_speed: float = velocity.y
	var horizontal_speed: float = abs(velocity.x)

	water.disturb_world(global_position.x, downward_speed * water_impulse_multiplier, 5)

	if not _can_skip(horizontal_speed, downward_speed):
		_start_sinking()
		return

	var bounce_speed: float = min(
		downward_speed * skip_bounce_factor,
		max_bounce_velocity
	)

	velocity.y = -bounce_speed
	velocity.x *= horizontal_drag_on_skip

	global_position.y = water.get_surface_y_world(global_position.x) - 4.0

	cooldown_timer = impact_cooldown
	was_above_surface = true


func _can_skip(horizontal_speed: float, downward_speed: float) -> bool:
	# Skip requires enough forward energy.
	if horizontal_speed < min_horizontal_speed_to_skip:
		return false

	# Very steep/heavy impacts should sink rather than bounce forever.
	if downward_speed > max_vertical_speed_to_skip:
		return false

	return true


func _start_sinking() -> void:
	launch_state = LaunchState.SINKING

	# Stop artificial bounce. Keep some forward drift as it dies.
	velocity.y = abs(velocity.y) * 0.25
	velocity.x *= 0.45

	cooldown_timer = impact_cooldown
	was_above_surface = false


func reset_pebble() -> void:
	global_position = reset_position
	velocity = Vector2.ZERO

	launch_state = LaunchState.ANGLE_SELECT

	current_angle = 20.0
	locked_angle = 20.0
	angle_direction = 1.0

	power_phase = 0.0
	selected_power = 0.0

	cooldown_timer = 0.0
	was_above_surface = true

	queue_redraw()


func _draw() -> void:
	if launch_state == LaunchState.ANGLE_SELECT:
		_draw_angle_selector()
	elif launch_state == LaunchState.POWER_SELECT:
		_draw_power_selector()


func _draw_angle_selector() -> void:
	var angle_radians: float = deg_to_rad(current_angle)
	var line_length: float = 95.0

	var end_point := Vector2(
		cos(angle_radians) * line_length,
		-sin(angle_radians) * line_length
	)

	draw_line(Vector2.ZERO, end_point, Color(1.0, 1.0, 1.0, 0.95), 3.0, true)
	draw_circle(end_point, 4.0, Color(1.0, 1.0, 1.0, 0.95))


func _draw_power_selector() -> void:
	var bar_height: float = 120.0
	var bar_width: float = 14.0
	var x_offset: float = -45.0
	var y_offset: float = -70.0

	var ratio: float = _get_power_ratio()
	var filled_height: float = bar_height * ratio

	var bg_rect := Rect2(
		Vector2(x_offset, y_offset),
		Vector2(bar_width, bar_height)
	)

	var fill_rect := Rect2(
		Vector2(x_offset, y_offset + bar_height - filled_height),
		Vector2(bar_width, filled_height)
	)

	draw_rect(bg_rect, Color(1.0, 1.0, 1.0, 0.20), false, 2.0)

	var power_color := Color(
		lerp(0.0, 1.0, ratio),
		lerp(1.0, 0.0, ratio),
		0.0,
		0.95
	)

	draw_rect(fill_rect, power_color, true)