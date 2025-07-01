extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_radius(value: float) -> void:
	# 4 because radius*2 is the diameter, and the axis is 2 units long, so 4 in total
	size = value * 4
func update_mini_camera(new_transform: Transform3D) -> void:
	# Update the mini camera's transform to match the main camera's transform
	# This is called by the rotating camera when it updates its position
	if not is_inside_tree():
		return # Ignore if not in the scene tree
	transform = new_transform
	# transform.origin = cur_pos # Keep the current position, but update the rotation


	# global_transform = new_transform
