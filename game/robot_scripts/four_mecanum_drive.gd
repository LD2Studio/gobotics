extends Node
class_name FourMecanumDrive

class Robot:
	var base_link: RigidBody3D
	var front_right_wheel
	var front_left_wheel
	var back_right_wheel
	var back_left_wheel
	var state: int
	var task_finished: bool = true
	
var robot = Robot.new()
var max_speed: float

func _init(base_link: RigidBody3D, front_right_wheel_joint, front_left_wheel_joint, back_right_wheel_joint, back_left_wheel_joint, new_max_speed: float = 5.0):
	robot.base_link = base_link
	robot.front_right_wheel = front_right_wheel_joint
	robot.front_left_wheel = front_left_wheel_joint
	robot.back_right_wheel = back_right_wheel_joint
	robot.back_left_wheel = back_left_wheel_joint
	max_speed = new_max_speed
	
func _ready():
	name = &"FourMecanumDrive"

func _physics_process(_delta):
	if get_parent().activated and not get_parent().python.activate:
		var speed = max_speed if Input.is_action_pressed("BOOST") else max_speed/2.0
		
		if Input.is_action_pressed("FORWARD"):
			robot.front_left_wheel.target_velocity = speed
			robot.front_right_wheel.target_velocity = speed
			robot.back_left_wheel.target_velocity = speed
			robot.back_right_wheel.target_velocity = speed
			
		elif Input.is_action_pressed("BACKWARD"):
			robot.front_left_wheel.target_velocity = -speed
			robot.front_right_wheel.target_velocity = -speed
			robot.back_left_wheel.target_velocity = -speed
			robot.back_right_wheel.target_velocity = -speed
			
		elif Input.is_action_pressed("TURN_RIGHT"):
			robot.front_left_wheel.target_velocity = speed
			robot.front_right_wheel.target_velocity = -speed
			robot.back_left_wheel.target_velocity = speed
			robot.back_right_wheel.target_velocity = -speed
			
		elif Input.is_action_pressed("TURN_LEFT"):
			robot.front_left_wheel.target_velocity = -speed
			robot.front_right_wheel.target_velocity = speed
			robot.back_left_wheel.target_velocity = -speed
			robot.back_right_wheel.target_velocity = speed
			
		elif Input.is_action_pressed("RIGHT"):
			robot.front_left_wheel.target_velocity = speed
			robot.front_right_wheel.target_velocity = -speed
			robot.back_left_wheel.target_velocity = -speed
			robot.back_right_wheel.target_velocity = speed
			
		elif Input.is_action_pressed("LEFT"):
			robot.front_left_wheel.target_velocity = -speed
			robot.front_right_wheel.target_velocity = speed
			robot.back_left_wheel.target_velocity = speed
			robot.back_right_wheel.target_velocity = -speed
			
		else:
			robot.front_left_wheel.target_velocity = 0
			robot.front_right_wheel.target_velocity = 0
			robot.back_left_wheel.target_velocity = 0
			robot.back_right_wheel.target_velocity = 0

## Functions exposed to Python
func get_pose() -> PackedFloat32Array:
	var pose = PackedFloat32Array(
		[
			robot.base_link.global_position.x / 10.0,
			-robot.base_link.global_position.z / 10.0,
			robot.base_link.global_position.y / 10.0,
			robot.base_link.rotation.y
		]
	)
	return pose

func set_pose(x: float, y: float, a: float):
	robot.base_link.global_position.x = x * 10.0
	robot.base_link.global_position.z = -y * 10.0
	robot.base_link.rotation.y = a

func move(front_right_vel: float, front_left_vel: float, back_right_vel: float, back_left_vel: float):
	robot.front_right_wheel.target_velocity = front_right_vel
	robot.front_left_wheel.target_velocity = front_left_vel
	robot.back_right_wheel.target_velocity = back_right_vel
	robot.back_left_wheel.target_velocity = back_left_vel
