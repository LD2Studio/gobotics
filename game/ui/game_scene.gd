extends Node3D

signal focused_block(block: Node)

var game_level := Node3D.new()
var coord3D: Node3D

func _ready() -> void:
	game_level.name = "GameLevel"
	add_child(game_level)
	var gaming_table = load("res://game/blocks/robotics_cup/gaming_table.tscn").instantiate()
	add_child(gaming_table)
	coord3D = gaming_table.get_node("Coord3D")
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var blocks = get_tree().get_nodes_in_group("BLOCKS")
		for block in blocks:
			if block.focused:
				emit_signal("focused_block", block)
				return
		emit_signal("focused_block", null)

func save_scene(path: String):
	assert(game_level.is_inside_tree())
	# Take all blocks added in game scene for apply owner
	var blocks = get_tree().get_nodes_in_group("BLOCKS")
#	print_debug("Nodes in BLOCKS group: ", blocks)
	for block in blocks:
		block.owner = game_level
	if not path.ends_with(".tscn"):
		path = path + ".tscn"
	var scene := PackedScene.new()
	scene.pack(game_level)
	
	var err = ResourceSaver.save(scene, path)
	if err:
		printerr("Scene saving failed")

func load_scene(path):
	remove_child(game_level)
	game_level.queue_free()
	game_level = load(path).instantiate()
	add_child(game_level)
	
func _on_run_button_pressed():
	for block in game_level.get_children():
		if block is RigidBody3D:
			block.freeze = false

func _on_stop_button_pressed():
	for block in game_level.get_children():
		if block is RigidBody3D:
			block.freeze = true

func _on_reset_button_pressed():
	load_scene(owner.current_filename)

