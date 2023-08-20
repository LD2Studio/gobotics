extends RefCounted
class_name URDFParser

var scale: float = 1.0
var asset_user_path: String
var packages_path: String
var parser = XMLParser.new()
var parse_error_message: String

var _materials: Array
## Links of robot
var links: Array
var _joints: Array
var _gobotics: Dictionary
var _script := GDScript.new()
var _filename : String
var _frame_mesh : ArrayMesh = load("res://game/gizmos/frame_arrows.res")

enum Tag {
		NONE,
		LINK,
		JOINT,
		MATERIAL,
		VISUAL,
		COLLISION,
		INERTIAL,
		GOBOTICS,
	}
	
func parse_buffer(buffer: String, asset={}):
	clear_buffer()
	var urdf_pack : PackedByteArray = buffer.to_ascii_buffer()
#	print("urdf pack: ", urdf_pack)
	var root_node = get_root_node(urdf_pack)
	if root_node == null: return
	asset.name = root_node.name
	asset.type = root_node.get_meta("type")
	load_gobotics_params(urdf_pack)
	load_materials(urdf_pack)
	if load_links(urdf_pack, root_node) != OK:
		delete_links()
		root_node.free()
		return parse_error_message
		
	load_joints(urdf_pack)
	var base_link = create_scene(root_node)
	if base_link:
		add_camera(base_link)
		root_node.add_child(base_link)
		kinematics_scene_owner_of(root_node)
		add_script_to(root_node)
		return root_node
	else:
		delete_links()
		root_node.free()
		return parse_error_message
	
## Return the root node of URDF tree <robot> or <asset>
func get_root_node(urdf_data) -> Node3D:
	var err
	if urdf_data is PackedByteArray:
		
		err = parser.open_buffer(urdf_data)
	elif urdf_data is String:
		err = parser.open(urdf_data)
	else:
		printerr("URDF format error")
		return null
	if err:
		if err == ERR_INVALID_DATA:
			printerr("XML no valid")
			return null
		printerr("Error opening URDF file: ", err)
		return null
		
	var root_node := Node3D.new()
	while true:
		if parser.read() != OK: # Ending parse XML file
			break
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			var node_name = parser.get_node_name()
			if node_name == "robot":
				var attrib = {}
				for idx in parser.get_attribute_count():
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				root_node.name = attrib.name
				root_node.set_meta("type", "robot")
				root_node.add_to_group("ASSETS", true)
				root_node.add_to_group("ROBOTS", true)
				break
				
			if node_name == "standalone":
				var attrib = {}
				for idx in parser.get_attribute_count():
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				root_node.name = attrib.name
				root_node.set_meta("type", "standalone")
				root_node.add_to_group("ASSETS", true)
				break
				
			if node_name == "env":
				var attrib = {}
				for idx in parser.get_attribute_count():
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				root_node.name = attrib.name
				root_node.set_meta("type", "env")
				root_node.add_to_group("ENVIRONMENT", true)
				break
				
	return root_node
	
