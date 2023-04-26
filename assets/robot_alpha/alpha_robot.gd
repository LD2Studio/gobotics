extends DifferentialRobot

func _ready():
	initialize()
	right_wheel = $Frame/RightWheel
	left_wheel = $Frame/LeftWheel
	
func _process(_delta: float):
	update_input()

func _physics_process(delta: float) -> void:
	pass
#	print(frame.global_position/10.0, ":", frame.rotation_degrees.y)
