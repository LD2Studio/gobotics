extends RefCounted
class_name URDFParser

var scale: float = 1.0

var parser = XMLParser.new()

var _materials: Array
var _links: Array
var _joints: Array
var _gobotics: Dictionary
var _script := GDScript.new()
var _filename : String

enum Tag {
		NONE,
		JOINT,
		VISUAL,
		COLLISION,
		INERTIAL,
		GOBOTICS,
	}
	
func parse(filename: String):
	_filename = filename
	load_gobotics_params(filename)
	load_materials(filename)
	load_links(filename)
	load_joints(filename)
	var root_node = get_root_node(filename)
	root_node.add_child(get_kinematics_scene())
	kinematics_scene_owner_of(root_node)
	add_script_to(root_node)
	return root_node
	
func load_gobotics_params(filename: String):
	var err = parser.open(filename)
	if err:
		printerr("Error opening URDF file: ", err)
		return

	var current_tag: int = Tag.NONE
	while true:
		if parser.read() != OK: # Ending parse XML file
#			print("Ending link parser")
			break
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "gobotics":
				current_tag = Tag.GOBOTICS
				
			if node_name == "category" and current_tag == Tag.GOBOTICS:
				var attrib: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				if "name" in attrib:
					_gobotics.category = attrib.name
					
			if node_name == "control" and current_tag == Tag.GOBOTICS:
				var attrib: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				var control = {}
				_gobotics.control = control
				if "name" in attrib:
					_gobotics.control.name = attrib.name
				if "type" in attrib:
					_gobotics.control.type = attrib.type
					
			if node_name == "right_wheel" and current_tag == Tag.GOBOTICS:
				var attrib: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				if "joint" in attrib:
					_gobotics.control.right_wheel_joint = attrib.joint
					
			if node_name == "left_wheel" and current_tag == Tag.GOBOTICS:
				var attrib: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				if "joint" in attrib:
					_gobotics.control.left_wheel_joint = attrib.joint
					
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "gobotics":
				current_tag = Tag.NONE
				
#	print("gobotics: ", JSON.stringify(_gobotics, "\t", false))
				
func load_materials(filename: String):
	var err = parser.open(filename)
	if err:
		printerr("Error opening URDF file: ", err)
		return
		
	var mat_dict: Dictionary
	while true:
		if parser.read() != OK: # Ending parse XML file
#			print("Ending link parser")
			break
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "material":
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					mat_dict[name] = value
				
				var res := StandardMaterial3D.new()
				mat_dict.res = res
				
			if node_name == "color" and not mat_dict.is_empty():
				var color_dict: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					color_dict[name] = value
					
				var color := Color.WHITE
				if "rgba" in color_dict:
					var rgba_arr = color_dict.rgba.split_floats(" ")
					color.r = rgba_arr[0]
					color.g = rgba_arr[1]
					color.b = rgba_arr[2]
					color.a = rgba_arr[3]
				
				mat_dict.res.albedo_color = color
				
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "material":
				_materials.append(mat_dict.duplicate(true))
				mat_dict.clear()

#	print("materials: ", _materials)

func load_links(filename: String):
	var err = parser.open(filename)
	if err:
		printerr("Error opening URDF file: ", err)
		return
		
	var link_dict: Dictionary
	var current_tag: int = Tag.NONE
	while true:
		if parser.read() != OK: # Ending parse XML file
