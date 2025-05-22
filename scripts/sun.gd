extends Node3D

var axis_scene := preload("res://scenes/axis_arrow.tscn")
var sun_axis: AxisArrow
func _ready() -> void:
	sun_axis = axis_scene.instantiate() as AxisArrow
	add_child(sun_axis)
	sun_axis.add_to_group("toggle_axis")
	sun_axis.set_axis_type(AxisArrow.AXIS_TYPE.SUN)
	sun_axis.set_height(1)
	pass

## Updates the sun axis position and size	
## Called by Comet.update_radius
func update_sun_axis(value: float) -> void:
	print("UPDATE SUN")
	if sun_axis:
		sun_axis.set_height(value)
	pass
func update_sun_dir_rotation(value: float) -> void:
	if is_instance_of(self, DirectionalLight3D):
		rotation.y = deg_to_rad(-value)
	else:
		# rotation_degrees.x = value
		rotation_degrees.z = value
		Util.sun_direction = value
	
func update_sun_inc_rotation(value: float) -> void:
	if is_instance_of(self, DirectionalLight3D):
		rotation.x = deg_to_rad(-value)
	else:
		# rotation_degrees.y = - value + 90
		rotation_degrees.y = - value
		Util.sun_inclination = value
