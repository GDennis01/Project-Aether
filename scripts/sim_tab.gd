extends CanvasLayer

@onready var file_explorer: FileDialog = $"Control/FileExplorer"
@onready var overlay_img_linedit: LineEdit = $"Control/OverlayImgLineEdit"
@onready var overlay_img_picker_btn: Button = $"Control/OverlayImgPickerBtn"
@onready var del_overlay_img_btn: Button = $"Control/DelOverlayImgBtn"
@onready var transparency_label: Label = $"Control/TransparencyLabel"
@onready var transparency_slider: HSlider = $"Control/TransparencySlider"
@onready var overlay_img: TextureRect = $"/root/Hud/Viewport/Panel/OverlayImg"
@onready var sub_viewport_container: SubViewportContainer = $"/root/Hud/Viewport/SubViewportContainer"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# $Control/FrequencyEdit.set_value(1)
	# $Control/NumRotationEdit.set_value(1)
	# $Control/JetRateEdit.set_value(5)
	pass

## Called by Navbar._on_file_explorer_file_selected()
## Save the data into the SaveManager.config structure
func save_data() -> void:
	SaveManager.config.set_value("simulation", "frequency", float($Control/FrequencyEdit.text))
	SaveManager.config.set_value("simulation", "num_rotations", float($Control/NumRotationEdit.text))
	SaveManager.config.set_value("simulation", "jet_rate", float($Control/JetRateEdit.text))
	SaveManager.config.set_value("simulation", "scale", float($Control/KmScaleEdit.text))
	SaveManager.config.set_value("simulation", "i", float($Control/IEdit.text))
	SaveManager.config.set_value("simulation", "phi", float($Control/PhiEdit.text))
	SaveManager.config.set_value("simulation", "true_anomaly", float($Control/TrueAnomalyEdit.text))
	SaveManager.config.set_value("simulation", "n_points", int($Control/NPointsEdit.text))
## Called by Navbar._on_file_explorer_file_selected()
## Loads the data from the config file into the different element of the scene
func load_data() -> void:
	# set block signals for the sanitized edits
	# $Control/FrequencyEdit.set_block_signals(true)
	# $Control/NumRotationEdit.set_block_signals(true)
	# $Control/JetRateEdit.set_block_signals(true)
	# $Control/KmScaleEdit.set_block_signals(true)
	# $Control/IEdit.set_block_signals(true)
	# $Control/PhiEdit.set_block_signals(true)
	# $Control/TrueAnomalyEdit.set_block_signals(true)
	$Control/FrequencyEdit.set_value(float(SaveManager.config.get_value("simulation", "frequency", 0)))
	$Control/NumRotationEdit.set_value(float(SaveManager.config.get_value("simulation", "num_rotations", 0)))
	$Control/JetRateEdit.set_value(float(SaveManager.config.get_value("simulation", "jet_rate", 0)))
	$Control/KmScaleEdit.set_value(float(SaveManager.config.get_value("simulation", "scale", 0)))
	# $Control/IEdit.set_value(float(SaveManager.config.get_value("simulation", "i", 0)))
	# $Control/PhiEdit.set_value(float(SaveManager.config.get_value("simulation", "phi", 0)))
	# $Control/TrueAnomalyEdit.set_value(float(SaveManager.config.get_value("simulation", "true_anomaly", 0)))
	$Control/NPointsEdit.set_value(int(SaveManager.config.get_value("simulation", "n_points", 1)))

	# set block signals for the sanitized edits
	# $Control/FrequencyEdit.set_block_signals(false)
	# $Control/NumRotationEdit.set_block_signals(false)
	# $Control/JetRateEdit.set_block_signals(false)
	# $Control/KmScaleEdit.set_block_signals(false)
	# $Control/IEdit.set_block_signals(false)
	# $Control/PhiEdit.set_block_signals(false)
	# $Control/TrueAnomalyEdit.set_block_signals(false)


# func update_i(value: float) -> void:
# 	if Util.PRINT_UPDATE_METHOD: print("Updated i:%f"%value)
# 	Util.i = value

# func update_phi(value: float) -> void:
# 	if Util.PRINT_UPDATE_METHOD: print("Updated phi:%f"%value)
# 	Util.phi = value

# func update_true_anomaly(value: float) -> void:
# 	if Util.PRINT_UPDATE_METHOD: print("Updated true_anomaly:%f"%value)
# 	Util.true_anomaly = value

func update_n_points(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD or true: print("Updated n_points:%f"%value)
	Util.n_points = int(value)

func _on_overlay_img_chosen() -> void:
	print("lol")
# shows the navbar.file_explorer
func _on_overlay_img_picker_btn_pressed() -> void:
	file_explorer.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_explorer.filters = ["*.png;Image File"]
	file_explorer.popup_centered()
	file_explorer.current_file = "config"
	
	file_explorer.visible = true


func _on_file_explorer_file_selected(path: String) -> void:
	print("File selected: ", path)
	var filename := path.get_file()
	overlay_img_linedit.visible = true
	overlay_img_linedit.text = filename

	overlay_img_picker_btn.visible = false
	del_overlay_img_btn.visible = true

	transparency_label.visible = true
	transparency_slider.visible = true

	sub_viewport_container.get_node("SubViewport").transparent_bg = true

	load_texture(path)

func load_texture(path: String) -> void:
	var img := Image.load_from_file(path)
	img.resize(900, 900)
	overlay_img.texture = ImageTexture.create_from_image(img)
	overlay_img.modulate.a = 0.5

func _on_del_overlay_img_btn_pressed() -> void:
	overlay_img_linedit.visible = false
	overlay_img_linedit.text = ""

	overlay_img_picker_btn.visible = true
	del_overlay_img_btn.visible = false

	transparency_label.visible = false
	transparency_slider.value = 0.5
	transparency_slider.visible = false

	# remove overlay image
	overlay_img.texture = null

	sub_viewport_container.modulate.a = 1.0
	sub_viewport_container.get_node("SubViewport").transparent_bg = false

func _on_transparency_slider_value_changed(value: float) -> void:
	print(value)
	sub_viewport_container.modulate.a = value
