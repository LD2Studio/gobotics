extends RigidBody3D

var focused: bool

func _ready() -> void:
	add_to_group("BLOCKS")
	freeze = true
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	%Outline.visible = true
	focused = true

func _on_mouse_exited() -> void:
	%Outline.visible = false
	focused = false
