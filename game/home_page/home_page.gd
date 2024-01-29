extends Control

var builtin_env = [
	{ name = "DarkEnv", scene_filename = "res://game/environments/dark_environment.tscn"},
	{ name = "LightEnv", scene_filename = "res://game/environments/light_environment.tscn"},
]

func _enter_tree():
	create_dir()
	GSettings.database.generate(GSettings.asset_path, builtin_env)


## Create missing directory in application folder like assets and temp.
## Must be called first.
func create_dir():
	# Creating temp directory
	if DirAccess.dir_exists_absolute(GSettings.temp_path):
		# delete all files before remove temp dir
		var files = DirAccess.get_files_at(GSettings.temp_path)
		for file in files:
			DirAccess.remove_absolute(GSettings.temp_path.path_join(file))
		DirAccess.remove_absolute(GSettings.temp_path)
	DirAccess.make_dir_absolute(GSettings.temp_path)
		
	# Creating assets directory
	if not DirAccess.dir_exists_absolute(GSettings.asset_path):
		DirAccess.make_dir_absolute(GSettings.asset_path)


func _on_exit_button_pressed():
	get_tree().quit()
