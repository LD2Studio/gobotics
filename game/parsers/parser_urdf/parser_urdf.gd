class_name URDFParser extends RefCounted

var scale: float = 1.0
var gravity_scale: float = 1.0
var asset_user_path: String
var meshes_list: Array
var parser = XMLParser.new()
var parse_error_message: String

var _materials: Array
var _links: Array
var _joints: Array
var _sensors: Array
var _gobotics: Array
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
		SENSOR,
		RAY,
		GOBOTICS,
	}

func parse(urdf_data: PackedByteArray, _error_output: Array = []) -> Node3D:
	clear_buffer()
	var root_node : Node3D = get_root_node(urdf_data)
	if root_node == null:
		printerr("[PARSER] root node not founded")
		return null
	parse_gobotics_params(urdf_data)
	parse_materials(urdf_data)
	if parse_links(urdf_data, root_node.get_meta("type")) != OK:
		delete_links()
		root_node.free()
		return null
	parse_joints(urdf_data)
	parse_sensors(urdf_data)
	var base_link = create_asset_scene(root_node)
	if base_link:
		if root_node.is_in_group("ROBOTS"):
			add_root_script_to(root_node)
			add_python_bridge(root_node)
			add_robot_base(root_node)
			add_gobotics_control(root_node)
			add_camera_on_robot(root_node, base_link)
		root_node.add_child(base_link)
		root_node.set_meta("offset_pos", Vector3.ZERO)
		kinematics_scene_owner_of(root_node)
		return root_node
	else:
		delete_links()
		root_node.free()
		return null
	
## Return the root node of URDF tree
func get_root_node(urdf_data: PackedByteArray) -> Node3D:
	var parse_err = parser.open_buffer(urdf_data)
	if parse_err:
		printerr("[PARSER] parse error ", parse_err)
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
	
func parse_gobotics_params(urdf_path: PackedByteArray):
	var parse_err = parser.open_buffer(urdf_path)
	if parse_err:
		printerr("[PARSER] parse error ", parse_err)
		return null
	var gobotics_types = [
		"diff_drive",
		"4_mecanum_drive",
		"grouped_joints",
	]
	var root_tag: int = Tag.NONE
	var gobotics_attrib = {}
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
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						gobotics_attrib[name] = value
					if "name" in gobotics_attrib:
						gobotics_attrib.name = gobotics_attrib.name.replace(" ", "_")
					if not "type" in gobotics_attrib:
						printerr("no type in gobotics tag")
						root_tag = Tag.NONE
						continue
					if "type" in gobotics_attrib:
						if not gobotics_attrib.type in gobotics_types:
							printerr("%s not recognized!" % [gobotics_attrib.type])
							root_tag = Tag.NONE
							continue
				"link":
					if not root_tag == Tag.NONE: continue
					root_tag = Tag.LINK
				"joint":
					if not root_tag == Tag.NONE: continue
					root_tag = Tag.JOINT
					
				"right_wheel":
					if not root_tag == Tag.GOBOTICS: continue
					if "type" in gobotics_attrib and gobotics_attrib.type == "diff_drive":
						var attrib: Dictionary = {}
						for idx in parser.get_attribute_count():
							var name = parser.get_attribute_name(idx)
							var value = parser.get_attribute_value(idx)
							attrib[name] = value
						if "joint" in attrib:
							gobotics_attrib.right_wheel_joint = attrib.joint
					
				"left_wheel":
					if not root_tag == Tag.GOBOTICS: continue
					if "type" in gobotics_attrib and gobotics_attrib.type == "diff_drive":
						var attrib: Dictionary = {}
						for idx in parser.get_attribute_count():
							var name = parser.get_attribute_name(idx)
							var value = parser.get_attribute_value(idx)
							attrib[name] = value
						if "joint" in attrib:
							gobotics_attrib.left_wheel_joint = attrib.joint
							
				"front_right_wheel":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "joint" in attrib:
						gobotics_attrib.front_right_wheel_joint = attrib.joint
				
				"front_left_wheel":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "joint" in attrib:
						gobotics_attrib.front_left_wheel_joint = attrib.joint
							
				"back_right_wheel":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "joint" in attrib:
						gobotics_attrib.back_right_wheel_joint = attrib.joint
				
				"back_left_wheel":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "joint" in attrib:
						gobotics_attrib.back_left_wheel_joint = attrib.joint
						
				"max_speed":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "value" in attrib:
						gobotics_attrib.max_speed = attrib.value
					
				"input":
					if not root_tag == Tag.GOBOTICS: continue
					if "type" in gobotics_attrib and gobotics_attrib.type == "grouped_joints":
						var attrib: Dictionary = {}
						for idx in parser.get_attribute_count():
							var name = parser.get_attribute_name(idx)
							var value = parser.get_attribute_value(idx)
							attrib[name] = value
						if "name" in attrib:
							gobotics_attrib.input = attrib.name
						if "lower" in attrib:
							gobotics_attrib.lower = attrib.lower
						else:
							gobotics_attrib.lower = -1.0
						if "upper" in attrib:
							gobotics_attrib.upper = attrib.upper
						else:
							gobotics_attrib.upper = 1.0
					
				"output":
					if not root_tag == Tag.GOBOTICS: continue
					if "type" in gobotics_attrib and gobotics_attrib.type == "grouped_joints":
						var attrib: Dictionary = {}
						for idx in parser.get_attribute_count():
							var name = parser.get_attribute_name(idx)
							var value = parser.get_attribute_value(idx)
							attrib[name] = value
						if "joint" in attrib:
							if not "outputs" in gobotics_attrib:
								gobotics_attrib.outputs = []
							gobotics_attrib.outputs.append(attrib)
								
					
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			match node_name:
				"gobotics":
					if root_tag == Tag.GOBOTICS:
						_gobotics.append(gobotics_attrib.duplicate(true))
						gobotics_attrib.clear()
						root_tag = Tag.NONE
				"link":
					if root_tag == Tag.LINK:
						root_tag = Tag.NONE
				"joint":
					if root_tag == Tag.JOINT:
						root_tag = Tag.NONE
	
