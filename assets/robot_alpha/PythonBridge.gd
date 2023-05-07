extends PythonBridge

#func _ready() -> void:
#	print("owner: ", owner.get_node("../.."))



func set_vl(speed: float):
	%LeftWheel.rotation_speed = speed

func set_vr(speed: float):
	%RightWheel.rotation_speed = speed

func set_pose(x: float, z: float, a: float):
	%Frame.global_position.x = x * 10.0
	%Frame.global_position.z = z * 10.0
	%Frame.rotation.y = a

func get_pose() -> PackedByteArray:
	var pose = PackedFloat32Array([
		%Frame.global_position.x / 10.0,
		%Frame.global_position.z / 10.0,
		%Frame.rotation_degrees.y])
	var data_bytes = PackedByteArray([0])
	data_bytes.append_array(pose.to_byte_array())
	return data_bytes

#func is_running() -> bool:
#	return owner.get_node("../..").running
