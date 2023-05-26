extends Node3D

var scene : Node3D
var running: bool = false
var selected_part: Node3D
var mouse_pos_on_area: Vector3
var game_area_pointed: bool = false

@onready var save_scene_as_button: Button = %SaveSceneAsButton
@onready var save_scene_button: Button = %SaveSceneButton
@onready var python = PythonBridge.new(4242)
@onready var terminal_output = %TerminalOutput
@onready var object_inspector: PanelContainer = %ObjectInspector

func _ready() -> void:
	%RunStopButton.modulate = Color.GREEN
	python.activate = true
	add_child(python)

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
			
func show_part_parameters(node: Node):
	selected_part = node.owner if node != null else null
#	print("selected block: ", selected_part)
	if running:
		return
	object_inspector.visible = true
#	# Update data in inspector
	%InspectorPartName.text = selected_part.name
	%X_pos.value = node.global_position.x / 10.0
	%Y_pos.value = node.global_position.y / 10.0
	%Z_pos.value = node.global_position.z / 10.0
	%Z_rot.value = node.rotation_degrees.y
	
	if selected_part.is_in_group("ROBOT"):
		%KeysControlContainer.visible = true
		%KeysControlCheck.set_pressed_no_signal(selected_part.robot.manual_control)
	else:
		%KeysControlContainer.visible = false

	if selected_part.is_in_group("PYTHON"):
		%PythonBridgeContainer.visible = true
		%PythonRemoteButton.set_pressed_no_signal(selected_part.python.activate)
		%UDPPortNumber.value = selected_part.python.port
	else:
		%PythonBridgeContainer.visible = false

func hide_part_parameters():
	object_inspector.visible = false

func save_scene(path: String):
	assert(scene != null)
	# Take all blocks added in game scene for apply owner
	var items = scene.get_children()
	for item in items:
#		print("item: ", item)
		item.owner = scene
		if %PositionSavedCheck.button_pressed:
			item.set_meta("transform", item.get_child(0).transform)
		if item.is_in_group("ROBOT"):
			print("%s is in ROBOT group" % [item])
			item.set_meta("manual_control", item.robot.manual_control)
		for child in item.get_children():
			if child.is_in_group("PYTHON"):
				item.set_meta("python_bridge_activate", child.activate)
				item.set_meta("python_bridge_port", child.port)
			
				
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
	if path == "" or path == "noname.tscn":
		return
	delete_scene()
	var res = ResourceLoader.load(path)
#	print(res)
	if res == null:
		return
	scene = res.instantiate()
	add_child(scene)
#	print(scene.get_children())
	
	for item in scene.get_children():
		var transform_saved = item.get_meta("transform", Transform3D())
		if transform_saved != Transform3D():
			item.get_child(0).transform = transform_saved
		freeze_item(item, true)
		var part_name = item.get_node_or_null("%PartName")
		if part_name:
			part_name.text = item.name
		for child in item.get_children():
			if child.is_in_group("PYTHON"):
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

## Python functions

func run():
	_on_run_stop_button_toggled(true)

func stop():
	_on_run_stop_button_toggled(false)

func reload():
	_on_reset_button_pressed()
	
func print_on_terminal(text: String):
	terminal_output.text += "%s\n" % text
	
## Slot functions

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
		hide_part_parameters()
		for node in scene.get_children():
			freeze_item(node, true)

func _on_reset_button_pressed():
	load_scene(owner.current_filename)

func _on_ground_input_event(_camera, event: InputEvent, mouse_position, _normal, _shape_idx):
#	print(mouse_position)
	mouse_pos_on_area = mouse_position
	if event.is_action_pressed("EDIT"):
#		print("EDIT")
		hide_part_parameters()

func _on_ground_mouse_entered():
#	print("mouse_entered")
	game_area_pointed = true

func _on_ground_mouse_exited():
	game_area_pointed = false

func _on_editable_block_input_event(_camera, event: InputEvent, _mouse_position, _normal, _shape_idx, node):
	if event.is_action_pressed("EDIT"):
#		print(node)
		show_part_parameters(node)

func _on_editable_mouse_entered():
	owner.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
func _on_editable_mouse_exited():
	owner.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_x_pos_value_changed(value: float) -> void:
	if selected_part == null:
		return
	var rigid_body = selected_part.get_child(0)
	if rigid_body is RigidBody3D:
		rigid_body.global_position.x = value*10.0

func _on_y_pos_value_changed(value: float) -> void:
	if selected_part == null:
		return
	var rigid_body = selected_part.get_child(0)
	if rigid_body is RigidBody3D:
		rigid_body.global_position.y = value*10.0

func _on_z_pos_value_changed(value: float) -> void:
	if selected_part == null:
		return
	var rigid_body = selected_part.get_child(0)
	if rigid_body is RigidBody3D:
		rigid_body.global_position.z = value*10.0

func _on_z_rot_value_changed(value: float) -> void:
	if selected_part == null:
		return
	var rigid_body = selected_part.get_child(0)
	if rigid_body is RigidBody3D:
		rigid_body.rotation_degrees.y = value

func _on_python_remote_button_toggled(button_pressed: bool) -> void:
	if selected_part == null: return
	if selected_part.is_in_group("PYTHON"):
		selected_part.python.activate = button_pressed

func _on_udp_port_number_value_changed(value: float) -> void:
	if selected_part == null: return
	if selected_part.is_in_group("PYTHON"):
		selected_part.python.port = int(value)

func _on_keys_control_check_toggled(button_pressed: bool) -> void:
	if selected_part == null: return
	if selected_part.is_in_group("ROBOT"):
		selected_part.robot.manual_control = button_pressed
