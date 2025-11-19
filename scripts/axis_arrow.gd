extends Node3D
class_name AxisArrow
@export var arrow_arm: MeshInstance3D
@export var arrow_head: MeshInstance3D
@export var height: float = 1.0
@export var color: Color

var _original_arm_mesh_height: float = 1.0
var _original_arm_mesh_scale: Vector3 = Vector3.ONE

enum AXIS_TYPE {X, Y, Z, SUN, REVERSE_Y}
var axis_type: AXIS_TYPE
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_original_arm_mesh_scale = arrow_arm.scale
	_original_arm_mesh_height = arrow_arm.mesh.height
	
	#set_height(height)

func set_axis_type(type: AXIS_TYPE) -> void:
	const ALPHA: float = 0.4
	axis_type = type
	match axis_type:
		AXIS_TYPE.X: # pitch axis
			rotation_degrees.z = -90
			position = Vector3(height / 2, 0, 0)
			# rotation_degrees.x = 90
			# position = Vector3(0, 0, height / 2)

			
			arrow_arm.get_surface_override_material(0).albedo_color = Color(Color.RED, ALPHA)
			arrow_head.get_surface_override_material(0).albedo_color = Color(Color.RED, ALPHA)
			pass
		AXIS_TYPE.Y:
			# default axis(yaw)
			position = Vector3(0, height / 2, 0)
			arrow_arm.get_surface_override_material(0).albedo_color = Color(Color.GREEN, ALPHA)
			arrow_head.get_surface_override_material(0).albedo_color = Color(Color.GREEN, ALPHA)
			pass
		AXIS_TYPE.REVERSE_Y:
			rotation_degrees.y = 180
			position = Vector3(0, -height / 4, 0)
			arrow_arm.get_surface_override_material(0).albedo_color = Color(Color.GREEN, ALPHA)
			arrow_head.get_surface_override_material(0).albedo_color = Color(Color.GREEN, ALPHA)
			pass
		AXIS_TYPE.Z: # roll axis
			rotation_degrees.x = 90
			position = Vector3(0, 0, height / 2)
			# rotation_degrees.z = -90
			# position = Vector3(height / 2, 0, 0)
			arrow_arm.get_surface_override_material(0).albedo_color = Color(Color.BLUE, ALPHA)
			arrow_head.get_surface_override_material(0).albedo_color = Color(Color.BLUE, ALPHA)
			pass
		AXIS_TYPE.SUN:
			position.z -= 0.01
			rotation_degrees.x = -90
			# FIXME: fix position
			position = Vector3(0, 0, 0)
			arrow_arm.get_surface_override_material(0).albedo_color = Color(Color.YELLOW, ALPHA)
			arrow_head.get_surface_override_material(0).albedo_color = Color(Color.YELLOW, ALPHA)
			pass
		
func set_height(value: float, distance: float = 0) -> void:
	height = max(0.01, value)
	if is_node_ready():
		# scaling arrow arm
		var required_y_scale := (height / _original_arm_mesh_height)
		arrow_arm.scale = Vector3(required_y_scale, required_y_scale, required_y_scale)
		arrow_head.scale = Vector3(required_y_scale, required_y_scale, required_y_scale)
		# offsetting by the original height(which is 2 so 2/4 = 0.5) so that the arm is centered in the center of the mesh
		match axis_type:
			AXIS_TYPE.SUN:
				# arrow_arm.position.y = distance - Util.comet_radius * 2.05 - height / 2
				arrow_arm.position.y = distance - 1.5

				# arrow_head.position.y = distance - height / 2 - Util.comet_radius * 2.05
				arrow_head.position.y = distance - 1
				# position.z = position.z - distance
			AXIS_TYPE.REVERSE_Y:
				arrow_head.scale = Vector3.ZERO
				arrow_arm.scale = arrow_arm.scale * 0.9
				arrow_arm.position.y = - height / 4 + _original_arm_mesh_height / 8
				
			_:
				arrow_arm.position.y = height / 2 - _original_arm_mesh_height / 4
				# positioning arrow heads
				arrow_head.position.y = height - _original_arm_mesh_height / 4


# func toggle_axis(type: AXIS_TYPE) -> void:
# 	if type == axis_type:
# 		visible = not visible
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
