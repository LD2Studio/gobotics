class_name MeshTools extends RefCounted

static var asset_aabb: AABB

static func get_bounding_box(node: Node3D) -> AABB:
	asset_aabb = AABB()
	return compute_aabb(node, Transform3D())


static func compute_aabb(node: Node3D, parent_tr: Transform3D) -> AABB:
	#var node_transform: Transform3D = node.transform
	for child: Node in node.get_children():
		#if not child is Node3D: continue
		#print(child.name)
		if child.is_in_group("VISUAL"):
			if child.mesh:
				var child_aabb: AABB = child.mesh.get_aabb()
				#print("child aabb: %s" % [child_aabb])
				child_aabb = parent_tr * child_aabb
				asset_aabb = asset_aabb.merge(child_aabb)
				#print("child aabb modified: %s, asset aabb: %s" % [child_aabb, asset_aabb])
		
		elif child is JoltJoint3D and child.get_child_count() > 0:
			compute_aabb(child, child.transform * parent_tr)
			
		elif child is RigidBody3D and child.get_child_count() > 0:
			compute_aabb(child, child.transform * parent_tr)
	
	return asset_aabb
