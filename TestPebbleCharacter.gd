extends CharacterBody2D
class_name TestPebbleCharacter

# TestPebbleCharacter.gd
# Pebble Hedz launch-control baseline.
#
# Purpose:
# - Preserve the original HTML-style two-tap launch mechanic.
# - Tap 1 locks the launch angle.
# - Tap 2 locks the power and launches the pebble.
# - Desktop mouse clicks are used as mobile tap simulation.
#
# Important:
# This file controls only the pebble and launch behaviour.
# It must not change the Hooke water system.

@export var water_path: NodePath

@export_group("Spawn")
@export var reset_position: Vector2 = Vector2(160.0, 120.0)
@export var reset_below_y: float = 820.0

@export_group("Launch")
# Angle sweeps between these two values while waiting for the first tap.
@export var min_angle_degrees: float = -1.0
@export var max_angle_degrees: float = 93.0
@export var angle_sweep_speed: float = 65.0

# Power rises and falls while waiting for the second tap.
@export var min_launch_power: float = 280.0
@export var max_launch_power: float = 920.0
@export var power_sweep_speed: float = 0.95

@export_group("Motion")
# Basic projectile motion after launch.
@export var gravity: float = 980.0
@export var air_drag: float = 0.995
@export var horizontal_drag_on_skip: float = 0.92

@export_group("Water Impact")
# Controls how the pebble reacts when crossing the animated water surface.
@export var impact_min_speed: float = 80.0
@export var impact_cooldown: float = 0.16
@export var skip_bounce_factor: float = 0.28
@export var min_bounce_velocity: float = 230.0
@export var max_bounce_velocity: float = 520.0
@export var water_impulse_multiplier: float = 1.0

enum LaunchState {
	ANGLE_SELECT,
	POWER_SELECT,
	LAUNCHED
}

var launch_state: LaunchState = LaunchState.ANGLE_SELECT

# Water can now be either:
# - one water node
# - endless water manager
var water: Node

var current_angle: float = 20.0
var locked_angle: float = 20.0
var angle_direction: float = 1.0

var power_phase: float = 0.0
var selected_power: float = 0.0

var cooldown_timer: float = 0.0
var was_above_surface: bool = true


func _ready() -> void:
	
	# Connect this pebble to the existing Hooke water node.
	# Resolve whichever water system we are using.
	water = get_node_or_null(water_path)

	# Always begin from a controlled launch-ready state.
	reset_pebble()


func _physics_process(delta: float) -> void:
	if water == null:
		return

	cooldown_timer = max(0.0, cooldown_timer - delta)

	# State machine:
	# 1. Sweep launch angle.
	# 2. Sweep power bar.
	# 3. Fly, collide with water, skip/bounce.
	if launch_state == LaunchState.ANGLE_SELECT:
		_update_angle_select(delta)
	elif launch_state == LaunchState.POWER_SELECT:
		_update_power_select(delta)
	else:
		_update_launched_motion(delta)

	# Redraw aiming line or power bar.
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	# Mouse click on desktop simulates mobile tap.
	if event.is_action_pressed("ui_accept") or _is_primary_tap(event):
		if launch_state == LaunchState.ANGLE_SELECT:
			locked_angle = current_angle
			launch_state = LaunchState.POWER_SELECT
		elif launch_state == LaunchState.POWER_SELECT:
			_launch_pebble()

	# R gives us a fast test reset during development.
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		reset_pebble()

		if water != null:
			water.reset_water()


func _is_primary_tap(event: InputEvent) -> bool:
	# Desktop test input.
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT

	# Mobile touch input for later device testing.
	if event is InputEventScreenTouch:
		return event.pressed

	return false


func _update_angle_select(delta: float) -> void:
	# Sweep the angle line back and forth between min and max angle.
	current_angle += angle_direction * angle_sweep_speed * delta

	if current_angle >= max_angle_degrees:
		current_angle = max_angle_degrees
		angle_direction = -1.0

	if current_angle <= min_angle_degrees:
		current_angle = min_angle_degrees
		angle_direction = 1.0

	# Keep pebble fixed while aiming.
	velocity = Vector2.ZERO
	global_position = reset_position


func _update_power_select(delta: float) -> void:
	# Power oscillates continuously until the second tap.
	power_phase += power_sweep_speed * delta

	if power_phase > 1.0:
		power_phase -= 1.0

	# Keep pebble fixed while selecting power.
	velocity = Vector2.ZERO
	global_position = reset_position


func _update_launched_motion(delta: float) -> void:
	# Basic projectile movement.
	velocity.y += gravity * delta
	velocity.x *= air_drag

	var surface_y: float = water.get_surface_y_world(global_position.x)
	var is_above_surface: bool = global_position.y < surface_y

	# Detect crossing from above the water surface to below it.
	if was_above_surface and not is_above_surface and velocity.y > impact_min_speed:
		if cooldown_timer <= 0.0:
			_handle_water_impact()

	was_above_surface = is_above_surface

	move_and_slide()

	# Auto reset after falling below screen.
	if global_position.y > reset_below_y:
		reset_pebble()


func _launch_pebble() -> void:
	# Convert the animated power bar into a launch velocity.
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
	# Smooth 0..1 oscillation.
	# Low = green / weak.
	# High = red / strong.
	return (sin(power_phase * TAU - PI / 2.0) + 1.0) * 0.5


func _handle_water_impact() -> void:
	var downward_speed: float = velocity.y

	# Push energy into the Hooke water surface.
	water.disturb_world(global_position.x, downward_speed * water_impulse_multiplier, 5)

	# Convert downward impact into upward skip velocity.
	var bounce_speed: float = clamp(
		downward_speed * skip_bounce_factor,
		min_bounce_velocity,
		max_bounce_velocity
	)

	velocity.y = -bounce_speed
	velocity.x *= horizontal_drag_on_skip

	# Lift pebble slightly above the surface to avoid duplicate impact frames.
	global_position.y = water.get_surface_y_world(global_position.x) - 4.0

	cooldown_timer = impact_cooldown
	was_above_surface = true


func reset_pebble() -> void:
	# Return to the start of the two-tap launch flow.
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
	# Draw the sweeping aim line from the pebble.
	var angle_radians: float = deg_to_rad(current_angle)
	var line_length: float = 95.0

	var end_point := Vector2(
		cos(angle_radians) * line_length,
		-sin(angle_radians) * line_length
	)

	draw_line(Vector2.ZERO, end_point, Color(1.0, 1.0, 1.0, 0.95), 3.0, true)
	draw_circle(end_point, 4.0, Color(1.0, 1.0, 1.0, 0.95))


func _draw_power_selector() -> void:
	# Draw a simple vertical power bar beside the pebble.
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

	# Bar outline.
	draw_rect(bg_rect, Color(1.0, 1.0, 1.0, 0.20), false, 2.0)

	# Green at low power, red at high power.
	var power_color := Color(
		lerp(0.0, 1.0, ratio),
		lerp(1.0, 0.0, ratio),
		0.0,
		0.95
	)

	draw_rect(fill_rect, power_color, true)
