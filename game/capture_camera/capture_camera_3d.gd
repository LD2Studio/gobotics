class_name CaptureCamera3D
extends Camera3D

@export var preview: bool = false
@export_dir var img_path: String

func _ready():
	current = false
	if preview: make_preview()
	
func make_preview():
	var light := DirectionalLight3D.new()
	light.rotate_x(-PI/4)
	add_child(light)
	current = true
	get_viewport().size = Vector2(128, 128)
	get_viewport().transparent_bg = true
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	var object_name = owner.name
	img.save_png(img_path.path_join(object_name+".png"))

