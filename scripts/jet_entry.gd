extends Control
class_name JetEntry

var emitter_scene := preload("res://scenes/particle_emitter.tscn")


#entry nodes
var speed_edit: SanitizedEdit
var latitude_edit: SanitizedEdit
var longitude_edit: SanitizedEdit
var diffusion_edit: SanitizedEdit
var color_edit: ColorPickerButton

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

	# setting nodes
	speed_edit = $SpeedEdit
	latitude_edit = $LatitudeEdit
	longitude_edit = $LongitudeEdit
	diffusion_edit = $DiffusionEdit
	color_edit = $ColorPickerButton

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
