extends Control

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris
@onready var game_scene = %GameScene

var selected_block: Node
var current_filename: String:
	set(value):
		current_filename = value
		%FilenameLabel.text = current_filename.get_file().get_basename()

func _ready():
	game_scene.focused_block.connect(_on_selected_block)

func _on_blocks_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	pass
#	print("Item clicked")

func _on_selected_block(block: Node):
#	print_debug(block)
	if block == null:
		selected_block = null
		%BlockName.text = ""
		%X_pos.editable = false
		%Y_pos.editable = false
		%Z_pos.editable = false
	else:
#		print_debug(game_scene.coord3D.transform)
		var tr = game_scene.coord3D.transform
#		print_debug("block : ", block.transform)
#		print_debug("block tr : ", block.transform * tr.inverse())
		selected_block = block
		%BlockName.text = block.name
		%X_pos.editable = true
		%Y_pos.editable = true
		%Z_pos.editable = true
		var coord_3d = game_scene.coord3D.transform
		var local_pos: Vector3 = block.transform.origin * coord_3d
		
		%X_pos.value = local_pos.x / 10.0
		%Y_pos.value = local_pos.y / 10.0
		%Z_pos.value = local_pos.z / 10.0

func _on_x_pos_value_changed(value: float) -> void:
	if selected_block == null:
		return
	var coord_3d = game_scene.coord3D.transform
#	print_debug("coord3D: ", coord_3d)
	var local_pos: Vector3 = selected_block.transform.origin * coord_3d
#	print_debug("local pos: ", local_pos)
	local_pos.x = 10.0 * value
	var new_pos_coord_3d = local_pos * coord_3d.inverse()	# Global coordinates
#	print_debug("new pos coord3D: ", new_pos_coord_3d)
	selected_block.position = new_pos_coord_3d

	
func _on_y_pos_value_changed(value: float) -> void:
	if selected_block == null:
		return
	var coord_3d = game_scene.coord3D.transform
	var local_pos: Vector3 = selected_block.transform.origin * coord_3d
#	print_debug("local pos: ", local_pos)
	local_pos.y = 10.0 * value
	var new_pos_coord_3d = local_pos * coord_3d.inverse()	# Global coordinates
#	print_debug("new pos coord3D: ", new_pos_coord_3d)
	selected_block.position = new_pos_coord_3d
	
func _on_z_pos_value_changed(value: float) -> void:
	if selected_block == null:
		return
	var coord_3d = game_scene.coord3D.transform
	var local_pos: Vector3 = selected_block.transform.origin * coord_3d
#	print_debug("local pos: ", local_pos)
	local_pos.z = 10.0 * value
	var new_pos_coord_3d = local_pos * coord_3d.inverse()	# Global coordinates
#	print_debug("new pos coord3D: ", new_pos_coord_3d)
	selected_block.position = new_pos_coord_3d
	
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
