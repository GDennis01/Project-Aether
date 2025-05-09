extends CanvasLayer

var jet_entry_scene := preload("res://scenes/ui/jet_entry.tscn")
var entry_emitter_dict := Dictionary()
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

	
#TODO: Simplify this!
func _on_cometbtn_pressed() -> void:
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $GraphicTab.visible:
		$GraphicTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	$CometTab.visible = not $CometTab.visible


func _on_jetsbtn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $GraphicTab.visible:
		$GraphicTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	$JetsTab.visible = not $JetsTab.visible


func _on_graphicsbtn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $HelpPanel.visible:
		$HelpPanel.visible = false
	$GraphicTab.visible = not $GraphicTab.visible


func _on_help_btn_pressed() -> void:
	if $CometTab.visible:
		$CometTab.visible = false
	if $JetsTab.visible:
		$JetsTab.visible = false
	if $GraphicTab.visible:
		$GraphicTab.visible = false
	$HelpPanel.visible = not $HelpPanel.visible
		

# Maybe make a scene button that automatically on pressed trigger this function?
func _on_trigger_rot_btn_pressed() -> void:
	get_tree().call_group("trigger_rotation", "trigger_rotation")
func _on_reset_rotn_btn_pressed() -> void:
	get_tree().call_group("reset_rotation", "reset_rotation")

func _on_toggle_axes_btn_pressed() -> void:
	get_tree().call_group("toggle_axis", "toggle_axis")


func _on_spawn_emitter_pressed() -> void:
	var lat: float = float($"JetsTab/Control/Latitude".text)
	var long: float = float($"JetsTab/Control/Longitude".text)
	
	get_tree().call_group("latitude", "spawn_emitter_at", lat, long)


func _on_add_jet_entry_btn_pressed() -> void:
	# var new_entry = jet_entry_scene.instantiate() as JetEntry
	# var entries := get_tree().get_nodes_in_group("jet_entry")
	# var max_id = entries.size()
	# new_entry.set_id_label(max_id)
	# if max_id > 0:
	# 	var lat = entries[-1].latitude
	# 	var long = entries[-1].longitude
	# 	#get_tree().call_group("latitude","spawn_emitter_at",lat,long)
	# $JetsTab/Control/JetTable/JetBodyScrollBar/JetBody.add_child(new_entry)
	# $JetsTab/Control/JetTable._update_scroll_container_height()
	pass

func _on_save_btn_pressed() -> void:
	print(OS.get_data_dir())
	$TabButtons/ColorRect/HBoxContainer/FileExplorer.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	$TabButtons/ColorRect/HBoxContainer/FileExplorer.visible = true

func _on_load_btn_pressed() -> void:
	$TabButtons/ColorRect/HBoxContainer/FileExplorer.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	$TabButtons/ColorRect/HBoxContainer/FileExplorer.visible = true

	
func _on_file_explorer_file_selected(path: String) -> void:
	if $TabButtons/ColorRect/HBoxContainer/FileExplorer.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		SaveManager.save(path)
	if $TabButtons/ColorRect/HBoxContainer/FileExplorer.file_mode == FileDialog.FILE_MODE_OPEN_FILE:
		SaveManager.load(path)
		get_tree().call_group("load", "load_data")
