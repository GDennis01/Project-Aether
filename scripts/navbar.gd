extends CanvasLayer

# @onready var rot_camera_viewport: SubViewport = $"/root/Hud/Body/SubViewportContainer/SubViewport"
@onready var sub_viewport_container: SubViewportContainer = $"/root/Hud/Viewport/SubViewportContainer"
@onready var rot_camera_viewport: SubViewport = $"/root/Hud/Viewport/SubViewportContainer/SubViewport"
@onready var minicamera_viewport: SubViewport = $"/root/Hud/Viewport/MiniViewportContainer/SubViewport"
@onready var cam: Camera3D = $"/root/Hud/Viewport/SubViewportContainer/SubViewport/RotatingCamera"
@onready var file_explorer: FileDialog = $TabButtons/ColorRect/HBoxContainer/FileExplorer
# @onready var plane: MeshInstance3D = $"/root/World/Plane"
@onready var comet: MeshInstance3D = $"/root/World/CometMesh"
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
	if $JPLTab.visible:
		$JPLTab.visible = false
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
	if $JPLTab.visible:
		$JPLTab.visible = false
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
	if $JPLTab.visible:
		$JPLTab.visible = false

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
	if $JPLTab.visible:
		$JPLTab.visible = false
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
	if $JPLTab.visible:
		$JPLTab.visible = false
	$ScaleTab.visible = not $ScaleTab.visible

func _on_jpl_btn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $SimTab.visible:
		$SimTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	if $ScaleTab.visible:
		$ScaleTab.visible = false
	$JPLTab.visible = not $JPLTab.visible
	return

		
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
	file_explorer.set_meta("is_screenshot_mini", false)
	file_explorer.popup_centered()
	file_explorer.current_file = "screenshot"
	
	file_explorer.visible = true

func _on_save_nucleus_btn_pressed() -> void:
	file_explorer.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_explorer.filters = ["*.png;Image File"]
	file_explorer.set_meta("is_screenshot_mini", true)
	file_explorer.set_meta("is_screenshot", false)
	file_explorer.popup_centered()
	file_explorer.current_file = "screenshot"
	
	file_explorer.visible = true


## Called when a file, either through the save or load methods, is selected.
## Saves/Loads a configuration
func _on_file_explorer_file_selected(path: String) -> void:
	if file_explorer.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		if file_explorer.get_meta("is_screenshot", false):
			var model_panel := $"/root/Hud/Viewport/Panel"
			var img := await screenshot_panel(model_panel)
			# var img := rot_camera_viewport.get_texture().get_image()
			img.resize(1200, 1200)
			img.save_png(path)
			print("Screenshot saved to: ", path)
		elif file_explorer.get_meta("is_screenshot_mini", false):
			# var minicamera_img := minicamera_viewport.get_texture().get_image()
			var nucleus_model_panel := $"/root/Hud/Viewport/NucleusPanelRect"
			var minicamera_img := await screenshot_panel(nucleus_model_panel)
			minicamera_img.save_png(path)
			print("Minicamera screenshot saved to: ", path)
		else:
			get_tree().call_group("save", "save_data")
			SaveManager.save(path)
	if file_explorer.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		SaveManager.load(path)
		get_tree().call_group("load", "load_data")

## Takes a screenshot of the whole frame and then crops it only to the given panel rect
func screenshot_panel(panel: Panel) -> Image:
	await RenderingServer.frame_post_draw # Wait for the frame to finish rendering

	var viewport := get_viewport()
	var img := viewport.get_texture().get_image()

	# Get the panel's position and size in screen coordinates
	var rect := panel.get_global_rect()

	# Crop the screenshot to the panel's area
	var cropped := img.get_region(rect)
	return cropped


