class_name GameScene extends Node3D

var scene : Node3D
var running: bool = false
var asset_dragged: Node3D
var mouse_pos_on_area: Vector3
var game_area_pointed: bool = false
var asset_focused : Node3D = null

var _selected_asset: Node3D
var _robot_selected: Node3D
var _cams : Array
var _current_cam: int = 0

@onready var game = owner
@onready var transform_container: GridContainer = %TransformContainer
@onready var asset_name_label: Label = %AssetNameLabel
@onready var udp_port_number: SpinBox = %UDPPortNumber
@onready var inputs_container: MarginContainer = %InputsContainer
@onready var drive_panel: PanelContainer = %DrivePanel
@onready var joints_panel: PanelContainer = %JointsPanel

@onready var camera_view_button = %CameraViewButton
@onready var robot_selected_button = %RobotSelectedButton
@onready var scene_view = %SceneView
@onready var confirm_delete_dialog: ConfirmationDialog = %ConfirmDeleteDialog
@onready var rename_dialog: ConfirmationDialog = %RenameDialog

var python_bridge_scene : PackedScene = preload("res://game/python_bridge/python_bridge.tscn")

#region INIT

func _ready() -> void:
	%RunStopButton.modulate = Color.GREEN
	inputs_container.visible = false
	_show_asset_properties(null)
	update_camera_view_menu()
	set_physics_process(false)
	var python_bridge : Node = python_bridge_scene.instantiate()
	add_child(python_bridge)
	python_bridge.port = 4242
	python_bridge.set_activate(true)
	python_bridge.nodes.append(self)
#endregion


#region PROCESS

func _unhandled_input(event: InputEvent) -> void:
	if not running and event.is_action_pressed("DELETE") and _selected_asset:
		confirm_delete_dialog.dialog_text = "Delete %s object ?" % [_selected_asset.name]
		confirm_delete_dialog.popup_centered()
		
	if not running and event.is_action_pressed("rename") and _selected_asset:
		rename_asset()
		
	if event.is_action_pressed("SELECT"):
		_select_asset()


func _process(_delta: float) -> void:
	%FPSLabel.text = "FPS: %.1f" % [Engine.get_frames_per_second()]
	

func _physics_process(delta: float) -> void:
	%PhysicsFrameLabel.text = "Frame: %d" % [GPSettings.physics_tick]
	GPSettings.physics_tick += 1
	
	if running and _robot_selected:
		var robot_base: Node = _robot_selected.get_node_or_null("RobotBase")
		if robot_base and robot_base.has_method("command"):
			robot_base.command(delta)
		
		var robot_drive: Node = _robot_selected.get_node_or_null("ControlRobot")
		if robot_drive and robot_drive.has_method("command"):
			robot_drive.command(delta)

#endregion


#region ASSET SELECTION

func _select_asset():
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin = get_viewport().get_camera_3d().project_ray_origin(mouse_pos)
	var ray_direction = get_viewport().get_camera_3d().project_ray_normal(mouse_pos)
	# Collision shape is in SELECTION Layer (mask 8)
	var ray_quering = PhysicsRayQueryParameters3D.create(
		ray_origin, ray_origin + ray_direction * 1000, 0b1000)
	
	var result = get_world_3d().direct_space_state.intersect_ray(ray_quering)
	if result:
		_selected_asset = result.collider.owner
		get_tree().call_group("VISUAL", "highlight", result.collider.owner)
		_show_asset_name(result.collider.owner)
		if result.collider.owner.is_in_group("ASSETS"):
			_show_asset_properties(result.collider.owner)
		else:
			_show_asset_properties(null)
	else: # Deselects all assets
		_selected_asset = null
		get_tree().call_group("VISUAL", "highlight", null)
		_show_asset_name(null)
		_show_asset_properties(null)


