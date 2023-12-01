extends Node3D

var scene : Node3D
var running: bool = false
var asset_selected: Node3D
var asset_dragged: Node3D
var mouse_pos_on_area: Vector3
var game_area_pointed: bool = false
var asset_focused : Node3D = null

var _cams : Array
var _current_cam: int = 0

@onready var game = owner
@onready var save_scene_as_button: Button = %SaveSceneAsButton
@onready var save_scene_button: Button = %SaveSceneButton
@onready var terminal_output = %TerminalOutput
@onready var object_inspector: PanelContainer = %ObjectInspector
@onready var udp_port_number: SpinBox = %UDPPortNumber
@onready var camera_view_button = %CameraViewButton
@onready var robot_selected_button = %RobotSelectedButton
@onready var focused_joint_label = %FocusedJointLabel
@onready var scene_view = %SceneView
@onready var confirm_delete_dialog: ConfirmationDialog = %ConfirmDeleteDialog
@onready var rename_dialog: ConfirmationDialog = %RenameDialog

var python_bridge_scene : PackedScene = preload("res://game/python_bridge/python_bridge.tscn")

func _ready() -> void:
	%RunStopButton.modulate = Color.GREEN
	%InfosContainer.visible = false
	update_camera_view_menu()
	
	var python_bridge : Node = python_bridge_scene.instantiate()
	add_child(python_bridge)
	python_bridge.port = 4242
	python_bridge.set_activate(true)
	python_bridge.nodes.append(self)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("DELETE") and asset_selected:
		confirm_delete_dialog.dialog_text = "Delete %s object ?" % [asset_selected.name]
		confirm_delete_dialog.popup_centered()
		
	if event.is_action_pressed("rename") and asset_selected:
#		print("Asset Name: ", asset_selected.name)
		rename_asset()
		
func _process(_delta: float) -> void:
	%FPSLabel.text = "FPS: %.1f" % [Engine.get_frames_per_second()]
#	Node.print_orphan_nodes()
	
func new_scene(environment_path: String) -> void:
#	print("Env path: ", environment_path)
	delete_scene()
	init_scene()
	var environment = ResourceLoader.load(environment_path).instantiate()
	scene.add_child(environment)
	connect_pickable()
	update_robot_select_menu()
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
	var robots = get_tree().get_nodes_in_group("ROBOTS")
	if not robots.is_empty():
		var selected_robot = robots.filter(func(robot): return robot.activated == true)
		var first_robot = selected_robot.front()
		if first_robot:
			_cams.push_back(first_robot.get_node("PivotCamera/Boom/Camera"))
			cam_popup.add_check_item("EmbeddedView")
	if _current_cam > len(_cams):
		_current_cam = 0
	_camera_view_selected(_current_cam)
		
func _camera_view_selected(idx: int):
	_current_cam = idx
	var cam_popup: PopupMenu = camera_view_button.get_popup()
	for i in cam_popup.item_count:
		if idx == i:
			cam_popup.set_item_checked(i, true)
		else:
			cam_popup.set_item_checked(i, false)
	_cams[idx].current = true
			
func update_robot_select_menu():
	if not is_robots_inside_scene():
		robot_selected_button.visible = false
		return
	robot_selected_button.visible = true
	# Get robots menu
	var robot_popup: PopupMenu = robot_selected_button.get_popup()
	
	var robot_checked_idx : int = -1
	for idx in robot_popup.item_count:
		if robot_popup.is_item_checked(idx):
			robot_checked_idx = idx
			break

	if not robot_popup.index_pressed.is_connected(_on_robot_selected):
		robot_popup.index_pressed.connect(_on_robot_selected)
	robot_popup.clear()
	var robots = get_tree().get_nodes_in_group("ROBOTS")
	for robot in robots:
		robot_popup.add_check_item(robot.name)
	if robot_checked_idx != -1:
		_on_robot_selected(robot_checked_idx)
	else:
		_on_robot_selected(0)
	
	
