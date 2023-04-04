@tool
class_name ConnectLight
extends MeshInstance3D

var enable: bool:
	set(value):
		enable = value
		material.set_shader_parameter("enable", enable)

var material: ShaderMaterial = ShaderMaterial.new()

func _ready():
	material.shader = load("res://robots/parts/connect_light.gdshader")
	if mesh != null:
		set_surface_override_material(0, material)
