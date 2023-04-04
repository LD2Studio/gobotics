extends SubViewportContainer


func _can_drop_data(at_position: Vector2, data) -> bool:
	return data.is_in_group("BLOCKS")

func _drop_data(at_position: Vector2, data) -> void:
	assert(%GameScene.has_node("GameLevel"), "GameLevel Node do not exists!")
	data.name = get_new_name()
	%GameScene.get_node("GameLevel").add_child(data)

func get_new_name() -> StringName:
	## Get used block name
	var block_names_used = Array()
	for block in %GameScene.get_node("GameLevel").get_children():
		block_names_used.append(block.name)
		
	var idx=0
	while (&"Block%d" % idx) in block_names_used:
		idx += 1
	
	return &"Block%d" % idx
