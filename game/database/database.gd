class_name GoboticsDB extends Resource

@export var assets: Array

var urdf_parser = URDFParser.new()
var reader := ZIPReader.new()

func _init():
	urdf_parser.scale = 10
	urdf_parser.gravity_scale = ProjectSettings.get_setting("physics/3d/default_gravity")/9.8
	
func generate():
	assets.clear()
	add_builtin_env(GSettings.builtin_env)
	add_assets(GSettings.asset_path, GSettings.asset_path)


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
	# Filtering URDF files
	var urdf_files: Array = files.filter(func(file): return file.get_extension() == "urdf")
#	print("[DB] URDF files: ", urdf_files)
	
	# Processing each urdf file
	for file in urdf_files:
		var urdf_pathname = search_path.path_join(file)
#		print("[DB] urdf_pathname: ", urdf_pathname)
		var scene : Array = []
		if create_scene(urdf_pathname, scene):
			
			assets.append({
				name = scene[0], # asset name setting in URDF
				fullname = urdf_pathname.trim_prefix(GSettings.asset_path+"/"), # relative path
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
	
	var err = ResourceSaver.save(self, GSettings.temp_path.path_join("database.tres"))
	if err:
		printerr("Database not saving!")
		
func update_asset(asset_fullname: String):
	#print("[DB] fullname: " , asset_fullname)
	if is_asset_exists(asset_fullname):
		#print("update asset")
		_update_asset(asset_fullname)
	else:
		#print("add new asset")
		add_new_asset(asset_fullname)
		
func _update_asset(fullname: String):
	for idx in len(assets):
		var asset = assets[idx]
		if asset.fullname == fullname:
			var urdf_pathname = GSettings.asset_path.path_join(fullname)
			var scene : Array = []
			if create_scene(urdf_pathname, scene):
				assets[idx] = {
					name = scene[0], # asset name setting in URDF
					fullname = urdf_pathname.trim_prefix(GSettings.asset_path+"/"), # relative path
					filename = urdf_pathname, # absolute path of file
					scene = scene[1], # absolute path of scene
					type = scene[2], # 
				}
				var err = ResourceSaver.save(self, GSettings.temp_path.path_join("database.tres"))
				if err:
					printerr("[ERROR] Database not saving!")
			else:
				printerr("[DB] creating scene failed")
			return
		
func add_new_asset(asset_fullname: String):
	var urdf_pathname = GSettings.asset_path.path_join(asset_fullname)
#	print("urdf pathname: ", urdf_pathname)
	var scene : Array = []
	if create_scene(urdf_pathname, scene):
		assets.append({
			name = scene[0], # asset name setting in URDF
			fullname = urdf_pathname.trim_prefix(GSettings.asset_path+"/"), # relative path
			filename = urdf_pathname, # absolute path of file
			scene = scene[1], # absolute path of scene
			type = scene[2], # 
			})
		var err = ResourceSaver.save(self, "res://temp/database.tres")
		if err:
			printerr("Database not saving!")
	else:
		printerr("[DB] creating scene failed")
	
func create_scene(urdf_pathname: String, scene: Array) -> bool:
	#print("[DB] urdf path: ", urdf_pathname)
	var asset_path = urdf_pathname.get_base_dir()+"/"
#	print("asset path: ", asset_path)
	urdf_parser.asset_user_path = asset_path
	var error_output : Array = []
	var urdf_data: PackedByteArray = FileAccess.get_file_as_bytes(urdf_pathname)
#	print("urdf data: ", urdf_data)
	var root_node: Node3D = urdf_parser.parse(urdf_data, error_output)
	
	if root_node == null:
		printerr("[DB] URDF Parser failed")
		return false
		
	var fullname = urdf_pathname.trim_prefix(GSettings.asset_path+"/")
#	print("[DB] fullname: ", fullname)
	root_node.set_meta("fullname", fullname) # Save fullname in asset scene for updating
#	print("root_node.name : ", root_node.name)
#	print("root node type: ", root_node.get_meta("type"))
	var scene_pathname: String
	if ProjectSettings.get_setting("application/config/create_binary_scene"):
		scene_pathname = GSettings.temp_path.path_join(urdf_pathname.trim_prefix(GSettings.asset_path).trim_prefix("/").get_basename().validate_node_name() + ".scn")
	else:
		scene_pathname = GSettings.temp_path.path_join(urdf_pathname.trim_prefix(GSettings.asset_path).trim_prefix("/").get_basename().validate_node_name() + ".tscn")
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
		
	root_node.free()	# Delete orphan nodes
	return true
	
func is_asset_exists(fullname: String) -> bool:
	for asset in assets:
		if asset.fullname == fullname:
			return true
	return false
	
func get_asset_filename(fullname: String):
	for asset in assets:
		if asset.fullname == fullname:
			return asset.filename
	return null
	
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
