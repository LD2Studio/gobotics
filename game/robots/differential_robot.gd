class_name DifferentialRobot
extends Node3D

@export var manual_control: bool = false
@export var speed: float = 1.0
@export_flags_3d_physics var collision_groups = 1

var right_wheel: RotationActuator3D:
	set(object):
		right_wheel = object
		right_wheel.actuator_type = "MOTOR"
		python.right_wheel = right_wheel
		
var left_wheel: RotationActuator3D:
	set(object):
		left_wheel = object
		left_wheel.actuator_type = "MOTOR"
		python.left_wheel = left_wheel

@onready var frame:RigidBody3D
@onready var python = DifferentialRobotPythonBridge.new()

func _enter_tree():
	add_to_group("PYTHON")

func init():
	add_child(python)
	python.root_rigid_body = get_child(0)
	set_meta("manual_control", true)
	frame = get_child(0)
	frame.freeze = true
	frame.collision_mask = collision_groups
	for child in frame.get_children():
		if child is RigidBody3D:
			child.collision_mask = collision_groups

func update_input():
	assert(right_wheel is RigidBody3D, "Right Wheel must be referenced")
	assert(left_wheel is RigidBody3D, "Left Wheel must be referenced")
	if manual_control:
		if Input.is_action_pressed("FORWARD"):
			if Input.is_action_pressed("RIGHT"):
				right_wheel.rotation_speed = 0
			else:
				right_wheel.rotation_speed = speed
			if Input.is_action_pressed("LEFT"):
				left_wheel.rotation_speed = 0
			else:
				left_wheel.rotation_speed = speed
		elif Input.is_action_pressed("BACKWARD"):
			right_wheel.rotation_speed = -speed
			left_wheel.rotation_speed = -speed
		elif Input.is_action_pressed("RIGHT"):
			right_wheel.rotation_speed = -speed
			left_wheel.rotation_speed = speed
		elif Input.is_action_pressed("LEFT"):
			right_wheel.rotation_speed = speed
			left_wheel.rotation_speed = -speed
		else:
			right_wheel.rotation_speed = 0
			left_wheel.rotation_speed = 0
