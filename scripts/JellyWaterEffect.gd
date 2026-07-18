extends Node

# JellyWaterEffect
# Temporary gameplay effect that applies a jelly-like physics profile
# to the existing HookeWater2D system, then restores the exact prior state.
#
# This script does not own water simulation.
# HookeWater2D remains the authoritative water system.

@export var water_path: NodePath
@export var effect_duration: float = 3.0

@export_group("Jelly Physics")
@export var jelly_spring_stiffness: float = 0.35
@export var jelly_damping: float = 0.012
@export var jelly_spread: float = 0.34
@export var jelly_impact_strength: float = 0.032

var water: HookeWater2D
var effect_active: bool = false

var previous_spring_stiffness: float
var previous_damping: float
var previous_spread: float
var previous_impact_strength: float

var previous_water_color: Color
var previous_surface_color: Color


func _ready() -> void:
	water = get_node_or_null(water_path) as HookeWater2D


func activate() -> void:
	if water == null:
		return

	if effect_active:
		return

	effect_active = true

	previous_spring_stiffness = water.spring_stiffness
	previous_damping = water.damping
	previous_spread = water.spread
	previous_impact_strength = water.impact_strength

	previous_water_color = water.water_color
	previous_surface_color = water.surface_color

	water.spring_stiffness = jelly_spring_stiffness
	water.damping = jelly_damping
	water.spread = jelly_spread
	water.impact_strength = jelly_impact_strength
	
	water.water_color = Color(0.72, 0.12, 0.18, 0.78)
	water.surface_color = Color(1.0, 0.42, 0.46, 0.98)

	await get_tree().create_timer(
		effect_duration,
		true,
		false,
		true
	).timeout

	_restore_previous_water_state()


func _restore_previous_water_state() -> void:
	if water == null:
		return

	water.spring_stiffness = previous_spring_stiffness
	water.damping = previous_damping
	water.spread = previous_spread
	water.impact_strength = previous_impact_strength
	water.water_color = previous_water_color
	water.surface_color = previous_surface_color

	effect_active = false
	
func is_active() -> bool:
	return effect_active

func trigger_jelly_impact(world_x: float, impact_velocity: float) -> void:
	if water == null or not effect_active:
		return

	var strong_impact: float = max(abs(impact_velocity), 1200.0)

	water.disturb_world(
		world_x,
		strong_impact * 3.2,
		9
	)

	await get_tree().create_timer(
		0.035,
		true,
		false,
		true
	).timeout

	if not effect_active:
		return

	water.disturb_world(world_x - 180.0, strong_impact * 2.6, 7)
	water.disturb_world(world_x + 180.0, strong_impact * 2.6, 7)

	await get_tree().create_timer(
		0.035,
		true,
		false,
		true
	).timeout

	if not effect_active:
		return

	water.disturb_world(world_x - 500.0, strong_impact * 2.0, 6)
	water.disturb_world(world_x + 500.0, strong_impact * 2.0, 6)

	await get_tree().create_timer(
		0.035,
		true,
		false,
		true
	).timeout

	if not effect_active:
		return

	water.disturb_world(world_x - 900.0, strong_impact * 1.5, 5)
	water.disturb_world(world_x + 900.0, strong_impact * 1.5, 5)

	await get_tree().create_timer(
		0.035,
		true,
		false,
		true
	).timeout

	if not effect_active:
		return

	water.disturb_world(world_x - 1500.0, strong_impact * 1.1, 4)
	water.disturb_world(world_x + 1500.0, strong_impact * 1.1, 4)