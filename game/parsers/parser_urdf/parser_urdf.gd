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
var _frame_mesh : ArrayMesh = load("res://game/gizmos/frame_arrows.res")

enum Tag {
		NONE,
		LINK,
		JOINT,
		MATERIAL,
		VISUAL,
		VISUAL_WITH_COL,
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
		printerr("[URDF PARSER] root node not founded")
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
			add_gobotics_control(root_node, base_link)
			add_camera_on_robot(root_node, base_link)
		if root_node.is_in_group("ENVIRONMENT"):
			_add_area_out_of_bounds(root_node)
		
		root_node.add_child(base_link)
		root_node.set_meta("offset_pos", Vector3.ZERO)
		kinematics_scene_owner_of(root_node)
		return root_node
	else:
		delete_links()
		root_node.free()
		return null
		
func get_urdf_error():
	pass
	

enum {
	OK,
	
}

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
				joint_node = ContinuousJoint.new()
				joint_node.name = joint.name
				joint_node.add_to_group("CONTINUOUS", true)
				joint_node.child_link = child_node
				_record(joint_node)
				if "visible" in joint:
					joint_node.set_meta("visible", joint.visible)
				else:
					joint_node.set_meta("visible", false)
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
				if "limit" in joint:
					if "effort" in joint.limit:
						joint_node.motor_max_torque = float(joint.limit.effort)
					if "velocity" in joint.limit:
						joint_node.limit_velocity = float(joint.limit.velocity)
				if not "axis" in joint:
					new_joint_basis = Basis.looking_at(-Vector3(1,0,0))
					joint_node.transform.basis *= new_joint_basis
				elif joint.axis != Vector3.UP:
					new_joint_basis = Basis.looking_at(-joint.axis)
					joint_node.transform.basis *= new_joint_basis
				else:
					new_joint_basis = Basis(Vector3(1,0,0), Vector3(0,0,-1), Vector3(0,1,0))
					joint_node.transform.basis *= new_joint_basis
				
			"revolute":
				joint_node = RevoluteJoint.new()
				joint_node.name = joint.name
				joint_node.add_to_group("REVOLUTE", true)
				joint_node.child_link = child_node
				joint_node.limit_enabled = true
				_record(joint_node)
				if "visible" in joint:
					joint_node.set_meta("visible", joint.visible)
				else:
					joint_node.set_meta("visible", false)
				if "origin" in joint:
					joint_node.position = joint.origin.xyz * scale
					joint_node.rotation = joint.origin.rpy
				if "limit" in joint:
					if "effort" in joint.limit:
						joint_node.motor_max_torque = float(joint.limit.effort)
					if "velocity" in joint.limit:
						joint_node.limit_velocity = float(joint.limit.velocity)
					if "lower" in joint.limit:
						joint_node.limit_upper = -joint.limit.lower
					else:
						joint_node.limit_upper = 0.0
					if "upper" in joint.limit:
						joint_node.limit_lower = -joint.limit.upper
					else:
						joint_node.limit_lower = 0.0
				if not "axis" in joint:
					new_joint_basis = Basis.looking_at(-Vector3(1,0,0))
					joint_node.transform.basis *= new_joint_basis
				elif joint.axis != Vector3.UP:
					new_joint_basis = Basis.looking_at(-joint.axis)
					joint_node.transform.basis *= new_joint_basis
				else:
					new_joint_basis = Basis(Vector3(1,0,0), Vector3(0,0,-1), Vector3(0,1,0))
					joint_node.transform.basis *= new_joint_basis
				
				var basis_node = Node3D.new()
				_record(basis_node)
				basis_node.name = joint_node.name + "_basis_inv"
				basis_node.transform.basis = new_joint_basis
				child_node.add_child(basis_node)
				
