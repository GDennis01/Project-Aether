extends Node3D

var axis_scene := preload("res://scenes/axis_arrow.tscn")
var sun_axis: AxisArrow
@onready var light3d: SpotLight3D = $SpotLight3D
@export var distance: float = 10.0
var sun_direction: float = 0.0
var sun_inclination: float = 0.0
func _ready() -> void:
	sun_axis = axis_scene.instantiate() as AxisArrow
	# setting up the yellow axis
	light3d.add_child(sun_axis)
	sun_axis.add_to_group("toggle_axis")
	sun_axis.set_axis_type(AxisArrow.AXIS_TYPE.SUN)
	print(distance)
	sun_axis.set_height(1, distance)
	# default sun orientation to PA 0 and STO 0
	update_sun_orientation(0, 0)
	pass

# https://www.youtube.com/watch?v=jhTe_lN4eKY I hate spherical coordinates
func update_sun_orientation(sun_pa: float, sto: float) -> void:
	if not is_node_ready():
		return
	# Convert angles to radians
	var azimuth_rad: float = deg_to_rad(sun_pa)
	var inclination_rad: float = deg_to_rad(sto)

	# Spherical to Cartesian conversion: inclination is the angle from the vertical (Y-axis)
	var x: float = sin(inclination_rad) * sin(azimuth_rad)
	var y: float = cos(inclination_rad) # Y points up
	var z: float = sin(inclination_rad) * cos(azimuth_rad)
	
	var direction: Vector3 = Vector3(x, y, z).normalized()
	# this represents the sun direction vector in 3D space
	Util.sun_direction_vector = direction
	Util.sun_direction_vector = - direction.rotated(Vector3.LEFT, deg_to_rad(-90)).normalized()

	direction = direction.rotated(Vector3.LEFT, deg_to_rad(-90))


	light3d.global_position = global_position + direction * distance
	var up_vector: Vector3 = - Vector3.LEFT
	light3d.look_at(global_position, up_vector)
	# sun_axis.look_at(light3d.global_position, Vector3.UP)
	# if sun_inclination >= 90:
	# 	sun_axis.rotate(Vector3.RIGHT, deg_to_rad(-180))

func debug() -> void:
	print(distance)
	sun_axis.set_height(1, distance)