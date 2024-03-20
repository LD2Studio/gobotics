class_name GoboticsSettings extends Node
## Singleton GoboticsSettings
##
## Stocke les paramètres de configuration du jeu Gobotics

enum AssetType {
	STANDALONE,
	ROBOT,
	ENVIRONMENT,
}
## Chemin vers le fichier de configuration de Gobotics
var setting_path: String:
	get:
		return (ProjectSettings.globalize_path(_setting_editor_path)
			if OS.has_feature("editor")
			else ProjectSettings.globalize_path(_setting_export_path))

var _setting_editor_path: String = "res://"
var _setting_export_path: String = "user://"

## Chemin vers les projets utilisateur de Gobotics.
var project_path: String:
	get:
		return (ProjectSettings.globalize_path(_project_editor_path)
			if OS.has_feature("editor")
				and not ProjectSettings.get_setting("application/run/global")
			else _project_export_path)

var _project_editor_path = "res://projects"
var _project_export_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Gobotics/projects")

## Chemin vers les assets de Gobotics.
var asset_path: String:
	get:
		return (ProjectSettings.globalize_path(_asset_editor_path)
			if OS.has_feature("editor")
				and not ProjectSettings.get_setting("application/run/global")
			else ProjectSettings.globalize_path(_asset_export_path))

var _asset_editor_path: String = "res://assets"
var _asset_export_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Gobotics/assets")

## Chemin vers les fichiers temporaires de Gobotics.
var temp_path: String:
	get:
		return (ProjectSettings.globalize_path(_temp_editor_path)
			if OS.has_feature("editor")
			else ProjectSettings.globalize_path(_temp_export_path))

var _temp_editor_path = "res://temp"
var _temp_export_path = "user://temp"

var custom_links: Array

var builtin_env = [
	{ name = "DarkEnv", scene_filename = "res://game/environments/dark_environment.tscn"},
	{ name = "LightEnv", scene_filename = "res://game/environments/light_environment.tscn"},
]

var database: GoboticsDB
var settings_db: SettingsDB

func _init() -> void:
	_create_dir()
	database = GoboticsDB.new()
	_load_settings()


## Loading modules for Gobotics
func load_mods():
	for mod_path in settings_db.mod_paths:
		if FileAccess.file_exists(mod_path):
			var success = ProjectSettings.load_resource_pack(mod_path, false)
			if not success:
				printerr("Failed to loading modules!")
			else:
				print("Loading <%s> module successfully!" % [mod_path])


## Loading assets for Gobotics
func load_assets():
	_load_custom_links()
	database.generate()


## Saving Gobotics settings in [code]settings.tres[/code]
func save_settings():
	settings_db.save_settings(setting_path.path_join("settings.tres"))


# INFO: Create directory like assets and temp in res/user path.
# WARNING: Must be called first before creating database.
func _create_dir():
	# Creating temp directory
	if DirAccess.dir_exists_absolute(temp_path):
		# delete all files before remove temp dir
		var files = DirAccess.get_files_at(temp_path)
		for file in files:
			DirAccess.remove_absolute(temp_path.path_join(file))
		DirAccess.remove_absolute(temp_path)
	DirAccess.make_dir_absolute(temp_path)
		
	# Creating assets directory
	if not DirAccess.dir_exists_absolute(asset_path):
		DirAccess.make_dir_absolute(asset_path)
	if not DirAccess.dir_exists_absolute(asset_path.path_join("demo")):
			DirAccess.make_dir_absolute(asset_path.path_join("demo"))
	
	const DEMO_ASSET_PATH = "res://game/assets/demo/"
	var demo_asset_dir = DirAccess.open(DEMO_ASSET_PATH)
	#var is_dev_mode: bool = not OS.has_feature("editor") or ProjectSettings.get_setting("application/config/use_user_path")
	
	if demo_asset_dir:
		var demo_files = demo_asset_dir.get_files()
		for file in demo_files:
			demo_asset_dir.copy(DEMO_ASSET_PATH.path_join(file),
					asset_path.path_join("demo").path_join(file))
		if not DirAccess.dir_exists_absolute(asset_path.path_join("demo/meshes")):
			DirAccess.make_dir_absolute(asset_path.path_join("demo/meshes"))
			
		var demo_meshes_dir = DirAccess.open(DEMO_ASSET_PATH.path_join("meshes"))
		#print("Open meshes dir error: ", DirAccess.get_open_error())
		if demo_meshes_dir:
			var demo_mesh_files = demo_meshes_dir.get_files()
			for file in demo_mesh_files:
				#print("extension: ", file.get_extension())
				if file.get_extension() == "import": continue # Exclude *.import files
				#print("Copy %s to %s" % [file, asset_path.path_join("demo/meshes")])
				var err = demo_meshes_dir.copy(DEMO_ASSET_PATH.path_join("meshes").path_join(file),
						asset_path.path_join("demo/meshes").path_join(file))
				if err != OK:
					printerr("Copy GLTF files failed!")
		else:
			printerr("Opening demo meshes dir failed (%d)" % [DirAccess.get_open_error()])
	else:
		printerr("Opening demo asset dir failed (%d)" % [DirAccess.get_open_error()])
		
	# Creating projects directory
	if not DirAccess.dir_exists_absolute(project_path):
		DirAccess.make_dir_absolute(project_path)


