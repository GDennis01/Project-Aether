extends Node3D
class_name Emitter
const RAY_LENGHT = 1000000

var particle_scene := preload("res://scenes/particle.tscn")

# @onready var comet: MeshInstance3D = $"/root/World/CometMesh"

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

## acceleration of a single particle
var a: float = 0.0


#multimesh
var mm_emitter: MultiMeshInstance3D = MultiMeshInstance3D.new()
var global_positions: Array[Vector3] ## global position of the mm_emitter at each instance spawned
var initial_positions: Array[Vector3] ## initial position of the mm_emitter at each instance spawned
var particle_speeds: Array[float] ## speeds of each particle
var normal_dirs: Array[Vector3] ## normal_dir of the mm_emitter at each instance spawned
var time_alive: Array[int] = [] # number of ticks each particle has been alive

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
	time_start = Time.get_ticks_msec()
	
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
	multi_mesh_istance.multimesh.mesh = _sphere_mesh
	multi_mesh_istance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	multi_mesh_istance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	multi_mesh_istance.lod_bias = 0.0001
	multi_mesh_istance.ignore_occlusion_culling = false
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

## Get the longitudinal angle given the angle between the comet inclination rotation angle and the sun inclination angle
func _get_longitude_angle(sun_comet_angle: float) -> float:
	var longitude_angle: float = 0.0
	match sun_comet_angle:
		0:
			if latitude < 0:
				longitude_angle = -90
			else:
				longitude_angle = 90
		var x when x < 90: # 0<x<90
			if latitude >= sun_comet_angle:
				longitude_angle = 90
			elif latitude <= -sun_comet_angle:
				longitude_angle = -90
			else:
				longitude_angle = 90.0 * latitude / sun_comet_angle # linear formula
		90:
			longitude_angle = 0
		var x when x < 180: # 90<x<180
			if latitude >= (180 - sun_comet_angle): # never
				longitude_angle = -90 #
				printerr("Error in 90<\"sun_comet_angle\"<180 branch")
			elif latitude <= (180 - sun_comet_angle):
				longitude_angle = 90
			else:
				longitude_angle = -90.0 * latitude / (180.0 - sun_comet_angle)

		180:
			if latitude > 0:
				longitude_angle = -90
			else:
				longitude_angle = 90
		_:
			printerr("Error: sun_comet_angle is greater than 180°")
	return longitude_angle
## Returns whether the emitter is lit by the sun or not, 
## based on sun inclination and direction angle, comet inclination and comet current rotation angle
## FIXME: probably this doesn't work properly
func is_lit_math(sun_incl: float, sun_dir: float, comet_dir: float, comet_rotation_angle: float) -> bool:
	# var sun_comet_angle: float = absf(sun_dir - comet_dir)
	var sun_comet_angle: float = absf(fmod(comet_dir - sun_dir, 180.0))
	var longitude_angle: float = _get_longitude_angle(sun_comet_angle)


	var angle_comet_sun: float = absf(comet_rotation_angle - sun_dir)
	print("sun_comet_angle %f Longitude angle %f Angle comet sun %f" % [sun_comet_angle, longitude_angle, angle_comet_sun])
	print("Comet rotation angle:%s Comet direction:%s Sun inclination:%s Sun dir:%s" % [str(comet_rotation_angle), str(comet_dir), str(sun_incl), str(sun_dir)])
	print()
	if angle_comet_sun <= (90 + longitude_angle) or angle_comet_sun >= 180 - (90 + longitude_angle):
		return true
	else:
		return false

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


#region Multimesh related
func set_number_particles(num: int) -> void:
	num_particles = num
	mm_emitter.multimesh.instance_count = num_particles
