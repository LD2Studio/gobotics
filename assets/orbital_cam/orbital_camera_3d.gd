extends Node3D
class_name OrbitalCamera3D

@export var current: bool = false:
	get:
		return current
	set(value):
		current = value
		var cam = get_node_or_null("Cam")
		if cam:
			cam.current = value

enum Cam {
	IDLE,	# A l'arrêt
	ROTATED,
	TRANSLATED,
}

const MOUSE_SENSITIVITY = 0.002
const PAN_MOUSE_SENSITIVITY = 0.005
const WHEEL_SENSITIVITY = 0.2
const MIN_DISTANCE_TO_PIVOT = 1
const MAX_DISTANCE_TO_PIVOT = 30

var state: int = Cam.IDLE:
	set(value):
		if state != value:
			state = value
			state_changed()

var distance_to_pivot: float = 20.0
var vp: Viewport

func _ready() -> void:
	var cam = Camera3D.new()
	cam.name = "Cam"
	cam.fov = 50
	add_child(cam)
	cam.current = current
	cam.position = Vector3.BACK * distance_to_pivot
	rotate_object_local(Vector3.RIGHT, -PI/8)
	vp = get_viewport()
	print_debug(vp)
	
func _process(_delta):
	get_node("Cam").position = Vector3.BACK * distance_to_pivot
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			state = Cam.ROTATED
		elif event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
			state = Cam.IDLE
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			state = Cam.TRANSLATED
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			state = Cam.IDLE
			
	if event is InputEventMouseMotion and state == Cam.ROTATED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotate_object_local(Vector3.RIGHT, -event.relative.y * MOUSE_SENSITIVITY)
		
	if event is InputEventMouseMotion and state == Cam.TRANSLATED:
		translate_object_local(
			-Vector3.RIGHT * PAN_MOUSE_SENSITIVITY * event.relative.x +
			Vector3.UP * PAN_MOUSE_SENSITIVITY * event.relative.y)
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		distance_to_pivot -= WHEEL_SENSITIVITY
		distance_to_pivot = clampf(distance_to_pivot, MIN_DISTANCE_TO_PIVOT, MAX_DISTANCE_TO_PIVOT)
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		distance_to_pivot += WHEEL_SENSITIVITY
		distance_to_pivot = clampf(distance_to_pivot, MIN_DISTANCE_TO_PIVOT, MAX_DISTANCE_TO_PIVOT)
		
func state_changed():
	match(state):
		Cam.IDLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Cam.ROTATED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Cam.TRANSLATED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
