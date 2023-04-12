@tool
@icon("res://addons/actuator3d/nodes/rotation_actuator_3d.svg")
## Rotation actuator with two modes : MOTOR and SERVO
class_name RotationActuator3D
extends RigidBody3D

@export_enum("MOTOR", "SERVO") var actuator_type = "MOTOR":
	set(value):
		actuator_type = value
		notify_property_list_changed()

@export var exclude_nodes_from_collision: bool = false

@export_enum("X","Y","Z") var rotation_axis = "Z":
	set(value):
		rotation_axis = value
		_draw_help()

## Angular velocity along Z axis in rad/sec
var desired_velocity: float = 0.0
## Constant of the motor torque ; too high a value can make the motor's behavior unstable
var torque_constant: float = 1.0:
	set(value):
		torque_constant = value
		if _inertia_shaft == 0:
			torque_constant = value
			return
		if value > (_inertia_shaft * Engine.physics_ticks_per_second):
			printerr("Higher constant torque motor can make the motor unstable!")
			
#@export var motor_damping: float = 0.1 # Frottement visqueux

## Desired angle value in °
var angle: float = 0:
	set(value):
		if angle != value:
#			angle = value
			angle = clamp(value, -180, 180)
			_in_angle = rad_to_deg(current_angle)
			_out_angle = angle
			_step_count = int(profile_duration * Engine.physics_ticks_per_second)
			_step = 0
#			print("in_angle: %f , out_angle: %f , step_count: %d" %[_in_angle, _out_angle, _step_count])

var servo_damping: float = 5.0
var angle_profile: float = 1.0
var profile_duration: float = 1.0

@export_group("Controller parameters")
@export var controllers: Array[Controller]

			
func _get_property_list():
	var props = []
	match actuator_type:
		"MOTOR":
			props.append({
				"name": "Motor parameters",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_GROUP,
			})
			props.append({
				"name": "desired_velocity",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			})
			props.append({
				"name": "angle",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_NONE,
			})
			props.append({
				"name": "torque_constant",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			})
			props.append({
				"name": "servo_damping",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE,
			})
			props.append({
				"name": "angle_profile",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE,
			})
			props.append({
				"name": "profile_duration",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE,
			})
		"SERVO":
			props.append({
				"name": "Servo parameters",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_GROUP,
			})
			props.append({
				"name": "desired_velocity",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_NONE,
			})
			props.append({
				"name": "angle",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "-180,180",
			})
			props.append({
				"name": "torque_constant",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			})
			props.append({
				"name": "servo_damping",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			})
			props.append({
				"name": "Input Profile",
				"type": TYPE_STRING,
				"usage": PROPERTY_USAGE_GROUP,
			})
			props.append({
				"name": "angle_profile",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
				"hint": PROPERTY_HINT_EXP_EASING
			})
			props.append({
				"name": "profile_duration",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "0.2,2"
			})
	return props


@export_group("Debug")
@export var helper_size: float = 1.0:
	set(value):
		helper_size = value
		if is_instance_valid(_help_meshinstance):
			_help_meshinstance.scale = Vector3.ONE * helper_size
			
## Current angular velocity in MOTOR mode
var current_velocity: float
## Current angle in SERVO mode
var current_angle: float

var _joint := Generic6DOFJoint3D.new()
var _help_meshinstance := MeshInstance3D.new()
var _help_mesh := ImmediateMesh.new()
var _help_mesh_material := StandardMaterial3D.new()
var _pose_basis_inv: Basis = transform.basis.inverse()
var _in_angle: float
var _out_angle: float
var _step_count: int
var _step: float
var _inertia_shaft: float

func _enter_tree() -> void:
	_joint.name = "HingeJoint"
	match rotation_axis:
		"X":
			_joint.set("angular_limit_x/enabled", false)
		"Y":
			_joint.set("angular_limit_y/enabled", false)
		"Z":
			_joint.set("angular_limit_z/enabled", false)
	_joint.node_a = ^"../.."
	_joint.node_b = ^"../"
	_joint.exclude_nodes_from_collision = exclude_nodes_from_collision
	add_child(_joint)
	
	_help_meshinstance.name = "HelpMeshInstance"
	_help_meshinstance.mesh = _help_mesh
	_help_meshinstance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_help_mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	add_child(_help_meshinstance)
	
func _exit_tree() -> void:
	remove_child(_joint)
	remove_child(_help_meshinstance)

