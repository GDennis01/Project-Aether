extends Node3D
class_name Emitter
const RAY_LENGHT = 1000000
const N_POINTS = 50
# const N_POINTS = 0

var particle_scene := preload("res://scenes/particle.tscn")
# @onready var comet: MeshInstance3D = $"/root/World/CometMesh"

var particles_alive: Array[Particle]

var _sphere_mesh: SphereMesh
# var _box_mesh: BoxMesh
var _point_mesh: PointMesh

# properties of emitter/jet_entry
var jet_id: int
var speed: float
var latitude: float
var longitude: float
var diffusion: float
var color: Color

## acceleration of a single particle
var a: float = 0.0


#multimesh
var mm_emitter: MultiMeshInstance3D = MultiMeshInstance3D.new()
var global_positions: Array[Vector3] ## global position of the mm_emitter at each instance spawned
var initial_positions: Array[Vector3] ## initial position of the mm_emitter at each instance spawned
var particle_speeds: Array[float] ## speeds of each particle
var normal_dirs: Array[Vector3] ## normal_dir of the mm_emitter at each instance spawned
var time_alive: Array[int] = [] # number of ticks each particle has been alive
var total_space: Array[float] = [] # total space travelled by the particles

#sim related
var num_particles: int = 0

var is_lit: bool = true
@export var max_particles: int = 10
@export var particle_per_second: int = 5
@export var particle_radius: float = 0.05
@export var enabled: bool = true
@export var light_source: Light3D
@export var comet_collider: CollisionObject3D
var norm: Vector3 = Vector3(0, 1, 0)
var initial_norm: Vector3 = Vector3(0, 1, 0)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var unshaded_material := StandardMaterial3D.new()
	unshaded_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	# unshaded_material.albedo_color = Color.WHITE
	unshaded_material.vertex_color_use_as_albedo = true
	
	#$Particle/ParticleArea/ParticleShape.shape.set_radius($Particle.mesh.radius)
	$Particle/ParticleArea/ParticleShape.shape.set_radius($Particle.mesh.radius)
	
	_sphere_mesh = SphereMesh.new()
	_sphere_mesh.radius = particle_radius
	_sphere_mesh.height = particle_radius * 2
	_sphere_mesh.surface_set_material(0, unshaded_material)
	# to reduce the polygons
	_sphere_mesh.radial_segments = 4
	_sphere_mesh.rings = 2

	_point_mesh = PointMesh.new()
	unshaded_material.use_point_size = true
	unshaded_material.point_size = particle_radius / 2
	
	_point_mesh.surface_set_material(0, unshaded_material)
	
	# _box_mesh = BoxMesh.new()
	# _box_mesh.size = Vector3(particle_radius, particle_radius, particle_radius)
	# _box_mesh.surface_set_material(0, unshaded_material)
	# to reduce the polygons

	longitude += 90 # longitude is shifted by 90°

	var lat_rad := deg_to_rad(latitude)
	var lon_rad := deg_to_rad(longitude)
 
	initial_norm = Vector3(
		cos(lat_rad) * cos(lon_rad) * 5,
		sin(lat_rad) * 5,
		cos(lat_rad) * sin(lon_rad) * 5
	).normalized()
	norm = initial_norm
	update_norm()

	init_multimesh(mm_emitter)
	add_child(mm_emitter)
	mm_emitter.global_position = Vector3(0, 0, 0)
	# mm_emitter.basis = Util.orbital_basis
	# for top_level = true
	# mm_emitter.global_position = global_position
	
	# norm = norm.rotated(Vector3.RIGHT, deg_to_rad(longitude))
	update_acceleration()

	# get_parent().debug_sphere.global_position = global_transform.origin + norm * 0.5 * 3
	# print("albedo:%f p:%f d:%f D:%f  a:%.10f" % [Util.albedo, Util.particle_density, Util.particle_diameter, Util.sun_comet_distance, a])

