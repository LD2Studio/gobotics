class_name ThreeOmniDrive extends Node

@export var wheel_1: String
@export var wheel_2: String
@export var wheel_3: String
@export var max_speed: float
@export var base_link: RigidBody3D

var wheel_1_joint: Node3D
var wheel_2_joint: Node3D
var wheel_3_joint: Node3D
var robot_settings: RobotSettings

enum Task {
	IDLE,
	MOVE,
	MOVE_TO,
}

class RobotSettings:
	var task: Task = Task.IDLE
	var finished_task := true
	var target_pos := Vector2.ZERO
	var speed: float
	var square_precision: float
	var response: float


func _ready() -> void:
	robot_settings = RobotSettings.new()


func _physics_process(_delta: float) -> void:
	match robot_settings.task:
		Task.IDLE:
			pass
			#print("IDLE (%s)" % [get_parent().name])
		Task.MOVE_TO:
			#print("MOVE TO (%s)" % [get_parent().name])
			_move_to_process()


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
	if robot_settings.task == Task.IDLE:
		var speed = max_speed if Input.is_action_pressed("BOOST") else max_speed/2.0
		var wheel_speeds = []
		
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

func set_wheels_speed(wheel_1_vel: float, wheel_2_vel: float, wheel_3_vel: float):
	wheel_1_joint.target_velocity = wheel_1_vel
	wheel_2_joint.target_velocity = wheel_2_vel
	wheel_3_joint.target_velocity = wheel_3_vel


## Functions exposed to Python

func move_omni_drive(wheel_1_vel: float, wheel_2_vel: float, wheel_3_vel: float):
	wheel_1_joint.target_velocity = wheel_1_vel
	wheel_2_joint.target_velocity = wheel_2_vel
	wheel_3_joint.target_velocity = wheel_3_vel
	
	robot_settings.task = Task.MOVE
	
	if wheel_1_vel == 0.0 and wheel_2_vel == 0.0 and wheel_3_vel == 0.0:
		robot_settings.task = Task.IDLE


func move_to(new_position: Vector2, new_speed: float,
			precision: float = 0.01, response: float = 20.0):
	#print("Move to %s at %f m/s" % [new_position, new_speed])
	robot_settings.task = Task.MOVE_TO
	robot_settings.finished_task = false
	robot_settings.target_pos = new_position
	robot_settings.speed = new_speed
	robot_settings.square_precision = precision**2
	robot_settings.response = response


func finished_task() -> bool:
	return robot_settings.finished_task


func _move_to_process() -> void:
	var current_pos := Vector2(
			base_link.global_position.x/GPSettings.SCALE,
			-base_link.global_position.z/GPSettings.SCALE)
	var d_square = pow((robot_settings.target_pos.x - current_pos.x), 2)\
			+ pow((robot_settings.target_pos.y - current_pos.y), 2)
	#print(d_square)
	
	if d_square > robot_settings.square_precision:
		var dir: Vector2 = current_pos.direction_to(robot_settings.target_pos)
		#print("dir: ", dir)
		var global_vel: Vector2 = dir * robot_settings.speed
		#print("global vel: ", global_vel)
		var angle: float = base_link.rotation.y
		#print("angle: ", angle)
		var v_x: float = global_vel.x * cos(angle) + global_vel.y * sin(angle)
		var v_y: float = -global_vel.x * sin(angle) + global_vel.y * cos(angle)
		#print("v_x: %f, v_y: %f" % [v_x, v_y])
		var wheels_speed: Array = get_wheel_speed(-v_x, v_y, 0)
		set_wheels_speed(wheels_speed[0], wheels_speed[1], wheels_speed[2])
	else:
		set_wheels_speed(0,0,0)
		robot_settings.task = Task.IDLE
		robot_settings.finished_task = true
