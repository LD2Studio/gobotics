class_name DiffDrive extends Node

@export var frozen: bool = true:
	set(value):
		frozen = value
		set_physics_process(!frozen)
		if frozen and robot_settings != null:
			if right_wheel_joint != null and left_wheel_joint != null:
				move_diff_drive(0,0)

@export var right_wheel: String
@export var left_wheel: String
@export var max_speed: float
@export var base_link: RigidBody3D

var right_wheel_joint: Node3D
var left_wheel_joint: Node3D

enum Task {
	IDLE,
	MOVE,
	MOVE_TO,
}

class RobotSettings:
	var task: Task = Task.IDLE
	var finished_task: bool = true
	var target_pos := Vector2.ZERO
	var speed: float
	var square_precision: float
	var response: float

var robot_settings: RobotSettings

func _ready() -> void:
	set_physics_process(!frozen)
	robot_settings = RobotSettings.new()


func _physics_process(_delta: float) -> void:
	match robot_settings.task:
		Task.IDLE:
			pass
		Task.MOVE_TO:
			_move_to_process()


#region PUBLIC METHODS

func setup():
	right_wheel_joint = get_parent().get_node_or_null("%%%s" % [right_wheel])
	left_wheel_joint = get_parent().get_node_or_null("%%%s" % [left_wheel])


func command(_delta: float):
	if robot_settings.task == Task.IDLE:
		var speed = max_speed if Input.is_action_pressed("BOOST") else max_speed/2.0
		
		if Input.is_action_pressed("FORWARD"):
			if Input.is_action_pressed("RIGHT"):
				right_wheel_joint.target_velocity = 0
			else:
				right_wheel_joint.target_velocity = speed
			if Input.is_action_pressed("LEFT"):
				left_wheel_joint.target_velocity = 0 
			else:
				left_wheel_joint.target_velocity = speed
		elif Input.is_action_pressed("BACKWARD"):
			if Input.is_action_pressed("RIGHT"):
				right_wheel_joint.target_velocity = 0
			else:
				right_wheel_joint.target_velocity = -speed
			if Input.is_action_pressed("LEFT"):
				left_wheel_joint.target_velocity = 0
			else:
				left_wheel_joint.target_velocity = -speed
		elif Input.is_action_pressed("RIGHT"):
			right_wheel_joint.target_velocity = -speed
			left_wheel_joint.target_velocity = speed
		elif Input.is_action_pressed("LEFT"):
			right_wheel_joint.target_velocity = speed
			left_wheel_joint.target_velocity = -speed
		else:
			right_wheel_joint.target_velocity = 0
			left_wheel_joint.target_velocity = 0

#endregion

#region PUBLIC METHODS EXPOSED TO PYTHON_BRIDGE

func move_diff_drive(right_vel: float, left_vel: float):
	_set_wheel_speed(right_vel, left_vel)
	robot_settings.task = Task.MOVE
	
	if right_vel == 0.0 and left_vel == 0.0:
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


func stop_task() -> void:
	robot_settings.task = Task.IDLE
	robot_settings.finished_task = true

#endregion

func _set_wheel_speed(right_vel: float, left_vel: float):
	right_wheel_joint.target_velocity = right_vel
	left_wheel_joint.target_velocity = left_vel


func _move_to_process() -> void:
	var current_pos := Vector2(
			base_link.global_position.x/GPSettings.SCALE,
			-base_link.global_position.z/GPSettings.SCALE)
	var d_square = pow((robot_settings.target_pos.x - current_pos.x), 2)\
			+ pow((robot_settings.target_pos.y - current_pos.y), 2)
	
	if d_square > robot_settings.square_precision:
		var forward_3d_dir :Vector3 = base_link.global_transform.basis.x
		var dir := Vector2(forward_3d_dir.x, -forward_3d_dir.z)
		var err_theta: float = dir.angle_to(robot_settings.target_pos - current_pos)
		const MAX_SPEED = 20
		var omega_c: float = robot_settings.response * err_theta
		_set_wheel_speed(clampf(robot_settings.speed + omega_c, -MAX_SPEED, MAX_SPEED),
			clampf(robot_settings.speed - omega_c, -MAX_SPEED, MAX_SPEED))
	else:
		_set_wheel_speed(0,0)
		robot_settings.task = Task.IDLE
		robot_settings.finished_task = true
