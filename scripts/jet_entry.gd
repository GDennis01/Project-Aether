extends Control
class_name JetEntry
var jet_id:int = 0
var speed:float = 0
var prev_speed:float = 0
var latitude:float = 0
var prev_lat:float = 0
var longitude:float = 0
var prev_long:float = 0
var diffusion:float = 0
var prev_diff:float = 0
var color:Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Debug only
	$SpeedEdit.text = str(randf())
	$LatitudeEdit.text = str(randf()*50)
	latitude = float($LatitudeEdit.text)
	$LongitudeEdit.text = str(randf()*50)
	longitude = float($LongitudeEdit.text)
	$DiffusionEdit.text = str(randf())
	$ColorPickerButton.color = Color(randf(),randf(),randf())
	
	# Setting the color picker shape/features
	var color_picker:= $ColorPickerButton.get_picker() as ColorPicker
	color_picker.presets_visible = false
	color_picker.edit_alpha = false
	color_picker.picker_shape = ColorPicker.SHAPE_VHS_CIRCLE
	color_picker.color_modes_visible = false
	color_picker.sampler_visible = false
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func set_id_label(value:int)->void:
	$JetID.text = str(value)
	jet_id = value
	
###############################################
# updating/sanitizing variables linked to line edit values
###############################################
func _on_speed_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		var new_val = max(0,float(new_text))
		speed = new_val
		prev_speed = new_val
	else:
		$SpeedEdit.text = str(prev_speed)
		
func _on_latitude_edit_text_changed(new_text: String) -> void:
	print("PREV:"+str(prev_lat))
	
	if new_text.is_valid_float():
		var new_val = clampf(float(new_text),-90,90)
		print(new_val)
		if not new_text.begins_with("-") or not new_text.is_empty():
			latitude = new_val
			prev_lat = new_val
			$LatitudeEdit.text = str(prev_lat)
	else:
		$LatitudeEdit.text = str(prev_lat)

func _on_longitude_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		var new_val = clampf(float(new_text),0,360)
		longitude = new_val
		prev_long = new_val
	else:
		$LongitudeEdit.text = str(prev_long)

func _on_diffusion_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		var new_val = clampf(float(new_text),0,100)
		diffusion = new_val
		prev_diff = new_val
	else:
		$DiffusionEdit.text = str(prev_diff)


######################################
# Disabling Focus on line edit buttons
#####################################
func _on_speed_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		FlyCamera.set_process(false)
	else:
		FlyCamera.set_process(true)

func _on_latitude_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		FlyCamera.set_process(false)
	else:
		FlyCamera.set_process(true)

func _on_longitude_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		FlyCamera.set_process(false)
	else:
		FlyCamera.set_process(true)

func _on_diffusion_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		FlyCamera.set_process(false)
	else:
		FlyCamera.set_process(true)

##################################
# Other buttons (toggle and remove
###################################
"""
Calls JetTable.remove_jet_entry
"""
func _on_remove_jet_btn_pressed() -> void:
	get_tree().call_group("jet_table","remove_jet_entry",jet_id)

"""
Calls JetTable.toggle_jet_entry
"""
func _on_toggle_jet_pressed() -> void:
	get_tree().call_group("jet_table","toggle_jet_entry",jet_id)
