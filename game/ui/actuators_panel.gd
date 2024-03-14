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


func _on_enable_actuator_button_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
