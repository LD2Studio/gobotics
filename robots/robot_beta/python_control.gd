# Python Control for Beta Robot
extends PythonBridge

var right_wheel_vel_record: PackedFloat32Array
var left_wheel_vel_record: PackedFloat32Array
var x_pos_record: PackedFloat32Array
var y_pos_record: PackedFloat32Array
var record_time: float = 0

func _ready():
	pass
#	python_client_connected.connect(func(): %ConnectLight.enable = true)

func run():
	%ConnectLight.enable = true
	
func stop():
	%ConnectLight.enable = false
	
func get_fps() -> int:
	return Engine.physics_ticks_per_second

func set_right_wheel_vel(value: float):
	%RightMotor.desired_velocity = value
	
func set_left_wheel_vel(value: float):
	%LeftMotor.desired_velocity = value
	
func get_right_wheel_vel() -> PackedByteArray:
	var data_bytes: PackedByteArray
	data_bytes.append(0) # Header for bytes data
	data_bytes.append_array(right_wheel_vel_record.to_byte_array())
#	print_debug(right_wheel_vel_record.size())
	return data_bytes
	
func get_left_wheel_vel() -> PackedByteArray:
	var data_bytes: PackedByteArray
	data_bytes.append(0) # Header for bytes data
	data_bytes.append_array(left_wheel_vel_record.to_byte_array())
	return data_bytes
	
func get_x_pos() -> PackedByteArray:
	var data_bytes: PackedByteArray
	data_bytes.append(0) # Header for bytes data
	data_bytes.append_array(x_pos_record.to_byte_array())
	return data_bytes
	
func get_y_pos() -> PackedByteArray:
	var data_bytes: PackedByteArray
	data_bytes.append(0) # Header for bytes data
	data_bytes.append_array(y_pos_record.to_byte_array())
	return data_bytes
	
	
func get_localisation():
	var data_bytes: PackedByteArray
	data_bytes.append(0)
	data_bytes.append_array(owner.get_localisation().to_byte_array())
	return data_bytes

func setup_record(time: float = 0):
	if time == 0:
		return
	right_wheel_vel_record.clear()
	left_wheel_vel_record.clear()
	x_pos_record.clear()
	y_pos_record.clear()
	record_time = time
	
func _physics_process(delta: float) -> void:
	if record_time > 0:
		right_wheel_vel_record.append(%RightMotor.current_velocity)
		left_wheel_vel_record.append(%LeftMotor.current_velocity)
		x_pos_record.append(owner.get_xy_pos().x)
		y_pos_record.append(owner.get_xy_pos().y)
		
	record_time -= delta
