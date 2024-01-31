class_name VisualRayCast3D extends RayCast3D

## INPUTS

func activate(value: bool, length: float = 0.0):
	if value:
		_ray_debug.set_surface_override_material(0, _ray_active)
		_ray_debug.mesh.length = length  * GPSettings.SCALE
	else:
		_ray_debug.set_surface_override_material(0, _ray_inactive)
		_ray_debug.mesh.length = (_ray_max - _ray_min)
	_ray_debug.mesh.update()

## INTERNALS
var _ray_max: float
var _ray_min: float
var _ray_debug := MeshInstance3D.new()
var _ray_active : StandardMaterial3D = preload("res://game/robot_features/sensors/ray_sensor_active.material")
var _ray_inactive : StandardMaterial3D = preload("res://game/robot_features/sensors/ray_sensor_inactive.material")
var _ray_debug_mesh : RayDebugMesh

func _init(ray_max: float, ray_min: float):
	_ray_debug_mesh = RayDebugMesh.new()
	_ray_max = ray_max; _ray_min = ray_min

func _ready() -> void:
	_ray_debug.mesh = _ray_debug_mesh
	_ray_debug.mesh.length = (_ray_max - _ray_min)  * GPSettings.SCALE
	_ray_debug.set_surface_override_material(0, _ray_inactive)
	add_child(_ray_debug)
