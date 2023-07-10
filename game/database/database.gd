class_name GoboticsDB
extends Resource

@export var assets: Array
@export var environments: Array

var is_asset_ext: bool = false
var assets_base_dir: String
var temp_dir: String
var urdf_parser = URDFParser.new()

func _init():
	if OS.has_feature("editor"):
		assets_base_dir = "res://assets"
		temp_dir = "res://temp"
	else:
		assets_base_dir = OS.get_executable_path().get_base_dir().path_join("assets")
		temp_dir = OS.get_executable_path().get_base_dir().path_join("temp")
		
	urdf_parser.scale = 10

func add_assets(search_path: String):
#	print("[Database] search path: ", search_path)
	var files = Array(DirAccess.get_files_at(search_path))
#	print("files: ", files)
	if is_asset_ext:
		# Filter asset files
		var asset_files: Array = files.filter(func(file): return file.get_extension() == "asset")
#		print("Asset files: ", asset_files)
		
		for file in asset_files:
			var asset_filename = ProjectSettings.globalize_path(search_path.path_join(file))
#			print("[Database] asset_filename: ", asset_filename)
			var reader := ZIPReader.new()
			var err := reader.open(asset_filename)
			if err != OK:
				print("[Database]: Open %s asset failed" % [file])
				return
			var asset_name = file.get_basename()
#			print("[Database] asset name: ", asset_name)
			var asset_content = reader.get_files()
			if (asset_name + ".urdf") in asset_content:
				var res := reader.read_file(asset_name + ".urdf")
				var scene_filename = generate_scene(res.get_string_from_ascii(), asset_name, asset_filename)
				assets.append({
					name=asset_name,
					filename=asset_filename,
					scene=scene_filename,
					group="ASSETS",
					})
			reader.close()
			
			
	else:
		# Filter tscn files
		var files_tscn: Array = files.filter(func(file): return file.get_extension() == "tscn")
	#	print("files tscn: ", files_tscn)
		# Browse each scene
		for file in files_tscn:
	#		print(file)
			var scene: PackedScene = ResourceLoader.load(search_path.path_join(file), "PackedScene")
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
		
	var err = ResourceSaver.save(self, "res://temp/database.tres")
	if err:
		printerr("Database not saving!")
		
func add_environments(search_path: String, builtin: bool = false):
#	print("[Database] search env path: ", search_path)
	var files = Array(DirAccess.get_files_at(search_path))
#	print("env files: ", files)
	if builtin:
		# Filter tscn files
		var files_tscn: Array = files.filter(func(file): return file.get_extension() == "tscn")
#		print("[Database] Env files tscn: ", files_tscn)
		for file in files_tscn:
			var scene: PackedScene = ResourceLoader.load(search_path.path_join(file))
	#		print("Loading ", scene)
			if scene == null:
				continue
			var name: String = scene.get_state().get_node_name(0)
			var scene_filename: String = search_path.path_join(file)
			
			environments.append({
				name=name,
				scene=scene_filename,
				})
				
	var err = ResourceSaver.save(self, "res://temp/database.tres")
	if err:
		printerr("[Database] not saving!")
		
func get_asset_filename(name: String):
	for asset in assets:
		if asset.name == name:
			return asset.filename

func generate_scene(urdf_description: String, asset_name: String, asset_filename: String):
#	print("asset name: ", asset_name)
	var root_node : Node3D = urdf_parser.parse_buffer(urdf_description)
#	print("root node: ", root_node)
	var scene_filename = temp_dir.path_join(asset_name + ".tscn")
	if root_node == null: return
	root_node.set_meta("asset_name", asset_name)
	var asset_scene = PackedScene.new()
	var result = asset_scene.pack(root_node)
	if result != OK:
		return null
	var err := ResourceSaver.save(asset_scene, scene_filename)
	if err != OK:
		printerr("[Database] An error %d occurred while saving the scene to disk." % err)
		return null
	return scene_filename
		
func get_scene(name: String):
	for asset in assets:
		if asset.name == name:
			if is_asset_ext:
				return asset.scene
			else:
				return asset.base_dir.path_join(asset.scene)
	return null
	
func get_asset_scene(name: String):
	return get_scene(name)
	
func get_environment(name: String):
	for env in environments:
		if env.name == name:
			if is_asset_ext:
				return env.scene
			else:
				return env.base_dir.path_join(env.scene)
	return null
	
#func get_preview(name: String):
#	for asset in assets:
#		if asset.name == name:
#			return asset.base_dir.path_join(asset.name + ".png")
#	return null
