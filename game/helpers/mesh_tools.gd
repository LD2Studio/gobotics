class_name MeshTools extends RefCounted

static var _meshes: Array[Mesh]
static var _bounding_boxes: Array

static func get_bounding_box(root_node: Node3D):
	_meshes.clear()
	_bounding_boxes.clear()
	_parse_meshes(root_node)
	var merge_bounding_boxes = func():
		if _bounding_boxes.is_empty():
			return null
		var aabb: AABB = _bounding_boxes[0]
		for i in range(1, _bounding_boxes.size()):
			aabb = aabb.merge(_bounding_boxes[i])
		return aabb
	return merge_bounding_boxes.call()

static func _parse_meshes(node: Node) -> void:
	for child: Node in node.get_children():
		if child.is_in_group("VISUAL"):
			_meshes.append(child.mesh)
			var aabb: AABB = child.get_aabb()
			_bounding_boxes.append(child.global_transform * aabb)
		if child.get_child_count() > 0:
			_parse_meshes(child)
