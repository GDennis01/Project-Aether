extends SubViewport
@export var _fr_camera: Camera3D
@export var _rot_camera: Camera3D

## Switch between a rotating camera and a free roam camera.
## This function saves the current camera state and switches to the other camera, loading its state.
func change_camera() -> void:
	if _fr_camera.current:
		# sets the current camera to the rotating camera
		_rot_camera.current = true
		_fr_camera.current = false
		# disable input for the free roam camera and enable the rotating camera
		_rot_camera.enabled = true
		_fr_camera.enabled = false
		Util.current_camera_label.text = "Rotating Camera"
	else:
		# sets the current camera to the free roam camera
		_fr_camera.current = true
		_rot_camera.current = false
		# disable input for the rotating camera and enable the free roam camera
		_fr_camera.enabled = true
		_rot_camera.enabled = false
		Util.current_camera_label.text = "Free Roam Camera"
