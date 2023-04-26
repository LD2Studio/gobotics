extends Node3D

func _ready():
	pass # Replace with function body.
	var parser_mujoco = XMLParser.new()
	var err = parser_mujoco.open("res://examples/essai.xml")
#	print(err)
	
#	var line: int
	var nodes_stack = Array()
	while true:
#		print("-----> line: ", parser_mujoco.get_current_line())
		if parser_mujoco.read() != OK:
			break
		if parser_mujoco.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name = parser_mujoco.get_node_name()
			print("Node Element: name = ", parser_mujoco.get_node_name())
			match node_name:
				"mujoco":
#					print("XML Mujoco")
					pass
				"worldbody":
					print("Add World")
					var world = Node3D.new()
					world.name = "WorldBody"
					add_child(world)
					nodes_stack.append(world)
				"body":
					var body = RigidBody3D.new()
					body.freeze = true
					nodes_stack.back().add_child(body)
					nodes_stack.append(body)
				"geom":
					var geom = MeshInstance3D.new()
					geom.mesh = BoxMesh.new()
					nodes_stack.back().add_child(geom)
				"joint":
					pass
		elif parser_mujoco.get_node_type() == XMLParser.NODE_TEXT:
			print("Node Text: %d attributes" % parser_mujoco.get_attribute_count())
		elif parser_mujoco.get_node_type() == XMLParser.NODE_ELEMENT_END:
			print("Remove last node")
			nodes_stack.pop_back()
			
		else:
			print("Other node: ", parser_mujoco.get_node_type())
			
	print("ending")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
