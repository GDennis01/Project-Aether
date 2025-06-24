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