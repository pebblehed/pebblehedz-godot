extends CharacterBody2D
class_name TestPebbleCharacter

signal run_reset

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
@export var min_launch_power: float = 520.0
@export var max_launch_power: float = 1350.0
@export var power_sweep_speed: float = 1.45

@export_group("Motion")
@export var gravity: float = 520.0
@export var air_drag: float = 0.995
@export var horizontal_drag_on_skip: float = 0.97

@export_group("Water Impact")
@export var impact_min_speed: float = 80.0
@export var impact_cooldown: float = 0.22
@export var skip_bounce_factor: float = 0.26
@export var water_forward_lift_boost: float = 85.0
@export var first_skip_lift_multiplier: float = 1.55
@export var max_bounce_velocity: float = 260.0
@export var water_impulse_multiplier: float = 1.0

# Temporary instrumentation toggle.
# Used to understand why skip counts normalize.
@export var debug_skip_metrics: bool = true

@export_group("Skip / Sink Rules")
@export var min_horizontal_speed_to_skip: float = 95.0
@export var max_vertical_speed_to_skip: float = 900.0

# Progressive skip model.
# These values control energy decay after each water contact.
@export var base_skip_energy_loss: float = 0.045
@export var steep_impact_energy_loss: float = 0.13
@export var weak_lift_energy_loss: float = 0.10
@export var sink_energy_threshold: float = 0.03
@export var micro_skip_energy_threshold: float = 0.10

# Late-stage skim behaviour.
# Used when the pebble is nearly out of energy but still has forward speed.
@export var skim_energy_threshold: float = 0.26
@export var skim_rebound_speed: float = 16.0
@export var skim_forward_decay: float = 0.995

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
var selected_power_ratio: float = 0.0

var cooldown_timer: float = 0.0
var was_above_surface: bool = true

# Runtime skip state.
# Calculated at launch and reduced after each water impact.
var launch_quality: float = 0.0
var throw_quality: float = 0.0
var skip_energy: float = 0.0
var skip_count: int = 0

# Runtime skim state.
# Used for the final low-energy glide/skitter before sinking.
var is_skimming: bool = false
var skim_timer: float = 0.0


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
		if is_skimming:
			_update_skim_motion(delta)
		else:
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

func _update_skim_motion(delta: float) -> void:
	# Skim mode keeps the pebble close to the water surface briefly.
	# This creates a visible low-height glide/skitter before final sink.
	skim_timer -= delta

	var surface_y: float = water.get_surface_y_world(global_position.x)

	velocity.x *= skim_forward_decay
	velocity.y = 0.0

	# Small oscillation so skim visually reads as repeated surface taps.
	var skim_wave: float = sin((0.55 - skim_timer) * 65.0) * 4.0

	global_position.y = surface_y - 2.0 + skim_wave

	# Small repeated disturbances create visible wake pulses.
	if randi() % 4 == 0:
		water.disturb_world(
			global_position.x - 20.0,
			180.0,
			2
		)

		water.disturb_world(
			global_position.x,
			260.0,
			2
	)

	move_and_slide()

	if debug_skip_metrics:
		print(
			"SKIM_METRICS | ",
			"timer=", snapped(skim_timer, 0.01),
			" | x=", snapped(global_position.x, 0.01),
			" | vx=", snapped(abs(velocity.x), 0.01),
			" | surface_y=", snapped(surface_y, 0.01)
		)

	if skim_timer <= 0.0 or abs(velocity.x) < min_horizontal_speed_to_skip:
		is_skimming = false
		_start_sinking()		


func _update_sinking_motion(delta: float) -> void:
	# Once sinking, the pebble loses forward energy and drops away.
	velocity.y += gravity * sink_gravity_multiplier * delta
	velocity.x *= sink_drag

	move_and_slide()

	if global_position.y > reset_below_y:
		reset_pebble()


func _launch_pebble() -> void:
	selected_power_ratio = _get_power_ratio()
	selected_power = lerp(min_launch_power, max_launch_power, selected_power_ratio)

	var angle_radians: float = deg_to_rad(locked_angle)

	# Pebble skipping launch bias:
	# A skipping stone needs strong forward speed and controlled vertical lift.
	var horizontal_launch_speed: float = cos(angle_radians) * selected_power * 1.35
	var vertical_launch_speed: float = sin(angle_radians) * selected_power * 0.25

	velocity = Vector2(
		horizontal_launch_speed,
		-vertical_launch_speed
)

	# Strong throws near the sweet spot carry more skip potential.
	var angle_error: float = abs(locked_angle - 22.0)
	var angle_quality: float = clamp(1.0 - (angle_error / 28.0), 0.0, 1.0)

	launch_quality = selected_power_ratio * angle_quality

	# Throw quality separates weak, average, great, and perfect throws.
	# It will let later impact logic respond differently without touching water/camera.
	throw_quality = clamp(launch_quality, 0.0, 1.0)

	skip_energy = clamp(launch_quality, 0.05, 1.0)
	skip_count = 0

	is_skimming = false
	skim_timer = 0.0

	launch_state = LaunchState.LAUNCHED
	cooldown_timer = 0.0
	was_above_surface = true
	is_skimming = false
	skim_timer = 0.0


func _get_power_ratio() -> float:
	# Smooth 0..1 power oscillation.
	var raw_ratio: float = (sin(power_phase * TAU - PI / 2.0) + 1.0) * 0.5

	# Skill curve:
	# early power rises slowly, then accelerates near full power.
	# This makes high-power timing harder and more satisfying.
	return pow(raw_ratio, 2.2)


