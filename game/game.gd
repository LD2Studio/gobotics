class_name Game extends Control

@export var asset_dir : String = "assets"
@export var package_dir : String = "packages"
@export var temp_dir : String = "temp"

var asset_base_dir: String
var package_base_dir: String

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris
@onready var game_scene = %GameScene
@onready var assets_list = %AssetList
@onready var control_camera_3d: Camera3D = %"3DView"
@onready var top_camera_2d: Camera3D = %TopView
@onready var object_inspector = %ObjectInspector
@onready var confirm_delete_dialog: ConfirmationDialog = %ConfirmDeleteDialog
@onready var environment_list = %EnvironmentList

var database: GoboticsDB = GoboticsDB.new(package_dir, temp_dir)

var current_filename: String:
	set(value):
		current_filename = value
		if current_filename == "":
			%SceneFileName.text = "No Scene saved"
		else:
			%SceneFileName.text = "%s" % [current_filename.get_file().get_basename()]
		
func _enter_tree():
	create_dir()
	load_assets_in_database()

func _ready():
	var app_name: String = ProjectSettings.get_setting("application/config/name")
	var version: String = ProjectSettings.get_setting("application/config/version")
	%TitleApp.text = "%s v%s" % [app_name, version]
	
	fill_assets_list()
	%SaveSceneButton.disabled = true
	%SaveSceneAsButton.disabled = true
	object_inspector.visible = false
	current_filename = ""

func _on_new_scene_button_pressed() -> void:
	environment_list.update_list()
	%NewSceneDialog.popup_centered(Vector2i(200, 300))

func _on_new_scene_dialog_confirmed() -> void:
	var items = %EnvironmentList.get_selected_items()
	if items.is_empty(): return
	var idx = items[0]
	var fullname = %EnvironmentList.get_item_metadata(idx)
	current_filename = ""
	var env = database.get_scene_from_fullname(fullname)
	if env:
		game_scene.new_scene(env)
	
func _on_load_scene_button_pressed():
	%LoadSceneDialog.popup_centered(Vector2i(300,300))

func _on_load_scene_dialog_file_selected(path):
	current_filename = path
	game_scene.load_scene(path)

func _on_save_button_pressed() -> void:
	game_scene.save_scene(current_filename)
	
func _on_save_scene_as_button_pressed():
	if current_filename != "":
		%SaveSceneDialog.current_file = current_filename.get_file()
	%SaveSceneDialog.popup_centered(Vector2i(300, 300))

func _on_save_scene_dialog_file_selected(path):
	current_filename = path
	game_scene.save_scene(path)

func _on_clear_button_pressed() -> void:
	%TerminalOutput.text = ""
	
#func load_pck():
#	var executable_path: String = OS.get_executable_path().get_base_dir()
#	var assets_dir: String = executable_path.path_join(asset_dir)
#	var files = Array(DirAccess.get_files_at(assets_dir))
#	var pck_files = files.filter(func(file): return file.get_extension() == "pck")
#	var zip_files = files.filter(func(file): return file.get_extension() == "zip")
##	print(pck_files)
#
#	for pck_file in pck_files:
#		var pck_abs_path: String = assets_dir.path_join(pck_file)
#		if not ProjectSettings.load_resource_pack(pck_abs_path, false):
#			print("Packed resource not loading")
#
#	for pck_file in zip_files:
#		var pck_abs_path: String = assets_dir.path_join(pck_file)
#		if not ProjectSettings.load_resource_pack(pck_abs_path, false):
#			print("Packed resource not loading")
			
## Loading assets located in the <asset> directory and places them in a GoboticsDB database
func load_assets_in_database():
	database.asset_base_dir = asset_base_dir
	database.assets.clear()
	database.add_assets(asset_base_dir)
	
func fill_assets_list():
	assets_list.clear()
	for asset in database.assets:
		var idx = assets_list.add_item(asset.name)
		assets_list.set_item_metadata(idx, asset.fullname)
		assets_list.set_item_tooltip(idx, asset.fullname)

## Create missing directory in application folder like assets, packages and temp.
## Must be called first.
func create_dir():
	# Creating temp directory
	var temp_abs_path: String
	if OS.has_feature("editor"):
		temp_abs_path = ProjectSettings.globalize_path("res://" + temp_dir)
	else:
		temp_abs_path = OS.get_executable_path().get_base_dir().path_join(temp_dir)
		
	if DirAccess.dir_exists_absolute(temp_abs_path):
		# delete all files before remove temp dir
		var files = DirAccess.get_files_at(temp_abs_path)
		for file in files:
			DirAccess.remove_absolute(temp_abs_path.path_join(file))
		DirAccess.remove_absolute(temp_abs_path)
	DirAccess.make_dir_absolute(temp_abs_path)

	# Creating packages directory
	if OS.has_feature("editor"):
		package_base_dir = ProjectSettings.globalize_path("res://" + package_dir)
	else:
		package_base_dir = OS.get_executable_path().get_base_dir().path_join(package_dir)
		
	if not DirAccess.dir_exists_absolute(package_base_dir):
		DirAccess.make_dir_absolute(package_base_dir)
		
	# Creating assets directory
	if OS.has_feature("editor"):
		asset_base_dir = ProjectSettings.globalize_path("res://" + asset_dir)
	else:
		asset_base_dir = OS.get_executable_path().get_base_dir().path_join(asset_dir)
		
	if not DirAccess.dir_exists_absolute(asset_base_dir):
		DirAccess.make_dir_absolute(asset_base_dir)
