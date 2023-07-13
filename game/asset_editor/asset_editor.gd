extends PanelContainer

## If true, Asset extension is .asset, else .tscn
@export var is_asset_ext: bool = true
@export var asset_filename: String = ""

signal asset_updated(name: StringName)
signal fullscreen_toggled(button_pressed: bool)

var urdf_parser = URDFParser.new()
var urdf_syntaxhighlighter = URDFSyntaxHighlighter.new()
var asset_scene : PackedScene = null
var asset_node : Node3D = null
var assets_base_dir: String
var package_base_dir: String

const urdf_robot_template = """<robot name="noname">
	<link name="base_link">
	
	</link>
	
	<gobotics>
	
	<gobotics/>
</robot>
"""

@onready var urdf_code_edit: CodeEdit = %URDFCodeEdit
@onready var asset_user_path_edit: LineEdit = %AssetPathEdit
@onready var preview_viewport = %PreviewViewport
@onready var preview_scene = %PreviewScene


func _ready():
#	print("[AssetEditor] asset_filename: ", asset_filename)
	if OS.has_feature("editor"):
		assets_base_dir = ProjectSettings.globalize_path("res://assets")
		package_base_dir = ProjectSettings.globalize_path("res://packages")
	else:
		assets_base_dir = OS.get_executable_path().get_base_dir().path_join("assets")
		package_base_dir = OS.get_executable_path().get_base_dir().path_join("packages")
	if asset_filename == "":
		%SaveAssetButton.disabled = true
		urdf_code_edit.text = urdf_robot_template
	else:
		asset_user_path_edit.text = asset_filename.trim_prefix(assets_base_dir+"/").get_base_dir()
		asset_filename = ProjectSettings.globalize_path(asset_filename)
		var assets_path = DirAccess.open(assets_base_dir)
		if assets_path.file_exists(asset_filename):
			var reader := ZIPReader.new()
			var err := reader.open(asset_filename)
			if err != OK:
				print("[Asset Editor]: Error %d" % err )
				return
			var asset_name = asset_filename.get_basename().get_file()
#				print("asset_name: ", asset_name)
			var asset_files = reader.get_files()
			if (asset_name + ".urdf") in asset_files:
				var res := reader.read_file(asset_name + ".urdf")
				urdf_code_edit.text = res.get_string_from_ascii()
			reader.close()

	urdf_parser.scale = 10
	urdf_parser.packages_path = package_base_dir
#	urdf_parser.asset_user_path = asset_filename.get_base_dir()
	urdf_code_edit.syntax_highlighter = urdf_syntaxhighlighter
	generate_scene()
	show_visual_mesh(%VisualCheckBox.button_pressed)
	show_collision_shape(%CollisionCheckBox.button_pressed)
	show_link_frame(%FrameCheckBox.button_pressed)
	show_joint_frame(%JointCheckBox.button_pressed)

func _on_save_button_pressed():
	var path = assets_base_dir.path_join(asset_user_path_edit.text)
	if not DirAccess.dir_exists_absolute(path):
		print("[INFO] %s not exist ()" % path)
		DirAccess.make_dir_recursive_absolute(path)
	if asset_node == null: return
	
	var new_asset_filename = assets_base_dir.path_join(asset_user_path_edit.text.path_join(asset_node.name.to_lower() + ".asset"))
	asset_filename = ProjectSettings.globalize_path(new_asset_filename)
#	print("[ASSET EDITOR] Asset filename saving", asset_filename)
	var assets_path = DirAccess.open(assets_base_dir)
	if assets_path.file_exists(asset_filename):
		%OverwriteConfirmationDialog.popup_centered()
	else:
		save_scene()

func _on_overwrite_confirmation_dialog_confirmed():
	save_scene()
		
func save_scene():
	var writer := ZIPPacker.new()
	var err := writer.open(asset_filename)
	if err != OK:
		print("[Asset Editor] Error %d opening %f" % [err, asset_filename])
		return
	writer.start_file("%s.urdf" % [asset_node.name.to_lower()])
	writer.write_file(urdf_code_edit.text.to_ascii_buffer())
	writer.close_file()
	writer.close()

#	print("[Asset Editor] asset name: ", asset_scene.get_state().get_node_name(0))
	asset_updated.emit(asset_scene.get_state().get_node_name(0))

func _on_generate_button_pressed() -> void:
	generate_scene()
	
func generate_scene():
	var urdf_code = urdf_code_edit.text
#	print("urdf code: ", urdf_code)
	var root_node : Node3D = urdf_parser.parse_buffer(urdf_code)
#	print_debug("root node: ", root_node)
	if root_node == null: return
	if root_node:
		root_node.set_meta("urdf_code", urdf_code)
	
	asset_scene = PackedScene.new()
	var result = asset_scene.pack(root_node)
	if result == OK:
		%SaveAssetButton.disabled = false
	else:
		%SaveAssetButton.disabled = true
		
	for child in preview_scene.get_children():
		if child.is_in_group("ASSETS"):
			preview_scene.remove_child(child)
			child.queue_free()
	asset_node = asset_scene.instantiate()
	freeze_asset(asset_node, true)
	preview_scene.add_child(asset_node)
	
	show_visual_mesh(%VisualCheckBox.button_pressed)
	show_collision_shape(%CollisionCheckBox.button_pressed)
	show_link_frame(%FrameCheckBox.button_pressed)
	show_joint_frame(%JointCheckBox.button_pressed)
	
func _on_urdf_code_edit_text_changed() -> void:
	%SaveAssetButton.disabled = true
	
func freeze_asset(root_node, frozen):
	root_node.set_physics_process(not frozen)
	freeze_children(root_node, frozen)

func freeze_children(node, frozen):
	if node is RigidBody3D:
		node.freeze = frozen
	for child in node.get_children():
		freeze_children(child, frozen)

func show_visual_mesh(enable: bool):
	var scene_tree : SceneTree = preview_viewport.get_tree()
	for node in scene_tree.get_nodes_in_group("VISUAL"):
		node.visible = enable
		
func show_collision_shape(enable: bool):
	var scene_tree : SceneTree = preview_viewport.get_tree()
	for node in scene_tree.get_nodes_in_group("COLLISION"):
		node.visible = enable
		
func show_link_frame(enable: bool):
	var scene_tree : SceneTree = preview_viewport.get_tree()
	for node in scene_tree.get_nodes_in_group("FRAME"):
		node.visible = enable
		
func show_joint_frame(enable: bool):
	for node in preview_viewport.get_tree().get_nodes_in_group("JOINTS"):
		node.visible = enable
	
func _on_visual_check_box_toggled(button_pressed):
	show_visual_mesh(button_pressed)

func _on_collision_check_box_toggled(button_pressed):
	show_collision_shape(button_pressed)

func _on_link_check_box_toggled(button_pressed):
	show_link_frame(button_pressed)

func _on_joint_check_box_toggled(button_pressed):
	show_joint_frame(button_pressed)

func _on_full_screen_button_toggled(button_pressed):
	fullscreen_toggled.emit(button_pressed)
