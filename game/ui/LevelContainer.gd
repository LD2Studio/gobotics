extends SubViewportContainer

@onready var sub_viewport: SubViewport = $SubViewport

func _can_drop_data(at_position: Vector2, data) -> bool:
	return data.is_in_group("BLOCKS")

func _drop_data(at_position: Vector2, data) -> void:
	var game_area = sub_viewport.get_child(0)
	game_area.add_child(data)
	game_area.save_tscn()