func load_gobotics_params(urdf_data):
	var err
	if urdf_data is String:
		err = parser.open(urdf_data)
	elif urdf_data is PackedByteArray:
		err = parser.open_buffer(urdf_data)
		
	if err:
		printerr("Error opening URDF file: ", err)
		return

	var root_tag = Tag.NONE
	while true:
		if parser.read() != OK: # Ending parse XML file
			break
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			# Get node name
			var node_name = parser.get_node_name()
			match node_name:
				"gobotics":
					if root_tag != Tag.NONE: continue
					root_tag = Tag.GOBOTICS
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
						
				"link":
					if not root_tag == Tag.NONE: continue
					root_tag = Tag.LINK
				"joint":
					if not root_tag == Tag.NONE: continue
					root_tag = Tag.JOINT
				"control":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					_gobotics.control = {}
					if "name" in attrib:
						_gobotics.control.name = attrib.name
					if "type" in attrib:
						_gobotics.control.type = attrib.type
					_gobotics.control.max_speed = "1.0"
					
				"right_wheel":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "joint" in attrib:
						_gobotics.control.right_wheel_joint = attrib.joint
					
				"left_wheel":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "joint" in attrib:
						_gobotics.control.left_wheel_joint = attrib.joint
						
				"max_speed":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "value" in attrib:
						_gobotics.control.max_speed = attrib.value
						
				"camera":
					if root_tag != Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					_gobotics.camera = {}
					var xyz := Vector3.ZERO
					if "xyz" in attrib:
						var xyz_arr = attrib.xyz.split_floats(" ")
						xyz.x = xyz_arr[0]
						xyz.y = xyz_arr[2]
						xyz.z = -xyz_arr[1]
					_gobotics.camera.position = xyz * scale
					var rpy := Vector3.ZERO
					if "rpy" in attrib:
						var rpy_arr = attrib.rpy.split_floats(" ")
						rpy.x = rpy_arr[0]
						rpy.y = rpy_arr[2]
						rpy.z = -rpy_arr[1]
					_gobotics.camera.rotation = rpy
					
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			match node_name:
				"gobotics":
					if root_tag == Tag.GOBOTICS:
						root_tag = Tag.NONE
				"link":
					if root_tag == Tag.LINK:
						root_tag = Tag.NONE
				"joint":
					if root_tag == Tag.JOINT:
						root_tag = Tag.NONE
	
#	print("gobotics: ", JSON.stringify(_gobotics, "\t", false))

func load_materials(urdf_data):
	var err
	if urdf_data is String:
		err = parser.open(urdf_data)
	elif urdf_data is PackedByteArray:
		err = parser.open_buffer(urdf_data)
	else: return null
	if err:
		printerr("Error opening URDF file: ", err)
		return
		
	var mat_dict: Dictionary = {}
	var current_tag: int = Tag.NONE
	while true:
		if parser.read() != OK: # Ending parse XML file
			break
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			# Get node name
			var node_name = parser.get_node_name()
			
			if node_name == "link":
				current_tag = Tag.LINK
			
			if node_name == "joint":
				current_tag = Tag.JOINT
				
			if node_name == "gobotics":
				current_tag = Tag.GOBOTICS
			
			if node_name == "material" and current_tag == Tag.NONE:
				current_tag = Tag.MATERIAL
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					mat_dict[name] = value
				
				var res := StandardMaterial3D.new()
				mat_dict.res = res
				
			if node_name == "color" and not mat_dict.is_empty():
				var attrib = {}
				for idx in parser.get_attribute_count():
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
					
				var color := Color.WHITE
				if "rgba" in attrib:
					var rgba_arr = attrib.rgba.split_floats(" ")
					color.r = rgba_arr[0]
					color.g = rgba_arr[1]
					color.b = rgba_arr[2]
					color.a = rgba_arr[3]
				
				mat_dict.res.albedo_color = color
				
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			match node_name:
				"material":
					if current_tag == Tag.MATERIAL:
						current_tag = Tag.NONE
						_materials.append(mat_dict.duplicate(true))
						mat_dict.clear()
				"link":
					current_tag = Tag.NONE
				"joint":
					current_tag = Tag.NONE
				"gobotics":
					current_tag = Tag.NONE

#	print("materials: ", _materials)

