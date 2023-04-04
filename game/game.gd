extends Control

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris
@onready var game_scene = %GameScene
@onready var control_camera_3d: Camera3D = %ControlCamera3D
@onready var top_camera_2d: Camera3D = %TopCamera2D


var selected_block: Node
var current_filename: String:
	set(value):
		current_filename = value
		%FilenameLabel.text = current_filename.get_file().get_basename()
		
var connected_joystick: Array[int]

func _ready():
	game_scene.focused_block.connect(_on_selected_block)
	connected_joystick = Input.get_connected_joypads()
#	print_debug(connected_joystick)
	%ObjectInspector.visible = false
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DELETE"):
		if selected_block == null: return
		var game_level = game_scene.get_node_or_null("GameLevel")
		if game_level:
			game_level.remove_child(selected_block)
			selected_block.queue_free()
		

func _on_blocks_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	pass
#	print("Item clicked")

# Call when a block is selected in the scene
func _on_selected_block(block: Node):
#	print_debug(block)
	if block == null or %GameScene.running:
		selected_block = null
		%ObjectInspector.visible = false
	else:
		selected_block = block
		%ObjectInspector.visible = true
		%BlockName.text = block.name
		var table_xy_tr: Transform3D = get_tree().get_nodes_in_group("TABLE")[0].get_node("Coord3D").transform
		var xyz_pos: Vector3 = block.transform.origin * table_xy_tr
		
		%X_pos.value = xyz_pos.x / 10.0
		%Y_pos.value = xyz_pos.y / 10.0
		%Z_pos.value = xyz_pos.z / 10.0
		%Z_rot.value = block.rotation_degrees.y
		if block.get("joystick_enable") == null or connected_joystick.size() == 0:
			%JoystickContainer.visible = false
		else:
			%JoystickContainer.visible = true
			if block.joystick_enable: %JoystickEnableButton.set_pressed_no_signal(true)
			else: %JoystickEnableButton.set_pressed_no_signal(false)
		if block.get("UDP_port") == null:
			%UDPPortContainer.visible = false
		else:
			%UDPPortContainer.visible = true
			%UDPPortNumber.value = block.UDP_port

func _on_x_pos_value_changed(value: float) -> void:
	if selected_block == null:
		return
	var table_xy_tr: Transform3D = get_tree().get_nodes_in_group("TABLE")[0].get_node("Coord3D").transform
#	print_debug("coord3D: ", coord_3d)
	var local_pos: Vector3 = selected_block.transform.origin * table_xy_tr
#	print_debug("local pos: ", local_pos)
	local_pos.x = 10.0 * value
	var new_pos_coord_3d = local_pos * table_xy_tr.inverse()	# Global coordinates
#	print_debug("new pos coord3D: ", new_pos_coord_3d)
	selected_block.position = new_pos_coord_3d

	
func _on_y_pos_value_changed(value: float) -> void:
	if selected_block == null:
		return
	var table_xy_tr: Transform3D = get_tree().get_nodes_in_group("TABLE")[0].get_node("Coord3D").transform
	var local_pos: Vector3 = selected_block.transform.origin * table_xy_tr
#	print_debug("local pos: ", local_pos)
	local_pos.y = 10.0 * value
	var new_pos_coord_3d = local_pos * table_xy_tr.inverse()	# Global coordinates
#	print_debug("new pos coord3D: ", new_pos_coord_3d)
	selected_block.position = new_pos_coord_3d
	
func _on_z_pos_value_changed(value: float) -> void:
	if selected_block == null:
		return
	var table_xy_tr: Transform3D = get_tree().get_nodes_in_group("TABLE")[0].get_node("Coord3D").transform
	var local_pos: Vector3 = selected_block.transform.origin * table_xy_tr
#	print_debug("local pos: ", local_pos)
	local_pos.z = 10.0 * value
	var new_pos_coord_3d = local_pos * table_xy_tr.inverse()	# Global coordinates
#	print_debug("new pos coord3D: ", new_pos_coord_3d)
	selected_block.position = new_pos_coord_3d
	
func _on_z_rot_value_changed(value: float) -> void:
	if selected_block == null:
		return
	selected_block.rotation_degrees.y = value
	
func _on_joystick_enable_button_toggled(button_pressed: bool) -> void:
	if selected_block == null:
		return
	selected_block.joystick_enable = button_pressed
	
func _on_udp_port_number_value_changed(value: float) -> void:
	if selected_block == null:
		return
	selected_block.UDP_port = int(value)
	
func _on_save_button_pressed() -> void:
	game_scene.save_scene(current_filename)

func _on_load_scene_button_pressed():
	%LoadSceneDialog.popup_centered(Vector2i(300,300))

func _on_load_scene_dialog_file_selected(path):
	current_filename = path
	game_scene.load_scene(path)

func _on_save_scene_button_pressed():
	if current_filename != "":
		%SaveSceneDialog.current_file = current_filename.get_file()
	%SaveSceneDialog.popup_centered(Vector2i(300, 300))

func _on_save_scene_dialog_file_selected(path):
	current_filename = path
	game_scene.save_scene(path)

func _on_view_button_toggled(button_pressed: bool) -> void:
	top_camera_2d.current = true if button_pressed else false
