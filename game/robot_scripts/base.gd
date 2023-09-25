extends Node
class_name RobotBase

var joypads_connected: Array[int]
var joypad_connected: bool = false
var joypad_selected: int = 0
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
	for node in get_tree().get_nodes_in_group("REVOLUTE"):
#		print("owner %s -> node %s" %  [node.owner, node])
		if node.owner == get_parent():
			_joints.append(node)
	for node in get_tree().get_nodes_in_group("PRISMATIC"):
#		print("owner %s -> node %s" %  [node.owner, node])
		if node.owner == get_parent():
			_joints.append(node)

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
	for joint in _joints:
		if joint.is_in_group("REVOLUTE") and joint.name == joint_name:
			joint.target_angle = deg_to_rad(value)
			return

func set_prismatic(jname: String, value: float):
	var joint_name = jname.replace(" ", "_")
#	print("Prismatic joint name: %s = %f " % [joint_name, value])
	for joint in _joints:
		if joint.is_in_group("PRISMATIC") and joint.name == joint_name:
			joint.target_dist = value * 10.0
			return
