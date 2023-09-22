extends Node
class_name RobotBase

var joypads_connected: Array[int]
var joypad_connected: bool = false
var joypad_selected: int = 0
var revolute_joints := Array()
var prismatic_joints := Array()
var focused_joint

var _joints := Array()
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
	name = &"RobotBase"
	group_joints()
#	print("group joints: ", joints)
	if not _joints.is_empty():
		focused_joint = _joints[_joint_idx]
	
func _physics_process(delta):
	if get_parent().activated and not get_parent().python.activate:
		if focused_joint:
			if Input.is_action_pressed("JOINT_POS"):
				focused_joint.shift_target(delta)
			elif Input.is_action_pressed("JOINT_NEG"):
				focused_joint.shift_target(-delta)
				
			if Input.is_action_just_pressed("JOINT_UP"):
				_joint_idx += 1
				if _joint_idx >= len(_joints):
					_joint_idx = 0
				focused_joint = _joints[_joint_idx]
			if Input.is_action_just_pressed("JOINT_DOWN"):
				_joint_idx -= 1
				if _joint_idx == -1:
					_joint_idx = len(_joints) - 1
				focused_joint = _joints[_joint_idx]
				
func group_joints():
	for joint_name in revolute_joints:
		_joints.append(get_parent().get_node("%%%s" % [joint_name]))
	for joint_name in prismatic_joints:
		_joints.append(get_parent().get_node("%%%s" % [joint_name]))

func _on_joypad_changed(device: int, connected: bool):
	print("device %d connected: %s" % [device, connected])
	joypads_connected = Input.get_connected_joypads()
	if joypad_selected in joypads_connected:
		joypad_connected = true
	else:
		joypad_connected = false

## Functions usable through GodotBridge

func set_revolute(jname: String, value: float):
	var joint_name = jname.replace(" ", "_")
#	print("Revolute joint name: %s = %f " % [joint_name, value])
#	print("Revolute joints: ", revolute_joints)
	if joint_name in revolute_joints:
		var joint_node = get_parent().get_node("%%%s" % [joint_name])
		if joint_node:
			joint_node.position_control = true
			joint_node.target_angle = deg_to_rad(value)

func set_prismatic(jname: String, value: float):
	var joint_name = jname.replace(" ", "_")
#	print("Prismatic joint name: %s = %f " % [joint_name, value])
#	print("Prismatic joints: ", revolute_joints)
	if joint_name in prismatic_joints:
		var joint_node = get_parent().get_node("%%%s" % [joint_name])
		if joint_node:
			joint_node.target_dist = value * 10.0
