class_name PIDController
extends Controller

@export var Kp: float = 1.0
@export var Ki: float = 0.0
@export var Kd: float = 0.0
@export var integral_saturation: float = 1.0

var _prev_err: float = 0
var _integration_stored: float = 0

func process(err: float):
	var delta : float = 1.0/Engine.physics_ticks_per_second
	
	var P = Kp * err
	
	var derivate_error = (err - _prev_err) / delta
	_prev_err = err
	var D = Kd * derivate_error
	
	_integration_stored += err * delta
	_integration_stored = clamp(_integration_stored, -integral_saturation, integral_saturation)
	var I = Ki * _integration_stored
	
	var command = P + D + I
#	print("error=%.14f P=%.14f I=%.14f D=%.14f C=%.14f" % [error, P, I, D, command])
#	command = clamp(command, output_min, output_max)
	return command