func load_links(urdf_data, root_node: Node3D) -> int:
	var err
	if urdf_data is String:
		err = parser.open(urdf_data)
	elif urdf_data is PackedByteArray:
		err = parser.open_buffer(urdf_data)
	else: return ERR_DOES_NOT_EXIST
	if err:
		printerr("Error opening URDF file: ", err)
		return ERR_FILE_CANT_OPEN
		
	var link_attrib = {}
	var link: RigidBody3D
	var current_visual: MeshInstance3D
	var current_collision: CollisionShape3D
	var current_col_debug: MeshInstance3D
	var current_tag: int = Tag.NONE
	var root_tag: int = Tag.NONE
	
	while true:
		if parser.read() != OK: # Ending parse XML file
			break
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			# Get tag name
			var tag_name = parser.get_node_name()
			match tag_name:
				"link":
					if root_tag != Tag.NONE: continue
					root_tag = Tag.LINK
					link_attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						link_attrib[name] = value
						
					link = RigidBody3D.new()
					link.set_meta("orphan", true)
					if "name" in link_attrib and link_attrib.name != "":
						link.name = link_attrib.name
					else:
						printerr("No name for link!")
						return ERR_PARSE_ERROR
						
					if root_node.get_meta("type") == "standalone" or root_node.get_meta("type") == "robot":
						link.add_to_group("SELECT", true)
					if "xyz" in link_attrib:
						var xyz := Vector3.ZERO
						var xyz_arr = link_attrib.xyz.split_floats(" ")
						xyz.x = xyz_arr[0]
						xyz.y = xyz_arr[2]
						xyz.z = -xyz_arr[1]
						link.position = xyz * scale

					## Add frame gizmo
					var frame_visual := MeshInstance3D.new()
					frame_visual.name = link_attrib.name + "_frame"
					frame_visual.add_to_group("FRAME", true)
					frame_visual.mesh = _frame_mesh
					frame_visual.scale = Vector3.ONE * scale
					frame_visual.visible = false
					link.add_child(frame_visual)
				
				"inertial":
					if root_tag != Tag.LINK: continue
					current_tag = Tag.INERTIAL
					
				"mass":
					if root_tag != Tag.LINK: continue
					var mass_tag = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						mass_tag[name] = value
					if current_tag == Tag.INERTIAL:
						if mass_tag.value:
							if float(mass_tag.value) == 0:
								link.mass = 1.0
							else:
								link.mass = float(mass_tag.value)
				
				"visual":
					if root_tag != Tag.LINK: continue
					current_tag = Tag.VISUAL
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					
					current_visual = MeshInstance3D.new()
					current_visual.add_to_group("VISUAL", true)
					if "name" in attrib and attrib.name != "":
						current_visual.name = attrib.name + "_mesh"
					else:
						current_visual.name = link_attrib.name + "_mesh"
					link.add_child(current_visual)

				"collision":
					if root_tag != Tag.LINK: continue
					current_tag = Tag.COLLISION
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
						
					current_collision = CollisionShape3D.new()
					if "name" in attrib:
						current_collision.name = attrib.name + "_col"
					else:
						current_collision.name = link_attrib.name + "_col"
					link.add_child(current_collision)
					
					current_col_debug = MeshInstance3D.new()
					current_col_debug.add_to_group("COLLISION", true)
					current_col_debug.visible = false
					if "name" in attrib:
						current_col_debug.name = attrib.name + "_debug"
					else:
						current_col_debug.name = link_attrib.name + "_debug"
					link.add_child(current_col_debug)
	
				"geometry":
					if root_tag != Tag.LINK: continue
				
				"cylinder":
					if root_tag != Tag.LINK: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if current_tag == Tag.VISUAL:
						var cylinder_mesh := CylinderMesh.new()
						cylinder_mesh.bottom_radius = float(attrib.radius) * scale
						cylinder_mesh.top_radius = float(attrib.radius) * scale
						cylinder_mesh.height = float(attrib.length) * scale
						current_visual.mesh = cylinder_mesh

					elif current_tag == Tag.COLLISION:
						var cylinder_shape := CylinderShape3D.new()
						cylinder_shape.radius = float(attrib.radius) * scale
						cylinder_shape.height = float(attrib.length) * scale
						current_collision.shape = cylinder_shape
						var debug_mesh: ArrayMesh = cylinder_shape.get_debug_mesh()
						current_col_debug.mesh = debug_mesh
				
				"box":
					if root_tag != Tag.LINK: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					var size := Vector3.ONE
					if "size" in attrib:
						var size_arr = attrib.size.split_floats(" ")
						size.x = size_arr[0]
						size.y = size_arr[2]
						size.z = size_arr[1]
					if current_tag == Tag.VISUAL:
						var box_mesh := BoxMesh.new()
						box_mesh.size = size * scale
						current_visual.mesh = box_mesh

					elif current_tag == Tag.COLLISION:
						var box_shape := BoxShape3D.new()
						box_shape.size = size * scale
						current_collision.shape = box_shape
						var debug_mesh: ArrayMesh = box_shape.get_debug_mesh()
						current_col_debug.mesh = debug_mesh
					
				"sphere":
					if root_tag != Tag.LINK: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if current_tag == Tag.VISUAL:
						var sphere_mesh := SphereMesh.new()
						sphere_mesh.radius = float(attrib.radius) * scale
						sphere_mesh.height = float(attrib.radius) * scale * 2
						current_visual.mesh = sphere_mesh
					elif current_tag == Tag.COLLISION:
						var sphere_shape := SphereShape3D.new()
						sphere_shape.radius = float(attrib.radius) * scale
						current_collision.shape = sphere_shape
						var debug_mesh: ArrayMesh = sphere_shape.get_debug_mesh()
						current_col_debug.mesh = debug_mesh
					
				"mesh":
					if root_tag != Tag.LINK: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "filename" in attrib:
						match attrib.filename.get_extension():
							"obj":
								var mesh_filename = _filename.get_base_dir().path_join(attrib.filename.trim_prefix("package://"))
		#						print_debug(mesh_filename)
								var mesh: ArrayMesh = load(mesh_filename)
								if mesh:
									current_visual.mesh = mesh
									current_visual.scale = Vector3.ONE * scale
							
							"glb":
								if not "object" in attrib:
									printerr("Object attribut missing!")
									continue
								err = load_gltf(current_visual, current_collision, current_col_debug, attrib, current_tag, link.name == "world")
								if err!= OK:
									return ERR_PARSE_ERROR
							"dae":
								pass
							_:
								printerr("3D format not supported!")
						
				"origin":
					if root_tag != Tag.LINK: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					var xyz := Vector3.ZERO
					if "xyz" in attrib:
						var xyz_arr = attrib.xyz.split_floats(" ")
						xyz.x = xyz_arr[0]
						xyz.y = xyz_arr[2]
						xyz.z = -xyz_arr[1]
					var rpy := Vector3.ZERO
					if "rpy" in attrib:
						var rpy_arr = attrib.rpy.split_floats(" ")
						rpy.x = rpy_arr[0]
						rpy.y = rpy_arr[2]
						rpy.z = -rpy_arr[1]
					if current_tag == Tag.VISUAL:
						current_visual.position = xyz * scale
						current_visual.rotation = rpy
					elif current_tag == Tag.COLLISION:
						current_collision.position = xyz * scale
						current_collision.rotation = rpy
						current_col_debug.position = xyz * scale
						current_col_debug.rotation = rpy
					elif current_tag == Tag.INERTIAL:
						link.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
						link.center_of_mass = xyz * scale
				
				"material":
					if root_tag != Tag.LINK: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if current_tag == Tag.VISUAL:
						## Global material
						if "name" in attrib and attrib.name != "":
							for mat in _materials:
								if mat.name == attrib.name:
	#								print("[global material tag] current visual: ", current_visual)
									current_visual.set_surface_override_material(0, mat.res)
						## Local material
						else:
	#						print("[local material tag] current visual: ", current_visual)
							var res := StandardMaterial3D.new()
							current_visual.set_surface_override_material(0, res)
				
				"color":
					if root_tag != Tag.LINK: continue
					if current_tag == Tag.INERTIAL: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					
					if current_visual and current_visual.get_surface_override_material_count() >= 1:
						var color := Color.WHITE
						if "rgba" in attrib:
							var rgba_arr = attrib.rgba.split_floats(" ")
							color.r = rgba_arr[0]
							color.g = rgba_arr[1]
							color.b = rgba_arr[2]
							color.a = rgba_arr[3]
						var res = current_visual.get_surface_override_material(0)
						res.albedo_color = color
						current_visual.set_surface_override_material(0, res)
					
		if type == XMLParser.NODE_ELEMENT_END:
			var node_name = parser.get_node_name()
			match node_name:
				"link":
					links.append(link.duplicate())
					link.queue_free()
					root_tag = Tag.NONE
				"intertial":
					current_tag = Tag.NONE
				"visual":
					current_tag = Tag.NONE
				"collision":
					current_tag = Tag.NONE
				
