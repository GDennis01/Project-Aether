extends Camera3D
class_name RotatingCamera

# --- EXPORTED VARIABLES (Editable in Inspector) ---
@export var target_node_path: NodePath # Path to the node we want to orbit (e.g., your sphere)
@export var distance: float = 5.0 # Initial distance from the target
@export var min_distance: float = 1.0
@export var max_distance: float = 20.0
@export var sensitivity: float = 0.005 # Mouse sensitivity for rotation
@export var zoom_sensitivity: float = 0.5 # Mouse wheel sensitivity for zoom
@export var pitch_limit_degrees: float = 89.0 # How far up/down you can look (prevents flipping)

# --- INTERNAL VARIABLES ---
@onready var _target_node: Node3D = $"/root/World/CometMesh"
var _target_position: Vector3 = Vector3.ZERO # Where the camera looks

var _yaw: float = 0.0 # Rotation around Y-axis (horizontal)
var _pitch: float = 0.3 # Rotation around X-axis (vertical)
var _is_dragging: bool = false

func _ready() -> void:
	# # Attempt to get the target node if the path is set
	# if not target_node_path.is_empty():
	# 	# _target_node = get_node_or_null(target_node_path)
	# 	# _target_node = $"/root/World/CometMesh"
	# 	if _target_node:
	# 		print("OrbitCamera: Target node found: ", _target_node.name)
	# 	else:
	# 		printerr("OrbitCamera: Target node not found at path: ", target_node_path)
	# else:
	# 	printerr("OrbitCamera: Target Node Path is not set in the Inspector!")
	# Initial camera position update
	_update_camera_transform()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.is_pressed()
			if _is_dragging:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clamp(distance - zoom_sensitivity, min_distance, max_distance)
			_update_camera_transform()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clamp(distance + zoom_sensitivity, min_distance, max_distance)
			_update_camera_transform()

	elif event is InputEventMouseMotion and _is_dragging:
		_yaw -= event.relative.x * sensitivity
		_pitch -= event.relative.y * sensitivity
		_pitch = clamp(_pitch, -deg_to_rad(pitch_limit_degrees), deg_to_rad(pitch_limit_degrees))
		_update_camera_transform()

func _process(_delta: float) -> void:
	# If the target node moves, we want to follow it
	if _target_node:
		var current_target_pos := _target_node.global_transform.origin
		if current_target_pos != _target_position:
			_target_position = current_target_pos
			_update_camera_transform() # Update if target moved, even if no input

func _update_camera_transform() -> void:
	if _target_node:
		_target_position = _target_node.global_transform.origin
	# else, it uses the default _target_position (Vector3.ZERO or whatever it was last)

	# Calculate camera position based on yaw, pitch, and distance
	var new_transform := Transform3D.IDENTITY
	new_transform = new_transform.rotated(Vector3.UP, _yaw) # Apply yaw
	new_transform = new_transform.rotated(new_transform.basis.x, _pitch) # Apply pitch relative to new yaw

	# Position the camera 'distance' units away along its new Z-axis
	# The camera looks along its -Z axis by default, so we move it along +Z
	global_transform.origin = _target_position + new_transform.basis.z * distance

	# Make the camera look at the target
	look_at(_target_position, Vector3.UP)

	# Ensure global_transform is updated for other nodes if needed immediately
	# This is usually handled by the scene tree, but can be forced.
	# force_update_transform() # Generally not needed, but good to know.