#			print("Ending link parser")
			break
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			# Get node name
			var node_name = parser.get_node_name()
			## Link tag
			if node_name == "link":
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					link_dict[name] = value
					
				var node := RigidBody3D.new()
				node.name = link_dict.name
				node.add_to_group("SELECT", true)
				link_dict["node"] = node
			## Visual tag
			if node_name == "visual" and not link_dict.is_empty():
				current_tag = Tag.VISUAL
				var attrib: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
					
				var mesh_node := MeshInstance3D.new()
				if "name" in attrib and attrib.name != "":
					mesh_node.name = attrib.name + "_mesh"
				else:
					mesh_node.name = link_dict.name + "_mesh"
				link_dict["node"].add_child(mesh_node)
				var mesh_dict: Dictionary
				mesh_dict.node = mesh_node
				link_dict.visual = mesh_dict
			## Collision tag
			if node_name == "collision" and not link_dict.is_empty():
				current_tag = Tag.COLLISION
				var attrib: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
					
				var collision_node := CollisionShape3D.new()
				if "name" in attrib:
					collision_node.name = attrib.name + "_col"
				else:
					collision_node.name = link_dict.name + "_col"
				link_dict.node.add_child(collision_node)
				var col_dict: Dictionary
				col_dict.node = collision_node
				link_dict.collision = col_dict
				
			if node_name == "geometry" and not link_dict.is_empty():
				if current_tag == Tag.VISUAL:
					pass
				elif current_tag == Tag.COLLISION:
					pass
				
			if node_name == "cylinder" and not link_dict.is_empty():
				var cyl_dict: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					cyl_dict[name] = value
				if current_tag == Tag.VISUAL:
					var cylinder_mesh := CylinderMesh.new()
					cylinder_mesh.bottom_radius = float(cyl_dict.radius) * scale
					cylinder_mesh.top_radius = float(cyl_dict.radius) * scale
					cylinder_mesh.height = float(cyl_dict.length) * scale
					link_dict.visual.node.set_mesh(cylinder_mesh)
				elif current_tag == Tag.COLLISION:
					var cylinder_shape := CylinderShape3D.new()
					cylinder_shape.radius = float(cyl_dict.radius) * scale
					cylinder_shape.height = float(cyl_dict.length) * scale
					link_dict.collision.node.set_shape(cylinder_shape)
				
			if node_name == "box" and not link_dict.is_empty():
				var box_dict: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					box_dict[name] = value
				var size := Vector3.ONE
				if "size" in box_dict:
#					print("size: ", box_dict.size)
					var size_arr = box_dict.size.split_floats(" ")
					size.x = size_arr[0]
					size.y = size_arr[2]
					size.z = size_arr[1]
				if current_tag == Tag.VISUAL:
					var box_mesh := BoxMesh.new()
					box_mesh.size = size * scale
					link_dict.visual.node.mesh = box_mesh
				elif current_tag == Tag.COLLISION:
					var box_shape := BoxShape3D.new()
					box_shape.size = size * scale
					link_dict.collision.node.shape = box_shape
					
			if node_name == "sphere" and not link_dict.is_empty():
				var sphere_dict: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					sphere_dict[name] = value
				if current_tag == Tag.VISUAL:
					var sphere_mesh := SphereMesh.new()
					sphere_mesh.radius = float(sphere_dict.radius) * scale
					sphere_mesh.height = float(sphere_dict.radius) * scale * 2
					link_dict.visual.node.mesh = sphere_mesh
				elif current_tag == Tag.COLLISION:
					var sphere_shape := SphereShape3D.new()
					sphere_shape.radius = float(sphere_dict.radius) * scale
					link_dict.collision.node.shape = sphere_shape
				
			if node_name == "mesh" and not link_dict.is_empty():
				var attrib: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
#				if current_tag == Tag.VISUAL:
				if "filename" in attrib:
					match attrib.filename.get_extension():
						"obj":
							var mesh_filename = _filename.get_base_dir().path_join(attrib.filename.trim_prefix("package://"))
	#						print_debug(mesh_filename)
							var mesh: ArrayMesh = load(mesh_filename)
							if mesh:
								link_dict.visual.node.mesh = mesh
								link_dict.visual.node.scale = Vector3.ONE * scale
						
						"glb":
							if not "object" in attrib:
								printerr("Object attribut missing!")
								continue
							var scene_filename = _filename.get_base_dir().path_join(attrib.filename.trim_prefix("package://"))
#							print_debug(scene_filename)
							if Engine.is_editor_hint():
#								print("Editor")
								var scene: PackedScene = load(scene_filename)
#								print_debug(scene)
								var scene_state = scene.get_state()
#								print("node count: ", scene_state.get_node_count())
								for idx in scene_state.get_node_count():