func init_multimesh(multi_mesh_istance: MultiMeshInstance3D) -> void:
	# init multimesh object
	multi_mesh_istance.multimesh = MultiMesh.new()
	multi_mesh_istance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	mm_emitter.multimesh.use_colors = true
	mm_emitter.multimesh.use_custom_data = true
	# init instance count(max particles) to an arbitrary number bc yes lol
	multi_mesh_istance.multimesh.instance_count = 1000
	multi_mesh_istance.multimesh.visible_instance_count = 0 # 0 so no particles are shown at the beginning
	# setting particle radius
	multi_mesh_istance.multimesh.mesh = _point_mesh
	# multi_mesh_istance.multimesh.mesh = _sphere_mesh
	# multi_mesh_istance.multimesh.mesh = _box_mesh

	multi_mesh_istance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	multi_mesh_istance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	multi_mesh_istance.lod_bias = 0.0001
	multi_mesh_istance.ignore_occlusion_culling = true
	# only the second layer is used for the particles, so that MiniCamera doesn't render them
	multi_mesh_istance.set_layer_mask_value(1, false)
	multi_mesh_istance.set_layer_mask_value(2, true)
	mm_emitter.top_level = true
	# mm_emitter.global_position = Vector3(0, 0, 0)
	
func _physics_process(_delta: float) -> void:
	if not visible:
		return
	var space_state := get_world_3d().direct_space_state
	# var has_line_of_sight: bool
	
	#var ray_origin = global_position
	#var light_dir_vector = light_source.global_transform.basis.z.normalized()
	#var ray_end = ray_origin+light_dir_vector*RAY_LENGHT
	#DebugLine.DrawLine(ray_origin,ray_end,Color(0,255,0))

	#var query = PhysicsRayQueryParameters3D.create(ray_origin,ray_end)
	var light_pos := light_source.global_position
	# var light_dir_vector := light_source.global_transform.basis.z.normalized()
	var emitter_pos := global_position


	# DebugLine.DrawLine(light_pos, emitter_pos, Color(0, 255, 0))

	var query := PhysicsRayQueryParameters3D.create(light_pos, emitter_pos)
	query.collide_with_areas = true
	#query.collide_with_bodies = true
	
	query.exclude = [$Particle/ParticleArea.get_rid()]
	var _result := space_state.intersect_ray(query)

	# TODO: fare in modo che is_lit venga settato da una state machine o roba simile.
	# Così almeno non si bugga all'inizio alla prima iterazione
	# Oppure convertire tutto sto processo in un metodo e richiamarlo al ready per settare
	# lo stato iniziale di is_lit
	## Raycasting-based solution
	# if not is_lit and result.is_empty():
	# 	#enabled = true
	# 	#print("LIT\n")
	# 	is_lit = true
	# 	$Particle.get_surface_override_material(0).albedo_color = Color.WHITE
	# elif is_lit and not result.is_empty():
	# 	is_lit = false
	# 	#print("NOT LIT\n"+str(result))
	# 	$Particle.get_surface_override_material(0).albedo_color = Color.RED

	## Dotproduct-based solution
	is_lit = is_lit_math()
	if is_lit:
		$Particle.get_surface_override_material(0).albedo_color = Color.WHITE
	else:
		$Particle.get_surface_override_material(0).albedo_color = Color.RED


## Returns whether the emitter is lit by the sun or not, 
## based on sun inclination and direction angle, comet inclination and comet current rotation angle
## FIXME: probably this doesn't work properly
func is_lit_math() -> bool:
	var comet_basis: Basis = get_parent().global_transform.basis
	var global_space_normal: Vector3 = comet_basis * norm
	# var global_space_normal: Vector3 = comet_basis * norm
	global_space_normal = global_space_normal.normalized().rotated(Vector3.LEFT, deg_to_rad(Util.sun_direction + 90))
	var result: float = (Util.sun_direction_vector).dot(global_space_normal)
	# print("Result: %f Result<0: %s" % [result, str(result > 0)])
	result = (-Util.sun_direction_vector).dot(norm)
	is_lit = result > 0
	return is_lit

func is_lit_math2(_n_step: int, _angle_per_step: float, _normal: Vector3) -> bool:
	var comet_basis: Basis = get_parent().global_transform.basis
	comet_basis = comet_basis * comet_basis.rotated(Vector3.UP, deg_to_rad(_n_step * _angle_per_step))
	# var comet_basis: Basis = get_parent().global_transform.basis
	# var global_space_normal: Vector3 = comet_basis * norm
	var global_space_normal: Vector3 = _normal.normalized().rotated(Vector3.LEFT, deg_to_rad(Util.sun_direction + 90))
	var result: float = (Util.sun_direction_vector).dot(global_space_normal)
	# print("Result: %f Result<0: %s" % [result, str(result > 0)])
	result = (-Util.sun_direction_vector).dot(_normal)
	is_lit = result > 0
	return is_lit


