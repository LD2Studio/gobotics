extends Control

## List of connected game controllers
var connected_game_controllers: Array[int]

func _ready() -> void:
	var app_name: String = ProjectSettings.get_setting("application/config/name")
	var version: String = ProjectSettings.get_setting("application/config/version")
	%GoboticsInfo.text = "%s v%s - Godot Engine %s" % [app_name, version, Engine.get_version_info().string]
	connected_game_controllers = Input.get_connected_joypads()
	
	GSettings.load_mods()
	GSettings.database.generate()


func _on_exit_button_pressed():
	get_tree().quit()


func _on_settings_button_pressed() -> void:
	var err = get_tree().change_scene_to_file("res://game/settings/settings.tscn")
	if err:
		printerr("[ERROR] Loading settings scene failed!")
