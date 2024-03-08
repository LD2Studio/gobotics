class_name MeshTools extends RefCounted

static var asset_aabb: AABB
static var transform: Transform3D

static func get_bounding_box(node: Node) -> AABB:
	asset_aabb = AABB()
	return compute_aabb(node)


static func compute_aabb(node: Node) -> AABB:
	for child: Node in node.get_children():
		#print(child.name)
		if child.is_in_group("VISUAL"):
			if child.mesh:
				var child_aabb : AABB = child.mesh.get_aabb()
				child_aabb.position += child.position
				return child_aabb
				
				asset_aabb = asset_aabb.merge(child_aabb)
		
		if child.get_child_count() > 0:
			get_bounding_box(child)
	
	return asset_aabb