func _show_asset_name(asset):
	if asset:
		#print("show %s" % asset.name)
		var asset_label = Label.new()
		asset_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		asset_label.text = asset.name
		var asset_position = func():
			for child in asset.get_children():
				if child is RigidBody3D:
					return child.global_position
		asset_label.position = (get_viewport().get_camera_3d()
			.unproject_position(asset_position.call())
			)
		add_child(asset_label)
		await get_tree().create_timer(1).timeout
		remove_child(asset_label)
		asset_label.queue_free()

func _show_asset_properties(asset):
	var set_property_editable = func(editable):
		for child in transform_container.get_children():
			if child is SpinBox:
				child.editable = editable
		if editable:
			asset_name_label.text = asset.name
		else:
			asset_name_label.text = "no selection"
		%UDPPortNumber.editable = editable
	
	if asset == null:
		set_property_editable.call(false)
		return
	else:
		set_property_editable.call(true)
	
	var search_base_link = func():
		for child_node in asset.get_children():
			if child_node is RigidBody3D:
				return child_node
	var base_link = search_base_link.call()
	
	var base_link_tr = {
		x = base_link.global_position.x / GPSettings.SCALE,
		y = -base_link.global_position.z / GPSettings.SCALE,
		z = base_link.global_position.y / GPSettings.SCALE,
		roll = base_link.global_basis.get_euler().x,
		pitch = -base_link.global_basis.get_euler().z,
		yaw = base_link.global_basis.get_euler().y,
	}
	
	transform_container.get_node("X_pos").call_deferred("set_value_no_signal", base_link_tr.x)
	transform_container.get_node("Y_pos").call_deferred("set_value_no_signal", base_link_tr.y)
	transform_container.get_node("Z_pos").call_deferred("set_value_no_signal", base_link_tr.z)
	transform_container.get_node("Roll").call_deferred("set_value_no_signal", base_link_tr.roll)
	transform_container.get_node("Pitch").call_deferred("set_value_no_signal", base_link_tr.pitch)
	transform_container.get_node("Yaw").call_deferred("set_value_no_signal", base_link_tr.yaw)
	
	if _selected_asset.is_in_group("ROBOTS"):
		%UDPPortContainer.visible = true
		var udp_port = _selected_asset.get_meta("udp_port")
		if udp_port:
			udp_port_number.set_value_no_signal(int(udp_port))
	else:
		%UDPPortContainer.visible = false

func _on_x_pos_value_changed(value: float) -> void:
	if _selected_asset == null:
		return
	var base_link = get_base_link(_selected_asset)
	base_link.global_position.x = value * GPSettings.SCALE


func _on_y_pos_value_changed(value: float) -> void:
	if _selected_asset == null:
		return
	var base_link = get_base_link(_selected_asset)
	base_link.global_position.z = -value * GPSettings.SCALE


func _on_z_pos_value_changed(value: float) -> void:
	if _selected_asset == null:
		return
	var base_link = get_base_link(_selected_asset)
	base_link.global_position.y = value * GPSettings.SCALE


func _on_roll_value_changed(value: float) -> void:
	if _selected_asset == null:
		return
	var base_link = get_base_link(_selected_asset)
	base_link.rotation.x = value


func _on_pitch_value_changed(value: float) -> void:
	if _selected_asset == null:
		return
	var base_link = get_base_link(_selected_asset)
	base_link.rotation.z = -value


func _on_yaw_value_changed(value: float) -> void:
	if _selected_asset == null:
		return
	var base_link = get_base_link(_selected_asset)
	base_link.rotation.y = value


func _on_udp_port_number_value_changed(value: float) -> void:
	if _selected_asset == null: return
	if _selected_asset.is_in_group("ROBOTS"):
		if not is_udp_port_available(int(value)):
			printerr("udp port not availabled")
			%UDPPortNumber.value = _selected_asset.get_meta("udp_port")
			%UDPPortWarning.visible = true
			%UDPPortWarning.text = "%d is already used" % [value]
			var warning_message := get_tree().create_tween()
			warning_message.tween_property(%UDPPortWarning, "visible", false, 2)
			return
		_selected_asset.set_meta("udp_port", int(value))

