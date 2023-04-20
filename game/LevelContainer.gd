extends SubViewportContainer

func _can_drop_data(_at_position: Vector2, _data) -> bool:
	var table = get_tree().get_nodes_in_group("TABLE").front()
	if table and table.mouse_on_area:
		return true
	return false

func _drop_data(_at_position: Vector2, data) -> void:
	var table = get_tree().get_nodes_in_group("TABLE").front()
	data.name = get_new_name()
	data.position = table.mouse_pos_on_area
	%GameScene.get_node("Scene").add_child(data)

func get_new_name() -> StringName:
	## Get used block name
	var block_names_used = Array()
	for block in %GameScene.get_node("Scene").get_children():
		block_names_used.append(block.name)
		
	var idx=0
	while (&"Block%d" % idx) in block_names_used:
		idx += 1
	
	return &"Block%d" % idx
