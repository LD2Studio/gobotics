extends Control

var builtin_env = [
	{ name = "DarkEnv", scene_filename = "res://game/environments/dark_environment.tscn"},
	{ name = "LightEnv", scene_filename = "res://game/environments/light_environment.tscn"},
]

func _enter_tree():
	create_dir()
	GSettings.database.asset_base_path = GSettings.asset_base_dir
	GSettings.database.generate(GSettings.asset_base_dir, builtin_env)


## Create missing directory in application folder like assets and temp.
## Must be called first.
func create_dir():
	# Creating temp directory
	var temp_abs_path: String
	if OS.has_feature("editor"):
		temp_abs_path = ProjectSettings.globalize_path("res://" + GSettings.temp_path)
	else:
		temp_abs_path = OS.get_executable_path().get_base_dir().path_join(GSettings.temp_path)
		
	if DirAccess.dir_exists_absolute(temp_abs_path):
		# delete all files before remove temp dir
		var files = DirAccess.get_files_at(temp_abs_path)
		for file in files:
			DirAccess.remove_absolute(temp_abs_path.path_join(file))
		DirAccess.remove_absolute(temp_abs_path)
	DirAccess.make_dir_absolute(temp_abs_path)
		
	# Creating assets directory
	if OS.has_feature("editor"):
		GSettings.asset_base_dir = ProjectSettings.globalize_path("res://" + GSettings.asset_dir)
	else:
		GSettings.asset_base_dir = OS.get_executable_path().get_base_dir().path_join(GSettings.asset_dir)
		
	if not DirAccess.dir_exists_absolute(GSettings.asset_base_dir):
		DirAccess.make_dir_absolute(GSettings.asset_base_dir)


func _on_exit_button_pressed():
	get_tree().quit()
