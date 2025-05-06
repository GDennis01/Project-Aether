extends VBoxContainer
class_name JetTable
var jet_entry_scene := preload("res://scenes/ui/jet_entry.tscn")
var entry_emitter_dict := Dictionary()
@export var content_node: Container
@export var scroll_container: ScrollContainer
@export var max_height: float = 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not is_instance_valid(scroll_container) or not is_instance_valid(content_node):
		printerr("Scroll container or content node not correctly assigned")
		return
	
	
func _update_scroll_container_height() -> void:
	await get_tree().process_frame
	#in case node is freed
	if not is_instance_valid(scroll_container) or not is_instance_valid(content_node):
		return
	var total_content_node_height := content_node.get_combined_minimum_size().y
	var new_height = min(total_content_node_height, max_height)
	if scroll_container.custom_minimum_size.y != new_height:
		scroll_container.custom_minimum_size.y = new_height
	
	
func _on_add_jet_entry_btn_pressed() -> void:
	var new_entry = jet_entry_scene.instantiate() as JetEntry
	var entries := get_tree().get_nodes_in_group("jet_entry")
	var max_id = entries.size()
	new_entry.set_id_label(max_id)

	content_node.add_child(new_entry)
	_update_scroll_container_height()

	# instantiating an emitter so that I can pass it to the CometMesh and thus setting correctly the position according
	# to the comet radius
	var emitter = load("res://scenes/particle_emitter.tscn").instantiate() as Emitter
	# Saving (jet_entry,emitter) to a dictionary so that later on I can remove both entry(HUD) and the emitter node
	entry_emitter_dict.set(new_entry.get_instance_id(), emitter.get_instance_id())
	get_tree().call_group("latitude", "spawn_emitter_at", randf() * 10, randf() * 10, emitter)

	# spawning an emitter at the latitude and longitude given by the second-last entry
"""
Called by JetEntry._on_remove_jet_btn_pressed()
TODO: logica per cancellare anche la particella
"""
func remove_jet_entry(id: int) -> void:
	# first deleting the entry, then removing the emitter by calling a comet's method
	var entry = instance_from_id(id)
	var emitter_id = entry_emitter_dict[id]
	entry.queue_free()
	get_tree().call_group("comet", "remove_emitter", emitter_id)
	await get_tree().process_frame
	_update_scroll_container_height()

	#then I update ids of the remaining jets
	# FIXME: it doesn't always update accordingly
	var entries := get_tree().get_nodes_in_group("jet_entry")
	var tmp_id = 0
	for _entry in entries as Array[JetEntry]:
		print(_entry)
		_entry.set_id_label(tmp_id)
		tmp_id += 1
			# var id_tmp = _entry.get_instance_id()

"""
Called by JetEntry._on_toggle_jet_btn_pressed()
TODO: logica per il toggle della particella
"""
func toggle_jet_entry(id: int) -> void:
	var emitter_to_toggle = instance_from_id(entry_emitter_dict[id])
	emitter_to_toggle.visible = not emitter_to_toggle.visible
