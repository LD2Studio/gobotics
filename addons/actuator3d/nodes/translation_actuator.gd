@icon("res://addons/actuator3d/nodes/translation_actuator_3d.svg")
## Translation actuator
class_name TranslationActuator3D
extends RigidBody3D

@export var moving_distance: float = 0.0:
	set(value):
		if moving_distance != value:
			moving_distance = value
			_in_dist = current_pos_x
			_out_dist = moving_distance
			_step_count = int(profile_duration * Engine.physics_ticks_per_second)
			_step = 0

@export_exp_easing var angle_profile: float = 1.0
@export_range(0.1, 2, 0.1) var profile_duration: float = 1.0

@export_group("Parameters")
## Coefficient of force (N/m)
@export var force_gain: float = 50
@export var damping: float = 20

@export var max_negative_distance: float = -1.0:
	set(value):
		if value <= 0:
			max_negative_distance = value
			if get_node_or_null("LinearJoint"):
				_joint.set("linear_limit_x/lower_distance", max_negative_distance)
@export var max_positive_distance: float = 1.0:
	set(value):
		if value >= 0:
			max_positive_distance = value
			if get_node_or_null("LinearJoint"):
				_joint.set("linear_limit_x/upper_distance", max_positive_distance)
			
@export_group("Controller parameters")
@export var controllers: Array[Controller]

var _joint: Generic6DOFJoint3D
var _pose_position: Vector3 = position
var current_pos_x: float
var _in_dist: float
var _out_dist: float
var _step_count: int
var _step: float

func _enter_tree() -> void:
	_joint = Generic6DOFJoint3D.new()
	_joint.name = "LinearJoint"
	_joint.set("linear_limit_x/lower_distance", max_negative_distance)
	_joint.set("linear_limit_x/upper_distance", max_positive_distance)
	_joint.node_a = ^"../.."
	_joint.node_b = ^"../"
	add_child(_joint)

func _ready() -> void:
	can_sleep = false
	current_pos_x = (transform.inverse().basis * (position - _pose_position)).x

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
#	print("linear velocity: ", transform.inverse().basis * linear_velocity)
#	print("local pos x: ", (transform.inverse().basis * (position - _pose_position)).x)
	current_pos_x = (transform.inverse().basis * (position - _pose_position)).x
	var i: float = _step / _step_count # Value between 0 and 1
	var ease_dist: float
	if i < 1:
		_step += 1
		ease_dist = _in_dist + (_out_dist - _in_dist) * ease(i, angle_profile)
	else:
		ease_dist = _out_dist
	var err = ease_dist - current_pos_x
	var vel = (global_transform.inverse().basis * linear_velocity)
	var x: float
	if controllers.is_empty():
		x = err
	else:
		x = err
		for controller in controllers:
			x = controller.process(x)
	var u = x * force_gain - damping * vel.x
#	print("pos: %f , err: %f" % [current_pos_x, err])
	apply_central_force(global_transform.basis.x * u)
	
