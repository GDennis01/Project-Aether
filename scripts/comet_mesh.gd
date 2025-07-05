extends MeshInstance3D
class_name Comet
enum ANIMATION_STATE {
	STARTED,
	PAUSED,
	STOPPED,
	RESUMED,
}

#debug/metrics related
@onready var fps_label: Label = $"/root/Hud/Body/DebugPanel/Control/DebugContainer/FPSLabel"
@onready var steps_label: Label = $"/root/Hud/Body/DebugPanel/Control/DebugContainer/StepsLabel"
@onready var time_label: Label = $"/root/Hud/Body/DebugPanel/Control/DebugContainer/SimTimeLabel"
var total_sim_time: float = 0.0
@onready var debug_sphere: MeshInstance3D = $"/root/World/DebugRotationSphere"


# simulation related
var animation_state: ANIMATION_STATE = ANIMATION_STATE.STOPPED
var n_steps: int = 0
var step_counter: int = 0

var angle_per_step: float = 0
var jet_rate: float = 0
var jet_rate_sped_up: float = 0
var num_rotation: float = 0
var frequency: float = 0
var freq_sped_up: float = 0

const EARTH_VIEW = Vector3(0.0, 0.0, 10.0)


var axis_scene := preload("res://scenes/axis_arrow.tscn")
var emitter_scene := preload("res://scenes/particle_emitter.tscn")

@onready var x_axis: AxisArrow
@onready var y_axis: AxisArrow
@onready var z_axis: AxisArrow

@onready var animation_slider: AnimationSlider = $"/root/Hud/Body/TabButtons/ColorRect/HBoxContainer/AnimationSlider"

@export var light_source: Light3D
@export var comet_collider: CollisionObject3D
var rotation_enabled := false
var starting_rotation: Vector3

var rotation_angle: float = 0.0

var speed_sim: int = 1

func _ready() -> void:
	var _x_axis := axis_scene.instantiate() as AxisArrow
	add_child(_x_axis)
	_x_axis.add_to_group("toggle_axis")
	_x_axis.set_axis_type(AxisArrow.AXIS_TYPE.X)
	_x_axis.set_height(mesh.height)
	
	var _y_axis := axis_scene.instantiate() as AxisArrow
	add_child(_y_axis)
	_y_axis.add_to_group("toggle_axis")
	_y_axis.set_axis_type(AxisArrow.AXIS_TYPE.Y)
	_y_axis.set_height(mesh.height)
	
	var _z_axis := axis_scene.instantiate() as AxisArrow
	add_child(_z_axis)
	_z_axis.add_to_group("toggle_axis")
	_z_axis.set_axis_type(AxisArrow.AXIS_TYPE.Z)
	_z_axis.set_height(mesh.height)
	
	x_axis = _x_axis
	y_axis = _y_axis
	z_axis = _z_axis

	# disabled by default
	x_axis.visible = false
	z_axis.visible = false

	starting_rotation = rotation

	get_tree().call_group("sun", "update_sun_axis", mesh.height)
	
	Util.comet_radius = mesh.radius
	# Hud.comet_collider = comet_collider
	# Hud.light_source = light_source
	update_comet_orientation()

# func _notification(what: int) -> void:
# 	if what == NOTIFICATION_WM_CLOSE_REQUEST:
# 		for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
# 			emitter.remove_from_group("emitter")
# 			emitter.destroy_multimesh()
# 			emitter.queue_free()
# 			await get_tree().process_frame
# 		await get_tree().process_frame
# 		SaveManager.cleanup()
# 		get_tree().quit()
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# if rotation_enabled:
	# 	# TODO: emit a signal whenever rotation_angle is changed 
	# 	rotation_angle = fmod(rotation_angle + delta, 2 * PI)
	# 	rotate_object_local(Vector3.UP, 1 * delta)
	# 	# TODO: understand how to make precession motion
	# 	# rotate_object_local(Vector3.FORWARD, 0.1 * delta)
	# print(Engine.get_frames_per_second())
	match animation_state:
		ANIMATION_STATE.STARTED, ANIMATION_STATE.RESUMED:
			if n_steps <= 0:
				animation_state = ANIMATION_STATE.STOPPED
				quaternion = Util.equatorial_rotation
			else:
				for _i in speed_sim:
					tick(step_counter)
					n_steps -= 1
					step_counter += 1
				total_sim_time += _delta
		ANIMATION_STATE.PAUSED, ANIMATION_STATE.STOPPED:
			pass

	# Prints on the debug panel how many FPS and TPS (Tick Per Second)
	# fps_label.text = "FPS:" + str(Engine.get_frames_per_second())
	# steps_label.text = "Steps:%d/%d" % [step_counter, n_steps + step_counter + 1]
	# time_label.text = "Time: %.3f" % (total_sim_time)


#region Simulation related

