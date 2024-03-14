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

#region SETUP
func _ready():
	set_physics_process(not frozen)
	_init_ray_cast()

func _init_ray_cast():
	for i: int in samples:
		var ray_pivot := Node3D.new()
		add_child(ray_pivot)
		var ray_angle: float
		if samples == 1:
			ray_angle = 0
		else:
			ray_angle = lerpf(hor_min_angle, hor_max_angle, float(i)/(samples-1))
		ray_pivot.rotate_object_local(Vector3.UP, ray_angle)

		var ray_cast = VisualRayCast3D.new(ray_max, ray_min)
		ray_pivot.add_child(ray_cast)
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
			var length: float = ray_cast_state.node.global_position.distance_to(collider_point) / GPSettings.SCALE
			ray_cast_state.node.activate(true, length)
			ray_lengths.append(length)
		else:
			ray_cast_state.colliding = false
			ray_cast_state.node.activate(false)
			ray_lengths.append(0)
			
#endregion
