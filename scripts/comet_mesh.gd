@tool
extends MeshInstance3D

enum ANIMATION_STATE {
	STARTED,
	PAUSED,
	STOPPED,
	RESUMED,
}

var animation_state: ANIMATION_STATE = ANIMATION_STATE.STOPPED
var step_count: int = 0
var n_steps: int = 0
var angle_per_step: float = 0

var jet_rate: float = 0
var jet_rate_sped_up: float = 0
var num_rotation: float = 0
var frequency: float = 0
var freq_sped_up: float = 0

var axis_scene := preload("res://scenes/axis_arrow.tscn")
var emitter_scene := preload("res://scenes/particle_emitter.tscn")
@onready var x_axis: AxisArrow
@onready var y_axis: AxisArrow
@onready var z_axis: AxisArrow
@onready var animation_slider: AnimationSlider = $"/root/Hud/Body/TabButtons/ColorRect/HBoxContainer/AnimationSlider"
@export var light_source: Light3D
@export var comet_collider: CollisionObject3D
var rotation_enabled = false
var starting_rotation: Vector3

var rotation_angle: float = 0.0

var speed_sim: int = 1

func _ready() -> void:
	var _x_axis = axis_scene.instantiate() as AxisArrow
	add_child(_x_axis)
	_x_axis.add_to_group("toggle_axis")
	_x_axis.set_axis_type(AxisArrow.AxisType.X)
	_x_axis.set_height(mesh.height)
	
	var _y_axis = axis_scene.instantiate() as AxisArrow
	add_child(_y_axis)
	_y_axis.add_to_group("toggle_axis")
	_y_axis.set_axis_type(AxisArrow.AxisType.Y)
	_y_axis.set_height(mesh.height)
	
	var _z_axis = axis_scene.instantiate() as AxisArrow
	add_child(_z_axis)
	_z_axis.add_to_group("toggle_axis")
	# calling after all axises are added to the scenetree and thus are _ready
	_z_axis.set_axis_type(AxisArrow.AxisType.Z)
	_z_axis.set_height(mesh.height)
	
	x_axis = _x_axis
	y_axis = _y_axis
	z_axis = _z_axis

	starting_rotation = rotation
	Hud.comet_collider = comet_collider
	Hud.light_source = light_source


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# return
	# if rotation_enabled:
	# 	# TODO: emit a signal whenever rotation_angle is changed (homi gaio)
	# 	rotation_angle = fmod(rotation_angle + delta, 2 * PI)
	# 	rotate_object_local(Vector3.UP, 1 * delta)
	# 	# TODO: understand how to make precession motion
	# 	# rotate_object_local(Vector3.FORWARD, 0.1 * delta)
	# print(Engine.get_frames_per_second())
	match animation_state:
		ANIMATION_STATE.STARTED, ANIMATION_STATE.RESUMED:
			if n_steps == 0:
				animation_state = ANIMATION_STATE.STOPPED
			else:
				for i in speed_sim:
					tick()
					n_steps -= 1
			pass

		ANIMATION_STATE.PAUSED:
			pass
		ANIMATION_STATE.STOPPED:
			pass

	pass


"""
Single elaboration step of the simulation.
Each tick spawn a new particle from the jet
"""
func tick() -> void:
	for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
		# emitter.tick()
		emitter.tick_optimized()
	animation_slider.tick()
	rotate_object_local(Vector3.UP, deg_to_rad(angle_per_step))
#region Simulation related
"""
Called by play_animation_slider._on_play_btn_pressed
"""
func animation_started() -> void:
	match animation_state:
		ANIMATION_STATE.PAUSED:
			animation_state = ANIMATION_STATE.RESUMED
		ANIMATION_STATE.STOPPED:
			animation_state = ANIMATION_STATE.STARTED
		_:
			# print("From RESUME to STARTED should never happen")
			pass
			
	if animation_state == ANIMATION_STATE.STARTED:
		starting_rotation = rotation
		n_steps = int(num_rotation * frequency * 60 / jet_rate)
		for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
			emitter.set_number_particles(n_steps)
		print(n_steps)
		# if I have a rotation period of 360 minutes and a jet_rate of 1 min, it means I have 1 angle per tick()
		angle_per_step = 1 / (frequency * 60 / jet_rate) * 360
		animation_slider.set_step_rate(100.0 / n_steps)
		# animation_slider.tick()
		# simulation()
	pass

