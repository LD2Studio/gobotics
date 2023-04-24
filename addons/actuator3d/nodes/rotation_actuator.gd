@tool
@icon("res://addons/actuator3d/nodes/rotation_actuator_3d.svg")
## Rotation actuator with two modes : MOTOR and SERVO
class_name RotationActuator3D
extends RigidBody3D

@export_enum("MOTOR", "SERVO") var actuator_type = "MOTOR":
	set(value):
		actuator_type = value
		notify_property_list_changed()

@export var exclude_nodes_from_collision: bool = true

@export_enum("X","-X","Y","-Y","Z","-Z") var rotation_axis = "Z":
	set(value):
		rotation_axis = value
		if _joint.is_inside_tree():
			if actuator_type == "SERVO":
				update_limit()
			if Engine.is_editor_hint() or not only_debug:
				draw_help()

## Desired angular velocity in rad/sec
var rotation_speed: float = 0.0

## Constant of the motor torque ; too high a value can make the motor's behavior unstable
var torque_constant: float = 1.0:
	set(value):
		torque_constant = value
		if _inertia_shaft == 0:
			torque_constant = value
			return
		if value > (_inertia_shaft * Engine.physics_ticks_per_second):
			printerr("Higher constant torque motor can make the motor unstable!")

## Desired angle value in °
var desired_angle: float = 0:
	set(value):
		if desired_angle != value:
			desired_angle = clamp(value, -180, 180)
			_in_angle = rad_to_deg(current_angle)
			_out_angle = desired_angle
			_step_count = int(profile_duration * Engine.physics_ticks_per_second)
			_step = 0
#			print("in_angle: %f , out_angle: %f , step_count: %d" %[_in_angle, _out_angle, _step_count])

var max_angle: float = 90:
	set(value):
		max_angle = value
		if Engine.is_editor_hint() or not only_debug:
			draw_help()
		update_limit()
		
