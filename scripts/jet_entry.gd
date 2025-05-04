extends Control
class_name JetEntry
@export var jet_id:int = 0
@export var speed:float = 0
@export var latitude:float = 0
@export var longitude:float = 0
@export var diffusion:float = 0
@export var color:Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_speed_edit_text_changed(new_text: String) -> void:
	if new_text.is_valid_float():
		speed = float(new_text)