## Callback on menu item selected
func _on_robot_selected(idx: int):
	var robot_popup: PopupMenu = robot_selected_button.get_popup()
	for i in robot_popup.item_count:
		robot_popup.set_item_checked(i, false)
		
	var robots = get_tree().get_nodes_in_group("ROBOTS")
	for robot in robots:
		if robot.name == robot_popup.get_item_text(idx):
			robot_popup.set_item_checked(idx, true)
			robot.activated = true
			asset_selected = robot
			robot_selected_button.text = asset_selected.name
		else:
			robot.activated = false
	update_camera_view_menu()
	show_joint_infos()
		
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
	var primatic_joints = all_prismatic_joints.filter(func(joint): return asset_selected.is_ancestor_of(joint) and not joint.grouped)
#	print("Prismatic joints: ", primatic_joints)
	for joint in primatic_joints:
		var dist_label = Label.new()
		dist_label.text = joint.name
		dist_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		%JointsContainer.add_child(dist_label)
		var dist_edit = PropertySlider.new()
		%JointsContainer.add_child(dist_edit)
		dist_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dist_edit.min_value = joint.limit_lower / 10.0
		dist_edit.max_value = joint.limit_upper / 10.0
		dist_edit.step = 0.01
		dist_edit.value = joint.target_dist / 10.0
		dist_edit.value_changed.connect(joint._target_dist_changed)
			
	var all_grouped_joints = get_tree().get_nodes_in_group("GROUPED_JOINTS")
	var grouped_joints = all_grouped_joints.filter(func(joint): return asset_selected.is_ancestor_of(joint))
#	print("Grouped joints: ", grouped_joints)
	for joint in grouped_joints:
#		print("grouped joint: ", joint)
		var input_label = Label.new()
		input_label.text = joint.input
		input_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		%JointsContainer.add_child(input_label)
		var input_edit = PropertySlider.new()
		%JointsContainer.add_child(input_edit)
		input_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		input_edit.min_value = joint.limit_lower
		input_edit.max_value = joint.limit_upper
		input_edit.step = 0.01
		input_edit.value = joint.input_value
		input_edit.value_changed.connect(joint._input_value_changed)
		
	if asset_selected.is_in_group("ROBOTS"):
		%PythonBridgeContainer.visible = true
		%PythonRemoteButton.set_pressed_no_signal(asset_selected.get_node("PythonBridge").activate)
#		%UDPPortNumber.value = asset_selected.get_node("PythonBridge").port
		var udp_port = asset_selected.get_meta("udp_port")
		if udp_port:
			%UDPPortNumber.set_value_no_signal(int(udp_port))
	else:
		%PythonBridgeContainer.visible = false

func hide_asset_parameters():
	object_inspector.visible = false

func save_scene(path: String):
	if path.get_extension() != "scene":
		game.current_filename = ""
		return
	if path.get_file().trim_suffix(".scene") == "":
		game.current_filename = ""
		return
	var scene_filename = path
	game.current_filename = path

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
			var udp_port = null
			if item.is_in_group("ROBOTS"):
				udp_port =  item.get_meta("udp_port", null)
			
			var scene_path = ProjectSettings.globalize_path(item.scene_file_path)
			scene_objects.assets.append({
					fullname = game.database.get_fullname(scene_path),
					string_name=item.name,
					transform=asset_transform,
					udp_port=udp_port,
					})
		if item.is_in_group("ENVIRONMENT"):
