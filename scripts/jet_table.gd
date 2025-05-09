extends VBoxContainer
class_name JetTable
var jet_entry_scene := preload("res://scenes/ui/jet_entry.tscn")
var emitter_scene := preload("res://scenes/particle_emitter.tscn")
var entry_emitter_dict := Dictionary()
@export var content_node: Container
@export var scroll_container: ScrollContainer
@export var max_height: float = 300

var _is_id_update_pending = false
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
	

"""
Called by Navbar._on_load_btn_pressed().
Loads the data from the config file into the different element of the scene
"""
func load_data() -> void:
	# first I remove all jet_entries
	print("Before deleting the current jet_body" + str(entry_emitter_dict))
	_clear_data_for_load()
	print("After deleting current jet_body" + str(entry_emitter_dict))
	var entries_to_add = SaveManager.config.get_section_keys("jets")
	print("Entries to add:" + str(entries_to_add))
	for entry in entries_to_add:
		var loaded_entry = SaveManager.config.get_value("jets", str(entry))
		var new_entry = jet_entry_scene.instantiate() as JetEntry
		new_entry.set_id_label(int(entry))
		content_node.add_child(new_entry)

		var emitter = emitter_scene.instantiate() as Emitter

		new_entry.speed_edit.sanitized_edit_focus_exited.connect(emitter.update_speed)
		new_entry.latitude_edit.sanitized_edit_focus_exited.connect(emitter.update_lat)
		new_entry.longitude_edit.sanitized_edit_focus_exited.connect(emitter.update_long)
		new_entry.diffusion_edit.sanitized_edit_focus_exited.connect(emitter.update_diff)
		new_entry.color_edit.color_changed.connect(emitter.update_color)

		new_entry.set_speed(loaded_entry[0])
		new_entry.set_latitude(loaded_entry[1])
		new_entry.set_longitude(loaded_entry[2])
		new_entry.set_diffusion(loaded_entry[3])
		new_entry.set_color(loaded_entry[4])

		# Saving (jet_entry,emitter) to a dictionary so that later on I can remove both entry(HUD) and the emitter node
		entry_emitter_dict.set(new_entry.get_instance_id(), emitter.get_instance_id())
		print("Adding entry" + str(new_entry.get_instance_id()))
		# spawning an emitter at (0,0)
		get_tree().call_group("latitude", "spawn_emitter_at", new_entry.latitude, new_entry.longitude, emitter)
	print("Dict after finished loading" + str(entry_emitter_dict))
	print("--------------------")
	_update_scroll_container_height()
	pass
func _on_add_jet_entry_btn_pressed() -> void:
	# creating the entry in the hud
	var new_entry = jet_entry_scene.instantiate() as JetEntry
	var entries := get_tree().get_nodes_in_group("jet_entry")
	var max_id = entries.size()
	new_entry.set_id_label(max_id)

	# adding the entry to the vertical container
	content_node.add_child(new_entry)
	_update_scroll_container_height()

	# instantiating an emitter so that I can pass it to the CometMesh and thus setting correctly the position according
	# to the comet radius
	var emitter = load("res://scenes/particle_emitter.tscn").instantiate() as Emitter

	# connecting the emitter to SanitizedEdit signals so that whenever one of those SanitizedEdit value changes,
	# the corresponding update method is called on the emitter
	new_entry.speed_edit.sanitized_edit_focus_exited.connect(emitter.update_speed)
	new_entry.latitude_edit.sanitized_edit_focus_exited.connect(emitter.update_lat)
	new_entry.longitude_edit.sanitized_edit_focus_exited.connect(emitter.update_long)
	new_entry.diffusion_edit.sanitized_edit_focus_exited.connect(emitter.update_diff)
	new_entry.color_edit.color_changed.connect(emitter.update_color)

	# Saving entry to config
	SaveManager.config.set_value("jets", str(new_entry.jet_id), [new_entry.speed, new_entry.latitude, new_entry.longitude, new_entry.diffusion, new_entry.color])

	# Saving (jet_entry,emitter) to a dictionary so that later on I can remove both entry(HUD) and the emitter node
	entry_emitter_dict.set(new_entry.get_instance_id(), emitter.get_instance_id())
	# spawning an emitter at (0,0)
	get_tree().call_group("latitude", "spawn_emitter_at", new_entry.latitude, new_entry.longitude, emitter)

func _clear_data_for_load() -> void:
	for child in content_node.get_children().duplicate():
		var id = child.get_instance_id()
		var emitter_id = entry_emitter_dict[id]
		entry_emitter_dict.erase(id)
		child.queue_free()
		get_tree().call_group("comet", "remove_emitter", emitter_id)

"""
CalledbyJetEntry._on_remove_jet_btn_pressed()
"""
func remove_jet_entry(id: int) -> void:
	# first deleting the entry, then removing the emitter by calling a comet's method
	var entry = instance_from_id(id)
	var emitter_id = entry_emitter_dict[id]
	entry_emitter_dict.erase(id)
	entry.queue_free()
	# removing corresponding jet section
	SaveManager.config.erase_section("jet_" + str(emitter_id))
	get_tree().call_group("comet", "remove_emitter", emitter_id)

	# update container size and ids of each jet entry
	# the call is deferred so that it works properly even if multiple jets have been queued for deletion 
	_ensure_id_update_is_scheduled()


"""
Update ids and scroll size if an update_id has not been issued yet
"""
func _ensure_id_update_is_scheduled() -> void:
	if not _is_id_update_pending:
		_is_id_update_pending = true
		call_deferred("_deferred_update_ids_and_scroll")

"""
Defers the update of ids and scroll container
"""
func _deferred_update_ids_and_scroll() -> void:
	_is_id_update_pending = false
	_update_scroll_container_height()

	var entries := $JetBodyScrollBar/JetBody.get_children()
	var tmp_id = 0

	for _entry in entries as Array[JetEntry]:
		if _entry is JetEntry and is_instance_valid(_entry):
			if _entry.is_queued_for_deletion():
				continue
			# updating the id only if it's different
			if _entry.jet_id != tmp_id:
				SaveManager.config.set_value("jets", str(tmp_id), [_entry.speed, _entry.latitude, _entry.longitude, _entry.diffusion, _entry.color])
				_entry.set_id_label(tmp_id)
			tmp_id += 1
	# since this method gets called whenever an entry is deleted, it means I have to remove the last entry from the config file
	SaveManager.config.erase_section_key("jets", str(tmp_id))

"""
CalledbyJetEntry._on_toggle_jet_btn_pressed()
"""
func toggle_jet_entry(id: int) -> void:
	var emitter_to_toggle = instance_from_id(entry_emitter_dict[id])
	emitter_to_toggle.visible = not emitter_to_toggle.visible
