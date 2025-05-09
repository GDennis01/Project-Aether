extends CanvasLayer

"""
Called by Navbar._on_load_btn_pressed()
Loads the data from the config file into the different element of the scene
"""
func load_data() -> void:
	$Control/EditRadius.set_value(SaveManager.config.get_value("comet", "radius"))
	$Control/EditCometIncl.set_value(SaveManager.config.get_value("comet", "inclination"))
	$Control/EditCometDir.set_value(SaveManager.config.get_value("comet", "direction"))
	$Control/EditSunDir.set_value(SaveManager.config.get_value("sun", "direction"))
	$Control/EditSunIncl.set_value(SaveManager.config.get_value("sun", "inclination"))