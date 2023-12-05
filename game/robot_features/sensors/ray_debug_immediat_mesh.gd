class_name RayDebugMesh extends ImmediateMesh

## INPUTS
var length : float = 1.0

var vertices = [
	Vector3(0,0,0), Vector3(1,0,0)
]
func _init() -> void:
	update()

func update():
	clear_surfaces()
	surface_begin(Mesh.PRIMITIVE_LINES)
	surface_add_vertex(vertices[0])
	surface_add_vertex(vertices[1] * length)
	surface_end()
