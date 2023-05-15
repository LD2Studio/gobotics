class_name PropsPythonBridge
extends PythonBridge

var root_rigid_body: RigidBody3D

func get_position() -> Vector3:
	return root_rigid_body.global_position/10.0