#	print("gobotics: ", JSON.stringify(_gobotics, "\t", false))

func parse_materials(urdf_path: PackedByteArray):
	var parse_err = parser.open_buffer(urdf_path)
	if parse_err:
		printerr("[PARSER] parse error ", parse_err)
		return null
		
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

func parse_links(urdf_data: PackedByteArray, asset_type: String) -> int:
	var parse_err = parser.open_buffer(urdf_data)
	if parse_err:
		printerr("[PARSER] parse error ", parse_err)
		return ERR_PARSE_ERROR
		
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
						var value : String = parser.get_attribute_value(idx)
						link_attrib[name] = value
						
					if "extends" in link_attrib:
						match link_attrib.extends:
							"right_mecanum_wheel":
#								print("Right Mecanum Wheel")
								link = load("res://game/builtins/right_mecanum_wheel.tscn").instantiate()
							"left_mecanum_wheel":
#								print("Left Mecanum Wheel")
								link = load("res://game/builtins/left_mecanum_wheel.tscn").instantiate()
							_:
								printerr("Unrecognized extends link!")
								return ERR_PARSE_ERROR
					
					else:
						link = RigidBody3D.new()
					var physics_material = PhysicsMaterial.new()
					link.physics_material_override = physics_material
					link.set_meta("orphan", true)
					link.set_meta("owner", true)
					if "name" in link_attrib and link_attrib.name != "":
						link.name = link_attrib.name.replace(" ", "_")
					else:
						printerr("No name for link!")
						return ERR_PARSE_ERROR
						
					if asset_type == "standalone" or asset_type == "robot":
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
					frame_visual.set_meta("owner", true)
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
								
				"friction":
					if root_tag != Tag.LINK: continue
					if current_tag == Tag.INERTIAL:
						var attrib = {}
						for idx in parser.get_attribute_count():
							var name = parser.get_attribute_name(idx)
							var value = parser.get_attribute_value(idx)
							attrib[name] = value
						if attrib.value:
							link.physics_material_override.friction = float(attrib.value)
				
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
					current_visual.set_meta("owner", true)
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
					current_collision.set_meta("owner", true)
					link.add_child(current_collision)
					
					current_col_debug = MeshInstance3D.new()
					current_col_debug.add_to_group("COLLISION", true)
					current_col_debug.visible = false
					if "name" in attrib:
						current_col_debug.name = attrib.name + "_debug"
					else:
						current_col_debug.name = link_attrib.name + "_debug"
					current_col_debug.set_meta("owner", true)
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
								if current_tag == Tag.VISUAL:
									var mesh: ArrayMesh = get_mesh_from_gltf(attrib)
									if mesh == null:
										printerr("Failed to load mesh into gltf")
										continue
									current_visual.mesh = mesh
									current_visual.scale = Vector3.ONE * scale
								elif current_tag == Tag.COLLISION:
									var shape: Shape3D = get_shape_from_gltf(attrib, current_col_debug, link.name == "world")
									if shape == null:
										printerr("Failed to load shape into gltf")
										continue
									current_collision.shape = shape
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
					if current_visual.get_surface_override_material_count() == 0: continue
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
						if current_visual.get_surface_override_material(0) == null:
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
						if res:
							res.albedo_color = color
							current_visual.set_surface_override_material(0, res)
						
		if type == XMLParser.NODE_ELEMENT_END:
			var node_name = parser.get_node_name()
			match node_name:
				"link":
					_links.append(link.duplicate())
					link.queue_free()
					root_tag = Tag.NONE
				"intertial":
					current_tag = Tag.NONE
				"visual":
					current_tag = Tag.NONE
				"collision":
					current_tag = Tag.NONE
				
