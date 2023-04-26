extends Control

@export var pck_dir: String = "assets"

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris
@onready var game_scene = %GameScene
@onready var control_camera_3d: Camera3D = %ControlCamera3D
@onready var top_camera_2d: Camera3D = %TopCamera2D
@onready var object_inspector = %ObjectInspector
@onready var confirm_delete_dialog: ConfirmationDialog = $ConfirmDeleteDialog


var selected_root_block: Node
var current_filename: String:
	set(value):
		current_filename = value
		%FilenameLabel.text = current_filename.get_file().get_basename()

var connected_joystick: Array[int]
var database: GoboticsDB = GoboticsDB.new()

func _enter_tree():
	if not OS.has_feature("editor"):
		load_pck()
	database.create()

func _ready():
	game_scene.block_selected.connect(_on_selected_block)
	confirm_delete_dialog.confirmed.connect(_on_confirm_delete_dialog_confirmed)
	connected_joystick = Input.get_connected_joypads()
	%SaveSceneButton.disabled = true
	%SaveSceneAsButton.disabled = true
#	print_debug(connected_joystick)
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DELETE"):
#		print(selected_block)
		if selected_root_block == null: return
		confirm_delete_dialog.dialog_text = "Delete %s object ?" % [selected_root_block.name]
		confirm_delete_dialog.popup_centered()

func _on_confirm_delete_dialog_confirmed() -> void:
	var scene = game_scene.get_node_or_null("Scene")
#	print(scene)
	if scene:
		scene.remove_child(selected_root_block)
		selected_root_block.queue_free()

# Call when a block is selected in the scene
func _on_selected_block(block: Node):
	selected_root_block = block.owner if block != null else null
#	print("selected block: ", selected_block)
	if block == null or game_scene.running:
		%ObjectInspector.visible = false
		return
	%ObjectInspector.visible = true
	%X_pos.value = block.global_position.x / 10.0
	%Y_pos.value = block.global_position.y / 10.0
	%Z_pos.value = block.global_position.z / 10.0
	%Z_rot.value = block.rotation_degrees.y
	%BlockName.text = block.owner.name

#		if block.get("joystick_enable") == null or connected_joystick.size() == 0:
#			%JoystickContainer.visible = false
#		else:
#			%JoystickContainer.visible = true
#			if block.joystick_enable: %JoystickEnableButton.set_pressed_no_signal(true)
#			else: %JoystickEnableButton.set_pressed_no_signal(false)
#		if block.get("UDP_port") == null:
#			%UDPPortContainer.visible = false
#		else:
#			%UDPPortContainer.visible = true
#			%UDPPortNumber.value = block.UDP_port

func _on_x_pos_value_changed(value: float) -> void:
	if selected_root_block == null:
		return
	var rigid_body = selected_root_block.get_child(0)
	if rigid_body is RigidBody3D:
		rigid_body.global_position.x = value*10.0

func _on_y_pos_value_changed(value: float) -> void:
	if selected_root_block == null:
		return
	var rigid_body = selected_root_block.get_child(0)
	if rigid_body is RigidBody3D:
		rigid_body.global_position.y = value*10.0

func _on_z_pos_value_changed(value: float) -> void:
	if selected_root_block == null:
		return
	var rigid_body = selected_root_block.get_child(0)
	if rigid_body is RigidBody3D:
		rigid_body.global_position.z = value*10.0

func _on_z_rot_value_changed(value: float) -> void:
	if selected_root_block == null:
		return
	var rigid_body = selected_root_block.get_child(0)
	if rigid_body is RigidBody3D:
		rigid_body.rotation_degrees.y = value

func _on_joystick_enable_button_toggled(button_pressed: bool) -> void:
	if selected_root_block == null:
		return
	selected_root_block.joystick_enable = button_pressed
	
func _on_udp_port_number_value_changed(value: float) -> void:
	if selected_root_block == null:
		return
	selected_root_block.UDP_port = int(value)
	

func _on_new_scene_button_pressed() -> void:
	%NewSceneDialog.popup_centered(Vector2i(200, 300))
	
func _on_new_scene_dialog_confirmed() -> void:
	var items = %EnvironmentList.get_selected_items()
	if items.is_empty(): return
	var environment_name: String = %EnvironmentList.get_item_text(items[0])
	game_scene.new_scene(database.get_scene(environment_name))
	
func _on_load_scene_button_pressed():
	%LoadSceneDialog.popup_centered(Vector2i(300,300))

func _on_load_scene_dialog_file_selected(path):
	current_filename = path
	game_scene.load_scene(path)

func _on_save_button_pressed() -> void:
	game_scene.save_scene(current_filename)
	
func _on_save_scene_as_button_pressed():
	if current_filename != "":
		%SaveSceneDialog.current_file = current_filename.get_file()
	%SaveSceneDialog.popup_centered(Vector2i(300, 300))

func _on_save_scene_dialog_file_selected(path):
	current_filename = path
	game_scene.save_scene(path)

func _on_view_button_toggled(button_pressed: bool) -> void:
	top_camera_2d.current = true if button_pressed else false

func load_pck():
	var executable_path: String = OS.get_executable_path().get_base_dir()
	var assets_dir: String = executable_path.path_join(pck_dir)
	var files = Array(DirAccess.get_files_at(assets_dir))
	var pck_files = files.filter(func(file): return file.get_extension() == "pck")
#	print(pck_files)
	
	for pck_file in pck_files:
		var pck_path: String = assets_dir.path_join(pck_file)
		if not ProjectSettings.load_resource_pack(pck_path, false):
			print("Packed resource not loading")

