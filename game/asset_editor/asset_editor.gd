class_name AssetEditor extends PanelContainer

@export var asset_filename: String = ""
var asset_name: String = ""
var is_new_asset = false
var asset_type : int

signal asset_updated(name: StringName)
signal fullscreen_toggled(button_pressed: bool)

var urdf_parser = URDFParser.new()
var urdf_syntaxhighlighter = URDFSyntaxHighlighter.new()
var asset_scene : PackedScene = null
var asset_node : Node3D = null:
	set(value):
		asset_node = value
		if asset_node == null:
			%SaveAssetButton.disabled = true
		else:
			%SaveAssetButton.disabled = false
var asset_base_dir: String = ProjectSettings.globalize_path("res://assets")
var package_base_dir: String = ProjectSettings.globalize_path("res://packages")

@onready var urdf_code_edit: CodeEdit = %URDFCodeEdit
@onready var preview_viewport = %PreviewViewport
@onready var preview_scene = %PreviewScene

enum NewAsset {
	STANDALONE,
	ROBOT,
	ENVIRONMENT,
}

func _ready():
	urdf_parser.scale = 10
	urdf_parser.packages_path = package_base_dir
	urdf_code_edit.syntax_highlighter = urdf_syntaxhighlighter
	
	if is_new_asset:
		%SaveAssetButton.disabled = true
		match asset_type:
			NewAsset.STANDALONE:
				urdf_code_edit.text = urdf_standalone_template
			
			NewAsset.ROBOT:
				urdf_code_edit.text = urdf_robot_template
				
			NewAsset.ENVIRONMENT:
				urdf_code_edit.text = urdf_environment_template
	else:
		var fullname = asset_filename.trim_prefix(asset_base_dir+"/")
		%AssetFilenameEdit.text = fullname.get_basename()
		asset_filename = ProjectSettings.globalize_path(asset_filename)
		var assets_path = DirAccess.open(asset_base_dir)
		if assets_path.file_exists(asset_filename):
			var reader := ZIPReader.new()
			var err := reader.open(asset_filename)
			if err != OK:
				print("[Asset Editor]: Error %d" % err )
				return
			var asset_files = reader.get_files()
			if ("urdf.xml") in asset_files:
				var res := reader.read_file("urdf.xml")
				urdf_code_edit.text = res.get_string_from_ascii()
			reader.close()
			generate_scene(urdf_code_edit.text, fullname)
			
	show_visual_mesh(%VisualCheckBox.button_pressed)
	show_collision_shape(%CollisionCheckBox.button_pressed)
	show_link_frame(%FrameCheckBox.button_pressed)
	show_joint_frame(%JointCheckBox.button_pressed)

func _on_save_button_pressed():
	if %AssetFilenameEdit.text == "":
		return
	var path = asset_base_dir.path_join(%AssetFilenameEdit.text + ".asset").get_base_dir()
	if not DirAccess.dir_exists_absolute(path):
		print("[INFO] %s not exist ()" % path)
		DirAccess.make_dir_recursive_absolute(path)
	if asset_node == null: return

	var new_asset_filename = asset_base_dir.path_join(%AssetFilenameEdit.text + ".asset")
	if FileAccess.file_exists(new_asset_filename):
		%OverwriteConfirmationDialog.popup_centered()
	else:
		asset_filename = new_asset_filename
		save_scene()

func _on_overwrite_confirmation_dialog_confirmed():
	save_scene()
		
func save_scene():
	var writer := ZIPPacker.new()
	var err := writer.open(asset_filename)
	if err != OK:
		print("[Asset Editor] Error %d opening %f" % [err, asset_filename])
		return
	
	writer.start_file("urdf.xml")
	writer.write_file(urdf_code_edit.text.to_ascii_buffer())
	writer.close_file()
	writer.close()

	var fullname = asset_filename.trim_prefix(asset_base_dir+"/")
	asset_updated.emit(fullname)

func _on_generate_button_pressed() -> void:
	var fullname = asset_filename.trim_prefix(asset_base_dir+"/")
	generate_scene(urdf_code_edit.text, fullname)
	
func generate_scene(urdf_code: String, _fullname: String, _asset_metadata: Dictionary = {}):
	var result = urdf_parser.parse_buffer(urdf_code)
	# If result return error message
	if result is String:
		%MessageContainer.visible = true
		%MessageLabel.text = result
		return
	else:
		%MessageContainer.visible = false
		
	var root_node = result
	
	if root_node == null: return
	if root_node:
		root_node.set_meta("urdf_code", urdf_code)
	
	asset_scene = PackedScene.new()
	var err = asset_scene.pack(root_node)
	
	if err == OK and %AssetFilenameEdit.text != "":
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
	# Freeing nodes
	root_node.queue_free()
	
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
	for node in preview_viewport.get_tree().get_nodes_in_group("JOINT"):
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

func _on_asset_filename_edit_text_changed(new_text):
	if new_text == "" or asset_node:
		%SaveAssetButton.disabled = true
	else:
		%SaveAssetButton.disabled = false

const urdf_robot_template = """<robot name="noname">
	<link name="base_link">
	
	</link>
	
	<gobotics>
	
	<gobotics/>
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
