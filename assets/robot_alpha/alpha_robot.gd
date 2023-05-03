extends DifferentialRobot

func _ready():
	initialize()
	right_wheel = $Frame/RightWheel
	left_wheel = $Frame/LeftWheel
	
func _process(_delta: float):
	update_input()

