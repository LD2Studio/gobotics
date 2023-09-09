extends Node3D

var scene : Node3D
var running: bool = false
var asset_selected: Node3D
var mouse_pos_on_area: Vector3
var game_area_pointed: bool = false
var asset_focused : Node3D = null

var _cams : Array

@onready var game = owner
@onready var save_scene_as_button: Button = %SaveSceneAsButton
@onready var save_scene_button: Button = %SaveSceneButton
@onready var python = PythonBridge.new(self, 4242)
@onready var terminal_output = %TerminalOutput
@onready var object_inspector: PanelContainer = %ObjectInspector
@onready var udp_port_number: SpinBox = %UDPPortNumber
@onready var camera_view_button = %CameraViewButton

func _ready() -> void:
	%RunStopButton.modulate = Color.GREEN
	update_camera_view_menu()
	python.name = &"AppPython"
	python.activate = true
	add_child(python)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DELETE"):
		if asset_selected == null: return
		%ConfirmDeleteDialog.dialog_text = "Delete %s object ?" % [asset_selected.name]
		%ConfirmDeleteDialog.popup_centered()
		
#	if asset_focused and event is InputEventMouseMotion:
#		get_viewport().set_input_as_handled()
#		print("asset position: ", asset_focused.get_child(0).global_position)
		
func _process(_delta: float) -> void:
	%FPSLabel.text = "FPS: %.1f" % [Engine.get_frames_per_second()]
#	print("game scene _process")
#	Node.print_orphan_nodes()
	
func new_scene(environment_path: String) -> void:
#	print("Env path: ", environment_path)
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
			
func update_camera_view_menu():
	var cam_popup: PopupMenu = camera_view_button.get_popup()
	if not cam_popup.index_pressed.is_connected(_camera_view_selected):
		cam_popup.index_pressed.connect(_camera_view_selected)
	cam_popup.clear()
	_cams.clear()
	var builtin_cams = get_tree().get_nodes_in_group("BUILTIN_CAMERA")
	for cam in builtin_cams:
		_cams.push_back(cam)
		cam_popup.add_check_item(cam.name)
	
	var embed_cams = get_tree().get_nodes_in_group("CAMERA")
	if not embed_cams.is_empty():
		cam_popup.add_separator("Embedded Cameras")
		_cams.push_back("Embedded Cameras")
	for cam in embed_cams:
		_cams.push_back(cam)
		cam_popup.add_check_item(cam.owner.name)
	_camera_view_selected(0)
		
func _camera_view_selected(idx: int):
	var cam_popup: PopupMenu = camera_view_button.get_popup()
	for i in cam_popup.item_count:
		if idx == i:
			cam_popup.set_item_checked(i, true)
		else:
			cam_popup.set_item_checked(i, false)
	_cams[idx].current = true
			
func show_asset_parameters(asset: Node3D):
	asset_selected = asset
	var base_link: RigidBody3D
	for child in asset_selected.get_children():
		if child is RigidBody3D:
			base_link = child
			break
	if base_link == null: return

	object_inspector.visible = true
#	# Update data in inspector
	%InspectorPartName.text = asset_selected.name
	%X_pos.value = base_link.global_position.x / 10.0
	%Y_pos.value = -base_link.global_position.z / 10.0
	%Z_pos.value = base_link.global_position.y / 10.0
	%Z_rot.value = base_link.rotation_degrees.y
	
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
	# Remove joint parameters
	for child in %JointsContainer.get_children():
		%JointsContainer.remove_child(child)
		child.queue_free()
		
	var all_continuous_joints = get_tree().get_nodes_in_group("CONTINUOUS")
	var continuous_joints = all_continuous_joints.filter(func(joint): return asset_selected.is_ancestor_of(joint))
#	print("Continuous joints: ", continuous_joints)
	if not continuous_joints.is_empty():
		for joint in continuous_joints:
			var velocity_label = Label.new()
			velocity_label.text = joint.name
			velocity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			%JointsContainer.add_child(velocity_label)
			var velocity_edit = PropertySlider.new()
			%JointsContainer.add_child(velocity_edit)
			velocity_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			velocity_edit.min_value = -joint.LIMIT_VELOCITY
			velocity_edit.max_value = joint.LIMIT_VELOCITY
			velocity_edit.step = joint.LIMIT_VELOCITY / 10.0
#			velocity_edit.tick_count = 3
			velocity_edit.value = joint.target_velocity
			velocity_edit.value_changed.connect(joint._target_velocity_changed)
			
	var all_revolute_joints = get_tree().get_nodes_in_group("REVOLUTE")
	var revolute_joints = all_revolute_joints.filter(func(joint): return asset_selected.is_ancestor_of(joint))
#	print("Revolute joints: ", revolute_joints)
	if not revolute_joints.is_empty():
		for joint in revolute_joints:
			var angle_label = Label.new()
			angle_label.text = joint.name
			angle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			%JointsContainer.add_child(angle_label)
			var angle_edit = PropertySlider.new()
			%JointsContainer.add_child(angle_edit)
			angle_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			angle_edit.min_value = rad_to_deg(-joint.limit_upper)
			angle_edit.max_value = rad_to_deg(-joint.limit_lower)
			angle_edit.value = joint.target_angle
			angle_edit.value_changed.connect(joint._target_angle_changed)
			
	var all_prismatic_joints = get_tree().get_nodes_in_group("PRISMATIC")
	var primatic_joints = all_prismatic_joints.filter(func(joint): return asset_selected.is_ancestor_of(joint))