#	print("links: ", JSON.stringify(links, "\t", false))
	return OK

func load_gltf(current_visual: MeshInstance3D, current_collision: CollisionShape3D, current_col_debug: MeshInstance3D, attrib: Dictionary, current_tag, trimesh=false):
	
#	if Engine.is_editor_hint():
#		var scene_filename = _filename.get_base_dir().path_join(attrib.filename.trim_prefix("package://"))
##		print_debug(scene_filename)
##		print("Editor")
#		var scene: PackedScene = load(scene_filename)
##		print_debug(scene)
#		var scene_state = scene.get_state()
##		print("node count: ", scene_state.get_node_count())
#		for idx in scene_state.get_node_count():
##			print("node name: ", scene_state.get_node_name(idx))
#			if scene_state.get_node_name(idx) == attrib.object:
#				for prop_idx in scene_state.get_node_property_count(idx):
#					var prop_name = scene_state.get_node_property_name(idx, prop_idx)
##					print("props: ", prop_name)
#					## Mesh attached to node
#					if prop_name == "mesh":
#						var mesh: ArrayMesh = scene_state.get_node_property_value(idx, prop_idx)
##						print("mesh: ", mesh)
#						if current_tag == Tag.VISUAL:
#							current_visual.mesh = mesh
#							current_visual.scale = Vector3.ONE * scale
						
