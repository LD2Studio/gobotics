extends Node3D

signal focused_block(block: Node)

func _ready() -> void:
	pass # Replace with function body.
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var blocks = get_tree().get_nodes_in_group("BLOCKS")
		for block in blocks:
			if block.focused:
				emit_signal("focused_block", block)
				return
		emit_signal("focused_block", null)
		

func save_tscn():
	var blocks = get_tree().get_nodes_in_group("BLOCKS")
#	print_debug("Nodes in BLOCKS group: ", blocks)
	for block in blocks:
		block.owner = self

	var game_scene := PackedScene.new()
	game_scene.pack(self)
	var err = ResourceSaver.save(game_scene, "res://scenes/demo.tscn")
	if err:
		printerr("Scene saving failed")
