extends Node3D

signal focused_block(block: Node)

var scene : Node3D
var running: bool = false
var mouse_pos_on_area: Vector3
var game_area_pointed: bool = false

func _ready() -> void:
	%RunStopButton.modulate = Color.GREEN
	init_scene()
	
func init_scene():
	scene = Node3D.new()
	scene.name = &"Scene"
	add_child(scene)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var blocks = get_tree().get_nodes_in_group("BLOCKS")
		for block in blocks:
			if block.get("focused"):
				emit_signal("focused_block", block)
				return
		emit_signal("focused_block", null)

func new_scene(environment_path: String) -> void:
#	print(environment_path)
	delete_scene()
	init_scene()
	var environment = ResourceLoader.load(environment_path).instantiate()
	scene.add_child(environment)
#	call_deferred("connect_pickable")
	connect_pickable()
	%RunStopButton.button_pressed = false
	
func connect_pickable():
	var nodes = get_tree().get_nodes_in_group("PICKABLE")
#	print(nodes)
	for node in nodes:
		if not node.is_connected("mouse_entered", _on_ground_mouse_entered):
			node.mouse_entered.connect(_on_ground_mouse_entered)
		if not node.is_connected("mouse_exited", _on_ground_mouse_exited):
			node.mouse_exited.connect(_on_ground_mouse_exited)
		if not node.is_connected("input_event", _on_ground_input_event):
			node.input_event.connect(_on_ground_input_event)
	

func save_scene(path: String):
	assert(scene != null)
	# Take all blocks added in game scene for apply owner
	var items = scene.get_children()
	for item in items:
		item.owner = scene
		if %PositionSavedCheck.button_pressed:
			item.set_meta("transform", item.get_child(0).transform)
			
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
	delete_scene()
	
	scene = ResourceLoader.load(path).instantiate()
	add_child(scene)
	for node in scene.get_children():
		var transform_saved = node.get_meta("transform", Transform3D())
		if  transform_saved != Transform3D():
			node.get_child(0).transform = transform_saved
		freeze_item(node, true)
	connect_pickable()
	%RunStopButton.button_pressed = false
	
func delete_scene():
	var scene_node = get_node("Scene")
	assert(scene_node!=null)
	for node in scene_node.get_children():
		scene_node.remove_child(node)
		node.queue_free()
	remove_child(scene_node)
	scene_node.queue_free()
	
func freeze_item(node, frozen):
	freeze_children(node, frozen)

func freeze_children(node, frozen):
	if node is RigidBody3D:
		node.freeze = frozen
	for child in node.get_children():
		freeze_children(child, frozen)
	
func _on_run_stop_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		running = true
		%RunStopButton.text = "STOP"
		%RunStopButton.modulate = Color.RED
		for node in scene.get_children():
			freeze_item(node, false)
	else:
		running = false
		%RunStopButton.text = "RUN"
		%RunStopButton.modulate = Color.GREEN
		for node in scene.get_children():
			freeze_item(node, true)

func _on_reset_button_pressed():
	load_scene(owner.current_filename)

func _on_ground_input_event(_camera, _event, mouse_position, _normal, _shape_idx):
#	print(mouse_position)
	mouse_pos_on_area = mouse_position

func _on_ground_mouse_entered():
#	print("mouse_entered")
	game_area_pointed = true

func _on_ground_mouse_exited():
	game_area_pointed = false

