extends Control
class_name SanitizedEdit

var property_value: float
var previous_value: float
@export var lower_bound: float = 0
@export var higher_bound: float = 0
@onready var line_edit: LineEdit = $LineEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func sanitize_field(low: float, high: float) -> void:
	if line_edit.text.is_valid_float():
		var new_val = clampf(float(line_edit.text), low, high)
		property_value = new_val
		previous_value = new_val
	else:
		line_edit.text = str(previous_value)
func _unhandled_input(event: InputEvent) -> void:
	if line_edit and line_edit.has_focus():
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
				line_edit.release_focus()
				sanitize_field(lower_bound, higher_bound)


func _on_line_edit_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		FlyCamera.set_process(false)
	else:
		FlyCamera.set_process(true)
