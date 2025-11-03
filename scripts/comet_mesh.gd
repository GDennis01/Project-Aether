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

#switch dateViewport/Panel/DateLabel
# @onready var switch_date: LineEdit = $"/root/Hud/Body/CometTab/Control/SwitchDate/CurrDateLineEdit"
@onready var switch_date: Label = $"/root/Hud/Viewport/Panel/DateLabel"
var current_date_index: int = 0


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
@onready var reverse_y_axis: AxisArrow
@onready var animation_slider: AnimationSlider = $"/root/Hud/Body/TabButtons/AnimationSlider"

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

	var _reverse_y_axis := axis_scene.instantiate() as AxisArrow
	# delete arrow head
	
	add_child(_reverse_y_axis)
	_reverse_y_axis.add_to_group("toggle_axis")
	_reverse_y_axis.set_axis_type(AxisArrow.AXIS_TYPE.REVERSE_Y)
	_reverse_y_axis.set_height(mesh.height)
	
	x_axis = _x_axis
	y_axis = _y_axis
	z_axis = _z_axis
	reverse_y_axis = _reverse_y_axis

	# disabled by default
	x_axis.visible = false
	z_axis.visible = false

	starting_rotation = rotation

	get_tree().call_group("sun", "update_sun_axis", mesh.height)
	
	Util.comet_radius = mesh.radius
	update_comet_orientation()

		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
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
	rotate_object_local(Vector3.UP, deg_to_rad(angle_per_step))


## Instant simulation. Basically it spawns all particles at once, without any delay.
## Then it computes the final position of each particle
func instant_simulation() -> void:
	simulation_setup()
	print("Instant simulation with n_steps:%d and angle_per_step:%f" % [n_steps, angle_per_step])
	for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
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

	n_steps = int(num_rotation * frequency * 60 / jet_rate)
	angle_per_step = 1.0 / (frequency * 60.0 / jet_rate) * 360.0
	animation_slider.set_step_rate(100.0 / n_steps)
	
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
			print("From RESUME to STARTED should never happen")
			pass
			
	if animation_state == ANIMATION_STATE.STARTED:
		simulation_setup()

		for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
			emitter.set_number_particles(n_steps)
	
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
	# +90 so that it spawn correctly
	var emitter_pos := Util.latlon_to_vector3(latitude, longitude + 90, mesh.radius)
	emitter.position = emitter_pos
	emitter.enabled = rotation_enabled
	emitter.comet_collider = comet_collider
	emitter.light_source = light_source
	emitter.add_to_group("emitter")
	add_child(emitter)
	# this is needed so that when I load the data, the particle mesh is updated correctly. 
	# it's after add_child since particle_mesh is initialized in the _ready function
	# the radius is 1/25 of the comet, chosen arbitrarly
	emitter.particle_mesh.mesh.radius = mesh.radius * (1.0 / 25)
	emitter.particle_mesh.mesh.height = emitter.particle_mesh.mesh.radius * 2


## Called by JetTable.remove_jet_entry
func remove_emitter(emitter_id: int) -> void:
	var emitter: Emitter = instance_from_id(emitter_id)
	emitter.remove_from_group("emitter")
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
	if reverse_y_axis:
		reverse_y_axis.set_height(mesh.height)
	# update position and size of sun axis
	get_tree().call_group("sun", "update_sun_axis", value * 2)
	# print("calling update_position on emitter\n")
	get_tree().call_group("emitter", "update_position", value)