#endregion


func connect_pickable():
	var nodes = get_tree().get_nodes_in_group("PICKABLE")
#	print(nodes)
	for node in nodes:
		if not node.is_connected("mouse_entered", _on_ground_mouse_entered):
			#print("[GS] set node %s pickable" % [node])
			node.mouse_entered.connect(_on_ground_mouse_entered)
		if not node.is_connected("mouse_exited", _on_ground_mouse_exited):
			node.mouse_exited.connect(_on_ground_mouse_exited)
		if not node.is_connected("input_event", _on_ground_input_event):
			node.input_event.connect(_on_ground_input_event)


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
	
	if _robot_selected:
		_cams.push_back(_robot_selected.get_node("PivotCamera/Boom/Camera"))
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
	if not _cams.is_empty():
		if not is_robots_inside_scene(): return
		_cams[idx].current = true

#region ROBOT SELECTION

func update_robot_select_menu():
	if not is_robots_inside_scene():
		robot_selected_button.visible = false
		return
	robot_selected_button.visible = true
	# Get robots menu
	var robot_popup: PopupMenu = robot_selected_button.get_popup()
	if not robot_popup.index_pressed.is_connected(_on_robot_selected):
		robot_popup.index_pressed.connect(_on_robot_selected)
	robot_popup.clear()
	var robots = scene.get_children().filter(
			func(child):
				return child.is_in_group("ROBOTS")
	)
	#print("robots: ", robots)
	for robot in robots:
		robot_popup.add_check_item(robot.name)
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
			_robot_selected = robot
			robot_selected_button.text = robot.name
	_show_robot_command()
	update_camera_view_menu()

#endregion

func _show_robot_command():
	inputs_container.visible = running
	if _robot_selected == null:
		drive_panel.visible = false
		return
	
	var driving_node = _robot_selected.get_node_or_null("ControlRobot")
	if driving_node:
		drive_panel.visible = true
	else:
		drive_panel.visible = false
		
	var base_node = _robot_selected.get_node_or_null("RobotBase")
	if base_node:
		var visible_joints: Array = base_node._joints.filter(
			func(joint: Node):
				return joint.get_meta("visible", false) == true
				)
		#print("robot: %s, base: %s, visible joints: %s" % [_robot_selected.name,
															#base_node, visible_joints])
		if visible_joints.is_empty():
			joints_panel.visible = false
		else:
			joints_panel.visible = true
			joints_panel.base_robot = base_node # Call before next instruction
			joints_panel.joints = visible_joints


func show_asset_parameters():
	# Remove joint parameters
	for child in %JointsContainer.get_children():
		%JointsContainer.remove_child(child)
		child.queue_free()
		
	var all_continuous_joints = get_tree().get_nodes_in_group("CONTINUOUS")
	var continuous_joints = all_continuous_joints.filter(func(joint): return _selected_asset.is_ancestor_of(joint))
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
		velocity_edit.step = joint.LIMIT_VELOCITY / GPSettings.SCALE
#			velocity_edit.tick_count = 3
		velocity_edit.value = joint.target_velocity
		velocity_edit.value_changed.connect(joint._target_velocity_changed)
			
	var all_revolute_joints = get_tree().get_nodes_in_group("REVOLUTE")
	var revolute_joints = all_revolute_joints.filter(func(joint): return _selected_asset.is_ancestor_of(joint))
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
		angle_edit.value = joint.target_input
		angle_edit.value_changed.connect(joint._target_angle_changed)
			
	var all_prismatic_joints = get_tree().get_nodes_in_group("PRISMATIC")
	var primatic_joints = all_prismatic_joints.filter(func(joint): return _selected_asset.is_ancestor_of(joint) and not joint.grouped)
