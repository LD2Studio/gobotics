extends SubViewportContainer

@onready var game_scene = %GameScene as Node3D

var _offset_pos : Vector3
var _base_link: RigidBody3D = null

func _can_drop_data(_at_position: Vector2, node: Variant) -> bool:
	#print("[SV] node: ", node)
	var result = get_collider(game_scene)
	#print("[SV] result: ", result)
	if result != {}:
		if game_scene.asset_dragged == null:
			game_scene.asset_dragged = node.duplicate()
			game_scene.set_physics(game_scene.asset_dragged, true)
			game_scene.get_node("Scene").add_child(game_scene.asset_dragged)
			if game_scene.asset_dragged.is_in_group("ROBOTS"):
				_offset_pos = Vector3.ZERO
			else:
				_offset_pos = game_scene.asset_dragged.get_meta("offset_pos", Vector3.ZERO)
			#print("[SV] offset pos: ", offset_pos)
			_base_link = game_scene.asset_dragged.get_children().filter(
				func(child): return child.is_in_group("BASE_LINK")).front()
		if _base_link:
			_base_link.position = result.position + _offset_pos
		return true
	else:
		if game_scene.asset_dragged:
			game_scene.get_node("Scene").remove_child(game_scene.asset_dragged)
			game_scene.asset_dragged.queue_free()
			game_scene.asset_dragged = null
			_base_link = null
		return false


func _drop_data(_at_position: Vector2, data) -> void:
	var asset = data as Node
	
	# Remove ghost asset
	var asset_pos = _base_link.position
	game_scene.get_node("Scene").remove_child(game_scene.asset_dragged)
	game_scene.asset_dragged.queue_free()
	game_scene.asset_dragged = null
	_base_link = null
	
	var base_link = asset.get_children().filter(
				func(child): return child.is_in_group("BASE_LINK")).front()
	asset.name = get_new_name(asset.name)
	base_link.position = asset_pos
	if asset.is_in_group("ROBOTS"):
		asset.set_meta("udp_port", game_scene.get_available_udp_port())
	else:
		asset.set_meta("udp_port", null)
	game_scene.set_physics(asset, true)
	game_scene.get_node("Scene").add_child(asset)
	game_scene.update_robot_select_menu()
	game_scene.update_camera_view_menu()
	
	var part_name = asset.get_node_or_null("%PartName")
	if part_name:
		part_name.text = asset.name
		
	game_scene.save_project()


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


func get_collider(scene: Node3D):
	var mouse_pos: Vector2 = scene.get_viewport().get_mouse_position()
	var ray_origin = scene.get_viewport().get_camera_3d().project_ray_origin(mouse_pos)
	var ray_direction = scene.get_viewport().get_camera_3d().project_ray_normal(mouse_pos)
	# Collision shape is in SELECTION Layer (mask 8)
	var ray_quering = PhysicsRayQueryParameters3D.create(
		ray_origin, ray_origin + ray_direction * 1000, 0b0010)
	return scene.get_world_3d().direct_space_state.intersect_ray(ray_quering)
