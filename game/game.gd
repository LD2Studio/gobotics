class_name Game extends Control

var asset_base_dir: String # Full pathname
var gravity_enabled: bool = true

var builtin_env = [
	{ name = "DarkEnv", scene_filename = "res://game/environments/dark_environment.tscn"},
	{ name = "LightEnv", scene_filename = "res://game/environments/light_environment.tscn"},
]

# IMPORTANT : Mettre la propriété "mouse_filter" du noeud racine sur "Pass" pour ne pas bloquer la détection des objets physiques avec la souris
@onready var game_scene = %GameScene
@onready var assets_list = %AssetList
@onready var control_camera_3d: Camera3D = %"3DView"
@onready var top_camera_2d: Camera3D = %TopView
@onready var object_inspector = %ObjectInspector
@onready var confirm_delete_dialog: ConfirmationDialog = %ConfirmDeleteDialog
@onready var environment_list = %EnvironmentList

var current_filename: String:
	set(value):
		current_filename = value
		if current_filename == "":
			%SceneFileName.text = "No Scene saved"
		else:
			%SceneFileName.text = "%s" % [current_filename.get_file().get_basename()]


func _ready():
	var app_name: String = ProjectSettings.get_setting("application/config/name")
	var version: String = ProjectSettings.get_setting("application/config/version")
	%TitleApp.text = "%s v%s" % [app_name, version]
	
	fill_assets_list()
	%SaveSceneButton.disabled = true
	%SaveSceneAsButton.disabled = true
	object_inspector.visible = false
	
	current_filename = GSettings.projects_global_path.path_join(GParam.project_file)
	#print("current filename: ", current_filename)
	game_scene.load_scene(current_filename)
	

func _unhandled_key_input(event: InputEvent) -> void:
	if event.keycode == KEY_ESCAPE and event.pressed:
		var err = get_tree().change_scene_to_file("res://game/home_page/home_page.tscn")

func _on_new_scene_button_pressed() -> void:
	environment_list.update_list()
	%NewSceneDialog.popup_centered(Vector2i(200, 300))

func _on_new_scene_dialog_confirmed() -> void:
	var items = %EnvironmentList.get_selected_items()
	if items.is_empty(): return
	var idx = items[0]
	var env = %EnvironmentList.get_item_metadata(idx)
	current_filename = ""
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
	
func load_assets_in_database():
	GSettings.database.generate(asset_base_dir, builtin_env)
	
func fill_assets_list():
	assets_list.clear()
	for asset in GSettings.database.assets:
		if asset.type == "builtin_env": continue
		var idx = assets_list.add_item(asset.name)
		assets_list.set_item_metadata(idx, asset.fullname)
		assets_list.set_item_tooltip(idx, asset.fullname)


func _on_setup_scene_button_pressed():
	%GravityCheckBox.button_pressed = gravity_enabled
	%SetupDialog.popup_centered()


func _on_setup_dialog_confirmed():
	gravity_enabled = %GravityCheckBox.button_pressed
	if gravity_enabled:
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 98)
	else:
		PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, 0)
		
