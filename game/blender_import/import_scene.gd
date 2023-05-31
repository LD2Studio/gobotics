@tool
extends EditorScenePostImport

# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
	# Modify the contents of the scene upon import.
	iterate(scene)
#	var file = get_source_file()
#	print(file)
	return scene # Return the modified root node when you're done.

# Recursive function that is called on every node
# (for demonstration purposes; EditorScenePostImport only requires a `_post_import(scene)` function).
func iterate(node: Node):
	if node != null:
#		print_rich("Post-import: [b]%s[/b] -> [b]%s[/b]" % [node.name, "modified_" + node.name])
		if node.name.ends_with("-rigidbody"):
			# Replace root node
			var new_node = RigidBody3D.new()
			new_node.name = node.name.trim_suffix("-rigidbody")
			new_node.transform = node.transform
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidbody-motor"):
			var new_node = RotationActuator3D.new()
			new_node.name = node.name.trim_suffix("-rigidbody-motor")
			new_node.transform = node.transform
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidbody-hinge"):
			var new_node = RotationActuator3D.new()
			new_node.name = node.name.trim_suffix("-rigidbody-hinge")
			new_node.transform = node.transform
			new_node.actuator_type = "FREE"
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidbody-rot3dof"):
			var new_node = Rotation3DOF.new()
			new_node.name = node.name.trim_suffix("-rigidbody-rot3dof")
			new_node.transform = node.transform
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-onlymesh"):
			node.name = node.name.trim_suffix("-onlymesh")
		
		if node.name.ends_with("-onlycol"):
			var col_shape = CollisionShape3D.new()
			col_shape.name = node.name.trim_suffix("-onlycol")
			col_shape.name += "Col"
			col_shape.transform = node.transform
			var shape = ConvexPolygonShape3D.new()
			var cp: ConvexPolygonShape3D = node.mesh.create_convex_shape()
			col_shape.shape = cp
			node.replace_by(col_shape)
			
		if node.name.ends_with("-spherecol"):
			var col_shape = CollisionShape3D.new()
			col_shape.name = node.name.trim_suffix("-spherecol")
			col_shape.name += "Col"
			col_shape.transform = node.transform
			
			var boundary_box: AABB = node.get_aabb()
			var shape = SphereShape3D.new()
			shape.radius = boundary_box.size.x / 2.0
			col_shape.shape = shape
			
			var mesh_instance = node.duplicate()
			mesh_instance.name = node.name.trim_suffix("-spherecol")
			mesh_instance.name += "Mesh"
			mesh_instance.transform = Transform3D()
			node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
			
			mesh_instance.owner = node.owner
			node.replace_by(col_shape)
			
		if node.name.ends_with("-cylindercol"):
			var col_shape = CollisionShape3D.new()
			col_shape.name = node.name.trim_suffix("-cylindercol")
			col_shape.name += "Col"
			col_shape.transform = node.transform
			
			var boundary_box: AABB = node.get_aabb()
			print("Cylinder AABB: ", boundary_box)
			var shape = CylinderShape3D.new()
			shape.radius
			col_shape.shape = shape
			
			var mesh_instance = node.duplicate()
			mesh_instance.name = node.name.trim_suffix("-cylindercol")
			mesh_instance.name += "Mesh"
			mesh_instance.transform = Transform3D()
			node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
			
			mesh_instance.owner = node.owner
			node.replace_by(col_shape)
			
		if node.name.ends_with("-meshcol"):
			var col_shape = CollisionShape3D.new()
			col_shape.name = node.name.trim_suffix("-meshcol")
			col_shape.transform = node.transform
			var shape = ConvexPolygonShape3D.new()
			var cp: ConvexPolygonShape3D = node.mesh.create_convex_shape()
			col_shape.shape = cp
			
			var mesh_instance = node.duplicate()
			mesh_instance.name = &"MeshInstance3D"
			mesh_instance.transform = Transform3D()
			node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
			
			mesh_instance.owner = node.owner
			node.replace_by(col_shape)
			
		for child in node.get_children():
			iterate(child)