#										print("node name: ", scene_state.get_node_name(idx))
									if scene_state.get_node_name(idx) == attrib.object:
										for prop_idx in scene_state.get_node_property_count(idx):
											var prop_name = scene_state.get_node_property_name(idx, prop_idx)
#											print("props: ", prop_name)
											
											## Mesh attached to node
											if prop_name == "mesh":
												var mesh: ArrayMesh = scene_state.get_node_property_value(idx, prop_idx)
												print("mesh: ", mesh)
												if current_tag == Tag.VISUAL:
													link_dict.visual.node.mesh = mesh
													link_dict.visual.node.scale = Vector3.ONE * scale
												elif current_tag == Tag.COLLISION:													
													var shape: ConvexPolygonShape3D = mesh.create_convex_shape()
													link_dict.collision.node.shape = shape
													link_dict.collision.node.scale = Vector3.ONE * scale
											if prop_name == "transform":
												var tr: Transform3D = scene_state.get_node_property_value(idx, prop_idx)
												print("tranform: ", tr)
												var xyz: Vector3 = tr.origin
												var rpy: Vector3 = tr.basis.get_euler()
												if current_tag == Tag.VISUAL:
													link_dict.visual.node.position = xyz * scale
													link_dict.visual.node.rotation = rpy
												elif current_tag == Tag.COLLISION:
													link_dict.collision.node.position = xyz * scale
													link_dict.collision.node.rotation = rpy
						"dae":
							pass
						_:
							printerr("3D format not supported !")
				
			if node_name == "origin" and not link_dict.is_empty():
				var attribut_count = parser.get_attribute_count()
				var origin_dict: Dictionary
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					origin_dict[name] = value
				var xyz := Vector3.ZERO
				if "xyz" in origin_dict:
					var xyz_arr = origin_dict.xyz.split_floats(" ")
					xyz.x = xyz_arr[0]
					xyz.y = xyz_arr[2]
					xyz.z = -xyz_arr[1]
				var rpy := Vector3.ZERO
				if "rpy" in origin_dict:
					var rpy_arr = origin_dict.rpy.split_floats(" ")
					rpy.x = rpy_arr[0]
					rpy.y = rpy_arr[2]
					rpy.z = -rpy_arr[1]
				if current_tag == Tag.VISUAL:
					link_dict.visual.node.position = xyz * scale
					link_dict.visual.node.rotation = rpy
				elif current_tag == Tag.COLLISION:
					link_dict.collision.node.position = xyz * scale
					link_dict.collision.node.rotation = rpy
				
			if node_name == "material" and not link_dict.is_empty():
				var attribut_count = parser.get_attribute_count()
				var attrib: Dictionary
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				if current_tag == Tag.VISUAL:
					if "name" in attrib and attrib.name != "":
						link_dict.visual.mat = attrib
					else:
						link_dict.visual.mat = {}
						var res := StandardMaterial3D.new()
						link_dict.visual.mat.res = res
				
			if node_name == "color" and not link_dict.is_empty() and current_tag == Tag.VISUAL:
				var attrib: Dictionary
				var attribut_count = parser.get_attribute_count()
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
					
				if "res" in link_dict.visual.mat:
					var color := Color.WHITE
					if "rgba" in attrib:
						var rgba_arr = attrib.rgba.split_floats(" ")
						color.r = rgba_arr[0]
						color.g = rgba_arr[1]
						color.b = rgba_arr[2]
						color.a = rgba_arr[3]
					link_dict.visual.mat.res.albedo_color = color
					
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "link":
				_links.append(link_dict.duplicate(true))
				link_dict.clear()
			
			if node_name == "visual":
				current_tag = Tag.NONE
				if not "mat" in link_dict.visual: continue
				## Global colors
				if "name" in link_dict.visual.mat:
					for mat in _materials:
						if mat.name == link_dict.visual.mat.name:
							link_dict.visual.node.set_surface_override_material(0, mat.res)
					continue
				## Local colors
				if "res" in link_dict.visual.mat:
					link_dict.visual.node.set_surface_override_material(0, link_dict.visual.mat.res)
						
			if node_name == "collision":
				current_tag = Tag.NONE
				
				
