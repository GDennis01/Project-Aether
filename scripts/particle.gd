extends Node3D
class_name Particle
var normal_direction: Vector3 = Vector3(0, 1, 0)
var enabled: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# if enabled:
	global_position = global_position + normal_direction * delta
