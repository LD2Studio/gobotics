class_name RobotBase extends Node

## Manual control
@export var activated: bool = false:
	set(value):
		activated = value
#		print("update activated flag : %s" % activated)
		if activated:
			update_all_joints()
			update_all_sensors()
			
@export var base_link: RigidBody3D

signal joint_changed(joint_name: String)

var joypads_connected: Array[int]
var joypad_connected: bool = false
var joypad_selected: int = 0
var focused_joint = null

var joints := Array()
var ray_sensors := Array()

var _joint_idx : int = 0

func _init():
	Input.joy_connection_changed.connect(_on_joypad_changed)
	joypads_connected = Input.get_connected_joypads()
#	print("Joypads connected: ", joypads_connected)
	if joypad_selected in joypads_connected:
		joypad_connected = true
	else:
		joypad_connected = false
		
func _ready():
	set_name.call_deferred(&"RobotBase")
	if not joints.is_empty():
		focused_joint = joints[_joint_idx]
		joint_changed.emit(focused_joint.name)
		
func setup():
	for node in get_parent().get_children():
		if node is RigidBody3D:
			base_link = node

func _physics_process(delta):
	if activated and focused_joint:
		if Input.is_action_pressed("JOINT_POS"):
			focused_joint.shift_target(delta)
		elif Input.is_action_pressed("JOINT_NEG"):
			focused_joint.shift_target(-delta)
			
		if Input.is_action_just_pressed("JOINT_UP"):
			_joint_idx += 1
			if _joint_idx >= len(joints):
				_joint_idx = 0
			focused_joint = joints[_joint_idx]
			joint_changed.emit(focused_joint.name)
#			print("focused joint: ", focused_joint)
			
		if Input.is_action_just_pressed("JOINT_DOWN"):
			_joint_idx -= 1
			if _joint_idx == -1:
				_joint_idx = len(joints) - 1
			focused_joint = joints[_joint_idx]
			joint_changed.emit(focused_joint.name)
#			print("focused joint: ", focused_joint)
				
func update_all_joints():
#	print("update all joints")
	joints.clear()
	for node in get_tree().get_nodes_in_group("CONTINUOUS"):
		if node.owner == get_parent(): joints.append(node)
	for node in get_tree().get_nodes_in_group("REVOLUTE"):
#		print("owner %s -> node %s" %  [node.owner, node])
		if node.owner == get_parent():
			joints.append(node)
	for node in get_tree().get_nodes_in_group("PRISMATIC"):
#		print("owner %s -> node %s" %  [node.owner, node])
		if node.owner == get_parent():
			joints.append(node)
	for node in get_tree().get_nodes_in_group("GROUPED_JOINTS"):
#		print("GROUPED_JOINTS: owner %s -> node %s" %  [node.owner, node])
		if node.owner == get_parent():
			joints.append(node)
	if not joints.is_empty():
		focused_joint = joints[0]
		joint_changed.emit(focused_joint.name)
		
func update_all_sensors():
	ray_sensors.clear()
	for node in get_tree().get_nodes_in_group("RAY"):
		if node.owner == get_parent():
			ray_sensors.append(node)

func _on_joypad_changed(device: int, connected: bool):
	print("device %d connected: %s" % [device, connected])
	joypads_connected = Input.get_connected_joypads()
	if joypad_selected in joypads_connected:
		joypad_connected = true
	else:
		joypad_connected = false

## Functions exposed to PythonBridge

func get_pose() -> PackedFloat32Array:
	var pose = PackedFloat32Array(
		[
			base_link.global_position.x / 10.0,
			-base_link.global_position.z / 10.0,
#			base_link.global_position.y / 10.0,
			base_link.rotation.y
		]
	)
	return pose
	
func set_pose(x: float, y: float, a: float):
	base_link.global_position.x = x * 10.0
	base_link.global_position.z = -y * 10.0
	base_link.rotation.y = a
	
func set_continuous_velocity(jname: String, value: float):
	var joint_name = jname.replace(" ", "_")
#	print("%s : %f " % [joint_name, value])
	for joint in joints:
		if joint.is_in_group("CONTINUOUS") and joint.name == joint_name:
#			print("%s : %f" % [joint_name, value])
			joint.target_velocity = value
			return

func set_revolute(jname: String, value: float):
	var joint_name = jname.replace(" ", "_")
#	print("Revolute joint name: %s = %f " % [joint_name, value])
	for joint in joints:
		if joint.is_in_group("REVOLUTE") and joint.name == joint_name:
			joint.target_angle = deg_to_rad(value)
			return

func set_prismatic(jname: String, value: float):
	var joint_name = jname.replace(" ", "_")
#	print("Prismatic joint name: %s = %f " % [joint_name, value])
	for joint in joints:
		if joint.is_in_group("PRISMATIC") and joint.name == joint_name:
			joint.target_dist = value * 10.0
			return

func set_grouped_joints(jname: String, value: float):
	var grouped_joint_name = jname.replace(" ", "_")
#	print("Grouped joint name: %s = %f " % [grouped_joint_name, value])
	for joint in joints:
		if joint.is_in_group("GROUPED_JOINTS") and joint.name == grouped_joint_name:
			joint.target_value = value
			return

func is_ray_colliding(sname: String) -> bool:
	var sensor_name = sname.replace(" ", "_")
	for ray in ray_sensors:
		if ray.is_in_group("RAY") and ray.name == sensor_name:
			return ray.colliding
	return false
	
func get_ray_length(sname: String) -> float:
	var sensor_name = sname.replace(" ", "_")
	for ray in ray_sensors:
		if ray.name == sensor_name:
			return ray.length
	return 0.0
