class_name AssetEditor extends PanelContainer

var asset_name: String = ""
var meshes_list: Array
var asset_type : int

var database : GoboticsDB # Setting by caller
var asset_fullname: String # Setting by caller

signal asset_updated(name: StringName)
signal fullscreen_toggled(button_pressed: bool)

var urdf_parser = URDFParser.new()
var urdf_syntaxhighlighter = URDFSyntaxHighlighter.new()
var asset_scene : PackedScene = null
var asset_node : Node3D = null:
	set(value):
		asset_node = value
var asset_base_dir: String = ProjectSettings.globalize_path("res://assets")

@onready var urdf_code_edit: CodeEdit = %URDFCodeEdit
@onready var preview_viewport = %PreviewViewport
@onready var preview_scene = %PreviewScene
@onready var replace_mesh_dialog = %ReplaceMeshDialog
@onready var mesh_view_container = %MeshViewContainer
@onready var mesh_item_list = %MeshesList
@onready var delete_mesh_dialog = %DeleteMeshDialog

enum NewAsset {
	STANDALONE,
	ROBOT,
	ENVIRONMENT,
}

func _ready():
	mesh_view_container.visible = false
	urdf_parser.scale = 10
	urdf_code_edit.syntax_highlighter = urdf_syntaxhighlighter
	
	if not asset_fullname:
		%SaveAssetButton.disabled = true
		match asset_type:
			NewAsset.STANDALONE:
				urdf_code_edit.text = urdf_standalone_template
			
			NewAsset.ROBOT:
				urdf_code_edit.text = urdf_robot_template
				
			NewAsset.ENVIRONMENT:
				urdf_code_edit.text = urdf_environment_template
	else:
		%AssetFilenameEdit.text = asset_fullname.get_basename()
		var urdf_path = database.get_asset_filename(asset_fullname)
		
		var urdf_file = FileAccess.open(urdf_path, FileAccess.READ)
		urdf_code_edit.text = urdf_file.get_as_text()
		
		urdf_parser.gravity_scale = ProjectSettings.get_setting("physics/3d/default_gravity")/9.8
		if not generate_scene():
			printerr("[AE] creating asset failed")
		
	show_visual_mesh(%VisualCheckBox.button_pressed)
	show_collision_shape(%CollisionCheckBox.button_pressed)
	show_link_frame(%FrameCheckBox.button_pressed)
	show_joint_frame(%JointCheckBox.button_pressed)
	folding_link_tags()
	
func generate_scene() -> bool:
	if database.get_asset_filename(asset_fullname) == null:
		return false
	var asset_path = database.get_asset_filename(asset_fullname).get_base_dir()+"/"
	urdf_parser.asset_user_path = asset_path
	var error_output : Array = []
	var root_node = urdf_parser.parse(urdf_code_edit.text.to_ascii_buffer(), error_output)
	
	if root_node == null:
		printerr("[DB] URDF Parser failed")
		return false
	
	asset_scene = PackedScene.new()
	var err = asset_scene.pack(root_node)
	
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
	# Freeing orphan nodes
	root_node.queue_free()
	return true
	
func _on_generate_button_pressed() -> void:
	generate_scene()
	
func _on_save_button_pressed():
	if %AssetFilenameEdit.text == "":
		return
	var new_asset_filename = asset_base_dir.path_join(%AssetFilenameEdit.text + ".urdf")
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
	var urdf_filename = asset_base_dir.path_join(%AssetFilenameEdit.text + ".urdf")
	var urdf_file = FileAccess.open(urdf_filename, FileAccess.WRITE)
	urdf_file.store_string(urdf_code_edit.text)
	urdf_file.flush()
	
	var fullname = urdf_filename.trim_prefix(asset_base_dir+"/")
	database.update_asset(fullname)
	
func _on_overwrite_confirmation_dialog_confirmed():
	save_asset()
	
func add_mesh(mesh_data: PackedByteArray, gltf_name: String):
	meshes_list.append(
		{
			name = gltf_name,
			data = mesh_data,
		})
		
func replace_mesh(gltf_name: String, new_mesh_data: PackedByteArray):
	for mesh in meshes_list:
		if mesh.name == gltf_name:
			mesh.data = new_mesh_data
			return
	
func _on_urdf_code_edit_text_changed() -> void:
	pass
#	%SaveAssetButton.disabled = true
	
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
		
func folding_link_tags():
	for line_num in urdf_code_edit.get_line_count():
		if urdf_code_edit.can_fold_line(line_num):
			if not urdf_code_edit.get_line(line_num).begins_with("<standalone") and \
				not urdf_code_edit.get_line(line_num).begins_with("<robot") and \
				not urdf_code_edit.get_line(line_num).begins_with("<env") :
#				print("Fold line %d" % [line_num])
				urdf_code_edit.fold_line(line_num)
		
func show_joint_frame(enable: bool):
	for node in preview_viewport.get_tree().get_nodes_in_group("JOINT_GIZMO"):
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

func _on_import_mesh_button_pressed():
	%ImportMeshFileDialog.popup_centered(Vector2i(300,400))

func _on_import_mesh_file_dialog_file_selected(path: String):
#	print("mesh file: ", path)
	if path.get_extension() == "glb":
		var gltf_res := GLTFDocument.new()
		var gltf_state = GLTFState.new()
		var err = gltf_res.append_from_file(path, gltf_state)
		if err:
			return
		var gltf_data = gltf_res.generate_buffer(gltf_state)
		var gltf_name = path.get_file()
		for mesh in meshes_list:
			if mesh.name == gltf_name:
				%ReplaceMeshDialog.mesh_name = gltf_name
				%ReplaceMeshDialog.mesh_data = gltf_data
				%ReplaceMeshDialog.popup_centered()
				return
		add_mesh(gltf_data, gltf_name)
		update_mesh_item_list()

func _on_replace_mesh_dialog_confirmed():
	replace_mesh(replace_mesh_dialog.mesh_name, replace_mesh_dialog.mesh_data)
	update_mesh_item_list()

func _on_show_meshes_button_toggled(button_pressed):
	%ShowMeshesButton.text = "Hide Meshes" if button_pressed else "Show Meshes"
	update_mesh_item_list()
	mesh_view_container.visible = button_pressed

func update_mesh_item_list():
	mesh_item_list.clear()
	for mesh_item in meshes_list:
		mesh_item_list.add_item(mesh_item.name)
		
func _on_delete_mesh_button_pressed():
	if delete_mesh_dialog.mesh_name != "":
		delete_mesh_dialog.dialog_text = "Do you want to delete %s ?" % delete_mesh_dialog.mesh_name
		delete_mesh_dialog.popup_centered()

func _on_delete_mesh_dialog_confirmed():
	var list_idx = 0
	for mesh_item in meshes_list:
		if mesh_item.name == delete_mesh_dialog.mesh_name:
			meshes_list.remove_at(list_idx)
			break
		list_idx += 1
		
	update_mesh_item_list()

func _on_meshes_list_item_selected(index):
#	print("item: ", mesh_item_list.get_item_text(index))
	delete_mesh_dialog.mesh_name = mesh_item_list.get_item_text(index)


