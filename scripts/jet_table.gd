extends VBoxContainer

var jet_entry_scene := preload("res://scenes/ui/jet_entry.tscn")
@export var content_node:Container
@export var scroll_container:ScrollContainer
@export var max_height:float = 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_instance_valid(scroll_container) or not is_instance_valid(content_node):
		printerr("Scroll container or content node not correctly assigned")
		return
	
	

func _update_scroll_container_height()->void:
	await get_tree().process_frame
	#in case node is freed
	if not is_instance_valid(scroll_container) or not is_instance_valid(content_node):
		return
	var total_content_node_height := content_node.get_combined_minimum_size().y
	var new_height = min(total_content_node_height,max_height)
	if scroll_container.custom_minimum_size.y != new_height:
		scroll_container.custom_minimum_size.y = new_height
	
	
func _on_add_jet_entry_btn_pressed() -> void:
	var new_entry = jet_entry_scene.instantiate() as JetEntry
	var entries :=  get_tree().get_nodes_in_group("jet_entry")
	var max_id = entries.size()
	new_entry.set_id_label(max_id)
	if max_id >0:
		var lat = entries[-1].latitude
		var long = entries[-1].longitude
		get_tree().call_group("latitude","spawn_emitter_at",lat,long)
	content_node.add_child(new_entry)
	_update_scroll_container_height()
	# spawning an emitter at the latitude and longitude given by the second-last entry
	
"""
Called by JetEntry._on_remove_jet_btn_pressed()
TODO: logica per cancellare anche la particella
"""
func remove_jet_entry(id:int)->void:
	var entries:=get_tree().get_nodes_in_group("jet_entry")
	# Cycling through all children to find the correct node to remove
	var removed:bool = false
	for entry in entries as Array[JetEntry]:
		if not removed and entry.jet_id == id:
			content_node.remove_child(entry)
			_update_scroll_container_height()
			removed = true
			# TODO
		if removed:
			entry.set_id_label(entry.jet_id-1)

"""
Called by JetEntry._on_toggle_jet_btn_pressed()
TODO: logica per il toggle della particella
"""
func toggle_jet_entry(id:int)->void:
	var entries:=get_tree().get_nodes_in_group("jet_entry")
	# Cycling through all children to find the correct node to toggle
	for entry in entries as Array[JetEntry]:
		if entry.jet_id == id:
			return
	
