extends Node
class_name RobotExt

var joypads_connected: Array[int]
var joypad_connected: bool = false
var joypad_selected: int = 0
var manual: bool = true
var revolute_joints := Array()

@onready var python = PythonBridge.new(self, 4243)

func _init():
	Input.joy_connection_changed.connect(_on_joypad_changed)
#	var joypads = Input.get_connected_joypads()
	joypads_connected = Input.get_connected_joypads()
	print("Joypads connected: ", joypads_connected)
	if joypad_selected in joypads_connected:
		joypad_connected = true
	else:
		joypad_connected = false
		
func _ready():
	name = &"RobotExt"
	add_child(python)

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
			joint_node.target_angle = value
