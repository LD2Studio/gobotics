class_name RayScanner extends Node3D

#region INPUTS

@export var samples: int = 1
@export var hor_min_angle: float = 0.0
@export var hor_max_angle: float = 0.0
@export var ray_min: float = 0.0
@export var ray_max: float = 1.0
@export var frozen: bool = false:
	set(value):
		frozen = value
		if frozen:
			set_physics_process(false)
			visible = false
		else:
			set_physics_process(true)
			visible = true
#endregion

#region OUTPUTS

var any_colliding: bool = false
var ray_lengths: PackedFloat32Array 
#endregion

#region INTERNALS

var _ray_cast_array: Array
#endregion

#region INIT
func _ready():
	set_physics_process(not frozen)
	_init_ray_cast()

func _init_ray_cast():
	if samples == 0: return
	if samples == 1:
		var ray_cast = VisualRayCast3D.new(ray_max, ray_min)
		ray_cast.position.x = ray_min
		ray_cast.target_position = Vector3(ray_max - ray_min, 0, 0)
		add_child(ray_cast)
		
		var ray_cast_obj = {
			node=ray_cast,
			colliding=false,
			length=0.0,
		}
		_ray_cast_array.append(ray_cast_obj)
		
	else:
		var hor_scan_range: float = hor_max_angle - hor_min_angle
		var hor_scan_step: float = hor_scan_range / (samples - 1)
		for i in samples:
			var ray_cast = VisualRayCast3D.new(ray_max, ray_min)
			add_child(ray_cast)
			ray_cast.rotate_y(i * hor_scan_step + hor_min_angle)
			ray_cast.position.x = ray_min
			ray_cast.target_position = Vector3(ray_max - ray_min, 0, 0)
			
			var ray_cast_state = {
				node=ray_cast,
				colliding=false,
				length=0.0,
			}
			_ray_cast_array.append(ray_cast_state)
#endregion

#region PROCESS
func _physics_process(_delta: float) -> void:
	any_colliding = false
	ray_lengths.clear()
	for ray_cast_state: Dictionary in _ray_cast_array:
		if ray_cast_state.node.is_colliding():
			any_colliding = true
			ray_cast_state.colliding = true
			var collider_point : Vector3 = ray_cast_state.node.get_collision_point()
			var length: float = ray_cast_state.node.global_position.distance_to(collider_point) / GParam.SCALE
			ray_cast_state.node.activate(true, length)
			ray_lengths.append(length)
		else:
			ray_cast_state.colliding = false
			ray_cast_state.node.activate(false)
			ray_lengths.append(0)
			
#endregion
