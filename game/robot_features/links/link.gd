class_name RigidLink extends RigidBody3D

var _label := Label.new()

func _ready() -> void:
	add_child(_label)
	_label.text = name
	_label.visible = false


func _process(_delta: float) -> void:
	if _label.visible:
		_label.position = (get_viewport().get_camera_3d()
			.unproject_position(global_transform.origin) - _label.size/2)

func _mouse_enter() -> void:
	#print("mouse entered")
	_label.visible = true
	
func _mouse_exit() -> void:
	#print("mouse exited")
	_label.visible = false