## Single elaboration step of the simulation.
## Each tick spawn a new particle from the jet
func tick(n_iteration: int) -> void:
	# var time_passed: float = (n_iteration - 1) / (60 / jet_rate)
	for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
		# emitter.tick()
		# print("tick:%f"%n_iteration)
		emitter.tick_optimized(n_iteration)
	animation_slider.tick()
	var _bas := transform.basis
	# print("R0tated Basis:%s" % str(_bas * Basis(Vector3.UP, deg_to_rad(angle_per_step))))
	rotate_object_local(Vector3.UP, deg_to_rad(angle_per_step))
	# print("Rotated Basis:%s" % str(transform.basis))
	# print("--")

## Instant simulation. Basically it spawns all particles at once, without any delay.
## Then it computes the final position of each particle
func instant_simulation() -> void:
	simulation_setup()

	n_steps = int(num_rotation * frequency * 60 / jet_rate)
	angle_per_step = 1.0 / (frequency * 60.0 / jet_rate) * 360.0
	animation_slider.set_step_rate(100.0 / n_steps)
	print("Instant simulation with n_steps:%d and angle_per_step:%f" % [n_steps, angle_per_step])
	for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
		# emitter.set_number_particles(n_steps)
		emitter.instant_simulation(n_steps, angle_per_step)
	animation_slider.instant_simulation()

func simulation_setup() -> void:
	get_tree().call_group("disable", "disable_btn", "LoadBtn")
	Util.equatorial_rotation = quaternion
	look_at(Util.sun_direction_vector, Vector3.UP)
	rotate(transform.basis.y, deg_to_rad(-90))
	# normalizing the basis
	transform.basis = transform.basis.orthonormalized()
	# used by emitters to convert from equatorial to orbital system
	Util.orbital_basis = transform.basis
	Util.orbital_transformation = transform
	# resuming the rotation
	quaternion = Util.equatorial_rotation
	starting_rotation = rotation
	
## Called by play_animation_slider._on_play_btn_pressed
func animation_started() -> void:
	if not Util.is_simulation:
		instant_simulation()
		return
	match animation_state:
		ANIMATION_STATE.PAUSED:
			animation_state = ANIMATION_STATE.RESUMED
		ANIMATION_STATE.STOPPED:
			animation_state = ANIMATION_STATE.STARTED
		_:
			# print("From RESUME to STARTED should never happen")
			pass
			
	if animation_state == ANIMATION_STATE.STARTED:
		simulation_setup()

		n_steps = int(num_rotation * frequency * 60 / jet_rate)
		for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
			emitter.set_number_particles(n_steps)
		# if I have a rotation period of 360 minutes and a jet_rate of 1 min, it means I have 1 angle per tick()
		# TODO: maybe this is wrong??
		angle_per_step = 1.0 / (frequency * 60.0 / jet_rate) * 360.0
		animation_slider.set_step_rate(100.0 / n_steps)

		# de-comment these lines to trigger instant simulation and disables per-tick simulation
		# set_process(false)
		# instant_simulation()
		tick(step_counter)
		step_counter += 1
		n_steps -= 1


## Called by play_animation_slider._on_pause_btn_pressed
func animation_paused() -> void:
	animation_state = ANIMATION_STATE.PAUSED
	pass

## Called by play_animation_slider._on_stop_btn_pressed
func animation_stopped() -> void:
	animation_state = ANIMATION_STATE.STOPPED

	reset_rotation()
	# delete all particles
	for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
		emitter.reset_particles()
		emitter.update_norm()
		emitter.reset_multimesh()

	animation_slider.reset()
	step_counter = 0
	n_steps = 0
	total_sim_time = 0

	quaternion = Util.equatorial_rotation
	get_tree().call_group("enable", "enable_btn", "LoadBtn")

## Called by play_animation_slider._on_speed_up_btn_pressed
func speed_up(value: int) -> void:
	speed_sim = value
	freq_sped_up = frequency / value
	jet_rate_sped_up = jet_rate / value
	n_steps = int(num_rotation * freq_sped_up * 60 / jet_rate_sped_up)
	angle_per_step = 1 / (freq_sped_up * 60 / jet_rate_sped_up) * 360

	
#endregion Simulation related

## Called by JetTable._on_add_jet_entry_btn_pressed
func spawn_emitter_at(latitude: float, longitude: float, emitter: Emitter) -> void:
	# print("Latitude:" + str(latitude) + " Longitude:" + str(longitude))
	var emitter_pos := Util.latlon_to_vector3(latitude, longitude + 90, mesh.radius)
	emitter.position = emitter_pos
	emitter.enabled = rotation_enabled
	emitter.comet_collider = comet_collider
	emitter.light_source = light_source
	emitter.add_to_group("emitter")
	add_child(emitter)


## Called by JetTable.remove_jet_entry
func remove_emitter(emitter_id: int) -> void:
	var emitter: Emitter = instance_from_id(emitter_id)
	emitter.remove_from_group("emitter")
	# print(emitter)
	# remove_child(emitter)
	emitter.destroy_multimesh()
	emitter.queue_free()
	pass

