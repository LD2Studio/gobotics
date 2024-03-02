extends PanelContainer


func _on_forward_button_button_down() -> void:
	Input.action_press("FORWARD")


func _on_forward_button_button_up() -> void:
	Input.action_release("FORWARD")


func _on_left_button_button_down() -> void:
	Input.action_press("LEFT")


func _on_left_button_button_up() -> void:
	Input.action_release("LEFT")


func _on_right_button_button_down() -> void:
	Input.action_press("RIGHT")


func _on_right_button_button_up() -> void:
	Input.action_release("RIGHT")


func _on_back_button_button_down() -> void:
	Input.action_press("BACKWARD")


func _on_back_button_button_up() -> void:
	Input.action_release("BACKWARD")