"""
Called by play_animation_slider._on_pause_btn_pressed
"""
func animation_paused() -> void:
	animation_state = ANIMATION_STATE.PAUSED
	pass
"""
Called by play_animation_slider._on_stop_btn_pressed
"""
func animation_stopped() -> void:
	animation_state = ANIMATION_STATE.STOPPED
	reset_rotation()
	# delete all particles
	for emitter: Emitter in get_tree().get_nodes_in_group("emitter"):
		emitter.reset_particles()
		emitter.update_norm()
		emitter.reset_multimesh()
	animation_slider.reset()

"""
Called by play_animation_slider._on_speed_up_btn_pressed
"""
func speed_up(value: int) -> void:
	speed_sim = value
	freq_sped_up = frequency / value
	jet_rate_sped_up = jet_rate / value
	n_steps = int(num_rotation * freq_sped_up * 60 / jet_rate_sped_up)
	angle_per_step = 1 / (freq_sped_up * 60 / jet_rate_sped_up) * 360

	
#endregion Simulation related
"""
Called by JetTable._on_add_jet_entry_btn_pressed
"""
func spawn_emitter_at(latitude: float, longitude: float, emitter: Emitter) -> void:
	# print("Latitude:" + str(latitude) + " Longitude:" + str(longitude))
	var emitter_pos = Util.latlon_to_vector3(latitude, longitude + 90, mesh.radius)
	emitter.position = emitter_pos
	emitter.enabled = rotation_enabled
	emitter.comet_collider = comet_collider
	emitter.comet_radius = mesh.radius
	emitter.light_source = light_source
	emitter.add_to_group("emitter")
	add_child(emitter)

"""
Called by JetTable.remove_jet_entry
"""
func remove_emitter(emitter_id: int) -> void:
	var emitter: Emitter = instance_from_id(emitter_id)
	emitter.remove_from_group("emitter")
	print(emitter)
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

#region Update methods
## These methods are called by SanitizedEdit through call_group() mechanism
func update_radius(value: float) -> void:
	#print_debug("[UPDATE RADIUS] Before:"+str(mesh.radius)+" After:"+str(value))
	mesh.set_radius(value)
	$CometArea/CometCollisionShape.shape.set_radius(value - 0.0001)
	mesh.set_height(value * 2)
	if x_axis:
		x_axis.set_height(mesh.height)
	if y_axis:
		y_axis.set_height(mesh.height)
	if z_axis:
		z_axis.set_height(mesh.height)
	SaveManager.config.set_value("comet", "radius", mesh.radius)
	get_tree().call_group("emitter", "update_position", value)
## Deprecated
func update_height(value: float) -> void:
	#print_debug("[UPDATE HEIGHT] Before:"+str(mesh.height)+" After:"+str(value))
	mesh.set_height(value)
func update_direction_rotation(value: float) -> void:
	rotation_degrees.z = value
	SaveManager.config.set_value("comet", "direction", value)
func update_inclination_rotation(value: float) -> void:
	#print_debug("[UPDATE INCLINATION]")
	rotation_degrees.y = - value + 90
	# rotate_object_local(Vector3.UP, deg_to_rad(-value + 90))
	SaveManager.config.set_value("comet", "inclination", value)
func update_jet_rate(value: float) -> void:
	print("updated jetrate")
	jet_rate = value
func update_num_rotation(value: float) -> void:
	num_rotation = value
func update_frequency(value: float) -> void:
	frequency = value
#endregion Update methods
