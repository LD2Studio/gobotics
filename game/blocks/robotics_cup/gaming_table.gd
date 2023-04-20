extends StaticBody3D

func _enter_tree():
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
func _exit_tree():
	input_event.disconnect(_on_input_event)
	mouse_entered.disconnect(_on_mouse_entered)
	mouse_exited.disconnect(_on_mouse_exited)

var mouse_on_area: bool = false
var mouse_pos_on_area: Vector3

func _on_mouse_entered():
	mouse_on_area = true
	
func _on_mouse_exited():
	mouse_on_area = false

func _on_input_event(camera, event, position, normal, shape_idx):
	mouse_pos_on_area = position