#	print("links: ", JSON.stringify(_links, "\t", false))
	return OK
	
func get_mesh_from_gltf(attrib: Dictionary) -> ArrayMesh:
	if attrib.filename.begins_with("package://"):
		printerr("[PARSER] not available yet")
		return null
	
	var gltf_res := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	var gltf_filename : String = asset_user_path.path_join(attrib.filename)
#	print("[PU] gltf filename: ", gltf_filename)
	var err = gltf_res.append_from_file(gltf_filename, gltf_state)
	if err:
		printerr("gltf from buffer failed!")
		parse_error_message = "GLTF file import failed!"
		return null
		
	var meshes : Array[GLTFMesh] = gltf_state.get_meshes()
	
	if gltf_state.json.nodes.is_empty():
		printerr("[PARSER] gltf is empty")
		return null
		
	var active_node = gltf_state.json.nodes[0]
	
	var imported_mesh : ImporterMesh = meshes[active_node.mesh].mesh
	var mesh: ArrayMesh = imported_mesh.get_mesh()
	
	# To avoid orphan nodes created by append_from_file()
	var scene_node = gltf_res.generate_scene(gltf_state)
	scene_node.queue_free()

	return mesh
	
func get_shape_from_gltf(attrib, debug_col = null,  trimesh=false) -> Shape3D:
	if attrib.filename.begins_with("package://"):
		printerr("[PARSER] not available yet")
		return null
		
	var gltf_res := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	var gltf_filename : String = asset_user_path + attrib.filename
	var err = gltf_res.append_from_file(gltf_filename, gltf_state)
	if err:
		printerr("gltf from buffer failed")
		parse_error_message = "GLTF file import failed!"
		return null
	
	var meshes : Array[GLTFMesh] = gltf_state.get_meshes()
	if gltf_state.json.nodes.is_empty():
		printerr("[PARSER] gltf is empty")
		return null
		
	var active_node = gltf_state.json.nodes[0]
	
	var imported_mesh : ImporterMesh = meshes[active_node.mesh].mesh
	var mesh: ArrayMesh = imported_mesh.get_mesh()
	# 
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(mesh, 0)
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		vertex *= scale
		# Save your change.
		mdt.set_vertex(i, vertex)
	mesh.clear_surfaces()
	mdt.commit_to_surface(mesh)
	#
	var shape: Shape3D
	if trimesh:
		shape = mesh.create_trimesh_shape()
	else:
		shape = mesh.create_convex_shape()
	if debug_col:
		var debug_mesh = shape.get_debug_mesh()
		debug_col.mesh = debug_mesh
	# To avoid orphan nodes created by append_from_file()
	var scene_node = gltf_res.generate_scene(gltf_state)
	scene_node.queue_free()
	
	return shape

#func load_gltf(current_visual: MeshInstance3D, current_collision: CollisionShape3D, current_col_debug: MeshInstance3D, attrib: Dictionary, current_tag, trimesh=false):
	
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
	
#	var gltf_filename: String
#
#	if not FileAccess.file_exists(gltf_filename):
#		parse_error_message = "GLTF file not found!"
#		return ERR_FILE_NOT_FOUND
#	var gltf_res := GLTFDocument.new()
#	var gltf_state = GLTFState.new()
#	var err = gltf_res.append_from_file(gltf_filename, gltf_state)
#	if err:
#		parse_error_message = "GLTF file import failed!"
#		return ERR_PARSE_ERROR
#
#	var nodes : Array[GLTFNode] = gltf_state.get_nodes()
#	var meshes : Array[GLTFMesh] = gltf_state.get_meshes()
#	var idx = 0
#
#	for node in gltf_state.json.nodes:
#		if node.name == attrib.object:
##			print("node.name:%s, id=%d " % [node.name, node.mesh])
#			var imported_mesh : ImporterMesh = meshes[node.mesh].mesh
#			var mesh: ArrayMesh = imported_mesh.get_mesh()
#			if current_tag == Tag.VISUAL:
#				current_visual.mesh = mesh
#				if "transform" in attrib and attrib.transform == "true":
#					current_visual.position = nodes[idx].position * scale
#				if "scale" in attrib:
#					current_visual.scale = Vector3.ONE * scale * float(attrib.scale)
#				else:
#					current_visual.scale = Vector3.ONE * scale
#				return OK
#			elif current_tag == Tag.COLLISION:
#				var mdt = MeshDataTool.new()
#				mdt.create_from_surface(mesh, 0)
#				for i in range(mdt.get_vertex_count()):
#					var vertex = mdt.get_vertex(i)
#					vertex *= scale
#					# Save your change.
#					mdt.set_vertex(i, vertex)
#				mesh.clear_surfaces()
#				mdt.commit_to_surface(mesh)
#				var shape
#				if trimesh:
#					shape = mesh.create_trimesh_shape()
#				else:
#					shape = mesh.create_convex_shape()
#				current_collision.shape = shape
#				if "transform" in attrib and attrib.transform == "true":
#					current_collision.position = nodes[idx].position * scale
#				var debug_mesh: ArrayMesh = shape.get_debug_mesh()
#				current_col_debug.mesh = debug_mesh
#				return OK
#		idx += 1
#	return ERR_CANT_RESOLVE
	