#	print("Prismatic joints: ", primatic_joints)
	for joint in primatic_joints:
		var dist_label = Label.new()
		dist_label.text = joint.name
		dist_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		%JointsContainer.add_child(dist_label)
		var dist_edit = PropertySlider.new()
		%JointsContainer.add_child(dist_edit)
		dist_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dist_edit.min_value = joint.limit_lower / GPSettings.SCALE
		dist_edit.max_value = joint.limit_upper / GPSettings.SCALE
		dist_edit.step = 0.01
		dist_edit.value = joint.target_input / GPSettings.SCALE
		dist_edit.value_changed.connect(joint._target_dist_changed)
			
	var all_grouped_joints = get_tree().get_nodes_in_group("GROUPED_JOINTS")
	var grouped_joints = all_grouped_joints.filter(func(joint): return _selected_asset.is_ancestor_of(joint))
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


func new_scene(environment_path: String) -> void:
	#print("Env path: ", environment_path)
	delete_scene()
	init_scene()
	var environment: Node3D = ResourceLoader.load(environment_path).instantiate()
	scene.add_child(environment)
	connect_pickable()
	update_robot_select_menu()
	%RunStopButton.button_pressed = false


func save_project():
	save_scene(GSettings.project_path.path_join(GPSettings.project_file))


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
					fullname = GSettings.database.get_fullname(scene_path),
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
					fullname = GSettings.database.get_fullname(scene_path),
					}
	var scene_json = JSON.stringify(scene_objects, "\t", false)
#		print("scene JSON: ", scene_json)
	
	var file = FileAccess.open(scene_filename, FileAccess.WRITE)
	file.store_string(scene_json)


func load_scene(path):
	var scene_filename = path
	#print("Load scene filename: ", scene_filename)
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
	var env_filename
	if "fullname" in scene_objects.environment:
		env_filename = GSettings.database.get_scene_from_fullname(scene_objects.environment.fullname)
	if env_filename:
		var environment = ResourceLoader.load(env_filename).instantiate()
		scene.add_child(environment)
	
	for asset in scene_objects.assets:
		if "fullname" in asset and asset.fullname is String:
			var asset_filename = GSettings.database.get_asset_scene(asset.fullname)
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
			set_physics(asset_node, true)
			scene.add_child(asset_node)

	connect_pickable()
	update_robot_select_menu()
	update_camera_view_menu()
	%RunStopButton.button_pressed = false


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


func set_physics(asset, frozen):
	#print("script %s, %s, frozen: %s" % [asset.name, asset.get_script(), asset.get("frozen")])
	if asset.get("frozen") == null:
		asset.set_physics_process(not frozen)
	else:
		asset.frozen = frozen
		
	_freeze_children(asset, frozen)


func _freeze_children(node, frozen):
	if node.is_in_group("STATIC"):
		node.freeze = true
	elif node is RigidBody3D:
		node.freeze = frozen
	elif node.is_in_group("RAY"):
		node.frozen = frozen
	for child in node.get_children():
		_freeze_children(child, frozen)


func rename_asset():
	rename_dialog.get_node("NameEdit").text = _selected_asset.name
	rename_dialog.popup_centered()


func enable_pickable(asset: Node, enable: bool):
	#print("[GS] pick %s: %s" % [asset, enable])
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


func _on_run_stop_button_toggled(button_pressed: bool) -> void:
	if scene == null: return
	
	%ControlContainer.visible = not button_pressed
	%ReloadButton.visible = not button_pressed
	
	var environments: Array = get_tree().get_nodes_in_group("ENVIRONMENT")
	if environments.is_empty(): return
	var environment: Node3D = environments[0]
	
	if button_pressed:
		running = true
		set_physics_process(true)
		if (environment.has_signal("asset_exited")
			and not environment.asset_exited.is_connected(_on_asset_out_of_bound_detected)):
			environment.asset_exited.connect(_on_asset_out_of_bound_detected)
		%RunStopButton.text = "STOP"
		%RunStopButton.modulate = Color.RED
	else:
		running = false
		set_physics_process(false)
		if environment.has_signal("asset_exited"):
			environment.asset_exited.disconnect(_on_asset_out_of_bound_detected)
		%RunStopButton.text = "RUN"
		%RunStopButton.modulate = Color.GREEN
	
	for asset in scene.get_children():
		set_physics(asset, !running)
		if asset.is_in_group("ROBOTS"):
			var udp_port = asset.get_meta("udp_port")
			if udp_port:
				asset.activate_python(running, asset.get_meta("udp_port"))
	
	_show_robot_command()


