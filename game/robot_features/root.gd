extends Node3D

var frozen: bool = true:
	set(value):
		frozen = value
		for node in behavior_nodes:
			#print("node %s frozen %s" % [node.name,frozen])
			node.set_physics_process(!frozen)

@export var activated: bool = false:
	set(value):
		activated = value
		for node in behavior_nodes:
			node.activated = activated

@export var behavior_nodes : Array[Node] = []

func _ready():
	#print("behavior nodes: ", behavior_nodes)
	for node in behavior_nodes:
		node.setup()
		node.set_physics_process(!frozen)


func activate_python(enable: bool, udp_port: int):
	var python_bridge : PythonBridge = get_node_or_null("PythonBridge")
	if python_bridge:
		python_bridge.port = udp_port
		python_bridge.activate = enable
