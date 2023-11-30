extends Node3D

@export var activated: bool = false:
	set(value):
		activated = value
		for node in behavior_nodes:
			node.activated = activated

@export var behavior_nodes : Array[Node] = []

func _ready():
#	print("behavior nodes: ", behavior_nodes)
	for node in behavior_nodes:
		node.setup()

func activate_python(enable: bool, udp_port: int):
	var python_bridge : PythonBridge = get_node_or_null("PythonBridge")
	if python_bridge:
		python_bridge.port = udp_port
		python_bridge.activate = enable