func parse_joints(urdf_data: PackedByteArray):
	var parse_err = parser.open_buffer(urdf_data)
	if parse_err:
		printerr("[PARSER] parse error ", parse_err)
		return ERR_PARSE_ERROR
		
	var root_tag: int = Tag.NONE
	var joint_attrib = {}
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
						var value : String = parser.get_attribute_value(idx)
						joint_attrib[name] = value
					if "name" in joint_attrib:
						joint_attrib.name = joint_attrib.name.replace(" ", "_")
						
				"parent":
					if not root_tag == Tag.JOINT: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value.replace(" ", "_")
					joint_attrib.parent = attrib
					
				"child":
					if not root_tag == Tag.JOINT: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value.replace(" ", "_")
					joint_attrib.child = attrib
					
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
					joint_attrib.origin = new_origin_dict
					
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
					joint_attrib.axis = axis
						
				"limit":
					if not root_tag == Tag.JOINT: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					joint_attrib.limit = {}
					if "effort" in attrib:
						joint_attrib.limit.effort = float(attrib.effort) * scale * gravity_scale
					if "velocity" in attrib:
						joint_attrib.limit.velocity = attrib.velocity
					if "lower" in attrib:
						joint_attrib.limit.lower = float(attrib.lower)
					else:
						joint_attrib.limit.lower = 0.0
					if "upper" in attrib:
						joint_attrib.limit.upper = float(attrib.upper)
					else:
						joint_attrib.limit.upper = 0.0
				
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "joint":
				_joints.append(joint_attrib.duplicate(true))
				joint_attrib.clear()
				root_tag = Tag.NONE

#	print("joints: ", JSON.stringify(_joints, "\t", false))

func parse_sensors(urdf_data: PackedByteArray):
	# http://wiki.ros.org/urdf/XML/sensor/proposals
	# http://wiki.ros.org/urdf/XML/sensor
	var parse_err = parser.open_buffer(urdf_data)
	if parse_err:
		printerr("[PARSER] parse error ", parse_err)
		return ERR_PARSE_ERROR
	
	var sensor_attrib = {}
	var sensor_node: Node3D
	var root_tag: int = Tag.NONE
	var internal_tag: int = Tag.RAY
	while true:
		if parser.read() != OK: # Ending parse XML file
			break
		var type = parser.get_node_type()
		
		if type == XMLParser.NODE_ELEMENT:
			# Get node name
			var node_name = parser.get_node_name()
			
			match node_name:
				"sensor":
					if root_tag != Tag.NONE: continue
					root_tag = Tag.SENSOR
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value : String = parser.get_attribute_value(idx)
						attrib[name] = value
					if "name" in attrib:
						sensor_attrib.name = attrib.name.replace(" ", "_")
					if "type" in attrib:
						match attrib.type:
							"ray":
								sensor_node = load("res://game/robot_features/sensors/ray_scanner.tscn").instantiate()
							_:
								printerr("Unrecognized sensor type name!")
					else:
						printerr("<type> attribute not present in <sensor> tag!")
					if sensor_node:
						sensor_node.set_meta("orphan", true)
						sensor_node.set_meta("owner", true)
						sensor_node.add_to_group("RAY", true)
						if sensor_attrib.name:
							sensor_node.name = sensor_attrib.name
						sensor_attrib.node = sensor_node
						
				"parent":
					if not root_tag == Tag.SENSOR: continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value.replace(" ", "_")
					sensor_attrib.parent = attrib
					
				"origin":
					if not root_tag == Tag.SENSOR: continue
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
					if sensor_node:
						sensor_node.position = xyz * scale
						sensor_node.rotation = rpy