var min_angle: float = -90:
	set(value):
		min_angle = value
		if Engine.is_editor_hint() or not only_debug:
			draw_help()
		update_limit()

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
				"name": "rotation_speed",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
			})
			props.append({
				"name": "torque_constant",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
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
				"name": "desired_angle",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "-170,170",
			})
			props.append({
				"name": "max_angle",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "0,170",
			})
			props.append({
				"name": "min_angle",
				"type": TYPE_FLOAT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR,
				"hint": PROPERTY_HINT_RANGE,
				"hint_string": "-170,0",
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
@export var only_debug: bool = true
			
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
	match actuator_type:
		"MOTOR":
			_joint.set("angular_limit_z/enabled", false)
		"SERVO":
			_joint.set("angular_limit_z/enabled", true)
			update_limit()
	_joint.node_a = ^"../.."
	_joint.node_b = ^"../"
	_joint.exclude_nodes_from_collision = exclude_nodes_from_collision
#	_joint.tree_entered.connect(func(): print("%s tree entered!" % [_joint.name]))
	add_child(_joint)
	match rotation_axis:
		"X":
			_joint.rotation_degrees = Vector3(0, 90, 0)
		"-X":
			_joint.rotation_degrees = Vector3(0, -90, 0)
		"Y":
			_joint.rotation_degrees = Vector3(-90, 0, 0)
		"-Y":
			_joint.rotation_degrees = Vector3(90, 0, 0)
		"Z":
			_joint.rotation_degrees = Vector3(0, 0, 0)
		"-Z":
			_joint.rotation_degrees = Vector3(0, 0, 90)
	_help_meshinstance.name = "HelpMeshInstance"
	_help_meshinstance.mesh = _help_mesh
	_help_meshinstance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_help_mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_help_mesh_material.vertex_color_use_as_albedo = true
	add_child(_help_meshinstance)
	can_sleep = false
	
	if Engine.is_editor_hint() or not only_debug:
		draw_help()

func _exit_tree() -> void:
	remove_child(_help_meshinstance)
	remove_child(_joint)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
#	print("actuator...")
	_inertia_shaft = PhysicsServer3D.body_get_direct_state(get_node(".").get_rid()).inverse_inertia.inverse().z
	match actuator_type:
		"MOTOR":
			match rotation_axis:
				"X":
					current_velocity = (global_transform.inverse().basis * angular_velocity).x
				"-X":
					current_velocity = -(global_transform.inverse().basis * angular_velocity).x
				"Y":
					current_velocity = (global_transform.inverse().basis * angular_velocity).y
				"-Y":
					current_velocity = -(global_transform.inverse().basis * angular_velocity).y
				"Z":
					current_velocity = (global_transform.inverse().basis * angular_velocity).z
				"-Z":
					current_velocity = -(global_transform.inverse().basis * angular_velocity).z
			var err = rotation_speed - current_velocity
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
				"-X":
					apply_torque(global_transform.basis.x * (-torque_cmd))
				"Y":
					apply_torque(global_transform.basis.y * (torque_cmd))
				"-Y":
					apply_torque(global_transform.basis.y * (-torque_cmd))
				"Z":
					apply_torque(global_transform.basis.z * (torque_cmd))
				"-Z":
					apply_torque(global_transform.basis.z * (-torque_cmd))
			
		"SERVO":
			var basis_not_tranformed = _pose_basis_inv * transform.basis
			match rotation_axis:
				"X":
					current_angle = basis_not_tranformed.get_euler(EULER_ORDER_XYZ).x
					current_velocity = (global_transform.inverse().basis * angular_velocity).x
				"-X":
					current_angle = -basis_not_tranformed.get_euler(EULER_ORDER_XYZ).x
					current_velocity = -(global_transform.inverse().basis * angular_velocity).x
				"Y":
					current_angle = basis_not_tranformed.get_euler().y
					current_velocity = (global_transform.inverse().basis * angular_velocity).y
				"-Y":
					current_angle = -basis_not_tranformed.get_euler().y
					current_velocity = -(global_transform.inverse().basis * angular_velocity).y
				"Z":
					current_angle = basis_not_tranformed.get_euler().z
					current_velocity = (global_transform.inverse().basis * angular_velocity).z
				"-Z":
					current_angle = -basis_not_tranformed.get_euler().z
					current_velocity = -(global_transform.inverse().basis * angular_velocity).z
			var i: float = _step / _step_count # Value between 0 and 1
			var ease_angle: float
			if i < 1:
				_step += 1
				ease_angle = _in_angle + (_out_angle - _in_angle) * ease(i, angle_profile)
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
#			print("x: ", x)
			var torque_cmd = torque_constant * x - servo_damping * current_velocity
#			print("angle: %f , vel: %f , err: %f , cmd: %f" %[rad_to_deg(current_angle), current_velocity, err, torque_cmd])
			match rotation_axis:
				"X":
					apply_torque(global_transform.basis.x * (torque_cmd))
				"-X":
					apply_torque(global_transform.basis.x * (-torque_cmd))
				"Y":
					apply_torque(global_transform.basis.y * (torque_cmd))
				"-Y":
					apply_torque(global_transform.basis.y * (-torque_cmd))
				"Z":
					apply_torque(global_transform.basis.z * (torque_cmd))
				"-Z":
					apply_torque(global_transform.basis.z * (-torque_cmd))
			if not Engine.is_editor_hint() and not only_debug:
				update_help()
			
func draw_help():
	match actuator_type:
		"MOTOR":
			draw_rotation_circle()
		"SERVO":
			draw_angle_sector()
		
	_help_meshinstance.scale = Vector3.ONE * helper_size
			
func draw_rotation_circle():
	var edges = 24
	var vertices = []
	for i in range(edges+1):
		var vertex = Vector3(cos(TAU/edges * i), sin(TAU/edges * i), 0)
		vertices.append(vertex)
	
	_help_mesh.clear_surfaces()
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
	
	match rotation_axis:
		"X":
			_help_meshinstance.rotation_degrees = Vector3(0,90,0)
		"Y":
			_help_meshinstance.rotation_degrees = Vector3(-90,0,0)
		"Z":
			_help_meshinstance.rotation_degrees = Vector3(0,0,0)
		"-X":
			_help_meshinstance.rotation_degrees = Vector3(0,-90,0)
		"-Y":
			_help_meshinstance.rotation_degrees = Vector3(90,0,0)
		"-Z":
			_help_meshinstance.rotation_degrees = Vector3(0,180,0)

func draw_angle_sector():
	var edges: int = 24
	var vertices = []
	vertices.append(Vector3.ZERO)
	var edges_count: int = int((max_angle - min_angle)*(float(edges)/360))
	for i in range(edges_count+1):
		var vertex = Vector3(cos(deg_to_rad(min_angle) + TAU/edges * i), sin(deg_to_rad(min_angle) + TAU/edges * i), 0)
		vertices.append(vertex)
	vertices.append(Vector3(cos(deg_to_rad(max_angle)), sin(deg_to_rad(max_angle)), 0))
	vertices.append(Vector3.ZERO)
	
	var axis_vertices = []
	axis_vertices.append(Vector3.ZERO)
	axis_vertices.append(Vector3.RIGHT * 1.2)
	
	_help_mesh.clear_surfaces()
	_help_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, _help_mesh_material)
	for vertex in vertices:
		_help_mesh.surface_add_vertex(vertex)
	_help_mesh.surface_end()
	
	_help_mesh.surface_begin(Mesh.PRIMITIVE_LINES, _help_mesh_material)
	_help_mesh.surface_set_color(Color.RED)
	for vertex in axis_vertices:
		_help_mesh.surface_add_vertex(vertex)
	_help_mesh.surface_end()
	
	match rotation_axis:
		"X":
			_help_meshinstance.rotation_degrees = Vector3(0,90,0)
		"-X":
			_help_meshinstance.rotation_degrees = Vector3(0,-90,0)
		"Y":
			_help_meshinstance.rotation_degrees = Vector3(-90,0,0)
		"-Y":
			_help_meshinstance.rotation_degrees = Vector3(90,0,0)
		"Z":
			_help_meshinstance.rotation_degrees = Vector3(0,0,0)
		"-Z":
			_help_meshinstance.rotation_degrees = Vector3(180,0,0)
			
func update_help():
#	print(rad_to_deg(current_angle))
	match rotation_axis:
		"X":
			_help_meshinstance.rotation_degrees = Vector3(0,90, rad_to_deg(-current_angle))
		"-X":
			_help_meshinstance.rotation_degrees = Vector3(0,-90, rad_to_deg(-current_angle))
		"Y":
			_help_meshinstance.rotation_degrees = Vector3(-90,0, rad_to_deg(-current_angle))
		"-Y":
			_help_meshinstance.rotation_degrees = Vector3(90,0, rad_to_deg(-current_angle))
		"Z":
			_help_meshinstance.rotation_degrees = Vector3(0, 0, rad_to_deg(-current_angle))
		"-Z":
			_help_meshinstance.rotation_degrees = Vector3(180, 0, rad_to_deg(-current_angle))

func update_limit():
#	print("update limit: ", rotation_axis)
	match rotation_axis:
		"X":
			_joint.set("angular_limit_z/upper_angle", -deg_to_rad(min_angle))
			_joint.set("angular_limit_z/lower_angle", -deg_to_rad(max_angle))
		"-X":
			_joint.set("angular_limit_z/upper_angle", deg_to_rad(max_angle))
			_joint.set("angular_limit_z/lower_angle", deg_to_rad(min_angle))
		"Y":
			_joint.set("angular_limit_z/upper_angle", deg_to_rad(max_angle))
			_joint.set("angular_limit_z/lower_angle", deg_to_rad(min_angle))
		"-Y":
			_joint.set("angular_limit_z/upper_angle", -deg_to_rad(min_angle))
			_joint.set("angular_limit_z/lower_angle", -deg_to_rad(max_angle))
		"Z":
			_joint.set("angular_limit_z/upper_angle", -deg_to_rad(min_angle))
			_joint.set("angular_limit_z/lower_angle", -deg_to_rad(max_angle))
		"-Z":
			_joint.set("angular_limit_z/upper_angle", deg_to_rad(max_angle))
			_joint.set("angular_limit_z/lower_angle", deg_to_rad(min_angle))
