extends CanvasLayer

@onready var tel_res_km_pixel: LineEdit = $Control/TelResLineEdit
@onready var fov_arcmin: LineEdit = $Control/FOVArcminLineEdit
@onready var fov_km: LineEdit = $Control/FOVKmLineEdit
@onready var scale_factor: LineEdit = $Control/ScaleFactorLineEdit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


## Called by Navbar._on_file_explorer_file_selected()
## Save the data into the SaveManager.config structure
func save_data() -> void:
	SaveManager.config.set_value("scale", "delta_au", float($Control/DeltaAUEdit.text))
	SaveManager.config.set_value("scale", "tel_res", float($Control/TelResolutionEdit.text))
	SaveManager.config.set_value("scale", "tel_img_size", float($Control/TelImageSizeEdit.text))
	SaveManager.config.set_value("scale", "window_fov", float($Control/WindowFOVEdit.text))
	SaveManager.config.set_value("scale", "window_size", float($Control/WindowSizeEdit.text))
## Called by Navbar._on_file_explorer_file_selected()
## Loads the data from the config file into the different element of the scene
func load_data() -> void:
	# set block signals to true to avoid triggering update methods
	# $Control/DeltaAUEdit.set_block_signals(true)
	# $Control/TelResolutionEdit.set_block_signals(true)
	# $Control/TelImageSizeEdit.set_block_signals(true)
	# $Control/WindowFOVEdit.set_block_signals(true)
	# $Control/WindowSizeEdit.set_block_signals(true)
	$Control/DeltaAUEdit.set_value(float(SaveManager.config.get_value("scale", "delta_au", 0)))
	$Control/TelResolutionEdit.set_value(float(SaveManager.config.get_value("scale", "tel_res", 0)))
	$Control/TelImageSizeEdit.set_value(float(SaveManager.config.get_value("scale", "tel_img_size", 0)))
	$Control/WindowFOVEdit.set_value(float(SaveManager.config.get_value("scale", "window_fov", 0)))
	$Control/WindowSizeEdit.set_value(float(SaveManager.config.get_value("scale", "window_size", 0)))

	# set block signals to false to allow triggering update methods
	# $Control/DeltaAUEdit.set_block_signals(false)
	# $Control/TelResolutionEdit.set_block_signals(false)
	# $Control/TelImageSizeEdit.set_block_signals(false)
	# $Control/WindowFOVEdit.set_block_signals(false)
	# $Control/WindowSizeEdit.set_block_signals(false)


## These methods are called by SanitizedEdit through call_group() mechanism

func update_delta_au(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated delta_au:%f"%value)
	Util.earth_comet_delta = value
	update_tel_res_km_pixel()
	# update_scale_factor()

func update_tel_resolution(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated tel_resolution:%f"%value)
	Util.tel_resolution = value
	update_tel_res_km_pixel()
	update_fov_arcmin()
	update_scale_factor()

func update_tel_image_size(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated tel_image_size:%f"%value)
	Util.tel_image_size = value
	update_fov_km()
	update_fov_arcmin()

func update_window_fov(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated window_fov:%f"%value)
	Util.window_fov = value
	update_scale_factor()

func update_window_size(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated window_size:%f"%value)
	Util.window_size = value
	update_scale_factor()


func update_tel_res_km_pixel() -> void:
	Util.tel_res_km_pixel = sin(Util.tel_resolution / 206265) * Util.earth_comet_delta * (Util.AU / 1000)
	if tel_res_km_pixel:
		tel_res_km_pixel.text = str(int(Util.tel_res_km_pixel))
	update_fov_km()
	update_fov_arcmin()
	update_scale_factor()

func update_fov_arcmin() -> void:
	Util.fov_arcmin = Util.tel_resolution * Util.tel_image_size / 60
	if fov_arcmin:
		fov_arcmin.text = str(Util.fov_arcmin)

func update_fov_km() -> void:
	Util.fov_km = Util.tel_image_size * Util.tel_res_km_pixel
	if fov_km:
		fov_km.text = str(int(Util.fov_km))

func update_scale_factor() -> void:
	var window_image_scale_factor: float = Util.tel_image_size / Util.window_size
	var fov_full_zoom: float = Util.window_fov / 1000 * window_image_scale_factor
	var pixel_resolution_full_zoom: float = fov_full_zoom / Util.window_size
	Util.scale = Util.tel_res_km_pixel / pixel_resolution_full_zoom * window_image_scale_factor * 1000
	# print("Scale factor: %f"%Util.scale)
	if scale_factor:
		scale_factor.text = str(Util.scale / 1000)
