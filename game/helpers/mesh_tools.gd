class_name MeshTools extends RefCounted

static var asset_aabb: AABB

static func get_bounding_box(node: Node) -> AABB:
	asset_aabb = AABB()
	return compute_aabb(node)


static func compute_aabb(node: Node) -> AABB:
	for child: Node in node.get_children():
		#print(child.name)
		if child.is_in_group("VISUAL"):
			if child.mesh:
				var child_aabb: AABB = child.mesh.get_aabb()
				#print("child aabb: %s, pos: %s" % [child_aabb, child.position])
				child_aabb.position += child.position
				#print("child aabb modified: %s, asset aabb: %s" % [child_aabb, asset_aabb])
				asset_aabb = asset_aabb.merge(child_aabb)
		
		if child.get_child_count() > 0:
			compute_aabb(child)
	
	return asset_aabb
