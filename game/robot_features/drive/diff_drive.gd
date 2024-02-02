class_name DiffDrive extends Node

@export var activated: bool = false
@export var right_wheel: String
@export var left_wheel: String
@export var max_speed: float

var right_wheel_joint: Node3D
var left_wheel_joint: Node3D

enum {
	IDLE,
	MOVE_TO,
}
class Behavior:
	var task: int = IDLE
	var finished_task: bool = true


@onready var behavior = Behavior.new()


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
			print("IDLE BEHAVIOR")
		MOVE_TO:
			pass


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
	print("Move to %s at %f m/s" % [new_position, new_speed])

#endregion