## Now is used as a button for debugging purposes
func _on_full_viewport_btn_pressed() -> void:
	var model_tab_nodes := get_tree().get_nodes_in_group("model_tab")
	for node in model_tab_nodes:
		node.visible = not node.visible
	var settings_tab_nodes := get_tree().get_nodes_in_group("settings_tab")
	for node in settings_tab_nodes:
		node.visible = not node.visible
	# get_visible_area_at_distance(42)
	## Prova plane
	#region plane
	# plane.global_rotation_degrees = comet.global_rotation_degrees
	# plane.transform.basis = comet.transform.basis * Basis(Vector3(1, 0, 0), deg_to_rad(-90))
	# plane.rotate(plane.transform.basis.z, deg_to_rad(90 - Util.i))
	# plane.rotate(plane.transform.basis.y, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	# plane.global_position.y = 0
	# plane.rotate(Vector3.FORWARD, deg_to_rad(90 - Util.i))
	# plane.rotate(Vector3.UP, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	# plane.global_rotation_degrees = comet.global_rotation_degrees
	#endregion plane
	## Prova comet vincent
	#region comet vincent
	# comet.rotate(Vector3.FORWARD, deg_to_rad(90 - Util.i))
	# comet.rotate(Vector3.UP, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	#endregion comet vincent
	## Prova degrees
	#region degrees
	# comet.transform.basis = comet2.transform.basis
	# comet.transform.basis = Util.get_equatorial_to_orbital_basis() * comet.transform.basis
	#endregion degrees
	## Prova lookat
	#region lookat
	# var tmp := comet.transform
	# comet.look_at(Util.sun_direction_vector, Vector3.UP)
	# comet.rotate(comet.transform.basis.y, deg_to_rad(-90))
	# comet.transform = tmp
	#endregion lookat
	## Prova quaternion
	#region quaternion
	# var quat1: Quaternion = Quaternion(comet.transform.basis.z, deg_to_rad(90 - Util.i))
	# var quat2: Quaternion = Quaternion(comet.transform.basis.y, deg_to_rad(- (Util.phi + Util.true_anomaly)))
	# var tot_quat := quat1 * quat2
	# tot_quat = tot_quat.normalized()
	# comet.quaternion = tot_quat
	#endregion quaternion
	return
	# if not rot_camera_viewport.size == Vector2i(900, 900):
	# 	# rot_camera_viewport.get_parent().position =
	# 	rot_camera_viewport.size = Vector2(900, 900)
	# 	rot_camera_viewport.get_parent().position = camera_position
	# else:
	# 	camera_position = rot_camera_viewport.get_parent().position
	# 	rot_camera_viewport.size = get_window().size
	# 	rot_camera_viewport.get_parent().position = Vector2(0, 0)


func _on_change_camera_btn_pressed() -> void:
	get_tree().call_group("camera", "change_camera")


func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_settings_btn_pressed() -> void:
	if not $Navbar/ModelBtn.button_pressed:
		return
	if not $Navbar/SettingsBtn.button_pressed:
		return
	print("Enabling settings tab, disabling model tab")
	$Navbar/ModelBtn.button_pressed = false
	var model_tab_nodes := get_tree().get_nodes_in_group("model_tab")
	for node in model_tab_nodes:
		node.visible = false
	var settings_tab_nodes := get_tree().get_nodes_in_group("settings_tab")
	for node in settings_tab_nodes:
		node.visible = true


func _on_model_btn_pressed() -> void:
	if not $Navbar/SettingsBtn.button_pressed:
		return
	print("Enabling model tab, disabling settings tab")
	$Navbar/SettingsBtn.button_pressed = false
	var model_tab_nodes := get_tree().get_nodes_in_group("model_tab")
	for node in model_tab_nodes:
		node.visible = true
	var settings_tab_nodes := get_tree().get_nodes_in_group("settings_tab")
	for node in settings_tab_nodes:
		node.visible = false
func _on_navbar_tab_changed(tab: int) -> void:
	var model_tab_nodes := get_tree().get_nodes_in_group("model_tab")
	var settings_tab_nodes := get_tree().get_nodes_in_group("settings_tab")
	var help_tab := $"/root/Hud/Body/HelpPanel"
	match tab:
		0:
			for node in model_tab_nodes:
				node.visible = false
			for node in settings_tab_nodes:
				node.visible = true
			help_tab.visible = false
		1:
			for node in model_tab_nodes:
				node.visible = true
			for node in settings_tab_nodes:
				node.visible = false
			help_tab.visible = false
		2:
			for node in model_tab_nodes:
				node.visible = false
			for node in settings_tab_nodes:
				node.visible = false
			help_tab.visible = true


func _on_toggle_date_btn_pressed() -> void:
	Util.date_label.visible = not Util.date_label.visible

func _on_toggle_nucleus_date_btn_pressed() -> void:
	print("Toggling nucleus date label visibility")
	Util.nucleus_date_label.visible = not Util.nucleus_date_label.visible


func _on_toggle_transparency_toggled(toggled_on: bool) -> void:
	if $"/root/Hud/Viewport/Panel/OverlayImg".texture == null:
		return
	$/root/Hud/Viewport/Panel/OverlayImg.visible = toggled_on
	# check if overlay_img exists
	sub_viewport_container.get_node("SubViewport").transparent_bg = toggled_on

func _on_toggle_nucleus_grid_btn_pressed() -> void:
	get_tree().call_group("comet", "toggle_nucleus_grid")


func _on_toggle_model_grid_btn_pressed() -> void:
	$"/root/Hud/Viewport/Panel/CoordinateGrid".visible = not $"/root/Hud/Viewport/Panel/CoordinateGrid".visible
