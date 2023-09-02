extends Node3D
class_name CameraExt

var base_link_path: NodePath
var state: CamState = CamState.IDLE
enum CamState {
	IDLE,
	ROTATED,
}
const MOUSE_SENSITIVITY = 0.005
const ZOOM_SENSITIVTY = 0.2
@onready var cam : Camera3D = $Boom/Camera
@onready var boom : Node3D = $Boom

func _physics_process(_delta):
	if base_link_path:
		global_position = get_node(base_link_path).global_position


func _unhandled_input(event: InputEvent) -> void:
#	print("camera event: ", event.as_text())
	if not cam.current: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		state = CamState.ROTATED if event.pressed else CamState.IDLE
		
	if state == CamState.ROTATED and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		boom.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		boom.rotation_degrees.x = clampf(boom.rotation_degrees.x, -90, -10)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if event.pressed:
			cam.translate_object_local(Vector3.BACK * ZOOM_SENSITIVTY)
			cam.position.z = clampf(cam.position.z, 2.5, 15)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if event.pressed:
			cam.translate_object_local(Vector3.FORWARD * ZOOM_SENSITIVTY)
			cam.position.z = clampf(cam.position.z, 2.5, 15)