func _load_settings():
	if FileAccess.file_exists(setting_path.path_join("settings.tres")):
		settings_db = ResourceLoader.load(setting_path.path_join("settings.tres"))
	else:
		settings_db = SettingsDB.new()
		save_settings()


func _load_custom_links():
	custom_links.clear()
	# Append builtin links
	if OS.has_feature("editor"):
		var builtin_links_dir = DirAccess.open(ProjectSettings.globalize_path("res://game/builtins/"))
		if builtin_links_dir:
			var scene_files = Array(builtin_links_dir.get_files())
			#print("raw files", scene_files)
			scene_files = scene_files.filter(
					func(file: String): return file.get_extension() == "tscn"
					)
			#print("scene files: ", scene_files)
			for scene_file in scene_files:
				var scene: PackedScene = load("res://game/builtins/".path_join(scene_file))
				#print("scene: ", scene.get_state())
				var node_count: int = scene.get_state().get_node_count()
				#print("count: ", node_count)
				#print("node 0: ", scene.get_state().get_node_name(0))
				var groups: PackedStringArray = scene.get_state().get_node_groups(0)
				#print("groups: ", groups)
				if "EXTENDS_LINK" in groups:
					#print("path: ", "res://game/builtins/".path_join(scene_file))
					#print("name: ", scene.get_state().get_node_name(0))
					custom_links.append(
						{
							name = scene.get_state().get_node_name(0),
							path = "res://game/builtins/".path_join(scene_file)
						}
					)
	else: # exported
		var builtin_links_dir = DirAccess.open("res://game/builtins")
		# INFO: When exported, scene is "tscn.remap" extension
		if builtin_links_dir:
			var scene_files = Array(builtin_links_dir.get_files())
			#print("raw files", scene_files)
			scene_files = scene_files.filter(func(file: String):
				return file.ends_with("tscn.remap")
				)
			scene_files = scene_files.map(func(file: String):
				return file.trim_suffix(".remap")
				)
			#print("scene files: ", scene_files)
			for scene_file in scene_files:
				var scene: PackedScene = load("res://game/builtins/".path_join(scene_file))
				#print("scene: ", scene.get_state())
				var node_count: int = scene.get_state().get_node_count()
				#print("count: ", node_count)
				#print("node 0: ", scene.get_state().get_node_name(0))
				var groups: PackedStringArray = scene.get_state().get_node_groups(0)
				#print("groups: ", groups)
				if "EXTENDS_LINK" in groups:
					#print("path: ", "res://game/builtins/".path_join(scene_file))
					#print("name: ", scene.get_state().get_node_name(0))
					custom_links.append(
						{
							name = scene.get_state().get_node_name(0),
							path = "res://game/builtins/".path_join(scene_file)
						}
					)
	# Append mods links
	#var mods_links_dir = DirAccess.open(ProjectSettings.globalize_path("res://mods/"))
	var mods_links_dir = DirAccess.open("res://mods")
	#print("mods link dir: ", mods_links_dir)
	# BUG : mods dir is not accessed on export game
	if mods_links_dir:
		var scene_files = Array(mods_links_dir.get_files())
		#scene_files = scene_files.filter(
				#func(file: String): return file.get_extension() == "tscn"
				#)
		scene_files = scene_files.filter(
				func(file: String): return file.ends_with("tscn.remap")
				)
		scene_files = scene_files.map(func(file: String):
			return file.trim_suffix(".remap")
		)
		#print("scene files: ", scene_files)
		for scene_file in scene_files:
			var scene: PackedScene = load("res://mods/".path_join(scene_file))
			#print("scene: ", scene.get_state())
			var node_count: int = scene.get_state().get_node_count()
			#print("count: ", node_count)
			#print("node 0: ", scene.get_state().get_node_name(0))
			var groups: PackedStringArray = scene.get_state().get_node_groups(0)
			#print("groups: ", groups)
			if "EXTENDS_LINK" in groups:
				#print("path: ", "res://mods/".path_join(scene_file))
				#print("name: ", scene.get_state().get_node_name(0))
				custom_links.append(
					{
						name = scene.get_state().get_node_name(0),
						path = "res://mods/".path_join(scene_file)
					}
				)