#			print("environment : ", item.name)
			if item.is_in_group("BUILTIN"):
				scene_objects.environment = {
					fullname="%s.builtin" % item.name,
					}
			else:
				var scene_path = ProjectSettings.globalize_path(item.scene_file_path)
				scene_objects.environment = {
					fullname = game.database.get_fullname(scene_path),
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
			if "udp_port" in asset and asset.udp_port:
				asset_node.set_meta("udp_port", asset.udp_port)
			freeze_asset(asset_node, true)
			scene.add_child(asset_node)

	connect_pickable()
	connect_editable()
	update_robot_select_menu()
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
	scene_node.queue_free()
	save_scene_as_button.disabled = true
	
func freeze_asset(asset, frozen):
	asset.set_physics_process(not frozen)
	freeze_children(asset, frozen)

func freeze_children(node, frozen):
	if node.is_in_group("STATIC"):
		node.freeze = true
	elif node is RigidBody3D:
		node.freeze = frozen
	elif node.is_in_group("RAY"):
		node.frozen = frozen
	for child in node.get_children():
		freeze_children(child, frozen)
		
func rename_asset():
	rename_dialog.get_node("NameEdit").text = asset_selected.name
	rename_dialog.popup_centered()
		
func enable_pickable(asset: Node3D, enable: bool):
	for child in asset.get_children():
		if child.is_in_group("SELECT"):
			child.input_ray_pickable = enable
		if child.get_child_count() > 0:
			enable_pickable(child, enable)

## Helper functions

func get_base_link(asset: Node) -> RigidBody3D:
	for child in asset.get_children():
		if child is RigidBody3D:
			return child
	return null

##

var _asset_aabb: AABB

func calculate_position_on_floor(root_node: Node3D) -> Vector3:
#	root_node.print_tree_pretty()
	var offset_pos := Vector3(0,1,0)
	_asset_aabb = AABB()
	iterate_root_node(root_node)
	var height = _asset_aabb.position.y * (-1)
	offset_pos.y = height
#	print("offset pos: ", offset_pos)
	return offset_pos

func iterate_root_node(parent: Node):
#	print("parent: ", parent)
	for child in parent.get_children():
		if child.is_in_group("VISUAL"):
			var child_aabb : AABB = child.mesh.get_aabb()
			child_aabb.position += child.global_position
			if child.mesh is ArrayMesh:
				child_aabb.size *= 10.0
				child_aabb.position *= 10.0
#			print("\tchild %s -> AABB = %s " % [child.name, child_aabb])
			_asset_aabb = _asset_aabb.merge(child_aabb)
#			print("\tmerge AABB = %s" % [_asset_aabb])
		if child.get_child_count() > 0:
			iterate_root_node(child)
			
#	print("asset %s -> AABB=%s" % [parent.name, _asset_aabb])
	
## Functions exposed to python bridge

func run():
	_on_run_stop_button_toggled(true)

func stop():
	_on_run_stop_button_toggled(false)

func reload():
	_on_reload_button_pressed()
	
func is_running() -> bool:
	return running
	
func is_robots_inside_scene() -> bool:
	var robots = get_tree().get_nodes_in_group("ROBOTS")
	if robots.is_empty():
		return false
	return true
		
func print_on_terminal(text: String):
	terminal_output.text += "%s\n" % text
	
func show_joint_infos():
#	print("selected asset: ", asset_selected)
	if asset_selected == null: return
	if asset_selected.has_node("RobotBase") and asset_selected.get_node("RobotBase").focused_joint:
		%InfosContainer.visible = true
		var focused_joint = asset_selected.get_node("RobotBase").focused_joint.name
	#			print(focused_joint)
		_joint_focus_changed(focused_joint)
		if not asset_selected.get_node("RobotBase").is_connected("joint_changed", _joint_focus_changed):
			asset_selected.get_node("RobotBase").joint_changed.connect(_joint_focus_changed)
	else:
		%InfosContainer.visible = false
		
## Slot functions

func _on_run_stop_button_toggled(button_pressed: bool) -> void:
	if scene == null:
		return
	%ObjectInspector.visible = not button_pressed
	if button_pressed:
		running = true
		%RunStopButton.text = "STOP"
		%RunStopButton.modulate = Color.RED
		show_joint_infos()
	else:
		running = false
		%RunStopButton.text = "RUN"
		%RunStopButton.modulate = Color.GREEN
		%InfosContainer.visible = false
		hide_asset_parameters()

	# activate/desactivate physics behavior
	for asset in scene.get_children():
		freeze_asset(asset, !running)
		if asset.is_in_group("ROBOTS"):
			var udp_port = asset.get_meta("udp_port")
			if udp_port:
				asset.activate_python(running, asset.get_meta("udp_port"))

func _on_reload_button_pressed():
	if owner.current_filename != "":
		load_scene(owner.current_filename)

func _on_ground_input_event(_camera, event: InputEvent, mouse_position, _normal, _shape_idx):
	mouse_pos_on_area = mouse_position
	if event.is_action_pressed("EDIT"):
		asset_focused = null
		hide_asset_parameters()
	if asset_dragged:
#		print("mouse position: ", mouse_position)
		asset_dragged.position = mouse_position + scene_view.offset_pos

func _on_ground_mouse_entered():
#	print("[GS] mouse entered")
	game_area_pointed = true

func _on_ground_mouse_exited():
#	print("[GS] mouse exited")
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

#func _on_python_remote_button_toggled(button_pressed: bool) -> void:
#	if asset_selected == null: return
#	if asset_selected.is_in_group("ROBOTS"):
#		asset_selected.get_node("PythonBridge").activate = button_pressed
#		asset_selected.get_node("PythonBridge").port = int(udp_port_number.value)

func _on_udp_port_number_value_changed(value: float) -> void:
	if asset_selected == null: return
	if asset_selected.is_in_group("ROBOTS"):
		if not is_udp_port_available(int(value)):
#			printerr("udp port not availabled")
			%UDPPortNumber.value = asset_selected.get_meta("udp_port")
			%UDPPortWarning.visible = true
			%UDPPortWarning.text = "%d is already used" % [value]
			var warning_message := get_tree().create_tween()
			warning_message.tween_property(%UDPPortWarning, "visible", false, 2)
			return
		asset_selected.set_meta("udp_port", int(value))
#		asset_selected.get_node("PythonBridge").port = int(value)
		
func get_available_udp_port():
	var robots_udp_port = Array()
	for asset in get_node("Scene").get_children():
		if asset.is_in_group("ROBOTS"):
			robots_udp_port.push_back(asset.get_meta("udp_port"))
	
	if robots_udp_port.is_empty():
		return 4243
#	print("udp ports: ", robots_udp_port)
	var higher_udp_port: int = robots_udp_port.max()
#	print("udp port higher: ", higher_udp_port)
	if higher_udp_port < 65533:
		return higher_udp_port + 1
	else:
		printerr("UDP port not assigned!")
		return null
		
func is_udp_port_available(udp_port: int) -> bool:
	var robots_udp_port : Array[int]= []
	for asset in get_node("Scene").get_children():
		if asset.is_in_group("ROBOTS") and asset.name != asset_selected.name:
			if asset.get_meta("udp_port"):
				robots_udp_port.push_back(int(asset.get_meta("udp_port")))
#	print("%d in %s: " % [udp_port, robots_udp_port])
	if udp_port in robots_udp_port:
		return false
	else:
		return true
		
func _on_open_script_button_pressed() -> void:
	if asset_selected == null: return
	if asset_selected.is_in_group("PYTHON"):
		%SourceCodeEdit.text = asset_selected.source_code
		%ScriptDialog.popup_centered()

#func _on_keys_control_check_toggled(button_pressed: bool) -> void:
#	if asset_selected == null: return
#	if asset_selected.is_in_group("ROBOTS"):
#		asset_selected.control.manual = button_pressed

func _on_confirm_delete_dialog_confirmed() -> void:
	if scene:
		scene.remove_child(asset_selected)
		asset_selected.queue_free()
		update_robot_select_menu()
		update_camera_view_menu()
		
func _on_rename_dialog_confirmed() -> void:
	object_inspector.visible = false
	if scene:
		var new_name : String = rename_dialog.get_node("NameEdit").text
		new_name = new_name.validate_node_name()
		
		if asset_selected:
			for asset in get_tree().get_nodes_in_group("ASSETS"):
				if asset.name == new_name and not asset_selected.name == new_name:
					rename_asset()
					return
			asset_selected.name = new_name
			update_robot_select_menu()
#			print("[GS] Asset selected: ", asset_selected)

func _on_script_dialog_confirmed() -> void:
	if asset_selected == null: return
	asset_selected.source_code = %SourceCodeEdit.text

func _on_builtin_script_check_box_toggled(button_pressed: bool) -> void:
	if asset_selected == null: return
	asset_selected.builtin = button_pressed

func _on_frame_check_box_toggled(button_pressed):
	for node in get_tree().get_nodes_in_group("FRAME"):
		node.visible = button_pressed

func _on_joint_check_box_toggled(button_pressed):
	for node in get_tree().get_nodes_in_group("JOINT_GIZMO"):
		node.visible = button_pressed

func _joint_focus_changed(value: String):
	focused_joint_label.text = value
