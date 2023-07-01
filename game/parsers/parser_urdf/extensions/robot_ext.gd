extends RefCounted
class_name RobotExt

var joypads_connected: Array[int]
var joypad_connected: bool = false
var joypad_selected: int = 0

func _init():
	Input.joy_connection_changed.connect(_on_joypad_changed)
#	var joypads = Input.get_connected_joypads()
	joypads_connected = Input.get_connected_joypads()
	print("Joypads connected: ", joypads_connected)
	if joypad_selected in joypads_connected:
		joypad_connected = true
	else:
		joypad_connected = false

func _on_joypad_changed(device: int, connected: bool):
	print("device %d connected: %s" % [device, connected])
	joypads_connected = Input.get_connected_joypads()
	if joypad_selected in joypads_connected:
		joypad_connected = true
	else:
		joypad_connected = false
