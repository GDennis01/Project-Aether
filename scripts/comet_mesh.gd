@tool
extends MeshInstance3D

var axis_scene := preload("res://scenes/axis_arrow.tscn")
var emitter_scene := preload("res://scenes/particle_emitter.tscn")
@onready var x_axis:AxisArrow
@onready var y_axis:AxisArrow
@onready var z_axis:AxisArrow
@export var light_source:SpotLight3D
@export var comet_collider:CollisionObject3D
var rotation_enabled = false
var starting_rotation:Vector3
func _ready() -> void:
	var _x_axis = axis_scene.instantiate() as AxisArrow
	add_child(_x_axis)
	_x_axis.add_to_group("toggle_axis")
	clamp(1,2,3)
	_x_axis.set_axis_type(AxisArrow.AxisType.X)
	_x_axis.set_height(mesh.height)
	
	var _y_axis = axis_scene.instantiate() as AxisArrow
	add_child(_y_axis)
	_y_axis.add_to_group("toggle_axis")
	_y_axis.set_axis_type(AxisArrow.AxisType.Y)
	_y_axis.set_height(mesh.height)
	
	var _z_axis = axis_scene.instantiate() as AxisArrow
	add_child(_z_axis)
	_z_axis.add_to_group("toggle_axis")
	# calling after all axises are added to the scenetree and thus are _ready
	_z_axis.set_axis_type(AxisArrow.AxisType.Z)
	_z_axis.set_height(mesh.height)
	
	x_axis = _x_axis
	y_axis = _y_axis
	z_axis = _z_axis

	starting_rotation = rotation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if rotation_enabled:
		rotate_object_local(Vector3.UP,1*delta)
		pass
	pass


func spawn_emitter_at(latitude:float,longitude:float)->void:
	print("Latitude:"+str(latitude)+" Longitude:"+str(longitude))
	var emitter = emitter_scene.instantiate() as Emitter
	add_child(emitter)
	var emitter_pos = Util.latlon_to_vector3(latitude,longitude+90,mesh.radius)
	emitter.latitude = latitude
	emitter.longitude = longitude
	emitter.position = emitter_pos
	emitter.enabled = false
	emitter.comet_collider = comet_collider
	emitter.light_source = light_source


func trigger_rotation()->void:
	rotation_enabled = not rotation_enabled
func reset_rotation()->void:
	rotation_enabled = false
	#rotation.y = starting_rotation.y
	rotation = starting_rotation

	
func update_radius(value:float)->void:
	#print_debug("[UPDATE RADIUS] Before:"+str(mesh.radius)+" After:"+str(value))
	mesh.set_radius(value)
	$CometArea/CometCollisionShape.shape.set_radius(value-0.001)
	mesh.set_height(value*2)
	if x_axis:
		x_axis.set_height(mesh.height)
	if y_axis:
		y_axis.set_height(mesh.height)
	if z_axis:
		z_axis.set_height(mesh.height)
	get_tree().call_group("emitter","update_position",mesh.radius)
		
## Deprecated
func update_height(value:float)->void:
	#print_debug("[UPDATE HEIGHT] Before:"+str(mesh.height)+" After:"+str(value))
	mesh.set_height(value)
func update_direction_rotation(value:float)->void:
	rotation_degrees.z = value
func update_inclination_rotation(value:float)->void:
	#print_debug("[UPDATE INCLINATION]")
	rotation_degrees.x = -value+90
	
