class_name DifferentialRobot
extends Node3D

@export var manual_control: bool = false
@export var speed: float = 1.0
@export_flags_3d_physics var collision_groups = 1
@onready var python = DifferentialRobotPythonBridge.new()
@onready var robot := Robot.new()

class Robot:
#	var frame
	var right_wheel: RotationActuator3D
	var left_wheel: RotationActuator3D

func _enter_tree():
	add_to_group("PYTHON")

func init(right_wheel: RotationActuator3D, left_wheel: RotationActuator3D):
	add_child(python)
	var frame = get_child(0)
	assert(frame is RigidBody3D, "Frame robot must be RigidBody3D type")
#	robot.frame = frame
	python.root_rigid_body = frame
	robot.right_wheel = right_wheel
	robot.left_wheel = left_wheel
	python.right_wheel = right_wheel
	python.left_wheel = left_wheel
	set_meta("manual_control", true)
	frame.freeze = true
	frame.collision_mask = collision_groups
	for child in frame.get_children():
		if child is RigidBody3D:
			child.collision_mask = collision_groups

func update_input():
	if manual_control:
		if Input.is_action_pressed("FORWARD"):
			if Input.is_action_pressed("RIGHT"):
				robot.right_wheel.rotation_speed = 0
			else:
				robot.right_wheel.rotation_speed = speed
			if Input.is_action_pressed("LEFT"):
				robot.left_wheel.rotation_speed = 0
			else:
				robot.left_wheel.rotation_speed = speed
		elif Input.is_action_pressed("BACKWARD"):
			robot.right_wheel.rotation_speed = -speed
			robot.left_wheel.rotation_speed = -speed
		elif Input.is_action_pressed("RIGHT"):
			robot.right_wheel.rotation_speed = -speed
			robot.left_wheel.rotation_speed = speed
		elif Input.is_action_pressed("LEFT"):
			robot.right_wheel.rotation_speed = speed
			robot.left_wheel.rotation_speed = -speed
		else:
			robot.right_wheel.rotation_speed = 0
			robot.left_wheel.rotation_speed = 0
