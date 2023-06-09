extends Node3D

var scene : Node3D
var running: bool = false
var item_selected: Node3D
var mouse_pos_on_area: Vector3
var game_area_pointed: bool = false

#var python_threads: Array

@onready var game = owner
@onready var save_scene_as_button: Button = %SaveSceneAsButton
@onready var save_scene_button: Button = %SaveSceneButton
@onready var python = PythonBridge.new(4242)
@onready var terminal_output = %TerminalOutput
@onready var object_inspector: PanelContainer = %ObjectInspector
@onready var udp_port_number: SpinBox = %UDPPortNumber

func _ready() -> void:
	%RunStopButton.modulate = Color.GREEN
	python.activate = true
	add_child(python)
	
func _input(event: InputEvent) -> void:
#	print("[game scene]: ", event.as_text())
	if event.is_action_pressed("DELETE"):
#		print(selected_block)
		if item_selected == null: return
		%ConfirmDeleteDialog.dialog_text = "Delete %s object ?" % [item_selected.name]
		%ConfirmDeleteDialog.popup_centered()
		
func _process(_delta: float) -> void:
	%FPSLabel.text = "FPS: %.1f" % [Engine.get_frames_per_second()]
		
func init_scene():
	scene = Node3D.new()
	scene.name = &"Scene"
	add_child(scene)

func new_scene(environment_path: String) -> void:
#	print("environment path: ", environment_path)
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
	var nodes = get_tree().get_nodes_in_group("SELECT")
#	print(nodes)
	for node in nodes:
		if not node.is_connected("input_event", _on_editable_block_input_event):
			node.input_event.connect(_on_editable_block_input_event.bind(node))
		if not node.is_connected("mouse_entered", _on_editable_mouse_entered):
			node.mouse_entered.connect(_on_editable_mouse_entered)
		if not node.is_connected("mouse_exited", _on_editable_mouse_exited):
			node.mouse_exited.connect(_on_editable_mouse_exited)
			
func show_part_parameters(asset_selected: Node3D):
#	print_debug(asset_selected)
	item_selected = asset_selected
	if not asset_selected.get_child(0) is RigidBody3D: return
	var base_rigid = asset_selected.get_child(0)
	
	object_inspector.visible = true
#	# Update data in inspector
	%InspectorPartName.text = item_selected.name
	%X_pos.value = base_rigid.global_position.x / 10.0
	%Y_pos.value = base_rigid.global_position.z * -1 / 10.0
	%Z_pos.value = base_rigid.global_position.y / 10.0
	%Z_rot.value = base_rigid.rotation_degrees.y
	
	if running:
		%X_pos.editable = false
		%Y_pos.editable = false
		%Z_pos.editable = false
		%Z_rot.editable = false
	else:
		%X_pos.editable = true
		%Y_pos.editable = true
		%Z_pos.editable = true
		%Z_rot.editable = true
		
#	var script: GDScript = item_selected.get_script()
#	print_debug(script.get_script_property_list())
	"""
	PROPERTY_USAGE_SCRIPT_VARIABLE = 4096
	The property is a script variable which should be serialized and saved in the scene file.
	PROPERTY_USAGE_STORAGE = 2
	The property is serialized and saved in the scene file (default).
	PROPERTY_USAGE_EDITOR = 4
	The property is shown in the EditorInspector (default).
	"""
	
	if item_selected.is_in_group("ROBOTS"):
		if item_selected.get("control"):
			%KeysControlContainer.visible = true
			%KeysControlCheck.set_pressed_no_signal(item_selected.control.manual)
		else:
			%KeysControlContainer.visible = false
	else:
		%KeysControlContainer.visible = false

	if item_selected.is_in_group("PYTHON"):
		%PythonBridgeContainer.visible = true
		%PythonRemoteButton.set_pressed_no_signal(item_selected.python.activate)
		%UDPPortNumber.value = item_selected.python.port
		%BuiltinScriptCheckBox.button_pressed = item_selected.builtin
	else:
		%PythonBridgeContainer.visible = false

func hide_part_parameters():
	object_inspector.visible = false

func save_scene(path: String):
	var scene_filename = path
