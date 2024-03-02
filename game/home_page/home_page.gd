extends Control

## List of connected game controllers
var connected_game_controllers: Array[int]

func _ready() -> void:
	var app_name: String = ProjectSettings.get_setting("application/config/name")
	var version: String = ProjectSettings.get_setting("application/config/version")
	%GoboticsInfo.text = "%s v%s - Develop with Godot Engine 4.2" % [app_name, version]
	connected_game_controllers = Input.get_connected_joypads()


func _on_exit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://game/settings/settings.tscn")
	if err:
		printerr("[ERROR] Loading settings scene failed!")
