extends Node3D

signal focused_block(block: Node)

var game_level := Node3D.new()
var gaming_table : Node3D

var running: bool = false

func _ready() -> void:
	game_level.name = "GameLevel"
	%FloorCollision.disabled = true
	add_child(game_level)
	gaming_table = load("res://game/blocks/robotics_cup/gaming_table.tscn").instantiate()
	game_level.add_child(gaming_table)
	gaming_table.process_mode = Node.PROCESS_MODE_DISABLED
	%RunStopButton.modulate = Color.GREEN


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
	assert(get_tree().get_nodes_in_group("TABLE"))
	var table = get_tree().get_nodes_in_group("TABLE")[0]
	table.owner = game_level
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
	if path == "":
		return
	remove_child(game_level)
	game_level.queue_free()
	game_level = load(path).instantiate()
	add_child(game_level)
	gaming_table = game_level.get_node("GamingTable")
	
func _on_run_stop_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		running = true
		%RunStopButton.text = "STOP"
		%RunStopButton.modulate = Color.RED
		%FloorCollision.disabled = false
		gaming_table.process_mode = Node.PROCESS_MODE_INHERIT
		var robots = get_tree().get_nodes_in_group("ROBOTS")
		for robot in robots:
			robot.frozen = false
		var sets = get_tree().get_nodes_in_group("SETS")
		for set in sets:
			set.freeze = false
	else:
		running = false
		%RunStopButton.text = "RUN"
		%RunStopButton.modulate = Color.GREEN
		%FloorCollision.disabled = true
		gaming_table.process_mode = Node.PROCESS_MODE_DISABLED
		var robots = get_tree().get_nodes_in_group("ROBOTS")
		for robot in robots:
			robot.frozen = true
		var sets = get_tree().get_nodes_in_group("SETS")
		for set in sets:
			set.freeze = true

func _on_reset_button_pressed():
	load_scene(owner.current_filename)



