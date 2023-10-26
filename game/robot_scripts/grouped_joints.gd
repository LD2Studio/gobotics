class_name GroupedJoints extends Node

@export var input: String = ""
@export var outputs : Array
var input_value: float = 0.0:
	set = _input_value_changed
@export var limit_lower: float
@export var limit_upper: float

func _init():
	add_to_group("GROUPED_JOINTS", true)

func _ready():
	pass
#	for output in outputs:
##		print("output: ", output)
#		get_parent().get_node("%%%s" % [output.joint]).grouped = true

func _input_value_changed(value: float):
#	print("input: ", value)
	input_value = value
	for output in outputs:
		get_parent().get_node("%%%s" % [output.joint]).input = output.factor.to_float() * value
#
func shift_target(step):
#	print("step: %f , input: %f" % [step, input_value])
	if step > 0 and input_value <= limit_upper:
		input_value += step
	if step < 0 and input_value >= limit_lower:
		input_value += step
