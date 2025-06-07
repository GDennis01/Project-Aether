extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


## Called by Navbar._on_file_explorer_file_selected()
## Save the data into the SaveManager.config structure
func save_data() -> void:
	SaveManager.config.set_value("scale", "tel_res", float($Control/TelResolutionEdit.text))
	SaveManager.config.set_value("scale", "tel_img_size", float($Control/TelImageSizeEdit.text))
	SaveManager.config.set_value("scale", "window_fov", float($Control/WindowFOVEdit.text))
	SaveManager.config.set_value("scale", "window_size", float($Control/WindowSizeEdit.text))
## Called by Navbar._on_file_explorer_file_selected()
## Loads the data from the config file into the different element of the scene
func load_data() -> void:
	$Control/TelResolutionEdit.set_value(float(SaveManager.config.get_value("scale", "tel_res", 0)))
	$Control/TelImageSizeEdit.set_value(float(SaveManager.config.get_value("scale", "tel_img_size", 0)))
	$Control/WindowFOVEdit.set_value(float(SaveManager.config.get_value("scale", "window_fov", 0)))
	$Control/WindowSizeEdit.set_value(float(SaveManager.config.get_value("scale", "window_size", 0)))


## These methods are called by SanitizedEdit through call_group() mechanism

func update_tel_resolution(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated tel_resolution:%f"%value)
	Util.tel_resolution = value
func update_tel_image_size(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated tel_image_size:%f"%value)
	Util.tel_image_size = value
func update_window_fov(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated window_fov:%f"%value)
	Util.window_fov = value
func update_window_size(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated window_size:%f"%value)
	Util.window_size = value
