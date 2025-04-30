@tool
extends Node3D
class_name AxisArrow
@export var arrow_arm:MeshInstance3D
@export var arrow_head:MeshInstance3D
@export var height: float = 1.0: set=set_height
@export var color:Color

var _original_arm_mesh_height:float = 1.0
var _original_arm_mesh_scale:Vector3 = Vector3.ONE

enum AxisType{X,Y,Z}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#arrow_arm.mesh.material.albedo_color = color
	#arrow_head.mesh.material.albedo_color = color
	_original_arm_mesh_scale = arrow_arm.scale
	_original_arm_mesh_height = arrow_arm.mesh.height
	
	#set_height(height)

func set_axis_type(type:AxisType):
	const ALPHA:float = 0.4
	match type:
		AxisType.X: # pitch axis
			rotation_degrees.z = -90
			position = Vector3(height/2,0,0)
			arrow_arm.get_surface_override_material(0).albedo_color = Color(Color.RED,ALPHA)
			arrow_head.get_surface_override_material(0).albedo_color = Color(Color.RED,ALPHA)
			pass
		AxisType.Y:
			# default axis(yaw)
			position = Vector3(0,height/2,0)
			arrow_arm.get_surface_override_material(0).albedo_color = Color(Color.GREEN,ALPHA)
			arrow_head.get_surface_override_material(0).albedo_color = Color(Color.GREEN,ALPHA)
			pass
		AxisType.Z: # roll axis
			rotation_degrees.x = 90
			position=Vector3(0,0,height/2)
			arrow_arm.get_surface_override_material(0).albedo_color = Color(Color.BLUE,ALPHA)
			arrow_head.get_surface_override_material(0).albedo_color = Color(Color.BLUE,ALPHA)
			pass
		
func set_height(value:float)->void:
	height = max(0.01,value)
	if is_node_ready():
		# scaling arrow arm
		var required_y_scale  =(height/ _original_arm_mesh_height)
		arrow_arm.scale = Vector3(_original_arm_mesh_scale.x,required_y_scale,_original_arm_mesh_scale.z)
		#arrow_arm.position = Vector3(arrow_arm.position.x,arrow_arm.position.y+height/2,arrow_arm.position.z)
		# positioning arrow head
		var head_y_position = height/2.0
		arrow_head.position = Vector3(arrow_head.position.x,head_y_position,arrow_head.position.z)
		
func toggle_axis()->void:
	visible = not visible		
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass
