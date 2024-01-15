class_name CameraSensor extends Node3D

#region INPUTS
@export var frozen: bool = false:
	set(value):
		frozen = value
		if frozen:
			set_physics_process(false)
			visible = false
		else:
			set_physics_process(true)
			visible = true
#endregion

#region OUTPUTS
var img : Image

#endregion

#region INIT
func _ready() -> void:
	set_physics_process(not frozen)
#endregion

#region PROCESS

func _physics_process(delta: float) -> void:
	img = %RenderCam.get_texture().get_image()
	
#endregion
