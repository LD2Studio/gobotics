extends SubViewportContainer
@onready var game_scene = %GameScene as Node3D

var offset_pos : Vector3

func _can_drop_data(_at_position: Vector2, node) -> bool:
	if game_scene.game_area_pointed:
		if game_scene.asset_dragged == null:
			game_scene.asset_dragged = node.duplicate()
			game_scene.freeze_asset(game_scene.asset_dragged, true)
			game_scene.enable_pickable(game_scene.asset_dragged, false)
			game_scene.get_node("Scene").add_child(game_scene.asset_dragged)
			offset_pos = game_scene.calculate_position_on_floor(game_scene.asset_dragged)
			
#		print("can drop in ", game_scene.mouse_pos_on_area)
		return true
	else:
#		print("no drop")
		if game_scene.asset_dragged:
			game_scene.get_node("Scene").remove_child(game_scene.asset_dragged)
			game_scene.asset_dragged.queue_free()
			game_scene.asset_dragged = null
		return false

func _drop_data(_at_position: Vector2, data) -> void:
	# Remove ghost asset
	game_scene.get_node("Scene").remove_child(game_scene.asset_dragged)
	game_scene.asset_dragged.queue_free()
	game_scene.asset_dragged = null
	
	data.name = get_new_name(data.name)
	data.position = game_scene.mouse_pos_on_area + offset_pos
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
		var idx=1
		while (&"%s_%03d" % [current_name, idx]) in block_names_used:
			idx += 1
		return &"%s_%03d" % [current_name, idx]


func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if game_scene.asset_dragged:
			# Remove ghost asset
			game_scene.get_node("Scene").remove_child(game_scene.asset_dragged)
			game_scene.asset_dragged.queue_free()
			game_scene.asset_dragged = null
		
