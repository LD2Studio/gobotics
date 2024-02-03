class_name DiffDrive extends Node

@export var activated: bool = false
@export var frozen: bool = true:
	set(value):
		frozen = value
		set_physics_process(!frozen)
		if frozen and behavior != null:
			behavior.task = IDLE
			move_diff_drive(0,0)

@export var right_wheel: String
@export var left_wheel: String
@export var max_speed: float
@export var base_link: RigidBody3D

var right_wheel_joint: Node3D
var left_wheel_joint: Node3D

enum {
	IDLE,
	MOVE_TO,
}
class Behavior:
	var task: int = IDLE
	var finished_task: bool = true
	var target_pos: Vector2
	var speed: float


@onready var behavior = Behavior.new()


func _ready() -> void:
	set_physics_process(!frozen)


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

func _physics_process(delta: float) -> void:
	match behavior.task:
		IDLE:
			pass
			#print("IDLE BEHAVIOR")
		MOVE_TO:
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


func move_to(new_position: Vector2, new_speed: float):
	#print("Move to %s at %f m/s" % [new_position, new_speed])
	behavior.task = MOVE_TO
	behavior.finished_task = false
	behavior.target_pos = new_position
	behavior.speed = new_speed


func finished_task() -> bool:
	return behavior.finished_task

#endregion

func _path_control_process() -> void:
	#print("path control")
	var current_pos := Vector2(
			base_link.global_position.x/GPSettings.SCALE,
			-base_link.global_position.z/GPSettings.SCALE)
	var d_square = pow((behavior.target_pos.x - current_pos.x), 2)\
			+ pow((behavior.target_pos.y - current_pos.y), 2)
	#print(d_square)
	const d_square_threshold = 0.01**2
	
	if d_square > d_square_threshold:
		var forward_3d_dir :Vector3 = base_link.global_transform.basis.x
		var dir := Vector2(forward_3d_dir.x, -forward_3d_dir.z)
		var err_theta: float = dir.angle_to(behavior.target_pos - current_pos)
		const Kp = 10.0
		const MAX_SPEED = 7
		var omega_c: float = Kp * err_theta
		move_diff_drive(clampf(behavior.speed + omega_c, -MAX_SPEED, MAX_SPEED),
			clampf(behavior.speed - omega_c, -MAX_SPEED, MAX_SPEED))
	else:
		move_diff_drive(0,0)
		behavior.task = IDLE
		behavior.finished_task = true