#					if prop_name == "transform":
#						var tr: Transform3D = scene_state.get_node_property_value(idx, prop_idx)
##						print("tranform: ", tr)
#						var xyz: Vector3 = tr.origin
#						var rpy: Vector3 = tr.basis.get_euler()
#						if current_tag == Tag.VISUAL:
#							current_visual.position = xyz * scale
#							current_visual.rotation = rpy
	
	var gltf_filename: String
	if attrib.filename.begins_with("package://"):
		gltf_filename = packages_path.path_join(attrib.filename.trim_prefix("package://"))
#		print("gltf filename: ", gltf_filename)
	else:
		printerr("package or user path!")
	if not FileAccess.file_exists(gltf_filename):
		parse_error_message = "GLTF file not found!"
		return ERR_FILE_NOT_FOUND
	var gltf_res := GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var err = gltf_res.append_from_file(gltf_filename, gltf_state)
	if err:
		parse_error_message = "GLTF file import failed!"
		return ERR_PARSE_ERROR
		
	var nodes : Array[GLTFNode] = gltf_state.get_nodes()
	var meshes : Array[GLTFMesh] = gltf_state.get_meshes()
	var idx = 0
	
	for node in gltf_state.json.nodes:
		if node.name == attrib.object:
#			print("node.name:%s, id=%d " % [node.name, node.mesh])
			var imported_mesh : ImporterMesh = meshes[node.mesh].mesh
			var mesh: ArrayMesh = imported_mesh.get_mesh()
			if current_tag == Tag.VISUAL:
				current_visual.mesh = mesh
				if "transform" in attrib and attrib.transform == "true":
					current_visual.position = nodes[idx].position * scale
				if "scale" in attrib:
					current_visual.scale = Vector3.ONE * scale * float(attrib.scale)
				else:
					current_visual.scale = Vector3.ONE * scale
				return OK
			elif current_tag == Tag.COLLISION:
				pass
				var mdt = MeshDataTool.new()
				mdt.create_from_surface(mesh, 0)
				for i in range(mdt.get_vertex_count()):
					var vertex = mdt.get_vertex(i)
					vertex *= scale
					# Save your change.
					mdt.set_vertex(i, vertex)
				mesh.clear_surfaces()
				mdt.commit_to_surface(mesh)
				var shape
				if trimesh:
					shape = mesh.create_trimesh_shape()
				else:
					shape = mesh.create_convex_shape()
				current_collision.shape = shape
				if "transform" in attrib and attrib.transform == "true":
					current_collision.position = nodes[idx].position * scale
				var debug_mesh: ArrayMesh = shape.get_debug_mesh()
				current_col_debug.mesh = debug_mesh
				return OK
		idx += 1
	return ERR_CANT_RESOLVE
	
