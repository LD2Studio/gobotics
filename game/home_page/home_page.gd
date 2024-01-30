extends Control


func _on_exit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://game/settings/settings.tscn")
	if err:
		printerr("[ERROR] Loading settings scene failed!")
