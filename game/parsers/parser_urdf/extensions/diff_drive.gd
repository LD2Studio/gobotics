extends AssetExt
class_name DiffDriveExt

var robot = Robot.new()


class Robot:
	var frame: RigidBody3D
	var right_wheel: Joint3D
	var left_wheel: Joint3D
	var max_speed: float
	var state: int
	var task_finished: bool = true
	var manual_control: bool = true


func _init(right_wheel_joint: Joint3D, left_wheel_joint: Joint3D, max_speed: float = 5.0):
	robot.right_wheel = right_wheel_joint
	robot.left_wheel = left_wheel_joint
	robot.max_speed = max_speed


func update_input():
	if robot.manual_control:
		if Input.is_action_pressed("FORWARD"):
			if Input.is_action_pressed("RIGHT"):
				robot.right_wheel.target_velocity = 0
			else:
				robot.right_wheel.target_velocity = robot.max_speed
			if Input.is_action_pressed("LEFT"):
				robot.left_wheel.target_velocity = 0
			else:
				robot.left_wheel.target_velocity = robot.max_speed
		elif Input.is_action_pressed("BACKWARD"):
			robot.right_wheel.target_velocity = -robot.max_speed
			robot.left_wheel.target_velocity = -robot.max_speed
		elif Input.is_action_pressed("RIGHT"):
			robot.right_wheel.target_velocity = -robot.max_speed
			robot.left_wheel.target_velocity = robot.max_speed
		elif Input.is_action_pressed("LEFT"):
			robot.right_wheel.target_velocity = robot.max_speed
			robot.left_wheel.target_velocity = -robot.max_speed
		else:
			robot.right_wheel.target_velocity = 0
			robot.left_wheel.target_velocity = 0
