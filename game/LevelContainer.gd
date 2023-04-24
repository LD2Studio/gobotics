extends SubViewportContainer
@onready var game_scene = %GameScene as Node3D

func _can_drop_data(_at_position: Vector2, _data) -> bool:
	if game_scene.game_area_pointed:
		return true
	else:
		return false

func _drop_data(_at_position: Vector2, data) -> void:
	data.name = get_new_name()
	data.position = game_scene.mouse_pos_on_area
	game_scene.freeze_item(data, true)
	game_scene.get_node("Scene").add_child(data)

func get_new_name() -> StringName:
	## Get used block name
	var block_names_used = Array()
	for block in %GameScene.get_node("Scene").get_children():
		block_names_used.append(block.name)
		
	var idx=0
	while (&"Block%d" % idx) in block_names_used:
		idx += 1
	
	return &"Block%d" % idx
