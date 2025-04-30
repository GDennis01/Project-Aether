@tool
extends Control
class_name SliderWithLineEdit
@export var slider:HSlider
@export var line_edit:LineEdit
@export var label:StringName
## Name of the group on which to call the [code]update_resize_type[/code] function
@export var resize_type:StringName

@export_group("Slider")
@export var minimum_value:float
@export var maximum_value:float
@export var starting_value:float
## If [code]true[/code], zero is an acceptable value for the [code]HSlider[/code]
@export var valid_zero:bool=false
	#get:
		#print_debug(starting_value," ",minimum_value," ",maximum_value)
		#return clampf(starting_value,minimum_value,maximum_value)
	#set(value):
		#print_debug("[SLIDER "+str(name)+"] Set value:"+str(value))
		#value = clampf(starting_value,minimum_value,maximum_value)
		#starting_value = value

func _ready() -> void:
	slider.min_value = minimum_value
	slider.max_value = maximum_value
	slider.set_value_no_signal(starting_value)
	line_edit.text = str(starting_value)
	$Label.text = label
	print_debug("[CALL] update_"+resize_type+"("+str(starting_value)+")")
	get_tree().call_group(resize_type,"update_"+resize_type,starting_value)


	
func _on_line_edit_text_changed(new_text: String) -> void:
	print_debug("entered here")
	if new_text.is_valid_float():
		var tmp = float(new_text)
		if tmp > 0 or valid_zero:
			slider.set_value_no_signal(float(new_text))
			get_tree().call_group(resize_type,"update_"+resize_type,float(new_text))


func _on_slider_value_changed(value: float) -> void:
	line_edit.text = str(value)
	print("entered slider","update_"+resize_type)
	get_tree().call_group(resize_type,"update_"+resize_type,value)


func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	#FlyCamera.
	if toggled_on:
		FlyCamera.set_process(false)
	else:
		FlyCamera.set_process(true)
		
func reset_rotation()->void:
	slider.value = starting_value
	line_edit.text = str(starting_value)
