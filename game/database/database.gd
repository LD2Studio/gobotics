class_name GoboticsDB
extends Resource

#@export var assets_base_path: String = "res://assets"
@export var assets: Array

func add_assets(search_path: String):
#	print("search path: ", search_path)
	var files = Array(DirAccess.get_files_at(search_path))
#	print("files: ", files)
	# Filter tscn files
	var files_tscn: Array = files.filter(func(file): return file.get_extension() == "tscn" or file.get_extension() == "urdf")
#	print("files tscn: ", files_tscn)
	# Browse each scene
	for file in files_tscn:
#		print(file)
		var scene: PackedScene = load(search_path.path_join(file))
#		print("Loading ", scene)
		if scene == null:
			continue
		var name: String = scene.get_state().get_node_name(0)
#		print("Scene name: ", name)
		if scene.get_script():
			print("script: ", scene.get_script())
		var group: String
		if scene.get_state().get_node_groups(0).is_empty():
			continue
		else:
			group = scene.get_state().get_node_groups(0)[0]
		var base_dir: String = search_path

#		print("name: %s, scene: %s, group: %s, base_dir: %s" % [name,file, group,base_dir])
		
		assets.append({
			name=name,
			scene=file,
			group=group,
			base_dir=base_dir,
			})
			
	# search sub-folders
	var dirs = Array(DirAccess.get_directories_at(search_path))
#	print_debug("dirs: ", dirs)
	var search_dirs = dirs.map(func(dir): return search_path.path_join(dir))
#	print("search dirs: ", search_dirs)
	for search_dir in search_dirs:
		add_assets(search_dir)
		
	var err = ResourceSaver.save(self, "res://assets/assets_db.tres")
	if err:
		printerr("Database not saving!")
		
func get_scene(name: String):
	for asset in assets:
		if asset.name == name:
			return asset.base_dir.path_join(asset.scene)
	return null
	
func get_preview(name: String):
	for asset in assets:
		if asset.name == name:
			return asset.base_dir.path_join(asset.name + ".png")
	return null