#					if sensor_attrib.node.is_in_group("RAY"):
#
#						print("Sensor %s is in RAY group" % sensor_attrib.name)
					
				"ray":
					if root_tag != Tag.SENSOR: continue
					internal_tag = Tag.RAY
					if "type" in sensor_attrib and sensor_attrib.type != "ray":
						printerr("ray tag should not be use here!")
						
				"horizontal":
					if not root_tag == Tag.SENSOR : continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					sensor_attrib.horizontal = {}
					if internal_tag == Tag.RAY:
						if "samples" in attrib:
							sensor_attrib.horizontal.samples = int(attrib.samples)
						else:
							sensor_attrib.horizontal.samples = 1
						if "resolution" in attrib:
							sensor_attrib.horizontal.resolution = float(attrib.resolution)
						else:
							sensor_attrib.horizontal.resolution = 1.0
						if "min_angle" in attrib:
							sensor_attrib.horizontal.min_angle = float(attrib.min_angle)
						else:
							sensor_attrib.horizontal.min_angle = 0.0
						if "max_angle" in attrib:
							sensor_attrib.horizontal.max_angle = float(attrib.max_angle)
						else:
							sensor_attrib.horizontal.max_angle = 0.0
							
						sensor_node.samples = sensor_attrib.horizontal.samples
						sensor_node.hor_max_angle = sensor_attrib.horizontal.max_angle
						sensor_node.hor_min_angle = sensor_attrib.horizontal.min_angle
							
				"vertical":
					if not root_tag == Tag.SENSOR : continue
					
				"range":
					if not root_tag == Tag.SENSOR : continue
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					sensor_attrib.range = {}
					if internal_tag == Tag.RAY:
						if "min" in attrib:
							sensor_attrib.range.min = float(attrib.min) * scale
						else:
							sensor_attrib.range.min = 0.0
						if "max" in attrib:
							sensor_attrib.range.max = float(attrib.max) * scale
						else:
							sensor_attrib.range.max = 1.0 * scale
						sensor_node.ray_min = sensor_attrib.range.min
						sensor_node.ray_max = sensor_attrib.range.max
					
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "sensor":
				if sensor_node:
					_sensors.append(sensor_attrib.duplicate(true))
					sensor_attrib.clear()
				root_tag = Tag.NONE
				
			elif node_name == "ray":
				internal_tag = Tag.NONE
				
#	print("sensors: ", JSON.stringify(_sensors, "\t", false))

func create_asset_scene(root_node: Node3D):
	# Attach links to joints
	for joint in _joints:
		# search for the link that matches the parent link of joint
		var parent_name: String = joint.parent.link
		var parent_node: Node3D
		for link in _links:
			if link.name == parent_name:
				parent_node = link
				link.set_meta("orphan", false) # Marked as used
		if parent_node == null:
			parse_error_message += "Joint <%s> has no parent link!" % [joint.name]
			return null
		# search for the link that matches the child link of joint
		var child_name: String = joint.child.link
		var child_node: Node3D
		for link in _links:
			if link.name == child_name:
				child_node = link
				link.set_meta("orphan", false)
		if child_node == null:
			parse_error_message += "Joint <%s> has no child link!" % [joint.name]
			return null
			
		var joint_node : Node3D
		var new_joint_basis : Basis
		if not "type" in joint:
			printerr("joint %s has no type" % joint.name)
			return null
			
		match joint.type:
			"fixed":
				joint_node = JoltGeneric6DOFJoint3D.new()
				joint_node.name = joint.name
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy

			"pin":
				joint_node = JoltPinJoint3D.new()
				joint_node.name = joint.name
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
					
			"continuous":
				joint_node = JoltHingeJoint3D.new()
				joint_node.name = joint.name
				joint_node.add_to_group("CONTINUOUS", true)
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
				
				var limit_velocity : float = 1.0
				if "limit" in joint:
					if "effort" in joint.limit:
						joint_node.motor_max_torque = float(joint.limit.effort)
					if "velocity" in joint.limit:
						limit_velocity = float(joint.limit.velocity)
				if not "axis" in joint:
