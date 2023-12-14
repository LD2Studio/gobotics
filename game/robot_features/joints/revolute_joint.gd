class_name RevoluteJoint extends JoltHingeJoint3D

#region INPUTS
@export var child_link: RigidBody3D = null
@export var limit_velocity: float
@export var grouped: bool = false

var target_input: float = 0.0
#endregion

#region INTERNALS

var _angle_step: float
var _basis_inv_node: Node3D
#endregion

#region INIT

func _ready():
	add_to_group("REVOLUTE", true)
	child_link.can_sleep = false
	motor_enabled = true
	_angle_step = limit_velocity / Engine.physics_ticks_per_second
	_basis_inv_node = child_link.get_node("%s_basis_inv" % name)
#endregion

#region PROCESS

func _physics_process(_delta):
	var child_basis: Basis = child_link.transform.basis
	var angle = (child_basis * _basis_inv_node.transform.basis).get_euler().z
	var err = target_input - angle
	var speed: float
	if abs(err) > _angle_step:
		speed = limit_velocity * sign(err)
	else:
		speed = 0
	motor_target_velocity = -speed
#endregion

#region METHODS

func _target_angle_changed(value: float):
	target_input = deg_to_rad(value)
	
func shift_target(step):
	if step > 0 and target_input <= -limit_lower:
		target_input += step
	if step < 0 and target_input >= -limit_upper:
		target_input += step
#endregion
