class_name AssetEditor extends PanelContainer

@export var asset_filename: String = ""
var asset_name: String = ""
var meshes_list: Array
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
			var files = reader.get_files()
			if ("urdf.xml") in files:
				var res := reader.read_file("urdf.xml")
				urdf_code_edit.text = res.get_string_from_ascii()
			for file in files:
				if file.get_extension() == "glb":
					var res := reader.read_file(file)
					meshes_list.append(
						{
							name = file,
							data = res,
						}
					)
			reader.close()
			urdf_parser.meshes_list = meshes_list
			urdf_parser.gravity_scale = ProjectSettings.get_setting("physics/3d/default_gravity")/9.8
			generate_scene(urdf_code_edit.text, fullname)
			
	show_visual_mesh(%VisualCheckBox.button_pressed)
	show_collision_shape(%CollisionCheckBox.button_pressed)
	show_link_frame(%FrameCheckBox.button_pressed)
	show_joint_frame(%JointCheckBox.button_pressed)
	folding_link_tags()
	

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
	var err
	err = writer.open(asset_filename, ZIPPacker.APPEND_CREATE)
	if err != OK:
		print("[Asset Editor] Error %d opening %s" % [err, asset_filename])
		return
	writer.start_file("urdf.xml")
	writer.write_file(urdf_code_edit.text.to_ascii_buffer())
	writer.close_file()
	
	for mesh in meshes_list:
		writer.start_file(mesh.name)
		writer.write_file(mesh.data)
		writer.close_file()
		
	writer.close()

	var fullname = asset_filename.trim_prefix(asset_base_dir+"/")
	asset_updated.emit(fullname)
	
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

func _on_generate_button_pressed() -> void:
	var fullname = asset_filename.trim_prefix(asset_base_dir+"/")
	generate_scene(urdf_code_edit.text, fullname)
	
func generate_scene(urdf_code: String, _fullname: String, _asset_metadata: Dictionary = {}):
	var root_node = urdf_parser.parse_buffer(urdf_code)
	# If result return error message
	if root_node is String:
		%MessageContainer.visible = true
		%MessageLabel.text = root_node
		return
	else:
		%MessageContainer.visible = false
	
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
	# Freeing orphan nodes
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


