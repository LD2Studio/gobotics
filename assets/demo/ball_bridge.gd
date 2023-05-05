extends PythonBridge

func get_position() -> Array:
	var pos = Array([
		%Sphere.position.x,
		%Sphere.position.y,
		%Sphere.position.z
	])
	return pos
