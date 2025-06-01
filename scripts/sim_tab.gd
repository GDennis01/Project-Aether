extends CanvasLayer

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
## Called by Navbar._on_file_explorer_file_selected()
## Loads the data from the config file into the different element of the scene
func load_data() -> void:
	$Control/FrequencyEdit.set_value(float(SaveManager.config.get_value("simulation", "frequency", 0)))
	$Control/NumRotationEdit.set_value(float(SaveManager.config.get_value("simulation", "num_rotations", 0)))
	$Control/JetRateEdit.set_value(float(SaveManager.config.get_value("simulation", "jet_rate", 0)))
	$Control/KmScaleEdit.set_value(float(SaveManager.config.get_value("simulation", "scale", 0)))
