class_name ContinuousJoint extends JoltHingeJoint3D

@export var child_link: RigidBody3D = null
@export var limit_velocity: float
@export var grouped: bool = false

var target_velocity: float = 0.0:
	set = _target_velocity_changed


func _ready():
	child_link.can_sleep = false
	motor_enabled = true
	motor_target_velocity = -target_velocity


func shift_target(step):
	if step > 0 and target_velocity <= limit_velocity:
		target_velocity += step
	if step < 0 and target_velocity >= -limit_velocity:
		target_velocity += step
	#print("velocity: %f" % target_velocity)


func _target_velocity_changed(value: float):
	target_velocity = value
	motor_target_velocity = -target_velocity
