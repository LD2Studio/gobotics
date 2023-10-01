extends SubViewportContainer
@onready var game_scene = %GameScene as Node3D

#func _input(event):
#	print("[scene viewport]: ", event.as_text())
	
func _can_drop_data(_at_position: Vector2, _data) -> bool:
	if game_scene.game_area_pointed:
		return true
	else:
		return false

func _drop_data(_at_position: Vector2, data) -> void:
	data.name = get_new_name(data.name)
	data.position = game_scene.mouse_pos_on_area
	if data.is_in_group("PYTHON"):
		data.python_script_finished.connect(game_scene._on_python_script_finished)
	game_scene.freeze_asset(data, true)
	game_scene.get_node("Scene").add_child(data)
	game_scene.connect_editable()
	game_scene.update_robot_select_menu()
	game_scene.update_camera_view_menu()
	
	var part_name = data.get_node_or_null("%PartName")
	if part_name:
		part_name.text = data.name

func get_new_name(current_name: StringName) -> StringName:
#	print(current_name)
	var block_names_used = Array()
	for block in game_scene.get_node("Scene").get_children():
		block_names_used.append(block.name)
	
	if not current_name in block_names_used:
		return current_name
	else:
		var idx=2
		while (&"%s_%d" % [current_name, idx]) in block_names_used:
			idx += 1
		return &"%s_%d" % [current_name, idx]
