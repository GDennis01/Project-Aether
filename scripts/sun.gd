extends Node3D

var axis_scene := preload("res://scenes/axis_arrow.tscn")
var sun_axis: AxisArrow
@onready var light3d: SpotLight3D = $SpotLight3D
@export var distance: float = 10.0
@onready var debug_sphere: MeshInstance3D = $"/root/World/DebugRotationSphere"
var sun_direction: float = 0.0
var sun_inclination: float = 0.0
var _dir_debug: Vector3 = Vector3(1, 1, 1)
func _ready() -> void:
	sun_axis = axis_scene.instantiate() as AxisArrow
	light3d.add_child(sun_axis)
	sun_axis.add_to_group("toggle_axis")
	sun_axis.set_axis_type(AxisArrow.AXIS_TYPE.SUN)
	sun_axis.set_height(1, distance)
	# sun.axis.global_position = global_position - distance
	_dir_debug = Vector3(1, 1, 1)
	# debug_sphere.global_position = global_transform.origin + _dir_debug * 3
	update_sun_orientation()
	pass
# func _process(_delta: float) -> void:
	# debug_sphere.global_position = global_transform.origin + _dir_debug * 1
# Updates the sun axis position and size	
## Called by Comet.update_radius
func update_sun_axis(value: float) -> void:
	if sun_axis:
		sun_axis.set_height(value, distance)
	pass
func update_sun_dir_rotation(value: float) -> void:
		if Util.PRINT_UPDATE_METHOD: print("Updated sun direction:%f"%value)
		# rotation_degrees.x = value
		sun_direction = value
		Util.sun_direction = value
		update_sun_orientation()
	
func update_sun_inc_rotation(value: float) -> void:
		if Util.PRINT_UPDATE_METHOD: print("Updated sun inclination:%f"%value)
		# rotation_degrees.x = - value + 90
		sun_inclination = - value
		Util.sun_inclination = value
		update_sun_orientation()

# https://www.youtube.com/watch?v=jhTe_lN4eKY I hate spherical coordinates
func update_sun_orientation() -> void:
	if not is_node_ready():
		return
	# Convert angles to radians
	var azimuth_rad: float = deg_to_rad(sun_direction)
	var inclination_rad: float = deg_to_rad(sun_inclination)

	# Spherical to Cartesian conversion: inclination is the angle from the vertical (Y-axis)
	var x: float = sin(inclination_rad) * sin(azimuth_rad)
	var y: float = cos(inclination_rad) # Y points up
	var z: float = sin(inclination_rad) * cos(azimuth_rad)
	
	var direction: Vector3 = Vector3(x, y, z).normalized()
	# this represents the sun direction vector in 3D space
	Util.sun_direction_vector = direction
	Util.sun_direction_vector = - direction.rotated(Vector3.LEFT, deg_to_rad(-90)).normalized()
	_dir_debug = Util.sun_direction_vector

	direction = direction.rotated(Vector3.LEFT, deg_to_rad(-90))


	light3d.global_position = global_position + direction * distance
	var up_vector: Vector3 = - Vector3.LEFT
	light3d.look_at(global_position, up_vector)
	# sun_axis.look_at(light3d.global_position, Vector3.UP)
	# if sun_inclination >= 90:
	# 	sun_axis.rotate(Vector3.RIGHT, deg_to_rad(-180))
