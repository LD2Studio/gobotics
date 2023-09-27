extends Node
class_name GroupedJoints

var input: String
var _outputs: Array
var target_value: float = 0.0:
	set = _input_value_changed
var limit_lower: float
var limit_upper: float

func _init(input_name: String, outputs: Array, lower_value: float, upper_value: float):
	input = input_name
	_outputs = outputs
	limit_lower = lower_value; limit_upper = upper_value
	add_to_group("GROUPED_JOINTS")

func _input_value_changed(value: float):
#	print("input: ", value)
	target_value = value
	for output in _outputs:
		get_parent().get_node("%%%s" % [output.joint]).input = output.factor * value

func shift_target(step):
	if step > 0 and target_value <= limit_upper:
		target_value += step
	if step < 0 and target_value >= limit_lower:
		target_value += step
