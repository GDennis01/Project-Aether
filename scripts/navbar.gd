
extends CanvasLayer


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
	get_tree().call_group("trigger_rotation","trigger_rotation")
func _on_reset_rotn_btn_pressed() -> void:
	get_tree().call_group("reset_rotation","reset_rotation")

func _on_toggle_axes_btn_pressed() -> void:
	get_tree().call_group("toggle_axis","toggle_axis")


func _on_spawn_emitter_pressed() -> void:
	var lat:float = float($"JetsTab/Control/Latitude".text)
	var long:float = float($"JetsTab/Control/Longitude".text)
	
	get_tree().call_group("latitude","spawn_emitter_at",lat,long)
