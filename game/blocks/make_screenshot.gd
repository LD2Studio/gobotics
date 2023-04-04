extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().transparent_bg = true
	get_viewport().size = Vector2i(256, 256)
	await RenderingServer.frame_post_draw

	var screenshot_img = get_viewport().get_texture().get_image()
#	screenshot_img.convert(Image.FORMAT_RGBA8)
	screenshot_img.save_png("res://game/blocks/robots/wheels_robots.png")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
