# meta-name: Default script
# meta-description: 
# meta-default: false
# meta-space-indent: 4
@tool
extends _BASE_

func _ready():
	initialize()
	
func _process(delta: float):
	update_input()