func _ready() -> void:
	can_sleep = false
	if Engine.is_editor_hint():
		_draw_help()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	_inertia_shaft = PhysicsServer3D.body_get_direct_state(get_node(".").get_rid()).inverse_inertia.inverse().z
	match actuator_type:
		"MOTOR":
			match rotation_axis:
				"X":
					current_velocity = (global_transform.inverse().basis * angular_velocity).x
				"Y":
					current_velocity = (global_transform.inverse().basis * angular_velocity).y
				"Z":
					current_velocity = (global_transform.inverse().basis * angular_velocity).z
			
			var err = desired_velocity - current_velocity
			var u: float
			if controllers.is_empty():
				u = err
			else:
				u = err
				for controller in controllers:
					u = controller.process(u)
			var torque_cmd : float = torque_constant * u
			match rotation_axis:
				"X":
					apply_torque(global_transform.basis.x * (torque_cmd))
				"Y":
					apply_torque(global_transform.basis.y * (torque_cmd))
				"Z":
					apply_torque(global_transform.basis.z * (torque_cmd))
			
		"SERVO":
			var basis_not_tranformed = _pose_basis_inv * transform.basis
			match rotation_axis:
				"X":
					current_angle = basis_not_tranformed.get_euler().x
					current_velocity = (global_transform.inverse().basis * angular_velocity).x
				"Y":
					current_angle = basis_not_tranformed.get_euler().y
					current_velocity = (global_transform.inverse().basis * angular_velocity).y
				"Z":
					current_angle = basis_not_tranformed.get_euler().z
					current_velocity = (global_transform.inverse().basis * angular_velocity).z
#			current_angle = basis_not_tranformed.get_euler().z
#			current_velocity = (global_transform.inverse().basis * angular_velocity).z
			var i: float = _step / _step_count # Value between 0 and 1
			var ease_angle: float
			if i < 1:
#				print("i: ", i)
				_step += 1
				ease_angle = _in_angle + (_out_angle - _in_angle) * ease(i, angle_profile)
#				print("ease angle: ", ease_angle)
			else:
				ease_angle = _out_angle
			var err = deg_to_rad(ease_angle) - current_angle
			var x: float
			if controllers.is_empty():
				x = err
			else:
				x = err
				for controller in controllers:
					x = controller.process(x)
			var torque_cmd = torque_constant * x - servo_damping * current_velocity
#			var torque_cmd = servo_gain * x - servo_damping * current_velocity
#			print("angle: %f , vel: %f , err: %f , cmd: %f" %[rad_to_deg(current_angle), current_velocity, err, torque_cmd])
#			apply_torque(global_transform.basis.z * (torque_cmd))
			match rotation_axis:
				"X":
					apply_torque(global_transform.basis.x * (torque_cmd))
				"Y":
					apply_torque(global_transform.basis.y * (torque_cmd))
				"Z":
					apply_torque(global_transform.basis.z * (torque_cmd))
			
func _draw_help():
	var edges = 24
	var vertices = []
	for i in range(edges+1):
		var vertex = Vector3(cos(TAU/edges * i), sin(TAU/edges * i), 0)
		vertices.append(vertex)
	
	_help_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _help_mesh_material)
	for vertex in vertices:
		_help_mesh.surface_add_vertex(vertex)
	_help_mesh.surface_end()
	
	vertices.clear()
	var arrows = 4
	for i in range(arrows):
		vertices.append(Vector3(cos(TAU/arrows * i), sin(TAU/arrows * i), 0))
		vertices.append(Vector3(cos(TAU/arrows * i), sin(TAU/arrows * i), 0) + 
				Vector3(0.1, -0.1, 0).rotated(Vector3.BACK, TAU/arrows * i))
		vertices.append(Vector3(cos(TAU/arrows * i), sin(TAU/arrows * i), 0))
		vertices.append(Vector3(cos(TAU/arrows * i), sin(TAU/arrows * i), 0) + 
				Vector3(-0.1, -0.1, 0).rotated(Vector3.BACK, TAU/arrows * i))
#	print(vertices)
	_help_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _help_mesh_material)
	for vertex in vertices:
		_help_mesh.surface_add_vertex(vertex)
	_help_mesh.surface_end()
	
	_help_meshinstance.scale = Vector3.ONE * helper_size
	
	match rotation_axis:
		"X":
			_help_meshinstance.rotation_degrees = Vector3(0,90,0)
		"Y":
			_help_meshinstance.rotation_degrees = Vector3(-90,0,0)
		"Z":
			_help_meshinstance.rotation_degrees = Vector3(0,0,0)