func load_joints(urdf_data):
	var err
	if urdf_data is String:
		err = parser.open(urdf_data)
	elif urdf_data is PackedByteArray:
		err = parser.open_buffer(urdf_data)
	else: return null
	if err:
		printerr("Error opening URDF file: ", err)
		return
	var root_tag: int = Tag.NONE
	var joint_tag = {}
	while true:
		if parser.read() != OK: # Ending parse XML file
			break
		var type = parser.get_node_type()
		
		if type == XMLParser.NODE_ELEMENT:
			# Get node name
			var node_name = parser.get_node_name()
			match node_name:
				"joint":
					root_tag = Tag.JOINT
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						joint_tag[name] = value
						
				"parent":
					if not root_tag == Tag.JOINT: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					joint_tag.parent = attrib
					
				"child":
					if not root_tag == Tag.JOINT: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					joint_tag.child = attrib
					
				"origin":
					if not root_tag == Tag.JOINT: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					var xyz := Vector3.ZERO
					if "xyz" in attrib:
						var xyz_arr = attrib.xyz.split_floats(" ")
						xyz.x = xyz_arr[0]
						xyz.y = xyz_arr[2]
						xyz.z = -xyz_arr[1]
					var rpy := Vector3.ZERO
					if "rpy" in attrib:
						var rpy_arr = attrib.rpy.split_floats(" ")
						rpy.x = rpy_arr[0]
						rpy.y = rpy_arr[2]
						rpy.z = -rpy_arr[1]
					var new_origin_dict = {
						"xyz": xyz,
						"rpy": rpy,
					}
					joint_tag.origin = new_origin_dict
					
				"axis":
					if not root_tag == Tag.JOINT: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					var axis := Vector3(1,0,0)
					if "xyz" in attrib:
						var xyz_arr = attrib.xyz.split_floats(" ")
						axis.x = xyz_arr[0]
						axis.y = xyz_arr[2]
						axis.z = -xyz_arr[1]
					joint_tag.axis = axis
						
				"limit":
					if not root_tag == Tag.JOINT: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					joint_tag.limit = {}
					if "effort" in attrib:
						joint_tag.limit.effort = attrib.effort
					if "velocity" in attrib:
						joint_tag.limit.velocity = attrib.velocity
				
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "joint":
				_joints.append(joint_tag.duplicate(true))
				joint_tag.clear()
				root_tag = Tag.NONE

#	print("joints: ", JSON.stringify(_joints, "\t", false))

func create_scene(root_node: Node3D):
	for joint in _joints:
		# search for the link that matches the parent link of joint
		var parent_name: String = joint.parent.link
		var parent_node: Node3D
		for link in links:
			if link.name == parent_name:
				parent_node = link
				link.set_meta("orphan", false) # Marked as used
		if parent_node == null:
			parse_error_message += "Joint <%s> has no parent link!" % [joint.name]
			return null
		# search for the link that matches the child link of joint
		var child_name: String = joint.child.link
		var child_node: Node3D
		for link in links:
			if link.name == child_name:
				child_node = link
				link.set_meta("orphan", false)
		if child_node == null:
			parse_error_message += "Joint <%s> has no child link!" % [joint.name]
			return null
			
		var joint_node : Joint3D
		var new_joint_basis : Basis
		if not "type" in joint:
			printerr("joint %s has no type" % joint.name)
			return null
			
		match joint.type:
			"fixed":
				joint_node = Generic6DOFJoint3D.new()
				joint_node.name = joint.name
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy

			"pin":
				joint_node = PinJoint3D.new()
				joint_node.name = joint.name
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
				
			"hinge":
				joint_node = HingeJoint3D.new()
				joint_node.name = joint.name
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
				if not "axis" in joint:
#					printerr("No axis for %s" % joint.name)
					var new_basis = Basis.looking_at(Vector3(1,0,0))
					joint_node.transform.basis = new_basis
				elif joint.axis != Vector3.UP:
					var new_basis = Basis.looking_at(joint.axis)
					joint_node.transform.basis = new_basis
					
			"continuous":
				joint_node = HingeJoint3D.new()
				joint_node.name = joint.name
				joint_node.add_to_group("CONTINUOUS", true)
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
				
				var limit_velocity : float = 1.0
				if "limit" in joint:
					if "effort" in joint.limit:
						joint_node.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, float(joint.limit.effort))
					if "velocity" in joint.limit:
						limit_velocity = float(joint.limit.velocity)
				if not "axis" in joint:
