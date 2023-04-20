extends Node3D

signal focused_block(block: Node)

var gaming_table : Node3D
var scene : Node3D
var running: bool = false

func _ready() -> void:
	%FloorCollision.disabled = true
	%RunStopButton.modulate = Color.GREEN
	init_scene()
	
func init_scene():
	scene = Node3D.new()
	scene.name = &"Scene"
	add_child(scene)
	
	gaming_table = load("res://game/blocks/robotics_cup/gaming_table.tscn").instantiate()
	scene.add_child(gaming_table)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var blocks = get_tree().get_nodes_in_group("BLOCKS")
		for block in blocks:
			if block.get("focused"):
				emit_signal("focused_block", block)
				return
		emit_signal("focused_block", null)

func save_scene(path: String):
	assert(scene != null)
	# Take all blocks added in game scene for apply owner
	var items = scene.get_children()
	for item in items:
		item.owner = scene
	if not path.ends_with(".tscn"):
		path = path + ".tscn"
	var scene_packed := PackedScene.new()
	scene_packed.pack(scene)
	
	var err = ResourceSaver.save(scene_packed, path)
	if err:
		printerr("Scene saving failed")

func load_scene(path):
	if path == "":
		return
	var scene_node = get_node("Scene")
	assert(scene_node!=null)
	for node in scene_node.get_children():
		scene_node.remove_child(node)
		node.queue_free()
	remove_child(scene_node)
	scene_node.queue_free()
		
	scene = ResourceLoader.load(path).instantiate()
	add_child(scene)
	
func _on_run_stop_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		running = true
		%RunStopButton.text = "STOP"
		%RunStopButton.modulate = Color.RED
		%FloorCollision.disabled = false

		var robots = get_tree().get_nodes_in_group("ROBOTS")
		for robot in robots:
			robot.frozen = false
	else:
		running = false
		%RunStopButton.text = "RUN"
		%RunStopButton.modulate = Color.GREEN
		%FloorCollision.disabled = true
#		gaming_table.process_mode = Node.PROCESS_MODE_DISABLED
		var robots = get_tree().get_nodes_in_group("ROBOTS")
		for robot in robots:
			robot.frozen = true

func _on_reset_button_pressed():
	load_scene(owner.current_filename)



