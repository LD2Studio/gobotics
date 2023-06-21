extends RefCounted
class_name ControlRobot

func get_diff_drive_script() -> String:
	
	var source_code = """extends DifferentialRobot

func _ready():
	init()
	
func _process(delta: float):
	update_input()

func _physics_process(delta):
	update_process(delta)
"""
	return source_code
