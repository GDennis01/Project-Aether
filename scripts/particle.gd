extends Node3D
class_name Particle
var normal_direction: Vector3 = Vector3(0, 1, 0)
var enabled: bool = true
var time_to_live: float = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# update only if it's rotating
	# if enabled:
	if false:
		global_position = global_position + normal_direction * delta
		time_to_live -= 1 * delta
		if is_zero_approx(time_to_live):
			self.queue_free()
"""
A single unit movement of the particle.
TODO: how to move it based on speed
"""
func tick() -> void:
	global_position = global_position + normal_direction * 0.01