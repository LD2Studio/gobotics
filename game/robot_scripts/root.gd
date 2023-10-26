extends Node3D

@export var activated: bool = false:
	set(value):
		activated = value
		for node in behavior_nodes:
			node.activated = activated


@export var behavior_nodes : Array[Node] = []
