extends CharacterBody2D
class_name TestPebbleCharacter

# TestPebbleCharacter.gd
# Godot 4.6.x compatible.
# CharacterBody2D replacement for Godot 3 KinematicBody2D.

@export var water_path: NodePath

@export_group("Spawn")
@export var reset_position: Vector2 = Vector2(160.0, 120.0)
@export var reset_velocity: Vector2 = Vector2(520.0, -80.0)
@export var reset_below_y: float = 820.0
@export var auto_reset_when_low: bool = true

@export_group("Motion")
@export var gravity: float = 980.0
@export var air_drag: float = 0.995
@export var horizontal_drag_on_skip: float = 0.92

@export_group("Water Impact")
@export var impact_min_speed: float = 80.0
@export var impact_cooldown: float = 0.16
@export var skip_bounce_factor: float = 0.36
@export var min_bounce_velocity: float = 230.0
@export var max_bounce_velocity: float = 520.0
@export var water_impulse_multiplier: float = 1.0

var water: HookeWater2D
var cooldown_timer: float = 0.0
var was_above_surface: bool = true


func _ready() -> void:
	water = get_node_or_null(water_path) as HookeWater2D
	reset_pebble()


func _physics_process(delta: float) -> void:
	if water == null:
		return

	cooldown_timer = max(0.0, cooldown_timer - delta)

	velocity.y += gravity * delta
	velocity.x *= air_drag

	var surface_y: float = water.get_surface_y_world(global_position.x)
	var is_above_surface: bool = global_position.y < surface_y

	if was_above_surface and not is_above_surface and velocity.y > impact_min_speed:
		if cooldown_timer <= 0.0:
			_handle_water_impact()

	was_above_surface = is_above_surface

	move_and_slide()

	if auto_reset_when_low and global_position.y > reset_below_y:
		reset_pebble()


func _handle_water_impact() -> void:
	var downward_speed: float = velocity.y

	water.disturb_world(global_position.x, downward_speed * water_impulse_multiplier, 5)

	var bounce_speed: float = clamp(downward_speed * skip_bounce_factor, min_bounce_velocity, max_bounce_velocity)
	velocity.y = -bounce_speed
	velocity.x *= horizontal_drag_on_skip

	global_position.y = water.get_surface_y_world(global_position.x) - 4.0

	cooldown_timer = impact_cooldown
	was_above_surface = true


func reset_pebble() -> void:
	global_position = reset_position
	velocity = reset_velocity
	cooldown_timer = 0.0
	was_above_surface = true
