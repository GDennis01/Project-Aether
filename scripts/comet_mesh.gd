extends MeshInstance3D
class_name Comet
enum ANIMATION_STATE {
	STARTED,
	PAUSED,
	STOPPED,
	RESUMED,
}

@onready var shader_material: ShaderMaterial = self.get_active_material(0) as ShaderMaterial


#switch dateViewport/Panel/DateLabel
# @onready var switch_date: LineEdit = $"/root/Hud/Body/CometTab/Control/SwitchDate/CurrDateLineEdit"
# @onready var switch_date: Label = $"/root/Hud/Viewport/Panel/DateLabel"
var current_date_index: int = 0


# simulation related
var animation_state: ANIMATION_STATE = ANIMATION_STATE.STOPPED
var n_steps: int = 0
var step_counter: int = 0

var angle_per_step: float = 0
var jet_rate: float = 0
var jet_rate_sped_up: float = 0
var num_rotation: float = 0
var frequency: float = 0
var freq_sped_up: float = 0

const EARTH_VIEW = Vector3(0.0, 0.0, 10.0)


var axis_scene := preload("res://scenes/axis_arrow.tscn")

@onready var x_axis: AxisArrow
@onready var y_axis: AxisArrow
@onready var z_axis: AxisArrow
@onready var reverse_y_axis: AxisArrow

@export var light_source: Light3D
@export var comet_collider: CollisionObject3D
var rotation_enabled := false
var starting_rotation: Vector3

var rotation_angle: float = 0.0

var speed_sim: int = 1

func _ready() -> void:
	var _x_axis := axis_scene.instantiate() as AxisArrow
	add_child(_x_axis)
	_x_axis.add_to_group("toggle_axis")
	_x_axis.set_axis_type(AxisArrow.AXIS_TYPE.X)
	_x_axis.set_height(mesh.height)
	
	var _y_axis := axis_scene.instantiate() as AxisArrow
	add_child(_y_axis)
	_y_axis.add_to_group("toggle_axis")
	_y_axis.set_axis_type(AxisArrow.AXIS_TYPE.Y)
	_y_axis.set_height(mesh.height)
	
	var _z_axis := axis_scene.instantiate() as AxisArrow
	add_child(_z_axis)
	_z_axis.add_to_group("toggle_axis")
	_z_axis.set_axis_type(AxisArrow.AXIS_TYPE.Z)
	_z_axis.set_height(mesh.height)

	var _reverse_y_axis := axis_scene.instantiate() as AxisArrow
	# delete arrow head
	
	add_child(_reverse_y_axis)
	_reverse_y_axis.add_to_group("toggle_axis")
	_reverse_y_axis.set_axis_type(AxisArrow.AXIS_TYPE.REVERSE_Y)
	_reverse_y_axis.set_height(mesh.height)
	
	x_axis = _x_axis
	y_axis = _y_axis
	z_axis = _z_axis
	reverse_y_axis = _reverse_y_axis

	# disabled by default
	# x_axis.visible = false
	# z_axis.visible = false

	starting_rotation = rotation

	get_tree().call_group("sun", "update_sun_axis", mesh.height)
	
	Util.comet_radius = mesh.radius
	update_comet_orientation(0, 0)


## These methods are called by SanitizedEdit through call_group() mechanism
#region Update methods

## For Antonio: this method just updates the radius of the mesh, I didn't remove it as it could break something
func update_radius(value: float) -> void:
	#print_debug("[UPDATE RADIUS] Before:"+str(mesh.radius)+" After:"+str(value))
	if Util.PRINT_UPDATE_METHOD: print("Updated comet radius:%f"%value)
	Util.comet_radius = value
	mesh.set_radius(value)
	$CometArea/CometCollisionShape.shape.set_radius(value - 0.0001)
	mesh.set_height(value * 2)
	if x_axis:
		x_axis.set_height(mesh.height)
	if y_axis:
		y_axis.set_height(mesh.height)
	if z_axis:
		z_axis.set_height(mesh.height)
	if reverse_y_axis:
		reverse_y_axis.set_height(mesh.height)


#endregion Update methods


func point_y_axis_toward(target_position: Vector3) -> void:
	var current_origin := global_transform.origin
	var direction := target_position - current_origin

	if direction.length_squared() < 1e-12:
		return

	direction = direction.normalized()

# We want the object's local Y-axis (Vector3.UP in its local untransformed space)
# to align with the 'direction' vector (which is in global space).
# The Quaternion(from_vector, to_vector) constructor creates a quaternion
# that represents the shortest rotation from 'from_vector' to 'to_vector'.
# Thanks Gemini 2.5
	var target_orientation_quat := Quaternion(Vector3.UP, direction).normalized()


# Set the object's orientation using this quaternion.
# This directly sets the rotation part of the global_transform.
	# var new_quat := Quaternion(Vector3.UP, direction).normalized()
	if not quaternion.is_equal_approx(target_orientation_quat):
		quaternion = target_orientation_quat
	quaternion = target_orientation_quat
	
# For debugging:
# var final_basis = Basis(target_orientation_quat)
# print("Target Y (World):%s" % str(final_basis.y)) # Should be 'direction'
# print("New Basis X (World):%s" % str(final_basis.x))
# print("New Basis Z (World):%s" % str(final_basis.z))
# print("New Basis (World):%s\n---" % str(final_basis))

func update_comet_orientation(pa: float, incl: float) -> void:
	print("AA")
	if not is_node_ready():
		return
	# Convert to radians
	var azimuth_rad := deg_to_rad(pa)
	var inclination_rad := deg_to_rad(-incl - 90)

	# Spherical to Cartesian conversion
	var x := sin(inclination_rad) * sin(azimuth_rad)
	var y := cos(inclination_rad)
	var z := sin(inclination_rad) * cos(azimuth_rad)

	var direction := Vector3(x, y, z).normalized()
	direction = direction.rotated(Vector3.LEFT, deg_to_rad(-90))
	# debug_sphere.global_position = global_transform.origin + direction * mesh.radius * 3
	point_y_axis_toward(global_transform.origin + direction)


	# Log equatorial basis
	var eq_basis_tmp: String = "X: " + str(transform.basis.x) + "\nY: " + str(transform.basis.y) + "\nZ: " + str(transform.basis.z)
	Util.log_equatorial_label.text = eq_basis_tmp


func rotate_equatorial_to_orbital() -> void:
	# saving equatorial rotation for future use (like undoing the rotation)
	# rotating the comet so that the X axis points toward the sun
	look_at(Util.sun_direction_vector, Vector3.UP)
	rotate(transform.basis.y, deg_to_rad(-90))
	# normalizing the basis (axes orthogonal and unitary)
	transform.basis = transform.basis.orthonormalized()

	# Log orbital basis
	var orb_basis_tmp: String = "X: " + str(transform.basis.x) + "\nY: " + str(transform.basis.y) + "\nZ: " + str(transform.basis.z)
	Util.log_orbital_label.text = orb_basis_tmp

func reset_rotation_to_equatorial() -> void:
	quaternion = Util.equatorial_rotation

	# Log equatorial basis
	var eq_basis_tmp: String = "X: " + str(transform.basis.x) + "\nY: " + str(transform.basis.y) + "\nZ: " + str(transform.basis.z)
	Util.log_equatorial_label.text = eq_basis_tmp
	print("Reset comet rotation to saved equatorial rotation.")
