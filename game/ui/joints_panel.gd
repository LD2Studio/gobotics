extends PanelContainer

@onready var joint_name_label: Label = %JointNameLabel

var base_robot: Node
var joints: Array:
	set(value):
		joints = value
		#print("joints: ", joints)
		_current_joint = joints.front()
		joint_name_label.text = _current_joint.name
		if base_robot:
			base_robot.focused_joint = _current_joint

var _current_joint: Node


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("NEXT_JOINT"):
		_on_next_button_pressed()


func _on_next_button_pressed() -> void:
	var idx = joints.find(_current_joint)
	#print("idx: ", idx)
	if idx == -1: return
	#print("joints size: ", len(joints))
	if idx + 1 == len(joints):
		_current_joint = joints[0]
		
	else:
		_current_joint = joints[idx + 1]
	#print("next joint: ", _current_joint)
	joint_name_label.text = _current_joint.name
	base_robot.focused_joint = _current_joint


func _on_dir_minus_button_button_down() -> void:
	Input.action_press("JOINT_NEG")


func _on_dir_minus_button_button_up() -> void:
	Input.action_release("JOINT_NEG")


func _on_dir_plus_button_button_down() -> void:
	Input.action_press("JOINT_POS")


func _on_dir_plus_button_button_up() -> void:
	Input.action_release("JOINT_POS")
