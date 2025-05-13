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
var speed: float = 0:
	get:
		return speed_edit.property_value
var prev_speed: float = 0
var latitude: float = 0:
	get:
		return latitude_edit.property_value
var prev_lat: float = 0
var longitude: float = 0:
	get:
		return longitude_edit.property_value
var prev_long: float = 0
var diffusion: float = 0:
	get:
		return diffusion_edit.property_value
var prev_diff: float = 0
var color: Color = Color.WHITE

# emitter node
var emitter: Emitter


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Debug only
	$SpeedEdit.text = str(0.0)
	$LatitudeEdit.text = str(0.0)
	$LongitudeEdit.text = str(0.0)
	$DiffusionEdit.text = str(0.0)
	$ColorPickerButton.color = Color(randf(), randf(), randf())
	color = $ColorPickerButton.color

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

func set_id_label(value: int) -> void:
	jet_id = value
	$JetID.text = str(value)
func set_speed(value: float) -> void:
	speed = value
	speed_edit.set_value(value)
func set_latitude(value: float) -> void:
	latitude = value
	latitude_edit.set_value(value)
func set_longitude(value: float) -> void:
	longitude = value
	longitude_edit.set_value(value)
func set_diffusion(value: float) -> void:
	diffusion = value
	diffusion_edit.set_value(value)
func set_color(value: Color) -> void:
	color = value
	color_edit.color = value

	
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


func disable_remove() -> void:
	$RemoveJetBtn.disabled = true
func enable_remove() -> void:
	$RemoveJetBtn.disabled = false
