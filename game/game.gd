extends Control

@export var asset_dir: String = "assets"

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris
@onready var game_scene = %GameScene
@onready var assets_list = %AssetList
@onready var control_camera_3d: Camera3D = %ControlCamera3D
@onready var top_camera_2d: Camera3D = %TopCamera2D
@onready var object_inspector = %ObjectInspector
@onready var confirm_delete_dialog: ConfirmationDialog = %ConfirmDeleteDialog

var current_filename: String:
	set(value):
		current_filename = value
		if current_filename == "":
			%SceneFileName.text = "No Scene"
		else:
			%SceneFileName.text = "%s" % [current_filename.get_file().get_basename()]
			
var database: GoboticsDB = GoboticsDB.new()

func _enter_tree():
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
	%NewSceneDialog.popup_centered(Vector2i(200, 300))

func _on_new_scene_dialog_confirmed() -> void:
	var items = %EnvironmentList.get_selected_items()
	if items.is_empty(): return
	var environment_name: String = %EnvironmentList.get_item_text(items[0])
	current_filename = "noname.tscn"
	game_scene.new_scene(database.get_scene(environment_name))
	
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

func _on_view_button_toggled(button_pressed: bool) -> void:
	top_camera_2d.current = true if button_pressed else false

func _on_clear_button_pressed() -> void:
	%TerminalOutput.text = ""
	
func load_pck():
	var executable_path: String = OS.get_executable_path().get_base_dir()
	var assets_dir: String = executable_path.path_join(asset_dir)
	var files = Array(DirAccess.get_files_at(assets_dir))
	var pck_files = files.filter(func(file): return file.get_extension() == "pck")
	var zip_files = files.filter(func(file): return file.get_extension() == "zip")
#	print(pck_files)
	
	for pck_file in pck_files:
		var pck_abs_path: String = assets_dir.path_join(pck_file)
		if not ProjectSettings.load_resource_pack(pck_abs_path, false):
			print("Packed resource not loading")
	
	for pck_file in zip_files:
		var pck_abs_path: String = assets_dir.path_join(pck_file)
		if not ProjectSettings.load_resource_pack(pck_abs_path, false):
			print("Packed resource not loading")
			
func load_assets_in_database():
	database.assets.clear()
	database.add_assets("res://game/assets")
#	if not OS.has_feature("editor"):
#		load_pck()
	if OS.has_feature("editor"):
		if not DirAccess.dir_exists_absolute("res://".path_join(asset_dir)):
			print("[ERROR] Asset Directory not exists")
		else:
			database.add_assets("res://".path_join(asset_dir))
	else:
		if not DirAccess.dir_exists_absolute(OS.get_executable_path().get_base_dir().path_join(asset_dir)):
			print("[ERROR] Asset Directory not exists")
		else:
			database.add_assets(OS.get_executable_path().get_base_dir().path_join(asset_dir))

func fill_assets_list():
	assets_list.clear()
#	print(database.assets)
	for asset in database.assets:
		if asset.group == "ITEMS" or asset.group == "ASSETS":
			assets_list.add_item(asset.name)