func _on_reload_button_pressed():
	if owner.current_filename != "":
		load_scene(owner.current_filename)
		GPSettings.physics_tick = 0
		%PhysicsFrameLabel.text = "Frame: %d" % [GPSettings.physics_tick]


func _on_ground_input_event(_camera, event: InputEvent, mouse_position, _normal, _shape_idx):
	mouse_pos_on_area = mouse_position
	if event.is_action_pressed("EDIT"):
		asset_focused = null
	if asset_dragged:
#		print("mouse position: ", mouse_position)
		asset_dragged.position = mouse_position + scene_view.offset_pos


func _on_ground_mouse_entered():
#	print("[GS] mouse entered")
	game_area_pointed = true

func _on_ground_mouse_exited():
#	print("[GS] mouse exited")
	game_area_pointed = false


func _on_editable_mouse_entered():
	owner.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	#print("[GS] mouse entered on %s" % [owner.mouse_default_cursor_shape])
	
func _on_editable_mouse_exited():
	#print("[GS] mouse exited on %s" % [owner.mouse_default_cursor_shape])
	owner.mouse_default_cursor_shape = Control.CURSOR_ARROW


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
		if asset.is_in_group("ROBOTS") and asset.name != _selected_asset.name:
			if asset.get_meta("udp_port"):
				robots_udp_port.push_back(int(asset.get_meta("udp_port")))
#	print("%d in %s: " % [udp_port, robots_udp_port])
	if udp_port in robots_udp_port:
		return false
	else:
		return true


func _on_open_script_button_pressed() -> void:
	if _selected_asset == null: return
	if _selected_asset.is_in_group("PYTHON"):
		%SourceCodeEdit.text = _selected_asset.source_code
		%ScriptDialog.popup_centered()


func _on_rename_dialog_confirmed() -> void:
	if scene:
		var new_name : String = rename_dialog.get_node("NameEdit").text
		new_name = new_name.validate_node_name()
		
		if _selected_asset:
			for asset in get_tree().get_nodes_in_group("ASSETS"):
				if asset.name == new_name and not _selected_asset.name == new_name:
					rename_asset()
					return
			_selected_asset.name = new_name
			update_robot_select_menu()
		save_project()


func _on_script_dialog_confirmed() -> void:
	if _selected_asset == null: return
	_selected_asset.source_code = %SourceCodeEdit.text


func _on_builtin_script_check_box_toggled(button_pressed: bool) -> void:
	if _selected_asset == null: return
	_selected_asset.builtin = button_pressed


func _on_frame_check_box_toggled(button_pressed):
	for node in get_tree().get_nodes_in_group("FRAME"):
		node.visible = button_pressed


func _on_joint_check_box_toggled(button_pressed):
	for node in get_tree().get_nodes_in_group("JOINT_GIZMO"):
		node.visible = button_pressed


func _on_asset_delete_dialog_confirmed() -> void:
	if scene:
		scene.remove_child(_selected_asset)
		# INFO: remove asset from project and update robot selection menu
		update_robot_select_menu()
		save_project()


func _on_asset_out_of_bound_detected(body: Node3D):
	#print("%s detected" % body)
	if body.is_in_group("BASE_LINK"):
		var root_node := body.get_parent_node_3d()
		if root_node:
			#print("Delete %s out of bounds" % root_node.name)
			scene.remove_child.call_deferred(root_node)


func _on_asset_exited_scene(node: Node):
	#print("%s exited scene" % node.name)
	await node.tree_exited
	if is_inside_tree():
		update_robot_select_menu()
		update_camera_view_menu()
		save_project()
		node.queue_free()