func tick_optimized(_n_iteration: int) -> void:
	# moving each particle
	# mm_emitter.quaternion = get_parent().global_transform.basis.get_rotation_quaternion()
	var mm_global_inverse: Transform3D = mm_emitter.global_transform.affine_inverse()
	for i in mm_emitter.multimesh.visible_instance_count:
		#region old code
		# # getting normal direction and converting it to vector3 since it's saved as a Color
		# var _normal_dir_as_color := mm_emitter.multimesh.get_instance_custom_data(i) as Color
		# var _normal_dir := Vector3(_normal_dir_as_color.r, _normal_dir_as_color.g, _normal_dir_as_color.b)
		# var instance_transform := mm_emitter.multimesh.get_instance_transform(i)
		# 	# TODO: capire come calcolare la forza del sole in base al tempo passato
		# # initial velocity of the particle which is equal to the normal direction multiplied by the speed
		# var initial_velocity: Vector3 = _normal_dir * speed
		# var initial_velocity_orb: Vector3 = initial_velocity
		# var initial_position_orb: Vector3 = initial_positions[i]
		# var new_basis := Basis(Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1))
		# # time passed in seconds ( jet_rate is in minutes) obtained by multiplying how many ticks have passed
		# var time_passed: float = time_alive[i] * Util.jet_rate * 60.0
		# time_alive[i] += 1 # incrementing time alive of the particle
		# # Updating speed as V= V*t + 1/2*a*t^2 (classic form), a is negative since the acceleration is in the opposite direction(?). It's in m(eters)
		# var sun_accel := 0.5 * a * (time_passed ** 2)
		# # sun_accel = 0
		# var new_pos: Vector3 = Vector3.ZERO
		# new_pos.x = initial_position_orb.x + (initial_velocity_orb.x * time_passed) - sun_accel
		# new_pos.y = initial_position_orb.y + (initial_velocity_orb.y * time_passed)
		# new_pos.z = initial_position_orb.z + (initial_velocity_orb.z * time_passed)
		# new_pos = new_pos / (Util.scale / 500) # scaling down
		# new_pos = new_pos * new_basis # applying the new basis to the position
		# var delta: Vector3 = new_pos - instance_transform.origin
		# # istance_transform.
		# # global_positions[i].x = initial_position_orb.x + (initial_velocity_orb.x * time_passed) - sun_accel
		# # global_positions[i].y = initial_position_orb.y + (initial_velocity_orb.y * time_passed)
		# # global_positions[i].z = initial_position_orb.z + (initial_velocity_orb.z * time_passed)
		# # global_positions[i] = global_positions[i] / (Util.scale / 500) # scaling down
		# # var new_transf := Transform3D(Util.orbital_basis, global_positions[i])
		# instance_transform.origin += delta # updating the position of the particle
		# var new_transf := Transform3D(new_basis, global_positions[i])
		# var parent_transform: Transform3D = Util.orbital_transformation
		# # var new_transf := Transform3D(Basis(), global_positions[i])
		# # apply local transform to the multimesh instance
		# # mm_emitter.multimesh.set_instance_transform(i, new_transf)
		# mm_emitter.multimesh.set_instance_transform(i, instance_transform)
		# # mm_emitter.multimesh.set_instance_transform(i, parent_transform * new_transf)
		#endregion old code
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
		var global_displacement: Vector3 = new_basis * local_displacement
		# --- 6. Calculate Final Global Position ---
		var final_global_position: Vector3 = initial_positions[i] + global_displacement
		# Apply your scaling factor
		var scaled_final_pos := final_global_position / (Util.scale / 500)
		# --- 7. Create the Final Transform and Set it ---
		var final_global_transform := Transform3D(new_basis, scaled_final_pos)

		# `set_instance_transform` requires the transform to be LOCAL to the MultiMeshInstance3D node.
		# We convert our desired global transform into a local one.
		# var instance_local_transform := mm_global_inverse * final_global_transform
		var instance_local_transform := final_global_transform
		
		mm_emitter.multimesh.set_instance_transform(i, instance_local_transform)
		
		
	# these three lines make so that the is_lit property is not computed based on raycasting but rather on sheer math
	# var _is_lit: bool = is_lit_math(Util.sun_inclination, Util.sun_direction, Util.comet_direction, comet_rotation_angle)
	# if _is_lit:
	# whether to spawn a new particle or not
	if is_lit:
		# incrementing number of maximum drawn particles (to simulate spawning them)
		var last_id := mm_emitter.multimesh.visible_instance_count + 1
		if last_id < mm_emitter.multimesh.instance_count:
			mm_emitter.multimesh.visible_instance_count = last_id
		# change color of particle based on emitter color
		mm_emitter.multimesh.set_instance_color(last_id - 1, color)
		# assign the normal direction to the particle
		mm_emitter.multimesh.set_instance_custom_data(last_id - 1, Color(norm.x, norm.y, norm.z))
		normal_dirs.append(norm)
		var _initial_position := mm_emitter.global_position + norm * Util.comet_radius
		# var _initial_position = global_position
		# global_positions.append(mm_emitter.global_position + norm * Util.comet_radius)
		global_positions.append(global_position)
		# initial_positions.append(global_position)
		initial_positions.append(_initial_position)
		time_alive.append(0) # time alive is 0 at the beginning
		# if last_id - 1 == 0:
		# 	print("Global pos: %s Norm: %s Radius: %f\n" % [str(global_positions[last_id - 1]), str(norm), Util.comet_radius])
		particle_speeds.append(speed)
		# spawn new particle at origin
		mm_emitter.multimesh.set_instance_transform(last_id - 1, Transform3D(Basis(Vector3.UP, Vector3.LEFT, Vector3.FORWARD), Vector3.ZERO))
		# mm_emitter.multimesh.set_instance_transform(last_id - 1, Transform3D(Util.orbital_basis, global_positions[last_id - 1]))
	update_norm()

