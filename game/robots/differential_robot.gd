class_name DifferentialRobot
extends Node3D

@export var speed: float = 1.0
@export_flags_3d_physics var collision_groups = 1

var focused: bool = false

var frozen: bool:
	set(value):
		assert(frame != null, "Frame is not defined! Call initialize() function")
		frozen = value
		if frozen:
			frame.freeze = true
			set_physics_process(false)
			for child in frame.get_children():
				if child is RigidBody3D:
					child.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			frame.freeze = false
			set_physics_process(true)
			for child in frame.get_children():
				if child is RigidBody3D:
					child.process_mode = Node.PROCESS_MODE_INHERIT
					
var right_wheel: RotationActuator3D:
	set(object):
		right_wheel = object
		right_wheel.actuator_type = "MOTOR"
		
var left_wheel: RotationActuator3D:
	set(object):
		left_wheel = object
		left_wheel.actuator_type = "MOTOR"

@onready var frame:RigidBody3D

func _init():
	add_to_group("ROBOTS")

func initialize():
	frame = get_child(0)
	frozen = true
	frame.collision_mask = collision_groups
	for child in frame.get_children():
		if child is RigidBody3D:
			child.collision_mask = collision_groups

func update_input():
	assert(right_wheel is RigidBody3D, "Right Wheel must be referenced")
	assert(left_wheel is RigidBody3D, "Left Wheel must be referenced")
	if true:
		if Input.is_action_pressed("FORWARD"):
			right_wheel.desired_velocity = speed if not Input.is_action_pressed("RIGHT") else 0
			left_wheel.desired_velocity = speed if not Input.is_action_pressed("LEFT") else 0
		elif Input.is_action_pressed("BACKWARD"):
			right_wheel.desired_velocity = -speed
			left_wheel.desired_velocity = -speed
		elif Input.is_action_pressed("RIGHT"):
			right_wheel.desired_velocity = -speed
			left_wheel.desired_velocity = speed
		elif Input.is_action_pressed("LEFT"):
			right_wheel.desired_velocity = speed
			left_wheel.desired_velocity = -speed
		else:
			right_wheel.desired_velocity = 0
			left_wheel.desired_velocity = 0
