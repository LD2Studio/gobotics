extends MeshInstance3D

var focused: bool

func _ready() -> void:
	pass

func _on_static_body_3d_mouse_entered() -> void:
	$Outline.visible = true
	focused = true

func _on_static_body_3d_mouse_exited() -> void:
	$Outline.visible = false
	focused = false
