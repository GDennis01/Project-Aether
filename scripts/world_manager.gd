extends WorldEnvironment
#@onready var HUD = $HUD

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _window := get_window()
	_window.min_size = Vector2i(1330, 930)