#	print("scene filename: ", scene_filename)
	# Take all blocks added in game scene for apply owner
	var items = scene.get_children()
	var scene_objects = {
		assets=[], environment="",
	}
	
	if true:
		for item in items:
#			print("[GAME SCENE] item: ", item)
			if item.is_in_group("ASSETS"):
				var gl_transform: Transform3D = item.get_child(0).global_transform
				
				var asset_transform = {
					origin=[gl_transform.origin.x, gl_transform.origin.y, gl_transform.origin.z],
					basis=[
						gl_transform.basis.x.x, gl_transform.basis.x.y, gl_transform.basis.x.z,
						gl_transform.basis.y.x, gl_transform.basis.y.y, gl_transform.basis.y.z,
						gl_transform.basis.z.x, gl_transform.basis.z.y, gl_transform.basis.z.z],
				}
				scene_objects.assets.append({
						name=item.get_meta("asset_name"),
						string_name=item.name,
						transform=asset_transform,
						})
			if item.is_in_group("ENVIRONMENT"):
#				print("environment : ", item.name)
				scene_objects.environment = {
					name=item.name,
					}
		var scene_json = JSON.stringify(scene_objects, "\t", false)
#		print("scene JSON: ", scene_json)
		
		var file = FileAccess.open(scene_filename, FileAccess.WRITE)
		file.store_string(scene_json)
		
		save_scene_button.disabled = false

	else:
		for item in items:
			item.owner = scene
			if item.is_in_group("ROBOTS"):
				# print("%s is in ROBOT group" % [item])
				if item.get("control"):
					item.set_meta("manual_control", item.control.manual)
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
	var scene_filename = path
#	print("Load scene filename: ", scene_filename)
	if scene_filename == "": return
	if true:
		var json = JSON.new()
		var json_scene = FileAccess.get_file_as_string(scene_filename)
		var error = json.parse(json_scene)
		if error != OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_scene, " at line ", json.get_error_line())
			return
			
		var scene_objects = json.data
#		print("scene_objects: ", scene_objects)
		
		delete_scene()
		init_scene()
		if "name" in scene_objects.environment:
			var env_filename = game.database.get_environment(scene_objects.environment.name)
			var environment = ResourceLoader.load(env_filename).instantiate()
			scene.add_child(environment)
			connect_pickable()
		
		for asset in scene_objects.assets:
			if "name" in asset:
				var asset_filename = game.database.get_asset_scene(asset.name)
				if asset_filename == null:
					printerr("Asset %s not available!" % [asset.name])
					continue
				var asset_node : Node3D = ResourceLoader.load(asset_filename).instantiate()
				if "transform" in asset:
					var origin = Vector3(asset.transform.origin[0], asset.transform.origin[1], asset.transform.origin[2])
					var new_basis = Basis(
						Vector3(asset.transform.basis[0], asset.transform.basis[1], asset.transform.basis[2]),
						Vector3(asset.transform.basis[3], asset.transform.basis[4], asset.transform.basis[5]),
						Vector3(asset.transform.basis[6], asset.transform.basis[7], asset.transform.basis[8]))
					var new_transform = Transform3D(new_basis, origin)
					asset_node.get_child(0).global_transform = new_transform
				if "string_name" in asset:
					asset_node.name = asset.string_name
				freeze_item(asset_node, true)
				scene.add_child(asset_node)
				connect_editable()

	else:
		var res = ResourceLoader.load(path)
		if res == null:
			return
		scene = res.instantiate()
		add_child(scene)
		## Get info from each items
		for item in scene.get_children():
			var transform_saved = item.get_meta("transform", Transform3D())
			if transform_saved != Transform3D():
				item.get_child(0).global_transform = transform_saved
			freeze_item(item, true)
			var part_name = item.get_node_or_null("%PartName")
			if part_name:
				part_name.text = item.name
			if item.is_in_group("ROBOTS"):
				if item.get("control"):
					item.control.manual = item.get_meta("manual_control", true)
			for child in item.get_children():
				if child.is_in_group("PYTHON"):
					child.port = item.get_meta("python_bridge_port", 4242)
					child.activate = item.get_meta("python_bridge_activate", false)
					item.python_script_finished.connect(_on_python_script_finished)
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
	
