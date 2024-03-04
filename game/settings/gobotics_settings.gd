class_name GoboticsSettings extends Node
## Singleton GoboticsSettings
##
## Stocke les paramètres de configuration du jeu Gobotics

## Chemin vers les projets utilisateur de Gobotics.
var project_path: String:
	get:
		return (ProjectSettings.globalize_path(_project_editor_path)
			if OS.has_feature("editor")
				and not ProjectSettings.get_setting("application/config/use_user_path")
			else _project_export_path)

var _project_editor_path = "res://projects"
var _project_export_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("Gobotics")

## Chemin vers les assets de Gobotics.
var asset_path: String:
	get:
		return (ProjectSettings.globalize_path(_asset_editor_path)
			if OS.has_feature("editor")
				and not ProjectSettings.get_setting("application/config/use_user_path")
			else ProjectSettings.globalize_path(_asset_export_path))

var _asset_editor_path: String = "res://assets"
var _asset_export_path: String = "user://assets"

## Chemin vers les fichiers temporaires de Gobotics.
var temp_path: String:
	get:
		return (ProjectSettings.globalize_path(_temp_editor_path)
			if OS.has_feature("editor")
			else ProjectSettings.globalize_path(_temp_export_path))
var _temp_editor_path = "res://temp"
var _temp_export_path = "user://temp"

var builtin_env = [
	{ name = "DarkEnv", scene_filename = "res://game/environments/dark_environment.tscn"},
	{ name = "LightEnv", scene_filename = "res://game/environments/light_environment.tscn"},
]

var database: GoboticsDB

func _init() -> void:
	create_dir()
	database = GoboticsDB.new()


func _ready() -> void:
	database.generate()


## Create directory like assets and temp in res/user path.
## Must be called first before creating database.
func create_dir():
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
		#print("Open asset editor error : ", DirAccess.get_open_error())
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
