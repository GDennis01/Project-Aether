extends CanvasLayer


func _on_update_pa_and_incl_pressed() -> void:
	var pa: float = float($TabButtons/ColorRect/HBoxContainer/PALineEdit.text)
	var incl: float = float($TabButtons/ColorRect/HBoxContainer/InclLineEdit.text)

	# PA: da 0 a 360
	# Inclination: da -90 a 90
	get_tree().call_group("comet", "update_comet_orientation", pa, -incl)


func _on_update_sto_and_incl_pressed() -> void:
	var sun_pa: float = float($TabButtons/ColorRect/HBoxContainer/SunPALineEdit.text)
	var sto: float = float($TabButtons/ColorRect/HBoxContainer/STOLineEdit.text)

	# PA: da 0 a 360
	# STO: da 0 a 180
	get_tree().call_group("sun", "update_sun_orientation", sun_pa, -sto)

func _on_rotate_btn_pressed() -> void:
	# calling the rotate_equatorial_to_orbital function in comet_mesh.gd (the Comet node where the script is attached has the "comet" group)
	get_tree().call_group("comet", "rotate_equatorial_to_orbital")

func _on_undo_rotation_btn_pressed() -> void:
	# resetting the comet rotation to the saved equatorial rotation
	get_tree().call_group("comet", "reset_rotation_to_equatorial")


## For ANTONIO: usa questo button come vuoi! 
## Per chiamare un metodo in comet_mesh, mettere come primo parametro comet e come secondo il nome del metodo in comet_mesh.gd
## Invece per chiamare un metodo in sun.gd, mettere come primo parametro sun e come secondo il nome del metodo in sun.gd
func _on_debug_pressed() -> void:
	get_tree().call_group("sun", "debug")
