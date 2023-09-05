class_name GoboticsDB extends Resource

@export var assets: Array

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
#	print("[Database] search path: ", search_path)
	var files = Array(DirAccess.get_files_at(search_path))
#	print("files: ", files)
	# Filter asset files
	var asset_files: Array = files.filter(func(file): return file.get_extension() == "asset")
#	print("asset files: ", asset_files)
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
		

		
## Create a scene from URDF description, and return asset filename
func generate_scene(urdf_code: String, fullname: String, asset: Dictionary = {}):
	var result = urdf_parser.parse_buffer(urdf_code, asset)
	
	if result is String:
		print("error message: ", result)
		return null
		
	var root_node : Node3D = result
	var scene_filename = temp_abs_path.path_join(fullname.get_basename().validate_node_name() + ".tscn")
	if root_node == null: return null

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
	
