extends PanelContainer

@onready var actuator_name_label: Label = %ActuatorNameLabel
@onready var enable_actuator_button: CheckButton = %EnableActuatorButton


var base_robot: Node
var actuators: Array:
	set(value):
		actuators = value
		#print("actuators: ", actuators)
		_current_actuator = actuators.front()
		actuator_name_label.text = _current_actuator.name
		if base_robot:
			base_robot.focused_actuator = _current_actuator
			if _current_actuator.is_in_group("MAGNET"):
				#print("current actuator: ", _current_actuator.name)
				enable_actuator_button.visible = true
			else:
				enable_actuator_button.visible = false

var _current_actuator: Node

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("next_actuator"):
		_on_next_button_pressed()
	
	if Input.is_action_just_pressed("toggle_actuator"):
		_current_actuator.activate = !_current_actuator.activate
		enable_actuator_button.set_pressed_no_signal(_current_actuator.activate)
		
func _on_next_button_pressed() -> void:
	var idx = actuators.find(_current_actuator)
	if idx == -1: return
	if idx + 1 == len(actuators):
		_current_actuator = actuators[0]
	else:
		_current_actuator = actuators[idx + 1]
	#print("next actuator: ", _current_actuator.name)
	actuator_name_label.text = _current_actuator.name
	enable_actuator_button.set_pressed_no_signal(_current_actuator.activate)
	base_robot.focused_actuator = _current_actuator

func _on_enable_actuator_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		_current_actuator.activate = true
	else:
		_current_actuator.activate = false
	