#	print("links: ", JSON.stringify(_links, "\t", false))

func load_joints(filename: String):
	var err = parser.open(filename)
	if err:
		printerr("Error opening URDF file: ", err)
		return
	var current_tag: int = Tag.NONE
	var joint_dict: Dictionary
	while true:
		if parser.read() != OK: # Ending parse XML file
#			print("Ending joints parser")
			break
		var type = parser.get_node_type()
		
		if type == XMLParser.NODE_ELEMENT:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "joint":
				current_tag = Tag.JOINT
				var attribut_count = parser.get_attribute_count()
				
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					joint_dict[name] = value
					
			if node_name == "parent":
				var attribut_count = parser.get_attribute_count()
				var parent_dict: Dictionary
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					parent_dict[name] = value
				
				joint_dict["parent"] = parent_dict
				
			if node_name == "child":
				var attribut_count = parser.get_attribute_count()
				var child_dict: Dictionary
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					child_dict[name] = value
				
				joint_dict["child"] = child_dict
				
			if node_name == "origin":
				var attribut_count = parser.get_attribute_count()
				var origin_dict: Dictionary
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					origin_dict[name] = value
				var xyz := Vector3.ZERO
				if "xyz" in origin_dict:
					var xyz_arr = origin_dict.xyz.split_floats(" ")
					xyz.x = xyz_arr[0]
					xyz.y = xyz_arr[2]
					xyz.z = -xyz_arr[1]
				var rpy := Vector3.ZERO
				if "rpy" in origin_dict:
					var rpy_arr = origin_dict.rpy.split_floats(" ")
					rpy.x = rpy_arr[0]
					rpy.y = rpy_arr[2]
					rpy.z = -rpy_arr[1]
				var new_origin_dict = {
					"xyz": xyz,
					"rpy": rpy,
				}
				joint_dict["origin"] = new_origin_dict
				
			if node_name == "axis":
				var attribut_count = parser.get_attribute_count()
				var attrib: Dictionary
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				var axis := Vector3(1,0,0)
				if "xyz" in attrib:
					var xyz_arr = attrib.xyz.split_floats(" ")
					axis.x = xyz_arr[0]
					axis.y = xyz_arr[2]
					axis.z = -xyz_arr[1]
				joint_dict.axis = axis
				
			if node_name == "gobotics" and current_tag == Tag.JOINT:
				var attribut_count = parser.get_attribute_count()
				var attrib: Dictionary
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					attrib[name] = value
				if "type" in attrib and "type" in joint_dict:
					joint_dict.type = attrib.type
				
		if type == XMLParser.NODE_ELEMENT_END:
			# Get node name
			var node_name = parser.get_node_name()
			if node_name == "joint":
				_joints.append(joint_dict.duplicate(true))
				joint_dict.clear()
				current_tag = Tag.NONE

#	print("joints: ", JSON.stringify(_joints, "\t", false))

func get_kinematics_scene():
	for joint in _joints:
		var parent_name: String = joint.parent.link
#		print(parent_name)
		var parent_node: Node3D
		for link in _links:
			if link.name == parent_name:
				parent_node = link.node
#		print("parent_node: ", parent_node)
		
		var child_name: String = joint.child.link
		var child_node: Node3D
		for link in _links:
			if link.name == child_name:
				child_node = link.node
		if "origin" in joint:
			child_node.position = joint.origin.xyz * scale
			child_node.rotation = joint.origin.rpy
#		print("add child %s to parent %s" % [child_node, parent_node])
		parent_node.add_child(child_node)
		var joint_node : Joint3D
		
		match joint.type:
			"fixed":
				joint_node = Generic6DOFJoint3D.new()
				
			"free_wheel":
				joint_node = PinJoint3D.new()

			"continuous":
				joint_node = HingeJoint3D.new()
				if joint.axis != Vector3.UP:
					var new_basis = Basis.looking_at(joint.axis)
					joint_node.transform.basis = new_basis
