class_name ThreeOmniDrive extends Node

@export var wheel_1: String
@export var wheel_2: String
@export var wheel_3: String
@export var max_speed: float

var wheel_1_joint: Node3D
var wheel_2_joint: Node3D
var wheel_3_joint: Node3D

enum Task {
	IDLE,
	MOVE,
	MOVE_TO,
}

var _current_task: Task = Task.IDLE

func setup():
	wheel_1_joint = get_parent().get_node_or_null("%%%s" % [wheel_1])
	wheel_2_joint = get_parent().get_node_or_null("%%%s" % [wheel_2])
	wheel_3_joint = get_parent().get_node_or_null("%%%s" % [wheel_3])
	
func get_wheel_speed(x_speed : float, y_speed : float, z_ang_speed : float):
	var v1 = -0.57*x_speed + 0.33*y_speed + 0.04*z_ang_speed;
	var v2 = 0.57*x_speed + 0.33*y_speed + 0.04*z_ang_speed;
	var v3 = -0.67*y_speed + 0.04*z_ang_speed;
	return [v1, v2, v3]

func command(_delta: float):
	if _current_task == Task.IDLE:
		var speed = max_speed if Input.is_action_pressed("BOOST") else max_speed/2.0
		var wheel_speeds = [];
		
		if Input.is_action_pressed("FORWARD"):
			wheel_speeds = get_wheel_speed(-speed, 0, 0);
			
		elif Input.is_action_pressed("BACKWARD"):
			wheel_speeds = get_wheel_speed(speed, 0, 0);
			
		elif Input.is_action_pressed("TURN_RIGHT"):
			wheel_speeds = get_wheel_speed(0, 0, -speed/0.04);
			
		elif Input.is_action_pressed("TURN_LEFT"):
			wheel_speeds = get_wheel_speed(0, 0, speed/0.04);
			
		elif Input.is_action_pressed("RIGHT"):
			wheel_speeds = get_wheel_speed(0, -speed, 0);
			
		elif Input.is_action_pressed("LEFT"):
			wheel_speeds = get_wheel_speed(0, speed, 0);
			
		else:
			wheel_speeds = [0,0,0]
			
		wheel_1_joint.target_velocity = wheel_speeds[0]
		wheel_2_joint.target_velocity = wheel_speeds[1]
		wheel_3_joint.target_velocity = wheel_speeds[2]

## Functions exposed to Python

func move_omni_drive(wheel_1_vel: float, wheel_2_vel: float, wheel_3_vel: float):
	wheel_1_joint.target_velocity = wheel_1_vel
	wheel_2_joint.target_velocity = wheel_2_vel
	wheel_3_joint.target_velocity = wheel_3_vel
	
	_current_task = Task.MOVE
	
	if wheel_1_vel == 0.0 and wheel_2_vel == 0.0 and wheel_3_vel == 0.0:
		_current_task = Task.IDLE
