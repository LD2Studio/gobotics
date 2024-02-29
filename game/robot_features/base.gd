class_name RobotBase extends Node

#region INPUTS

@export var base_link: RigidBody3D

#endregion


#region OUTPUTS

var joypads_connected: Array[int]
var joypad_connected: bool = false
var joypad_selected: int = 0
var focused_joint: Node = null

signal joint_changed(joint_name: String)

#endregion


#region INTERNALS
var _joints := Array()
var _ray_sensors := Array()
var _joint_idx : int = 0

#region INIT
func _init():
	Input.joy_connection_changed.connect(_on_joypad_changed)
	joypads_connected = Input.get_connected_joypads()
	#print("Joypads connected: ", joypads_connected)
	if joypad_selected in joypads_connected:
		joypad_connected = true
	else:
		joypad_connected = false


func _ready():
	set_name.call_deferred(&"RobotBase")
	if not _joints.is_empty():
		focused_joint = _joints[_joint_idx]
		joint_changed.emit(focused_joint.name)


func setup():
	for node in get_parent().get_children():
		if node is RigidBody3D:
			base_link = node
	update_all_joints()
	update_all_sensors()

#endregion

func update_all_joints():
	#print("update all joints")
	_joints.clear()
	for node in get_tree().get_nodes_in_group("CONTINUOUS"):
		if node.owner == get_parent(): _joints.append(node)
	for node in get_tree().get_nodes_in_group("REVOLUTE"):
#		print("owner %s -> node %s" %  [node.owner, node])
		if node.owner == get_parent():
			_joints.append(node)
	for node in get_tree().get_nodes_in_group("PRISMATIC"):
#		print("owner %s -> node %s" %  [node.owner, node])
		if node.owner == get_parent():
			_joints.append(node)
	for node in get_tree().get_nodes_in_group("GROUPED_JOINTS"):
#		print("GROUPED_JOINTS: owner %s -> node %s" %  [node.owner, node])
		if node.owner == get_parent():
			_joints.append(node)
	if not _joints.is_empty():
		focused_joint = _joints[0]
		joint_changed.emit(focused_joint.name)


func update_all_sensors():
	_ray_sensors.clear()
	for node in get_tree().get_nodes_in_group("SENSORS"):
		if node.owner == get_parent():
			_ray_sensors.append(node)
	#print("ray sensors: ", _ray_sensors)


func _on_joypad_changed(device: int, connected: bool):
	print("device %d connected: %s" % [device, connected])
	joypads_connected = Input.get_connected_joypads()
	if joypad_selected in joypads_connected:
		joypad_connected = true
	else:
		joypad_connected = false

#endregion


#region PROCESS
func command(delta):
	if focused_joint:
		if focused_joint.has_method("shift_target"):
			if Input.is_action_pressed("JOINT_POS"):
				focused_joint.shift_target(-delta)
			elif Input.is_action_pressed("JOINT_NEG"):
				focused_joint.shift_target(delta)

#endregion

#region PYTHON_BRIDGE FUNCTIONS

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
	#print("%s : %f " % [joint_name, value])
	for joint in _joints:
		if joint.is_in_group("CONTINUOUS") and joint.name == joint_name:
			#print("%s : %f" % [joint_name, value])
			joint.target_velocity = value
			return
			
func set_revolute_config(jname: String, custom: bool = false):
	var joint_name = jname.replace(" ", "_")
	#print("Revolute config: %s = %s " % [joint_name, custom])
	for joint: Node3D in _joints:
		if joint.is_in_group("REVOLUTE") and joint.name == joint_name:
			joint.custom_control = custom
			return

func set_revolute(jname: String, value: float, velocity: bool = false):
	var joint_name = jname.replace(" ", "_")
#	print("Revolute joint name: %s = %f " % [joint_name, value])
	for joint in _joints:
		if joint.is_in_group("REVOLUTE") and joint.name == joint_name:
			if velocity:
				joint.target_speed = value
			else:
				joint.target_input = deg_to_rad(value)
			return
			
func get_revolute(jname: String) -> PackedFloat32Array:
	var joint_name = jname.replace(" ", "_")
	var angle: float
	for joint: Node3D in _joints:
		if joint.is_in_group("REVOLUTE") and joint.name == joint_name:
			angle = joint.angle
	var data = PackedFloat32Array(
		[angle, GPSettings.physics_tick]
	)
	return data
			
func set_prismatic_config(jname: String, custom: bool = false):
	var joint_name = jname.replace(" ", "_")
	#print("Prismatic config: %s = %s " % [joint_name, custom])
	for joint: Node3D in _joints:
		if joint.is_in_group("PRISMATIC") and joint.name == joint_name:
			joint.custom_control = custom
			return
			
func set_prismatic(jname: String, value: float, velocity: bool = false):
	var joint_name = jname.replace(" ", "_")
	#print("Prismatic: %s = %f " % [joint_name, value])
	for joint in _joints:
		if joint.is_in_group("PRISMATIC") and joint.name == joint_name:
			if velocity:
				joint.target_speed = value * GPSettings.SCALE
			else:
				joint.target_input = value * GPSettings.SCALE
			return
			
func get_prismatic(jname: String) -> PackedFloat32Array:
	var joint_name = jname.replace(" ", "_")
	var dist: float
	for joint: Node3D in _joints:
		if joint.is_in_group("PRISMATIC") and joint.name == joint_name:
			dist = joint.dist / GPSettings.SCALE
	var data = PackedFloat32Array(
		[dist, GPSettings.physics_tick]
	)
	return data

func set_grouped_joints(jname: String, value: float):
	var grouped_joint_name = jname.replace(" ", "_")
#	print("Grouped joint name: %s = %f " % [grouped_joint_name, value])
	for joint in _joints:
		if joint.is_in_group("GROUPED_JOINTS") and joint.name == grouped_joint_name:
			joint.target_value = value
			return

func is_ray_colliding(sname: String) -> bool:
	var sensor_name = sname.replace(" ", "_")
	for ray: Node3D in _ray_sensors:
		#print("ray: ", ray)
		if ray.is_in_group("RAY") and ray.name == sensor_name:
			return ray.any_colliding
	return false

func get_ray_scanner(sname: String) -> PackedFloat32Array:
	var sensor_name = sname.replace(" ", "_")
	var ray_lengths = PackedFloat32Array()
	
	for ray_scanner: Node3D in _ray_sensors:
		if ray_scanner.name == sensor_name:
			ray_lengths = ray_scanner.ray_lengths.duplicate()
			break
	return ray_lengths
	
func get_image(sname: String) -> PackedByteArray:
	var sensor_name = sname.replace(" ", "_")
	var png = PackedByteArray()
	for cam: Node3D in _ray_sensors:
		#print("ray: ", ray)
		if cam.is_in_group("CAM") and cam.name == sensor_name:
			var img: Image = cam.img
			png = img.save_jpg_to_buffer()
	return png
#endregion
