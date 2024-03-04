class_name AssetEditor extends PanelContainer

signal fullscreen_toggled(button_pressed: bool)

@export var asset_fullname: String # Setting by caller

enum TypeAsset {
	STANDALONE,
	ROBOT,
	ENVIRONMENT,
}
var asset_type : TypeAsset = TypeAsset.ROBOT


var urdf_parser = URDFParser.new()
var urdf_syntaxhighlighter = URDFSyntaxHighlighter.new()
var asset_scene : PackedScene = null
var asset_node : Node3D = null:
	set(value):
		asset_node = value

@onready var urdf_code_edit: CodeEdit = %URDFCodeEdit
@onready var preview_viewport = %PreviewViewport
@onready var preview_scene = %PreviewScene
@onready var asset_filename_edit = %AssetFilenameEdit
@onready var save_asset_button = %SaveAssetButton

func _ready():
	urdf_parser.scale = 10
	urdf_code_edit.syntax_highlighter = urdf_syntaxhighlighter
	if not asset_fullname:
		match asset_type:
			TypeAsset.STANDALONE:
				urdf_code_edit.text = urdf_standalone_template
				
			TypeAsset.ROBOT:
				urdf_code_edit.text = urdf_robot_template
				
			TypeAsset.ENVIRONMENT:
				urdf_code_edit.text = urdf_environment_template
				
		asset_fullname = "noname.urdf"
	else:
		var asset_path = GSettings.asset_path.path_join(asset_fullname)
		#print("[AE] asset path: ", asset_path)
		var urdf_file = FileAccess.open(asset_path, FileAccess.READ)
		if urdf_file == null:
			printerr("urdf file failed to loading. %d" % [FileAccess.get_open_error()])
			return
		urdf_code_edit.text = urdf_file.get_as_text()
		urdf_parser.gravity_scale = ProjectSettings.get_setting("physics/3d/default_gravity")/9.8
		save_asset_button.disabled = true
		
	asset_filename_edit.text = asset_fullname
	show_visual_mesh(%VisualCheckBox.button_pressed)
	show_collision_shape(%CollisionCheckBox.button_pressed)
	show_link_frame(%FrameCheckBox.button_pressed)
	show_joint_frame(%JointCheckBox.button_pressed)
	folding_link_tags()
	
	if not generate_scene():
		printerr("[AE] creating asset failed")
	
func generate_scene() -> bool:
	urdf_parser.asset_user_path = GSettings.asset_path.path_join(asset_filename_edit.text).get_base_dir()

	var error_output : Array = []
	var root_node = urdf_parser.parse(urdf_code_edit.text.to_ascii_buffer(), error_output)
	
	if root_node == null:
		printerr("[DB] URDF Parser failed")
		return false
	
	root_node.set_meta("fullname", asset_filename_edit.text)
	asset_scene = PackedScene.new()
	var err = asset_scene.pack(root_node)
	if err:
		printerr("error packed %s!" % root_node)
	for child in preview_scene.get_children():
		if child.is_in_group("ASSETS") or child.is_in_group("ENVIRONMENT"):
			preview_scene.remove_child(child)
			child.queue_free()
	asset_node = asset_scene.instantiate()
	freeze_asset(asset_node, true)
	preview_scene.add_child(asset_node)
	
	show_visual_mesh(%VisualCheckBox.button_pressed)
	show_collision_shape(%CollisionCheckBox.button_pressed)
	show_link_frame(%FrameCheckBox.button_pressed)
	show_joint_frame(%JointCheckBox.button_pressed)
	# Freeing orphan nodes
	root_node.queue_free()
	return true
	
func _on_generate_button_pressed() -> void:
	generate_scene()
	
func _on_save_button_pressed():
	if asset_filename_edit.text == "":
		return
	if not asset_filename_edit.text.ends_with(".urdf"):
		asset_filename_edit.text = asset_filename_edit.text + ".urdf"
	var new_asset_filename = GSettings.asset_path.path_join(asset_filename_edit.text)
#	print("new asset filename: ", new_asset_filename)
	var path = new_asset_filename.get_base_dir()
	if not DirAccess.dir_exists_absolute(path):
		printerr("[AE] %s not exist ()" % path)
		DirAccess.make_dir_recursive_absolute(path)

	if FileAccess.file_exists(new_asset_filename):
		%OverwriteConfirmationDialog.popup_centered()
	else:
		save_asset()

