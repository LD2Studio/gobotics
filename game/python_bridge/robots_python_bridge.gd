extends PythonBridge
class_name RobotsPythonBridge

var root_rigid_body: RigidBody3D

func get_pose() -> PackedFloat32Array:
	var pose = PackedFloat32Array([
		root_rigid_body.global_position.x / 10.0,
		root_rigid_body.global_position.z / 10.0,
		root_rigid_body.rotation.y])
	return pose

func set_pose(x: float, z: float, a: float):
	root_rigid_body.global_position.x = x * 10.0
	root_rigid_body.global_position.z = z * 10.0
	root_rigid_body.rotation.y = a
