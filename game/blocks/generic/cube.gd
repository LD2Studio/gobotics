extends RigidBody3D

var focused: bool
var size: Vector3:
	set(value):
		size = value
		$MeshInstance3D.mesh.size = size
		var outline = Mesh.new()
		%Outline.mesh = $MeshInstance3D.mesh.create_outline(0.05)
		$CollisionShape3D.shape.size = size

func _ready() -> void:
	add_to_group("BLOCKS")
	freeze = true
	size = Vector3(1,1,1)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	%Outline.visible = true
	focused = true

func _on_mouse_exited() -> void:
	%Outline.visible = false
	focused = false