#					printerr("No axis for %s" % joint.name)
					new_joint_basis = Basis.looking_at(-Vector3(1,0,0))
					joint_node.transform.basis *= new_joint_basis
				elif joint.axis != Vector3.UP:
					new_joint_basis = Basis.looking_at(-joint.axis)
					joint_node.transform.basis *= new_joint_basis
				else:
					new_joint_basis = Basis(Vector3(1,0,0), Vector3(0,0,-1), Vector3(0,1,0))
					joint_node.transform.basis *= new_joint_basis
					
				var joint_script := GDScript.new()
				joint_script.source_code = get_continuous_joint_script(child_node, limit_velocity)
				joint_node.set_script(joint_script)
				
			"revolute":
				joint_node = JoltHingeJoint3D.new()
				joint_node.name = joint.name
				joint_node.limit_enabled = true
				joint_node.add_to_group("REVOLUTE", true)
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
				var limit_velocity : float = 1.0
				if "limit" in joint:
					if "effort" in joint.limit:
						joint_node.motor_max_torque = float(joint.limit.effort)
					if "velocity" in joint.limit:
						limit_velocity = float(joint.limit.velocity)
					if "lower" in joint.limit:
						joint_node.limit_upper = -joint.limit.lower
					else:
						joint_node.limit_upper = 0.0
					if "upper" in joint.limit:
						joint_node.limit_lower = -joint.limit.upper
					else:
						joint_node.limit_lower = 0.0
				if not "axis" in joint:
#					printerr("No axis for %s" % joint.name)
					new_joint_basis = Basis.looking_at(-Vector3(1,0,0))
					joint_node.transform.basis *= new_joint_basis
				elif joint.axis != Vector3.UP:
					new_joint_basis = Basis.looking_at(-joint.axis)
					joint_node.transform.basis *= new_joint_basis
				else:
					new_joint_basis = Basis(Vector3(1,0,0), Vector3(0,0,-1), Vector3(0,1,0))
					joint_node.transform.basis *= new_joint_basis
					
				var basis_node = Node3D.new()
				basis_node.set_meta("owner", true)
				basis_node.name = joint_node.name + "_basis_inv"
				basis_node.unique_name_in_owner = true
				basis_node.transform.basis = new_joint_basis
				child_node.add_child(basis_node)
					
				var joint_script := GDScript.new()
				joint_script.source_code = get_revolute_joint_script(child_node, basis_node, limit_velocity)
				joint_node.set_script(joint_script)
				
			"prismatic":
				joint_node = PrismaticJoint.new()
				joint_node.name = joint.name
				joint_node.child_link = child_node
				joint_node.set_meta("owner", true)
				joint_node.limit_enabled = true
				joint_node.add_to_group("PRISMATIC", true)
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
				var limit_velocity : float = 1.0
				if "limit" in joint:
					if "effort" in joint.limit:
						joint_node.motor_max_force = float(joint.limit.effort)
					if "velocity" in joint.limit:
						joint_node.limit_velocity = float(joint.limit.velocity) * scale
					if "lower" in joint.limit:
						joint_node.limit_lower = joint.limit.lower * scale
					else:
						joint_node.limit_lower = 0.0
					if "upper" in joint.limit:
						joint_node.limit_upper = joint.limit.upper * scale
					else:
						joint_node.limit_upper = 0.0
				if not "axis" in joint:
					new_joint_basis = Basis.looking_at(Vector3(1,0,0)).rotated(Vector3.UP, PI/2)
					joint_node.transform.basis *= new_joint_basis
				elif joint.axis != Vector3.UP:
					new_joint_basis = Basis.looking_at(joint.axis).rotated(Vector3.UP, PI/2)
					joint_node.transform.basis *= new_joint_basis
				else:
					new_joint_basis = Basis().rotated(Vector3.BACK, PI/2)
					joint_node.transform.basis *= new_joint_basis
					
				var basis_node = Node3D.new()
				basis_node.set_meta("owner", true)
				basis_node.name = joint_node.name + "_basis_inv"
				basis_node.transform.basis = new_joint_basis
				child_node.add_child(basis_node)
				
			_:
				return null
				
		joint_node.node_a = ^"../"
		joint_node.node_b = NodePath("%s" % [child_node.name])
		joint_node.unique_name_in_owner = true
		joint_node.set_meta("owner", true)
		# Add frame gizmo
		var frame_visual := MeshInstance3D.new()
		frame_visual.set_meta("owner", true)
		frame_visual.name = joint_node.name + "_frame"
		frame_visual.add_to_group("JOINT_GIZMO", true)
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
		
	# Attach sensors to links
	for sensor in _sensors:
		var parent_name: String = sensor.parent.link
		var parent_node: Node3D
		for link in _links:
			if link.name == parent_name:
				parent_node = link
				break
		if parent_node == null:
			printerr("Sensor <%s> has no parent link!" % [sensor.name])
			continue
		else:
			# Add frame gizmo
			var frame_visual := MeshInstance3D.new()
			frame_visual.set_meta("owner", true)
			frame_visual.name = sensor.name + "_frame"
			frame_visual.add_to_group("SENSOR_GIZMO", true)
			frame_visual.mesh = _frame_mesh
			frame_visual.scale = Vector3.ONE * scale
			frame_visual.visible = false
			sensor.node.add_child(frame_visual)
			parent_node.add_child(sensor.node)
		
	var base_link: RigidBody3D
	for link in _links:
		if link and link.get_parent() == null:
			base_link = link
			link.set_meta("orphan", false)
			if link.name == "world":
				link.add_to_group("STATIC", true)
				link.add_to_group("PICKABLE", true)
			if root_node.get_meta("type") == "env":
				base_link.freeze = true
			break
			
	freeing_nodes()
	return base_link
	
