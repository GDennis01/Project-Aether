extends Node3D


func update_sun_dir_rotation(value:float)->void:
	rotation_degrees.z = value
	
func update_sun_inc_rotation(value:float)->void:
	rotation_degrees.x = -value+90