func _handle_water_impact() -> void:
	var downward_speed: float = velocity.y
	var horizontal_speed: float = abs(velocity.x)

	water.disturb_world(global_position.x, downward_speed * water_impulse_multiplier, 5)

	var impact_angle: float = rad_to_deg(abs(atan2(downward_speed, horizontal_speed)))
	var lift_quality: float = _get_angle_quality(impact_angle)

	if debug_skip_metrics:
		print(
			"SKIP_METRICS | ",
			"skip=", skip_count,
			" | power=", snapped(selected_power, 0.01),
			" | angle=", snapped(locked_angle, 0.01),
			" | vx=", snapped(horizontal_speed, 0.01),
			" | vy=", snapped(downward_speed, 0.01),
			" | impact_angle=", snapped(impact_angle, 0.01),
			" | lift_quality=", snapped(lift_quality, 0.01),
			" | energy=", snapped(skip_energy, 0.01),
			" | throw_quality=", snapped(throw_quality, 0.01)
			
		)

	if not _can_skip(horizontal_speed, downward_speed, impact_angle, lift_quality):
		_start_sinking()
		return

	skip_count += 1

	# Energy decays faster when impact angle is poor or lift is weak.
	var steepness: float = clamp(impact_angle / 48.0, 0.0, 1.0)

	var energy_loss: float = base_skip_energy_loss
	energy_loss += steepness * steep_impact_energy_loss
	energy_loss += (1.0 - lift_quality) * weak_lift_energy_loss

	# Stronger throws retain more usable energy.
	# Poor throws fade sooner, great throws carry further.
	var quality_retention: float = lerp(1.15, 0.70, throw_quality)
	energy_loss *= quality_retention

	skip_energy = max(0.0, skip_energy - energy_loss)

	# Enter skim mode when energy is low but the pebble still has forward speed.
	# This creates the final surface slide/skitter before sinking.
	# Better throws delay skim entry so they earn extra real skips first.
	var quality_scaled_skim_threshold: float = lerp(
		skim_energy_threshold,
		skim_energy_threshold * 0.55,
		throw_quality
	)

	if skip_energy <= quality_scaled_skim_threshold and horizontal_speed >= min_horizontal_speed_to_skip and throw_quality >= 0.45 and lift_quality >= 0.35:
		is_skimming = true
		skim_timer = 0.85
		return

	# Early skips carry more height. Late skips become smaller taps.
	var energy_factor: float = clamp(skip_energy, 0.0, 1.0)
	var bounce_energy_scale: float = lerp(0.60, 1.0, energy_factor)

	var bounce_speed: float = min(
	downward_speed * skip_bounce_factor * bounce_energy_scale,
	max_bounce_velocity

	)

	# Forward speed decays more on steep/poor impacts.
	var forward_decay: float = horizontal_drag_on_skip - (steepness * 0.12)
	forward_decay = clamp(forward_decay, 0.72, horizontal_drag_on_skip)

	# First good contact gets extra lift, then later skips decay normally.
	# This helps create: big first skip -> smaller skips -> skim.
	var final_bounce_speed: float = bounce_speed

	if skip_count == 1 and impact_angle <= 40.0 and lift_quality >= 0.35:
		final_bounce_speed *= first_skip_lift_multiplier

	velocity.y = -final_bounce_speed
	velocity.x *= forward_decay

	# Good shallow contacts convert some water lift into forward drive.
	# Keep this modest so repeated skips do not accelerate unnaturally.
	if impact_angle <= 40.0 and lift_quality >= 0.35:
		velocity.x += water_forward_lift_boost

	if debug_skip_metrics:
		print(
			"SKIP_RESPONSE | ",
			"bounce=", snapped(bounce_speed, 0.01),
			" | new_vx=", snapped(abs(velocity.x), 0.01),
			" | new_vy=", snapped(velocity.y, 0.01),
			" | forward_decay=", snapped(forward_decay, 0.01),
			" | energy_after=", snapped(skip_energy, 0.01)
		)

	global_position.y = water.get_surface_y_world(global_position.x) - 4.0

	cooldown_timer = impact_cooldown
	was_above_surface = true

func _can_skip(horizontal_speed: float, downward_speed: float, _impact_angle: float, _lift_quality: float) -> bool:
	# Forward speed is still the minimum requirement.
	if horizontal_speed < min_horizontal_speed_to_skip:
		return false

	# A very hard downward hit should sink.
	if downward_speed > max_vertical_speed_to_skip:
		return false

	# Bad throws with no remaining skip energy should not keep bouncing.
	if skip_energy <= sink_energy_threshold and throw_quality < 0.25:
		return false

	return true

func _start_sinking() -> void:
	launch_state = LaunchState.SINKING

	# Enter sink state with reduced vertical impact and fading forward drift.
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

	if water != null:
		water.reset_water()

	emit_signal("run_reset")

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

func _get_angle_quality(angle_degrees: float) -> float:
	# Pebbles skip best at shallow launch / impact angles.
	# 22 degrees is our current game sweet spot.
	var sweet_spot: float = 22.0
	var angle_error: float = abs(angle_degrees - sweet_spot)

	return clamp(1.0 - (angle_error / 28.0), 0.0, 1.0)

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
