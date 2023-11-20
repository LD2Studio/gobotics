extends Node3D

@export var ray_min: float = 0.0
@export var ray_max: float = 1.0
@export var frozen: bool = false:
	set(value):
		frozen = value
		if frozen:
			set_physics_process(false)
		else:
			set_physics_process(true)

var ray_cast_array: Array

func _ready() -> void:
	set_physics_process(not frozen)
	for ray_cast in get_children():
		if ray_cast is RayCast3D:
			ray_cast.position.x = ray_min
			ray_cast.target_position = Vector3(ray_max - ray_min, 0, 0)
			var mat : StandardMaterial3D
			if ray_cast.get_child(0) is MeshInstance3D:
				var ray_debug : MeshInstance3D = ray_cast.get_child(0)
				ray_debug.scale.x = ray_max - ray_min
				mat = ray_debug.get_surface_override_material(0)
			var ray_cast_obj = {
				node=ray_cast,
				mat=mat,
			}
			ray_cast_array.append(ray_cast_obj)

func _physics_process(delta: float) -> void:
	for ray_cast in ray_cast_array:
		if ray_cast.node.is_colliding():
			ray_cast.mat.albedo_color = Color.RED
		else:
			ray_cast.mat.albedo_color = Color.html("00b08c")
