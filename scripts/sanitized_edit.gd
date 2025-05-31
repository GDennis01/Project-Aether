@tool
extends Control
class_name SanitizedEdit

var property_value: float
var previous_value: float
@export var resize_type: StringName
@export var slider: Slider
@export var lower_bound: float = 0
@export var higher_bound: float = 0

signal sanitized_edit_focus_exited

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_value(float(self.text))

func set_value(_value: float) -> void:
	self.text = str(_value)
	var tmp := property_value
	previous_value = tmp
	property_value = _value
	if resize_type:
		# print("[Sanitized Edit] Calling update_%s" % resize_type)
		get_tree().call_group(resize_type, "update_" + resize_type, property_value)

func sanitize_field(low: float, high: float) -> void:
	if self.text.is_valid_float():
		if int(high) == -1:
			high = INF
		var new_val := clampf(float(self.text), low, high)
		property_value = new_val
		previous_value = new_val
		self.text = str(new_val)
	else:
		self.text = str(previous_value)
## Makes you release focus when you click outside a LineEdit. In this way, the _on_focus_exited method is triggered
func _unhandled_input(event: InputEvent) -> void:
	if self and self.has_focus():
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				self.release_focus()
				sanitize_field(lower_bound, higher_bound)
				# sanitized_edit_focus_exited.emit(float(self.text))
				# if slider:
				# 	slider.set_value_no_signal(float(self.text))
				# 	print("a")
				# 	return
				# if resize_type:
				# 	print("Unh")
				# 	get_tree().call_group(resize_type, "update_" + resize_type, float(self.text))


func _on_editing_toggled(toggled_on: bool) -> void:
	# if toggled_on:
	# 	FlyCamera.set_process(false)
	# else:
	# 	FlyCamera.set_process(true)
	pass

func _on_focus_exited() -> void:
	# sanitize_field(lower_bound, higher_bound)
	sanitized_edit_focus_exited.emit(float(self.text))
	if slider:
		slider.set_value_no_signal(float(self.text))
	if resize_type:
		get_tree().call_group(resize_type, "update_" + resize_type, float(self.text))
