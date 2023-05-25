extends Node3D
class_name Props

@onready var python = PythonBridge.new(4243)

var _rigid_node: RigidBody3D

func _enter_tree():
	add_to_group("PYTHON")
	
func init():
	add_child(python)
	assert(get_child(0) is RigidBody3D, "This props is not physics")
	_rigid_node = get_child(0)
	
func get_pos() -> Vector3:
	return _rigid_node.global_position/10.0

func set_pos(value: Vector3):
	_rigid_node.global_position = value*10.0
