extends Node3D

var frozen: bool = true:
	set(value):
		frozen = value
		for node in behavior_nodes:
			#print("node %s frozen %s" % [node.name,frozen])
			if node.get("frozen") == null:
				node.set_physics_process(!frozen)
			else:
				node.frozen = frozen


var behavior_nodes : Array[Node] = []

func _ready():
	for child in get_children():
		match child.name:
			"RobotBase", "ControlRobot":
				behavior_nodes.append(child)
				child.setup()
				child.set_physics_process(!frozen)


func activate_python(enable: bool, udp_port: int):
	var python_bridge : PythonBridge = get_node_or_null("PythonBridge")
	if python_bridge:
		python_bridge.port = udp_port
		python_bridge.activate = enable
