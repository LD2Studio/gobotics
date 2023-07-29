class_name GoboticsDB extends Resource

@export var assets: Array
@export var environments: Array

var asset_base_dir: String
var temp_abs_path: String
var package_abs_path: String
var urdf_parser = URDFParser.new()
var reader := ZIPReader.new()

func _init(package_dir: String, temp_dir: String):
	if OS.has_feature("editor"):
		temp_abs_path = ProjectSettings.globalize_path("res://" + temp_dir)
		package_abs_path = ProjectSettings.globalize_path("res://" + package_dir)
	else:
		temp_abs_path = OS.get_executable_path().get_base_dir().path_join(temp_dir)
		package_abs_path = OS.get_executable_path().get_base_dir().path_join(package_dir)
		
	urdf_parser.scale = 10
	urdf_parser.packages_path = package_abs_path

func add_assets(search_path: String):
#	print("[Database] search path: ", search_path)
	var files = Array(DirAccess.get_files_at(search_path))
#	print("files: ", files)
	# Filter asset files
	var asset_files: Array = files.filter(func(file): return file.get_extension() == "asset")
	
	for file in asset_files:
		var asset_filename = search_path.path_join(file)
#		print("asset_filename: ", asset_filename)
		var err := reader.open(asset_filename)
		if err != OK:
			print("Open %s asset failed" % [file])
			return
		var asset_name = file.get_basename()
#		print("asset name: ", asset_name)
		var asset_content = reader.get_files()

		if ("urdf.xml") in asset_content:
			var res := reader.read_file("urdf.xml")
			var fullname : String = search_path.trim_prefix(asset_base_dir).trim_prefix("/").path_join(file)
#			print("fullname: ", fullname)
			var output_metadata = {}
			var scene_filename = generate_scene(res.get_string_from_ascii(), fullname, output_metadata)
			if scene_filename == null:
				assets.append({
					name=asset_name,
					fullname=asset_name,
					filename=asset_filename,
					scene=null,
					group="ASSETS",
					})
			else:
				assets.append({
					name=output_metadata.name,
					fullname=fullname,
					filename=asset_filename,
					scene=scene_filename,
					group="ASSETS",
					})
		reader.close()
		
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
				
#	var err = ResourceSaver.save(self, "res://temp/database.tres")
#	if err:
#		printerr("[Database] not saving!")
		
func generate_scene(urdf_code: String, fullname: String, asset_metadata: Dictionary = {}):
	var result = urdf_parser.parse_buffer(urdf_code)
	# If result return error message
	if result is String:
		print("error message: ", result)
		return null
		
	var root_node = result
	asset_metadata.name = root_node.name
	var scene_filename = temp_abs_path.path_join(fullname.get_basename().validate_node_name() + ".tscn")
	if root_node == null: return
#	root_node.set_meta("asset_name", root_node.name)
	root_node.set_meta("fullname", fullname)
	var asset_scene = PackedScene.new()
	var err = asset_scene.pack(root_node)
	if err != OK:
		return null
	err = ResourceSaver.save(asset_scene, scene_filename)
	if err != OK:
		printerr("[Database] An error %d occurred while saving the scene to disk." % err)
		return null
	
#	root_node.print_tree_pretty()
	root_node.queue_free()	# Delete orphan nodes
	return scene_filename
	
func get_asset_filename(fullname: String):
	for asset in assets:
		if asset.fullname == fullname:
			return asset.filename
	
func get_scene_from_fullname(fullname: String):
	for asset in assets:
		if asset.fullname == fullname:
			return asset.scene
	return null
	
func get_asset_scene(fullname: String):
	for asset in assets:
		if asset.fullname == fullname:
			return asset.scene
	return null
	
func get_environment(name: String):
	for env in environments:
		if env.name == name:
			return env.scene
	return null
	
#func get_preview(name: String):
#	for asset in assets:
#		if asset.name == name:
#			return asset.base_dir.path_join(asset.name + ".png")
#	return null