#	print("Prismatic joints: ", primatic_joints)
	if not primatic_joints.is_empty():
		for joint in primatic_joints:
			var angle_label = Label.new()
			angle_label.text = joint.name
			angle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			%JointsContainer.add_child(angle_label)
			var angle_edit = PropertySlider.new()
			%JointsContainer.add_child(angle_edit)
			angle_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			angle_edit.min_value = -joint.limit_upper
			angle_edit.max_value = -joint.limit_lower
			angle_edit.step = (-joint.limit_upper + joint.limit_lower)/10.0
			angle_edit.value = joint.target_angle
			angle_edit.value_changed.connect(joint._target_angle_changed)
		
	if asset_selected.is_in_group("ROBOTS"):
		if asset_selected.get("control"):
			%KeysControlContainer.visible = true
			%KeysControlCheck.set_pressed_no_signal(asset_selected.control.manual)
		else:
			%KeysControlContainer.visible = false
		%PythonBridgeContainer.visible = true
		%PythonRemoteButton.set_pressed_no_signal(asset_selected.control.python.activate)
		%UDPPortNumber.value = asset_selected.control.python.port
	else:
		%KeysControlContainer.visible = false
		%PythonBridgeContainer.visible = false

func hide_asset_parameters():
	object_inspector.visible = false

func save_scene(path: String):
	var scene_filename = path

	# Take all blocks added in game scene for apply owner
	var items = scene.get_children()
	var scene_objects = {
		assets=[], environment={},
	}
	
	for item in items:
		if item.is_in_group("ASSETS"):
			var base_link: RigidBody3D
			for child in item.get_children():
				if child is RigidBody3D:
					base_link = child
					break
			if base_link == null: return null
			var gl_transform: Transform3D = base_link.global_transform
			
			var asset_transform = {
				origin=[gl_transform.origin.x, gl_transform.origin.y, gl_transform.origin.z],
				basis=[
					gl_transform.basis.x.x, gl_transform.basis.x.y, gl_transform.basis.x.z,
					gl_transform.basis.y.x, gl_transform.basis.y.y, gl_transform.basis.y.z,
					gl_transform.basis.z.x, gl_transform.basis.z.y, gl_transform.basis.z.z],
			}
			scene_objects.assets.append({
					fullname=item.get_meta("fullname"),
					string_name=item.name,
					transform=asset_transform,
					})
		if item.is_in_group("ENVIRONMENT"):
#			print("environment : ", item.name)
			if item.is_in_group("BUILTIN"):
				scene_objects.environment = {
					fullname="%s.builtin" % item.name,
					}
			else:
				scene_objects.environment = {
					fullname=item.get_meta("fullname"),
					}
	var scene_json = JSON.stringify(scene_objects, "\t", false)
#		print("scene JSON: ", scene_json)
	
	var file = FileAccess.open(scene_filename, FileAccess.WRITE)
	file.store_string(scene_json)
	save_scene_button.disabled = false

func load_scene(path):
	var scene_filename = path
#	print("Load scene filename: ", scene_filename)
	if scene_filename == "": return
	var json = JSON.new()
	var json_scene = FileAccess.get_file_as_string(scene_filename)
	var error = json.parse(json_scene)
	if error != OK:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_scene, " at line ", json.get_error_line())
		return
		
	delete_scene()
	init_scene()
	
	var scene_objects = json.data
	var env_filename: String = ""
	if "fullname" in scene_objects.environment:
		env_filename = game.database.get_scene_from_fullname(scene_objects.environment.fullname)
	if env_filename:
		var environment = ResourceLoader.load(env_filename).instantiate()
		scene.add_child(environment)
	
	for asset in scene_objects.assets:
		if "fullname" in asset:
			var asset_filename = game.database.get_asset_scene(asset.fullname)
			if asset_filename == null:
				printerr("Asset %s not available!" % [asset.fullname])
				continue
			var asset_node : Node3D = ResourceLoader.load(asset_filename).instantiate()
			var base_link: RigidBody3D
			for child in asset_node.get_children():
				if child is RigidBody3D:
					base_link = child
					break
			if base_link == null: return null
			if "transform" in asset:
				var origin = Vector3(asset.transform.origin[0], asset.transform.origin[1], asset.transform.origin[2])
				var new_basis = Basis(
					Vector3(asset.transform.basis[0], asset.transform.basis[1], asset.transform.basis[2]),
					Vector3(asset.transform.basis[3], asset.transform.basis[4], asset.transform.basis[5]),
					Vector3(asset.transform.basis[6], asset.transform.basis[7], asset.transform.basis[8]))
				var new_transform = Transform3D(new_basis, origin)
				base_link.global_transform = new_transform
			if "string_name" in asset:
				asset_node.name = asset.string_name
			freeze_asset(asset_node, true)
			scene.add_child(asset_node)

	connect_pickable()
	connect_editable()
	update_camera_view_menu()
	%RunStopButton.button_pressed = false
	save_scene_as_button.disabled = false
	save_scene_button.disabled = false
	