## Deprecated
# func update_height(value: float) -> void:
# 	#print_debug("[UPDATE HEIGHT] Before:"+str(mesh.height)+" After:"+str(value))
# 	mesh.set_height(value)
func update_direction_rotation(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated comet PA:%f"%value)
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

# jpl related
func update_alpha_p(value: float, booted: bool = true) -> void:
	# to prevent to being called at startup
	if not booted:
		return
	if Util.PRINT_UPDATE_METHOD: print("Updated alpha_p:%f"%value)
	Util.alpha_p = value
	if Util.jpl_data == null or Util.jpl_data.size() == 0:
		Util.create_popup("JPL data not loaded", "Please first load JPL data to compute ecliptic and orbital coordinates.")
		return
	update_pa_incl()
	update_lambda_beta()
	update_i_phi()
	update_subsolar_latitude()
func update_delta_p(value: float, booted: bool = true) -> void:
	# to prevent to being called at startup
	if not booted:
		return
	if Util.PRINT_UPDATE_METHOD: print("Updated delta_p:%f"%value)
	Util.delta_p = value
	if Util.jpl_data == null or Util.jpl_data.size() == 0:
		Util.create_popup("JPL data not loaded", "Please first load JPL data to compute ecliptic and orbital coordinates.")
		return
	update_pa_incl()
	update_lambda_beta()
	update_i_phi()
	update_subsolar_latitude()
func update_pa_incl() -> void:
	var alpha_rad := deg_to_rad(Util.alpha_p)
	var delta_rad := deg_to_rad(Util.delta_p)
	var ra_comet_pos: float = float(Util.jpl_data[current_date_index]["right_ascension"])
	var dec_comet_pos: float = float(Util.jpl_data[current_date_index]["declination"])

	var pa: float = atan2(
		cos(delta_rad) * sin(alpha_rad - deg_to_rad(ra_comet_pos)),
		cos(deg_to_rad(dec_comet_pos)) * sin(delta_rad) - sin(deg_to_rad(dec_comet_pos)) * cos(delta_rad) * cos(alpha_rad - deg_to_rad(ra_comet_pos)))
	pa = fmod(pa + 2 * PI, 2 * PI)
	var incl: float = acos(cos(alpha_rad - deg_to_rad(ra_comet_pos)) * cos(deg_to_rad(dec_comet_pos)) * cos(delta_rad) + sin(deg_to_rad(dec_comet_pos)) * sin(delta_rad))

	Util.comet_direction = rad_to_deg(pa)
	Util.comet_inclination = -90 + rad_to_deg(incl)
	
	Util.comet_incl_line_edit.set_value(Util.comet_inclination)
	Util.comet_pa_line_edit.set_value(Util.comet_direction)
	update_comet_orientation()
func update_lambda_beta() -> void:
	var alpha_rad := deg_to_rad(Util.alpha_p)
	var delta_rad := deg_to_rad(Util.delta_p)
	const eps := deg_to_rad(23.43929111)
	var lambda := atan2(sin(alpha_rad) * cos(eps) + tan(delta_rad) * sin(eps), cos(alpha_rad))
	var beta := asin(sin(delta_rad) * cos(eps) - cos(delta_rad) * sin(eps) * sin(alpha_rad))
	lambda = fmod(lambda + 2 * PI, 2 * PI)
	# print("Updated lambda:%f beta:%f" % [rad_to_deg(lambda), rad_to_deg(asin(beta))])
	Util.lambda = rad_to_deg(lambda)
	Util.beta = rad_to_deg(beta)
	#  only 2 decimals
	Util.lambda_line_edit.text = str("%.2f" % Util.lambda)
	Util.beta_line_edit.text = str(" %.2f" % Util.beta)
func update_i_phi() -> void:
	var lambda := deg_to_rad(Util.lambda)
	var beta := deg_to_rad(Util.beta)
	var asc_node_long: float = deg_to_rad(Util.om) # Omega
	var incl: float = deg_to_rad(Util.incl) # i
	var arg_perihelion: float = deg_to_rad(Util.w) # omega(w)

	# ecliptic to equatorial conversion
	var x_e := cos(beta) * cos(lambda)
	var y_e := cos(beta) * sin(lambda)
	var z_e := sin(beta)

	var p := Vector3(x_e, y_e, z_e)

	# rotation of Omega around Z
	var rz_omega := Basis(
		Vector3(cos(asc_node_long), -sin(asc_node_long), 0),
		Vector3(sin(asc_node_long), cos(asc_node_long), 0),
		Vector3(0, 0, 1)
	)
	var p1 := rz_omega * p


	# rotation of i around X
	var rx_i := Basis(
		Vector3(1, 0, 0),
		Vector3(0, cos(incl), -sin(incl)),
		Vector3(0, sin(incl), cos(incl))
	)

	var p2 := rx_i * p1

	# rotation of w around Z
	var rz_w := Basis(
		Vector3(cos(arg_perihelion), -sin(arg_perihelion), 0),
		Vector3(sin(arg_perihelion), cos(arg_perihelion), 0),
		Vector3(0, 0, 1)
	)
	var p3 := rz_w * p2

	
	#  back to spherical coordinates
	var phi := atan2(p3.x, p3.y)
	phi = rad_to_deg(phi) + 180
	var I := acos(p3.z)
	I = rad_to_deg(I)
	Util.i_line_edit.text = str("%.2f" % I)
	Util.i = I
	Util.phi_line_edit.text = str("%.2f" % phi)
	Util.phi = phi

func update_subsolar_latitude() -> void:
	var I := deg_to_rad(Util.i)
	var phi := deg_to_rad(Util.phi)
	# if Util.jpl_data == null or Util.jpl_data.size() == 0:
	# 	Util.create_popup("JPL data not loaded", "Please load JPL data to compute ecliptic and orbital elements.")
	# 	return
	var true_anomaly := deg_to_rad(float(Util.jpl_data[current_date_index]["true_anomaly"]))
	# var I := deg_to_rad(133.9)
	# var phi := deg_to_rad(245.1)
	# var true_anomaly := deg_to_rad(272.6)
	Util.subsolar_latitude = asin(sin(I) * sin(true_anomaly + phi))
	Util.subsolar_lat_line_edit.text = str("%.2f" % rad_to_deg(Util.subsolar_latitude))


#region switch date
func switch_date_set_date(date: String, reset: bool = false) -> void:
	if reset:
		current_date_index = 0
	switch_date.text = date
	# updates all parameters based on the jpl data in that date
	update_pa_incl()
	update_lambda_beta()
	update_i_phi()
	update_subsolar_latitude()
	# sun params
	Util.sun_pa_line_edit.set_value(float(Util.jpl_data[current_date_index]["sun_pa"]))
	Util.sun_incl_line_edit.set_value(float(Util.jpl_data[current_date_index]["sto"]))
	Util.sun_dist_line_edit.set_value(float(Util.jpl_data[current_date_index]["sun_distance_r"]))
	# scale 
	Util.scale_line_edit.set_value(float(Util.jpl_data[current_date_index]["delta"]))
# called by CometTab._on_prev_date_btn_pressed
func switch_date_prev_date() -> void:
	_switch_date_prev_next_date(-1, 0)

func switch_date_first_date() -> void:
	_switch_date_prev_next_date(-1, -1)

func switch_date_last_date() -> void:
	_switch_date_prev_next_date(1, 1)

# called by CometTab._on_next_date_btn_pressed
func switch_date_next_date() -> void:
	_switch_date_prev_next_date(1, 0)


func _switch_date_prev_next_date(prev_next: int, first_last: int) -> void:
	if Util.jpl_data == null or Util.jpl_data.size() == 0:
		Util.create_popup("JPL data not loaded", "Please load JPL data to switch dates.")
		return
	# current_date_index-1 or +1 based on prev_next
	current_date_index += prev_next
	if current_date_index < 0:
		current_date_index = Util.jpl_data.size() - 1
	elif first_last == 1:
		current_date_index = Util.jpl_data.size() - 1
	elif first_last == -1:
		current_date_index = 0
	elif current_date_index >= Util.jpl_data.size():
		current_date_index = 0
	var date_str: String = str(Util.jpl_data[current_date_index]["date"])
	var time_str: String = str(Util.jpl_data[current_date_index]["time"])
	# only the first 2 digits (hours)
	time_str = time_str.substr(0, 2)
	switch_date_set_date(date_str + " " + time_str)


#endregion switch date


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