func freeze_item(item, frozen):
	item.set_physics_process(not frozen)
	freeze_children(item, frozen)

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
	
func is_running() -> bool:
	return running
	
func print_on_terminal(text: String):
	terminal_output.text += "%s\n" % text
	
## Slot functions

func _on_run_stop_button_toggled(button_pressed: bool) -> void:
#	print_debug(button_pressed)
	if scene == null:
		return
	%ObjectInspector.visible = not button_pressed
	if button_pressed:
		running = true
		%RunStopButton.text = "STOP"
		%RunStopButton.modulate = Color.RED
		for item in scene.get_children():
			freeze_item(item, false)
			if item.is_in_group("PYTHON"):
				item.run()
	else:
		running = false
		%RunStopButton.text = "RUN"
		%RunStopButton.modulate = Color.GREEN
		hide_part_parameters()
		for item in scene.get_children():
			freeze_item(item, true)
			if item.is_in_group("PYTHON"):
				item.stop()

func _on_reset_button_pressed():
	load_scene(owner.current_filename)

func _on_ground_input_event(_camera, event: InputEvent, mouse_position, _normal, _shape_idx):
	mouse_pos_on_area = mouse_position
	if event.is_action_pressed("EDIT"):
		hide_part_parameters()

func _on_ground_mouse_entered():
	game_area_pointed = true

func _on_ground_mouse_exited():
	game_area_pointed = false

func _on_editable_block_input_event(_camera, event: InputEvent, _mouse_position, _normal, _shape_idx, node):
	if event.is_action_pressed("EDIT"):
		var asset_selected: Node3D = node.owner
		if asset_selected.is_in_group("ASSETS"):
			show_part_parameters(asset_selected)

func _on_editable_mouse_entered():
	owner.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
func _on_editable_mouse_exited():
	owner.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_x_pos_value_changed(value: float) -> void:
	if item_selected == null:
		return
	var base_link = item_selected.get_child(0)
	base_link.global_position.x = value * 10.0

func _on_y_pos_value_changed(value: float) -> void:
	if item_selected == null:
		return
	var base_link = item_selected.get_child(0)
	base_link.global_position.z = -value * 10.0

func _on_z_pos_value_changed(value: float) -> void:
	if item_selected == null:
		return
	var base_link = item_selected.get_child(0)
	base_link.global_position.y = value * 10.0

func _on_z_rot_value_changed(value: float) -> void:
	if item_selected == null:
		return
	var base_link = item_selected.get_child(0)
	base_link.rotation_degrees.y = value

func _on_python_remote_button_toggled(button_pressed: bool) -> void:
	if item_selected == null: return
	if item_selected.is_in_group("PYTHON"):
		item_selected.python.activate = button_pressed
		item_selected.python.port = int(udp_port_number.value)

func _on_udp_port_number_value_changed(value: float) -> void:
	if item_selected == null: return
	if item_selected.is_in_group("PYTHON"):
		item_selected.python.port = int(value)
		
func _on_open_script_button_pressed() -> void:
	if item_selected == null: return
	if item_selected.is_in_group("PYTHON"):
		%SourceCodeEdit.text = item_selected.source_code
		%ScriptDialog.popup_centered()

func _on_keys_control_check_toggled(button_pressed: bool) -> void:
	if item_selected == null: return
	if item_selected.is_in_group("ROBOTS"):
		item_selected.control.manual = button_pressed

func _on_confirm_delete_dialog_confirmed() -> void:
	if scene:
		scene.remove_child(item_selected)
		item_selected.queue_free()

func _on_script_dialog_confirmed() -> void:
	if item_selected == null: return
	item_selected.source_code = %SourceCodeEdit.text
	
func _on_python_script_finished(new_text: String):
#	print(new_text)
	%TerminalOutput.text += new_text

func _on_builtin_script_check_box_toggled(button_pressed: bool) -> void:
	if item_selected == null: return
	item_selected.builtin = button_pressed

func _on_frame_check_box_toggled(button_pressed):
	for node in get_tree().get_nodes_in_group("FRAME"):
		node.visible = button_pressed