func add_root_script_to(root_node: Node3D):
	var root_script: GDScript = load("res://game/robot_features/root.gd")
	root_node.set_script(root_script)
	
func add_python_bridge(root_node: Node3D):
	var python_bridge : Node = load("res://game/python_bridge/python_bridge.tscn").instantiate()
	python_bridge.name = &"PythonBridge"
	python_bridge.set_meta("owner", true)
	root_node.add_child(python_bridge)
	root_node.set_meta("udp_port", 0)
	
func add_robot_base(root_node: Node3D):
	var robot_base : Node = RobotBase.new()
	robot_base.name = &"RobotBase"
	robot_base.set_meta("owner", true)
	root_node.add_child(robot_base)
	if root_node.get_node_or_null("PythonBridge"):
		root_node.get_node("PythonBridge").nodes.append(robot_base)
	if root_node.get("behavior_nodes") != null:
		root_node.behavior_nodes.append(robot_base)
		
func add_gobotics_control(root_node: Node3D):
#	print("_gobotics: ", _gobotics)
	for control in _gobotics:
		if "type" in control:
			match control.type:
				"grouped_joints":
					add_grouped_joints(root_node, control)
				"diff_drive":
					add_diff_drive(root_node, control)
				"4_mecanum_drive":
					add_4_mecanum_drive(root_node, control)

func add_grouped_joints(root_node: Node3D, control):
	var grouped_joints : Node = GroupedJoints.new()
	grouped_joints.name = StringName(control.name.to_pascal_case())
	grouped_joints.set_meta("owner", true)
	root_node.add_child(grouped_joints)
	grouped_joints.input = control.input
	grouped_joints.limit_lower = control.lower.to_float() * scale
	grouped_joints.limit_upper = control.upper.to_float() * scale
	grouped_joints.outputs = control.outputs
	
func add_diff_drive(root_node: Node3D, control):
	var diff_drive : Node = DiffDrive.new()
	diff_drive.name = StringName(control.name.to_pascal_case())
	diff_drive.set_meta("owner", true)
	diff_drive.right_wheel = control.right_wheel_joint
	diff_drive.left_wheel = control.left_wheel_joint
	diff_drive.max_speed = control.max_speed
	root_node.add_child(diff_drive)
	
	if root_node.get_node_or_null("PythonBridge"):
		root_node.get_node("PythonBridge").nodes.append(diff_drive)
	if root_node.get("behavior_nodes") != null:
		root_node.behavior_nodes.append(diff_drive)
		
func add_4_mecanum_drive(root_node: Node3D, control):
	var mecanum_drive : Node = FourMecanumDrive.new()
	mecanum_drive.name = StringName(control.name.to_pascal_case())
	mecanum_drive.set_meta("owner", true)
	mecanum_drive.front_right_wheel = control.front_right_wheel_joint
	mecanum_drive.front_left_wheel = control.front_left_wheel_joint
	mecanum_drive.back_right_wheel = control.back_right_wheel_joint
	mecanum_drive.back_left_wheel = control.back_left_wheel_joint
	mecanum_drive.max_speed = control.max_speed
	root_node.add_child(mecanum_drive)
	
	if root_node.get_node_or_null("PythonBridge"):
		root_node.get_node("PythonBridge").nodes.append(mecanum_drive)
	if root_node.get("behavior_nodes") != null:
		root_node.behavior_nodes.append(mecanum_drive)
	
func add_dummy_node(root_node: Node3D):
	var dummy_node : Node = DummyNode.new()
	dummy_node.name = &"Dummy"
	dummy_node.set_meta("owner", true)
	root_node.add_child(dummy_node)
	
func add_camera_on_robot(root_node: Node3D, base_link: RigidBody3D):
	var pivot := Node3D.new()
	pivot.set_meta("owner", true)
	pivot.name = &"PivotCamera"
	var boom := Node3D.new()
	boom.set_meta("owner", true)
	boom.name = &"Boom"
	boom.rotation_degrees.x = -30
	var camera := Camera3D.new()
	camera.set_meta("owner", true)
	camera.name = &"Camera"
	camera.add_to_group("CAMERA", true)
	camera.position = Vector3(0, 0 , 6.0)
	var camera_script := GDScript.new()
	var base_link_path = "../" + base_link.name
