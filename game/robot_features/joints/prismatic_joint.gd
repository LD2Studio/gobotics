class_name PrismaticJoint extends JoltSliderJoint3D

#region INPUTS
@export var child_link: RigidBody3D = null
@export var limit_velocity: float
@export var grouped: bool = false

var target_dist: float = 0.0:
	set(value):
		target_dist = value
		_target_reached = false
		motor_enabled = true
#endregion

#region OUTPUTS
var dist: float
#endregion

var input: float:
	set(value):
		input = value
		target_dist = value
var dist_step: float
var rest_angle: float
var _target_reached: bool = false

var _basis_inv_node: Node3D

func shift_target(step):
	if step > 0 and target_dist <= limit_upper:
		target_dist += step
	if step < 0 and target_dist >= limit_lower:
		target_dist += step

func _ready():
	child_link.can_sleep = false
	motor_enabled = true
	dist_step = limit_velocity / Engine.physics_ticks_per_second
	_basis_inv_node = child_link.get_node("%s_basis_inv" % name)

func _physics_process(_delta):
	var child_tr: Transform3D = child_link.transform
	dist = (child_tr * _basis_inv_node.transform).origin.x
	#print("dist=", dist)
	var err = target_dist - dist
	#print("err: ", err)
	var speed: float
	if not _target_reached:
		if abs(err) > dist_step:
			speed = limit_velocity * sign(err)
		else:
			speed = 0
			_target_reached = true
	else:
		speed = limit_velocity * err
	
	motor_target_velocity = speed

func _target_dist_changed(value: float):
	target_dist = value * 10.0
	#print("target dist: ", target_dist)