#region Simulation related
## Instant simulation of n_steps with angle_per_step each step.
## First, it computes when each particle spawns, then based on that it computes the final position of each particle.
func instant_simulation(_n_steps: int, _angle_per_step: float) -> void:
	mm_emitter.multimesh.instance_count = 0
	mm_emitter.multimesh.use_colors = true
	mm_emitter.multimesh.use_custom_data = false

	var particle_transforms: Array[Transform3D] = []
	var _normal_dirs: Array[Vector3] = []
	var time_alive2: Array[int] = []
	var mm_buffer: PackedFloat32Array = PackedFloat32Array()
	# var total_space_cumulative: Array[float] = []
	# for each steps i, compute position of ith particle (if it's spawned)
	# ie: at step 40(out of 100) the emitter is lit and thus spawns a particle -> compute that particle position at the end of simulation (step 100)
	for i in range(_n_steps):
		var comet_basis: Basis = get_parent().global_transform.basis
		comet_basis = comet_basis * Basis(Vector3.UP, deg_to_rad((i + 1) * _angle_per_step))
		var _normal := update_norm2(initial_norm, comet_basis)
		_normal_dirs.append(_normal)
		# continue to next 
		if not is_lit_math2(i, _angle_per_step, _normal):
			continue
		time_alive2.append(i) # time alive is the number of steps left until the end of simulation

		# _n_steps - i so that it correctly defines the time the ith particle has been alive (ie: i=0, nsteps=100 -> particle alive for 100)
		# just i would've worked just fine but it wasn't logically correct
		var ith_transform := _accelerate_particle2(_n_steps - i, _normal)
		particle_transforms.append(ith_transform)
		_append_data_to_mm_buffer(mm_buffer, ith_transform, color)
	# if diffusion > 0:
	# 	var total_space_cumulative := 0.0
	# 	for i in range(particle_transforms.size()):
	# 		if i > 0:
	# 			var delta = (particle_transforms[i].origin
	# 					- particle_transforms[i - 1].origin).length()
	# 			total_space_cumulative += delta
	# 		# now use the cumulative path-length as the radius:
	# 		var diff_cloud = _generate_diffusion_particles2(
	# 			total_space_cumulative,
	# 			particle_transforms[i].origin
	# 		)
	# 		for p in diff_cloud:
	# 			_append_data_to_mm_buffer(mm_buffer, p, Color.YELLOW)

	# numerical integration to reconstruct diffusion particles
	if diffusion > 0:
		@warning_ignore("integer_division")
		var SUBSTEPS: int = clamp(_n_steps / 10, 10, 150)
		for idx in range(particle_transforms.size()):
			var final_t := particle_transforms[idx]
			var age := _n_steps - time_alive2[idx] # however you tracked “time_alive2” per particle
			var normal := _normal_dirs[idx] # same for your _normal passed in

			# approximate arc‐length via sampling:
			var travelled_space := 0.0
			var prev_pos := Vector3.ZERO
			for s in range(1, SUBSTEPS + 1):
				@warning_ignore("integer_division")
				var sub_age := int(age * s / SUBSTEPS)
				var sub_t := _accelerate_particle2(sub_age, normal)
				var pos := sub_t.origin
				travelled_space += (pos - prev_pos).length()
				prev_pos = pos

			# now generate small cloud around the *true* path‐length:
			var cloud := _generate_diffusion_particles2(travelled_space, final_t.origin)
			for p in cloud:
				_append_data_to_mm_buffer(mm_buffer, p, color)
	@warning_ignore("integer_division")
	mm_emitter.multimesh.instance_count = mm_buffer.size() / 16 # 16 is the number of floats per instance (12 for transform, 4 for color)
	print("Emitter %d multimesh instance count: %d" % [jet_id, mm_emitter.multimesh.instance_count])
	mm_emitter.multimesh.visible_instance_count = -1
	mm_emitter.multimesh.set_buffer(mm_buffer)
