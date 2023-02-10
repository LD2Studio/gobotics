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
const WHEEL_SENSITIVITY = 0.1

var state: int = Cam.IDLE:
	set(value):
		if state != value:
			state = value
			state_changed()

var distance_to_pivot: float = 5.0

func _ready() -> void:
	var cam = Camera3D.new()
	cam.name = "Cam"
	add_child(cam)
	cam.current = current
	cam.position = Vector3.BACK * distance_to_pivot
	
	
func _process(_delta):
	get_node("Cam").position = Vector3.BACK * distance_to_pivot
	

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			state = Cam.ROTATED
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			state = Cam.IDLE
		
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			state = Cam.TRANSLATED
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			state = Cam.IDLE
			
	if event is InputEventMouseMotion and state == Cam.ROTATED:
#		print(event.as_text())
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotate_object_local(Vector3.RIGHT, -event.relative.y * MOUSE_SENSITIVITY)
		
	if event is InputEventMouseMotion and state == Cam.TRANSLATED:
		translate_object_local(
			-Vector3.RIGHT * MOUSE_SENSITIVITY * event.relative.x +
			Vector3.UP * MOUSE_SENSITIVITY * event.relative.y)
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		distance_to_pivot -= WHEEL_SENSITIVITY
		distance_to_pivot = clampf(distance_to_pivot, 1, 20)
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		distance_to_pivot += WHEEL_SENSITIVITY
		distance_to_pivot = clampf(distance_to_pivot, 1, 20)
		
func state_changed():
	match(state):
		Cam.IDLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Cam.ROTATED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
		Cam.TRANSLATED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
