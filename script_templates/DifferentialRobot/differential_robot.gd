# meta-name: Default script
# meta-description: 
# meta-default: false
# meta-space-indent: 4
extends _BASE_

func _ready():
	init()
	
func _process(delta: float):
	update_input()

func _physics_process(delta):
	update_process(delta)