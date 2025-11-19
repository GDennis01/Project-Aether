extends CanvasLayer


## Called by Navbar._on_file_explorer_file_selected()
## Save the data into the SaveManager.config structure
func save_data() -> void:
	SaveManager.config.set_value("comet", "distance_from_sun", float($Control/EditSunCometDist.text))
	SaveManager.config.set_value("comet", "direction", float($Control/EditCometDir/SanitizedEdit.text))
	SaveManager.config.set_value("comet", "inclination", float($Control/EditCometIncl/SanitizedEdit.text))
	SaveManager.config.set_value("comet", "radius", float($Control/EditRadius/SanitizedEdit.text))
	SaveManager.config.set_value("comet", "alpha_p", float($Control/AlphaPSanEdit/SanitizedEdit.text))
	SaveManager.config.set_value("comet", "delta_p", float($Control/DeltaPSanEdit/SanitizedEdit.text))

	SaveManager.config.set_value("sun", "direction", float($Control/EditSunDir/SanitizedEdit.text))
	SaveManager.config.set_value("sun", "inclination", float($Control/EditSunIncl/SanitizedEdit.text))

	SaveManager.config.set_value("particle", "albedo", float($Control/EditAlbedo.text))
	SaveManager.config.set_value("particle", "diameter", float($Control/EditParticleDiameter.text))
	SaveManager.config.set_value("particle", "density", float($Control/EditParticleDensity.text))

	
## Called by Navbar._on_file_explorer_file_selected()
## Loads the data from the config file into the different element of the scene
func load_data() -> void:
	$Control/EditSunCometDist.set_value(float(SaveManager.config.get_value("comet", "distance_from_sun", 0)))
	$Control/EditRadius.set_value(float(SaveManager.config.get_value("comet", "radius", 0)))
	$Control/EditCometIncl.set_value(float(SaveManager.config.get_value("comet", "inclination", 0)))
	$Control/EditCometDir.set_value(float(SaveManager.config.get_value("comet", "direction", 0)))
	$Control/AlphaPSanEdit.set_value(float(SaveManager.config.get_value("comet", "alpha_p", 0)))
	$Control/DeltaPSanEdit.set_value(float(SaveManager.config.get_value("comet", "delta_p", 0)))

	$Control/EditSunDir.set_value(float(SaveManager.config.get_value("sun", "direction", 0)))
	$Control/EditSunIncl.set_value(float(SaveManager.config.get_value("sun", "inclination", 0)))

	$Control/EditAlbedo.set_value(float(SaveManager.config.get_value("particle", "albedo", 0)))
	$Control/EditParticleDiameter.set_value(float(SaveManager.config.get_value("particle", "diameter", 0)))
	$Control/EditParticleDensity.set_value(float(SaveManager.config.get_value("particle", "density", 0)))


func _on_next_date_btn_pressed() -> void:
	get_tree().call_group("switch_date", "switch_date_next_date")


func _on_prev_date_btn_pressed() -> void:
	get_tree().call_group("switch_date", "switch_date_prev_date")


func _on_prev_date_full_btn_pressed() -> void:
	get_tree().call_group("switch_date", "switch_date_first_date")


func _on_next_date_full_btn_pressed() -> void:
	get_tree().call_group("switch_date", "switch_date_last_date")