func save_asset():
	var asset_path = GSettings.asset_path.path_join(asset_filename_edit.text)
	var urdf_file = FileAccess.open(asset_path, FileAccess.WRITE)
	if urdf_file == null:
		printerr("urdf file failed to saving!")
		return
	urdf_file.store_string(urdf_code_edit.text)
	urdf_file.flush() # Force writing
	
	GSettings.database.update_asset(asset_filename_edit.text)
	
	var asset_editor_dialog = get_parent()
	if asset_editor_dialog:
		asset_editor_dialog.set_meta("fullname", asset_filename_edit.text)
		var asset_list = asset_editor_dialog.get_parent()
		if asset_list:
			asset_list.update_assets_in_scene()
	save_asset_button.disabled = true
	
func _on_overwrite_confirmation_dialog_confirmed():
	save_asset()


func _on_urdf_code_edit_text_changed() -> void:
	save_asset_button.disabled = false
	
func freeze_asset(root_node, frozen):
	root_node.set_physics_process(not frozen)
	freeze_children(root_node, frozen)

func freeze_children(node, frozen):
	if node is RigidBody3D:
		node.freeze = frozen
	for child in node.get_children():
		freeze_children(child, frozen)

func show_visual_mesh(enable: bool):
	var scene_tree : SceneTree = get_tree()
	for node in scene_tree.get_nodes_in_group("VISUAL"):
		if preview_scene.is_ancestor_of(node):
			node.visible = enable
		
func show_collision_shape(enable: bool):
	var scene_tree : SceneTree = get_tree()
	for node in scene_tree.get_nodes_in_group("COLLISION"):
		if preview_scene.is_ancestor_of(node):
			node.visible = enable
		
func show_link_frame(enable: bool):
	var scene_tree : SceneTree = get_tree()
	for node in scene_tree.get_nodes_in_group("FRAME"):
		if preview_scene.is_ancestor_of(node):
			node.visible = enable
			
func show_joint_frame(enable: bool):
	for node in get_tree().get_nodes_in_group("JOINT_GIZMO"):
		if preview_scene.is_ancestor_of(node):
			node.visible = enable
			
func show_sensor_frame(enable: bool):
	for node in get_tree().get_nodes_in_group("SENSOR_GIZMO"):
		if preview_scene.is_ancestor_of(node):
			node.visible = enable

func folding_link_tags():
	for line_num in urdf_code_edit.get_line_count():
		if urdf_code_edit.can_fold_line(line_num):
			if not urdf_code_edit.get_line(line_num).begins_with("<standalone") and \
				not urdf_code_edit.get_line(line_num).begins_with("<robot") and \
				not urdf_code_edit.get_line(line_num).begins_with("<env") :
#				print("Fold line %d" % [line_num])
				urdf_code_edit.fold_line(line_num)


func _on_visual_check_box_toggled(button_pressed):
	show_visual_mesh(button_pressed)

func _on_collision_check_box_toggled(button_pressed):
	show_collision_shape(button_pressed)

func _on_link_check_box_toggled(button_pressed):
	show_link_frame(button_pressed)

func _on_joint_check_box_toggled(button_pressed):
	show_joint_frame(button_pressed)
	
func _on_sensor_check_box_toggled(button_pressed):
	show_sensor_frame(button_pressed)

func _on_full_screen_button_toggled(button_pressed):
	fullscreen_toggled.emit(button_pressed)

func _on_asset_filename_edit_text_changed(new_text):
	asset_fullname = new_text
	if new_text == "":
		%SaveAssetButton.disabled = true
	else:
		%SaveAssetButton.disabled = false

const urdf_robot_template = """<robot name="noname">
	<link name="base_link">
	
	</link>
</robot>
"""

const urdf_standalone_template = """<standalone name="noname">
	<link name="base_link">
	
	</link>
</standalone>
"""

const urdf_environment_template = """<env name="noname">
	<link name="world">
	
	</link>
</env>
"""


func _on_quit_button_pressed():
	if save_asset_button.disabled == false:
		%SavingConfirmationDialog.popup_centered()
	else:
		_on_exit()


func _on_saving_confirmation_dialog_confirmed():
	save_asset()
	_on_exit()


func _on_saving_confirmation_dialog_canceled():
	_on_exit()


func _on_exit():
	var dialog = get_parent()
	dialog.visible = false
	queue_free()