#	print("BaseLink NodePath: ", base_link_path)
	camera_script.source_code = get_pivot_camera_script(base_link_path)
	pivot.set_script(camera_script)
	boom.add_child(camera)
	pivot.add_child(boom)
	root_node.add_child(pivot)
	
func kinematics_scene_owner_of(root_node: Node3D):
	add_owner(root_node, root_node.get_children())
	return root_node
		
func add_owner(owner_node, nodes: Array):
	for node in nodes:
		if not node.get_meta("owner", false):
			continue
		node.owner = owner_node
		if node.get_child_count():
			add_owner(owner_node, node.get_children())

func get_continuous_joint_script(child_node: Node3D, limit_velocity: float) -> String:
	var source_code = """extends JoltHingeJoint3D
@export var grouped: bool = false
@onready var child_link: RigidBody3D = $%s
var target_velocity: float = 0.0:
	set = _target_velocity_changed
const LIMIT_VELOCITY = %f

func _ready():
	child_link.can_sleep = false
	motor_enabled = true
	motor_target_velocity = -target_velocity
	
func _target_velocity_changed(value: float):
	target_velocity = value
	motor_target_velocity = -target_velocity
""" % [child_node.name, limit_velocity]
	return source_code
	
func get_revolute_joint_script(child_node: Node3D, basis_node: Node3D, limit_velocity: float) -> String:
	var source_code = """extends JoltHingeJoint3D
@export var grouped: bool = false
@onready var child_link: RigidBody3D = $%s
@onready var basis_inv: Node3D = %%%s
var target_angle: float = 0
var input: float:
	set(value):
		input = value
		target_angle = value
var angle_step: float
var rest_angle: float
var LIMIT_VELOCITY: float = %f

func shift_target(step):
	if step > 0 and target_angle <= -limit_lower:
		target_angle += step
	if step < 0 and target_angle >= -limit_upper:
		target_angle += step

func _ready():
	child_link.can_sleep = false
	motor_enabled = true
	angle_step = LIMIT_VELOCITY / Engine.physics_ticks_per_second

func _physics_process(_delta):
	var child_basis: Basis = child_link.transform.basis
	var angle = (child_basis * basis_inv.transform.basis).get_euler().z
	var err = target_angle - angle
	var speed: float
	if abs(err) > angle_step:
		speed = LIMIT_VELOCITY * sign(err)
	else:
		speed = 0
	motor_target_velocity = -speed

func _target_angle_changed(value: float):
	target_angle = deg_to_rad(value)
""" % [child_node.name, basis_node.name, limit_velocity]
	return source_code
	
func get_prismatic_joint_script(child_node: Node3D, basis_node: Node3D, limit_velocity: float) -> String:
	var source_code = """extends JoltSliderJoint3D
@export var grouped: bool = false
@onready var child_link: RigidBody3D = $%s
@onready var basis_inv: Node3D = %%%s
var target_dist: float = 0.0:
	set(value):
		target_dist = value
		_target_reached = false
		motor_enabled = true
var input: float:
	set(value):
		input = value
		target_dist = value
var dist_step: float
var rest_angle: float
var LIMIT_VELOCITY: float = %f
var _target_reached: bool = false


func shift_target(step):
	if step > 0 and target_dist <= limit_upper:
		target_dist += step
	if step < 0 and target_dist >= limit_lower:
		target_dist += step

func _ready():
	child_link.can_sleep = false
	motor_enabled = true
	dist_step = LIMIT_VELOCITY / Engine.physics_ticks_per_second

func _physics_process(_delta):
	
	var child_tr: Transform3D = child_link.transform
	var dist = (child_tr * basis_inv.transform).origin.x
#	print("dist=", dist)
	var err = target_dist - dist
	var speed: float
	if not _target_reached:
		if abs(err) > dist_step:
			speed = LIMIT_VELOCITY * sign(err)
		else:
			speed = 0
			_target_reached = true
	else:
		speed = LIMIT_VELOCITY * err
	
	motor_target_velocity = speed

func _target_dist_changed(value: float):
	target_dist = value * 10.0
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

func get_pivot_camera_script(node_path: NodePath) -> String:
	var source_code = """extends CameraExt
func _ready():
	base_link_path = "%s"
""" % [node_path]
	return source_code
	
func clear_buffer():
	_materials.clear()
	_links.clear()
	_joints.clear()
	_sensors.clear()
	_gobotics.clear()
	parse_error_message = ""

func delete_links():
	for link in _links:
		link.queue_free()

func freeing_nodes():
	for link in _links:
		if link.get_meta("orphan"):
#			print("freeing %s" % link)
			link.queue_free()
	for sensor in _sensors:
		if sensor.node.get_meta("orphan"):
			sensor.node.queue_free()