func _accelerate_particle2(time_alive2: int, _normal_dir: Vector3) -> Transform3D:
	# --- 1. Get Particle-Specific Data ---
	var new_basis := Util.orbital_basis
	var time_passed: float = time_alive2 * Util.jet_rate * 60.0
	# --- 2. Calculate Initial Global Velocity and Acceleration Term  in the global space ---
	var global_initial_velocity: Vector3 = _normal_dir * speed
	var sun_accel_magnitude: float = 0.5 * a * (time_passed ** 2)
	# --- 3. Change of Basis ---
	var local_velocity := global_initial_velocity * new_basis
	# --- 4. Calculate Displacement in the new space  ---
	var local_displacement := Vector3(local_velocity * time_passed)
	local_displacement.x -= sun_accel_magnitude
	# --- 5. Convert Local Displacement back to a Global Vector ---
	var global_displacement: Vector3 = local_displacement * new_basis.transposed()
	# --- 6. Calculate Final Global Position ---
	var final_global_position: Vector3 = Vector3.ZERO + global_displacement
	var scaled_final_pos := final_global_position / (Util.scale / 500)
	global_positions.append(scaled_final_pos)
	# total_space[i] += (scaled_final_pos - global_positions[i]).length() # update total space travelled by the particle
	# --- 7. Create the Final Transform and Set it ---
	var final_global_transform := Transform3D(new_basis, scaled_final_pos)
	return final_global_transform
func _generate_diffusion_particles2(travelled_space: float, particle_origin: Vector3) -> Array[Transform3D]:
	if N_POINTS <= 0:
		# return # no diffusion particles to generate
		return []
	var diffusion_particles: Array[Transform3D] = []
	var pc_radius := travelled_space * (diffusion / 100) * 1 # pointcloud radius based on total space travelled by the particle and diffusion factor
	# print("Radius:%f" % pc_radius)
	for i in range(N_POINTS):
		# generating a random position around the particle
		var new_pos := Util.generate_gaussian_vector(0, 1, pc_radius)
		diffusion_particles.append(Transform3D(Basis(), particle_origin + new_pos))
	return diffusion_particles

## Append data to a multimesh buffer. https://docs.godotengine.org/en/stable/classes/class_renderingserver.html#class-renderingserver-method-multimesh-set-buffer
func _append_data_to_mm_buffer(buffer: PackedFloat32Array, transf: Transform3D, _color: Color) -> void:
	# basis.x.x, basis.y.x, basis.z.x, origin.x, basis.x.y, basis.y.y, basis.z.y, origin.y, basis.x.z, basis.y.z, basis.z.z, origin.z).
	buffer.append(transf.basis.x.x)
	buffer.append(transf.basis.y.x)
	buffer.append(transf.basis.z.x)
	buffer.append(transf.origin.x)
	buffer.append(transf.basis.x.y)
	buffer.append(transf.basis.y.y)
	buffer.append(transf.basis.z.y)
	buffer.append(transf.origin.y)
	buffer.append(transf.basis.x.z)
	buffer.append(transf.basis.y.z)
	buffer.append(transf.basis.z.z)
	buffer.append(transf.origin.z)
	buffer.append(_color.r)
	buffer.append(_color.g)
	buffer.append(_color.b)
	buffer.append(_color.a)
func tick_optimized(_n_iteration: int) -> void:
	# moving each particle
	# print("Iteration: %d" % _n_iteration)
	# print_global_array_size()
	for i in range(0, mm_emitter.multimesh.visible_instance_count, N_POINTS + 1):
		## accelerating only main particles, so every N_POINTS-th particle
		# print("Accelerating particle %d" % i)
		_accelerate_particle(i)
		# print("Generating diffusion particles for particle %d" % i)
		_generate_diffusion_particles(i)
		
	# if _is_lit:
	# whether to spawn a new particle or not
	if is_lit_math():
		# print("Entered here at iteration %d" % _n_iteration)
		# incrementing number of maximum drawn particles (to simulate spawning them)
		var last_id := mm_emitter.multimesh.visible_instance_count + 1
		if last_id < mm_emitter.multimesh.instance_count:
			mm_emitter.multimesh.visible_instance_count = last_id + N_POINTS
		_spawn_particle(last_id)
		# print("Spawned particle at id %d" % (last_id - 1))
	update_norm()
	# print("buffer size: %d" % mm_emitter.multimesh.get_buffer().size())
## Prints the size of the global positions, initial positions, normal directions, particle speeds, time alive and total space arrays