#					printerr("No axis for %s" % joint.name)
					new_joint_basis = Basis.looking_at(Vector3(1,0,0))
					joint_node.transform.basis = new_joint_basis
				elif joint.axis != Vector3.UP:
					new_joint_basis = Basis.looking_at(joint.axis)
					joint_node.transform.basis = new_joint_basis
				else:
					new_joint_basis = Basis(Vector3(1,0,0), Vector3(0,0,-1), Vector3(0,1,0))
					joint_node.transform.basis = new_joint_basis
					
				var joint_script := GDScript.new()
				joint_script.source_code = get_continuous_joint_script(child_node, limit_velocity)
				joint_node.set_script(joint_script)
				
			"revolute":
				joint_node = HingeJoint3D.new()
				joint_node.name = joint.name
				joint_node.add_to_group("REVOLUTE", true)
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
				var limit_velocity : float = 1.0
				if "limit" in joint:
					if "effort" in joint.limit:
						joint_node.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, float(joint.limit.effort))
					if "velocity" in joint.limit:
						limit_velocity = float(joint.limit.velocity)
				if not "axis" in joint:
#					printerr("No axis for %s" % joint.name)
					new_joint_basis = Basis.looking_at(Vector3(1,0,0))
					joint_node.transform.basis = new_joint_basis
				elif joint.axis != Vector3.UP:
					new_joint_basis = Basis.looking_at(joint.axis)
					joint_node.transform.basis = new_joint_basis
				else:
					new_joint_basis = Basis(Vector3(1,0,0), Vector3(0,0,-1), Vector3(0,1,0))
					joint_node.transform.basis = new_joint_basis
					
				var basis_node = Node3D.new()
				basis_node.name = joint_node.name + "_basis_inv"
				basis_node.unique_name_in_owner = true
				basis_node.transform.basis = new_joint_basis
				child_node.add_child(basis_node)
					
				var joint_script := GDScript.new()
				joint_script.source_code = get_revolute_joint_script(child_node, basis_node, limit_velocity)
				joint_node.set_script(joint_script)
				
		
		joint_node.node_a = ^"../"
		joint_node.node_b = NodePath("%s" % [child_node.name])
		joint_node.unique_name_in_owner = true
		# Add frame gizmo
		var frame_visual := MeshInstance3D.new()
		frame_visual.name = joint_node.name + "_frame"
		frame_visual.add_to_group("JOINT", true)
		frame_visual.mesh = _frame_mesh
		if new_joint_basis:
			frame_visual.transform.basis = new_joint_basis.inverse()
		frame_visual.scale = Vector3.ONE * scale
		frame_visual.visible = false
		joint_node.add_child(frame_visual)
		joint_node.add_child(child_node)
		if new_joint_basis:
			child_node.transform.basis = new_joint_basis.inverse()
		parent_node.add_child(joint_node)
		
	var base_link: RigidBody3D
	for link in links:
		if link and link.get_parent() == null:
			base_link = link
			link.set_meta("orphan", false)
			if link.name == "world":
				link.add_to_group("STATIC", true)
				link.add_to_group("PICKABLE", true)
			if root_node.get_meta("type") == "env":
				base_link.freeze = true
			break
			
	clean_links()

	return base_link
	
	
func add_camera(base_link):
	if not "camera" in _gobotics: return
	var camera := Camera3D.new()
	camera.name = &"RobotCamera"
	camera.add_to_group("CAMERA", true)
	camera.position = _gobotics.camera.position
	camera.rotation = _gobotics.camera.rotation
	var camera_script := GDScript.new()
	camera_script.source_code = follow_camera_script(_gobotics.camera.position)
	camera.set_script(camera_script)
	base_link.add_child(camera)
	
func kinematics_scene_owner_of(root_node: Node3D):
	add_owner(root_node, root_node.get_children())
	return root_node
		
