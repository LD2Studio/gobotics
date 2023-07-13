extends Camera3D
class_name FollowCamera3D
# https://kidscancode.org/godot_recipes/4.x/3d/interpolated_camera/index.html

@export var lerp_speed = 3.0
@export var target_path : NodePath
@export var offset = Vector3.ZERO

var target = null

func _ready():
	if target_path:
		target = get_node(target_path)
#		print("target: ", target)

func _physics_process(delta):
	if target:
		var target_xform = target.global_transform.translated_local(offset)
		global_transform = global_transform.interpolate_with(target_xform, lerp_speed * delta)
		look_at(target.global_transform.origin, target.transform.basis.y)