#				joint_node.rotate_x(-PI/2) # Y axis -> Z axis
				var joint_script := GDScript.new()
				joint_script.source_code = get_continuous_joint_script()
				joint_node.set_script(joint_script)
			"revolute":
				joint_node = Generic6DOFJoint3D.new()
				
		joint_node.name = joint.name
		joint_node.node_a = ^"../.."
		joint_node.node_b = ^"../"
		joint_node.unique_name_in_owner = true
		child_node.add_child(joint_node)
		
	var root_node: Node3D
	for link in _links:
#		print("parent of %s is %s" % [link.node, link.node.get_parent()])
		if link.node.get_parent() == null:
			root_node = link.node
			break
			
	return root_node
	
func kinematics_scene_owner_of(root_node: Node3D):
	add_owner(root_node, root_node.get_children())
	return root_node
		
func add_owner(owner_node, nodes: Array):
	for node in nodes:
		node.owner = owner_node
		if node.get_child_count():
			add_owner(owner_node, node.get_children())

func get_root_node(filename) -> Node3D:
	var err = parser.open(filename)
	if err:
		printerr("Error opening URDF file: ", err)
		return
		
	var root_node := Node3D.new()
	while true:
		if parser.read() != OK: # Ending parse XML file
#			print("Ending link parser")
			break
		var type = parser.get_node_type()
		if type == XMLParser.NODE_ELEMENT:
			var node_name = parser.get_node_name()
			if node_name == "robot":
				var attribut_count = parser.get_attribute_count()
				var robot_dict: Dictionary
				for idx in attribut_count:
					var name = parser.get_attribute_name(idx)
					var value = parser.get_attribute_value(idx)
					robot_dict[name] = value
				root_node.name = robot_dict.name
				break
				
	return root_node

func add_script_to(root_node: Node3D):
	var ready_script = """
func _ready():
	pass"""

	var process_script = """
func _process(delta: float):
	pass"""
	
	_script.source_code = """extends Node3D
"""
	if "control" in _gobotics and "type" in _gobotics.control:
#		print_debug("type: ", _gobotics.control.type)
		
		match _gobotics.control.type:
			"diff_drive":
				_script.source_code += """
var control : DiffDriveExt
"""
				ready_script += """
	control = DiffDriveExt.new(%%%s, %%%s)""" % [_gobotics.control.right_wheel_joint, _gobotics.control.left_wheel_joint]

				process_script += """
	control.update_input()"""
	if "category" in _gobotics:
		root_node.add_to_group(_gobotics.category.to_upper(), true)
		
	var continuous_joints_props = get_continuous_joints_properties(root_node)
#	print_debug(continuous_joints_props)
	for prop in continuous_joints_props:
#		var onready_var = "@onready var %s = get_node(\"%s\")\n" % [prop.name, prop.path]
#		_script.source_code += onready_var
		var export_target_vel = """@export var %s_target_velocity: float = 0:
	set(value):
		%s_target_velocity = value
		var joint = get_node_or_null("%s")
		if joint:
			joint.target_velocity = value
""" % [prop.name, prop.name, prop.path]
		_script.source_code += export_target_vel
	
	_script.source_code += ready_script
	_script.source_code += process_script
	root_node.set_script(_script)
	
func get_continuous_joints_properties(root_node: Node3D) -> Array:
	var joints_properties = Array()
	
	for child in root_node.get_children():
		if child is HingeJoint3D:
			var name = child.name
			var root = child.owner
			var dict = {
				name = child.name,
				path = root.get_path_to(child),
			}
			joints_properties.append(dict)
		if child.get_child_count() != 0:
			var props: Array = get_continuous_joints_properties(child)
			if not props.is_empty():
				joints_properties.append_array(props)
		
	return joints_properties


func get_continuous_joint_script() -> String:
	var source_code = """extends HingeJoint3D
@onready var link: RigidBody3D = $".."
var target_velocity: float = 0.0:
	set(value):
		target_velocity = value
		set_param(PARAM_MOTOR_TARGET_VELOCITY, target_velocity)

func _ready():
	link.can_sleep = false
	set_flag(FLAG_ENABLE_MOTOR, true)
	set_param(PARAM_MOTOR_TARGET_VELOCITY, target_velocity)

"""
	return source_code
