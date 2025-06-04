extends SubViewport
@export var _fr_camera: Node3D
@export var _rot_camera: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Manage multiple cameras and switching between them
# TODO: fix this
func change_camera() -> void:
	if _fr_camera.current:
		_rot_camera.current = true
		_fr_camera.current = false
	else:
		_rot_camera.current = false
		_fr_camera.current = true
	# reset_cameras()

func reset_rot_camera() -> void:
	if _rot_camera:
		_rot_camera.global_transform.origin = Vector3.ZERO
		_rot_camera.global_transform.basis = Basis.IDENTITY
		_rot_camera.rotation_degrees = Vector3.ZERO

func reset_fr_camera() -> void:
	if _fr_camera:
		_fr_camera.global_transform.origin = Vector3.ZERO
		_fr_camera.global_transform.basis = Basis.IDENTITY
		_fr_camera.rotation_degrees = Vector3.ZERO
		_fr_camera.current = true
func reset_cameras() -> void:
	if _fr_camera:
		reset_fr_camera()
	if _rot_camera:
		reset_rot_camera()
