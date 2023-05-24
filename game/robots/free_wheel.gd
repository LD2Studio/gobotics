@tool
#@icon("res://addons/actuator3d/nodes/rotation_actuator_3d.svg")
## Free Wheel 3dof
class_name Rotation3DOF
extends RigidBody3D

@export var exclude_nodes_from_collision: bool = true

var _joint := Generic6DOFJoint3D.new()

func _enter_tree() -> void:
	_joint.name = "3DOF"
	_joint.set("angular_limit_x/enabled", false)
	_joint.set("angular_limit_y/enabled", false)
	_joint.set("angular_limit_z/enabled", false)
	_joint.node_a = ^"../.."
	_joint.node_b = ^"../"
	_joint.exclude_nodes_from_collision = exclude_nodes_from_collision
	add_child(_joint)

func _exit_tree() -> void:
	remove_child(_joint)
	
