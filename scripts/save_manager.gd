extends Node2D

var config := ConfigFile.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func save(filename: StringName) -> void:
	config.save(filename)
func load(filename: StringName) -> void:
	config = ConfigFile.new()
	config.load(filename)
func get_data_bytes() -> PackedByteArray:
	return config.encode_to_text().to_utf8_buffer()
func load_from_string(data_string: String) -> void:
	config = ConfigFile.new()
	config.parse(data_string)