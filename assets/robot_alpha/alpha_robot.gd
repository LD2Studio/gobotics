extends DifferentialRobot

func _ready():
	init($FrameCol/RightWheel, $FrameCol/LeftWheel)

func _process(_delta: float):
	update_input()
	
func _physics_process(delta):
	update_process(delta)