## Update the position of the i-th particle in the multimesh by accelerating it according to the formula in the Vincent's paper.
## The formula is: X = V * t - 1/2 * a * t
## Y= V * t 	Z= V * t
func _accelerate_particle(i: int) -> void:
	# --- 1. Get Particle-Specific Data ---
	var _normal_dir_as_color := mm_emitter.multimesh.get_instance_custom_data(i) as Color
	var _normal_dir := Vector3(_normal_dir_as_color.r, _normal_dir_as_color.g, _normal_dir_as_color.b)
	var new_basis := Basis(Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1))
	new_basis = Util.orbital_basis
	var time_passed: float = time_alive[i] * Util.jet_rate * 60.0
	time_alive[i] += 1
	# --- 2. Calculate Initial Global Velocity and Acceleration Term  in the global space ---
	var global_initial_velocity: Vector3 = _normal_dir * speed
	var sun_accel_magnitude: float = 0.5 * a * (time_passed ** 2)
	# --- 3. Change of Basis ---
	var local_velocity := global_initial_velocity * new_basis
	# --- 4. Calculate Displacement in the new space  ---
	# X = V * t - 1/2 * a * t^2 	Y= V * t 	Z= V * t
	var local_displacement := Vector3(local_velocity * time_passed)
	local_displacement.x -= sun_accel_magnitude
	# --- 5. Convert Local Displacement back to a Global Vector ---
	# This gives us a single displacement vector in the main world space.
	# .transposed() is used to convert the local displacement back to the global space.
	var global_displacement: Vector3 = local_displacement * new_basis.transposed()
	# --- 6. Calculate Final Global Position ---
	var final_global_position: Vector3 = initial_positions[i] + global_displacement
	# Apply your scaling factor
	var scaled_final_pos := final_global_position / (Util.scale / 500)
	total_space[i] += (scaled_final_pos - global_positions[i]).length() # update total space travelled by the particle
	# if i == 0:
	# 	print("%s - %s = %s" % [scaled_final_pos, global_positions[i], (scaled_final_pos - global_positions[i])])
	global_positions[i] = scaled_final_pos
	# add to the total space only the delta travelled by the particle
	# total_space[i] += (global_displacement.length() / (Util.scale / 500)) # update total space travelled by the particle
	# --- 7. Create the Final Transform and Set it ---
	var final_global_transform := Transform3D(new_basis, scaled_final_pos)

	# `set_instance_transform` requires the transform to be LOCAL to the MultiMeshInstance3D node.
	# We convert our desired global transform into a local one.
	# var instance_local_transform := mm_global_inverse * final_global_transform
	var instance_local_transform := final_global_transform
	mm_emitter.multimesh.set_instance_transform(i, instance_local_transform)
## TODO: refactor so that there's only one function that accelerates the particle

## Generate N_POINTS diffusion particles around the current particle 
## It doesn't update multimesh.visible_instance_count!
func _generate_diffusion_particles(i: int) -> void:
	if N_POINTS <= 0:
		return # no diffusion particles to generate
	# var _normal_dir_as_color := mm_emitter.multimesh.get_instance_custom_data(i) as Color
	# var _normal_dir := Vector3(_normal_dir_as_color.r, _normal_dir_as_color.g, _normal_dir_as_color.b)
	var center_particle := mm_emitter.multimesh.get_instance_transform(i)
	var center_particle_color := mm_emitter.multimesh.get_instance_color(i)
	var pc_radius := total_space[i] * (diffusion / 100) * 1 # pointcloud radius based on total space travelled by the particle and diffusion factor
	# TODO: maybe use compute shader to generate the particles around the center particle
	for j in range(1, N_POINTS + 1):
		# generating a random position around the particle
		var new_pos := Util.generate_gaussian_vector(0, 1, pc_radius)
		# mm_emitter.multimesh.visible_instance_count += 1
		mm_emitter.multimesh.set_instance_transform(i + j, Transform3D(Basis(), center_particle.origin + new_pos))
		# mm_emitter.multimesh.set_instance_color(i + j, Color.YELLOW)
		mm_emitter.multimesh.set_instance_color(i + j, center_particle_color)

	# mm_emitter.multimesh.visible_instance_count += N_POINTS
## Spawns a new particle in the multimesh at the current position of the emitter. 
## The id of the particle is the last id -1  of the multimesh.
## It doesn't update multimesh.visible_instance_count!
func _spawn_particle(last_id: int) -> void:
	# change color of particle based on emitter color
	mm_emitter.multimesh.set_instance_color(last_id - 1, color)
	# assign the normal direction to the particle
	mm_emitter.multimesh.set_instance_custom_data(last_id - 1, Color(norm.x, norm.y, norm.z))
	normal_dirs.append(norm)
	var _initial_position := mm_emitter.global_position + norm * Util.comet_radius
	# global_positions.append(mm_emitter.global_position + norm * Util.comet_radius)
	global_positions.append(global_position)
	# initial_positions.append(global_position)
	initial_positions.append(_initial_position)
	time_alive.append(0) # time alive is 0 at the beginning
	particle_speeds.append(speed)
	total_space.append(0) # total space travelled is 0 at the beginning
	for i in range(N_POINTS):
		time_alive.append(0) # time alive is 0 at the beginning for each diffusion particle
		global_positions.append(global_position)
		initial_positions.append(_initial_position)
		normal_dirs.append(norm)
		particle_speeds.append(speed)
		total_space.append(0) # total space travelled is 0 at the beginning for each diffusion particle
	# spawn new particle at origin
	mm_emitter.multimesh.set_instance_transform(last_id - 1, Transform3D(Basis(Vector3.UP, Vector3.LEFT, Vector3.FORWARD), Vector3.ZERO))


