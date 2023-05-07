extends Node3D

signal block_selected(block: Node)

var scene : Node3D
var running: bool = false
var mouse_pos_on_area: Vector3
var game_area_pointed: bool = false

@onready var save_scene_as_button: Button = %SaveSceneAsButton
@onready var save_scene_button: Button = %SaveSceneButton

func _ready() -> void:
	%RunStopButton.modulate = Color.GREEN
	$PythonBridge.activate = true

func init_scene():
	scene = Node3D.new()
	scene.name = &"Scene"
	add_child(scene)

func new_scene(environment_path: String) -> void:
	delete_scene()
	init_scene()
	var environment = ResourceLoader.load(environment_path).instantiate()
	scene.add_child(environment)
	connect_pickable()
	%RunStopButton.button_pressed = false
	save_scene_as_button.disabled = false
	save_scene_button.disabled = true
	
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

func connect_editable():
	var nodes = get_tree().get_nodes_in_group("EDITABLE")
#	print(nodes)
	for node in nodes:
		if not node.is_connected("input_event", _on_editable_block_input_event):
			node.input_event.connect(_on_editable_block_input_event.bind(node))
		if not node.is_connected("mouse_entered", _on_editable_mouse_entered):
			node.mouse_entered.connect(_on_editable_mouse_entered)
		if not node.is_connected("mouse_exited", _on_editable_mouse_exited):
			node.mouse_exited.connect(_on_editable_mouse_exited)

func save_scene(path: String):
	assert(scene != null)
	# Take all blocks added in game scene for apply owner
	var items = scene.get_children()
	for item in items:
		item.owner = scene
		if %PositionSavedCheck.button_pressed:
			item.set_meta("transform", item.get_child(0).transform)
		for child in item.get_children():
			if child.name == "PythonBridge":
				item.set_meta("python_bridge_activate", child.activate)
				item.set_meta("python_bridge_port", child.port)
				break
	if not path.ends_with(".tscn"):
		path = path + ".tscn"
	var scene_packed := PackedScene.new()
	scene_packed.pack(scene)
	
	var err = ResourceSaver.save(scene_packed, path)
	if err:
		printerr("Scene saving failed")
	else:
		save_scene_button.disabled = false

func load_scene(path):
	if path == "":
		return
	delete_scene()
	var res = ResourceLoader.load(path)
#	print(res)
	if res == null:
		return
	scene = res.instantiate()
	add_child(scene)
	for item in scene.get_children():
		var transform_saved = item.get_meta("transform", Transform3D())
		if transform_saved != Transform3D():
			item.get_child(0).transform = transform_saved
		freeze_item(item, true)
		for child in item.get_children():
			if child.name == "PythonBridge":
				child.port = item.get_meta("python_bridge_port", 4242)
				child.activate = item.get_meta("python_bridge_activate", false)
				break
	connect_pickable()
	connect_editable()
	%RunStopButton.button_pressed = false
	save_scene_as_button.disabled = false
	save_scene_button.disabled = false
	
func delete_scene():
	var scene_node = get_node_or_null("Scene")
	if scene_node == null:
		return
	assert(scene_node!=null)
	for node in scene_node.get_children():
		scene_node.remove_child(node)
		node.queue_free()
	remove_child(scene_node)
	scene_node.queue_free()
	save_scene_as_button.disabled = true
	
func freeze_item(node, frozen):
	node.set_physics_process(not frozen)
	freeze_children(node, frozen)

func freeze_children(node, frozen):
	if node is RigidBody3D:
		node.freeze = frozen
#		set_physics_process(not frozen)
	for child in node.get_children():
		freeze_children(child, frozen)
	
func _on_run_stop_button_toggled(button_pressed: bool) -> void:
	if scene == null:
		return
	%ObjectInspector.visible = not button_pressed
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
		block_selected.emit(null)
		for node in scene.get_children():
			freeze_item(node, true)

func _on_reset_button_pressed():
	load_scene(owner.current_filename)

func _on_ground_input_event(_camera, event: InputEvent, mouse_position, _normal, _shape_idx):
#	print(mouse_position)
	mouse_pos_on_area = mouse_position
	if event.is_action_pressed("EDIT"):
#		print("EDIT")
		block_selected.emit(null)

func _on_ground_mouse_entered():
#	print("mouse_entered")
	game_area_pointed = true

func _on_ground_mouse_exited():
	game_area_pointed = false

func _on_editable_block_input_event(_camera, event: InputEvent, _mouse_position, _normal, _shape_idx, node):
	if event.is_action_pressed("EDIT"):
#		print(node)
		block_selected.emit(node)

func _on_editable_mouse_entered():
	owner.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
func _on_editable_mouse_exited():
	owner.mouse_default_cursor_shape = Control.CURSOR_ARROW
