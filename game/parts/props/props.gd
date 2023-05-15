extends Node3D
class_name Props

@onready var python = PropsPythonBridge.new()

func _enter_tree():
	add_to_group("PYTHON")
	
func init():
	python.root_rigid_body = get_child(0)
	add_child(python)
	
