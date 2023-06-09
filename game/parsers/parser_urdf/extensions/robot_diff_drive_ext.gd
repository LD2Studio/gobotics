extends RobotExt
class_name RobotDiffDriveExt

var robot = Robot.new()

var manual: bool = true
var max_speed: float

class Robot:
	var frame: RigidBody3D
	var right_wheel: Joint3D
	var left_wheel: Joint3D
	var state: int
	var task_finished: bool = true


func _init(right_wheel_joint: Joint3D, left_wheel_joint: Joint3D, max_speed: float = 5.0):
	super()
	robot.right_wheel = right_wheel_joint
	robot.left_wheel = left_wheel_joint
	self.max_speed = max_speed


func update_input():
	if manual:
		var speed = max_speed if Input.is_action_pressed("BOOST") else max_speed/2.0
		
		if Input.is_action_pressed("FORWARD"):
			if Input.is_action_pressed("RIGHT"):
				robot.right_wheel.target_velocity = 0
			else:
				robot.right_wheel.target_velocity = speed * Input.get_action_strength("FORWARD")
			if Input.is_action_pressed("LEFT"):
				robot.left_wheel.target_velocity = 0 
			else:
				robot.left_wheel.target_velocity = speed * Input.get_action_strength("FORWARD")
		elif Input.is_action_pressed("BACKWARD"):
			if Input.is_action_pressed("RIGHT"):
				robot.right_wheel.target_velocity = 0
			else:
				robot.right_wheel.target_velocity = -speed * Input.get_action_strength("BACKWARD")
			if Input.is_action_pressed("LEFT"):
				robot.left_wheel.target_velocity = 0
			else:
				robot.left_wheel.target_velocity = -speed * Input.get_action_strength("BACKWARD")
		elif Input.is_action_pressed("RIGHT"):
			robot.right_wheel.target_velocity = -speed * Input.get_action_strength("RIGHT")
			robot.left_wheel.target_velocity = speed * Input.get_action_strength("RIGHT")
		elif Input.is_action_pressed("LEFT"):
			robot.right_wheel.target_velocity = speed * Input.get_action_strength("LEFT")
			robot.left_wheel.target_velocity = -speed * Input.get_action_strength("LEFT")
		else:
			robot.right_wheel.target_velocity = 0
			robot.left_wheel.target_velocity = 0

