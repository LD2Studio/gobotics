class_name SettingsDB extends Resource

@export var mod_paths: Array


func save_settings(path: String):
	var err = ResourceSaver.save(self, path)
	if err:
		printerr("Setting Database not saving!")
