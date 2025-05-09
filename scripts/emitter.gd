extends Node3D
class_name Emitter
const RAY_LENGHT = 1000000

var particles_alive: Array[MeshInstance3D]
var time_start: float
var time_now: float
var _sphere_mesh: SphereMesh
var comet_radius: float

# properties of emitter/jet_entry
var jet_id: int
var speed: float
var latitude: float
var longitude: float
var diffusion: float
var color: Color

var is_lit: bool = true
@export var max_particles: int = 10
@export var particle_per_second: int = 5
@export var particle_radius: float = 0.1
@export var enabled: bool = true
@export var light_source: Light3D
@export var comet_collider: CollisionObject3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_start = Time.get_ticks_msec()
	
	var unshaded_material = StandardMaterial3D.new()
	unshaded_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	unshaded_material.albedo_color = Color.WHITE
	
	#$Particle/ParticleArea/ParticleShape.shape.set_radius($Particle.mesh.radius)
	$Particle/ParticleArea/ParticleShape.shape.set_radius($Particle.mesh.radius)
	
	_sphere_mesh = SphereMesh.new()
	_sphere_mesh.radius = particle_radius
	_sphere_mesh.height = particle_radius * 2
	_sphere_mesh.surface_set_material(0, unshaded_material)
	
func _physics_process(_delta: float) -> void:
	if not visible:
		return
	var space_state := get_world_3d().direct_space_state
	var has_line_of_sight: bool
	
	#var ray_origin = global_position
	#var light_dir_vector = light_source.global_transform.basis.z.normalized()
	#var ray_end = ray_origin+light_dir_vector*RAY_LENGHT
	#DebugLine.DrawLine(ray_origin,ray_end,Color(0,255,0))

	#var query = PhysicsRayQueryParameters3D.create(ray_origin,ray_end)
	var light_pos = light_source.global_position
	var light_dir_vector = light_source.global_transform.basis.z.normalized()
	var emitter_pos = global_position
	DebugLine.DrawLine(light_pos, emitter_pos, Color(0, 255, 0))

	var query = PhysicsRayQueryParameters3D.create(light_pos, emitter_pos)
	query.collide_with_areas = true
	#query.collide_with_bodies = true
	
	query.exclude = [$Particle/ParticleArea.get_rid()]
	var result := space_state.intersect_ray(query)

	# TODO: fare in modo che is_lit venga settato da una state machine o roba simile.
	# Così almeno non si bugga all'inizio alla prima iterazione
	# Oppure convertire tutto sto processo in un metodo e richiamarlo al ready per settare
	# lo stato iniziale di is_lit
	if not is_lit and result.is_empty():
		#enabled = true
		#print("LIT\n")
		is_lit = true
		$Particle.get_surface_override_material(0).albedo_color = Color.WHITE
	elif is_lit and not result.is_empty():
		is_lit = false
		#print("NOT LIT\n"+str(result))
		$Particle.get_surface_override_material(0).albedo_color = Color.RED
	#else:
	#print(result)
		#enabled = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time_now = Time.get_ticks_msec()
	
	if enabled and time_now - time_start > 1000 * 1.0 / particle_per_second:
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
		var my_mesh: MeshInstance3D
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
		particle.global_position.x += 1 * delta
		
	#var current_angle = angular_speed * time_now
	#for particle in particles_alive:
		#particle.position.x = helix_center.x + radius * cos(current_angle)*0.01
		#particle.position.y = helix_center.y + pitch_factor * current_angle*0.01
		#particle.position.z = helix_center.z + radius * sin(current_angle)*0.01
	pass


###################################################################################
# Update methods called when sanitized_edit.sanitized_edit_focus_exited is emitted
# Connection of signals is done in JetTable._on_add_jet_entry_btn_pressed
###################################################################################
func update_position(radius: float) -> void:
	var new_pos = Util.latlon_to_vector3(latitude, longitude + 90, radius)
	position = new_pos
func update_speed(_speed: float) -> void:
	print("new__speed:" + str(_speed))
	pass
func update_lat(lat: float) -> void:
	print("new_lat:" + str(lat))
	latitude = lat
	var new_pos = Util.latlon_to_vector3(latitude, longitude, comet_radius)
	position = new_pos
func update_long(long: float) -> void:
	print("new_long:" + str(long))
	longitude = long + 90
	var new_pos = Util.latlon_to_vector3(latitude, longitude, comet_radius)
	position = new_pos
func update_diff(_diffusion: float) -> void:
	print("new_diff:" + str(_diffusion))
	pass
func update_color(_color: Color) -> void:
	print("new_color:" + str(_color))
	color = _color
