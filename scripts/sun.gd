extends Node3D


func update_sun_dir_rotation(value:float)->void:
	if is_instance_of(self,DirectionalLight3D):
		rotation.y = deg_to_rad(-value)
	else:
		rotation_degrees.z = value
	
func update_sun_inc_rotation(value:float)->void:
	if is_instance_of(self,DirectionalLight3D):
		rotation.x = deg_to_rad(-value)
	else:
		rotation_degrees.x = -value+90
