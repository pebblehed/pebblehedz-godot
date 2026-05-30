extends Node2D

# Main.gd
# Optional test helper for Godot 4.6.x.
# R resets. Space manually splashes under the pebble.

@export var water_path: NodePath
@export var pebble_path: NodePath

var water: HookeWater2D
var pebble: TestPebbleCharacter


func _ready() -> void:
	water = get_node_or_null(water_path) as HookeWater2D
	pebble = get_node_or_null(pebble_path) as TestPebbleCharacter


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if water != null and pebble != null:
			water.disturb_world(pebble.global_position.x, 900.0, 6)

	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if water != null:
			water.reset_water()
		if pebble != null:
			pebble.reset_pebble()
