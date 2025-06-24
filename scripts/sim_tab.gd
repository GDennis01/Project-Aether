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
	SaveManager.config.set_value("simulation", "i", float($Control/IEdit.text))
	SaveManager.config.set_value("simulation", "phi", float($Control/PhiEdit.text))
	SaveManager.config.set_value("simulation", "true_anomaly", float($Control/TrueAnomalyEdit.text))
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
	$Control/IEdit.set_value(float(SaveManager.config.get_value("simulation", "i", 0)))
	$Control/PhiEdit.set_value(float(SaveManager.config.get_value("simulation", "phi", 0)))
	$Control/TrueAnomalyEdit.set_value(float(SaveManager.config.get_value("simulation", "true_anomaly", 0)))

	# set block signals for the sanitized edits
	# $Control/FrequencyEdit.set_block_signals(false)
	# $Control/NumRotationEdit.set_block_signals(false)
	# $Control/JetRateEdit.set_block_signals(false)
	# $Control/KmScaleEdit.set_block_signals(false)
	# $Control/IEdit.set_block_signals(false)
	# $Control/PhiEdit.set_block_signals(false)
	# $Control/TrueAnomalyEdit.set_block_signals(false)


func update_i(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated i:%f"%value)
	Util.i = value

func update_phi(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated phi:%f"%value)
	Util.phi = value

func update_true_anomaly(value: float) -> void:
	if Util.PRINT_UPDATE_METHOD: print("Updated true_anomaly:%f"%value)
	Util.true_anomaly = value