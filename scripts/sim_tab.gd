extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func save_data() -> void:
	var freq = float($Control/FrequencyEdit.text)
	var num_rots = float($Control/NumRotationEdit.text)
	var jet_rate = float($Control/JetRateEdit.text)
	SaveManager.config.set_value("simulation", "frequency", freq)
	SaveManager.config.set_value("simulation", "num_rotations", num_rots)
	SaveManager.config.set_value("simulation", "jet_rate", jet_rate)
func load_data() -> void:
	var freq = SaveManager.config.get_value("simulation", "frequency", 0)
	var num_rots = SaveManager.config.get_value("simulation", "num_rotations", 0)
	var jet_rate = SaveManager.config.get_value("simulation", "jet_rate", 0)
	$Control/FrequencyEdit.set_value(freq)
	$Control/NumRotationEdit.set_value(num_rots)
	$Control/JetRateEdit.set_value(jet_rate)
