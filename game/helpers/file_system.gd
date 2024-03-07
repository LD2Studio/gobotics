class_name FileSystem extends RefCounted

static func get_all_project_names() -> Array:
	var project_files := Array(DirAccess.get_files_at(GSettings.project_path)).filter(
		func(file: String):
			return file.get_extension() == "scene"
	)
	var names := project_files.map(
		func(file: String):
			return file.get_basename()
	)
	return names
