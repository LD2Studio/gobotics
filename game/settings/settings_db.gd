class_name SettingsDB extends Resource

@export var mod_paths: Array


func save_settings(path: String):
	var err = ResourceSaver.save(self, path)
	if err:
		printerr("Setting Database not saving!")


func remove_mod(path) -> void:
	mod_paths = mod_paths.filter(func(mod_path):
		return mod_path != path
		)