## Computes acceleration(in m/s^2) based on particle density, particle radius, particle albedo, solar pressure etc
## It uses the following formula: a = 3\*P/(4\*d/2\*p) where
## d, p and alpha are particle diameter, particle density and albedo
## P = eps \* (2-alpha) 	 and eps = I/c = L_sun/(4\*PI\*c\*D^2) is the pressure radiation
## D is the sun-comet distance and c is the light speed and L_sun is the sun luminosity (J/s)
func update_acceleration() -> void:
	# Ls / 4PI * c *(AU*sun_comet_distance)^2
	var eps: float = Util.SUN_LUMINOSITY / ((4 * PI) * Util.LIGHT_SPEED * pow(Util.AU * Util.sun_comet_distance, 2))
	var P: float = eps * (1 + Util.albedo)
	# # P * 3 / (4 * d/2 * p)
	var _a: float = P * 3.0 / (4.0 * ((Util.particle_diameter / 1000.0) / 2.0) * (Util.particle_density * 1000.0))
	self.a = _a

func update_initial_norm(_lat: float, _long: float) -> void:
	var lat_rad := deg_to_rad(_lat)
	var lon_rad := deg_to_rad(_long)
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
## update_norm that doesn't use global variables. It takes a vector3 and a basis as parameters.
## It returns a normal vector3 that is normalized and transformed by the inverse of the basis.
func update_norm2(v: Vector3, b: Basis) -> Vector3:
	var result := (v * b.inverse())
	return result.normalized()

func set_number_particles(num: int) -> void:
	if N_POINTS > 0:
		num_particles = num * (N_POINTS + 1)
	else:
		num_particles = num
	mm_emitter.multimesh.instance_count = num_particles

# Cleanup methods
func reset_particles() -> void:
	for particle in particles_alive:
		particle.queue_free()
	particles_alive.clear()
func reset_multimesh() -> void:
	mm_emitter.multimesh.instance_count = 0
	mm_emitter.multimesh.visible_instance_count = 0
	mm_emitter.multimesh.use_custom_data = true
	mm_emitter.multimesh.use_colors = true
	total_space.clear()
	global_positions.clear()
	initial_positions.clear()
	normal_dirs.clear()
	particle_speeds.clear()
	time_alive.clear()
func destroy_multimesh() -> void:
	mm_emitter.queue_free()
#endregion Simulation related

###################################################################################
# Update methods called when sanitized_edit.sanitized_edit_focus_exited is emitted
# Connection of signals is done in JetTable._on_add_jet_entry_btn_pressed
###################################################################################
#region update methods
func update_position(radius: float) -> void:
	var new_pos := Util.latlon_to_vector3(latitude, longitude, radius)
	position = new_pos
func update_speed(_speed: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated speed:%f"%_speed)
	speed = _speed
	pass
func update_lat(lat: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated lat:%f"%lat)
	latitude = lat
	var new_pos := Util.latlon_to_vector3(latitude, longitude, Util.comet_radius)
	position = new_pos
	update_initial_norm(latitude, longitude)
	# get_parent().debug_sphere.global_position = global_transform.origin + norm * 0.5 * 3
func update_long(long: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated long:%f"%long)
	longitude = long + 90
	var new_pos := Util.latlon_to_vector3(latitude, longitude, Util.comet_radius)
	position = new_pos
	update_initial_norm(latitude, longitude)
	# get_parent().debug_sphere.global_position = global_transform.origin + norm * 0.5 * 3
func update_diff(_diffusion: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated diffusion:%f"%_diffusion)
	diffusion = _diffusion
	pass
func update_color(_color: Color) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated albedo:%s"%str(_color))
	color = _color
#endregion update methods


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
		particle.color = color
		add_child(particle)
		particle.global_position = self.global_position
		particle.add_to_group("particle")
		particles_alive.append(particle)
	update_norm()
