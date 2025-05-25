@tool
extends Control
class_name SliderWithLineEdit
@export var slider: HSlider
@export var line_edit: SanitizedEdit
var prev_value: StringName
@export var label: StringName
## Name of the group on which to call the [code]update_resize_type[/code] function
@export var resize_type: StringName

@export var reverse: bool = false

@export_group("Slider")
@export var minimum_value: float
@export var maximum_value: float
@export var starting_value: float
## If [code]true[/code], zero is an acceptable value for the [code]HSlider[/code]
@export var valid_zero: bool = false


func _ready() -> void:
	slider.min_value = minimum_value
	slider.max_value = maximum_value
	slider.set_value_no_signal(starting_value)
	if reverse:
		slider.scale.x = -1
		slider.position.x += slider.size.x
	line_edit.lower_bound = minimum_value
	line_edit.higher_bound = maximum_value
	line_edit.text = str(starting_value)
	line_edit.resize_type = resize_type
	prev_value = line_edit.text
	$Label.text = label
	if resize_type:
		# print("[Slider w LineEdit] update_" + resize_type + "(" + str(starting_value) + ")")
		get_tree().call_group(resize_type, "update_" + resize_type, starting_value)


func _on_slider_value_changed(value: float) -> void:
	line_edit.text = "%.2f" % value

	# print("Calling ")
	get_tree().call_group(resize_type, "update_" + resize_type, value)

"""
Sets the value of both line edit and slider
"""
func set_value(value: float) -> void:
	value = clampf(value, minimum_value, maximum_value)
	# print(label + " clamped value between" + str(minimum_value) + " and maiximum value:" + str(maximum_value) + " is:" + str(value))
	# this line of code triggers _on_slider_value_changed
	slider.value = value


"""
Called by Navbar._on_reset_rotn_btn_pressed()
"""
func reset_rotation() -> void:
	slider.value = starting_value
	line_edit.text = str(starting_value)


# func _on_sanitized_edit_text_changed(new_text: String) -> void:
# 	if new_text.is_valid_float():
# 		var tmp = float(new_text)
# 		if tmp > 0 or valid_zero:
# 			slider.set_value_no_signal(float(new_text))
# 			get_tree().call_group(resize_type, "update_" + resize_type, float(new_text))
