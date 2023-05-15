extends DifferentialRobot

func _ready():
	init($Frame/RightWheel, $Frame/LeftWheel)

func _process(_delta: float):
	update_input()
