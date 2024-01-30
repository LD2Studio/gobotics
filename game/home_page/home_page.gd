extends Control


func _enter_tree():
	GSettings.database.generate()


func _on_exit_button_pressed():
	get_tree().quit()