			"prismatic":
				joint_node = PrismaticJoint.new()
				joint_node.name = joint.name
				joint_node.child_link = child_node
				joint_node.limit_enabled = true
				_record(joint_node)
				if "visible" in joint:
					joint_node.set_meta("visible", joint.visible)
				else:
					joint_node.set_meta("visible", false)
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
			# INFO: evaluate if base_link has collision shape like children
			if not base_link.get_children().any(func(child): return child is CollisionShape3D):
				freeing_nodes()
				printerr("[URDF PARSER] base_link has not collision shape!")
				return null
			base_link.add_to_group("BASE_LINK", true)
			link.set_meta("orphan", false)
			if link.name == "world":
				link.add_to_group("STATIC", true)
				link.add_to_group("PICKABLE", true)
			if root_node.get_meta("type") == "env":
				base_link.freeze = true
			break
	
	freeing_nodes()
	return base_link

func parse_gobotics_params(urdf_path: PackedByteArray):
	var parse_err = parser.open_buffer(urdf_path)
	if parse_err:
		printerr("[PARSER] parse error ", parse_err)
		return null
	var gobotics_types = [
		"diff_drive",
		"4_mecanum_drive",
		"3_omni_drive",
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

				"wheel_1":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "joint" in attrib:
						gobotics_attrib.wheel_1_joint = attrib.joint
					
				"wheel_2":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "joint" in attrib:
						gobotics_attrib.wheel_2_joint = attrib.joint
						
				"wheel_3":
					if not root_tag == Tag.GOBOTICS: continue
					var attrib: Dictionary = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					if "joint" in attrib:
						gobotics_attrib.wheel_3_joint = attrib.joint

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
	
	#print("gobotics: ", JSON.stringify(_gobotics, "\t", false))

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

	#print("materials: ", _materials)

func parse_links(urdf_data: PackedByteArray, asset_type: String) -> int:
	var parse_err = parser.open_buffer(urdf_data)
	if parse_err:
		printerr("[URDF PARSER] parse error ", parse_err)
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
								#print("Right Mecanum Wheel")
								link = load("res://game/builtins/right_mecanum_wheel.tscn").instantiate()
							"left_mecanum_wheel":
								#print("Left Mecanum Wheel")
								link = load("res://game/builtins/left_mecanum_wheel.tscn").instantiate()
							"omni_wheel":
								#print("Omni Wheel parsed")
								link = load("res://game/builtins/omni_wheel.tscn").instantiate()
							_:
								printerr("Unrecognized extends link!")
								return ERR_PARSE_ERROR
					
					else:
						link = RigidBody3D.new()
					var physics_material = PhysicsMaterial.new()
					link.physics_material_override = physics_material
					link.collision_layer = 0b1001 # Robots + Selection mask
					link.set_meta("orphan", true)
					_record(link)
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
					#current_tag = Tag.VISUAL
					var attrib = {}
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value = parser.get_attribute_value(idx)
						attrib[name] = value
					
					current_visual = VisualMesh.new()
					current_visual.add_to_group("VISUAL", true)
					if "name" in attrib and attrib.name != "":
						current_visual.name = attrib.name + "_mesh"
					else:
						current_visual.name = link_attrib.name + "_mesh"
					_record(current_visual)
					link.add_child(current_visual)
					
					if "with_col" in attrib:
						match attrib.with_col:
							"true":
								current_tag = Tag.VISUAL_WITH_COL
								current_collision = CollisionShape3D.new()
								current_collision.name = attrib.name + "_col"
								_record(current_collision)
								link.add_child(current_collision)
								
								current_col_debug = MeshInstance3D.new()
								current_col_debug.add_to_group("COLLISION", true)
								current_col_debug.visible = false
								current_col_debug.name = attrib.name + "_debug"
								_record(current_col_debug)
								link.add_child(current_col_debug)
							"false":
								current_tag = Tag.VISUAL
							_:
								printerr("with_col attribut has wrong value!")
								current_tag = Tag.VISUAL
					else:
						current_tag = Tag.VISUAL
				
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
					_record(current_collision)
					link.add_child(current_collision)
					
					current_col_debug = MeshInstance3D.new()
					current_col_debug.add_to_group("COLLISION", true)
					current_col_debug.visible = false
					if "name" in attrib:
						current_col_debug.name = attrib.name + "_debug"
					else:
						current_col_debug.name = link_attrib.name + "_debug"
					_record(current_col_debug)
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
						
					elif current_tag == Tag.VISUAL_WITH_COL:
						var cylinder_mesh := CylinderMesh.new()
						cylinder_mesh.bottom_radius = float(attrib.radius) * scale
						cylinder_mesh.top_radius = float(attrib.radius) * scale
						cylinder_mesh.height = float(attrib.length) * scale
						current_visual.mesh = cylinder_mesh
						var cylinder_shape := CylinderShape3D.new()
						cylinder_shape.radius = float(attrib.radius) * scale
						cylinder_shape.height = float(attrib.length) * scale
						current_collision.shape = cylinder_shape
						var debug_mesh: ArrayMesh = cylinder_shape.get_debug_mesh()
						current_col_debug.mesh = debug_mesh
						
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
					
					elif current_tag == Tag.VISUAL_WITH_COL:
						var box_mesh := BoxMesh.new()
						box_mesh.size = size * scale
						current_visual.mesh = box_mesh
						var box_shape := BoxShape3D.new()
						box_shape.size = size * scale
						current_collision.shape = box_shape
						var debug_mesh: ArrayMesh = box_shape.get_debug_mesh()
						current_col_debug.mesh = debug_mesh
					
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
						
					elif current_tag == Tag.VISUAL_WITH_COL:
						var sphere_mesh := SphereMesh.new()
						sphere_mesh.radius = float(attrib.radius) * scale
						sphere_mesh.height = float(attrib.radius) * scale * 2
						current_visual.mesh = sphere_mesh
						var sphere_shape := SphereShape3D.new()
						sphere_shape.radius = float(attrib.radius) * scale
						current_collision.shape = sphere_shape
						var debug_mesh: ArrayMesh = sphere_shape.get_debug_mesh()
						current_col_debug.mesh = debug_mesh
						
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
							"glb":
								if current_tag == Tag.VISUAL:
									var mesh: ArrayMesh = get_mesh_from_gltf(attrib)
									if mesh == null:
										printerr("Failed to load mesh into gltf")
										continue
									current_visual.mesh = mesh
									current_visual.scale = Vector3.ONE * scale
								
								elif current_tag == Tag.VISUAL_WITH_COL:
									var mesh: ArrayMesh = get_mesh_from_gltf(attrib)
									if mesh == null:
										printerr("Failed to load mesh into gltf")
										continue
									current_visual.mesh = mesh
									current_visual.scale = Vector3.ONE * scale
									if current_collision:
										var shape: Shape3D = get_shape_from_gltf(attrib, current_col_debug)
										if shape == null:
											printerr("Failed to load shape into gltf")
											continue
										current_collision.shape = shape
									
								elif current_tag == Tag.COLLISION:
									var shape: Shape3D = get_shape_from_gltf(attrib, current_col_debug, link.name == "world")
									if shape == null:
										printerr("Failed to load shape into gltf")
										continue
									current_collision.shape = shape
							_:
								printerr("3D format not supported!")
					else:
						printerr("Filename was not entered!")
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
					elif current_tag == Tag.VISUAL_WITH_COL:
						current_visual.position = xyz * scale
						current_visual.rotation = rpy
						current_collision.position = xyz * scale
						current_collision.rotation = rpy
						current_col_debug.position = xyz * scale
						current_col_debug.rotation = rpy
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
					if current_tag == Tag.VISUAL or current_tag == Tag.VISUAL_WITH_COL:
						## Global material
						if "name" in attrib and attrib.name != "":
							for mat in _materials:
								if mat.name == attrib.name:
									#print("[global material tag] current visual: ", current_visual)
									mat.res.resource_local_to_scene = true
									current_visual.set_surface_override_material(0, mat.res)
						## Local material
						if current_visual.get_surface_override_material(0) == null:
							#print("[local material tag] current visual: ", current_visual)
							var material := StandardMaterial3D.new()
							material.resource_local_to_scene = true
							current_visual.set_surface_override_material(0, material)
				
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
				
	#print("links: ", JSON.stringify(_links, "\t", false))
	return OK

func get_mesh_from_gltf(attrib: Dictionary) -> ArrayMesh:
	
	var gltf_res := GLTFDocument.new()
	var gltf_data := GLTFState.new()
	var gltf_filename : String = GSettings.asset_path.path_join(attrib.filename)
	
	# Fixed bug : https://github.com/godotengine/godot/issues/85960
	# 8 is the constant for EditorSceneFormatImporter.IMPORT_GENERATE_TANGENT_ARRAYS :
	# blendshapes without tangents seem to have been broken in 4.2, so this is why it works around the bug.
	var err = gltf_res.append_from_file(gltf_filename, gltf_data, 8)
	if err:
		printerr("gltf from buffer failed!")
		parse_error_message = "GLTF file import failed!"
		return null
		
	var meshes : Array[GLTFMesh] = gltf_data.get_meshes()
	
	if gltf_data.json.nodes.is_empty():
		printerr("[PARSER] gltf is empty")
		return null
		
	var active_node = gltf_data.json.nodes[0]
	
	var imported_mesh : ImporterMesh = meshes[active_node.mesh].mesh
	var mesh: ArrayMesh = imported_mesh.get_mesh()
	
	# To avoid orphan nodes created by append_from_file()
	var scene_node = gltf_res.generate_scene(gltf_data)
	scene_node.queue_free()

	return mesh

func get_shape_from_gltf(attrib, debug_col = null,  trimesh=false) -> Shape3D:
		
	var gltf_res := GLTFDocument.new()
	var gltf_data := GLTFState.new()
	
	var gltf_filename : String = GSettings.asset_path.path_join(attrib.filename)
	var err = gltf_res.append_from_file(gltf_filename, gltf_data)
	if err:
		printerr("gltf from buffer failed")
		parse_error_message = "GLTF file import failed!"
		return null
	
	var meshes : Array[GLTFMesh] = gltf_data.get_meshes()
	if gltf_data.json.nodes.is_empty():
		printerr("[PARSER] gltf is empty")
		return null
		
	var active_node = gltf_data.json.nodes[0]
	
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
	var scene_node = gltf_res.generate_scene(gltf_data)
	scene_node.queue_free()
	
	return shape

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
					if "visible" in joint_attrib:
						match joint_attrib.visible:
							"true":
								joint_attrib.visible = true
							"false":
								joint_attrib.visible = false
							_:
								joint_attrib.visible = false
						
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

	#print("joints: ", JSON.stringify(_joints, "\t", false))

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
					sensor_node = null
					for idx in parser.get_attribute_count():
						var name = parser.get_attribute_name(idx)
						var value : String = parser.get_attribute_value(idx)
						attrib[name] = value
					if "name" in attrib:
						sensor_attrib.name = attrib.name.replace(" ", "_")
						if not _sensors.filter(func(sensor): return sensor.name == sensor_attrib.name).is_empty():
							printerr("Sensor name \"%s\" already used!" % sensor_attrib.name)
							root_tag = Tag.NONE
							continue
					if "type" in attrib:
						match attrib.type:
							"ray":
								sensor_node = load("res://game/robot_features/sensors/ray_scanner.tscn").instantiate()
								sensor_node.add_to_group("RAY", true)
							"camera":
								sensor_node = load("res://game/robot_features/sensors/camera_sensor.tscn").instantiate()
								sensor_node.add_to_group("CAM", true)
							_:
								printerr("Unrecognized sensor type name!")
					else:
						printerr("<type> attribute not present in <sensor> tag!")
					if sensor_node:
						sensor_node.set_meta("orphan", true)
						sensor_node.set_meta("owner", true)
						sensor_node.add_to_group("SENSORS", true)
						sensor_node.unique_name_in_owner = true
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
					if sensor_node and sensor_node.is_in_group("RAY") and internal_tag == Tag.RAY:
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
					if sensor_node and sensor_node.is_in_group("RAY") and internal_tag == Tag.RAY:
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
				
	#print("_sensors: ", JSON.stringify(_sensors, "\t", false))


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

func add_gobotics_control(root_node: Node3D, base_link: RigidBody3D):
	#print("_gobotics: ", _gobotics)
	for control in _gobotics:
		if "type" in control:
			match control.type:
				"grouped_joints":
					add_grouped_joints(root_node, control)
				"diff_drive":
					add_diff_drive(root_node, base_link, control)
				"4_mecanum_drive":
					add_4_mecanum_drive(root_node, control)
				"3_omni_drive":
					add_3_omni_drive(root_node, control)

func add_grouped_joints(root_node: Node3D, control):
	var grouped_joints : Node = GroupedJoints.new()
	grouped_joints.name = StringName(control.name)
	grouped_joints.set_meta("owner", true)
	grouped_joints.set_meta("visible", true)
	root_node.add_child(grouped_joints)
	grouped_joints.input = control.input
	grouped_joints.limit_lower = control.lower.to_float() * scale
	grouped_joints.limit_upper = control.upper.to_float() * scale
	grouped_joints.outputs = control.outputs

func add_diff_drive(root_node: Node3D, base_link: RigidBody3D, control):
	var diff_drive : Node = DiffDrive.new()
	diff_drive.name = StringName(control.name.to_pascal_case())
	diff_drive.set_meta("owner", true)
	diff_drive.right_wheel = control.right_wheel_joint
	diff_drive.left_wheel = control.left_wheel_joint
	diff_drive.max_speed = control.max_speed
	diff_drive.base_link = base_link
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

func add_3_omni_drive(root_node: Node3D, control):
	var omni_drive : Node = ThreeOmniDrive.new()
	omni_drive.name = StringName(control.name.to_pascal_case())
	omni_drive.set_meta("owner", true)
	omni_drive.wheel_1 = control.wheel_1_joint
	omni_drive.wheel_2 = control.wheel_2_joint
	omni_drive.wheel_3 = control.wheel_3_joint
	omni_drive.max_speed = control.max_speed
	root_node.add_child(omni_drive)

	if root_node.get_node_or_null("PythonBridge"):
		root_node.get_node("PythonBridge").nodes.append(omni_drive)
	if root_node.get("behavior_nodes") != null:
		root_node.behavior_nodes.append(omni_drive)

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
	#print("BaseLink NodePath: ", base_link_path)
	camera_script.source_code = get_pivot_camera_script(base_link_path)
	pivot.set_script(camera_script)
	boom.add_child(camera)
	pivot.add_child(boom)
	root_node.add_child(pivot)

func _add_area_out_of_bounds(root_node: Node3D):
	#print("Add area for %s" % root_node.name)
	var living_area := Area3D.new()
	living_area.name = &"LivingArea"
	living_area.unique_name_in_owner = true
	var area_col_shape := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(20, 5, 20) * GPSettings.SCALE
	area_col_shape.shape = col_shape
	area_col_shape.set_meta("owner", true)
	living_area.add_child(area_col_shape)
	living_area.set_meta("owner", true)
	var env_script: GDScript = load("res://game/environments/environment.gd")
	root_node.set_script(env_script)
	root_node.add_child(living_area)

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

# Helper function to record node in scenetree
func _record(node: Node, saving = true):
	node.set_meta("owner", saving)
