extends Control
class_name JetEntry

var emitter_scene := preload("res://scenes/particle_emitter.tscn")

# entry fields
var jet_id: int = 0
var speed: float = 0
var prev_speed: float = 0
var latitude: float = 0
var prev_lat: float = 0
var longitude: float = 0
var prev_long: float = 0
var diffusion: float = 0
var prev_diff: float = 0
var color: Color = Color.WHITE
# emitter node
var emitter: Emitter


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Debug only
	$SpeedEdit.text = str(randf())
	$LatitudeEdit.text = str(randf() * 50)
	latitude = float($LatitudeEdit.text)
	$LongitudeEdit.text = str(randf() * 50)
	longitude = float($LongitudeEdit.text)
	$DiffusionEdit.text = str(randf())
	$ColorPickerButton.color = Color(randf(), randf(), randf())
	print(Hud.current_radius)
	# Setting the color picker shape/features
	var color_picker := $ColorPickerButton.get_picker() as ColorPicker
	color_picker.presets_visible = false
	color_picker.edit_alpha = false
	color_picker.picker_shape = ColorPicker.SHAPE_VHS_CIRCLE
	color_picker.color_modes_visible = false
	color_picker.sampler_visible = false
	
	# Creating an emitter
	#emitter = emitter_scene.instantiate() as Emitter
	#var emitter_pos = Util.latlon_to_vector3(0,0+90,Hud.current_radius)
	#emitter.latitude = latitude
	#emitter.longitude = longitude
	#emitter.position = emitter_pos
	#emitter.enabled = false
	#emitter.comet_collider = Hud.comet_collider
	#emitter.light_source = Hud.light_source
	#add_child(emitter)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func set_id_label(value: int) -> void:
	$JetID.text = str(value)
	jet_id = value
	
###################################
# Other buttons (toggle and remove)
###################################
"""
Calls JetTable.remove_jet_entry
"""
func _on_remove_jet_btn_pressed() -> void:
	get_tree().call_group("jet_table", "remove_jet_entry", self.get_instance_id())

"""
Calls JetTable.toggle_jet_entry
"""
func _on_toggle_jet_pressed() -> void:
	get_tree().call_group("jet_table", "toggle_jet_entry", self.get_instance_id())


func set_jet_entry_field(line_edit: LineEdit, value: float) -> void:
	if line_edit == $LatitudeEdit:
		latitude = value
		prev_lat = value
	elif line_edit == $LongitudeEdit:
		longitude = value
		prev_long = value
	elif line_edit == $SpeedEdit:
		speed = value
		prev_speed = value
	elif line_edit == $DiffusionEdit:
		diffusion = value
		prev_diff = value
		
func sanitize_field(line_edit: LineEdit, low: float, higher: float) -> void:
	if line_edit.text.is_valid_float():
		var new_val = clampf(float(line_edit.text), low, higher)
		set_jet_entry_field(line_edit, new_val)
		line_edit.prev_val = new_val
	else:
		line_edit.text = str(line_edit.prev_val)
# func _unhandled_input(event: InputEvent) -> void:
# 	var edit_fields = [$SpeedEdit, $LatitudeEdit, $LongitudeEdit, $DiffusionEdit]
# 	var edit_sanitization_field = [??,??,??]
# 	for edit_field in edit_fields:
# 		if edit_field and edit_field.has_focus():
# 			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
# 				edit_field.release_focus()
