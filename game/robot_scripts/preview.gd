class_name Preview
extends Camera3D

@export var preview: bool = false
@export var texture: Texture2D

func _ready():
	current = false
	if owner.get_parent().name == "root" and preview:
		make_preview()
	
func make_preview():
	var light := DirectionalLight3D.new()
	light.rotate_x(-PI/4)
	add_child(light)
	current = true
	get_viewport().size = Vector2(128, 128)
	get_viewport().transparent_bg = true
	await RenderingServer.frame_post_draw
	texture = get_viewport().get_texture()
	var base_dir: String = owner.scene_file_path.get_base_dir()
	var object_name = owner.name
	
	var img = texture.get_image()
	img.save_png(base_dir.path_join(object_name+".png"))

