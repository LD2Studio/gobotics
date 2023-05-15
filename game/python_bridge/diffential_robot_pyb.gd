extends RobotsPythonBridge
class_name DifferentialRobotPythonBridge

var left_wheel: RigidBody3D
var right_wheel: RigidBody3D

func set_vl(speed: float):
	left_wheel.rotation_speed = speed

func set_vr(speed: float):
	right_wheel.rotation_speed = speed
