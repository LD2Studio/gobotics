class_name PrismaticJoint extends JoltSliderJoint3D

#region INPUTS
@export var child_link: RigidBody3D = null
@export var limit_velocity: float
@export var grouped: bool = false

var target_input: float = 0.0:
	set(value):
		target_input = value
		_target_reached = false
		motor_enabled = true
		
var target_speed: float = 0.0

var custom_control: bool = false:
	set(value):
		custom_control = value
		#print("custom control: ", custom_control)
#endregion

#region OUTPUTS
var dist: float
#endregion

#region INTERNALS

var _dist_step: float
var _target_reached: bool = false
var _basis_inv_node: Node3D
#endregion

#region INIT
func _ready():
	add_to_group("PRISMATIC", true)
	child_link.can_sleep = false
	motor_enabled = true
	_dist_step = limit_velocity / Engine.physics_ticks_per_second
	_basis_inv_node = child_link.get_node("%s_basis_inv" % name)
#endregion

#region PROCESS
func _physics_process(_delta):
	var child_tr: Transform3D = child_link.transform
	dist = (child_tr * _basis_inv_node.transform).origin.x
	#print("dist=", dist)
	var speed: float
	
	var err = target_input - dist
	#print("err: ", err)
	if not custom_control:
		if not _target_reached:
			if abs(err) > _dist_step:
				speed = limit_velocity * sign(err)
			else:
				speed = 0
				_target_reached = true
		else:
			speed = limit_velocity * err
	else:
		speed = target_speed
	
	motor_target_velocity = speed
#endregion

#region METHODS
func _target_dist_changed(value: float):
	target_input = value * GParam.SCALE
	#print("target dist: ", target_input)

func shift_target(step):
	if step > 0 and target_input <= limit_upper:
		target_input += step
	if step < 0 and target_input >= limit_lower:
		target_input += step
#endregion
