extends SubViewportContainer

@onready var table = get_tree().get_nodes_in_group("TABLE").front()

func _can_drop_data(at_position: Vector2, data) -> bool:
#	print(table)
	if table and table.mouse_on_area:
		return data.is_in_group("BLOCKS")
	return false

func _drop_data(at_position: Vector2, data) -> void:
	assert(%GameScene.has_node("GameLevel"), "GameLevel Node do not exists!")
	print(table.mouse_pos_on_area)
	data.name = get_new_name()
	data.position = table.mouse_pos_on_area
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