func add_assets_to_scene():
	pass
	
func init_scene():
	scene = Node3D.new()
	scene.name = &"Scene"
	add_child(scene)
	
func delete_scene():
	var scene_node = get_node_or_null("Scene")
	if scene_node == null:
		return
	remove_child(scene_node)
	scene_node.free()
	save_scene_as_button.disabled = true
	
func freeze_asset(asset, frozen):
	asset.set_physics_process(not frozen)
	freeze_children(asset, frozen)

func freeze_children(node, frozen):
	if node.is_in_group("STATIC"):
		node.freeze = true
	elif node is RigidBody3D:
		node.freeze = frozen
#		set_physics_process(not frozen)
	for child in node.get_children():
		freeze_children(child, frozen)
		
## Helper functions

func get_base_link(asset: Node) -> RigidBody3D:
	for child in asset.get_children():
		if child is RigidBody3D:
			return child
	return null

## Python functions

func run():
	_on_run_stop_button_toggled(true)

func stop():
	_on_run_stop_button_toggled(false)

func reload():
	_on_reload_button_pressed()
	
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
		for asset in scene.get_children():
			freeze_asset(asset, false)
			if asset.is_in_group("PYTHON"):
				asset.run()
	else:
		running = false
		%RunStopButton.text = "RUN"
		%RunStopButton.modulate = Color.GREEN
		hide_asset_parameters()
		for item in scene.get_children():
			freeze_asset(item, true)
			if item.is_in_group("PYTHON"):
				item.stop()
				
func _on_reload_button_pressed():
	if owner.current_filename != "":
		load_scene(owner.current_filename)

func _on_ground_input_event(_camera, event: InputEvent, mouse_position, _normal, _shape_idx):
	mouse_pos_on_area = mouse_position
	if event.is_action_pressed("EDIT"):
		asset_focused = null
		hide_asset_parameters()

func _on_ground_mouse_entered():
	game_area_pointed = true

func _on_ground_mouse_exited():
	game_area_pointed = false

func _on_editable_block_input_event(_camera, event: InputEvent, _mouse_position, _normal, _shape_idx, node):
	if event.is_action_pressed("EDIT"):
		var asset: Node3D = node.owner
		asset_focused = asset
		show_asset_parameters(asset)

func _on_editable_mouse_entered():
	owner.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
func _on_editable_mouse_exited():
	owner.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_x_pos_value_changed(value: float) -> void:
	if asset_selected == null:
		return
	var base_link = get_base_link(asset_selected)
	base_link.global_position.x = value * 10.0

func _on_y_pos_value_changed(value: float) -> void:
	if asset_selected == null:
		return
	var base_link = get_base_link(asset_selected)
	base_link.global_position.z = -value * 10.0

func _on_z_pos_value_changed(value: float) -> void:
	if asset_selected == null:
		return
	var base_link = get_base_link(asset_selected)
	base_link.global_position.y = value * 10.0

func _on_z_rot_value_changed(value: float) -> void:
	if asset_selected == null:
		return
	var base_link = get_base_link(asset_selected)
	base_link.rotation_degrees.y = value

func _on_python_remote_button_toggled(button_pressed: bool) -> void:
	if asset_selected == null: return
	if asset_selected.is_in_group("ROBOTS"):
		asset_selected.control.python.activate = button_pressed
		asset_selected.control.python.port = int(udp_port_number.value)

func _on_udp_port_number_value_changed(value: float) -> void:
	if asset_selected == null: return
	if asset_selected.is_in_group("ROBOTS"):
		asset_selected.control.python.port = int(value)
		
func _on_open_script_button_pressed() -> void:
	if asset_selected == null: return
	if asset_selected.is_in_group("PYTHON"):
		%SourceCodeEdit.text = asset_selected.source_code
		%ScriptDialog.popup_centered()

func _on_keys_control_check_toggled(button_pressed: bool) -> void:
	if asset_selected == null: return
	if asset_selected.is_in_group("ROBOTS"):
		asset_selected.control.manual = button_pressed

func _on_confirm_delete_dialog_confirmed() -> void:
	if scene:
		scene.remove_child(asset_selected)
		asset_selected.queue_free()

func _on_script_dialog_confirmed() -> void:
	if asset_selected == null: return
	asset_selected.source_code = %SourceCodeEdit.text
	
func _on_python_script_finished(new_text: String):
#	print(new_text)
	%TerminalOutput.text += new_text

func _on_builtin_script_check_box_toggled(button_pressed: bool) -> void:
	if asset_selected == null: return
	asset_selected.builtin = button_pressed

func _on_frame_check_box_toggled(button_pressed):
	for node in get_tree().get_nodes_in_group("FRAME"):
		node.visible = button_pressed

func _on_joint_check_box_toggled(button_pressed):
	for node in get_tree().get_nodes_in_group("JOINT"):
		node.visible = button_pressed