func add_owner(owner_node, nodes: Array):
	for node in nodes:
		node.owner = owner_node
		if node.get_child_count():
			add_owner(owner_node, node.get_children())

func add_script_to(root_node: Node3D):
	var base_link = root_node.get_child(0)
	var ready_script = """
func _ready():
	pass"""

	var process_script = """
func _process(_delta: float):
	pass"""
	
	_script.source_code = """extends Node3D
"""

	## Control Tag
	if root_node.is_in_group("ROBOTS"):
		if not "control" in _gobotics:
			_script.source_code += """
var control : RobotExt
"""
			ready_script += """
	control = RobotExt.new()
	add_child(control)
"""
		
		elif "control" in _gobotics and "type" in _gobotics.control:
			match _gobotics.control.type:
				"diff_drive":
					_script.source_code += """
var control : RobotDiffDriveExt
"""
					ready_script += """
	control = RobotDiffDriveExt.new($%s, %%%s, %%%s, %f)""" % [
			base_link.name,
			_gobotics.control.right_wheel_joint,
			_gobotics.control.left_wheel_joint,
			float(_gobotics.control.max_speed),
			]
					ready_script += """
	add_child(control)
"""
	_script.source_code += ready_script
	_script.source_code += process_script

	root_node.set_script(_script)


func get_continuous_joint_script(child_node: Node3D, limit_velocity: float) -> String:
	var source_code = """extends HingeJoint3D
@onready var child_link: RigidBody3D = $%s
var target_velocity: float = 0.0:
	set = _target_velocity_changed
const LIMIT_VELOCITY = %d

func _ready():
	child_link.can_sleep = false
	set_flag(FLAG_ENABLE_MOTOR, true)
	set_param(PARAM_MOTOR_TARGET_VELOCITY, target_velocity)
	
func _target_velocity_changed(value: float):
	target_velocity = value
	set_param(PARAM_MOTOR_TARGET_VELOCITY, target_velocity)
""" % [child_node.name, limit_velocity]
	return source_code
	
func get_revolute_joint_script(child_node: Node3D, basis_node: Node3D, limit_velocity: float) -> String:
	var source_code = """extends HingeJoint3D
@onready var child_link: RigidBody3D = $%s
@onready var basis_inv: Node3D = %%%s
@export var target_angle: float = 0.0

var angle_step: float
var rest_angle: float
var LIMIT_VELOCITY: float = %d

func _ready():
	child_link.can_sleep = false
	set_flag(FLAG_ENABLE_MOTOR, true)
	angle_step = LIMIT_VELOCITY / Engine.physics_ticks_per_second
#	rest_angle = arm_basis.get_euler(EULER_ORDER_XYZ).z

func _physics_process(_delta):
	var child_basis: Basis = child_link.transform.basis
	var angle = (child_basis * basis_inv.transform.basis).get_euler().z
	var err = deg_to_rad(target_angle) - angle
	var speed: float
	if abs(err) > angle_step:
		speed = LIMIT_VELOCITY * sign(err)
	else:
		speed = 0
	set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, -speed)

func _target_angle_changed(value: float):
	target_angle = value
""" % [child_node.name, basis_node.name, limit_velocity]
	return source_code
	
func follow_camera_script(position: Vector3):
	var source_code = """extends Camera3D
var lerp_speed = 3.0
var target_path = "../"
var offset = Vector3%s

var target = null

func _ready():
	top_level = true
	if target_path:
		target = get_node(target_path)

func _physics_process(delta):
	if target:
		var target_xform = target.global_transform.translated_local(offset)
		global_transform = global_transform.interpolate_with(target_xform, lerp_speed * delta)
		look_at(target.global_transform.origin, target.transform.basis.y)
""" % [position]
	return source_code

func clear_buffer():
	_materials.clear()
	links.clear()
	_joints.clear()
	_gobotics.clear()
	parse_error_message = ""

func delete_links():
	for link in links:
		link.free()

func clean_links():
	for link in links:
		if link.get_meta("orphan"):
#			print("freeing %s" % link)
			link.queue_free()
