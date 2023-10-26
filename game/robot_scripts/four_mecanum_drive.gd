class_name FourMecanumDrive extends Node

@export var activated: bool = false
@export var front_right_wheel: String
@export var front_left_wheel: String
@export var back_right_wheel: String
@export var back_left_wheel: String
@export var max_speed: float

var front_right_wheel_joint: Node3D
var front_left_wheel_joint: Node3D
var back_right_wheel_joint: Node3D
var back_left_wheel_joint: Node3D
	
func setup():
	front_right_wheel_joint = get_parent().get_node_or_null("%%%s" % [front_right_wheel])
	front_left_wheel_joint = get_parent().get_node_or_null("%%%s" % [front_left_wheel])
	back_right_wheel_joint = get_parent().get_node_or_null("%%%s" % [back_right_wheel])
	back_left_wheel_joint = get_parent().get_node_or_null("%%%s" % [back_left_wheel])

func _input(event):
	if event is InputEventKey and activated:
		var speed = max_speed if Input.is_action_pressed("BOOST") else max_speed/2.0
		
		if Input.is_action_pressed("FORWARD"):
			front_left_wheel_joint.target_velocity = speed
			front_right_wheel_joint.target_velocity = speed
			back_left_wheel_joint.target_velocity = speed
			back_right_wheel_joint.target_velocity = speed
			
		elif Input.is_action_pressed("BACKWARD"):
			front_left_wheel_joint.target_velocity = -speed
			front_right_wheel_joint.target_velocity = -speed
			back_left_wheel_joint.target_velocity = -speed
			back_right_wheel_joint.target_velocity = -speed
			
		elif Input.is_action_pressed("TURN_RIGHT"):
			front_left_wheel_joint.target_velocity = speed
			front_right_wheel_joint.target_velocity = -speed
			back_left_wheel_joint.target_velocity = speed
			back_right_wheel_joint.target_velocity = -speed
			
		elif Input.is_action_pressed("TURN_LEFT"):
			front_left_wheel_joint.target_velocity = -speed
			front_right_wheel_joint.target_velocity = speed
			back_left_wheel_joint.target_velocity = -speed
			back_right_wheel_joint.target_velocity = speed
			
		elif Input.is_action_pressed("RIGHT"):
			front_left_wheel_joint.target_velocity = speed
			front_right_wheel_joint.target_velocity = -speed
			back_left_wheel_joint.target_velocity = -speed
			back_right_wheel_joint.target_velocity = speed
			
		elif Input.is_action_pressed("LEFT"):
			front_left_wheel_joint.target_velocity = -speed
			front_right_wheel_joint.target_velocity = speed
			back_left_wheel_joint.target_velocity = speed
			back_right_wheel_joint.target_velocity = -speed
			
		else:
			front_left_wheel_joint.target_velocity = 0
			front_right_wheel_joint.target_velocity = 0
			back_left_wheel_joint.target_velocity = 0
			back_right_wheel_joint.target_velocity = 0

## Functions exposed to Python

func move(front_right_vel: float, front_left_vel: float, back_right_vel: float, back_left_vel: float):
	front_left_wheel_joint.target_velocity = front_left_vel
	front_right_wheel_joint.target_velocity = front_right_vel
	back_left_wheel_joint.target_velocity = back_left_vel
	back_right_wheel_joint.target_velocity = back_right_vel
