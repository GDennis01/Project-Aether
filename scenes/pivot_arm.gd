# Script attached to PivotArm
@tool
extends Node3D

@export var rotation_speed: float = 1.2 # Radians per second

func _process(delta):
	# Rotate the PivotArm node around its local Y-axis
	#rotate_object_local(Vector3.UP, rotation_speed * delta)
	pass
