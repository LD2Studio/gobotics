class_name GoboticsDB
extends Resource

@export var assets_base_path: String = "assets"
@export var assets: Array

func create():
	var assets_path: String
	if OS.has_feature("editor"):
		assets_path = assets_base_path
	else:
		var executable_path: String = OS.get_executable_path().get_base_dir()
		assets_path = executable_path.path_join(assets_base_path)
		if not DirAccess.dir_exists_absolute(assets_path):
			printerr("Assets directory missing!")
			return
		
	add_assets(assets_path)
	
	# Save database
	ResourceSaver.save(self, assets_path.path_join("assets_db.tres"))
	
	
func add_assets(search_path: String):
#	print_debug("search path: ", search_path)
	var files = Array(DirAccess.get_files_at(search_path))
	# Filter tscn files
	var files_tscn: Array = files.filter(func(file): return file.get_extension() == "tscn")
#	print_debug(files_tscn)
	# Browse each scene
	for file in files_tscn:
		var scene: PackedScene = load(search_path.path_join(file))
#		print_debug(scene)
		var name: String = scene.get_state().get_node_name(0)
		var group: String
		if scene.get_state().get_node_groups(0).is_empty():
			group = "NOGROUP"
		else:
			group = scene.get_state().get_node_groups(0)[0]
		var base_dir: String = search_path
		var preview_filename: String
		if FileAccess.file_exists(base_dir.path_join(name+".png")):
			preview_filename = name+".png"
#		print("name: %s, scene: %s, group: %s, base_dir: %s, preview: %s" % [name,file, group,base_dir, preview_filename])
		
		assets.append({
			name=name,
			scene=file,
			group=group,
			base_dir=base_dir,
			preview=preview_filename,
			})
		
func get_scene(name: String):
	for asset in assets:
		if asset.name == name:
			return asset.base_dir.path_join(asset.scene)
	return null
	
func get_preview(name: String):
	for asset in assets:
		if asset.name == name:
			return asset.base_dir.path_join(asset.preview)
	return null
