class_name DiffDrive extends Node

@export var activated: bool = false
@export var frozen: bool = true:
	set(value):
		frozen = value
		set_physics_process(!frozen)
		if frozen and _move_to_settings != null:
			_move_to_settings.task = Task.IDLE
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
	MOVE_TO,
}

class MoveToSettings:
	var task: Task = Task.IDLE
	var finished_task: bool = true
	var target_pos := Vector2.ZERO
	var speed: float
	var square_precision: float
	var response: float

var _move_to_settings: MoveToSettings

func _ready() -> void:
	set_physics_process(!frozen)
	_move_to_settings = MoveToSettings.new()

func _input(event):
	if event is InputEventKey and activated:
#		print(event)
		var speed = max_speed if Input.is_action_pressed("BOOST") else max_speed/2.0
#		print("FORWARD: ", event.is_action("FORWARD"))
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

func _physics_process(_delta: float) -> void:
	match _move_to_settings.task:
		Task.IDLE:
			pass
			#print("IDLE (%s)" % [get_parent().name])
		Task.MOVE_TO:
			#print("MOVE TO (%s)" % [get_parent().name])
			_path_control_process()


#region PUBLIC METHODS

func setup():
	right_wheel_joint = get_parent().get_node_or_null("%%%s" % [right_wheel])
	left_wheel_joint = get_parent().get_node_or_null("%%%s" % [left_wheel])
	
#endregion

#region PUBLIC METHODS EXPOSED TO PYTHON_BRIDGE

func move_diff_drive(right_vel: float, left_vel: float):
	right_wheel_joint.target_velocity = right_vel
	left_wheel_joint.target_velocity = left_vel


func move_to(new_position: Vector2, new_speed: float,
			precision: float = 0.01, response: float = 20.0):
	#print("Move to %s at %f m/s" % [new_position, new_speed])
	_move_to_settings.task = Task.MOVE_TO
	_move_to_settings.finished_task = false
	_move_to_settings.target_pos = new_position
	_move_to_settings.speed = new_speed
	_move_to_settings.square_precision = precision**2
	_move_to_settings.response = response

func finished_task() -> bool:
	return _move_to_settings.finished_task

#endregion

func _path_control_process() -> void:
	#print("path control")
	var current_pos := Vector2(
			base_link.global_position.x/GPSettings.SCALE,
			-base_link.global_position.z/GPSettings.SCALE)
	var d_square = pow((_move_to_settings.target_pos.x - current_pos.x), 2)\
			+ pow((_move_to_settings.target_pos.y - current_pos.y), 2)
	#print(d_square)
	
	if d_square > _move_to_settings.square_precision:
		var forward_3d_dir :Vector3 = base_link.global_transform.basis.x
		var dir := Vector2(forward_3d_dir.x, -forward_3d_dir.z)
		var err_theta: float = dir.angle_to(_move_to_settings.target_pos - current_pos)
		const MAX_SPEED = 20
		var omega_c: float = _move_to_settings.response * err_theta
		move_diff_drive(clampf(_move_to_settings.speed + omega_c, -MAX_SPEED, MAX_SPEED),
			clampf(_move_to_settings.speed - omega_c, -MAX_SPEED, MAX_SPEED))
	else:
		move_diff_drive(0,0)
		_move_to_settings.task = Task.IDLE
		_move_to_settings.finished_task = true
