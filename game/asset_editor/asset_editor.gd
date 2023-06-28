extends PanelContainer

var urdf_parser = URDFParser.new()
var asset_scene : PackedScene = null
var asset_node : Node3D = null
var asset_path : String = "":
	set(value):
		asset_path = value
		asset_scene = load(asset_path)
		asset_node = asset_scene.instantiate()
		freeze_asset(asset_node, true)
		%PreviewScene.add_child(asset_node)
		%AssetNameEdit.text = asset_path.trim_prefix(assets_path+"/").trim_suffix(".tscn")
		

const assets_path = "res://assets"
const urdf_robot_template = """<robot name="noname">

</robot>
"""

@onready var urdf_code_edit: CodeEdit = %URDFCodeEdit
@onready var asset_name_edit: LineEdit = %AssetNameEdit
@onready var preview_viewport = %PreviewViewport


func _ready():
	urdf_parser.scale = 10
	urdf_parser.packages_path = assets_path.path_join("packages")
	if asset_node == null:
		%SaveAssetButton.disabled = true
		urdf_code_edit.text = urdf_robot_template
	else:
		urdf_code_edit.text = asset_node.get_meta("urdf_code", urdf_robot_template)
	show_visual_mesh(%VisualCheckBox.button_pressed)
	show_collision_shape(%CollisionCheckBox.button_pressed)

		
func _on_save_button_pressed():
	var path = assets_path.path_join(asset_name_edit.text.get_base_dir())
	if not DirAccess.dir_exists_absolute(path):
		print("%s not exist" % path)
		DirAccess.make_dir_recursive_absolute(path)
	var tscn_file: String = assets_path.path_join(asset_name_edit.text + ".tscn")
	var error = ResourceSaver.save(asset_scene, tscn_file)
	if error != OK:
		push_error("An error occurred while saving the scene to disk.")

func _on_generate_button_pressed() -> void:
	var urdf_code = urdf_code_edit.text
#	print("urdf code: ", urdf_code)
	var root_node : Node3D = urdf_parser.parse_buffer(urdf_code)
#	print("root node: ", root_node)
	root_node.set_meta("urdf_code", urdf_code)
	
	asset_scene = PackedScene.new()
	var result = asset_scene.pack(root_node)
	if result == OK:
		%SaveAssetButton.disabled = false
		if asset_name_edit.text == "":
			asset_name_edit.text = root_node.name
	else:
		%SaveAssetButton.disabled = true
		
	for child in %PreviewScene.get_children():
		if child.is_in_group("ITEMS"):
			%PreviewScene.remove_child(child)
			child.queue_free()
	asset_node = asset_scene.instantiate()
	freeze_asset(asset_node, true)
	%PreviewScene.add_child(asset_node)
	
	show_visual_mesh(%VisualCheckBox.button_pressed)
	show_collision_shape(%CollisionCheckBox.button_pressed)
	
func _on_urdf_code_edit_text_changed() -> void:
	%SaveAssetButton.disabled = true
	

func freeze_asset(root_node, frozen):
	root_node.set_physics_process(not frozen)
	freeze_children(root_node, frozen)

func freeze_children(node, frozen):
	if node is RigidBody3D:
		node.freeze = frozen
#		set_physics_process(not frozen)
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
	
func _on_visual_check_box_toggled(button_pressed):
	show_visual_mesh(button_pressed)


func _on_collision_check_box_toggled(button_pressed):
	show_collision_shape(button_pressed)
