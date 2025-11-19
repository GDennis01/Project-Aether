extends WorldEnvironment
#@onready var HUD = $HUD

# Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	var _window := get_window()
# 	_window.min_size = Vector2i(1330, 980)
func _ready() -> void:
	# Wait a short moment, then force a resize
	await get_tree().process_frame
	_force_resize()
	var _window := get_window()
	_window.min_size = Vector2i(1920, 1030)

func _force_resize() -> void:
	var size := DisplayServer.window_get_size()
	DisplayServer.window_set_size(size)