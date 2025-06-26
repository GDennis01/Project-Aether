extends CanvasLayer

# @onready var rot_camera_viewport: SubViewport = $"/root/Hud/Body/SubViewportContainer/SubViewport"
@onready var rot_camera_viewport: SubViewport = $"/root/Hud/Viewport/SubViewportContainer/SubViewport"
@onready var file_explorer: FileDialog = $TabButtons/ColorRect/HBoxContainer/FileExplorer
# @onready var plane: MeshInstance3D = $"/root/World/Plane"
# @onready var comet: MeshInstance3D = $"/root/World/CometMesh"
# @onready var comet2: MeshInstance3D = $"/root/World/CometMesh2"
var camera_position: Vector2

## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

	
#TODO: Simplify this!
## Toggle CometTab and hides all other tabs
func _on_cometbtn_pressed() -> void:
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	$CometTab.visible = not $CometTab.visible

## Toggle JetsTab and hides all other tabs
func _on_jetsbtn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	$JetsTab.visible = not $JetsTab.visible

## Toggle SimTab and hides all other tabs
func _on_sim_btn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	$SimTab.visible = not $SimTab.visible

## Toggle HelpTab and hides all other tabs
func _on_help_btn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	$HelpPanel.visible = not $HelpPanel.visible

func _on_scale_btn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	$ScaleTab.visible = not $ScaleTab.visible

		
# Maybe make a scene button that automatically on pressed trigger this function?
func _on_trigger_rot_btn_pressed() -> void:
	get_tree().call_group("trigger_rotation", "trigger_rotation")
func _on_reset_rotn_btn_pressed() -> void:
	get_tree().call_group("reset_rotation", "reset_rotation")

## Toggle X and Z Axes
func _on_toggle_axes_btn_pressed() -> void:
	get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.X)
	get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.Z)

## Toggle Y Axis
func _on_toggle_y_btn_pressed() -> void:
	get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.Y)

## Toggle Sun Axis
func _on_toggle_sun_btn_pressed() -> void:
	get_tree().call_group("toggle_axis", "toggle_axis", AxisArrow.AXIS_TYPE.SUN)

## Spawns an emitter at a given latitude and longitude. No Longer Used
func _on_spawn_emitter_pressed() -> void:
	var lat: float = float($"JetsTab/Control/Latitude".text)
	var long: float = float($"JetsTab/Control/Longitude".text)
	
	get_tree().call_group("latitude", "spawn_emitter_at", lat, long)

## Opens the OS Native file explorer to save the current configuration in a file
func _on_save_btn_pressed() -> void:
	print(OS.get_data_dir())
	file_explorer.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_explorer.filters = ["*.txt;Configuration File"]
	file_explorer.set_meta("is_screenshot", false)
	file_explorer.popup_centered()
	file_explorer.current_file = "config"
	
	file_explorer.visible = true
## Opens the OS Native file explorer to load a configuration from a chosen file
func _on_load_btn_pressed() -> void:
	file_explorer.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_explorer.filters = ["*.txt;Configuration File"]
	file_explorer.set_meta("is_screenshot", false)
	file_explorer.popup_centered()
	
	file_explorer.visible = true

func disable_btn(btn_name: String) -> void:
	var btn := $TabButtons/ColorRect/HBoxContainer.get_node(btn_name)
	if btn:
		btn.disabled = true
		btn.modulate = Color(0.5, 0.5, 0.5, 1)
	else:
		print("Button not found: ", name)
func enable_btn(btn_name: String) -> void:
	var btn := $TabButtons/ColorRect/HBoxContainer.get_node(btn_name)
	if btn:
		btn.disabled = false
		btn.modulate = Color(1, 1, 1, 1)
	else:
		print("Button not found: ", name)

func _on_screenshot_btn_pressed() -> void:
	file_explorer.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_explorer.filters = ["*.png;Image File"]
	file_explorer.set_meta("is_screenshot", true)
	file_explorer.popup_centered()
	file_explorer.current_file = "screenshot"
	
	file_explorer.visible = true


## Called when a file, either through the save or load methods, is selected.
## Saves/Loads a configuration
func _on_file_explorer_file_selected(path: String) -> void:
	if file_explorer.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		if file_explorer.get_meta("is_screenshot", false):
			var img := rot_camera_viewport.get_texture().get_image()
			img.resize(1200, 1200)
			img.save_png(path)
			print("Screenshot saved to: ", path)
		else:
			get_tree().call_group("save", "save_data")
			SaveManager.save(path)
	if file_explorer.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		SaveManager.load(path)
		get_tree().call_group("load", "load_data")


# TODO: fix this by making so that the container reposition itself based on the new size
func _on_full_viewport_btn_pressed() -> void:
	# if not rot_camera_viewport.size == get_window().size:
	# 	rot_camera_viewport.size = get_window().size
	# 	# rot_camera_viewport.get_parent().position =
	# else:
	# 	rot_camera_viewport.size = Vector2(900, 900)
	## Prova plane
	# plane.global_rotation_degrees = comet.global_rotation_degrees
	# plane.transform.basis = comet.transform.basis * Basis(Vector3(1, 0, 0), deg_to_rad(-90))
	# plane.rotate(plane.transform.basis.z, deg_to_rad(90 - Util.i))
	# plane.rotate(plane.transform.basis.y, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	# plane.global_position.y = 0
	# plane.rotate(Vector3.FORWARD, deg_to_rad(90 - Util.i))
	# plane.rotate(Vector3.UP, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	# plane.global_rotation_degrees = comet.global_rotation_degrees
	## Prova degrees
	# comet.transform.basis = comet2.transform.basis
	# comet.transform.basis = Util.get_equatorial_to_orbital_basis() * comet.transform.basis
	## Prova lookat
	# var tmp := comet.transform
	# print(comet.transform)
	# comet.look_at(Util.sun_direction_vector, Vector3.UP)
	# comet.rotate(comet.transform.basis.y, deg_to_rad(-90))
	# Util.orbital_basis = comet.transform.basis
	# Util.orbital_transformation = comet.transform
	# comet.transform = tmp
	# comet.transform.basis = comet.transform.basis * Basis(Vector3(1, 0, 0), deg_to_rad(-90))
	# comet.rotate(comet.transform.basis.z, deg_to_rad(90 - Util.i))
	# comet.rotate(comet.transform.basis.y, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	## Prova quaternion
	# var quat1: Quaternion = Quaternion(comet.transform.basis.z, deg_to_rad(90 - Util.i))
	# var quat2: Quaternion = Quaternion(comet.transform.basis.y, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	# var tot_quat := quat1 * quat2
	# tot_quat = tot_quat.normalized()
	# comet.quaternion = tot_quat
	# # print("TEST::	")
	# print(Util.convert_equatorial_to_orbital(Vector3(1, 1, 1)))
	# plane.global_position = Vector3(1, 1, 1)
	# var plane_coords := plane.global_position
	# var new_plane_coords := Util.convert_equatorial_to_orbital(plane_coords)
	# plane.global_position = new_plane_coords
	return
	if not rot_camera_viewport.size == Vector2i(900, 900):
		# rot_camera_viewport.get_parent().position =
		rot_camera_viewport.size = Vector2(900, 900)
		rot_camera_viewport.get_parent().position = camera_position
	else:
		camera_position = rot_camera_viewport.get_parent().position
		rot_camera_viewport.size = get_window().size
		rot_camera_viewport.get_parent().position = Vector2(0, 0)


func _on_change_camera_btn_pressed() -> void:
	get_tree().call_group("camera", "change_camera")


func _on_quit_btn_pressed() -> void:
	get_tree().quit()
