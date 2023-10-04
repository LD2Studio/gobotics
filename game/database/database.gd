class_name GoboticsDB extends Resource

@export var assets: Array
var asset_base_path: String
var temp_abs_path: String
var urdf_parser = URDFParser.new()
var reader := ZIPReader.new()

func _init(temp_dir: String):
	if OS.has_feature("editor"):
		temp_abs_path = ProjectSettings.globalize_path("res://" + temp_dir)
	else:
		temp_abs_path = OS.get_executable_path().get_base_dir().path_join(temp_dir)
		
	urdf_parser.scale = 10
	urdf_parser.gravity_scale = ProjectSettings.get_setting("physics/3d/default_gravity")/9.8
	
func generate(asset_base_dir: String, builtin_env: Array):
	assets.clear()
	add_builtin_env(builtin_env)
	add_assets(asset_base_dir, asset_base_dir)
	

func add_builtin_env(builtin_env: Array):
	for env in builtin_env:
		assets.append({
			name=env.name, # env name
			fullname="%s.builtin" % env.name,
			filename=null,
			scene=env.scene_filename,
			type="builtin_env",
		})
		

func add_assets(search_path: String, asset_base_dir: String):
#	print("[DB] search path: ", search_path)
	var files = Array(DirAccess.get_files_at(search_path))
#	print("[DB] files: ", files)
	# Filter asset files
	var asset_files: Array = files.filter(func(file): return file.get_extension() == "asset")
#	print("asset files: ", asset_files)
	# Filtering URDF files
	var urdf_files: Array = files.filter(func(file): return file.get_extension() == "urdf")
#	print("[DB] URDF files: ", urdf_files)
	
	for file in asset_files:
		var asset_filename = search_path.path_join(file)
#		print("asset_filename: ", asset_filename)
		var err := reader.open(asset_filename)
		if err != OK:
			printerr("Open %s asset failed" % [file])
			return
		var asset_name = file.get_basename()
#		print("asset name: ", asset_name)
		var asset_content = reader.get_files()
		var meshes_list := Array()
		for asset_file in asset_content:
			if asset_file.get_extension() == "glb":
				var res := reader.read_file(asset_file)
				meshes_list.append(
					{
						name = asset_file,
						data = res,
					}
				)
		urdf_parser.meshes_list = meshes_list.duplicate(true)

		if ("urdf.xml") in asset_content:
			var res := reader.read_file("urdf.xml")
			var fullname : String = search_path.trim_prefix(asset_base_dir).trim_prefix("/").path_join(file)
			var asset = {} # Output of generate_scene()
			var scene_filename = generate_scene(res.get_string_from_ascii(), fullname, asset)
#			print("asset output: ", asset)
			if scene_filename == null:
				assets.append({
					name=asset_name,
					fullname=asset_name,
					filename=asset_filename,
					scene=null,
					type="ASSETS",
					})
			else:
				assets.append({
					name=asset.name, # asset name setting in URDF
					fullname=fullname, # relative path
					filename=asset_filename, # absolute path of file
					scene=scene_filename, # absolute path of scene
					type=asset.type, # 
					})
		reader.close()
		
	# Processing each urdf file
	for file in urdf_files:
		var urdf_pathname = search_path.path_join(file)
#		print("[DB] urdf_pathname: ", urdf_pathname)
		var scene : Array = []
		if create_scene(urdf_pathname, scene):
			pass
			assets.append({
				name = scene[0], # asset name setting in URDF
				fullname = urdf_pathname.trim_prefix(asset_base_path+"/"), # relative path
				filename = urdf_pathname, # absolute path of file
				scene = scene[1], # absolute path of scene
				type = scene[2], # 
				})
		else:
			printerr("[DB] creating scene failed")
		
		
	# search sub-folders
	var dirs = Array(DirAccess.get_directories_at(search_path))
#	print_debug("dirs: ", dirs)
	var search_dirs = dirs.map(func(dir): return search_path.path_join(dir))
#	print("search dirs: ", search_dirs)
	for search_dir in search_dirs:
		add_assets(search_dir, asset_base_dir)
	
	var err = ResourceSaver.save(self, "res://temp/database.tres")
	if err:
		printerr("Database not saving!")
		
func create_scene(urdf_pathname: String, scene: Array) -> bool:
	var asset_path = urdf_pathname.get_base_dir()+"/"
	urdf_parser.asset_user_path = asset_path
	var error_output : Array = []
	var urdf_data: PackedByteArray = FileAccess.get_file_as_bytes(urdf_pathname)
	var root_node: Node3D = urdf_parser.parse(urdf_data, error_output)
	
	if root_node == null:
		printerr("[DB] URDF Parser failed")
		return false
#	print("root_node.name : ", root_node.name)
#	print("root node type: ", root_node.get_meta("type"))
	var scene_pathname: String
	if ProjectSettings.get_setting("application/config/create_binary_scene"):
		scene_pathname = temp_abs_path.path_join(urdf_pathname.trim_prefix(asset_base_path).trim_prefix("/").get_basename().validate_node_name() + ".scn")
	else:
		scene_pathname = temp_abs_path.path_join(urdf_pathname.trim_prefix(asset_base_path).trim_prefix("/").get_basename().validate_node_name() + ".tscn")
#	print("[DB] scene pathname: ", scene_pathname)
	scene.append(root_node.name)
	scene.append(scene_pathname)
	scene.append(root_node.get_meta("type"))
	
	var asset_scene = PackedScene.new()
	var err = asset_scene.pack(root_node)
	if err:
		printerr("[DB] asset pack failed")
		return false
	err = ResourceSaver.save(asset_scene, scene_pathname)
	if err != OK:
		printerr("[DB] An error %d occurred while saving the scene to disk." % err)
		return false
	return true
		
## Create a scene from URDF description, and return asset filename
func generate_scene(urdf_code: String, fullname: String, asset: Dictionary = {}):
	var result = urdf_parser.parse_buffer(urdf_code, asset)
	
	if result is String:
		print("error message: ", result)
		return null
		
	var root_node : Node3D = result
	if root_node == null: return null
	var scene_filename: String
	if ProjectSettings.get_setting("application/config/create_binary_scene"):
		scene_filename = temp_abs_path.path_join(fullname.get_basename().validate_node_name() + ".scn")
	else:
		scene_filename = temp_abs_path.path_join(fullname.get_basename().validate_node_name() + ".tscn")
	
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
	
	root_node.free()	# Delete orphan nodes
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
	
func get_type(fullname: String):
	for asset in assets:
		if asset.fullname == fullname:
			return asset.type
	return null
	
func get_fullname(scene_path: String):
	for asset in assets:
		if asset.scene == scene_path:
			return asset.fullname
	return null
