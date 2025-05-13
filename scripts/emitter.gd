extends Node3D
class_name Emitter
const RAY_LENGHT = 1000000

var particle_scene := preload("res://scenes/particle.tscn")

var particles_alive: Array[Particle]
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
var norm: Vector3 = Vector3(0, 1, 0)
var initial_norm: Vector3 = Vector3(0, 1, 0)
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

	longitude += 90 # longitude is shifted by 90°

	var lat_rad = deg_to_rad(latitude)
	var lon_rad = deg_to_rad(longitude)
 
	initial_norm = Vector3(
		cos(lat_rad) * cos(lon_rad) * 5,
		sin(lat_rad) * 5,
		cos(lat_rad) * sin(lon_rad) * 5
	).normalized()
	norm = initial_norm
	update_norm()
	
	print(get_parent().global_transform.basis)
	# norm = norm.rotated(Vector3.RIGHT, deg_to_rad(longitude))


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


func _process(_delta: float) -> void:
	# time_now = Time.get_ticks_msec()
	# if enabled and is_lit and time_now - time_start > 1000 * 1.0 / particle_per_second:
	# 	time_start = Time.get_ticks_msec()
	# 	var particle: Particle
	# 	if particles_alive.size() < max_particles:
	# 		particle = particle_scene.instantiate() as Particle
	# 		# particle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# 		particle.top_level = true
	# 		particle.normal_direction = norm
	# 		particle.enabled = true
	# 		particle.global_position = self.global_position
	# 		particle.time_to_live = 10
	# 		add_child(particle)
	# 		particle.add_to_group("particle")
	# 		particles_alive.append(particle)
	# 	update_norm()
	pass
func tick() -> void:
	# trigger tick() on every particles alive
	for particle in particles_alive:
		particle.tick()
	# then spawn a new particle if needed
	if is_lit and particles_alive.size() < max_particles:
		var particle := particle_scene.instantiate() as Particle
		# particle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		particle.top_level = true
		particle.normal_direction = norm
		particle.enabled = true
		particle.time_to_live = 10
		add_child(particle)
		particle.global_position = self.global_position
		particle.add_to_group("particle")
		particles_alive.append(particle)
	update_norm()

func reset_particles() -> void:
	for particle in particles_alive:
		particle.queue_free()
	particles_alive.clear()

###################################################################################
# Update methods called when sanitized_edit.sanitized_edit_focus_exited is emitted
# Connection of signals is done in JetTable._on_add_jet_entry_btn_pressed
###################################################################################
#region update methods
func update_position(radius: float) -> void:
	var new_pos = Util.latlon_to_vector3(latitude, longitude + 90, radius)
	position = new_pos
func update_speed(_speed: float) -> void:
	print("new__speed:" + str(_speed))
	pass
func update_lat(lat: float) -> void:
	print("new_lat:" + str(lat))
	print("new_long:" + str(longitude))
	latitude = lat
	var new_pos = Util.latlon_to_vector3(latitude, longitude, comet_radius)
	position = new_pos
	update_initial_norm(latitude, longitude)
func update_long(long: float) -> void:
	print("new_lat:" + str(latitude))
	print("new_long:" + str(long))
	longitude = long + 90
	var new_pos = Util.latlon_to_vector3(latitude, longitude, comet_radius)
	position = new_pos
	update_initial_norm(latitude, longitude)
func update_diff(_diffusion: float) -> void:
	print("new_diff:" + str(_diffusion))
	pass
func update_color(_color: Color) -> void:
	print("new_color:" + str(_color))
	color = _color

func update_initial_norm(_lat: float, _long: float) -> void:
	print("UPDATED NORM")
	var lat_rad = deg_to_rad(_lat)
	var lon_rad = deg_to_rad(_long)
	initial_norm = Vector3(
		cos(lat_rad) * cos(lon_rad) * 5,
		sin(lat_rad) * 5,
		cos(lat_rad) * sin(lon_rad) * 5
	).normalized()
	norm = initial_norm
	update_norm()
func update_norm() -> void:
	# print(get_parent().rotation_angle)
	var rotation_matrix: Basis = get_parent().global_transform.basis
	norm = initial_norm * rotation_matrix.inverse()
	norm = norm.normalized()
	pass
#endregion update methods
