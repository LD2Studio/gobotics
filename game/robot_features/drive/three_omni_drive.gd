class_name ThreeOmniDrive extends Node

@export var wheel_1: String
@export var wheel_2: String
@export var wheel_3: String
@export var max_speed: float
@export var base_link: RigidBody3D

var wheel_1_joint: Node3D
var wheel_2_joint: Node3D
var wheel_3_joint: Node3D
var robot: Robot

enum Task {
	IDLE,
	MOVE,
	MOVE_TO,
	ROTATE_TO,
}

class Robot:
	var task: Task = Task.IDLE
	var finished_task := true
	var target_pos := Vector2.ZERO
	var target_angle: float
	var speed: float
	var rotate_dir: float
	var square_precision: float
	var response: float


func _ready() -> void:
	robot = Robot.new()


func _physics_process(_delta: float) -> void:
	match robot.task:
		Task.IDLE:
			pass
		Task.MOVE_TO:
			_move_to_process()
		Task.ROTATE_TO:
			_rotate_to_process()


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
	if robot.task == Task.IDLE:
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
	
	robot.task = Task.MOVE
	
	if wheel_1_vel == 0.0 and wheel_2_vel == 0.0 and wheel_3_vel == 0.0:
		robot.task = Task.IDLE


func move_to(new_position: Vector2, new_speed: float,
			precision: float = 0.01, response: float = 20.0):
	#print("Move to %s at %f m/s" % [new_position, new_speed])
	robot.task = Task.MOVE_TO
	robot.finished_task = false
	robot.target_pos = new_position
	robot.speed = new_speed
	robot.square_precision = precision**2
	robot.response = response


func rotate_to(new_angle: float, new_speed: float) -> void:
	
	robot.finished_task = false
	robot.target_angle = new_angle
	robot.speed = new_speed
	var angle = base_link.rotation.y
	k = 0
	
	if robot.target_angle < angle:
		if abs(robot.target_angle - angle) < abs(robot.target_angle + TAU - angle):
			robot.rotate_dir = 1 # sens horaire
			if angle < robot.target_angle:
				robot.target_angle -= TAU
			#print("1")
		else:
			robot.rotate_dir = -1 # sens anti-horaire
			if angle > robot.target_angle:
				robot.target_angle += TAU
			#print("2")
	else:
		if abs(robot.target_angle - angle) < abs(robot.target_angle - TAU - angle):
			robot.rotate_dir = -1
			if angle > robot.target_angle:
				robot.target_angle += TAU
			#print("3")
		else:
			robot.rotate_dir = 1
			if angle < robot.target_angle:
				robot.target_angle -= TAU
			#print("4")
	
	prev_angle = 0
	robot.task = Task.ROTATE_TO


func finished_task() -> bool:
	return robot.finished_task


func stop_task() -> void:
	robot.task = Task.IDLE
	robot.finished_task = true


func _move_to_process() -> void:
	var current_pos := Vector2(
			base_link.global_position.x/GPSettings.SCALE,
			-base_link.global_position.z/GPSettings.SCALE)
	var d_square = pow((robot.target_pos.x - current_pos.x), 2)\
			+ pow((robot.target_pos.y - current_pos.y), 2)
	#print(d_square)
	
	if d_square > robot.square_precision:
		var dir: Vector2 = current_pos.direction_to(robot.target_pos)
		#print("dir: ", dir)
		var global_vel: Vector2 = dir * robot.speed
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
		robot.task = Task.IDLE
		robot.finished_task = true


var prev_angle = 0
var k: int = 0

func _rotate_to_process():
	var angle = base_link.rotation.y + k*TAU
	#print("prev angle: %f, angle: %f, target: %f, k: %d" %[prev_angle, angle, robot.target_angle, k])
	if robot.rotate_dir == 1: # Sens horaire
		if abs(prev_angle - angle) > (TAU - 0.05):
			k = -1
		if angle > robot.target_angle:
			var wheels_speed = get_wheel_speed(0, 0,
			-robot.speed/0.04 * robot.rotate_dir);
			set_wheels_speed(wheels_speed[0], wheels_speed[1], wheels_speed[2])
		else:
			set_wheels_speed(0,0,0)
			robot.task = Task.IDLE
			robot.finished_task = true
	else: # Sens anti-horaire
		if abs(prev_angle - angle) > (TAU - 0.05):
			k = +1
		if angle < robot.target_angle:
			var wheels_speed = get_wheel_speed(0, 0,
			-robot.speed/0.04 * robot.rotate_dir);
			set_wheels_speed(wheels_speed[0], wheels_speed[1], wheels_speed[2])
		else:
			set_wheels_speed(0,0,0)
			robot.task = Task.IDLE
			robot.finished_task = true
	prev_angle = angle
	
