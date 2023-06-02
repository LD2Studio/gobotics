@tool
extends EditorScenePostImport

# Called by the editor when a scene has this script set as the import script in the import tab.
func _post_import(scene: Node) -> Object:
	# Modify the contents of the scene upon import.
	iterate(scene)
	var file: String = get_source_file().get_file().trim_suffix(".blend").to_pascal_case()
#	print(file)
	scene.name = file
	return scene # Return the modified root node when you're done.

# Recursive function that is called on every node
# (for demonstration purposes; EditorScenePostImport only requires a `_post_import(scene)` function).
func iterate(node: Node):
	if node != null:
#		print_rich("Post-import: [b]%s[/b] -> [b]%s[/b]" % [node.name, "modified_" + node.name])

		## RigidBody
		if node.name.ends_with("-rigid"):
			# Replace root node
			var new_node = RigidBody3D.new()
			new_node.name = node.name.trim_suffix("-rigid")
			new_node.transform = node.transform
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidmeshcol"):
			if node is MeshInstance3D:
				# Replace root node
				var new_node = RigidBody3D.new()
				new_node.name = node.name.trim_suffix("-rigidmeshcol")
				new_node.transform = node.transform
				
				var mesh_instance = node.duplicate()
				mesh_instance.name = new_node.name + "Mesh"
				mesh_instance.transform = Transform3D()
				node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
				mesh_instance.owner = node.owner
				
				var col_shape = CollisionShape3D.new()
				col_shape.name = new_node.name + "Col"
				col_shape.transform = Transform3D()
				var shape = ConvexPolygonShape3D.new()
				var cp: ConvexPolygonShape3D = node.mesh.create_convex_shape()
				col_shape.shape = cp
				node.add_child(col_shape, true, Node.INTERNAL_MODE_FRONT)
				col_shape.owner = node.owner
				
				node.replace_by(new_node)
				node = new_node
				
		if node.name.ends_with("-rigidmeshcolsphere"):
			if node is MeshInstance3D:
				# Replace root node
				var new_node = RigidBody3D.new()
				new_node.name = node.name.trim_suffix("-rigidmeshcolsphere")
				new_node.transform = node.transform
				
				var mesh_instance = node.duplicate()
				mesh_instance.name = new_node.name + "Mesh"
				mesh_instance.transform = Transform3D()
				node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
				mesh_instance.owner = node.owner
				
				var col_shape = CollisionShape3D.new()
				col_shape.name = new_node.name + "Col"
				col_shape.transform = Transform3D()
				var boundary_box: AABB = node.get_aabb()
				var shape = SphereShape3D.new()
				shape.radius = boundary_box.size.x / 2.0
				col_shape.shape = shape
				node.add_child(col_shape, true, Node.INTERNAL_MODE_FRONT)
				col_shape.owner = node.owner
				
				node.replace_by(new_node)
				node = new_node
			
		if node.name.ends_with("-rigidmeshcolcylinder"):
			if node is MeshInstance3D:
				# Replace root node
				var new_node = RigidBody3D.new()
				new_node.name = node.name.trim_suffix("-rigidmeshcolcylinder")
				new_node.transform = node.transform
				
				var mesh_instance = node.duplicate()
				mesh_instance.name = new_node.name + "Mesh"
				mesh_instance.transform = Transform3D()
				node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
				mesh_instance.owner = node.owner
				
				var col_shape = CollisionShape3D.new()
				col_shape.name = new_node.name + "Col"
				col_shape.transform = Transform3D()
				
				var boundary_box: AABB = node.get_aabb()
				var shape = CylinderShape3D.new()
				shape.radius = boundary_box.size.x / 2.0
				shape.height = boundary_box.size.y
				col_shape.shape = shape
				
				node.add_child(col_shape, true, Node.INTERNAL_MODE_FRONT)
				col_shape.owner = node.owner
				
				node.replace_by(new_node)
				node = new_node
		
		if node.name.ends_with("-rigidmesh"):
			# Replace root node
			var new_node = RigidBody3D.new()
			new_node.name = node.name.trim_suffix("-rigidmesh")
			new_node.transform = node.transform
			
			var mesh_instance = node.duplicate()
			mesh_instance.name = new_node.name + "Mesh"
			mesh_instance.transform = Transform3D()
			node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
			mesh_instance.owner = node.owner
			
			node.replace_by(new_node)
			node = new_node
			
		## RigidBody with joints
		if node.name.ends_with("-rigidjoint_motoryrot"):
			var new_node = RotationActuator3D.new()
			new_node.name = node.name.trim_suffix("-rigidjoint_motoryrot")
			new_node.transform = node.transform
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidjoint_motorxrot"):
			var new_node = RotationActuator3D.new()
			new_node.name = node.name.trim_suffix("-rigidjoint_motorxrot")
			new_node.rotation_axis = "X"
			new_node.transform = node.transform
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidjoint_motor-xrot"):
			var new_node = RotationActuator3D.new()
			new_node.name = node.name.trim_suffix("-rigidjoint_motor-xrot")
			new_node.rotation_axis = "-X"
			new_node.transform = node.transform
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidjoint_freeyrot"):
			var new_node = RotationActuator3D.new()
			new_node.name = node.name.trim_suffix("-rigidjoint_freeyrot")
			new_node.transform = node.transform
			new_node.actuator_type = "FREE"
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidjoint_freexrot"):
			var new_node = RotationActuator3D.new()
			new_node.name = node.name.trim_suffix("-rigidjoint_freexrot")
			new_node.transform = node.transform
			new_node.rotation_axis = "X"
			new_node.actuator_type = "FREE"
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidjoint_freezrot"):
			var new_node = RotationActuator3D.new()
			new_node.name = node.name.trim_suffix("-rigidjoint_freezrot")
			new_node.transform = node.transform
			new_node.rotation_axis = "Y"
			new_node.actuator_type = "FREE"
			node.replace_by(new_node)
			node = new_node
			
		if node.name.ends_with("-rigidjoint_freexyzrot"):
			var new_node = Rotation3DOF.new()
			new_node.name = node.name.trim_suffix("-rigidjoint_freexyzrot")
			new_node.transform = node.transform
			node.replace_by(new_node)
			node = new_node
			
		## Shape Collision
		if node.name.ends_with("-meshcol"):
			var col_shape = CollisionShape3D.new()
			col_shape.name = node.name.trim_suffix("-meshcol") + "Col"
			col_shape.transform = node.transform
			var shape = ConvexPolygonShape3D.new()
			var cp: ConvexPolygonShape3D = node.mesh.create_convex_shape()
			col_shape.shape = cp
			
			var mesh_instance = node.duplicate()
			mesh_instance.name = node.name.trim_suffix("-meshcol") + "Mesh"
			mesh_instance.transform = Transform3D()
			node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
			
			mesh_instance.owner = node.owner
			node.replace_by(col_shape)
			
		if node.name.ends_with("-meshcolsphere"):
			var col_shape = CollisionShape3D.new()
			col_shape.name = node.name.trim_suffix("-meshcolsphere") + "Col"
			col_shape.transform = node.transform
			
			var boundary_box: AABB = node.get_aabb()
			var shape = SphereShape3D.new()
			shape.radius = boundary_box.size.x / 2.0
			col_shape.shape = shape
			
			var mesh_instance = node.duplicate()
			mesh_instance.name = node.name.trim_suffix("-meshcolsphere") + "Mesh"
			mesh_instance.transform = Transform3D()
			node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
			
			mesh_instance.owner = node.owner
			node.replace_by(col_shape)
			
		if node.name.ends_with("-meshcolcylinder"):
			var col_shape = CollisionShape3D.new()
			col_shape.name = node.name.trim_suffix("-meshcolcylinder") + "Col"
			col_shape.transform = node.transform
			
			var boundary_box: AABB = node.get_aabb()
			var shape = CylinderShape3D.new()
			shape.radius = boundary_box.size.x / 2.0
			shape.height = boundary_box.size.y
			col_shape.shape = shape
			
			var mesh_instance = node.duplicate()
			mesh_instance.name = node.name.trim_suffix("-meshcolcylinder") + "Mesh"
			mesh_instance.transform = Transform3D()
			node.add_child(mesh_instance, true, Node.INTERNAL_MODE_FRONT)
			
			mesh_instance.owner = node.owner
			node.replace_by(col_shape)
			
		if node.name.ends_with("-mesh"):
			node.name = node.name.trim_suffix("-mesh") + "Mesh"
			
		
		if node.name.ends_with("-shapecol"):
			if node is MeshInstance3D:
				var col_shape = CollisionShape3D.new()
				col_shape.name = node.name.trim_suffix("-shapecol") + "Col"
				col_shape.transform = node.transform
				var shape = ConvexPolygonShape3D.new()
				var cp: ConvexPolygonShape3D = node.mesh.create_convex_shape()
				col_shape.shape = cp
				node.replace_by(col_shape)
			
		if node.name.ends_with("-spherecol"):
			if node is MeshInstance3D:
				var col_shape = CollisionShape3D.new()
				col_shape.name = node.name.trim_suffix("-spherecol")
				col_shape.name += "Col"
				col_shape.transform = node.transform
				
				var boundary_box: AABB = node.get_aabb()
				var shape = SphereShape3D.new()
				shape.radius = boundary_box.size.x / 2.0
				col_shape.shape = shape
			
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
			

		for child in node.get_children():
			iterate(child)