## Computes acceleration(in m/s^2) based on particle density, particle radius, particle albedo, solar pressure etc
## It uses the following formula: a = 3\*P/(4\*d/2\*p) where
## d, p and alpha are particle diameter, particle density and albedo
## P = eps \* (2-alpha) 	 and eps = I/c = L_sun/(4\*PI\*c\*D^2) is the pressure radiation
## D is the sun-comet distance and c is the light speed and L_sun is the sun luminosity (J/s)
func update_acceleration() -> void:
	# Ls / 4PI * c *(AU*sun_comet_distance)^2
	var eps: float = Util.SUN_LUMINOSITY / ((4 * PI) * Util.LIGHT_SPEED * pow(Util.AU * Util.sun_comet_distance, 2))
	var P: float = eps * (1 + Util.albedo)

	# print("Ls:%f"%Util.SUN_LUMINOSITY)
	# print("eps:%f P:%f c:%f" % [eps, P, Util.LIGHT_SPEED])
	# print("4*PI:%f" % (4.0 * PI))
	# print("Distance Squared:%f" % [pow(Util.AU * Util.sun_comet_distance, 2)])
	# print("c * Distance Squared:%f" % [Util.LIGHT_SPEED * pow(Util.AU * Util.sun_comet_distance, 2)])
	# print("Dividendo:%f " % ((4 * PI) * Util.LIGHT_SPEED * pow(Util.AU * Util.sun_comet_distance, 2)))

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


func reset_particles() -> void:
	for particle in particles_alive:
		particle.queue_free()
	particles_alive.clear()
func reset_multimesh() -> void:
	mm_emitter.multimesh.instance_count = 0
	mm_emitter.multimesh.visible_instance_count = 0
	global_positions.clear()
	initial_positions.clear()
	normal_dirs.clear()
	particle_speeds.clear()
	time_alive.clear()
func destroy_multimesh() -> void:
	mm_emitter.queue_free()
#endregion Multimesh

###################################################################################
# Update methods called when sanitized_edit.sanitized_edit_focus_exited is emitted
# Connection of signals is done in JetTable._on_add_jet_entry_btn_pressed
###################################################################################
#region update methods
func update_position(radius: float) -> void:
	var new_pos := Util.latlon_to_vector3(latitude, longitude + 90, radius)
	position = new_pos
func update_speed(_speed: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated speed:%f"%_speed)
	speed = _speed
	pass
func update_lat(lat: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated lat:%f"%lat)
	latitude = lat
	var new_pos := Util.latlon_to_vector3(latitude, longitude, comet_radius)
	position = new_pos
	update_initial_norm(latitude, longitude)
	# get_parent().debug_sphere.global_position = global_transform.origin + norm * 0.5 * 3
func update_long(long: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated long:%f"%long)
	longitude = long + 90
	var new_pos := Util.latlon_to_vector3(latitude, longitude, comet_radius)
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
