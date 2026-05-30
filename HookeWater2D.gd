extends Node2D
class_name HookeWater2D

# HookeWater2D.gd
# Godot 4.6.x compatible.
# Single-node Hooke spring water surface for Pebble Hedz water-feel testing.

@export_group("Surface")
@export var surface_width: float = 1150.0
@export var spring_count: int = 140
@export var rest_y: float = 0.0
@export var water_depth: float = 320.0

@export_group("Hooke Physics")
@export var spring_stiffness: float = 0.025
@export var damping: float = 0.035
@export var spread: float = 0.22
@export var propagation_passes: int = 8
@export var time_scale: float = 1.0

@export_group("Impact")
@export var impact_strength: float = 0.018
@export var max_impact_velocity: float = 1600.0
@export var default_impact_radius: int = 4

@export_group("Visual")
@export var water_color: Color = Color(0.10, 0.42, 0.74, 0.70)
@export var surface_color: Color = Color(0.86, 0.96, 1.0, 0.95)
@export var surface_line_width: float = 3.0
@export var draw_debug_springs: bool = false

var heights: PackedFloat32Array = PackedFloat32Array()
var velocities: PackedFloat32Array = PackedFloat32Array()
var left_deltas: PackedFloat32Array = PackedFloat32Array()
var right_deltas: PackedFloat32Array = PackedFloat32Array()
var spacing: float = 1.0


func _ready() -> void:
	_initialise_springs()


func _process(_delta: float) -> void:
	queue_redraw()


func _physics_process(delta: float) -> void:
	_simulate(delta * time_scale)


func _initialise_springs() -> void:
	spring_count = max(8, spring_count)
	spacing = surface_width / float(spring_count - 1)

	heights.resize(spring_count)
	velocities.resize(spring_count)
	left_deltas.resize(spring_count)
	right_deltas.resize(spring_count)

	for i in range(spring_count):
		heights[i] = rest_y
		velocities[i] = 0.0
		left_deltas[i] = 0.0
		right_deltas[i] = 0.0


func _simulate(delta: float) -> void:
	for i in range(spring_count):
		var displacement: float = heights[i] - rest_y
		var force: float = -spring_stiffness * displacement - damping * velocities[i]

		velocities[i] += force * delta * 60.0
		heights[i] += velocities[i] * delta * 60.0

	for _pass_index in range(propagation_passes):
		for i in range(spring_count):
			if i > 0:
				left_deltas[i] = spread * (heights[i] - heights[i - 1])
				velocities[i - 1] += left_deltas[i] * delta * 60.0

			if i < spring_count - 1:
				right_deltas[i] = spread * (heights[i] - heights[i + 1])
				velocities[i + 1] += right_deltas[i] * delta * 60.0

		for i in range(spring_count):
			if i > 0:
				heights[i - 1] += left_deltas[i] * delta * 60.0

			if i < spring_count - 1:
				heights[i + 1] += right_deltas[i] * delta * 60.0


func disturb_world(world_x: float, impact_velocity: float, radius: int = -1) -> void:
	if radius < 0:
		radius = default_impact_radius

	var local_x: float = to_local(Vector2(world_x, global_position.y)).x
	var half_width: float = surface_width * 0.5
	var index: int = int(round((local_x + half_width) / spacing))

	if index < 0 or index >= spring_count:
		return

	var clamped_velocity: float = clamp(impact_velocity, -max_impact_velocity, max_impact_velocity)
	var impulse: float = clamped_velocity * impact_strength

	for offset in range(-radius, radius + 1):
		var j: int = index + offset

		if j < 0 or j >= spring_count:
			continue

		var falloff: float = 1.0 - (abs(float(offset)) / float(radius + 1))
		velocities[j] += impulse * falloff


func get_surface_y_world(world_x: float) -> float:
	if spring_count < 2:
		return global_position.y + rest_y

	var local_x: float = to_local(Vector2(world_x, global_position.y)).x
	var half_width: float = surface_width * 0.5
	var raw_index: float = (local_x + half_width) / spacing
	var i0: int = int(floor(raw_index))
	var i1: int = i0 + 1

	if i0 < 0 or i1 >= spring_count:
		return global_position.y + rest_y

	var t: float = raw_index - float(i0)
	var y: float = lerp(heights[i0], heights[i1], t)

	return global_position.y + y


func reset_water() -> void:
	for i in range(spring_count):
		heights[i] = rest_y
		velocities[i] = 0.0
		left_deltas[i] = 0.0
		right_deltas[i] = 0.0


func _draw() -> void:
	if spring_count < 2:
		return

	var half_width: float = surface_width * 0.5
	var surface_points: PackedVector2Array = PackedVector2Array()

	for i in range(spring_count):
		var x: float = -half_width + float(i) * spacing
		surface_points.append(Vector2(x, heights[i]))

	var polygon_points: PackedVector2Array = PackedVector2Array(surface_points)
	polygon_points.append(Vector2(half_width, water_depth))
	polygon_points.append(Vector2(-half_width, water_depth))
	draw_colored_polygon(polygon_points, water_color)

	for i in range(surface_points.size() - 1):
		draw_line(surface_points[i], surface_points[i + 1], surface_color, surface_line_width, true)

	if draw_debug_springs:
		for point in surface_points:
			draw_circle(point, 2.0, Color(1.0, 1.0, 1.0, 0.55))
