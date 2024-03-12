class_name TopCamera2D
extends Camera3D

@export_group("Camera Control")
## Mouse button used for panoramic movement
@export_enum("LEFT_BUTTON", "MIDDLE_BUTTON")
var action_mouse_button: String = "MIDDLE_BUTTON"

@export_range(0.5, 2, 0.1) var zoom_speed: float = 1.0
@export var default_zoom: float = 30
@export var zoom_near: float = 10:
	set(value):
		if value > 0:
			zoom_near = value
@export var zoom_far: float = 100:
	set(value):
		if value > zoom_near:
			zoom_far = value

const _MOUSE_SENSITIVITY = 0.001
const _WHEEL_SENSITIVITY = 0.2

enum State{
	IDLE,
	TRANSLATED,
}

var _state : int = State.IDLE

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = default_zoom

func _unhandled_input(event: InputEvent) -> void:
	if not current: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if size > zoom_near:
			size -= zoom_speed
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if size < zoom_far:
			size += zoom_speed
			
	if event is InputEventMouseButton:
		match action_mouse_button:
			"MIDDLE_BUTTON":
				if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
					_state = State.TRANSLATED
				elif event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
					_state = State.IDLE
			"LEFT_BUTTON":
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_state = State.TRANSLATED
				elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
					_state = State.IDLE
	if event is InputEventMouseMotion and _state == State.TRANSLATED:
		global_position += Vector3(
			-event.relative.x * _MOUSE_SENSITIVITY * size,
			0,
			-event.relative.y * _MOUSE_SENSITIVITY * size,
		)
