extends Node3D

var particles_alive:Array[MeshInstance3D]
var time_start:float
var time_now:float
var _sphere_mesh:SphereMesh
@export var max_particles:int = 10
@export var particle_per_second:int = 5
@export var particle_radius:float = 0.1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_start = Time.get_ticks_msec()
	
	var unshaded_material = StandardMaterial3D.new()
	unshaded_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	unshaded_material.albedo_color = Color.WHITE
	
	_sphere_mesh = SphereMesh.new()
	_sphere_mesh.radius = particle_radius
	_sphere_mesh.height = particle_radius*2
	_sphere_mesh.surface_set_material(0,unshaded_material)
	
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_now = Time.get_ticks_msec()
	if time_now-time_start> 1000 * 1.0/particle_per_second:
		#var my_mesh = MeshInstance3D.new()
		#add_child(my_mesh)
		#my_mesh.mesh = _sphere_mesh
		#my_mesh.top_level = true
		#if particles_alive.size() < max_particles:
			## at least 1 second has passed thus I spawn another child
			#time_start = Time.get_ticks_msec()
			#particles_alive.append(my_mesh)
		#else:
			#particles_alive[0].queue_free()
			#particles_alive.append(my_mesh)
			#particles_alive = particles_alive.slice(1,-1)
		time_start = Time.get_ticks_msec()
		var my_mesh:MeshInstance3D	
		if particles_alive.size() < max_particles:
			my_mesh = MeshInstance3D.new()
			my_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			
			add_child(my_mesh)
			my_mesh.mesh = _sphere_mesh
			my_mesh.top_level = true
			particles_alive.append(my_mesh)
		else:
			my_mesh = particles_alive.pop_front()
			my_mesh.global_position = global_position
			particles_alive.append(my_mesh)
	for particle in particles_alive:
		particle.global_position.x +=1*delta
		
	#var current_angle = angular_speed * time_now
#
	#for particle in particles_alive:
		#particle.position.x = helix_center.x + radius * cos(current_angle)*0.01
		#particle.position.y = helix_center.y + pitch_factor * current_angle*0.01
		#particle.position.z = helix_center.z + radius * sin(current_angle)*0.01
	pass