func trigger_rotation() -> void:
	rotation_enabled = not rotation_enabled
	for emitter in get_tree().get_nodes_in_group("emitter"):
		emitter.enabled = rotation_enabled
	for particle in get_tree().get_nodes_in_group("particle"):
		particle.enabled = rotation_enabled
func reset_rotation() -> void:
	rotation_enabled = false
	for emitter in get_tree().get_nodes_in_group("emitter"):
		emitter.enabled = rotation_enabled
	#rotation.y = starting_rotation.y
	rotation = starting_rotation

## These methods are called by SanitizedEdit through call_group() mechanism
#region Update methods

func update_radius(value: float) -> void:
	#print_debug("[UPDATE RADIUS] Before:"+str(mesh.radius)+" After:"+str(value))
	if Util.PRINT_UPDATE_METHOD: print("Updated comet radius:%f"%value)
	Util.comet_radius = value
	mesh.set_radius(value)
	$CometArea/CometCollisionShape.shape.set_radius(value - 0.0001)
	mesh.set_height(value * 2)
	if x_axis:
		x_axis.set_height(mesh.height)
	if y_axis:
		y_axis.set_height(mesh.height)
	if z_axis:
		z_axis.set_height(mesh.height)
	# update position and size of sun axis
	get_tree().call_group("sun", "update_sun_axis", value * 2)
	print("calling update_position on emitter\n")
	get_tree().call_group("emitter", "update_position", value)
## Deprecated
func update_height(value: float) -> void:
	#print_debug("[UPDATE HEIGHT] Before:"+str(mesh.height)+" After:"+str(value))
	mesh.set_height(value)
func update_direction_rotation(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated comet direction:%f"%value)
	Util.comet_direction = value
	update_comet_orientation()
func update_inclination_rotation(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated comet inclination:%f"%value)
	Util.comet_inclination = - value
	update_comet_orientation()

#jets related
func update_jet_rate(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated jet_rate:%f"%value)
	jet_rate = value
	Util.jet_rate = value
func update_num_rotation(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated num_rotation:%f"%value)
	num_rotation = value
func update_frequency(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated frequency:%f"%value)
	frequency = value
func update_scale(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated scale:%f"%value)
	Util.scale = value

# simulation related
func update_albedo(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated albedo:%f"%value)
	Util.albedo = value
	get_tree().call_group("emitter", "update_acceleration")
func update_particle_diameter(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated particle_diameter:%f"%value)
	Util.particle_diameter = value
	get_tree().call_group("emitter", "update_acceleration")
func update_particle_density(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated particle_density:%f"%value)
	Util.particle_density = value
	get_tree().call_group("emitter", "update_acceleration")
func update_sun_comet_distance(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated sun_comet_distance:%f"%value)
	Util.sun_comet_distance = value
	get_tree().call_group("emitter", "update_acceleration")
	# get_tree().call_group("tel_resolution", "update_tel_res_km_pixel")
	# get_tree().call_group("tel_resolution", "update_scale_factor")

#endregion Update methods


func point_y_axis_toward(target_position: Vector3) -> void:
	var current_origin := global_transform.origin
	var direction := target_position - current_origin

	if direction.length_squared() < 1e-12:
		return

	direction = direction.normalized()

# We want the object's local Y-axis (Vector3.UP in its local untransformed space)
# to align with the 'direction' vector (which is in global space).
# The Quaternion(from_vector, to_vector) constructor creates a quaternion
# that represents the shortest rotation from 'from_vector' to 'to_vector'.
# Thanks Gemini 2.5
	var target_orientation_quat := Quaternion(Vector3.UP, direction)

# Set the object's orientation using this quaternion.
# This directly sets the rotation part of the global_transform.
	quaternion = target_orientation_quat
	
# For debugging:
# var final_basis = Basis(target_orientation_quat)
# print("Target Y (World):%s" % str(final_basis.y)) # Should be 'direction'
# print("New Basis X (World):%s" % str(final_basis.x))
# print("New Basis Z (World):%s" % str(final_basis.z))
# print("New Basis (World):%s\n---" % str(final_basis))

func update_comet_orientation() -> void:
	if not is_node_ready():
		return
	# Convert to radians
	var azimuth_rad := deg_to_rad(Util.comet_direction)
	var inclination_rad := deg_to_rad(-Util.comet_inclination - 90)

	# Spherical to Cartesian conversion
	var x := sin(inclination_rad) * sin(azimuth_rad)
	var y := cos(inclination_rad)
	var z := sin(inclination_rad) * cos(azimuth_rad)

	var direction := Vector3(x, y, z).normalized()
	direction = direction.rotated(Vector3.LEFT, deg_to_rad(-90))
	# debug_sphere.global_position = global_transform.origin + direction * mesh.radius * 3
	point_y_axis_toward(global_transform.origin + direction)
	get_tree().call_group("emitter", "update_norm")
